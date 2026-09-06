---
name: create-store
description: Build a MobX store — @readonly observables, @action mutations, DioService access, error handling, and the @injectable vs @singleton scope decision. Use when adding or modifying any *_store.dart, or when deciding whether logic belongs in a store or a page state.
---

# Create a MobX store

Governed by [ADR-0002](../../../docs/adr/0002-state-vs-store-separation.md) (state vs store), [ADR-0006](../../../docs/adr/0006-feature-owned-singletons.md) (feature-owned), [ADR-0007](../../../docs/adr/0007-di-scopes-and-constructor-injection.md) (DI scopes).

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

## Shape

```dart
part 'home_store.g.dart';

@singleton
class HomeStore = _HomeStoreBase with _$HomeStore;

abstract class _HomeStoreBase with Store {
  final DioService _dioService;
  final AuthStore _authStore;

  _HomeStoreBase(this._dioService, this._authStore);

  @readonly
  ObservableList<TodoDto> _todos = ObservableList();

  @readonly
  bool _isLoading = false;

  @readonly
  String? _error;

  @computed
  bool get hasTodos => _todos.isNotEmpty;

  @action
  Future<void> loadTodos() async {
    _isLoading = true;
    _error = null;
    try {
      final result = await _dioService.todosProvider.getTodos();
      _todos = ObservableList.of(result);
    } on DioException catch (e) {
      _error = e.message;
    } finally {
      _isLoading = false;
    }
  }
}
```

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

- Every mutation of an observable happens inside `@action`. A write outside an action silently fails to batch and can trip MobX's strict mode.
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
| `debounceReaction` (`lib/core/utils/`) | a reaction that should settle first — a search query |

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

## Error handling

Catch `DioException` at the store boundary and translate it into observable state. Never let a `DioException` escape into the state class or the widget tree.

```dart
} on DioException catch (e) {
  _error = e.message;
}
```

If the app tracks issues (Sentry), report through the injected service inside the catch — do not call a global.

## Collections

`ObservableList` / `ObservableMap`, and mutate them through actions. Reassigning (`_todos = ObservableList.of(...)`) replaces the whole list and rebuilds every observer of it; `_todos.add(x)` is granular. Prefer the granular mutation when only one element changed.

## Cross-store access

A store may inject another store. It must not inject a page state, and it must not reach into another feature's `view/`. If two stores need the same logic, that logic becomes a service or a use case — not a shared base class.

## Checklist

- [ ] Lives under `{feature}/mobx/`, even if `@singleton`
- [ ] Scope justified: `@injectable` unless a second consumer needs the instance
- [ ] All fields `@readonly` with no hand-written getter; `@computed` only for derived values
- [ ] Every mutation inside `@action`; loading cleared in `finally`
- [ ] `DioException` caught and turned into observable error state
- [ ] `melos run build` after adding or renaming annotated members
- [ ] Unit test covers success, API failure, and the empty result — [`write-tests`](../write-tests/SKILL.md)
