# Architecture Overview

How the boilerplate fits together, traced through its real code. Read it on your first day, or before you plan work that crosses layers, such as a feature that needs a new endpoint, a store, a modal and an E2E flow. This guide is the map. The rules are in [`AGENTS.md`](../AGENTS.md), the steps for building each artifact are in the playbooks under [`.claude/skills/`](../.claude/skills/), and the reasons are in the [ADRs](adr/README.md). If this guide disagrees with an ADR or a playbook, the ADR or playbook wins.

## Architecture Principles

### Layers and packages

```
lib/ (the app)
  UI        *_page.dart, *_widget.dart
   │        context.read<T>() for the state, Observer for rebuilds
   ▼
  State     *_state.dart ───────────┬──────────► AppNavigator
   │                                ▼
   │                          Use Case  *_use_case.dart ──► AppNavigator, IssueTrackingService,
   ▼                                ▲         │              FlavorService, other services
  Store     *_store.dart ───────────┘         │
   │                                          │
   ▼                                          │
  DioService + interceptors  ◄────────────────┘
─ ─ ─ ─ ─ ─ ─ ─ ─ ─ package boundary ─ ─ ─ ─ ─ ─ ─ ─ ─ ─
  packages/api             @RestApi providers, @freezed DTOs
  packages/design_system   GeistTheme tokens, components (imported by widgets)
```

