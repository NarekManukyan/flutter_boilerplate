---
name: create-api-provider
description: Add a Retrofit @RestApi provider in packages/api — the _Paths convention, method annotations, request bodies, queries, multipart, paged envelopes, barrel exports, DioService registration, a request-shape test over a fake HttpClientAdapter, and the interceptor chain (order, no-connection fail-fast, retry with backoff, environment-gated logging). Use when adding a new API resource or endpoint, or an interceptor.
---

# Create a Retrofit API provider

Governed by [ADR-0011](../../../docs/adr/0011-retrofit-typed-api-layer.md). Providers live in `packages/api`; app code reaches them only through `DioService`.

## Shape

One provider per resource, at `packages/api/lib/src/providers/{resource}_provider/{resource}_api_provider.dart`.

```dart
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'models/models.dart';

part 'todos_api_provider.g.dart';

class _Paths {
  static const getTodos = '/todos';
  static const createTodo = '/todos';
  static const todoById = '/todos/{id}';

  _Paths._();
}

@RestApi()
abstract class TodosApiProvider {
  factory TodosApiProvider(Dio dio) = _TodosApiProvider;

  @GET(_Paths.getTodos)
  Future<List<TodoDto>> getTodos();

  @POST(_Paths.createTodo)
  Future<TodoDto> createTodo({
    @Body() required TodoCreateRequestDto todoCreateDto,
  });

  @DELETE(_Paths.todoById)
  Future<void> deleteTodo(@Path('id') String id);
}
```

`deleteTodo` and `todoById` are illustrative: the real [`todos_api_provider.dart`](../../../packages/api/lib/src/providers/todos_provider/todos_api_provider.dart) has only `getTodos` and `createTodo`.

- **Every path string goes in the private `_Paths` class** with a private constructor. No literals in annotations. A path shared by several methods on one resource is named for the resource, not the verb: `todoById` serves `GET`, `PUT` and `DELETE /todos/{id}`.
- The `factory … = _{Name}` line is required — it binds to the generated implementation.
- Method names are verbs: `getTodos`, `createTodo`, `deleteTodo`.
- Path parameters are positional (`deleteTodo(@Path('id') String id)`, called as `deleteTodo(id)`), as in [ADR-0011](../../../docs/adr/0011-retrofit-typed-api-layer.md). Bodies are named and required.

## Return types

- Single resource → the DTO directly: `Future<TodoDto>`.
- Paginated list → the shared envelope: `Future<ListResponseDto<TodoDto>>`.
- Unwrapped list → `Future<List<TodoDto>>` only when the server really returns a bare array.
- No body → `Future<void>`.

Never return `Response<dynamic>` or a raw `Map` — the point of this layer is that the type is the contract.

**`ListResponseDto<T>` needs a case per `T`.** Its items are parsed by the private `_Converter<T>` in `packages/api/lib/src/models/list_response_entity/list_response_entity.dart`, which throws `ArgumentError('add model for type: $T')` for any type it does not know. Add the DTO there when you first page it:

```dart
@override
T fromJson(Json json) {
  if (T == TodoDto) {
    return TodoDto.fromJson(json) as T;
  }
  throw ArgumentError('add model for type: $T');
}
```

## Parameters

| Kind | Annotation |
|---|---|
| Body | `@Body() required XDto dto` |
| Path segment | `@Path('id') String id` — must match `{id}` in the path |
| Query | `@Query('page') int page` |
| Header | `@Header('X-Thing') String thing` |
| Multipart | `@MultiPart()` on the method + `@Part() File file` |

Auth headers are **not** declared here — `AuthInterceptor` adds them for every request.

## Wire it up

1. Create the provider file plus its `models/` tree ([`create-dto`](../create-dto/SKILL.md)).
2. `{resource}_provider.dart` barrel:
   ```dart
   export 'models/models.dart';
   export 'todos_api_provider.dart';
   ```
3. Export the barrel from `packages/api/lib/api.dart`.
4. Register a lazily-created field on `DioService` (`lib/core/services/dio_service.dart`):
   ```dart
   late final TodosApiProvider todosProvider = TodosApiProvider(dio);
   ```
5. `melos run build` — regenerates `*.g.dart`.
6. A request-shape test for each new endpoint (below).

## Test the request shape

