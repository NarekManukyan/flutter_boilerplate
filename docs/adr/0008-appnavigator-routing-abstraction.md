# 8. `AppNavigator` Routing Abstraction

- Status: Accepted
- Date: 2026-05-08
- Deciders: Flutter team

## Context and Problem Statement

`auto_route` exposes navigation through `context.router`, which is convenient inside widgets but couples every page to the routing library and ties navigation calls to the `BuildContext`. Tests of state classes can't drive navigation without pumping a widget tree; swapping the routing library means rewriting every `context.router.push(...)` site.

Navigation called from widgets also leaves cross-cutting concerns without a home. Route analytics, guards and deep-link mapping would each have to be repeated at every call site.

The boilerplate already wraps navigation behind `AppNavigator` — this ADR captures why and pins the rule.

## Decision Drivers

- Testability — state classes and navigation use cases own navigation; their tests should not pump widgets.
- Decoupling — features depend on navigation behavior, not on `auto_route` specifics.
- Single ownership — one class owns route configuration; pages don't reach into the router.
- One seam — route analytics, guards and deep-link mapping need a single place to attach.

## Considered Options

- **`AppNavigator` wrapper, single `@singleton`, injected into states and navigation use cases**.
- **`context.router` everywhere** — pages call `auto_route` directly.
- **Mixed — `AppNavigator` for cross-feature flows, `context.router` for in-feature**.
- **Per-feature navigators or route services** — each feature wraps the router in its own class.

## Decision Outcome

Chosen option: **`AppNavigator` wrapper**.

[`AppNavigator`](../../lib/core/navigation/app_navigator.dart) is a `@singleton` that owns the `AppRouter` and exposes `push`, `pop`, `popUntilRoot`, `popUntilRouteWithName`, `navigatePath`, etc. It is injected through the constructor into state classes and into navigation use cases (Type 2 in [ADR-0004](0004-use-case-taxonomy-and-colocation.md), such as [`OpenTodoDetailsUseCase`](../../lib/core/use_cases/open_todo_details_use_case.dart)). It is never resolved through `context`.

`AppNavigator` is the single seam for route analytics, guards and deep-link mapping. A new cross-cutting navigation concern is added there, or to the `AppRouter` it owns, and never at call sites. `AuthGuard` is already wired this way: `AppNavigator` constructs it and hands it to the router.

Hard rules:

- Widgets **never** navigate through the context. That means no `context.router`, no `Navigator.of(context)` and no `Navigator.pop(context)`. The rule also covers throwaway places, such as a close button, a back arrow or a dialog's cancel action.
- Pages call methods on their state class; the state class calls `AppNavigator`, directly or through a navigation use case.
- A reusable widget with no state class of its own takes a callback (`VoidCallback onBack`) when it needs to navigate. Whoever owns a state class decides where the callback goes; the widget never calls the router.
- `AppNavigator.config` (a `RouterConfig<UrlState>`) is consumed only by `MaterialApp.router` in [`lib/app.dart`](../../lib/app.dart), which is keyed on `dependencyGeneration` so a DI reset mounts the new navigator's router.

```dart
// ❌ Forbidden in a widget, including one-line cases
context.router.push(const SettingsRoute());
Navigator.of(context).pop();

// ✅ Correct — in *_state.dart
abstract class _SettingsPageStateBase with Store {
  final AppNavigator _appNavigator;
  _SettingsPageStateBase(this._appNavigator);

  @action
  void openProfile() => _appNavigator.push(const ProfileRoute());

  @action
  Future<void> close() => _appNavigator.pop();
}

// ✅ Correct — a reusable widget without a state class takes a callback
class SheetHeader extends StatelessWidget {
  const SheetHeader({required this.onClose, super.key});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) =>
      IconButton(onPressed: onClose, icon: const Icon(Icons.close));
}
```

### Consequences

- Good: state-class and use-case tests drive navigation by stubbing `AppNavigator`, with no widget pumping.
- Good: routing-library swap is one file, not a sweep across the codebase.
- Good: route analytics, guards and deep-link mapping have one place to live.
- Good: navigation calls appear only in state classes and navigation use cases, and both inject `AppNavigator`, so they are easy to audit.
- Bad: trivial pushes and pops still go through a state method, including a dialog's cancel button.
- Bad: reviewers have to enforce the rule in throwaway places, where calling `Navigator` directly looks harmless.
- Bad: `AppNavigator`'s API surface grows over time (every new navigation primitive needs a method).

## Pros and Cons of the Options

### `AppNavigator` wrapper
- Good: testable, decoupled, single source of truth, one seam for cross-cutting concerns.
- Bad: indirection for trivial navigation.

### `context.router` everywhere
- Good: zero indirection.
- Bad: state-class tests require widget tree; routing-library swap is a sweep; analytics must be added per call site.

### Mixed
- Good: lets simple navigation stay terse.
- Bad: arbitrary line; "in-feature" definition drifts; reviewers can't tell which side a call should be on.

### Per-feature navigators or route services
- Good: each feature owns its routing surface.
- Bad: cross-cutting concerns fragment across features, and there is no single seam for analytics, guards or deep links. It keeps the problems of calling the router directly and adds a file per feature.

## Links

- [ADR-0001 Layered architecture](0001-layered-architecture.md)
- [ADR-0004 Use-case taxonomy and colocation](0004-use-case-taxonomy-and-colocation.md)
- [ADR-0007 DI scopes and constructor injection](0007-di-scopes-and-constructor-injection.md)
- Code: [lib/core/navigation/app_navigator.dart](../../lib/core/navigation/app_navigator.dart), [lib/core/navigation/app_router.dart](../../lib/core/navigation/app_router.dart)
