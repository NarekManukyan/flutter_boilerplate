# 8. `AppNavigator` Routing Abstraction

- Status: Accepted
- Date: 2026-05-08
- Deciders: Flutter team

## Context and Problem Statement

`auto_route` exposes navigation through `context.router`, which is convenient inside widgets but couples every page to the routing library and ties navigation calls to the `BuildContext`. Tests of state classes can't drive navigation without pumping a widget tree; swapping the routing library means rewriting every `context.router.push(...)` site.

The boilerplate already wraps navigation behind `AppNavigator` — this ADR captures why and pins the rule.

## Decision Drivers

- Testability — state classes own navigation; their tests should not pump widgets.
- Decoupling — features depend on navigation behavior, not on `auto_route` specifics.
- Single ownership — one class owns route configuration; pages don't reach into the router.

## Considered Options

- **`AppNavigator` wrapper, single `@singleton`, injected into states**.
- **`context.router` everywhere** — pages call `auto_route` directly.
- **Mixed — `AppNavigator` for cross-feature flows, `context.router` for in-feature**.

## Decision Outcome

Chosen option: **`AppNavigator` wrapper**.

[`AppNavigator`](../../lib/core/navigation/app_navigator.dart) is a `@singleton` that owns the `AppRouter` and exposes `push`, `pop`, `popUntilRoot`, `popUntilRouteWithName`, `navigatePath`, etc. It is injected into state classes via constructor, never resolved through `context`.

Hard rules:

- Pages **never** call `context.router` directly.
- Pages call methods on their state class; the state class calls `AppNavigator`.
- `AppNavigator.config` (a `RouterConfig<UrlState>`) is consumed once by `MaterialApp.router` in [`lib/app.dart`](../../lib/app.dart).

```dart
// ❌ Forbidden in a page
context.router.push(const SettingsRoute());

// ✅ Correct — in *_state.dart
abstract class _SettingsPageStateBase with Store {
  final AppNavigator _appNavigator;
  _SettingsPageStateBase(this._appNavigator);

  @action
  void openProfile() => _appNavigator.push(const ProfileRoute());
}
```

### Consequences

- Good: state-class tests drive navigation by stubbing `AppNavigator` — no widget pumping.
- Good: routing-library swap is one file, not a sweep across the codebase.
- Good: navigation calls appear only in state classes — easy to audit.
- Bad: trivial pushes still go through a state method.
- Bad: `AppNavigator`'s API surface grows over time (every new navigation primitive needs a method).

## Pros and Cons of the Options

### `AppNavigator` wrapper
- Good: testable, decoupled, single source of truth.
- Bad: indirection for trivial navigation.

### `context.router` everywhere
- Good: zero indirection.
- Bad: state-class tests require widget tree; routing-library swap is a sweep.

### Mixed
- Good: lets simple navigation stay terse.
- Bad: arbitrary line; "in-feature" definition drifts; reviewers can't tell which side a call should be on.

## Links

- [ADR-0001 Layered architecture](0001-layered-architecture.md)
- [ADR-0007 DI scopes and constructor injection](0007-di-scopes-and-constructor-injection.md)
- Code: [lib/core/navigation/app_navigator.dart](../../lib/core/navigation/app_navigator.dart), [lib/core/navigation/app_router.dart](../../lib/core/navigation/app_router.dart)