The generated `*.g.dart` is not tested by hand, but the provider interface is yours, and its annotations are where a wrong method or path gets in: `@GET` where the server wants `@DELETE`, `/todo/{id}` for `/todos/{id}`, a `@Path` name that does not match its placeholder. A store test mocks the provider, so it cannot see any of that.

Build the real provider over a `Dio` whose `httpClientAdapter` is a small fake. The fake records the `RequestOptions` and returns a canned `ResponseBody`, so nothing touches the network. Written against dio 5:

```dart
// packages/api/test/providers/todos_provider/todos_api_provider_test.dart
import 'dart:typed_data';

import 'package:api/api.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

/// Records each request instead of sending it, and answers with [body].
class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter({this.statusCode = 200, this.body = ''});

  final int statusCode;
  final String body;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: body.isEmpty
          ? null
          : {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('TodosApiProvider', () {
    test('should send DELETE /todos/{id}', () async {
      final adapter = _RecordingAdapter(statusCode: 204);
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = adapter;

      await TodosApiProvider(dio).deleteTodo('2');

      final request = adapter.requests.single;
      expect(request.method, 'DELETE');
      expect(request.path, '/todos/2');
    });

    test('should send GET /todos and parse the list', () async {
      final adapter = _RecordingAdapter(
        body: '[{"id": "1", "title": "a", "completed": false}]',
      );
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = adapter;

      final todos = await TodosApiProvider(dio).getTodos();

      expect(adapter.requests.single.method, 'GET');
      expect(adapter.requests.single.path, '/todos');
      expect(todos.single.id, '1');
    });
  });
}
```

- `HttpClientAdapter` has only a factory constructor, so the fake `implements` it; it cannot `extends`.
- Assert the method and `path`, plus `queryParameters` or `data` when the endpoint has them. Add a body when the return type is parsed, so the DTO is checked against a real payload shape too.
- The `DELETE` example is illustrative: this repo's provider has no delete endpoint.
- `packages/api` has no tests yet. The first one adds `test` to its `dev_dependencies`; `melos run test` then runs `dart test` there.

## Consuming it

Only stores and use cases touch `DioService`. States and widgets never do ([ADR-0001](../../../docs/adr/0001-layered-architecture.md)).

```dart
final result = await _dioService.todosProvider.getTodos();
```

