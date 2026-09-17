# 7. DI Scopes and Constructor Injection

- Status: Accepted
- Date: 2026-05-08
- Deciders: Flutter team

## Context and Problem Statement

GetIt + Injectable gives several knobs: `@injectable`, `@singleton`, `@lazySingleton`, factory params, named registrations, environments. Without a rule, every author picks a different combination and the DI graph becomes inconsistent. Worse, code calling `getIt<T>()` from inside business classes turns DI into an ambient service locator, breaking testability.

We also need flavor-aware bindings — `dev` vs `prod` — without scattering `if (isDev)` throughout the app.

## Decision Drivers

- Testability — constructor injection makes a class testable with plain Dart fakes; service-locator calls require mocking the locator.
- Visible dependency graph — a class's dependencies are readable from its constructor without running the container.
- Predictable lifetimes — small set of scopes: per-resolution (`@injectable`), app-wide eager (`@singleton`), app-wide lazy (`@lazySingleton`).
- Flavor handling — env-specific bindings should be declarative, not branching at the call site.

## Considered Options

- **Constructor injection only, three injectable scopes (`@injectable`, `@singleton`, `@lazySingleton`), env via injectable environments**.
- **Service locator everywhere** — call `getIt<T>()` inside classes.
- **Riverpod / Provider tree only** — no GetIt.

## Decision Outcome

Chosen option: **Constructor injection, three injectable scopes (`@injectable`, `@singleton`, `@lazySingleton`), env-scoped bindings**.

### Scopes

- **`@injectable` is the default.** Use it for State classes, feature-scoped stores, use cases and stateless services such as [`IssueTrackingService`](../../lib/core/services/issue_tracking_service.dart). Every resolution returns a new instance, so a caller must not expect to share state with anything else that resolved the same type. State that has to be shared belongs in a `@singleton` store.
- **`@singleton`** is for app-wide stores (`AuthStore`, `HomeStore`, `NotificationsStore`, `ConnectivityStore`) and for long-lived services that must exist from startup: [`AppNavigator`](../../lib/core/navigation/app_navigator.dart) and [`FlavorService`](../../lib/core/services/flavor_service.dart). They are created when `configureDependencies` runs.
- **`@lazySingleton`** is for expensive long-lived services that are created on first use. Current example: [`DioService`](../../lib/core/services/dio_service.dart), which builds its `Dio` clients and interceptor chain in its constructor. It is not a safer default than `@singleton`. Use it only when eager construction would do work that nothing needs yet.
- **Use cases are never singletons.** A use case performs one operation ([ADR-0004](0004-use-case-taxonomy-and-colocation.md)). As a singleton it turns into a place to keep state that no store owns.

### Where `getIt` may be called

`getIt` is resolved in exactly two places:

1. **App bootstrap.** `main()` initialization ([`lib/main.dart`](../../lib/main.dart) reads `FlavorService` to configure Sentry), router setup and app-level flags in the app root ([`lib/app.dart`](../../lib/app.dart) reads `AppNavigator.config` and the debug-banner flag), splash, and the DI bootstrap itself in [`lib/injectable.dart`](../../lib/injectable.dart).
2. **`Provider(create: (_) => getIt<MyState>())` at page roots.** A modal or dialog that owns a state class counts as a page root. See [ADR-0009](0009-provider-based-state-access.md).

Everywhere else, dependencies arrive through the constructor. Never call `getIt<>()` inside a class. This includes objects the container does not build, such as Dio interceptors and route guards. They receive their dependencies from whoever constructs them: `DioService` passes `AuthStore` and `AppNavigator` into `AuthInterceptor`, and `AppNavigator` passes `AuthStore` into `AuthGuard`.

### Flavors

Flavor-specific bindings declare their environment by `FlavorType` name, for example `@Singleton(env: ['DEVELOPMENT'], as: FlavorService)` on `FlavorDev`. Bootstrap is [`configureDependencies(FlavorType)`](../../lib/injectable.dart), which passes the flavor name as the injectable `environment`. [`resetDependencies()`](../../lib/injectable.dart) tears down GetIt and re-registers under the current flavor. `AuthStore.clearSession()` calls it on logout so that every singleton starts fresh.

### Consequences

- Good: classes are unit-testable with plain constructor stubs; no `getIt` mocking.
- Good: each scope has one stated use and `@injectable` is the default, so choosing any other scope needs a reason a reviewer can check.
- Good: flavor differences declared at registration sites, not at consumption sites.
- Bad: large constructors when a class needs many collaborators (forces extraction).
- Bad: an `@injectable` type resolved in two places yields two instances. Code that assumes they share state is wrong without any error.
- Bad: developers learning the codebase must remember the two places `getIt` may be called.

## Pros and Cons of the Options

### Constructor injection, three scopes
- Good: testable; no ambient locator usage.
- Bad: long constructor parameter lists for collaborator-heavy classes.
- Bad: `@lazySingleton` vs `@singleton` is a judgement call. Without the rule above, one of them gets picked as "the safer default" for everything.

### Service locator everywhere
- Good: zero constructor noise.
- Bad: hidden dependencies; tests must mock the locator; refactors are silent.

### Riverpod / Provider tree only
- Good: scoped overrides per widget subtree.
- Bad: codebase migration cost; loses `injectable` codegen for non-widget classes (use cases, services).

## Links

- [ADR-0002 State vs Store separation](0002-state-vs-store-separation.md)
- [ADR-0004 Use-case taxonomy and colocation](0004-use-case-taxonomy-and-colocation.md)
- [ADR-0006 Feature-owned singletons](0006-feature-owned-singletons.md)
- [ADR-0009 Provider-based state access](0009-provider-based-state-access.md)
- Code: [lib/injectable.dart](../../lib/injectable.dart), [lib/core/services/get_it.dart](../../lib/core/services/get_it.dart)
