# 11. Retrofit + Freezed Typed API Layer

- Status: Accepted
- Date: 2026-05-08
- Deciders: Flutter team

## Context and Problem Statement

The app talks to several HTTP backends. Hand-rolled `Dio.get(...)` calls scattered across stores produce three problems: (1) request building duplicated per call site, (2) JSON decoding inline with business logic, (3) DTO contracts implicit and untyped.

A typed API layer with code generation removes the boilerplate, centralizes DTOs, and gives compile-time guarantees about request and response shapes.

## Decision Drivers

- Single contract — DTOs are the boundary between app and HTTP, owned in one package.
- Compile-time typing — bad request bodies fail at build, not at runtime.
- Pagination handling — paginated lists need a uniform helper, not ad-hoc `data` / `meta` parsing.

## Considered Options

- **Retrofit + freezed sealed DTOs in a separate `packages/api` module**.
- **Hand-rolled `Dio` calls per store**.
- **OpenAPI codegen (`openapi-generator`, `chopper` w/ generated client)**.

## Decision Outcome

Chosen option: **Retrofit + freezed sealed DTOs in `packages/api`**.

### Provider pattern

```dart
@RestApi()
abstract class TodosApiProvider {
  factory TodosApiProvider(Dio dio) = _TodosApiProvider;

  @GET(_Paths.getTodos)
  Future<List<TodoDto>> getTodos();

  @POST(_Paths.createTodo)
  Future<TodoDto> createTodo({
    @Body() required TodoCreateRequestDto todoCreateDto,
  });
}
```

Real example: [`TodosApiProvider`](../../packages/api/lib/src/providers/todos_provider/todos_api_provider.dart).

Endpoints that answer `204 No Content`, or whose body the app does not read, return `Future<void>`. They do not return `Future<dynamic>` or a placeholder DTO.

```dart
// _Paths.todoById = '/todos/{id}'
@DELETE(_Paths.todoById)
Future<void> deleteTodo(@Path('id') String id);
```

Illustrative: the real `TodosApiProvider` has no delete endpoint. Path parameters are positional, so a caller writes `deleteTodo(id)`. A path shared by several methods is named for the resource (`todoById`), not for one verb. Every path string lives in the provider's private `_Paths` class.

Each endpoint gets a request-shape test: the real provider over a `Dio` with a fake `HttpClientAdapter` that records the request, asserting method and path. The generated code is not written by hand, but the annotations are, and a store test that mocks the provider cannot catch a wrong one. See [`create-api-provider`](../../.claude/skills/create-api-provider/SKILL.md#test-the-request-shape).

### Where DTOs live

```
packages/api/lib/src/
  providers/
    todos_provider/
      todos_api_provider.dart
      models/                   per-resource DTOs: models.dart barrel, src/*_dto.dart
  models/
    list_response_entity/       DTOs shared across providers
```

- A DTO used by one provider lives in that provider's `models/` directory, next to the provider.
- A DTO shared across providers lives in `packages/api/lib/src/models/`, e.g. [`ListResponseDto`](../../packages/api/lib/src/models/list_response_entity/list_response_entity.dart) and `MetaDto`. A DTO moves there when a second provider needs it.

### DTO pattern

DTOs are `@freezed sealed class`es with `fromJson` factories. `build.yaml` enables `any_map: true` and `explicit_to_json: true` so nested DTOs serialize correctly and the JSON decoder accepts non-`Map<String, dynamic>` shapes.

Field names follow Dart style. `build.yaml` sets `field_rename: none`, so when a JSON key differs from the field name, the parameter maps it with `@JsonKey(name: ...)`:

```dart
@freezed
sealed class UserResponseDto with _$UserResponseDto {
  factory UserResponseDto({
    required String id,
    required String email,
    required String name,
    @JsonKey(name: 'req_id') required String reqId,
  }) = _UserResponseDto;

  factory UserResponseDto.fromJson(Map<String, dynamic> json) =>
      _$UserResponseDtoFromJson(json);
}
```

### Pagination envelope

Paginated responses use a generic [`ListResponseDto<T>`](../../packages/api/lib/src/models/list_response_entity/list_response_entity.dart) with `data: List<T>` and an optional `MetaDto`, plus a `parsedData(old)` extension that merges page 1 vs subsequent pages. Single-resource endpoints return the DTO directly; there is no universal response envelope.

> **Known oddity:** `ListResponseDto` and `MetaDto` currently declare `implements Exception`. This ADR codifies the *envelope shape*, not the `Exception` declaration — that looks like a vestigial artifact and is not part of the intended contract. Treat it as a follow-up cleanup; do not propagate the pattern to new DTOs.

### Access boundary

API providers are reached only through [`DioService`](../../lib/core/services/dio_service.dart) in stores and use cases. A store calls a provider inline for its own single request whose result it applies to its own observables (a load, a refresh, an optimistic mutation and its rollback). The call moves into an API use case when another consumer needs it, when it coordinates several requests or services, or when its response or error mapping is not trivial ([`create-use-case`](../../.claude/skills/create-use-case/SKILL.md)). Interceptors (auth, logging, mocking) live in [`lib/core/services/interceptors/`](../../lib/core/services/interceptors/) — app-side concerns belong in the app, not in the `packages/api` package.

### Consequences

- Good: typed request/response surface; DTO mismatches fail at build.
- Good: providers and DTOs sit in their own package, decoupled from the app.
- Good: `melos run build:api` runs codegen for the API package alone ([ADR-0014](0014-melos-package-split.md)).
- Bad: every endpoint requires an annotation + a codegen run — friction for one-off requests.
- Bad: DTOs use freezed code generation; build_runner cycles add wall-clock time on first build.

## Pros and Cons of the Options

### Retrofit + freezed
- Good: typed; single package; codegen pays for itself at scale.
- Bad: codegen friction; generic `ListResponseDto<T>` requires a custom converter for `T`.

### Hand-rolled `Dio`
- Good: zero codegen.
- Bad: duplicated request building; untyped responses; JSON parsing leaks into stores.

### OpenAPI codegen
- Good: server contract is the source of truth.
- Bad: requires a maintained OpenAPI spec; generated clients are bulky and harder to customize per endpoint.

## Links

- [ADR-0001 Layered architecture](0001-layered-architecture.md)
- [ADR-0014 Melos package split](0014-melos-package-split.md)
- Code: [packages/api](../../packages/api), [lib/core/services/dio_service.dart](../../lib/core/services/dio_service.dart)
