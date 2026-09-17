---
name: create-page
description: Build a page and its MobX page state — Provider root, context.read access, HookWidget for local state, AppNavigator for navigation, Observer for reactive rebuilds, and the loading/empty/error branches. Use when adding or modifying any screen, modal or route-level widget.
---

# Create a page + page state

Governed by [ADR-0009](../../../docs/adr/0009-provider-based-state-access.md) (Provider access), [ADR-0010](../../../docs/adr/0010-hookwidget-default.md) (HookWidget), [ADR-0018](../../../docs/adr/0018-widget-construction-discipline.md) (widget construction), [ADR-0019](../../../docs/adr/0019-hook-selection.md) (hook selection), [ADR-0008](../../../docs/adr/0008-appnavigator-routing-abstraction.md) (navigation), [ADR-0002](../../../docs/adr/0002-state-vs-store-separation.md) (state vs store).

## The page state

`@injectable`, MobX, lives at `lib/features/{feature}/view/{feature}_page_state.dart`. It **never** touches `DioService` — it calls stores and use cases.

```dart
part 'home_page_state.g.dart';

@injectable
class HomePageState = _HomePageStateBase with _$HomePageState;

abstract class _HomePageStateBase with Store {
  final HomeStore _homeStore;
  final AppNavigator _appNavigator;
  final OpenTodoDetailsUseCase _openTodoDetailsUseCase;

  _HomePageStateBase(
    this._homeStore,
    this._appNavigator,
    this._openTodoDetailsUseCase,
  );

  HomeStore get store => _homeStore;

  Future<void> init() async => _homeStore.loadTodos();

  @action
  Future<void> onTodoTap(String id) async => _openTodoDetailsUseCase(id);

  @action
  Future<void> onLogoutPressed() async {
    await _homeStore.logout();
    await _appNavigator.pushAndPopAll(const LoginRoute());
  }

  void dispose() {}
}
```

- Handler names read as events: `onXPressed`, `onXTap`, `onXChanged`.
- `init()` is called by the `Provider`, not by `build()`.
- `dispose()` always exists — cancel reactions, dispose controllers.

## The page

Two widgets. The outer one is the `Provider` root; the inner one reads the state.

```dart
@RoutePage()
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Provider<HomePageState>(
      create: (_) => getIt<HomePageState>()..init(),
      dispose: (_, state) => state.dispose(),
      child: const _HomePageContent(),
    );
  }
}

class _HomePageContent extends HookWidget {
  const _HomePageContent();

  @override
  Widget build(BuildContext context) {
    final g = context.geist;
    final state = context.read<HomePageState>();
    final controller = useScrollController();
    // …
  }
}
```

`Provider(create:)` is the **only** place `getIt<>()` may be called from widget code ([ADR-0007](../../../docs/adr/0007-di-scopes-and-constructor-injection.md)).

## Hard rules

