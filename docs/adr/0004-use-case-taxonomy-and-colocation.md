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

## Considered Options

- **Taxonomy + consumer-based colocation** — 4 UC types; placement follows the consumer layer; promote on second consumer.
- **All UCs in `lib/core/use_cases/`** — one flat directory.
- **No UC concept** — fold logic into stores or state directly.

## Decision Outcome

Chosen option: **Taxonomy + consumer-based colocation**.

### Four types

1. **API** — wraps one HTTP call, handles `DioException`. Example: [`CreateTodoUseCase`](../../lib/features/home/modals/add_todo_modal/use_cases/create_todo_use_case.dart).
2. **Navigation** — wraps `AppNavigator` calls (modals, routes). Example: [`ShowAddTodoModalUseCase`](../../lib/features/home/view/use_cases/show_add_todo_modal_use_case.dart).
3. **Service Coordination** — orchestrates 2+ services (HTTP + analytics + tracking).
4. **State Delegation** — conditional flow/guard logic invoked from multiple callers.

### Location rules

| Consumer | Path |
|---|---|
| Store only | `lib/features/{feature}/mobx/use_cases/` |
| State / View only | `lib/features/{feature}/view/use_cases/` |
| Modal only | `lib/features/{feature}/modals/{modal}/use_cases/` |
| Multiple layers within one feature | `lib/features/{feature}/core/use_cases/` |
| Multiple features | `lib/core/use_cases/` |

Promotion rule: gains a consumer in a different layer of the same feature → promote one level. Gains a consumer in a different feature → promote to [`lib/core/use_cases/`](../../lib/core/use_cases). Today's only cross-feature UC is [`OpenTodoDetailsUseCase`](../../lib/core/use_cases/open_todo_details_use_case.dart).

### Extract vs keep inline

Extract when the operation is reused in 2+ places, coordinates 2+ services, or is complex enough for its own test. Keep inline for trivial one-line delegation.

### Consequences

- Good: a UC's home matches the file that calls it — discovery is local.
- Good: promotion is rule-based, not taste-based.
- Good: `lib/core/use_cases/` stays small and intentional (cross-feature only).
- Bad: file moves on second-consumer promotion produce churn in git history.
- Bad: developers must classify before placing — easy to put a navigation UC in `view/use_cases/` when it's really used by a store.

## Pros and Cons of the Options

### Taxonomy + consumer-based colocation
- Good: locality and a deterministic promotion path.
- Bad: occasional file moves.

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
