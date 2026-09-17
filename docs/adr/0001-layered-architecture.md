# 1. Layered Architecture with Adjacent-Only Access

- Status: Accepted
- Date: 2026-05-08
- Deciders: Flutter team

## Context and Problem Statement

A Flutter app mixes presentation, business logic, navigation, persistence, and HTTP concerns. Without a clear seam between them, widgets reach into HTTP clients, business logic embeds widgets, and tests devolve into integration setups.

This boilerplate must give every feature a predictable shape so reviewers know where a change belongs and tests can mock at the seam closest to the unit under test.

## Decision Drivers

- Reviewability — a reader should know which layer is responsible for a behavior in seconds.
- Testability — UI tests should not require HTTP mocking; store tests should not require widget pumping.
- Replaceability — swap HTTP client, swap navigation lib, swap state lib, without rewriting feature code.
- Existing convention — the codebase already follows this layout; the ADR codifies it.

## Considered Options

- **Layered with adjacent-only access** (UI → State → Store → DioService → API Provider). Each layer talks only to its immediate neighbor.
- **Hexagonal / ports-and-adapters**. Domain core plus inward-pointing adapters for UI, HTTP, persistence.
- **Flat / pragmatic**. Widgets call API providers directly, no intermediate state class.
- **BLoC / Cubit**. One Bloc or Cubit per feature, with a repository per data source.
- **Riverpod**. Providers for both state and DI, with no separate State / Store distinction.
- **Provider plus an ad-hoc `ChangeNotifier` per feature**. No codegen and no DI container.

## Decision Outcome

Chosen option: **Layered with adjacent-only access**, using MobX for reactivity, Retrofit for the typed API layer and GetIt + injectable for DI.

The contract:

```
UI (page/widget) → State (*_state.dart) → Store (*_store.dart) → DioService → API Provider
                                       ↘ Use Case ↗
```

### Layer access matrix

| Layer | Files | May access | Must NOT access |
|---|---|---|---|
| UI | `*_page.dart`, `*_widget.dart` | State via `context.read<T>()` | `DioService`, Stores, Use Cases directly |
| State | `*_state.dart` | Stores, `AppNavigator`, Use Cases | `DioService` |
| Store | `*_store.dart` | `DioService`, other Stores, Use Cases | — |
| Use Case | `*_use_case.dart` | `DioService`, Services (including `IssueTrackingService`), `AppNavigator` | Other Use Cases ([ADR-0003](0003-no-use-case-to-use-case-dependencies.md)), Stores |
| Data | `packages/api` providers | DTOs (`*_dto.dart`) | App layers (UI, State, Store, Use Case) |

The layer of any file is identifiable from its filename suffix, so a reviewer can check an import against this matrix without opening the file.

Hard rules:

- UI never touches `DioService`, stores or use cases directly. It reads its `*_state.dart` via `context.read<T>()` ([ADR-0009](0009-provider-based-state-access.md)) and calls methods on that state. A button that opens a modal calls the state, and the state calls the navigation use case.
- Reactive UI goes through MobX `Observer` widgets that read observables exposed by the state class.
- State has no direct API access. It calls stores or use cases.
- Stores own API access via `DioService` and may collaborate with other stores. API use cases also reach the API through `DioService`; nothing else does.
- Use cases (`*_use_case.dart`) are an orthogonal seam between State/Store and services. They encapsulate one operation and may be invoked from State, Store, or a modal state, placed per [ADR-0004](0004-use-case-taxonomy-and-colocation.md).
- Use cases consume services, not stores. When a use case needs data a store holds, the caller (the State or Store) reads it and passes it in as a parameter.
- API providers live in `packages/api` and depend only on their DTOs. The package boundary means they cannot import app code.
- Any change to a MobX, Retrofit, Freezed or Injectable annotation needs the codegen step, `melos run build`, before the code analyzes or runs. Generated files are never edited by hand.

### Consequences

- Good: each layer has a short, fixed list of allowed collaborators, so dependency graphs stay shallow.
- Good: a wrong-layer import is visible in review from the file name and the import line alone.
- Good: tests target one layer at a time. State tests fake stores; store tests fake `DioService`; use case tests fake services and never need a store.
- Good: swapping HTTP, navigation, or state library is layer-local.
- Good: reactive rebuilds come from MobX `Observer`, with no manual diffing or `setState` plumbing for domain data.
- Bad: extra indirection for trivial features — a page that lists static data still gets a state class.
- Bad: developers learning the codebase must internalize five layer roles before shipping.
- Bad: annotation changes require a `build_runner` run; forgetting it produces analyzer errors about missing generated members.
- Bad: a use case that needs store data gets it as a parameter, so call sites are slightly longer than injecting the store would be.

## Pros and Cons of the Options

### Layered with adjacent-only access
- Good: matches existing code; predictable for review.
- Good: clean unit-test seams.
- Bad: ceremony for trivial screens.

### Hexagonal / ports-and-adapters
- Good: maximum decoupling of domain from frameworks.
- Bad: overkill for a Flutter UI app — domain logic is thin, most code is presentation + IO.
- Bad: introduces ports/adapters/domain entities that duplicate DTOs.

### Flat / pragmatic
- Good: fastest to write a screen.
- Bad: widgets become untestable without HTTP setup.
- Bad: business logic spreads across `build()` methods and ad-hoc helpers.

### BLoC / Cubit
- Good: widely used and well documented, so many Flutter hires already know it.
- Good: Bloc's explicit events make every state transition traceable.
- Bad: event and state classes add more boilerplate than MobX. Cubit reduces it, but derived state is still less ergonomic than `@computed`.
- Bad: adopting it means rewriting every store and state class and dropping `mobx_codegen`.

### Riverpod
- Good: compile-time safe DI and scoping, with less codegen ceremony than injectable.
- Bad: requires a full rewrite of state management and DI.
- Bad: any provider can read any other provider, which blurs the layer boundaries this ADR exists to enforce.

### Provider plus an ad-hoc `ChangeNotifier` per feature
- Good: the simplest setup; no codegen, and `provider` is already a dependency.
- Bad: no DI scoping and no layer enforcement, so each feature invents its own structure.
- Bad: every change needs a manual `notifyListeners()` call, a missed call is a silent stale-UI bug, and there is no equivalent of `@computed`.

## Links

- [ADR-0002 State vs Store separation](0002-state-vs-store-separation.md)
- [ADR-0003 No use-case → use-case dependencies](0003-no-use-case-to-use-case-dependencies.md)
- [ADR-0004 Use case taxonomy and colocation](0004-use-case-taxonomy-and-colocation.md)
- [ADR-0007 DI scopes and constructor injection](0007-di-scopes-and-constructor-injection.md)
- [ADR-0009 Provider-based state access](0009-provider-based-state-access.md)
- [ADR-0011 Retrofit + freezed typed API layer](0011-retrofit-typed-api-layer.md)
- Code: [lib/core/services/dio_service.dart](../../lib/core/services/dio_service.dart), [lib/core/services/issue_tracking_service.dart](../../lib/core/services/issue_tracking_service.dart), [lib/core/navigation/app_navigator.dart](../../lib/core/navigation/app_navigator.dart), [packages/api](../../packages/api)
