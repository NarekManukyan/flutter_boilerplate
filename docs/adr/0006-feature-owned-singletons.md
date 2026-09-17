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
- Incremental migration — deprecating a location should not force a big-bang move of every file in it.

## Considered Options

- **Feature-owned singletons** — singletons live under their owning feature's `mobx/`, scoped via `@singleton`.
- **`lib/shared/` for singletons** — top-level dir for app-wide stores.
- **`lib/core/state/` for singletons** — under `core/` next to services.
- **Top-level `lib/stores/`** — a dedicated directory for app-wide stores, separate from `lib/shared/`.

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

### Cross-cutting stores

A store used by many features still lives under the feature it most naturally belongs to: `AuthStore` is used everywhere but belongs to `auth/`. App-wide concerns with no natural owner live in the `app` feature ([`lib/features/app/mobx/`](../../lib/features/app/mobx/)). It exists for exactly that: connectivity, notifications and the app-update modal, without a `lib/shared/` directory. If one of those concerns grows enough to deserve its own feature, extract it to a dedicated feature at that point.

### Where reusable code goes

| Kind | Location |
|---|---|
| Store, any DI scope | `lib/features/{owning_feature}/mobx/` |
| Reusable state class | The owning feature's `view/` or `mobx/`, never a shared directory |
| Feature-agnostic state primitive (`LoadingState`) | [`lib/core/state/`](../../lib/core/state) — a small observable building block composed *into* screen states, with no feature logic and no dependencies. A class that knows about a feature is not a primitive and belongs to that feature. |
| Reusable widget | [`lib/core/ui/`](../../lib/core/ui) |
| Reusable model | `lib/core/models/` or the owning feature's `models/` |
| Cross-feature use case | [`lib/core/use_cases/`](../../lib/core/use_cases), per [ADR-0004](0004-use-case-taxonomy-and-colocation.md) |

`lib/shared/` is **deprecated** and not present in the current tree — do not add it back.

### Migration rule

Legacy files in a deprecated location keep working. Move them when you touch them, to the location in the table above. Never create new files in a deprecated location. This applies to projects created from this template that still carry a `lib/shared/`, and to any location a later ADR deprecates.

### Consequences

- Good: every store has an obvious owning feature.
- Good: new contributors find auth code in `features/auth/`, not in two places.
- Good: removing a feature removes its singleton with it.
- Bad: a store used heavily by every feature still nominally "belongs" to one feature (e.g. `AuthStore` in `auth/`).
- Bad: requires the `app/` feature as a home for genuinely cross-cutting concerns (connectivity, notifications) that don't belong to a domain feature.
- Bad: placing a cross-cutting store needs judgment; the tie-breaker is the most natural owning feature, then the `app` feature.
- Bad: during a migration the deprecated location and the target location coexist until every legacy file has been touched.

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

### Top-level `lib/stores/`
- Good: avoids the naming baggage of `shared`, and one listing shows every app-wide store.
- Bad: the same dumping-ground problem as `lib/shared/`, under a new name.
- Bad: separates a store from the feature that owns its state classes and use cases.

## Links

- [ADR-0001 Layered architecture](0001-layered-architecture.md)
- [ADR-0002 State vs Store separation](0002-state-vs-store-separation.md)
- [ADR-0005 Flat feature tree](0005-flat-feature-tree.md)
- [ADR-0007 DI scopes and constructor injection](0007-di-scopes-and-constructor-injection.md)
