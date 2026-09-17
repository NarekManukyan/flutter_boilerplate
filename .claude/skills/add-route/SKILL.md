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

`AppRouter` is not registered in DI. `AppNavigator` (a `@singleton`) builds it and hands it its guards, which get their dependencies through the constructor ([ADR-0007](../../../docs/adr/0007-di-scopes-and-constructor-injection.md)):

```dart
@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends RootStackRouter {
  AppRouter({required AuthGuard authGuard}) : _authGuard = authGuard;

  final AuthGuard _authGuard;

  @override
  late final List<AutoRoute> routes = [
    AutoRoute(
      initial: true,
      path: '/',
      page: SplashRoute.page,
      // No guard: SplashPageState decides between home and login.
    ),
    AutoRoute(path: '/login', page: LoginRoute.page),
    AutoRoute(path: '/home', page: HomeRoute.page, guards: [_authGuard]),
    // Illustrative: nested routes. The template has none.
    AutoRoute(
      path: '/dashboard',
      page: DashboardRoute.page,
      guards: [_authGuard],
      meta: const {'description': 'Signed-in dashboard with its tabs'},
      children: [
        AutoRoute(path: 'agenda', page: AgendaRoute.page),
        AutoRoute(path: 'meetings', page: MeetingsListRoute.page),
      ],
    ),
  ];
}
```

The real router is [`lib/core/navigation/app_router.dart`](../../../lib/core/navigation/app_router.dart); it also has `/todos/:id` and `/challenges/joined`, both guarded.

- `replaceInRouteName: 'Page,Route'` is why `LoginPage` generates `LoginRoute`. Always use the generated class, never a string.
- **Paths are kebab-case** and describe the page: `/login`, `/sign-up-with-email`. Children use relative paths.
- Give a new route `meta: {'description': …}`; it is what makes the router readable a year later. The template's own routes do not carry one yet.
- **The initial route is not guarded.** A guard on `/` let a signed-in user through to the splash page and left them there. `SplashPageState.init` reads the token and replaces the stack with Home or Login.

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
| `navigatePath(path)` | navigate by path string (deep-link style) |
| `canPop()` | whether the router can pop |
| `showModal({builder, …})` | modal bottom sheet |
| `showScaffoldMessage(widget)` | bottom overlay notification, used by `IssueTrackingService` |
| `showFullScreenLoading()` / `hideFullScreenLoading()` | blocking spinner dialog, and pop it |
| `openPhoneSettings()` | the app's page in system settings |

`showAppDialog`, `showErrorMessage` and `showSuccessMessage` also exist, but their bodies are empty: calling them shows nothing. Implement one before a state relies on it.

## Guards

Guards extend `AutoRouteGuard`, live in `lib/core/guards/`, and are listed on the route they protect. They are not registered in DI: `AppNavigator` constructs each one with its dependencies and passes it to `AppRouter` (`AppRouter(authGuard: AuthGuard(authStore))`), so a new guard is a new `AppRouter` constructor parameter too.

```dart
class AuthGuard extends AutoRouteGuard {
  AuthGuard(this._authStore);

  final AuthStore _authStore;

  @override
  Future<void> onNavigation(
    NavigationResolver resolver,
    StackRouter router,
  ) async {
    // Reads the stored token, which sets isAuthed on a cold start.
    await _authStore.getAccessToken();

    if (!_authStore.isAuthed) {
      resolver.redirectUntil(const LoginRoute());
      return;
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

A modal with its own state is not a feature ([ADR-0005](../../../docs/adr/0005-flat-feature-tree.md)): it has no route. It lives inside the feature that opens it, at `lib/features/{feature}/modals/{modal}/`, with `view/` for the widget, `mobx/` for its state and `use_cases/` when it has one, as `home/modals/add_todo_modal/` does ([`create-feature`](../create-feature/SKILL.md#directory-shape)). Its widget is a page root: `Provider(create: (_) => getIt<AddTodoModalState>())`.

## E2E

`clearState: true` in a Maestro flow clears the auth token, so splash sends the app to login and a guarded route redirects there. Flows start from the shared `common/start_home.yaml` subflow rather than assuming a signed-in state ([`write-maestro-flow`](../write-maestro-flow/SKILL.md)).

## Checklist

- [ ] `@RoutePage()` on the page, `melos run build` run
- [ ] `AutoRoute` entry added with a kebab-case path and a `meta` description; no guard on the initial route
- [ ] Generated `{Page}Route` class used, never a path string
- [ ] Parameters are ids, not objects a deep link could not rebuild
- [ ] Navigation only from a state class via `AppNavigator`; no `context.router` anywhere
- [ ] Guards live in `lib/core/guards/`, are constructed by `AppNavigator` with their dependencies, and every path calls `next()` or `redirectUntil()`
- [ ] Deep link into the route works from a cold start
