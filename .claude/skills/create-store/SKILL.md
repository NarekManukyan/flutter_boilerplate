---
name: create-store
description: Build a MobX store — @readonly observables, @action mutations, DioService access inline vs through a use case, error tracking, optimistic mutations with rollback, pagination, search and filtering with @computed, the @injectable vs @singleton scope decision, and who disposes what. Use when adding or modifying any *_store.dart, or when deciding whether logic belongs in a store or a page state.
---

# Create a MobX store

Governed by [ADR-0002](../../../docs/adr/0002-state-vs-store-separation.md) (state vs store), [ADR-0006](../../../docs/adr/0006-feature-owned-singletons.md) (feature-owned), [ADR-0007](../../../docs/adr/0007-di-scopes-and-constructor-injection.md) (DI scopes), [ADR-0020](../../../docs/adr/0020-error-handling-and-issue-tracking.md) (error tracking).

Concepts behind this playbook: [`state-management-guide`](../../../docs/state-management-guide.md).

## Store or state?

| Question | Store (`*_store.dart`) | State (`*_state.dart`) |
|---|---|---|
| Needs API access? | yes — injects `DioService` | no — calls stores / use cases |
| Outlives one screen? | often | never |
| Location | `lib/features/{feature}/mobx/` | `lib/features/{feature}/view/` |

If it does not touch the network and dies with the screen, it is a state, not a store.

## Location

**Always** under the owning feature's `mobx/`, regardless of scope. A `@singleton AuthStore` lives at `lib/features/auth/mobx/auth_store.dart` — not in `lib/shared/`, not in `lib/core/`.

## Scope

- `@injectable` — a new instance per resolution. Feature stores whose data does not need to survive navigation.
- `@singleton` — one instance for the app. Session, connectivity, notifications, anything two features read.
- `@lazySingleton` — app-wide but expensive; constructed on first resolution (e.g. `DioService`).

Choose `@injectable` unless a second consumer genuinely needs the same instance. A singleton is a decision to keep state alive for the whole process — it is not free.

## Design principles

- **One responsibility per store.** A store owns one resource or one concern: the todo list, the session, connectivity. When a store grows a second unrelated set of observables, split it. Two stores that need the same logic get a service or a use case, not a shared base class.
- **Immutable data inside observable containers.** DTOs are `@freezed` and never mutated in place. To change one element, replace it: `_todos[i] = todo.copyWith(completed: true)`. The `ObservableList` notices the replacement; it cannot notice a field changing inside an element.
- **Batch related changes in one `@action`.** Everything an action writes is published as one change, so observers never render a half-updated store (new items with the old `hasMore`, say). Do not split one logical update into `setItems()` + `setHasMore()` called back to back.

## Shape

```dart
part 'home_store.g.dart';

@singleton
class HomeStore = _HomeStoreBase with _$HomeStore;

abstract class _HomeStoreBase with Store {
  final DioService _dioService;
  final AuthStore _authStore;
  final IssueTrackingService _issueTrackingService;

  _HomeStoreBase(this._dioService, this._authStore, this._issueTrackingService);

  @readonly
  ObservableList<TodoDto> _todos = ObservableList();

  @readonly
  bool _isLoading = false;

  @readonly
  String? _error;

  @action
  Future<void> loadTodos() async {
    _isLoading = true;
    _error = null;
    try {
      final result = await _dioService.todosProvider.getTodos();
      _todos = ObservableList.of(result);
    } catch (e, stackTrace) {
      // Everything, not only DioException: the generated Retrofit client
      // rethrows a response that fails fromJson unchanged. The page renders
      // [error] as its error state, so this is handled.
      _issueTrackingService.trackHandledError(
        e,
        stackTrace: stackTrace,
        handlingContext: 'load_todos',
      );
      _error = e is DioException ? e.message : e.toString();
    } finally {
      _isLoading = false;
    }
  }
}
```

Working example: [`lib/features/home/mobx/home_store.dart`](../../../lib/features/home/mobx/home_store.dart), which also has `addTodo`, `replaceTodo` and `logout`.

## `@readonly` — never write a redundant getter

`@readonly` on `_field` generates the public `field` getter. Adding your own is duplicated, un-reactive code.

```dart
// ✅
@readonly
bool _isLoading = false;            // read as store.isLoading

// ❌ delete this
@computed
bool get isLoading => _isLoading;

// ✅ @computed is for DERIVED state only
@computed
bool get canSubmit => !_isLoading && _title.isNotEmpty;
```

