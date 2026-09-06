---
name: create-dto
description: Create a freezed + json_serializable DTO in packages/api — file location under the owning resource provider, sealed class shape, barrel exports, nullable and default handling, enums, and paginated list responses. Use when adding or changing any *_dto.dart or wiring a new API response type.
---

# Create a DTO

Governed by [ADR-0011](../../../docs/adr/0011-retrofit-typed-api-layer.md). DTOs live in `packages/api`, never in `lib/`.

## Location

DTOs are owned by the resource provider that returns them:

```
packages/api/lib/src/providers/{resource}_provider/
  {resource}_api_provider.dart
  {resource}_provider.dart          barrel: exports models + provider
  models/
    models.dart                     export 'src/models.dart';
    src/
      models.dart                   export every dto in this dir
      {name}_dto.dart
```

Cross-resource models (`ListResponseDto`, shared envelopes) go in `packages/api/lib/src/models/`.

Naming: `{name}_dto.dart` for responses, `{name}_request_dto.dart` for request bodies.

## Shape

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'todo_dto.freezed.dart';
part 'todo_dto.g.dart';

@freezed
sealed class TodoDto with _$TodoDto {
  factory TodoDto({
    required String id,
    required String title,
    required bool completed,
  }) = _TodoDto;

  factory TodoDto.fromJson(Map<String, dynamic> json) =>
      _$TodoDtoFromJson(json);
}
```

- `@freezed sealed class` — the repo's freezed 3.x convention.
- Both `part` directives, in this order.
- `fromJson` factory always present, even on request-only DTOs (cheap, and mock interceptors need it).
- `build.yaml` sets `explicit_to_json: true` and `any_map: true` globally — nested DTOs serialise correctly and `Map<dynamic, dynamic>` payloads parse. Do not re-declare these per class.

## Fields

- **`required` only when the server always sends it.** A `required` field on an optional key throws at parse time on a payload you did not anticipate — a crash instead of a degraded screen.
- Optional → nullable (`String? avatarUrl`) or defaulted (`@Default(false) bool completed`). Prefer a default when the absence has an obvious meaning; prefer nullable when "absent" and "false" differ.
- Name mismatch → `@JsonKey(name: 'created_at') required DateTime createdAt`.
- Do not put computed values, formatting, or presentation logic in a DTO. Map to a feature model in `lib/features/{feature}/models/` if the UI needs a different shape.

## Enums

Annotate the values so an unknown server value does not crash the parse:

```dart
@JsonEnum(alwaysCreate: true)
enum TodoStatus {
  @JsonValue('open') open,
  @JsonValue('done') done,
  @JsonValue('archived') archived,
}
```

Where the server may add values, keep an `unknown` member and use `@JsonKey(unknownEnumValue: TodoStatus.unknown)` on the field.

## Paginated lists

Endpoints returning a page use the shared envelope rather than a bespoke wrapper:

```dart
@GET(_Paths.getTodos)
Future<ListResponseDto<TodoDto>> getTodos(@Query('page') int page);
```

See `packages/api/lib/src/models/list_response_entity/`. A single-resource endpoint returns the DTO directly — no envelope.

## Wire it up

1. Create `{name}_dto.dart` under the resource's `models/src/`.
2. Add it to `models/src/models.dart`.
3. Confirm `{resource}_provider.dart` exports `models/models.dart`, and `lib/api.dart` exports the provider barrel.
4. `melos run build` (or `melos exec --scope api -- "dart run build_runner build -d"`).
5. Never edit `*.freezed.dart` or `*.g.dart`.

## Checklist

- [ ] Under the owning resource's `models/src/`, named `*_dto.dart`
- [ ] `@freezed sealed class`, both `part` directives, `fromJson` factory
- [ ] `required` only for fields the server always sends; others nullable or defaulted
- [ ] Enums use `@JsonValue`, with an unknown fallback where the server may extend
- [ ] Exported through `models/src/models.dart` → `{resource}_provider.dart` → `lib/api.dart`
- [ ] `melos run build` run; generated files untouched
- [ ] A round-trip `fromJson`/`toJson` test exists for any non-trivial mapping
