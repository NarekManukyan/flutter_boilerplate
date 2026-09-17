---
name: create-use-case
description: Build a *_use_case.dart — what a use case may inject (services, never stores or other use cases), the four types, where to put it by consumer and when to promote it, return and error patterns, anti-patterns, and the extract-or-inline decision. Use when extracting an operation out of a store or state, or when deciding whether logic deserves its own class.
---

# Create a use case

Governed by [ADR-0001](../../../docs/adr/0001-layered-architecture.md) (access matrix), [ADR-0003](../../../docs/adr/0003-no-use-case-to-use-case-dependencies.md) (no UC → UC), [ADR-0004](../../../docs/adr/0004-use-case-taxonomy-and-colocation.md) (taxonomy + colocation), [ADR-0020](../../../docs/adr/0020-error-handling-and-issue-tracking.md) (errors).

A use case encapsulates **one** business operation: an `@injectable` class with one public method, `call()`, invoked with call syntax. It is short-lived and stateless — it performs the operation and is done.

```dart
@injectable
class CreateTodoUseCase {
  final DioService _dioService;
  final IssueTrackingService _issueTrackingService;

  CreateTodoUseCase(this._dioService, this._issueTrackingService);

  Future<TodoDto?> call(String title) async {
    try {
      return await _dioService.todosProvider.createTodo(
        todoCreateDto: TodoCreateRequestDto(title: title),
      );
    } on DioException catch (e, stackTrace) {
      _issueTrackingService.trackHandledError(
        e,
        stackTrace: stackTrace,
        handlingContext: 'create_todo',
      );
      return null;
    }
  }
}

// call site — no .call()
final todo = await _createTodoUseCase(title);
```

- Named as a verb phrase: `CreateTodoUseCase`, `FetchTodosUseCase`, `ShowAddTodoModalUseCase`.
- **Always `@injectable`, never `@singleton`.** It holds no state worth sharing.
- Constructor injection only — never `getIt<>()` inside.

## What a use case may inject

| May inject | Must not inject |
|---|---|
| `DioService`, `AppNavigator`, `IssueTrackingService`, platform / analytics / other services | **another use case** (ADR-0003) |
| | **a store** (ADR-0001) |

**Use cases consume services, not stores.** If a use case needs data a store holds, the caller passes it in as a parameter. If a store must change as a result, the use case *returns* the result and the caller applies it.

**Who calls a use case:** stores and states. **Never the UI** — a widget calls its state, the state calls the use case.

## The four types

| Type | Injects | Does |
|---|---|---|
| **API** | `DioService`, `IssueTrackingService` | an API call that more than one consumer needs, or whose response or error mapping is not trivial; returns a domain-friendly result |
| **Navigation** | `AppNavigator` (+ services for conditions) | shows a modal, pushes a route, guards an action |
| **Service coordination** | 2+ services | orchestrates a multi-service operation into one logical action |
| **State delegation** | often nothing | conditional flow, guard logic, or a **pure transform** of data the caller passes in |

A class that fits two types is placed by its **dominant responsibility**. If it genuinely does two jobs, it is two use cases. A reviewer should flag a category mismatch — API logic inside a navigation use case, for example.

```dart
// Navigation — conditional, reusable across states
@injectable
class ShowAddTodoModalUseCase {
  final AppNavigator _appNavigator;

  ShowAddTodoModalUseCase(this._appNavigator);

  Future<void> call() async {
    await _appNavigator.showModal(builder: (_) => const AddTodoModal());
  }
}

// State delegation — a pure transform; the store applies the result
@injectable
class ReplaceTodoUseCase {
  List<TodoDto> call(List<TodoDto> todos, TodoDto updated) {
    return [
      for (final todo in todos) todo.id == updated.id ? updated : todo,
    ];
  }
}
```

## Where it goes — by consumer, not by topic

| Consumed by | Path |
|---|---|
| One store only | `lib/features/{feature}/mobx/use_cases/` |
| One state / view only | `lib/features/{feature}/view/use_cases/` |
| One modal only | `lib/features/{feature}/modals/{modal}/use_cases/` |
| 2+ layers of the same feature | `lib/features/{feature}/core/use_cases/` |
| 2+ features | `lib/core/use_cases/` |

**Promote on the second consumer:**

```
mobx/use_cases/  ──→ {feature}/core/use_cases/   (gained a state consumer)
view/use_cases/  ──→ {feature}/core/use_cases/   (gained a store consumer)
{feature}/core/  ──→ lib/core/use_cases/         (gained a consumer in another feature)
```

Do not pre-promote "because it feels shared", and do not create a flat `lib/features/{feature}/use_cases/` — placement follows actual consumers.

## Composing use cases is the caller's job

A use case never calls another. When an operation needs two, the **store or state** orchestrates:

```dart
// ❌ use case calling use case
class CreateAndOpenTodoUseCase {
  final CreateTodoUseCase _createTodo;
  final OpenTodoDetailsUseCase _openTodoDetails;
}

// ✅ the state composes
@action
Future<void> onCreateAndOpen(String title) async {
  final todo = await _createTodoUseCase(title);
  if (todo != null) {
    await _openTodoDetailsUseCase(todo.id);
  }
}
```

If two operations must succeed together with shared error handling, extract that shared logic into a **service** and inject the service into both use cases. No exceptions.

## Return values