- **Never pass state as a widget parameter.** Descendants call `context.read<HomePageState>()`. Pass plain data and callbacks down, never the state object.
- **Never `context.router`.** Navigation goes through `AppNavigator` in the state class.
- **`HookWidget`** whenever the widget needs a controller, effect, or local UI state. `StatelessWidget` for pure presentation. `StatefulWidget` only for APIs hooks cannot express.
- **Hooks are for local widget state and lifecycle only.** Business logic, anything shared between widgets, and anything that outlives the screen belong in the state class or a store — never in a `useState`.
- **No widget-returning methods, no `BuildContext` parameters.** See [Splitting a large `build()`](#splitting-a-large-build) below.
- **Pick the hook by rebuild scope.** See [Choosing a hook](#choosing-a-hook) below.
- **`Observer` scoped tight.** Wrap the smallest subtree that reads observables — not the whole `Scaffold`. A page-wide `Observer` rebuilds the app bar on every list change.
- **Design-system tokens only** — `context.geist.*`, `GeistTextStyles.*`, `GeistRadius.*`, `GeistDuration.*`, `kSpacingNpx`. No raw `Color`, `TextStyle(…)`, or `BoxShadow` stacks ([ADR-0013](../../../docs/adr/0013-design-system-tokens-only.md)).
- **Every string via `LocaleKeys`** ([ADR-0012](../../../docs/adr/0012-mandatory-localization.md)).

## The four branches — all of them, every time

An `Observer` over remote data renders four states. Skipping one is the most common defect this repo produces.

```dart
Observer(
  builder: (_) {
    final store = state.store;
    if (store.isLoading && store.todos.isEmpty) return const _SkeletonList();
    if (store.error != null) return _ErrorState(onRetry: state.init);
    if (store.todos.isEmpty) return const _EmptyState();
    return _TodoList(todos: store.todos);
  },
)
```

- **Loading** — `skeletonizer`, never a bare centred spinner on first load.
- **Error** — a message plus a retry affordance that actually re-runs the request.
- **Empty** — distinct from loading and from error; says what the user can do next.
- **Content**.

Each branch needs a test identifier (below) so the Maestro failure and edge flows can assert it.

## Lists whose rows are removed or inserted

A list whose rows can be removed or inserted mid-list (swipe to delete, reorder, an optimistic insert) keys each row with `ValueKey(item.id)` and gives the builder a callback that maps the key back to the row's current index:

| Builder | Callback |
|---|---|
| `SliverList.separated`, `ListView.separated` | `findItemIndexCallback` |
| `SliverList.builder`, `ListView.builder` | `findChildIndexCallback` |

Without the callback, Flutter matches children by position. Remove row 2, and the element at position 2 is handed row 3's widget. The keys differ, so that element is thrown away and row 3 is built from scratch, and so is every row below it. Their state is lost and their entry animations play again.

Illustrative: `onTodoDismissed` and `HomeKeys.todoRow` do not exist in this repo.

```dart
SliverList.separated(
  itemCount: todos.length,
  separatorBuilder: (_, _) => const Gap(kSpacing8px),
  itemBuilder: (_, index) {
    final todo = todos[index];
    return Dismissible(
      key: ValueKey(todo.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => state.onTodoDismissed(todo.id),
      child: _TodoCard(todo: todo).withTestId(HomeKeys.todoRow(todo.id)),
    );
  },
  findItemIndexCallback: (key) {
    final index = todos.indexWhere((todo) => ValueKey(todo.id) == key);
    return index == -1 ? null : index;
  },
)
```

- The key goes on the widget the builder returns, here the `Dismissible`, not on a child inside it.
- `ValueKey(item.id)`, never `ValueKey(index)` (the index shifts with the removal) or `UniqueKey()` (it never matches).
- `onDismissed` must take the row out of the list before the next frame, or `Dismissible` throws. The store removes it before its first `await` ([`create-store`](../create-store/SKILL.md#optimistic-mutation-with-rollback)).
- A row's test id includes the item id, so a flow can assert that exact row before and after: `static String todoRow(String id) => 'home_todo_row_$id';` in the keys file.
- Lowering `dismissThresholds` so a swipe dismisses sooner is a product decision, not a test fix ([`write-maestro-flow`](../write-maestro-flow/SKILL.md#swipes-and-gestures-shared-by-several-flows)).
- Widget test: the element of a row below the removed one survives the removal ([`write-tests`](../write-tests/SKILL.md#rows-keep-their-element-when-a-row-is-removed)).

## Test identifiers

Every widget an E2E flow touches carries a stable identifier, and every interactive widget carries a `Semantics` label from `LocaleKeys` ([ADR-0015](../../../docs/adr/0015-mandatory-test-coverage-and-qa-gate.md)).

**A plain `Key` is not enough.** Verified on device: Flutter does not export a `Key` to the native accessibility tree, so Maestro cannot see it — the widget shows up with an empty `resource-id` and every `id:` selector fails. Only `Semantics(identifier:)` sets the native accessibility identifier.

Use `TestId` (`lib/core/ui/test_id.dart`), which applies both from one string — the `Semantics(identifier:)` Maestro matches, and the `Key` widget tests find:

```dart
// lib/features/home/view/home_keys.dart — plain Strings
class HomeKeys {
  HomeKeys._();
  static const addTodoFab = 'home_add_todo_fab';
  static const todoList = 'home_todo_list';
  static const emptyState = 'home_empty_state';
  static const errorState = 'home_error_state';
  static const errorRetry = 'home_error_retry';
}
```

```dart
// wrap the branch or the control
return const _EmptyState().withTestId(HomeKeys.emptyState);

_NewTodoFab(visible: v, onPressed: p).withTestId(HomeKeys.addTodoFab)

TestId(HomeKeys.todoList, child: RefreshIndicator(...))
```

Widget tests then use `find.byKey(const Key(HomeKeys.emptyState))`; flows use `id: "home_empty_state"`. The string is the contract across both — do not rename it without updating the flow.

Where the ids live:

- A feature widget uses its feature's `{feature}_keys.dart`.
- A shared widget in `lib/core/ui/` belongs to no feature, so it keeps its ids in a `{widget}_keys.dart` next to it: `lib/core/ui/error_notice_keys.dart` for `error_notice.dart`.

A `TextField` is the one case where the inner widget also wants the raw `Key` (so `find.byKey` targets the field itself rather than the wrapper); tag the wrapper with `TestId` for Maestro and put `key: const Key(...)` on the `TextField` too.

## Splitting a large `build()`

[ADR-0018](../../../docs/adr/0018-widget-construction-discipline.md). When `build()` grows, extract a **widget class**, never a method.

```dart
// ❌ a method that returns a widget: no const, no Observer boundary,
//    rebuilds with the parent, cannot be pumped on its own
Widget _buildHeader() => Text(LocaleKeys.homePage_title.tr());

// ✅ a real widget, file-private
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) => Text(LocaleKeys.homePage_title.tr());
}
```

Never pass `BuildContext` into a helper. Helpers take plain data; the widget that owns the context uses it directly, and anything that has to act from outside a build phase goes through `AppNavigator` ([ADR-0008](../../../docs/adr/0008-appnavigator-routing-abstraction.md)).

The only exceptions are framework `builder:` callbacks whose signature the framework fixes (`ListView.builder`, `LayoutBuilder`, `ValueListenableBuilder`, `showModalBottomSheet`, …) and extension methods on `BuildContext` such as `context.geist` and `context.read<T>()`.

## Choosing a hook

[ADR-0019](../../../docs/adr/0019-hook-selection.md). Pick by **what should rebuild**, not by habit.

| Need | Use |
|---|---|
| Local value that only part of the widget reads | `useValueNotifier` + `ValueListenableBuilder` |
| Local value that legitimately changes the whole widget | `useState` |
| A controller | `useTextEditingController`, `useScrollController`, `useFocusNode`, `useAnimationController` |
| Anything allocated in `build()` — derived lists, parsed values, formatters | `useMemoized(() => …, [keys])` |
| Side effect with cleanup | `useEffect` |

```dart
// ❌ useState from a scroll listener: every direction change rebuilds
//    the whole page (app bar, filters, list Observer) to move one button
final fabVisible = useState(true);
// ...
floatingActionButton: _NewTodoFab(visible: fabVisible.value, ...),

// ✅ only the FAB rebuilds
final fabVisible = useValueNotifier(true);
// ...
floatingActionButton: ValueListenableBuilder<bool>(
  valueListenable: fabVisible,
  builder: (_, visible, _) => _NewTodoFab(visible: visible, ...),
),
```

That was a real defect on the Home page, fixed alongside this rule.

A `useMemoized` with a missing key returns a stale value. Treat the key list with the same care as a `useEffect` dependency list.

## Motion

Use the primitives in `lib/core/ui/geist_motion.dart` — `PressScale` for tap feedback, `FadeSlideIn` for entry, `AnimatedCount` for numbers. They already respect `MediaQuery.disableAnimationsOf`. Durations come from `GeistDuration`; never hardcode a `Duration` in `lib/`.

## Checklist

- [ ] `Provider` root + `_Content` child; `getIt` only inside `create:`
- [ ] State injected, never passed as a parameter
- [ ] No `context.router`; `AppNavigator` in the state
- [ ] `Observer` scoped to the smallest reactive subtree
- [ ] No `Widget _buildX()` methods; no `BuildContext` passed into helpers
- [ ] `useValueNotifier` where only part of the widget reads a value; `useMemoized` for values built in `build()`
- [ ] Loading / error / empty / content all handled, each tagged with `TestId`
- [ ] Rows that can be removed or inserted: `ValueKey(item.id)` on the returned widget, plus `findItemIndexCallback` (`.separated`) or `findChildIndexCallback` (`.builder`)
- [ ] Tokens + `LocaleKeys` only
- [ ] Ids are Strings in `{feature}_keys.dart` (a `lib/core/ui/` widget: `{widget}_keys.dart` next to it), applied with `TestId` — never a bare `Key`
- [ ] Semantics labels on interactive widgets, sourced from `LocaleKeys`
- [ ] `melos run build` after adding `@RoutePage` or MobX annotations
