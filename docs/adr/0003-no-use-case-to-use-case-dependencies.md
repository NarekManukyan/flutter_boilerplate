# 3. Use Cases Never Depend on Other Use Cases

- Status: Accepted
- Date: 2026-05-08
- Deciders: Flutter team

## Context and Problem Statement

Use cases (`*_use_case.dart`) are single-operation classes invoked from State, Store, or modal-state. As features grow, the temptation appears to compose them: `CopyNotesUseCase` injects `CopyUseCase` to avoid duplicating clipboard logic.

That introduces a graph of UC → UC dependencies, which: (1) makes test setup recursive (every UC test stubs N other UCs), (2) hides the real seam (a `Service` or utility), and (3) creates implicit ordering across UCs that aren't explicitly co-located.

## Decision Drivers

- Test setup cost — UCs should fake their *services*, not their *peers*.
- Single responsibility — a UC is one operation; if it needs a peer, the peer is the operation, not a sub-step.
- Discoverability — shared logic should live in an obviously-shared place (`Service`, utility, extension), not behind another UC name.

## Considered Options

- **Forbid UC → UC** — UC depends only on services, navigators, and stores. Shared logic lives in a service or utility.
- **Allow shallow UC composition** — a UC may inject one UC, but no deeper.
- **Allow free composition** — UCs form a free DAG.

## Decision Outcome

Chosen option: **Forbid UC → UC**.

A use case may inject:
- `DioService` and any feature/app store
- `AppNavigator`
- Any `*_service.dart` (e.g. `IssueTrackingService`, `FlavorService`)

It must not inject another `*_use_case.dart`. When two UCs share logic, extract that logic to a service or top-level utility.

Example — `CreateTodoUseCase` ([lib/features/home/modals/add_todo_modal/use_cases/create_todo_use_case.dart](../../lib/features/home/modals/add_todo_modal/use_cases/create_todo_use_case.dart)) takes only `DioService`. Adding clipboard support would not inject a `CopyUseCase`; it would inject a `ClipboardService`.

### Consequences

- Good: UC tests are flat — fake the services, call `useCase()`, assert.
- Good: shared logic surfaces as a named service, not hidden behind a UC's `call()`.
- Good: dependency graph stays a tree of UC → service, not a DAG of UC → UC → UC.
- Bad: occasional duplication when two UCs would naturally share a single service-less helper.
- Bad: requires extracting a service for what could have been a 3-line UC reuse.

## Pros and Cons of the Options

### Forbid UC → UC
- Good: flat test setup; explicit shared seams.
- Bad: occasional small extractions.

### Allow shallow UC composition
- Good: convenient for small reuse.
- Bad: "shallow" decays — once allowed, the depth limit drifts.
- Bad: still inverts the rule that shared logic is a *service*, not a *use case*.

### Allow free composition
- Good: maximum reuse.
- Bad: tests become recursive mock setups.
- Bad: cycles become possible; UC ordering becomes implicit.

## Links

- [ADR-0001 Layered architecture](0001-layered-architecture.md)
- [ADR-0004 Use case taxonomy and colocation](0004-use-case-taxonomy-and-colocation.md)
- [ADR-0007 DI scopes and constructor injection](0007-di-scopes-and-constructor-injection.md)