| Return | Example | Means |
|---|---|---|
| `Future<T?>` | `Future<TodoDto?>` | `null` is failure; the caller branches |
| `Future<List<T>>` | `Future<List<TodoDto>>` | empty on failure; the caller renders either way |
| `Future<void>` | navigation, fire-and-forget | nothing to branch on |
| `T` (sync) | `List<TodoDto>` | a pure transform |
| sealed result | `Future<CreateTodoResult>` | the caller must tell failure reasons apart |

Return domain-friendly types, not raw responses. Prefer `Future` over `Stream` — ongoing data is a store's job, a use case is one operation.

## Errors

Catch at the use-case boundary and **track before returning** — the full rules and the five patterns (return null, return empty, throw a domain exception, guard with callbacks, rethrow) are in [`handle-errors`](../handle-errors/SKILL.md). The short version:

- `DioException` never leaks to a state class unless the pattern is a deliberate rethrow.
- A use case whose failure value the caller renders uses `trackHandledError`.
- Never swallow silently. Never track and rethrow in the same `catch`.

## Extract or keep inline?

**API calls.** A store may call `DioService` inline for its own single request whose result it applies to its own observables: a load, a refresh, an optimistic mutation and its rollback ([`create-store`](../create-store/SKILL.md#inline-request-or-use-case)). Extract an API use case only when:
- another consumer needs the same call;
- the call coordinates several requests or services;
- response or error mapping is not trivial, such as translating server codes into domain exceptions.

"It makes an API call" is not a reason on its own — for a **store**. A **state** never touches `DioService` (ADR-0001), so a state that needs a request calls its store or, when no store owns that data, an API use case (`CreateTodoUseCase`, `FetchTodoUseCase`).

**Other logic: extract** when it is:
- reused in 2+ places;
- coordinating 2+ services;
- complex enough to deserve its own test;
- making the store or state method hard to read.

**Keep inline** when it is:
- a one-line delegation to a store or service — `await _authStore.login(email);` does not need a class;
- used once and straightforward;
- a class with zero logic, a pure pass-through.

## Anti-patterns

- ❌ **Use case injecting another use case** — the caller composes; shared logic becomes a service.
- ❌ **Use case injecting or mutating a store** — return the result, let the caller apply it.

  Illustrative: the todos provider in this repo has no delete endpoint. A plain delete would stay inline in the store; the use case below exists because it maps a status code.

  ```dart
  // ❌ the use case mutates the store
  class DeleteTodoUseCase {
    final HomeStore _homeStore;
    Future<void> call(String id) async {
      await _dioService.todosProvider.deleteTodo(id);
      _homeStore.removeTodo(id);
    }
  }

  // ✅ the use case only talks to the server, and returns or throws
  @injectable
  class DeleteTodoUseCase {
    DeleteTodoUseCase(this._dioService);

    final DioService _dioService;

    /// Throws on failure (pattern 5, rethrow): the store rolls back and the
    /// state tracks.
    Future<void> call(String id) async {
      try {
        await _dioService.todosProvider.deleteTodo(id);
      } on DioException catch (e) {
        // Not tracked: a 404 means it is already gone, which is the outcome
        // the user asked for.
        if (e.response?.statusCode == HttpStatus.notFound) {
          return;
        }
        rethrow;
      }
    }
  }

  // ✅ the store owns the list: it removes first, and puts the row back
  //    where it was if the call fails
  @action
  Future<void> deleteTodo(String id) async {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index == -1) {
      return;
    }
    final removed = _todos.removeAt(index);
    try {
      await _deleteTodoUseCase(id);
    } catch (_) {
      _todos.insert(min(index, _todos.length), removed);
      rethrow;
    }
  }
  ```

  The state that calls `deleteTodo` tracks with `trackIssue(…, context: 'delete_todo', message: …, notifyOnConnectivityError: true)` ([`handle-errors`](../handle-errors/SKILL.md#stores-restore-then-rethrow)).

- ❌ **Use case as a getter** — `GetCurrentUserUseCase` returning `_userStore.currentUser`. Read the store.
- ❌ **Use case called from a widget** — go through the state.
- ❌ **`@singleton` use case.**
- ❌ **Swallowing errors** — `catch (_) { return null; }` with no tracking.

## Decision flow

```
Business logic to place
├─ Trivial one-liner, no error handling?          → inline in the store / state
├─ A store's own single request, applied to its own observables
│  (load, refresh, optimistic mutation + rollback)? → inline in the store
├─ An API call that another consumer needs, that coordinates
│  several requests or services, or whose response or error
│  mapping is not trivial?                        → API use case
├─ Navigation, modal, or guard?                   → Navigation use case
├─ Coordinates 2+ services?                       → Service coordination use case
├─ Conditional / guard / transform used in 2+ places? → State delegation use case
└─ None of the above                              → inline
   then: place it by consumer (table above)
```

## Testing

Mock the **services** the use case injects, call it, assert the result and the tracking call on the failure path. Skip tests only for a pure pass-through with zero logic — and question whether it should exist.

When testing a store or state that consumes use cases, prefer mocking the services underneath over mocking the use cases, so the test exercises the real composition. Mock a use case only when its own setup would dominate the test.

## Checklist

- [ ] One operation, one `call()`, verb-phrase name
- [ ] `@injectable`, constructor injection only
- [ ] Injects services only — no store, no other use case
- [ ] Called from a store or state, never from a widget
- [ ] Placed next to its consumer; promoted only when a second consumer appears
- [ ] Every `catch` tracks through `IssueTrackingService` or rethrows — [`handle-errors`](../handle-errors/SKILL.md)
- [ ] `melos run build` after adding the annotation
- [ ] Unit test covers success and failure, including the tracking call — [`write-tests`](../write-tests/SKILL.md)