At that call site, catch what you can handle ([`handle-errors`](../handle-errors/SKILL.md#what-to-catch)):

- `on DioException catch (e, stackTrace)` when the request is the only expected failure and there is nothing to undo: track it, and turn it into observable state or a value the caller branches on.
- A `catch` with no `on` clause when the call site restores state on failure (an optimistic change): the restore has to run whatever threw.

## Interceptors

App-level concerns live in `lib/core/services/interceptors/`, not in `packages/api`. `DioService.initDio()` builds the chain.

### What ships, and what you add

| Interceptor | Ships | Job |
|---|---|---|
| `NoConnectionInterceptor` | no — add per app | Fails fast when the device is offline |
| `MockTodosInterceptor` | yes, dev flavor only | Canned responses. Maestro flows run against it, so a new endpoint used by an E2E flow needs a mock branch here ([ADR-0015](../../../docs/adr/0015-mandatory-test-coverage-and-qa-gate.md)) |
| `ApiInterceptor` | yes | Base URL from `FlavorService`, request-data clean-up |
| `AuthInterceptor` | yes | Attaches the token; logs out on `401` |
| `RetryInterceptor` | no — add per app | Retries idempotent requests with backoff |
| `LogInterceptor` (Dio) | yes | Request/response logging — gate it by flavor, below |

Retry and no-connection are **added per app, when the app needs them**. The code below is the reference shape, not something the boilerplate already runs.

### Order

**no-connection → mock (dev) → api → auth → retry → log.** Without the two optional interceptors that is mock → api → auth → log. Dio runs every phase — request, response, error — in the order the list is written, and a `resolve` or `reject` from `onRequest` skips every interceptor after it.

- **No-connection first**, when the app adds it: an offline request is rejected before any other work, including the token read from storage. It goes in front of the mock on purpose — the dev build is what Maestro drives, and an offline flow (`.maestro/common/go_offline.yaml`) has to see the same offline failure a production build would, not a canned success.
- **Mock next**, so it answers before the real chain shapes, signs or logs anything.
- **Api, then auth**: the request is shaped, then signed.
- **Retry after auth**: auth's `onError` handles a `401` (logout) before retry sees the error, and a retried request goes back through `dio.fetch`, so auth signs it again with the current token.
- **Log last**: it logs the request as it was actually sent, and every retry attempt.

### Dependencies come through the constructor

Interceptors are not built by the container. `DioService` constructs them and passes what they need — the same rule as everywhere else ([ADR-0007](../../../docs/adr/0007-di-scopes-and-constructor-injection.md)). **Never call `getIt` inside an interceptor**, including to reach `DioService` for a retry: the retry interceptor gets the `Dio` it is installed on as a constructor argument.

### No-connection fail-fast

Check connectivity before the request goes out and reject it with a typed exception, instead of letting it wait out the 32-second connect timeout.

```dart
// lib/core/exceptions/no_connection_exception.dart

/// A request was not sent because the device has no network connection.
class NoConnectionException implements Exception {
  const NoConnectionException();

  @override
  String toString() => 'NoConnectionException: the device is offline';
}
```

```dart
// lib/core/services/interceptors/no_connection_interceptor.dart
import 'package:dio/dio.dart';

import '../../../features/app/mobx/connectivity_store.dart';
import '../../exceptions/no_connection_exception.dart';

/// Fails a request immediately when the device is offline, instead of letting
/// it wait out the connect timeout.
class NoConnectionInterceptor extends Interceptor {
  NoConnectionInterceptor(this._connectivityStore);

  final ConnectivityStore _connectivityStore;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_connectivityStore.hasConnection) {
      return handler.next(options);
    }
    // `reject` skips the remaining interceptors, error ones included, so the
    // retry interceptor never retries a request that was never sent.
    handler.reject(
      DioException.connectionError(
        requestOptions: options,
        reason: 'the device is offline',
        error: const NoConnectionException(),
      ),
    );
  }
}
```

- The rejection is a `DioException` of type `connectionError`, so callers keep catching `DioException`. One that needs to tell offline apart checks `e.error is NoConnectionException`.
- `IssueTrackingService` already treats `connectionError` as a connectivity error: no report and no notice, because the connection page tells the user ([ADR-0020](../../../docs/adr/0020-error-handling-and-issue-tracking.md)). Callers still call `trackHandledError`; the service drops it.

### Retry with backoff

```dart
// lib/core/services/interceptors/retry_interceptor.dart
import 'dart:math';

import 'package:dio/dio.dart';

/// Retries a failed request when retrying is safe and likely to help.
///
/// Gets the [Dio] it is installed on, so a retry runs through the whole chain
/// again: the auth interceptor attaches a current token, and the log
/// interceptor logs the attempt.
class RetryInterceptor extends Interceptor {
  RetryInterceptor(
    this._dio, {
    this.maxRetries = 3,
    this.baseDelay = const Duration(milliseconds: 500),
    this.maxDelay = const Duration(seconds: 8),
  });

  /// Opts a non-idempotent request in, for an endpoint that deduplicates
  /// (for example with an idempotency key):
  /// `@Extra({RetryInterceptor.forceRetryKey: true})`.
  static const forceRetryKey = 'retry_non_idempotent';

  static const _attemptKey = 'retry_attempt';
  static const _idempotentMethods = {'GET', 'HEAD', 'OPTIONS', 'PUT', 'DELETE'};
  static const _retryableStatusCodes = {502, 503, 504};

  final Dio _dio;
  final int maxRetries;
  final Duration baseDelay;
  final Duration maxDelay;
  final _random = Random();

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final attempt = options.extra[_attemptKey] as int? ?? 0;
    if (attempt >= maxRetries || !_isRetryable(err)) {
      return handler.next(err);
    }

    await Future<void>.delayed(_delayFor(attempt));
    options.extra[_attemptKey] = attempt + 1;

    try {
      handler.resolve(await _dio.fetch<dynamic>(options));
    } on DioException catch (retryError) {
      // Not tracked: `next` hands the final failure to the caller, which
      // tracks it (ADR-0020). Tracking here as well would report it twice.
      handler.next(retryError);
    }
  }

  bool _isRetryable(DioException err) {
    final options = err.requestOptions;
    final isIdempotent =
        _idempotentMethods.contains(options.method.toUpperCase()) ||
        options.extra[forceRetryKey] == true;
    // A FormData or stream body is consumed by the first attempt.
    if (!isIdempotent || options.data is FormData || options.data is Stream) {
      return false;
    }
    return switch (err.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError => true,
      DioExceptionType.badResponse => _retryableStatusCodes.contains(
        err.response?.statusCode,
      ),
      _ => false,
    };
  }

  /// 0.5 s, 1 s, 2 s … capped at [maxDelay], plus up to one [baseDelay] of
  /// jitter so clients that failed together do not all retry together.
  Duration _delayFor(int attempt) {
    final delay =
        baseDelay * pow(2, attempt) + baseDelay * _random.nextDouble();
    return delay > maxDelay ? maxDelay : delay;
  }
}
```

- **Only idempotent methods retry by default** — `GET`, `HEAD`, `OPTIONS`, `PUT`, `DELETE`: sending one twice leaves the server in the same state as sending it once.
- **`POST` and `PATCH` do not.** A `POST` that timed out may already have been applied — the response was lost, not the request. Retrying it creates a second todo, a second order, a second payment. Opt a single endpoint in with `@Extra({RetryInterceptor.forceRetryKey: true})` only when the server deduplicates it.
- **Only transient failures retry**: timeouts, connection errors, and `502` / `503` / `504`. A `4xx` fails the same way every time, and a `500` is usually a bug rather than a blip. The mock's `serverError` scenario answers `500`, so the Maestro failure flows see the error immediately.
- **The interceptor does not track.** Only the last failure reaches the caller, and the caller tracks it once.
- **Cancellation** is `DioExceptionType.cancel`, which is not retried.

### Environment-gated logging

The log interceptor exists only outside production, and never logs the auth header:

```dart
if (!_flavorService.isProduction)
  LogInterceptor(
    requestHeader: false, // Authorization carries the bearer token
    requestBody: true,
    responseBody: true,
    logPrint: (line) => log(line.toString(), name: 'BE'),
  ),
```

- **Production: no request or response logging at all.** Headers carry the bearer token and bodies carry user data, and device logs are readable by anything the user plugs the phone into. If production needs a breadcrumb, log the method, path and status code only.
- Dio's `LogInterceptor` logs request headers **by default** (`requestHeader: true`). Turn it off even in dev: dev logs end up in screenshots, CI output and bug reports.

### Wiring it together

```dart
// lib/core/services/dio_service.dart — initDio()
final options = BaseOptions(
  baseUrl: _flavorService.config.apiUrl,
  receiveDataWhenStatusError: true,
  connectTimeout: const Duration(seconds: 32),
  receiveTimeout: const Duration(seconds: 32),
);

// Two statements, not one cascade: RetryInterceptor needs `dio`, which is not
// assigned until `Dio(options)` returns. Reading it inside the cascade throws
// a LateInitializationError.
dio = Dio(options);
dio.interceptors.addAll(<Interceptor>[
  NoConnectionInterceptor(_connectivityStore),
  if (_flavorService.isDev) MockTodosInterceptor(),
  ApiInterceptor(_flavorService),
  AuthInterceptor(_authStore, _appNavigator),
  RetryInterceptor(dio),
  if (!_flavorService.isProduction)
    LogInterceptor(
      requestHeader: false,
      requestBody: true,
      responseBody: true,
      logPrint: (line) => log(line.toString(), name: 'BE'),
    ),
]);
```

`DioService` receives `ConnectivityStore` through its constructor like its other dependencies. Apply the same gating to any second `Dio` instance (`uploadImageDio`), and leave upload clients out of retry unless their bodies can be re-sent.

## Checklist

- [ ] One provider per resource, `@RestApi()` + `factory … = _{Name}`
- [ ] All paths in the private `_Paths` class
- [ ] Typed return: DTO, `List<DTO>`, or `ListResponseDto<T>` — never `dynamic`
- [ ] A new `ListResponseDto<T>` type has its case in `_Converter.fromJson`
- [ ] Exported via the resource barrel → `lib/api.dart`
- [ ] Field added to `DioService`
- [ ] Mock branch added to `MockTodosInterceptor` if an E2E flow exercises it
- [ ] A non-idempotent endpoint is not opted into retry unless the server deduplicates it
- [ ] Any new interceptor: dependencies via constructor, placed in the documented order, no logging of headers or bodies in production
- [ ] Path parameters positional, matching `{placeholders}` in `_Paths`
- [ ] `melos run build` run; `*.g.dart` untouched
- [ ] Request-shape test per endpoint: fake `HttpClientAdapter`, method and path asserted
- [ ] Only stores / use cases call it
