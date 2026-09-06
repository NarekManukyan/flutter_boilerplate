---
name: add-route
description: Register a screen with AutoRoute — the @RoutePage annotation, router entry, path and naming conventions, route parameters, nested routes, guards, modals and dialogs, and the AppNavigator methods states call. Use when adding a screen to the router, adding a guard, or navigating somewhere new.
---

# Add a route

Governed by [ADR-0008](../../../docs/adr/0008-appnavigator-routing-abstraction.md). The router lives in `lib/core/navigation/`; guards in `lib/core/guards/`.

## The loop

1. Annotate the page with `@RoutePage()` ([`create-page`](../create-page/SKILL.md)).
2. Run `melos run build` — this generates the `{PageName}Route` class in `app_router.gr.dart`.
3. Add an `AutoRoute` entry to `AppRouter.routes`.
4. Navigate to it from a **state class** via `AppNavigator`. Never from a widget.

## Router entry

```dart
@singleton
@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends RootStackRouter {
  @override
  late final List<AutoRoute> routes = [
    AutoRoute(
      initial: true,
      path: '/',
      page: SplashRoute.page,
      guards: [authGuard],
      meta: const {'description': 'Splash screen, entry point of the app'},
    ),
    AutoRoute(
      page: LoginRoute.page,
      path: '/login-page',
      meta: const {'description': 'Login page for user authentication'},
    ),
    AutoRoute(
      path: '/dashboard',
      page: DashboardRoute.page,
      children: [
        AutoRoute(path: 'agenda', page: AgendaRoute.page),
        AutoRoute(path: 'meetings', page: MeetingsListRoute.page),
      ],
    ),
  ];
}
```

- `replaceInRouteName: 'Page,Route'` is why `LoginPage` generates `LoginRoute`. Always use the generated class, never a string.
- **Paths are kebab-case** and describe the page: `/login-page`, `/sign-up-with-email`. Children use relative paths.
- `meta: {'description': …}` on every route — it is what makes the router readable a year later.

## Parameters

Passed through the generated route's constructor, `const` wherever possible:

```dart
await _appNavigator.push(TodoDetailsRoute(todoId: id));
await _appNavigator.push(const SettingsRoute());
```

Optional values are named parameters. Do not pass objects a deep link could not reconstruct — pass an id and let the target load it.

## Navigating — from the state class only

```dart
// ❌ FORBIDDEN, anywhere in a widget
context.router.push(const SettingsRoute());

// ✅ inject AppNavigator into the state
abstract class _MyPageStateBase with Store {
  final AppNavigator _appNavigator;
  _MyPageStateBase(this._appNavigator);

  @action
  Future<void> onSettingsPressed() =>
      _appNavigator.push(const SettingsRoute());
}
```

Pages call the state method. If a navigation decision has real logic in it, extract a Navigation use case ([`create-use-case`](../create-use-case/SKILL.md)).

### `AppNavigator` methods

| Method | Does |
|---|---|
| `push(route)` | push a new route |
| `pop<T>({result})` | pop the current route |
| `popUntilRoot()` | pop to the root |
| `popUntilRouteWithName(name)` | pop back to a named route |
| `replace(route)` | replace the current route |
| `pushAndPopAll(route)` | replace the whole stack — use after login and logout |
| `showModal({builder})` | modal bottom sheet |
| `showAlertDialog({content})` | alert dialog |
| `showAppDialog({title, content, actions})` | adaptive dialog |

## Guards

`@injectable`, extend `AutoRouteGuard`, live in `lib/core/guards/`, and are listed on the route they protect.

```dart
@injectable
class AuthGuard extends AutoRouteGuard {
  final AuthStore _authStore;

  const AuthGuard(this._authStore);

  @override
  Future<void> onNavigation(
    NavigationResolver resolver,
    StackRouter router,
  ) async {
    if (!_authStore.isLoggedIn) {
      return resolver.redirectUntil<void>(const LoginRoute());
    }
    resolver.next();
  }
}
```

Every path must end in exactly one of `resolver.next()` or `resolver.redirectUntil(...)`. A guard that returns without calling either hangs the navigation with no error.

## Modals and dialogs

Reached through `AppNavigator`, not `showModalBottomSheet` directly, so the state layer stays the only thing that knows about presentation:

```dart
await _appNavigator.showModal(builder: (_) => const AddTodoModal());
```

A modal with its own store or state is a feature module with `view/` + `mobx/`, not a loose widget ([`create-feature`](../create-feature/SKILL.md)).

## E2E

`clearState: true` in a Maestro flow clears the auth token, so a guarded route sends the app back to login. Flows start from the shared `common/start_home.yaml` subflow rather than assuming a signed-in state ([`write-maestro-flow`](../write-maestro-flow/SKILL.md)).

## Checklist

- [ ] `@RoutePage()` on the page, `melos run build` run
- [ ] `AutoRoute` entry added with a kebab-case path and a `meta` description
- [ ] Generated `{Page}Route` class used, never a path string
- [ ] Parameters are ids, not objects a deep link could not rebuild
- [ ] Navigation only from a state class via `AppNavigator`; no `context.router` anywhere
- [ ] Guards are `@injectable`, in `lib/core/guards/`, and every path calls `next()` or `redirectUntil()`
- [ ] Deep link into the route works from a cold start
