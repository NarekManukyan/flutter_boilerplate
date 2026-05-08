# 6. Feature-Owned Singletons (no `lib/shared/`)

- Status: Accepted
- Date: 2026-05-08
- Deciders: Flutter team

## Context and Problem Statement

App-wide singletons — auth, connectivity, notifications — are long-lived and reachable from many features. The traditional Flutter habit puts them in a top-level `lib/shared/` (or `lib/global/`, `lib/common/`) directory because their *scope* is global.

That directory then becomes the dumping ground for "anything used by more than one feature": a few singletons, then some shared widgets, then orphaned models, then a `state/` dir for cross-cutting flags. Ownership becomes ambiguous; nobody owns "the shared dir".

## Decision Drivers

- Ownership — every store has one feature that conceptually owns it (auth code owns `AuthStore`).
- Scope ≠ location — singleton scope is a DI annotation, not a directory.
- Consistency — one rule for where stores live, regardless of lifetime.

## Considered Options

- **Feature-owned singletons** — singletons live under their owning feature's `mobx/`, scoped via `@singleton`.
- **`lib/shared/` for singletons** — top-level dir for app-wide stores.
- **`lib/core/state/` for singletons** — under `core/` next to services.

## Decision Outcome

Chosen option: **Feature-owned singletons**.

Every store, regardless of DI scope, lives at `lib/features/{owning_feature}/mobx/`. Lifetime is encoded in the annotation, not the path:

App-wide stores (per [ADR-0002](0002-state-vs-store-separation.md), `*_store.dart`):

| Store | Path | Annotation |
|---|---|---|
| [`AuthStore`](../../lib/features/auth/mobx/auth_store.dart) | `lib/features/auth/mobx/` | `@singleton` |
| [`HomeStore`](../../lib/features/home/mobx/home_store.dart) | `lib/features/home/mobx/` | `@singleton` |
| [`NotificationsStore`](../../lib/features/app/mobx/notifications_store.dart) | `lib/features/app/mobx/` | `@singleton` |
| [`ConnectivityStore`](../../lib/features/app/mobx/connectivity_store.dart) | `lib/features/app/mobx/` | `@singleton` |

`ConnectionWrapperState` (`lib/features/app/mobx/connection_wrapper_state.dart`) lives in the same directory but is `@injectable`, not a singleton — it is the connection-wrapper page's state class, included here to show that the `mobx/` directory holds both `*_store.dart` (app-wide) and `*_state.dart` for app-feature widgets.

The `lib/features/app/` feature exists specifically to own genuinely app-level concerns (connectivity, notifications, app-update modal) without a `lib/shared/` directory.

`lib/shared/` is **deprecated** and not present in the current tree — do not add it back. Existing widgets used cross-feature go in [`lib/core/ui/`](../../lib/core/ui); cross-feature models in [`lib/core/`](../../lib/core); cross-feature use cases in [`lib/core/use_cases/`](../../lib/core/use_cases).

### Consequences

- Good: every store has an obvious owning feature.
- Good: new contributors find auth code in `features/auth/`, not in two places.
- Good: removing a feature removes its singleton with it.
- Bad: a store used heavily by every feature still nominally "belongs" to one feature (e.g. `AuthStore` in `auth/`).
- Bad: requires the `app/` feature as a home for genuinely cross-cutting concerns (connectivity, notifications) that don't belong to a domain feature.

## Pros and Cons of the Options

### Feature-owned singletons
- Good: scope-vs-location decoupling; consistent placement rule.
- Bad: occasional "which feature owns this?" debates.

### `lib/shared/`
- Good: matches habit from many Flutter samples.
- Bad: becomes a dumping ground; ownership erodes.
- Bad: same store can plausibly live in `shared/` or `features/x/` — two valid paths.

### `lib/core/state/`
- Good: groups all singletons.
- Bad: `core/` is for framework-level concerns (services, navigation, DI bootstrap), not domain stores.
- Bad: separates a feature's store from its state classes and use cases.

## Links

- [ADR-0001 Layered architecture](0001-layered-architecture.md)
- [ADR-0002 State vs Store separation](0002-state-vs-store-separation.md)
- [ADR-0007 DI scopes and constructor injection](0007-di-scopes-and-constructor-injection.md)