## Actions

- Every mutation of an observable happens inside `@action`. A write outside one is not rejected: MobX wraps each stray write to a generated field or observable collection in its own action. But it is not batched, so each write notifies on its own and an observer can see a half-updated store ([`state-management-guide`](../../../docs/state-management-guide.md#a-write-outside-an-action)).
- `@action` covers async methods too — MobX handles the await boundaries. For a write in a callback that is not inside an action, wrap it in `runInAction`.
- Async actions set the loading flag first and clear it in `finally` — never only on the success path, or an error leaves a permanent spinner.
- Reset the error at the start of a retry-able action, otherwise a stale error survives the next success.

## Reactions — and disposing them

Side effects that should fire when an observable changes belong in a reaction, not in `build()`:

| | Use for |
|---|---|
| `reaction` | a side effect on a specific observable changing — navigate, refetch, log |
| `autorun` | a computation that should re-run whenever anything it reads changes |
| `when` | wait once for a condition to become true, then run |
| `debounceReaction` (`lib/core/utils/`) | a reaction that should settle first — a search query sent to the server |

**Every reaction returns a `ReactionDisposer`, and every disposer must be called.** Store them on the class and dispose in `dispose()`; a leaked reaction keeps firing against a dead screen and holds its whole object graph alive.

```dart
final _disposers = <ReactionDisposer>[];

void init() {
  _disposers.add(
    reaction((_) => _query, _search),
  );
}

void dispose() {
  for (final d in _disposers) {
    d();
  }
  _disposers.clear();
}
```

## Lifecycle: who disposes what

- **A `@singleton` store that owns resources** (subscriptions, timers, controllers) registers its cleanup in the annotation, with a top-level function. `@disposeMethod` does not work here: a MobX store is `class X = _XBase with _$X;`, injectable does not see annotations on the methods of `_XBase`, and it registers nothing without a warning.

  ```dart
  @Singleton(dispose: disposeConnectivityStore)
  class ConnectivityStore = _ConnectivityStore with _$ConnectivityStore;

  Future<void> disposeConnectivityStore(ConnectivityStore store) =>
      store.dispose();
  ```

  Working example: [`lib/features/app/mobx/connectivity_store.dart`](../../../lib/features/app/mobx/connectivity_store.dart). After `melos run build`, check that `lib/injectable.config.dart` registers the store with `dispose:`.
- **A screen state disposes only what it created**: its controllers, its reactions, an `@injectable` store instance made for it. Never an injected app-wide `@singleton` or `@lazySingleton` store. The next screen gets a dead store. The boilerplate's `ConnectionWrapperState.dispose()` once disposed `ConnectivityStore`, and connectivity tracking stopped for the rest of the session.
- **A subscription assigned after an `await` is nullable, not `late`.** `dispose()` can run before the `await` returns, and cancelling an unassigned `late` field throws. Cancel with `await _subscription?.cancel();`, and check a disposed flag after the `await` before subscribing.

## Inline request or use case?

A store may call `DioService` inline when the request is its own and the result goes into its own observables: a load, a refresh, an optimistic mutation and its rollback. `loadTodos` above is that case.

Extract an API use case ([`create-use-case`](../create-use-case/SKILL.md)) when:

- another consumer (a second store, a state) needs the same call;
- the call coordinates several requests or services;
- mapping the response or the error is not trivial, such as translating server codes into domain exceptions.

Either way the store owns its observables. A use case returns a result or throws; the store applies it or rolls back.

## Error handling

Every `catch` tracks or rethrows, never both ([ADR-0020](../../../docs/adr/0020-error-handling-and-issue-tracking.md)). Inject `IssueTrackingService` through the constructor; never call Sentry or a global. The full decision tree is in [`handle-errors`](../handle-errors/SKILL.md).

**What to catch.** The API boundary catches everything.

- A request (a load, a page) catches with `catch (e, stackTrace)`, no `on` clause. The generated Retrofit client rethrows a response that fails `fromJson` unchanged, and that must reach the error state too. Set `error` from `e is DioException ? e.message : e.toString()`.
- A rollback or state restore must run on any failure, so its `catch` has no `on` clause either. More than the request can throw between the change and the restore.
- `on DioException` is only for branching on the Dio error type (a `404`, a timeout) while letting everything else propagate.

**Who tracks.**

- A store whose page renders its `error` observable tracks with `trackHandledError`, sets `error`, and does not rethrow. The page already tells the user, so a notice would say it twice. `loadTodos` above.
- A store action with no error observable for the failure **restores its state, then rethrows**. The calling state owns the screen and tracks once, with `trackIssue` or, if it shows its own error UI, `trackHandledError`. A store shared across screens never decides what the user sees.

What a store rethrows stops at the state. It never reaches the widget tree.

### Optimistic mutation with rollback

Illustrative: the todos provider in this repo has no delete endpoint.

```dart
@action
Future<void> deleteTodo(String id) async {
  final index = _todos.indexWhere((todo) => todo.id == id);
  if (index == -1) {
    return;
  }
  // Removed before the first await, so a dismissed row leaves the list in the
  // same frame. A Dismissible still in the tree after its dismiss throws.
  final removed = _todos.removeAt(index);
  try {
    await _dioService.todosProvider.deleteTodo(id);
  } catch (_) {
    // Any failure, not only DioException: the row goes back where it was.
    // min(): the list may have shrunk while the request was out.
    _todos.insert(min(index, _todos.length), removed);
    rethrow;
  }
}
```

The state that calls it catches, and tracks with `trackIssue(…, context: 'delete_todo', message: …, notifyOnConnectivityError: true)`, because an undone change needs a notice even offline or after a timeout ([`handle-errors`](../handle-errors/SKILL.md#optimistic-changes-notify-on-rollback)). The page keys its rows so the rows below a removed one keep their state ([`create-page`](../create-page/SKILL.md#lists-whose-rows-are-removed-or-inserted)).

## Collections

`ObservableList` / `ObservableMap`, and mutate them through actions. Reassigning (`_todos = ObservableList.of(...)`) replaces the whole list and rebuilds every observer of it; `_todos.add(x)` is granular. Prefer the granular mutation when only one element changed, and reassign on a full reload.

Never hold a plain `List` in an observable and call `addAll` on it: the list changes, the observable does not, and nothing rebuilds.

## Pagination

The rules that are easy to get wrong:

- **Guard re-entry.** A scroll listener fires many times near the end of the list. Return early while a page is loading or when there is nothing more.
- **Advance the page only after the request succeeded.** Incrementing first and failing skips a page for good.
- **Loading is cleared in `finally`**, and the failure is tracked, with the page unchanged so a retry asks for the same page.
- **Append the next page; replace on the first page.** That is the granular-vs-reassign rule above.
- **Refresh resets the page and drops any page still in flight.** A response that lands after a refresh belongs to the old list.

The example assumes a paged endpoint returning the shared envelope, `Future<ListResponseDto<TodoDto>> getTodosPage({required int page, required int take})` — see [`create-api-provider`](../create-api-provider/SKILL.md).

```dart
part 'todo_list_store.g.dart';

@injectable
class TodoListStore = _TodoListStoreBase with _$TodoListStore;

abstract class _TodoListStoreBase with Store {
  _TodoListStoreBase(this._dioService, this._issueTrackingService);

  static const _pageSize = 20;

  final DioService _dioService;
  final IssueTrackingService _issueTrackingService;

  @readonly
  ObservableList<TodoDto> _todos = ObservableList<TodoDto>();

  @readonly
  bool _hasMore = true;

  @readonly
  bool _isLoadingMore = false;

  @readonly
  String? _error;

  /// The last page that loaded. 0 until the first page arrives.
  int _page = 0;

  /// Bumped by [refresh]. A page that lands after a refresh belongs to the
  /// list that was thrown away, so it is dropped.
  int _generation = 0;

  /// Skeleton, not the footer spinner.
  @computed
  bool get isFirstLoad => _isLoadingMore && _todos.isEmpty;

  @action
  Future<void> loadNextPage() async {
    if (!_hasMore || _isLoadingMore) {
      return;
    }
    final generation = _generation;
    final nextPage = _page + 1;
    _isLoadingMore = true;
    _error = null;
    try {
      final response = await _dioService.todosProvider.getTodosPage(
        page: nextPage,
        take: _pageSize,
      );
      if (generation != _generation) {
        return;
      }
      if (nextPage == 1) {
        _todos = ObservableList.of(response.data); // first page or refresh
      } else {
        _todos.addAll(response.data); // next page: append only
      }
      // Advanced only now: a failed request leaves the page where it was, so
      // the retry asks for the same page instead of skipping one.
      _page = nextPage;
      _hasMore =
          response.meta?.hasNextPage ?? response.data.length == _pageSize;
    } catch (e, stackTrace) {
      // The list renders [error] (a footer with a retry), so this is handled.
      _issueTrackingService.trackHandledError(
        e,
        stackTrace: stackTrace,
        handlingContext: 'load_todos_page',
      );
      if (generation == _generation) {
        _error = e is DioException ? e.message : e.toString();
      }
    } finally {
      if (generation == _generation) {
        _isLoadingMore = false;
      }
    }
  }

  @action
  Future<void> refresh() {
    _generation++;
    _page = 0;
    _hasMore = true;
    _isLoadingMore = false;
    _error = null;
    return loadNextPage();
  }
}
```

- Refresh keeps the old items on screen until page 1 replaces them, so a pull-to-refresh does not flash the skeleton.
- The page state triggers `loadNextPage` from the scroll controller (`addInfiniteScrollListener` in `lib/core/extensions/infinity_scroll_extension.dart`) and `refresh` from the `RefreshIndicator`.
- Tests: success appends and advances, failure keeps the page and tracks, a refresh during an in-flight page drops the late page — [`write-tests`](../write-tests/SKILL.md).

## Search and filtering

The query and the active filters are `@readonly` observables, changed through actions. The visible list is `@computed`:

```dart
enum TodoStatusFilter {
  all,
  active,
  done;

  bool matches(TodoDto todo) => switch (this) {
    TodoStatusFilter.all => true,
    TodoStatusFilter.active => !todo.completed,
    TodoStatusFilter.done => todo.completed,
  };
}
```

```dart
@readonly
String _query = '';

@readonly
TodoStatusFilter _statusFilter = TodoStatusFilter.all;

@computed
List<TodoDto> get visibleTodos {
  final query = _query.trim().toLowerCase();
  return _todos
      .where(
        (todo) =>
            _statusFilter.matches(todo) &&
            (query.isEmpty || todo.title.toLowerCase().contains(query)),
      )
      .toList(growable: false);
}

@action
void setQuery(String value) => _query = value;

@action
void setStatusFilter(TodoStatusFilter value) => _statusFilter = value;
```

- **Use `@computed` for expensive derived collections** — filtered, sorted, grouped. While an `Observer` or reaction reads it, the result is cached and recomputed only when `_todos`, `_query` or `_statusFilter` changes, not on every rebuild. Never filter inside `build()`.
- The filter enum is a feature model: `lib/features/{feature}/models/`, as `TodoFilter` is in `lib/features/home/models/todo_filter.dart`.
- A filter only one screen uses can sit on the page state instead of the store. `HomePageState` holds `@readonly TodoFilter _filter` and a `@computed visibleTodos` over `HomeStore.todos`.
- A query that goes to the **server** is not a `@computed`: debounce it with `debounceReaction` on `_query` (see Reactions) and load the results into the store.

## Cross-store access

A store may inject another store. It must not inject a page state, and it must not reach into another feature's `view/`. If two stores need the same logic, that logic becomes a service or a use case — not a shared base class.

## Checklist

- [ ] Lives under `{feature}/mobx/`, even if `@singleton`
- [ ] Scope justified: `@injectable` unless a second consumer needs the instance
- [ ] One responsibility; related writes batched in one `@action`
- [ ] All fields `@readonly` with no hand-written getter; `@computed` only for derived values
- [ ] Every mutation inside `@action`; loading cleared in `finally`
- [ ] Collections are `ObservableList` / `ObservableMap`; DTOs replaced, never mutated
- [ ] Inline `DioService` call only for the store's own request applied to its own observables; otherwise an API use case
- [ ] Every `catch` tracks or rethrows: `trackHandledError` + `error` when the page renders it; restore then rethrow when there is no error observable
- [ ] Requests, rollbacks and restores catch every failure (no `on` clause); `on DioException` only to branch on the Dio error type
- [ ] A `@singleton` that owns resources registers `@Singleton(dispose: …)` (not `@disposeMethod`), visible in `injectable.config.dart`
- [ ] No screen state disposes an app-wide store; subscriptions assigned after an `await` are nullable, not `late`
- [ ] Pagination: re-entry guard, page advanced only on success, refresh resets and drops late pages
- [ ] Filtered or sorted lists are `@computed`, not computed in `build()`
- [ ] `melos run build` after adding or renaming annotated members
- [ ] Unit test covers success, API failure (tracking verified, or `verifyNever` on all three methods where the store rethrows), and the empty result; a rollback test asserts the item is back at its index — [`write-tests`](../write-tests/SKILL.md)
