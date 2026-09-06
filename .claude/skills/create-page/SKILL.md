---
name: create-page
description: Build a page and its MobX page state — Provider root, context.read access, HookWidget for local state, AppNavigator for navigation, Observer for reactive rebuilds, and the loading/empty/error branches. Use when adding or modifying any screen, modal or route-level widget.
---

# Create a page + page state

Governed by [ADR-0009](../../../docs/adr/0009-provider-based-state-access.md) (Provider access), [ADR-0010](../../../docs/adr/0010-hookwidget-default.md) (HookWidget), [ADR-0008](../../../docs/adr/0008-appnavigator-routing-abstraction.md) (navigation), [ADR-0002](../../../docs/adr/0002-state-vs-store-separation.md) (state vs store).

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

Each branch needs a key (below) so the Maestro failure and edge flows can assert it.

## Keys and semantics

Every widget an E2E flow touches carries a stable `Key` from the feature's key file, and every interactive widget carries a `Semantics` label from `LocaleKeys` ([ADR-0015](../../../docs/adr/0015-mandatory-test-coverage-and-qa-gate.md)).

```dart
// lib/features/home/view/home_keys.dart
class HomeKeys {
  HomeKeys._();
  static const addTodoFab = Key('home_add_todo_fab');
  static const todoList = Key('home_todo_list');
  static const emptyState = Key('home_empty_state');
  static const errorState = Key('home_error_state');
  static const errorRetry = Key('home_error_retry');
}
```

Maestro selects on the accessibility id, so the string inside `Key(...)` is the contract — do not rename it without updating the flow.

## Motion

Use the primitives in `lib/core/ui/geist_motion.dart` — `PressScale` for tap feedback, `FadeSlideIn` for entry, `AnimatedCount` for numbers. They already respect `MediaQuery.disableAnimationsOf`. Durations come from `GeistDuration`; never hardcode a `Duration` in `lib/`.

## Checklist

- [ ] `Provider` root + `_Content` child; `getIt` only inside `create:`
- [ ] State injected, never passed as a parameter
- [ ] No `context.router`; `AppNavigator` in the state
- [ ] `Observer` scoped to the smallest reactive subtree
- [ ] Loading / error / empty / content all handled, each with a key
- [ ] Tokens + `LocaleKeys` only
- [ ] Keys in `{feature}_keys.dart`, semantics labels on interactive widgets
- [ ] `melos run build` after adding `@RoutePage` or MobX annotations
