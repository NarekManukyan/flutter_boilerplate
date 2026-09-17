# 4. Use Case Taxonomy and Colocation by Consumer

- Status: Accepted
- Date: 2026-05-08
- Deciders: Flutter team

## Context and Problem Statement

Use cases proliferate. Without a taxonomy, every "thing that does something" becomes a `*_use_case.dart`, including trivial one-liners that belong inline. Without a placement rule, they pile into `lib/core/use_cases/` regardless of who consumes them, producing a directory disconnected from feature code.

We need (a) when to extract a UC at all, (b) what kinds of UC exist, and (c) where each one lives.

## Decision Drivers

- Locality — a UC consumed by one state class should live next to that state class.
- Promotion clarity — when a UC gains a second consumer, the move should be mechanical.
- Test cohesion — tests live near the code, so the UC's home directory is also the test's home directory.
- Shared vocabulary — a UC's type should say what it is allowed to inject and do, so a review can name a mismatch instead of arguing taste.

## Considered Options

- **Taxonomy + consumer-based colocation** — 4 UC types; placement follows the consumer layer; promote on second consumer.
- **All UCs in `lib/features/{feature}/use_cases/`** — one directory per feature, regardless of consumer.
- **All UCs in `lib/core/use_cases/`** — one flat directory.
- **No UC concept** — fold logic into stores or state directly.

## Decision Outcome

Chosen option: **Taxonomy + consumer-based colocation**.

### Four types

| Type | Injects | Does | Example |
|---|---|---|---|
| **API** | `DioService`, `IssueTrackingService` | Wraps one API call, catches its failures (everything, not only `DioException`), returns a domain-friendly result (a DTO, `null`, a bool or a sealed result) | [`CreateTodoUseCase`](../../lib/features/home/modals/add_todo_modal/use_cases/create_todo_use_case.dart) |
| **Navigation** | `AppNavigator` (+ optional services for conditions) | Wraps `AppNavigator` calls: modals, routes, guards | [`ShowAddTodoModalUseCase`](../../lib/features/home/view/use_cases/show_add_todo_modal_use_case.dart) |
| **Service coordination** | 2+ services | Orchestrates a multi-service operation (e.g. HTTP + analytics + issue tracking) | — |
| **State delegation** | Often nothing | Conditional flow, guard logic, or a pure transform of data the caller passes in (e.g. returning an updated list) | — |

A State delegation use case does not inject a store and does not mutate one. It takes what it needs as parameters and returns a value; the calling Store or State applies the result ([ADR-0003](0003-no-use-case-to-use-case-dependencies.md)). A guard that redirects through `AppNavigator` is Navigation; a check that only returns a decision to the caller is State delegation.

A use case that fits two types is classified by its dominant responsibility. The taxonomy lets reviewers flag category mismatches, such as API logic inside a Navigation use case or a State delegation use case that injects `DioService`.

Use cases are always `@injectable`, never `@singleton` or `@lazySingleton` ([ADR-0007](0007-di-scopes-and-constructor-injection.md)). They hold no state, so a new instance per resolution is cheap and cannot carry data from one caller to the next.

### Location rules

| Consumer | Path |
|---|---|
| Store only | `lib/features/{feature}/mobx/use_cases/` |
| State / View only | `lib/features/{feature}/view/use_cases/` |
| Modal only | `lib/features/{feature}/modals/{modal}/use_cases/` |
| Multiple layers within one feature | `lib/features/{feature}/core/use_cases/` |
| Multiple features | `lib/core/use_cases/` |

Promotion rule: gains a consumer in a different layer of the same feature → promote one level. Gains a consumer in a different feature → promote to [`lib/core/use_cases/`](../../lib/core/use_cases). [`OpenTodoDetailsUseCase`](../../lib/core/use_cases/open_todo_details_use_case.dart) sits there to illustrate the path, but it is not a real cross-feature case: its only consumer is `HomePageState`, so by these rules it would live in `lib/features/home/view/use_cases/`.

### Extract vs keep inline

Extract when the operation is reused in 2+ places, coordinates 2+ services, or is complex enough for its own test. Keep inline for trivial one-line delegation.

### Consequences

- Good: a UC's home matches the file that calls it — discovery is local.
- Good: promotion is rule-based, not taste-based.
- Good: `lib/core/use_cases/` stays small and intentional (cross-feature only).
- Good: the type vocabulary turns "this UC does too much" into a concrete review comment.
- Bad: file moves on second-consumer promotion produce churn in git history.
- Bad: developers must classify before placing — easy to put a navigation UC in `view/use_cases/` when it's really used by a store.
- Bad: a UC that straddles two types needs a judgment call about its dominant responsibility.

## Pros and Cons of the Options

### Taxonomy + consumer-based colocation
- Good: locality and a deterministic promotion path.
- Good: scope is visible from the path, without grepping for callers.
- Bad: occasional file moves.

### All UCs in `lib/features/{feature}/use_cases/`
- Good: simpler; one directory to look in per feature.
- Bad: muddles store-only and cross-layer use cases, so the path no longer says who may call a UC.
- Bad: nothing in the layout prevents cross-feature reach; another feature can import from the directory without triggering a promotion.

### All UCs in `lib/core/use_cases/`
- Good: one place to look.
- Bad: directory grows unbounded; tests detach from the feature they cover; reuse appears artificially common.

### No UC concept
- Good: fewer files.
- Bad: stores and states bloat with cross-cutting concerns (HTTP error handling, modal coordination) that have no natural home in either.

## Links

- [ADR-0001 Layered architecture](0001-layered-architecture.md)
- [ADR-0003 No use-case → use-case dependencies](0003-no-use-case-to-use-case-dependencies.md)
- [ADR-0005 Flat feature tree](0005-flat-feature-tree.md)
- [ADR-0007 DI scopes and constructor injection](0007-di-scopes-and-constructor-injection.md)
