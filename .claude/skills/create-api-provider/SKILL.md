---
name: create-api-provider
description: Add a Retrofit @RestApi provider in packages/api — the _Paths convention, method annotations, request bodies, queries, multipart, barrel exports, DioService registration and interceptors. Use when adding a new API resource or a new endpoint to an existing one.
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

- **Every path string goes in the private `_Paths` class** with a private constructor. No literals in annotations.
- The `factory … = _{Name}` line is required — it binds to the generated implementation.
- Method names are verbs: `getTodos`, `createTodo`, `deleteTodo`.

## Return types

- Single resource → the DTO directly: `Future<TodoDto>`.
- Paginated list → the shared envelope: `Future<ListResponseDto<TodoDto>>`.
- Unwrapped list → `Future<List<TodoDto>>` only when the server really returns a bare array.
- No body → `Future<void>`.

Never return `Response<dynamic>` or a raw `Map` — the point of this layer is that the type is the contract.

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

## Consuming it

Only stores and use cases touch `DioService`. States and widgets never do ([ADR-0001](../../../docs/adr/0001-layered-architecture.md)).

```dart
final result = await _dioService.todosProvider.getTodos();
```

Catch `DioException` at that call site and translate it into observable state or a return value the caller can branch on.

## Interceptors

App-level concerns live in `lib/core/services/interceptors/`, not in `packages/api`:

- `AuthInterceptor` — token attach and refresh
- `ApiInterceptor` — shared headers, error normalisation
- `MockTodosInterceptor` — canned responses; this is what Maestro flows run against, so a new endpoint used by an E2E flow needs a mock branch here ([ADR-0015](../../../docs/adr/0015-mandatory-test-coverage-and-qa-gate.md))
- `LogInterceptor` — request/response logging

Order matters: mock first (so it short-circuits), then API, then auth, then logging.

## Checklist

- [ ] One provider per resource, `@RestApi()` + `factory … = _{Name}`
- [ ] All paths in the private `_Paths` class
- [ ] Typed return: DTO, `List<DTO>`, or `ListResponseDto<T>` — never `dynamic`
- [ ] Exported via the resource barrel → `lib/api.dart`
- [ ] Field added to `DioService`
- [ ] Mock branch added to `MockTodosInterceptor` if an E2E flow exercises it
- [ ] `melos run build` run; `*.g.dart` untouched
- [ ] Only stores / use cases call it
