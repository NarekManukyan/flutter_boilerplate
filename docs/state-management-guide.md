# State Management Guide

MobX in the boilerplate: where each piece of state lives, how a change reaches the screen, who creates and disposes what, and the pitfalls that span stores, page states and widgets. Read it when a change or a bug crosses those layers: a widget that does not rebuild, a reaction that fires after its screen is gone, a singleton that keeps stale data. To build one store, page or test, open its playbook. This guide explains the model and links to the rules. Behaviour described here was checked against `mobx` 2.6.0, `mobx_codegen` 2.7.7 and `flutter_mobx` 2.3.0.

**Related:** playbooks [`create-store`](../.claude/skills/create-store/SKILL.md), [`create-page`](../.claude/skills/create-page/SKILL.md), [`create-use-case`](../.claude/skills/create-use-case/SKILL.md), [`handle-errors`](../.claude/skills/handle-errors/SKILL.md), [`write-tests`](../.claude/skills/write-tests/SKILL.md) · ADRs [0001](adr/0001-layered-architecture.md), [0002](adr/0002-state-vs-store-separation.md), [0006](adr/0006-feature-owned-singletons.md), [0007](adr/0007-di-scopes-and-constructor-injection.md), [0009](adr/0009-provider-based-state-access.md), [0010](adr/0010-hookwidget-default.md), [0019](adr/0019-hook-selection.md), [0020](adr/0020-error-handling-and-issue-tracking.md)

## Overview

### Four places state lives

| Kind | Where | Holds | Lives as long as | Example |
|---|---|---|---|---|
| Store | `*_store.dart` in `features/{feature}/mobx/` | data from the API ([ADR-0002](adr/0002-state-vs-store-separation.md)) | `@singleton`: the process, until `resetDependencies()`. `@injectable`: whoever resolved it | `HomeStore`, `AuthStore`, `ConnectivityStore` |
| Page state | `*_state.dart` in `view/`, or `mobx/` for a modal or app-level widget | what one screen shows and does. Calls stores, use cases, `AppNavigator` | the `Provider` at the page root | `HomePageState`, `AddTodoModalState`, `ConnectionWrapperState` |
| Hook-local state | `useValueNotifier`, `useState`, controller hooks | UI-only values of one widget | the widget | `fabVisible` in `HomePage` |
| State primitive | `lib/core/state/` | one reusable observable concern, composed into a state | the object holding it | `LoadingState` in `AddTodoModalState` |

### Where does this value live?

| The value… | Put it in |
|---|---|
| comes from the API | a store |
| is read by two screens, or must survive leaving the screen | a `@singleton` store |
| is loaded for one screen and dropped with it | a page state calling an API use case (`TodoDetailsPageState` with `FetchTodoUseCase`), or an `@injectable` store |
| drives screen logic: validation, submit flags, a filter a `@computed` depends on, navigation after an action | the page state (`HomePageState._filter`) |
| is read by only part of one widget, and nothing outside it cares | `useValueNotifier` ([ADR-0019](adr/0019-hook-selection.md)) |
| changes everything one widget renders, and nothing outside it cares | `useState` |
| is a loading flag or another concern many states repeat | a primitive from `lib/core/state/` |
| can be derived from other observables | a `@computed` on the class that owns the inputs, never a second stored copy |

### How a change reaches the screen

```
tap → widget calls state.onSubmit()             context.read, ADR-0009
    → page state @action                        writes the state's own observables
    → use case makes the API call               returns a result, touches no store
    → store @action applies the result          writes the store's observables
    → the synchronous stretch of the action ends: observers are notified
    → every Observer that read a changed observable in its last build rebuilds
```

Adding a todo follows exactly this path. `AddTodoModalState.onSubmit` calls `CreateTodoUseCase`, then `HomeStore.addTodo`, then `AppNavigator.pop`. The home page's list `Observer` rebuilds because it read `state.todos`, a plain getter on `HomePageState` that reads `HomeStore.todos`. MobX tracks through the getter. The sheet's button `Observer` rebuilds because it read `loadingState.isLoading`.

## Observables and actions

