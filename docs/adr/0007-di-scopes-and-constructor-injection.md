# 7. DI Scopes and Constructor Injection

- Status: Accepted
- Date: 2026-05-08
- Deciders: Flutter team

## Context and Problem Statement

GetIt + Injectable gives several knobs: `@injectable`, `@singleton`, `@lazySingleton`, factory params, named registrations, environments. Without a rule, every author picks a different combination and the DI graph becomes inconsistent. Worse, code calling `getIt<T>()` from inside business classes turns DI into an ambient service locator, breaking testability.

We also need flavor-aware bindings — `dev` vs `prod` — without scattering `if (isDev)` throughout the app.

## Decision Drivers

- Testability — constructor injection makes a class testable with plain Dart fakes; service-locator calls require mocking the locator.
- Predictable lifetimes — small set of scopes: per-resolution (`@injectable`), app-wide eager (`@singleton`), app-wide lazy (`@lazySingleton`).
- Flavor handling — env-specific bindings should be declarative, not branching at the call site.

## Considered Options

- **Constructor injection only, three injectable scopes (`@injectable`, `@singleton`, `@lazySingleton`), env via injectable environments**.
- **Service locator everywhere** — call `getIt<T>()` inside classes.
- **Riverpod / Provider tree only** — no GetIt.

## Decision Outcome

Chosen option: **Constructor injection, three injectable scopes (`@injectable`, `@singleton`, `@lazySingleton`), env-scoped bindings**.

Rules:

- `@injectable` for State classes, feature stores, use cases — new instance on resolution.
- `@singleton` for app-wide stores (`AuthStore`, `HomeStore`, `NotificationsStore`, `ConnectivityStore`) and for [`AppNavigator`](../../lib/core/navigation/app_navigator.dart) — eagerly registered at startup.
- `@lazySingleton` for app-wide services that are expensive or rarely used and acceptable to construct on first resolution. Current example: [`DioService`](../../lib/core/services/dio_service.dart). Prefer `@singleton` by default; reach for `@lazySingleton` only when eager construction is wasteful.
- Always inject via constructor. Never call `getIt<>()` inside a class — except at the Widget→State boundary inside `Provider(create:)`, which is the one allowed seam (see [ADR-0009](0009-provider-based-state-access.md)).
- Flavor-specific bindings annotated with `@dev` / `@prod`. Bootstrap is [`configureDependencies(FlavorType)`](../../lib/injectable.dart) which passes the flavor name as the injectable `environment`. [`resetDependencies()`](../../lib/injectable.dart) tears down GetIt and re-registers under the current flavor — used when the user switches environment at runtime.

### Consequences

- Good: classes are unit-testable with plain constructor stubs; no `getIt` mocking.
- Good: two scopes only — readers don't have to reason about lazy vs eager singletons.
- Good: flavor differences declared at registration sites, not at consumption sites.
- Bad: large constructors when a class needs many collaborators (forces extraction).
- Bad: developers learning the codebase must remember the one allowed `getIt<>()` site (`Provider(create:)`).

## Pros and Cons of the Options

### Constructor injection, three scopes
- Good: testable; no ambient locator usage.
- Bad: long constructor parameter lists for collaborator-heavy classes.
- Bad: `@lazySingleton` vs `@singleton` is a judgement call — gets misused as "the safer default" until startup time regresses.

### Service locator everywhere
- Good: zero constructor noise.
- Bad: hidden dependencies; tests must mock the locator; refactors are silent.

### Riverpod / Provider tree only
- Good: scoped overrides per widget subtree.
- Bad: codebase migration cost; loses `injectable` codegen for non-widget classes (use cases, services).

## Links

- [ADR-0002 State vs Store separation](0002-state-vs-store-separation.md)
- [ADR-0006 Feature-owned singletons](0006-feature-owned-singletons.md)
- [ADR-0009 Provider-based state access](0009-provider-based-state-access.md)
- Code: [lib/injectable.dart](../../lib/injectable.dart), [lib/core/services/get_it.dart](../../lib/core/services/get_it.dart)
