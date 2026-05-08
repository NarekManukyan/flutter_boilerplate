# 2. State vs Store Separation

- Status: Accepted
- Date: 2026-05-08
- Deciders: Flutter team

## Context and Problem Statement

MobX gives a single primitive (a class with `@observable` / `@action`) for both screen-local UI state and app-wide cross-feature state. Conflating those two roles produces stores that own modal flags, animation timers, navigation calls, and HTTP at the same time.

We need a rule that tells a reader, at a glance, whether a class is a *page controller* or a *domain store*, and tells the writer where API access is allowed.

## Decision Drivers

- Lifetime mismatch — page state is short-lived (one route entry); domain data is app-wide.
- API ownership — only one layer should own HTTP for a given resource, to keep caching and error handling consistent.
- Testability — page-state tests should fake stores, not `Dio`.

## Considered Options

- **Two distinct types** — `*_state.dart` (per-page, no API) vs `*_store.dart` (feature/app-wide, owns API).
- **Single MobX class per feature** — one store does both jobs.
- **Riverpod-style providers** — replace MobX entirely.

## Decision Outcome

Chosen option: **Two distinct types**.

| | `*_state.dart` | `*_store.dart` |
|---|---|---|
| Purpose | Per-page/modal UI state | Feature or app-wide domain data |
| API access | No — calls stores or use cases | Yes — injects `DioService` |
| DI | `@injectable` | `@injectable` (feature) or `@singleton` (app-wide) |
| Location | `features/{f}/view/` or `features/{f}/modals/{m}/mobx/` | `features/{f}/mobx/` |
| Lifetime | One screen entry | Bound to feature container or app |

Rationale: an `AuthStore` outlives every login screen; a `LoginPageState` dies when the user navigates away. Putting both in the same class forces one of the two lifetimes to leak.

`@readonly` private fields auto-generate the public getter — never hand-write a `@computed` mirror for them. `@computed` is reserved for *derived* state.

### Consequences

- Good: API ownership is concentrated in stores; pages can be tested without HTTP.
- Good: singletons stay small (no per-screen flags pollute them).
- Good: a quick filename glance reveals the role.
- Bad: features with one screen still produce two MobX classes.
- Bad: requires discipline to resist adding `Dio` to a state class "just this once".

## Pros and Cons of the Options

### Two distinct types
- Good: clear API ownership and lifetime separation.
- Bad: more files per feature.

### Single MobX class per feature
- Good: fewer files.
- Bad: page-local flags leak into the singleton; tests pull HTTP into UI specs.
- Bad: lifetime ambiguity — when does a singleton's "page state" reset?

### Riverpod-style providers
- Good: built-in scoping.
- Bad: codebase-wide migration off MobX; loses code-gen integration with `mobx_codegen`.
- Bad: introduces a second reactive primitive next to existing MobX.

## Links

- [ADR-0001 Layered architecture](0001-layered-architecture.md)
- [ADR-0006 Feature-owned singletons](0006-feature-owned-singletons.md)
- [ADR-0007 DI scopes and constructor injection](0007-di-scopes-and-constructor-injection.md)
- Code: [lib/features/auth/mobx/auth_store.dart](../../lib/features/auth/mobx/auth_store.dart), [lib/features/home/view/home_page_state.dart](../../lib/features/home/view/home_page_state.dart)