- **`@readonly`** on a private field generates the public getter (`_todos` → `store.todos`). Never add a getter or a `@computed` that mirrors it ([ADR-0002](adr/0002-state-vs-store-separation.md)). **`@observable`** on a public field keeps its public setter, so use it only when outside code really has to assign the field.
- **`@computed`** is for derived values, including filtered or sorted lists ([`create-store`](../.claude/skills/create-store/SKILL.md#search-and-filtering)). It is cached only while an `Observer` or reaction observes it. Read with nothing observing it, in a unit test for example, it recomputes on every read.
- **`@action`** wraps every write. mobx_codegen turns an `async` action into an `AsyncAction`, which runs the body in a `Zone` and opens an action around each continuation. Writes after an `await` are therefore batched as well, one batch per stretch between `await`s (`_$loadTodosAsyncAction.run(...)` in `home_store.g.dart`).

Two limits of that wrapping:

- The generator checks for the `async` keyword, not the return type. A `Future` method written with `.then()` and no `async` gets a synchronous action, so the write inside `.then` runs after that action has ended.
- A callback that runs later on its own, such as a `Timer`, a stream listener or a `debounceReaction` effect, needs its own action. `ConnectivityStore` does this:

```dart
_subscription = _connectivity.onConnectivityChanged.listen(_addStatus);

@action
void _addStatus(List<ConnectivityResult> result) {
  _hasConnection = result.any(_isConnectionType);
}
```

### A write outside an action

The default `ReactiveConfig` uses `writePolicy: ReactiveWritePolicy.observed`:

| What is written | Result |
|---|---|
| a codegen `@observable` / `@readonly` field, or an `ObservableList` / `Map` / `Set` | MobX wraps that one write in its own action. Nothing throws, and nothing is batched either: each write notifies on its own, so an observer can run between two writes and see a half-updated store. |
| a hand-made `Observable(...)` that something observes | fails an assert in debug builds ("Side effects like changing state are not allowed at this point") |
| an observed observable, from inside a `@computed` | always throws `MobXException` |

So a missing `@action` rarely fails loudly. The symptom is a flicker or a reaction that fires twice. Keep one logical update in one action ([`create-store`](../.claude/skills/create-store/SKILL.md#design-principles)).

## Collections

- `ObservableList`, `ObservableMap` and `ObservableSet` report reads and writes of their contents. Each collection has one atom, so an `Observer` that reads any part of it (`length`, iteration, `[i]`) rebuilds on every add, remove or replace.
- Mutate the collection for a single change (`_todos.add(todo)` in `HomeStore.addTodo`). Assign a new collection on a full reload (`_todos = ObservableList.of(result)` in `loadTodos`). The rules are in [`create-store`](../.claude/skills/create-store/SKILL.md#collections).
- A plain `List` in an observable field is observable only as a reference. Calling `add` on it changes nothing MobX can see. Only assigning a different list notifies.
- Elements are not observable. Replace a freezed DTO (`_todos[i] = todo.copyWith(completed: true)`) instead of changing it. Assigning a value that is `==` to the current one does not notify.
- `list.asObservable()` and `ObservableList.of(list)` copy the list. Later changes to the source list are not seen.

## Async state

The boilerplate tracks async work with flags: `@readonly bool _isLoading` and `String? _error` in `HomeStore`, and `LoadingState` in `AddTodoModalState`. `ObservableFuture` is available but not used.

| | Flags | `ObservableFuture` |
|---|---|---|
| Fits | refresh that keeps old data on screen, retry, pagination, errors tracked per [ADR-0020](adr/0020-error-handling-and-issue-tracking.md) | a one-shot value where pending / fulfilled / rejected is all the UI needs |
| Watch for | reset in `finally`, stale responses, re-entry | a new future starts `pending` with a `null` value, so a refresh blanks the screen unless you use `.replace()`. The error is only a value, so tracking still needs a `catch` |

- **Clear loading in `finally`**, and reset the error when a retry starts ([`handle-errors`](../.claude/skills/handle-errors/SKILL.md#stores-and-states)).
- **Drop stale responses.** When a newer request can start before the older one returns (a search, a refresh), number the requests and ignore any response that is not the latest. Pagination does the same with its `_generation` field ([`create-store`](../.claude/skills/create-store/SKILL.md#pagination)).

```dart
@action
Future<void> search(String query) async {
  final generation = ++_generation;
  _isLoading = true;
  try {
    final result = await _searchTodos(query);
    if (generation != _generation) {
      return; // a newer search owns the list
    }
    _results = ObservableList.of(result);
  } finally {
    if (generation == _generation) {
      _isLoading = false;
    }
  }
}
```

- **Guard re-entry in the action.** A disabled button is not enough: a keyboard submit or a second tap can reach the action while the first call is still running. Return early while loading, as `AddTodoModalState.onSubmit` does.
- **Optimistic updates** change the store before the request and put it back on any failure. The store restores and rethrows, and the calling state tracks ([`create-store`](../.claude/skills/create-store/SKILL.md#optimistic-mutation-with-rollback)).
- **Who tracks** is decided by who shows the error. Track once, in the layer that catches and does not rethrow ([ADR-0020](adr/0020-error-handling-and-issue-tracking.md)).

## `Observer` placement

- **Wrap the smallest subtree that reads the observable**, with one `Observer` per region that changes on its own. The add-todo sheet has one for `hasError` and one for the submit button.
- **Read inside `builder`.** An `Observer` tracks only what its builder reads while it builds. A value read before the `Observer`, or inside a lazy `itemBuilder`, is not tracked. `ListView.builder` builds its rows during layout, after tracking has finished. Read what the rows need in the builder (`HomePage` reads `state.visibleTodos` there), or give each row its own `Observer`.
- **"No observables detected in the build method of …"** is printed by flutter_mobx with `debugPrint` after any build in which the builder read no observable. MobX will never rebuild that `Observer`. Common causes: a read moved out of the builder, a builder that reads only plain fields or mocked getters, and reads inside `itemBuilder`.
- **Keep what does not change out of the rebuild.** A `const` child costs nothing. A child that cannot be `const` goes through `Observer.withBuiltChild`, which receives it already built.
- **Hooks do not notify an `Observer`** ([ADR-0019](adr/0019-hook-selection.md)). A `useValueNotifier` value read inside the builder does not rebuild it. Give that value its own `ValueListenableBuilder`, as the home page's FAB does. A `useState` value seems to work there only because `useState` rebuilds the whole widget.
- **`context.read`, never `context.watch`.** The state object never changes identity. Rebuilds come from `Observer` ([ADR-0009](adr/0009-provider-based-state-access.md)).

```dart
// ❌ read outside the builder: the Observer tracks nothing and never rebuilds
final hasError = state.hasError;
return Observer(
  builder: (_) => hasError ? const _ErrorText() : const SizedBox.shrink(),
);

// ✅ read inside the builder
return Observer(
  builder: (_) =>
      state.hasError ? const _ErrorText() : const SizedBox.shrink(),
);

// ✅ only the opacity rebuilds; the form is built once and passed in
return Observer.withBuiltChild(
  builder: (_, child) => AnimatedOpacity(
    opacity: state.loadingState.isLoading ? 0.4 : 1,
    duration: GeistDuration.fast,
    child: child,
  ),
  child: _Form(onSubmit: state.onSubmit),
);
```

## Reactions

| API | Runs its effect | Stops |
|---|---|---|
| `reaction(fn, effect)` | when the value `fn` returns changes. `fireImmediately: true` also runs it once at creation | its disposer |
| `autorun(fn)` | at creation, then whenever anything it read changes | its disposer |
| `when(predicate, effect)` | once, the first time `predicate` is true | by itself after firing, or its disposer |
| `asyncWhen(predicate)` | none: returns a `Future` that completes the first time `predicate` is true | when the predicate holds, or at `timeout:`. It has no disposer, so without a timeout it can wait forever |
| `debounceReaction(fn, effect, delay: duration)` in `lib/core/utils/` | once the `delay` `Duration` passes without a change. With `fireImmediately` the first value also waits `delay` | its disposer, which also cancels a pending effect |

- `reaction` and `when` run their effect inside an action. A `debounceReaction` effect runs later from a `Timer`, outside any action, so make the effect an `@action`.
- `delay:` on MobX's own `reaction` throttles rather than debounces: the effect runs `delay` ms after the first change, with the latest value. Use `debounceReaction` when the effect should wait until changes stop.
- **Every reaction returns a `ReactionDisposer`, and the object that created the reaction disposes it.** Create reactions in the state's constructor or `init()`. Dispose them in the state's `dispose()`, which the page root's `Provider(dispose:)` calls. For several reactions, keep a list of disposers ([`create-store`](../.claude/skills/create-store/SKILL.md#reactions--and-disposing-them)).

`ConnectionWrapperState` creates its reaction in the constructor and disposes only that reaction:

```dart
_ConnectionWrapperStateBase(this._connectivityStore) {
  _connectivityReaction = debounceReaction(
    (_) => _connectivityStore.hasConnection,
    _onConnectivityChange,
    delay: TimingConstants.connectivityDebounce,
    fireImmediately: true,
  );
}

@action
void _onConnectivityChange(bool hasConnection) {
  _hasConnection = hasConnection;
}

void dispose() {
  _connectivityReaction(); // never _connectivityStore: it is app-wide
}
```

```dart
Provider<ConnectionWrapperState>(
  create: (_) => getIt<ConnectionWrapperState>(),
  dispose: (_, state) => state.dispose(),
  child: _ConnectionWrapperContent(child: child),
)
```

`Provider(create:)` is lazy. `create`, and the `init()` chained onto it, run at the first `context.read`. If nothing reads the state, `dispose` never runs. A state that nothing below reads but whose `init()` must run passes `lazy: false`, as `SplashPage` does.

**Do not use a reaction for something the action already knows.** Reactions are for changes the state does not cause itself, such as connectivity, auth expiry, or a query typed in another widget.

```dart
// ❌ closes the sheet whenever the list grows, even when another screen adds
reaction((_) => _homeStore.todos.length, (_) => _appNavigator.pop());

// ✅ AddTodoModalState.onSubmit: the action that saved knows it succeeded
await _homeStore.addTodo(todo);
await _appNavigator.pop();
```

## Lifetimes and ownership

| Object | Created by | Disposed by |
|---|---|---|
| `@singleton` store | GetIt, in `configureDependencies` | GetIt on `reset()`, through `@Singleton(dispose: fn)` |
| `@injectable` store or state | every `getIt<T>()` call, which returns a new instance each time | whoever resolved it. For a page state, its `Provider` |
| reaction, subscription, timer or controller held by a state | that state | that state's `dispose()` |
| hook controller, `useValueNotifier` | the hook | the hook, when the widget unmounts |

- **A screen disposes only what it created**, never an injected app-wide store. `ConnectionWrapperState.dispose()` once disposed `ConnectivityStore`, and connectivity tracking stopped for the rest of the session ([`create-store`](../.claude/skills/create-store/SKILL.md#lifecycle-who-disposes-what)).
- **Singleton cleanup** goes in `@Singleton(dispose: fn)`. injectable does not see `@disposeMethod` on the MobX base class. After `melos run build`, check that `injectable.config.dart` registers `dispose:`.
- **A subscription assigned after an `await` is nullable, not `late`**, and the code checks a disposed flag after the `await` (`ConnectivityStore._init`).
- **Logout.** `AuthStore.clearSession()` calls `resetDependencies()`, which disposes every registration and registers them again. The next `getIt<T>()` returns a fresh singleton, but references taken before the reset still point at the old, disposed instances. `resetDependencies()` therefore bumps `dependencyGeneration`, and `MyApp` keys `MaterialApp.router` on it: the new router is mounted, and everything below it, the `ConnectionWrapperState` created in `builder` included, is created again. Something created above that key, or held in a static, is not ([ADR-0007](adr/0007-di-scopes-and-constructor-injection.md)).

## Cross-store communication

- A store may inject and read another store: `HomeStore` injects `AuthStore` for `logout` ([ADR-0001](adr/0001-layered-architecture.md)). Keep those dependencies one-way. Two stores that need each other form a cycle GetIt cannot construct, so move the shared logic into a service ([`create-store`](../.claude/skills/create-store/SKILL.md#cross-store-access)).
- A use case never injects or changes a store. It returns a result and the caller applies it. The caller also composes use cases, as `AddTodoModalState.onSubmit` does ([`create-use-case`](../.claude/skills/create-use-case/SKILL.md#composing-use-cases-is-the-callers-job)).
- Data that two screens show belongs in one store, and changes are applied there. A copy in a page state goes stale unless the change is applied to the store too. `TodoDetailsPageState.onToggleCompleted` updates its own copy and calls `HomeStore.replaceTodo`, so the Home list shows the same value.

## Testing state

- Unit-test stores and states as plain Dart, with mocktail fakes one layer down, and assert observable values after the action rather than only `verify` ([`write-tests`](../.claude/skills/write-tests/SKILL.md)).
- `mobx` and `mocktail` both export `when`, and `flutter_hooks` and `mobx` both export `Store`. Import mobx narrowly: `import 'package:mobx/mobx.dart' show ObservableList, runInAction;`
- Record a sequence of values with `autorun`, and dispose it at the end of the test ([`write-tests`](../.claude/skills/write-tests/SKILL.md#reacting-to-observables)).
- Test a reaction through its real source. Change the source, let the event queue run (wait past `delay` for `debounceReaction`, or `tester.pump(delay)` in a widget test), then assert. The mocks and the `changes` stream are set up as in `test/features/app/mobx/connectivity_store_test.dart`:

```dart
test('should follow the store once the debounce settles', () async {
  final store = ConnectivityStore(connectivity, issueTracking);
  final state = ConnectionWrapperState(store);
  await pumpEventQueue();

  changes.add([ConnectivityResult.none]);
  await Future<void>.delayed(const Duration(milliseconds: 250));

  expect(state.hasConnection, isFalse);
  state.dispose();
  await store.dispose();
});
```

- Widget tests that pump a whole page register the mock state with `getIt.registerFactory` and call `tearDown(getIt.reset)`. A widget below the root is pumped under `Provider<T>.value` ([`write-tests`](../.claude/skills/write-tests/SKILL.md#overriding-the-page-state)).
- A mocked store getter is not observable. To test that a widget rebuilds, return a real `ObservableList` or `Observable` from the stub and change it inside `runInAction`.

## Pitfalls

| Symptom | Cause | Fix |
|---|---|---|
| UI does not update after the store changed | read outside the `Observer` builder, a field without `@readonly` / `@observable`, or codegen not re-run | read inside the builder, annotate, `melos run build` |
| Updates only after hot reload or an unrelated rebuild | the read happened in a build nobody tracks: before the `Observer`, or in a lazy `itemBuilder` | move the read into the builder, or add an `Observer` per row |
| A changed list item is not reflected | a field changed inside an element, or `add` on a plain `List` | replace the element with `copyWith`; use `ObservableList` |
| "No observables detected in the build method" | the builder read no observable | move the read into the builder, or remove the `Observer` |
| Whole page rebuilds on every change | one `Observer` around the `Scaffold`, `useState` set from a listener, filtering in `build()` | an `Observer` per region, `useValueNotifier`, `@computed` / `useMemoized` |
| A hook value does not update inside an `Observer` | `Observer` ignores `ValueNotifier`s | `ValueListenableBuilder` for that value |
| Observers flicker or a reaction fires twice for one update | related writes made outside a single action | one `@action` per logical update |
| Reaction fires after the screen closed | disposer never called, or `dispose()` not wired to `Provider(dispose:)` | keep the disposer; call it in `dispose()` |
| `LateInitializationError` in `dispose()` | a `late` field assigned after an `await` | nullable field, `?.cancel()`, disposed flag |
| Another screen stops updating after one closes | a screen disposed an injected singleton | dispose only what the state created |
| Spinner stuck after an error | loading reset only on the success path | reset in `finally` |
| Older response overwrites newer data | no guard against stale responses | request counter; drop late responses |
| Item created twice | no re-entry guard in the action | return early while loading |
| Failure reported twice, or two messages | tracked and rethrown, or a store tracked an error its page already shows | track once, per [ADR-0020](adr/0020-error-handling-and-issue-tracking.md) |
| Store state leaks between tests | `getIt` not reset, reaction not disposed, one instance shared by several tests | new instance in `setUp`, `tearDown(getIt.reset)`, dispose reactions |
| Previous user's data after logout | singleton not reset, or an object holding a singleton from before the reset | `clearSession()` → `resetDependencies()`; do not keep singletons in objects that outlive logout |
| Two screens show different values for one item | each screen keeps its own copy | keep the item in one store and apply changes there (`HomeStore.replaceTodo`) |
| Logging in again after logout goes nowhere | the mounted router belongs to the `AppNavigator` from before the reset | keep the router subtree keyed on `dependencyGeneration` |

## More information

- [ADR-0001 Layered architecture](adr/0001-layered-architecture.md) · [ADR-0002 State vs Store separation](adr/0002-state-vs-store-separation.md) · [ADR-0006 Feature-owned singletons](adr/0006-feature-owned-singletons.md) · [ADR-0007 DI scopes](adr/0007-di-scopes-and-constructor-injection.md)
- [ADR-0009 Provider-based state access](adr/0009-provider-based-state-access.md) · [ADR-0010 `HookWidget` default](adr/0010-hookwidget-default.md) · [ADR-0019 Hook selection](adr/0019-hook-selection.md) · [ADR-0020 Error handling](adr/0020-error-handling-and-issue-tracking.md)
- Playbooks: [`create-store`](../.claude/skills/create-store/SKILL.md) · [`create-page`](../.claude/skills/create-page/SKILL.md) · [`create-use-case`](../.claude/skills/create-use-case/SKILL.md) · [`handle-errors`](../.claude/skills/handle-errors/SKILL.md) · [`write-tests`](../.claude/skills/write-tests/SKILL.md)
- Guides: [`architecture.md`](architecture.md) · [`project-structure.md`](project-structure.md) · [`use_cases_guide.md`](use_cases_guide.md) · [`error-handling-guidelines.md`](error-handling-guidelines.md) · [`performance-guide.md`](performance-guide.md) · [`troubleshooting.md`](troubleshooting.md#mobx-ui-does-not-update)
