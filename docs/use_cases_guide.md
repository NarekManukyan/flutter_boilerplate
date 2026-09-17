# Use Cases Guide

A use case is how this boilerplate packages one operation: a small `@injectable` class with a `call()` method, injected into the state or store that needs it. This guide explains the idea using the use cases that exist in `lib/`. The rules are in [ADR-0003](adr/0003-no-use-case-to-use-case-dependencies.md) and [ADR-0004](adr/0004-use-case-taxonomy-and-colocation.md). The step-by-step build is the [`create-use-case`](../.claude/skills/create-use-case/SKILL.md) playbook.

## Table of contents

- [What is a use case?](#what-is-a-use-case)
- [Why use cases exist](#why-use-cases-exist)
- [The 4 types of use cases](#the-4-types-of-use-cases)
- [Where to place use cases](#where-to-place-use-cases)
- [How use cases work](#how-use-cases-work)
- [Inline store request or API use case?](#inline-store-request-or-api-use-case)
- [Anti-patterns](#anti-patterns)
- [More information](#more-information)

## What is a use case?

A use case wraps one operation (an API call, a navigation, a decision) behind a `call()` method, so the caller invokes it like a function. `ShowAddTodoModalUseCase` opens the add-todo sheet:

```dart
@injectable
class ShowAddTodoModalUseCase {
  final AppNavigator _appNavigator;

  ShowAddTodoModalUseCase(this._appNavigator);

  Future<void> call() async {
    await _appNavigator.showModal(builder: (_) => const AddTodoModal());
  }
}

// HomePageState.onAddTodoPressed: call syntax, no `.call()`
await _showAddTodoModalUseCase();
```

Source: [`lib/features/home/view/use_cases/show_add_todo_modal_use_case.dart`](../lib/features/home/view/use_cases/show_add_todo_modal_use_case.dart).

A use case holds no state. It runs, returns and is done. That is the difference from a service: `DioService` and `AppNavigator` are long-lived and shared, while a use case is created per resolution and does one thing.

## Why use cases exist

1. **Layer boundaries.** A state never touches `DioService` ([ADR-0001](adr/0001-layered-architecture.md)). When a state needs a request and no store owns that data, a use case is the way in. No store holds a single todo, so `TodoDetailsPageState` calls `FetchTodoUseCase`.
2. **Readable states and stores.** Error tracking, response mapping and modal wiring live in a named class instead of an `@action` body.
3. **Reuse.** Two callers inject one class instead of copying the logic.
4. **Testing.** A use case is a plain class. Construct it with mocked services, call it, assert. A state test mocks the use case and checks what the state does with the result ([`home_page_state_test.dart`](../test/features/home/view/home_page_state_test.dart)).
5. **Review vocabulary.** Each type says what a use case may inject, so "this navigation use case makes a request" becomes a concrete review comment.

## The 4 types of use cases

| Type | Injects | In this repo |
|---|---|---|
| API | `DioService`, `IssueTrackingService` | `CreateTodoUseCase`, `FetchTodoUseCase` |
| Navigation | `AppNavigator` (+ services for conditions) | `ShowAddTodoModalUseCase`, `OpenTodoDetailsUseCase` |
| Service coordination | 2+ services | none yet |
| State delegation | often nothing | none yet |

A class that fits two types is classified by its dominant responsibility. If it really does two jobs, it is two use cases.

### Type 1: API

One API call, its error handling, and a result the caller can branch on. `CreateTodoUseCase` returns the created `TodoDto`, or `null` after tracking the failure:

```dart
Future<TodoDto?> call(String title) async {
  try {
    return await _dioService.todosProvider.createTodo(
      todoCreateDto: TodoCreateRequestDto(title: title),
    );
  } catch (e, stackTrace) {
    _issueTrackingService.trackHandledError(
      e,
      stackTrace: stackTrace,
      handlingContext: 'create_todo',
    );
    return null;
  }
}
```

It catches everything, not only `DioException`: the generated Retrofit client rethrows a response that fails `fromJson` unchanged, and the caller still needs its `null`. It uses `trackHandledError` because its caller, `AddTodoModalState`, shows its own error text when it gets `null`. How to pick the tracking method is in [error-handling-guidelines.md](error-handling-guidelines.md).

`FetchTodoUseCase` has the same shape. It loads the list, picks the todo by id, and returns `null` both when the id is missing and when the request fails, because the details page shows one error state for both.

### Type 2: Navigation

Wraps `AppNavigator`: a modal, a route push, a guard. `ShowAddTodoModalUseCase` above is one. `OpenTodoDetailsUseCase` is the other:

```dart
Future<void> call(String id) async {
  await _appNavigator.push(TodoDetailsRoute(todoId: id));
}
```

`HomePage` passes `state.onTodoTap` to the list, and `HomePageState.onTodoTap` calls `_openTodoDetailsUseCase(id)`. The page never sees `AppNavigator` or the route ([ADR-0008](adr/0008-appnavigator-routing-abstraction.md)).

### Type 3: Service coordination

One logical operation across two or more services, such as a request plus analytics plus tracking. Illustrative: the repo has no analytics service, so `AnalyticsService` does not exist.

```dart
@injectable
class CreateTodoAndLogUseCase {
  final DioService _dioService;
  final AnalyticsService _analyticsService;

  CreateTodoAndLogUseCase(this._dioService, this._analyticsService);

  /// Throws on failure (the rethrow pattern): the calling state tracks it.
  Future<TodoDto> call(String title) async {
    final todo = await _dioService.todosProvider.createTodo(
      todoCreateDto: TodoCreateRequestDto(title: title),
    );
    _analyticsService.logEvent('todo_created');
    return todo;
  }
}
```

It injects the services directly, not `CreateTodoUseCase` ([ADR-0003](adr/0003-no-use-case-to-use-case-dependencies.md)).

### Type 4: State delegation

A decision, or a pure transform of data the caller passes in. It injects no store and mutates none: it returns a value, and the caller applies it. Illustrative, taken from the playbook:

```dart
@injectable
class ReplaceTodoUseCase {
  List<TodoDto> call(List<TodoDto> todos, TodoDto updated) {
    return [
      for (final todo in todos)
        if (todo.id == updated.id) updated else todo,
    ];
  }
}
```

Extract one only when two callers need it or it deserves its own test. Otherwise keep the logic inline ([ADR-0004](adr/0004-use-case-taxonomy-and-colocation.md#extract-vs-keep-inline)).

## Where to place use cases

Next to the consumer, not by topic:

| Consumed by | Path | In this repo |
|---|---|---|
| One store | `lib/features/{feature}/mobx/use_cases/` | none yet |
| One state or view | `lib/features/{feature}/view/use_cases/` | `ShowAddTodoModalUseCase` (home), `FetchTodoUseCase` (todo_details) |
| One modal | `lib/features/{feature}/modals/{modal}/use_cases/` | `CreateTodoUseCase` (home, `add_todo_modal`) |
| 2+ layers of one feature | `lib/features/{feature}/core/use_cases/` | none yet |
| 2+ features | `lib/core/use_cases/` | `OpenTodoDetailsUseCase`, placed here to illustrate the path |

The path tells a reviewer who may call a use case without a search. `CreateTodoUseCase` sits under `add_todo_modal/` because only `AddTodoModalState` calls it. `OpenTodoDetailsUseCase` is the exception: its only consumer is `HomePageState`, so by this rule it would live in `home/view/use_cases/`. It stays in `lib/core/use_cases/` as the template's example of that folder.

### Promotion

Move a use case when it gains a consumer, not before:

```
mobx/use_cases/  ──→ {feature}/core/use_cases/   gained a state consumer
view/use_cases/  ──→ {feature}/core/use_cases/   gained a store consumer
{feature}/core/  ──→ lib/core/use_cases/         gained a consumer in another feature
```

If `HomePageState` also created todos, `CreateTodoUseCase` would move to `lib/features/home/core/use_cases/`. Move its test to the mirrored path under `test/`, and run `melos run build` so `injectable.config.dart` imports the new location.

## How use cases work

### Dependency injection

A use case is always `@injectable`, never `@singleton` or `@lazySingleton`, so every resolution gets a new instance ([ADR-0007](adr/0007-di-scopes-and-constructor-injection.md)). Its dependencies come through the constructor, never from `getIt<>()`. It may inject `DioService`, `AppNavigator`, `IssueTrackingService` and other `*_service.dart` classes, but never a store and never another use case.

The consumer receives it the same way: `HomePageState` takes `OpenTodoDetailsUseCase` and `ShowAddTodoModalUseCase` as constructor parameters, next to `HomeStore` and `AppNavigator`. After adding, renaming or moving a use case, run `melos run build` to regenerate `lib/injectable.config.dart`.

### Calling conventions

- The one public method is `call()`, invoked with call syntax: `await _createTodoUseCase(title)`, `await _showAddTodoModalUseCase()`.
- The field is private and final, named after the class: `_fetchTodoUseCase`.
- Only states and stores call use cases. A widget calls its state, and the state calls the use case.
- In a mocktail test, stub a zero-argument use case through its tear-off: `when(showAddTodoModal.call).thenAnswer((_) async {})`.

### Return values

A use case returns something the caller can act on, not a raw response:

| Return | In this repo | The caller |
|---|---|---|
| `Future<T?>` | `CreateTodoUseCase`, `FetchTodoUseCase` return `Future<TodoDto?>` | branches on `null` |
| `Future<void>` | `ShowAddTodoModalUseCase`, `OpenTodoDetailsUseCase` | has nothing to branch on |
| `Future<List<T>>`, a sync `T`, a sealed result | none yet | renders an empty list, applies a transform, or tells failure reasons apart |

Return a sealed result instead of `null` when the caller must tell "not found" from "offline". `FetchTodoUseCase` returns `null` for both because the details page shows one error for both. The full table is in [`create-use-case`](../.claude/skills/create-use-case/SKILL.md#return-values), and the five error patterns are in [`handle-errors`](../.claude/skills/handle-errors/SKILL.md#use-cases-the-five-patterns).

### The caller composes and applies

The caller owns the flow. `AddTodoModalState.onSubmit` calls the use case, gives the result to the store and closes the sheet:

```dart
final todo = await _createTodoUseCase(titleController.text.trim());
if (todo == null) {
  _hasError = true;
  return;
}
await _homeStore.addTodo(todo);
await _appNavigator.pop();
```

`CreateTodoUseCase` never sees `HomeStore`. The state reads the result and decides what changes.

## Inline store request or API use case?

The answer depends on who needs the request:

- **A store** may call `DioService` inline for its own request whose result goes into its own observables: a load, a refresh, an optimistic mutation and its rollback. `HomeStore.loadTodos` does this and needs no use case.
- **A state** never touches `DioService`. It calls its store or, when no store owns that data, an API use case. `TodoDetailsPageState` loads a todo no store holds, so it calls `FetchTodoUseCase`, and hands a toggled todo to `HomeStore.replaceTodo`. `AddTodoModalState` calls `CreateTodoUseCase` and hands the result to `HomeStore`.

A store moves a request into an API use case when another consumer needs the same call, when the call coordinates several requests or services, or when mapping the response or the error is not trivial. Making an API call is not, on its own, a reason ([`create-store`](../.claude/skills/create-store/SKILL.md#inline-request-or-use-case), [ADR-0011](adr/0011-retrofit-typed-api-layer.md#access-boundary)).

## Anti-patterns

- **A use case that injects another use case.** An illustrative `CreateAndOpenTodoUseCase` holding `CreateTodoUseCase` and `OpenTodoDetailsUseCase` is the wrong shape. The state calls both in order, as `AddTodoModalState` composes above. Logic that two use cases share becomes a service injected into both.
- **A use case that injects or mutates a store.** `CreateTodoUseCase` returns the `TodoDto`; the state calls `HomeStore.addTodo`. When a use case needs store data, the caller passes it in as a parameter.
- **A use case as a getter.** Illustrative: a `GetEmailUseCase` that returns `_authStore.email` adds a class and hides a store read. Read `AuthStore.email` directly.
- **A `@singleton` use case.** It becomes a place to keep state that no store owns, and data leaks from one caller to the next.
- **Swallowed errors.** `catch (_) { return null; }` without tracking hides the failure from Sentry. ADR-0020 records exactly this bug in an earlier `CreateTodoUseCase`; its test now guards against it. Track, then return.
- **UI calling a use case.** A widget that calls a use case moves logic into the widget tree, where only a widget test reaches it. `HomePage` passes `state.onAddTodoPressed` to the add button, and the state calls `ShowAddTodoModalUseCase`.
- **A use case for a one-liner.** `await _authStore.login(email)` needs no class. `LoginPageState` calls the store directly.

## More information

- [ADR-0003 Use cases never depend on other use cases](adr/0003-no-use-case-to-use-case-dependencies.md)
- [ADR-0004 Use case taxonomy and colocation](adr/0004-use-case-taxonomy-and-colocation.md)
- [ADR-0001 Layered architecture](adr/0001-layered-architecture.md) · [ADR-0007 DI scopes](adr/0007-di-scopes-and-constructor-injection.md) · [ADR-0020 Error handling](adr/0020-error-handling-and-issue-tracking.md)
- Playbooks: [`create-use-case`](../.claude/skills/create-use-case/SKILL.md), [`handle-errors`](../.claude/skills/handle-errors/SKILL.md), [`write-tests`](../.claude/skills/write-tests/SKILL.md)
- Guides: [architecture.md](architecture.md), [state-management-guide.md](state-management-guide.md), [error-handling-guidelines.md](error-handling-guidelines.md), [project-structure.md](project-structure.md)
