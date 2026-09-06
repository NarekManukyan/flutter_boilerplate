---
name: create-feature
description: Scaffold a new feature module in lib/features/ with the correct directory shape, store, state, page, use-case placement, DI registration, route, localization and tests. Use when adding any new screen-owning feature or promoting a sub-module to a peer feature.
---

# Create a feature module

Governed by [ADR-0001](../../../docs/adr/0001-layered-architecture.md) (layers), [ADR-0005](../../../docs/adr/0005-flat-feature-tree.md) (flat tree), [ADR-0006](../../../docs/adr/0006-feature-owned-singletons.md) (feature-owned stores).

## Decide the location first

Features are **peers** under a domain grouping. A feature must never contain a `features/` subdirectory.

```
❌ lib/features/meetings/meeting_details/features/ai_chat/
✅ lib/features/meetings/ai_chat/
✅ lib/features/meetings/meeting_details/
```

A pure view-layer sub-page with no store of its own may stay under the parent's `view/` (e.g. `meeting_details/view/share_meeting/`). The moment it gains its own store or state, promote it to a sibling.

Never create anything under `lib/shared/` — it is deprecated.

## Directory shape

Create only the directories the feature actually needs. A feature with no modals does not get a `modals/` folder.

```
lib/features/{feature}/
  view/
    {feature}_page.dart          @RoutePage widget — Provider root
    {feature}_page_state.dart    @injectable, MobX, no API access
    {feature}_keys.dart          widget keys used by Maestro flows
    widgets/                     private widgets for this page
    use_cases/                   UCs consumed only by view/state
  mobx/
    {feature}_store.dart         @injectable or @singleton, owns DioService
    use_cases/                   UCs consumed only by the store
  core/use_cases/                UCs consumed by 2+ layers of THIS feature
  models/                        feature-local models (not DTOs)
  modals/{modal}/                view/ + mobx/ + use_cases/ per modal
  components/                    widgets reused across this feature's pages
```

Mirror it in tests and flows:

```
test/features/{feature}/         unit tests (store, state, use cases)
test/features/{feature}/view/    widget tests
.maestro/flows/{feature}/        {feature}_happy.yaml | _failure.yaml | _edge.yaml
```

## Build order

Bottom-up, so each layer compiles against something real:

1. **DTOs + API provider** — only if the endpoint is new. [`create-dto`](../create-dto/SKILL.md), [`create-api-provider`](../create-api-provider/SKILL.md).
2. **Store** — [`create-store`](../create-store/SKILL.md). Owns `DioService`, exposes `@readonly` observables.
3. **Use cases** — [`create-use-case`](../create-use-case/SKILL.md). Place next to the consumer layer.
4. **Page state** — `@injectable`, injects the store, `AppNavigator`, use cases. No `DioService`.
5. **Page + widgets** — [`create-page`](../create-page/SKILL.md). `Provider` at the root, `context.read<T>()` below.
6. **Localization** — [`add-localization`](../add-localization/SKILL.md). Every visible string.
7. **Route** — register the `@RoutePage` in `lib/core/navigation/`, then `melos run build`.
8. **Codegen** — `melos run build` regenerates `*.g.dart` and `injectable.config.dart`.
9. **Tests + flows** — [`write-tests`](../write-tests/SKILL.md), [`write-maestro-flow`](../write-maestro-flow/SKILL.md).

## Route registration

The page carries `@RoutePage()`. After adding it, run `melos run build` so `*.gr.dart` picks it up, then add the route to the router config in `lib/core/navigation/`. Guards go in `lib/core/guards/`.

Never navigate from the page. The state class injects `AppNavigator` and the page calls a state method ([ADR-0008](../../../docs/adr/0008-appnavigator-routing-abstraction.md)).

## Definition of done

- [ ] Feature is a peer, not nested; nothing added to `lib/shared/`
- [ ] Store lives under `{feature}/mobx/` even if `@singleton`
- [ ] State has no `DioService`; page has no store and no `context.router`
- [ ] Every string via `LocaleKeys`; every colour/style via design-system tokens
- [ ] Interactive widgets carry keys from `{feature}_keys.dart` + `Semantics` labels
- [ ] `melos run build` run after annotation changes; no generated file edited by hand
- [ ] Unit + widget tests exist; Maestro happy / failure / edge flows exist
- [ ] `melos run verify` passes