Each layer calls only the ones its arrows reach. A widget calls its state. A state calls stores, use cases and `AppNavigator`. A store calls `DioService`, other stores and use cases. A use case calls `DioService`, services and `AppNavigator`, but never a store or another use case. The full access matrix is in [`AGENTS.md`](../AGENTS.md#architecture), and the reasoning is in [ADR-0001](adr/0001-layered-architecture.md).

### Key principles

- **Widgets hold no logic.** The page root creates the state with `Provider`, descendants read it with `context.read<T>()`, and each visual piece is a real widget class ([ADR-0009](adr/0009-provider-based-state-access.md), [ADR-0018](adr/0018-widget-construction-discipline.md)).
- **State vs store.** A `*_state.dart` belongs to one screen and has no API access. A `*_store.dart` owns data and API access ([ADR-0002](adr/0002-state-vs-store-separation.md)).
- **Use cases take services, not stores.** The state or store that calls a use case composes the flow ([ADR-0003](adr/0003-no-use-case-to-use-case-dependencies.md), [ADR-0004](adr/0004-use-case-taxonomy-and-colocation.md)).
- **Navigation goes through `AppNavigator`**, never through `context.router` or `Navigator` ([ADR-0008](adr/0008-appnavigator-routing-abstraction.md)).
- **Constructor injection.** `getIt` is called only at bootstrap and in `Provider(create:)` ([ADR-0007](adr/0007-di-scopes-and-constructor-injection.md)).
- **Every `catch` rethrows or tracks** through `IssueTrackingService` ([ADR-0020](adr/0020-error-handling-and-issue-tracking.md)).

## Project architecture

The app and its two packages resolve as one Dart workspace (`workspace:` in [`pubspec.yaml`](../pubspec.yaml)). Dependencies point in one direction only:

```
             app (lib/)
            /          \
           ▼            ▼
   packages/api    packages/design_system
```

Neither package imports the other or the app ([ADR-0014](adr/0014-melos-package-split.md#dependency-direction)). The two meet in the app: a store turns DTOs into observables, and a widget passes plain values into design-system components. `DioService`, the interceptors and `IssueTrackingService` are app code and live in `lib/core/services/`, not in `packages/api`.

To find where a file goes (`view/`, `mobx/`, `modals/`, `lib/core/`), see [`project-structure.md`](project-structure.md).

## Bootstrap sequence

1. **Entry point.** `lib/main_dev.dart` calls `app.run()`, and `lib/main_prod.dart` calls `app.run(env: FlavorType.PROD)`. `lib/main.dart` also has a `main()` that runs the dev flavor.
2. **`run()`** (`lib/main.dart:17`) calls `WidgetsFlutterBinding.ensureInitialized()`, locks portrait orientation, and awaits `EasyLocalization.ensureInitialized()`.
3. **DI.** `registerGetIt(env)` (`lib/core/services/get_it.dart:4`) calls `configureDependencies(flavorType)` (`lib/injectable.dart:16`), which runs `getIt.init(environment: flavorType.name)`. Every eager singleton is built at this point (see [Dependency injection](#dependency-injection)).
4. **Sentry**, outside debug builds only: `SentryFlutter.init` reads the DSN with `getIt<FlavorService>().config.sentryDsn` (`lib/main.dart:37`) and starts the app through `appRunner: _runApp`. A debug build calls `_runApp()` directly.
5. **`_runApp()`** (`lib/main.dart:47`) calls `runApp(EasyLocalization(..., child: const MyApp()))`.
6. **`MyApp`** (`lib/app.dart`), a `HookWidget`, wraps `OverlaySupport.global`, which `IssueTrackingService` notices need, around `MaterialApp.router`. Here it passes `routerConfig: getIt<AppNavigator>().config` and the light and dark themes from `design_system`, reads the debug-banner flag from `FlavorService`, and keys the router on `dependencyGeneration` (see [Logout reset](#dependency-injection)).
7. **`builder:`** wraps the router's output in `ConnectionWrapperPage` (`lib/features/app/view/connection_wrapper_page.dart`). It sits above every route, keeps the router's child mounted, and lays the offline screen over it in a `Stack` while `ConnectionWrapperState.hasConnection` (`ConnectivityStore`, debounced) is false.
8. **Initial route.** `/` is `SplashRoute`, with no guard. `SplashPage` provides `SplashPageState` with `lazy: false`, and its `init()` awaits `AuthStore.getAccessToken()`, then calls `pushAndPopAll` with `HomeRoute` or `LoginRoute`. `AuthGuard` (`lib/core/guards/auth_guard.dart`) protects the other signed-in routes: it awaits the same call, then calls `redirectUntil(const LoginRoute())` or `next()`. Signing in (`LoginPageState.onContinuePressed`) calls `AuthStore.login` and then `pushAndPopAll(const HomeRoute())`.

`getIt` appears in steps 3, 4 and 6, and after that only inside `Provider(create:)` ([ADR-0007](adr/0007-di-scopes-and-constructor-injection.md#where-getit-may-be-called)).

## A request, end to end

### Home loads todos

```
HomePage ──Provider(create:)──► HomePageState.init() ──► HomeStore.loadTodos()
                                                            │
      mock (dev) → api → auth → log ◄── todosProvider.getTodos() ◄┘
                    │
      Retrofit ──► TodoDto.fromJson ──► _todos (ObservableList) ──► Observer rebuilds HomePage
```

1. **Page root** (`lib/features/home/view/home_page.dart:26`):
   ```dart
   return Provider<HomePageState>(
     create: (_) => getIt<HomePageState>()..init(),
     dispose: (_, state) => state.dispose(),
     child: const _HomePageContent(),
   );
   ```
2. **State → store.** `HomePageState.init()` (`home_page_state.dart:52`) calls `_homeStore.loadTodos()`. The state never sees `DioService`.
3. **Store → API.** `HomeStore.loadTodos()` (`lib/features/home/mobx/home_store.dart:32`) sets `_isLoading`, clears `_error` and calls `_dioService.todosProvider.getTodos()`. It calls the provider inline because this is the store's own load ([`create-store`](../.claude/skills/create-store/SKILL.md#inline-request-or-use-case)).
4. **Interceptors.** `DioService.initDio()` (`lib/core/services/dio_service.dart:29`) installs `MockTodosInterceptor` (dev only), `ApiInterceptor` (base URL, strips `runtimeType` keys), `AuthInterceptor` (bearer token for the API host only, session cleared on `401`) and `LogInterceptor` (not in prod, no headers). In dev, the mock answers every `/todos` request from `onRequest` with `handler.resolve`, so the interceptors after it never run for that request.
5. **Retrofit → DTO.** `TodosApiProvider.getTodos()` (`packages/api/lib/src/providers/todos_provider/todos_api_provider.dart:19`) is implemented in the generated `todos_api_provider.g.dart`, which maps every item through `TodoDto.fromJson`.
6. **Observable.** `_todos = ObservableList.of(result)`, and `finally` resets `_isLoading`.
7. **Rebuild.** An `Observer` around the body (`home_page.dart:70`) reads `state.isLoading`, `state.error` and `state.todos`, getters on `HomePageState` that proxy `HomeStore`, and renders the skeleton, error, empty or list branch. The rows come from `state.visibleTodos`, a `@computed` over the store's todos and the state's `filter`. Pull to refresh calls `state.init` again.

**Failure.** The store catches every error, tracks it as handled, and sets the observable the page renders (`home_store.dart:38`). It catches everything, not only `DioException`, because the generated Retrofit client rethrows a response that fails `fromJson` unchanged:

```dart
} catch (e, stackTrace) {
  _issueTrackingService.trackHandledError(
    e,
    stackTrace: stackTrace,
    handlingContext: 'load_todos',
  );
  _error = e is DioException ? e.message : e.toString();
}
```

When `error` is non-null, the `Observer` renders `_ErrorState(onRetry: state.init)`, tagged `HomeKeys.errorState`, with a retry button tagged `HomeKeys.errorRetry`. The user sees one message, from the page. `trackHandledError` reports the error to Sentry without showing a notice. `.maestro/flows/home/home_todos_failure.yaml` drives this branch through the mock's `serverError` scenario.

### Adding a todo from the modal

1. **FAB → state.** `_NewTodoFab(onPressed: state.onAddTodoPressed)` (`home_page.dart:155`). The widget calls the state and never calls the use case.
2. **State → navigation use case.** `HomePageState.onAddTodoPressed()` calls `ShowAddTodoModalUseCase` (`lib/features/home/view/use_cases/show_add_todo_modal_use_case.dart`), which sits in `view/use_cases/` because only the view layer uses it:
   ```dart
   await _appNavigator.showModal(builder: (_) => const AddTodoModal());
   ```
3. **Modal root.** `AppNavigator.showModal` opens a bottom sheet on the router's navigator context. `AddTodoModal` (`lib/features/home/modals/add_todo_modal/view/add_todo_modal.dart:24`) is a page root of its own: `Provider(create: (_) => getIt<AddTodoModalState>())`.
4. **Submit → state.** The primary button, or the keyboard's done action, calls `state.onSubmit()`, which returns at once while a submit is already loading.
5. **State composes the flow** (`add_todo_modal_state.dart:33`, comment trimmed):
   ```dart
   final todo = await _createTodoUseCase(titleController.text.trim());
   if (todo == null) {
     _hasError = true;
     return;
   }
   await _homeStore.addTodo(todo);
   await _appNavigator.pop();
   ```
   The state sequences the steps because `CreateTodoUseCase` may not inject `HomeStore` ([ADR-0003](adr/0003-no-use-case-to-use-case-dependencies.md)).
6. **API use case.** `CreateTodoUseCase.call` (`lib/features/home/modals/add_todo_modal/use_cases/create_todo_use_case.dart:16`) posts a `TodoCreateRequestDto` through `todosProvider.createTodo`. On any failure it calls `trackHandledError(..., handlingContext: 'create_todo')` and returns `null`, following pattern 1 in [`handle-errors`](../.claude/skills/handle-errors/SKILL.md).
7. **Success.** `HomeStore.addTodo` appends to `_todos`. The Home `Observer` under the sheet rebuilds, and `pop()` closes the sheet.
8. **Failure.** `_hasError` flips, and an `Observer` renders `LocaleKeys.addTodoModal_error` tagged `AddTodoModalKeys.errorText`. The sheet stays open with the input intact. `loadingState.stopLoading()` runs in `finally`.

## State management

MobX, split into stores and states. The full detail is in [`state-management-guide.md`](state-management-guide.md).

- **Store** (`features/*/mobx/*_store.dart`) owns data and API access. It is `@injectable` or `@singleton`, and every store lives under its owning feature, even a singleton ([ADR-0006](adr/0006-feature-owned-singletons.md)).
- **State** (`*_state.dart`) belongs to one screen or modal, is `@injectable`, and is created and disposed by its `Provider`.
- **Feature-agnostic primitives**, such as `LoadingState` (`@readonly isLoading`, set through `startLoading` / `stopLoading`), live in `lib/core/state/` and are composed into states.
- **Widget-local UI state** uses hooks. [ADR-0019](adr/0019-hook-selection.md) says which hook to use and when to use MobX instead.

## API architecture

`@RestApi()` providers and `@freezed` DTOs live in `packages/api` ([ADR-0011](adr/0011-retrofit-typed-api-layer.md)). `DioService` (`@lazySingleton`, built at startup by the eager `HomeStore`) builds one `Dio` with the interceptor chain and exposes a provider per resource (`authProvider`, `todosProvider`) on top of it. A second client, `uploadImageDio`, carries only the logger. Only stores and use cases touch `DioService`. [`use_cases_guide.md`](use_cases_guide.md) covers when a call moves out of a store into a use case. Interceptor order, and what to add per app (no-connection, retry), are in [`create-api-provider`](../.claude/skills/create-api-provider/SKILL.md#interceptors).

## Navigation

- **`AppRouter`** (`lib/core/navigation/app_router.dart`) lists the routes: `/` splash, `/login`, `/home`, `/todos/:id` and `/challenges/joined`. The last three carry `AuthGuard`. Splash has none: `SplashPageState` decides between Home and Login.
- **Pages** carry `@RoutePage()`. `auto_route_generator` writes `app_router.gr.dart` with `SplashRoute`, `LoginRoute`, `HomeRoute`, `TodoDetailsRoute(todoId:)` and `ChallengeJoinedRoute`. `app_navigator.dart` re-exports the router, so importing `AppNavigator` also brings in the route classes.
- **`AppNavigator`** (`@singleton`) receives `AuthStore`, builds `AppRouter(authGuard: AuthGuard(authStore))`, and exposes `config`, which `app.dart` hands to `MaterialApp.router`. It also provides `push`, `pop`, `replace`, `pushAndPopAll`, `popUntilRoot`, `navigatePath`, `showModal`, `showScaffoldMessage` and `context`, the router's navigator context. `showAppDialog`, `showErrorMessage` and `showSuccessMessage` exist but are empty stubs.
- **Callers** are states and navigation use cases only. `ShowAddTodoModalUseCase` is feature-local. `OpenTodoDetailsUseCase` sits in `lib/core/use_cases/` only to illustrate that path: its one consumer is `HomePageState`, so by the consumer rule it belongs in `home/view/use_cases/`. A reusable widget with no state takes a callback instead.
- **Outside the widget tree**, `AuthInterceptor.onError` passes a `401` on to the caller and calls `AuthStore.clearSession()`, once however many requests fail together. The DI reset remounts the router at splash, which sends the user to login.

To add a route, guard or modal, see [`add-route`](../.claude/skills/add-route/SKILL.md). The reasons are in [ADR-0008](adr/0008-appnavigator-routing-abstraction.md).

## Dependency injection

`@InjectableInit` on `configureDependencies` (`lib/injectable.dart:13`) makes `injectable_generator` write `lib/injectable.config.dart`. That file contains one `gh.factory`, `gh.singleton` or `gh.lazySingleton` per annotated class, sorted so that dependencies register first.

| Annotation | Registered as | In this repo |
|---|---|---|
| `@injectable` | factory, new instance per resolve | every state and use case, `IssueTrackingService`, `AppUpdateService` |
| `@singleton` | built during `getIt.init` | `FlavorService`, `AuthStore`, `NotificationsStore`, `AppNavigator`, `ConnectivityStore`, `HomeStore` |
| `@lazySingleton` | built on first resolve | `DioService`, and `Connectivity` from `ThirdPartyModule` |

- **Eager order.** `FlavorService` (`order: -1`), then `NotificationsStore`, `AuthStore`, `AppNavigator` (with its router and guard), `HomeStore` and `ConnectivityStore` (starts listening). `HomeStore` depends on `DioService`, so the lazy `DioService` and its interceptor chain are built during `init` as well.
- **Modules.** `ThirdPartyModule` (`lib/core/services/third_party_module.dart`) registers `Connectivity`, which the app cannot annotate, so `ConnectivityStore` receives it through the constructor and tests can pass a fake.
- **Flavors.** `FlavorDev` and `FlavorProd` are annotated `@Singleton(env: ['DEVELOPMENT'] / ['PROD'], as: FlavorService, order: -1)`. Only the one that matches the `environment` passed to `init` registers. Code that behaves differently per flavor reads `FlavorService`: `isDev` installs the mock interceptor, and `isProduction` drops request logging and makes `LocaleKeys.errors_generic` the fallback notice text.
- **Logout reset.** `HomeStore.logout()` calls `AuthStore.clearSession()`, which removes the token and awaits `resetDependencies()` (`lib/injectable.dart:27`). That calls `getIt.reset()`, which disposes registrations in reverse order (including `disposeConnectivityStore`), re-registers everything under the same flavor, and bumps `dependencyGeneration`. `MyApp` keys `MaterialApp.router` on it, so the new `AppNavigator`'s router is mounted and everything below it, `ConnectionWrapperPage` included, is rebuilt from the new container. Anything outside that subtree that captured an instance keeps the old one.
- **Objects the container does not build** still get constructor arguments. `DioService` passes its injected `FlavorService` into `ApiInterceptor` and `AuthStore` plus the API base URL into `AuthInterceptor`, and `AppNavigator` passes `AuthStore` into `AuthGuard`. A `getIt` call inside an interceptor or guard would hide the dependency and force tests to mock the locator.

The rules for choosing a scope are in [ADR-0007](adr/0007-di-scopes-and-constructor-injection.md).

## Errors across the stack

| Origin | Example | Caught by | What the user sees |
|---|---|---|---|
| Dio: status code, timeout, offline | `getTodos()` returns 500 | store or use case, `catch (e, stackTrace)` | the caller's error UI (error state, inline text) |
| Dio: `401` | expired token | `AuthInterceptor.onError` passes it on and clears the session; the caller's `catch` still runs | splash, then login; the service ignores `401` |
| Dio: cancel | the mock's `/mock` command | the caller's `catch` | whatever the caller renders; never reported |
| Response parsing | `TodoDto.fromJson` on a bad payload | the same store or use case `catch`: the generated provider rethrows it unchanged, which is why API boundaries catch everything | the caller's error UI, as for a failed request |
| Plugin or platform | `Connectivity.checkConnectivity()` | `ConnectivityStore`, `trackSilentError` | nothing; the app stays "online" |
| Offline device | no network | `ConnectivityStore` stream | `ConnectionWrapperPage` offline screen, over the still-mounted routes |

Who tracks and how:

- **`trackHandledError`**, when the caller shows the failure. `HomeStore`, `CreateTodoUseCase` and `FetchTodoUseCase` use it.
- **`trackSilentError`**, for background work nobody is waiting on. `ConnectivityStore` and `AppUpdateService` use it.
- **`trackIssue`**, when nothing else shows the failure. It shows an `ErrorNotice` through `AppNavigator.showScaffoldMessage`, which uses `overlay_support`, which is why `OverlaySupport.global` wraps the app. No code in the template calls `trackIssue` yet.

`IssueTrackingService` filters connectivity errors, cancellations and ignored status codes, so call sites never special-case them. Reports go to Sentry only outside debug builds. Choosing the method, the five use-case patterns and restore-then-rethrow are covered in [`error-handling-guidelines.md`](error-handling-guidelines.md), [`handle-errors`](../.claude/skills/handle-errors/SKILL.md) and [ADR-0020](adr/0020-error-handling-and-issue-tracking.md).

## Design system architecture

`packages/design_system` exports the `GeistTheme` extension (`context.geist.*`), `GeistTextStyles`, `GeistRadius`, `GeistDuration`, the `kSpacingNpx` constants, the legacy Tailor `CustomTheme` getters (`context.backgroundSurface`) and shared components. `app.dart` registers `lightTheme` and `darkTheme`. `lib/` uses tokens only ([ADR-0013](adr/0013-design-system-tokens-only.md)). To add a token, see [`add-design-token`](../.claude/skills/add-design-token/SKILL.md). To add a component, see [`create-ds-component`](../.claude/skills/create-ds-component/SKILL.md).

## Code generation

Generated files are gitignored, so a fresh clone runs `melos run bootstrap` before anything analyzes. Never edit one by hand: change the annotation or input and regenerate.

| Generator | Reads | Writes | Package |
|---|---|---|---|
| `mobx_codegen` | `@readonly`, `@observable`, `@action`, `@computed` | `*_store.g.dart`, `*_state.g.dart` | app |
| `freezed` | `@freezed` | `*.freezed.dart` (DTOs; `Config` in the app) | api, app |
| `json_serializable` | `fromJson` factories, `@JsonLiteral` | DTO `*.g.dart`, `config.g.dart`, `development.g.dart` | api, app |
| `retrofit_generator` | `@RestApi()` | `*_api_provider.g.dart` | api |
| `auto_route_generator` | `@RoutePage()`, `@AutoRouterConfig` | `lib/core/navigation/app_router.gr.dart` | app |
| `injectable_generator` | `@injectable`, `@singleton`, `@lazySingleton`, `@module` | `lib/injectable.config.dart` | app |
| `easy_localization:generate` | `assets/translations/en-US.json` | `lib/gen/locale_keys.g.dart` | app |
| `theme_tailor` | `@tailorMixin` | `custom_theme.tailor.dart` | design_system |
| `flutter_gen_runner` | `flutter_gen:` in the package pubspec | `packages/design_system/lib/gen/*.gen.dart` | design_system |

`melos run build` runs `translations` → `build:api` → `build:design_system` → `build:app`. The app's generators resolve types from both packages, so the packages go first ([ADR-0014](adr/0014-melos-package-split.md#codegen-order)). Within a package, the `build.yaml` files run `freezed` before `json_serializable`, and in `api`, `json_serializable` before `retrofit_generator`. `melos run build:app` and `melos run watch` cover `lib/` only. `melos run bootstrap` is `deps` followed by `build`.

## Testing architecture

A tier is what the test exercises, not a folder: every test mirrors its source file's path.

| Tier | Lives in | Seam faked | Example |
|---|---|---|---|
| Unit | `test/features/{feature}/` (page-state tests sit in `view/`), `test/core/` | `DioService` and providers, services, `AppNavigator` | `home_store_test.dart`, `home_page_state_test.dart`, `issue_tracking_service_test.dart` |
| Widget | `test/features/{feature}/view/` | the page state (registered in `getIt`, or `Provider.value`) | `home_page_test.dart` |
| E2E | `.maestro/flows/{feature}/`, subflows in `.maestro/common/` | the network, through the dev-flavor mock interceptor | `home_todos_failure.yaml` |

- **Harness.** `test/helpers/pump_app.dart` loads translations once (`initLocalizationForTests`), pumps inside the real theme (`pumpApp`) and advances a bounded number of frames (`settleFrames`).
- **E2E seam.** `MockTodosInterceptor` serves a `MockScenario` (`normal`, `empty`, `serverError`, `slow`). A flow switches scenarios at run time by typing `/mock <scenario>` into the add-todo field (`.maestro/common/set_mock.yaml`). A build can start in a scenario with `--dart-define=MOCK_SCENARIO=...`. A new endpoint that a flow uses needs a branch in the mock.
- **Test ids.** `TestId` (`lib/core/ui/test_id.dart`) applies `Semantics(identifier:)` for Maestro and a `Key` for widget tests from one string in the feature's `*_keys.dart`.
- **Runner.** `tool/run_maestro.sh` runs the `.maestro` workspace root with `APP_ID`.

What a feature must ship is in [ADR-0015](adr/0015-mandatory-test-coverage-and-qa-gate.md), [`write-tests`](../.claude/skills/write-tests/SKILL.md), [`write-maestro-flow`](../.claude/skills/write-maestro-flow/SKILL.md) and [`qa-feature`](../.claude/skills/qa-feature/SKILL.md).

## Where to find the rule for X

| Question | Answer lives in |
|---|---|
| Can a use case call a store, or another use case? | [ADR-0003](adr/0003-no-use-case-to-use-case-dependencies.md), [`create-use-case`](../.claude/skills/create-use-case/SKILL.md) |
| Where does a new use case go, and when does it move? | [ADR-0004](adr/0004-use-case-taxonomy-and-colocation.md#location-rules), [`use_cases_guide.md`](use_cases_guide.md) |
| Can a state inject `DioService`? | [ADR-0002](adr/0002-state-vs-store-separation.md) |
| Should a store call the API inline or through a use case? | [`create-store`](../.claude/skills/create-store/SKILL.md#inline-request-or-use-case), [ADR-0011](adr/0011-retrofit-typed-api-layer.md#access-boundary) |
| Where do I put a new store? | [ADR-0006](adr/0006-feature-owned-singletons.md), [`create-store`](../.claude/skills/create-store/SKILL.md) |
| `@injectable`, `@singleton` or `@lazySingleton`? | [ADR-0007](adr/0007-di-scopes-and-constructor-injection.md), [`create-store`](../.claude/skills/create-store/SKILL.md#scope) |
| Can I call `getIt` here? | [ADR-0007](adr/0007-di-scopes-and-constructor-injection.md#where-getit-may-be-called) |
| Who disposes a store, a reaction, a controller? | [`create-store`](../.claude/skills/create-store/SKILL.md#lifecycle-who-disposes-what), [`state-management-guide.md`](state-management-guide.md) |
| Who shows an error, and which tracking method? | [`handle-errors`](../.claude/skills/handle-errors/SKILL.md#pick-the-method-by-who-shows-the-error), [ADR-0020](adr/0020-error-handling-and-issue-tracking.md) |
| A shared store's mutation failed and it has no error observable | [`handle-errors`](../.claude/skills/handle-errors/SKILL.md#stores-restore-then-rethrow) |
| How do I add a route or a guard? | [`add-route`](../.claude/skills/add-route/SKILL.md) |
| How do I open a modal or dialog? | [`add-route`](../.claude/skills/add-route/SKILL.md#modals-and-dialogs), [ADR-0008](adr/0008-appnavigator-routing-abstraction.md) |
| How does a widget without a state navigate? | [ADR-0008](adr/0008-appnavigator-routing-abstraction.md) (it takes a callback) |
| How does a widget get its state? | [ADR-0009](adr/0009-provider-based-state-access.md) |
| `HookWidget`, `StatelessWidget` or `StatefulWidget`? | [ADR-0010](adr/0010-hookwidget-default.md) |
| Hook or MobX? `useState` or `useValueNotifier`? | [ADR-0019](adr/0019-hook-selection.md#which-tool) |
| Can I write `Widget _buildHeader()`? | [ADR-0018](adr/0018-widget-construction-discipline.md) |
| Where do test ids go? | [ADR-0015](adr/0015-mandatory-test-coverage-and-qa-gate.md#test-identifiers-are-part-of-the-feature), [`create-page`](../.claude/skills/create-page/SKILL.md#test-identifiers) |
| How does an E2E flow reach the error branch? | [`write-maestro-flow`](../.claude/skills/write-maestro-flow/SKILL.md#driving-the-failure-and-edge-cases) |
| Where does a DTO go? | [`create-dto`](../.claude/skills/create-dto/SKILL.md), [ADR-0011](adr/0011-retrofit-typed-api-layer.md) |
| In what order do interceptors run? | [`create-api-provider`](../.claude/skills/create-api-provider/SKILL.md#order) |
| Can `packages/api` import `design_system`? | [ADR-0014](adr/0014-melos-package-split.md#dependency-direction) |
| App widget or design-system component? | [`create-ds-component`](../.claude/skills/create-ds-component/SKILL.md#does-it-belong-here) |
| No token fits this colour, radius or duration | [`add-design-token`](../.claude/skills/add-design-token/SKILL.md), [ADR-0013](adr/0013-design-system-tokens-only.md) |
| A new UI string | [`add-localization`](../.claude/skills/add-localization/SKILL.md), [ADR-0012](adr/0012-mandatory-localization.md) |
| Can a feature contain another feature? | [ADR-0005](adr/0005-flat-feature-tree.md), [`create-feature`](../.claude/skills/create-feature/SKILL.md#decide-the-location-first) |
| Can I start coding this ticket? | [ADR-0016](adr/0016-plan-first-delivery-workflow.md), [`plan-feature`](../.claude/skills/plan-feature/SKILL.md) |
| Token storage, logging, secrets | [`security-guidelines.md`](security-guidelines.md) |
| Jank, rebuilds, list performance | [`performance-guide.md`](performance-guide.md) |
| Codegen or a device misbehaves | [`troubleshooting.md`](troubleshooting.md) |

## Extending the architecture

- **A feature.** Plan it with [`plan-feature`](../.claude/skills/plan-feature/SKILL.md), then build it bottom-up with [`create-feature`](../.claude/skills/create-feature/SKILL.md): DTO and provider, store, use cases, state, page, strings, route, codegen, tests.
- **A package.** Add it under `workspace:` in `pubspec.yaml` with `resolution: workspace`, give it a `build:<name>` script, and place that script in `build` before every package that depends on it and before `build:app`. It never imports the app. `api` and `design_system` still never import each other. Code both of them need goes into a third package they depend on, which needs its own ADR ([ADR-0014](adr/0014-melos-package-split.md#dependency-direction)).
- **A flavor.** Add a `FlavorType` value, a config JSON with its `@JsonLiteral` getter under `lib/core/configs/environments/`, a `FlavorService` implementation with `@Singleton(env: ['NAME'], as: FlavorService, order: -1)` in `flavor_service.dart` (the class is `sealed`, so implementations stay in that file), and a `lib/main_{name}.dart` that calls `run(env: FlavorType.NAME)`. Decide what `isDev` and `isProduction` return, because they gate the mock interceptor and logging.
- **An interceptor.** Build it in `lib/core/services/interceptors/`, construct it in `DioService.initDio()`, pass it dependencies through `DioService`'s constructor, and place it by the order in [`create-api-provider`](../.claude/skills/create-api-provider/SKILL.md#interceptors).
- **A platform channel.** Write the contract first, then add a Dart wrapper in `lib/core/platform_channels/` (create the folder on first use) that catches `PlatformException` and tracks it, and inject the wrapper like a service ([`add-platform-channel`](../.claude/skills/add-platform-channel/SKILL.md)).
- **A new rule.** If the decision had real alternatives, it is an ADR ([`create-adr`](../.claude/skills/create-adr/SKILL.md#does-this-need-an-adr)). Add it to the [index](adr/README.md), put the one-line form in `AGENTS.md`, and run `melos run sync-agents`. If the change is a procedure, edit a playbook instead.

## More information

- Rules: [`AGENTS.md`](../AGENTS.md)
- Decisions: [`docs/adr/`](adr/README.md)
- Directory reference: [`project-structure.md`](project-structure.md)
- State and MobX: [`state-management-guide.md`](state-management-guide.md)
- Use cases: [`use_cases_guide.md`](use_cases_guide.md)
- Errors: [`error-handling-guidelines.md`](error-handling-guidelines.md)
- Security: [`security-guidelines.md`](security-guidelines.md)
- Performance: [`performance-guide.md`](performance-guide.md)
- Visual system: [`DESIGN.md`](../DESIGN.md)
- Something broken: [`troubleshooting.md`](troubleshooting.md)
