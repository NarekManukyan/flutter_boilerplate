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
- Composition belongs to the caller — the Store or State that owns a flow decides which operations run and in what order.

## Considered Options

- **Forbid UC → UC** — UC depends only on services (`DioService`, `AppNavigator`, `IssueTrackingService`, platform and analytics services). Shared logic lives in a service or utility.
- **Allow shallow UC composition** — a UC may inject one UC, but no deeper.
- **Allow free composition** — UCs form a free DAG.

## Decision Outcome

Chosen option: **Forbid UC → UC**.

A use case depends only on services:
- `DioService`
- `AppNavigator`
- `IssueTrackingService`
- platform and analytics services, i.e. any other `*_service.dart` (e.g. `FlavorService`)

It must not inject another `*_use_case.dart`, and it must not inject a store. Use cases consume services, not stores ([ADR-0001](0001-layered-architecture.md)). When a use case needs data a store holds, the caller reads the store and passes the value in as a parameter.

Composing several use cases is the caller's job. When a flow needs more than one operation, the Store or State that owns the flow calls the use cases in order and handles what happens between them. A use case never calls another use case to build a larger operation.

When two operations must succeed together with shared error handling, extract the shared logic into a service and inject that service into both use cases. There are no exceptions, including one level of composition.

```dart
// FORBIDDEN: a use case injects another use case
@injectable
class ArchiveNoteUseCase {
  final ExportUseCase _exportUseCase;

  ArchiveNoteUseCase(this._exportUseCase);
}

// CORRECT: a use case injects services only
@injectable
class ArchiveNoteUseCase {
  final DioService _dioService;
  final IssueTrackingService _issueTrackingService;

  ArchiveNoteUseCase(this._dioService, this._issueTrackingService);
}
```

Example — `CreateTodoUseCase` ([lib/features/home/modals/add_todo_modal/use_cases/create_todo_use_case.dart](../../lib/features/home/modals/add_todo_modal/use_cases/create_todo_use_case.dart)) takes only `DioService` and `IssueTrackingService`. Adding clipboard support would not inject a `CopyUseCase`; it would inject a `ClipboardService`.

### Consequences

- Good: UC tests are flat — fake the services, call `useCase()`, assert.
- Good: shared logic surfaces as a named service, not hidden behind a UC's `call()`.
- Good: dependency graph stays a tree of UC → service, not a DAG of UC → UC → UC.
- Good: removing or renaming a use case affects only its direct callers.
- Good: UC tests never construct or fake a store.
- Bad: occasional duplication when two UCs would naturally share a single service-less helper.
- Bad: requires extracting a service for what could have been a 3-line UC reuse.
- Bad: the Store or State orchestrates multi-step flows itself, so that sequencing lives in the caller rather than in one reusable class.
- Bad: store data a use case needs arrives as a parameter, which makes some call sites longer.

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
