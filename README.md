# Flutter Boilerplate

A Flutter starter for mobile apps: layered architecture, MobX state management, a Retrofit API package, a token-based design system package, GetIt + Injectable DI, and a Melos-managed Dart workspace. Start a new app from it so every project shares the same structure, rules and tooling.

## Working in this repo — with or without an AI agent

| File | What it is |
|---|---|
| [`AGENTS.md`](AGENTS.md) | **Single source of truth.** Architecture rules, delivery workflow, naming, file boundaries, testing contract. Read by Codex, Cursor, Zed, Amp and Jules natively. |
| [`.claude/skills/`](.claude/skills/) | **Playbooks** — step-by-step guides for building one kind of thing (a DTO, a store, a page, a Maestro flow). Plain Markdown any agent can read; Claude Code registers them as invocable skills. Open the one you need; do not read them all. |
| [`docs/adr/`](docs/adr/README.md) | **Why** each rule exists, and what was rejected. |
| [`DESIGN.md`](DESIGN.md) | Visual system — palette, type, motion, component states, dark mode, accessibility, and the per-feature design-spec template. |
| [`docs/troubleshooting.md`](docs/troubleshooting.md) | Symptom → cause → fix for setup, codegen, runtime, test, device and Maestro problems. |

`CLAUDE.md`, `GEMINI.md`, `.github/copilot-instructions.md` and `.cursor/rules/000-agents.mdc` are **generated** from `AGENTS.md` — edit `AGENTS.md`, then run `melos run sync-agents`. CI fails on drift.

### The delivery loop

Every feature follows [ADR-0016](docs/adr/0016-plan-first-delivery-workflow.md): read the Jira acceptance criteria in full → restate them as a verifiable checklist → analyse the codebase → write a file-level plan mapping every AC line to a test → get approval → build → exit through the QA gate.

A feature is done when all three test tiers exist ([ADR-0015](docs/adr/0015-mandatory-test-coverage-and-qa-gate.md)):

| Tier | Where |
|---|---|
| Unit | `test/features/{feature}/` |
| Widget | `test/features/{feature}/view/` |
| E2E (Maestro) | `.maestro/flows/{feature}/` — **happy, failure and edge** |

In Claude Code: `/build-feature <JIRA-KEY>` runs the whole loop, `/qa-feature <feature>` runs the gate.

## Prerequisites

| Tool | Needed for | Check |
|---|---|---|
| Flutter SDK (stable channel), which includes Dart | everything | `flutter --version` |
| Xcode, with its command-line tools | iOS builds (macOS only) | `xcodebuild -version` |
| CocoaPods | iOS plugin dependencies | `pod --version` |
| Android Studio, or the Android SDK and an emulator image | Android builds | `flutter doctor` |
| Melos | workspace scripts | `melos --version` |
| Maestro *(optional)* | E2E flows | `maestro --version` |

```bash
dart pub global activate melos                   # then add $HOME/.pub-cache/bin to PATH
curl -fsSL "https://get.maestro.mobile.dev" | bash   # optional, for E2E
flutter doctor                                   # fix anything it reports before going on
```

## Getting started

**1. Clone the repo** (or create a repository from the template):

```bash
git clone https://github.com/NarekManukyan/flutter_boilerplate
cd flutter_boilerplate
```

**2. Generate the platform folders** with your own organisation id:

```bash
flutter create --platforms=ios,android --org com.yourcompany .
```

See [No committed `ios/` or `android/`](#no-committed-ios-or-android) for why this step exists.

**3. Fetch dependencies and generate code:**

```bash
melos run bootstrap
```

This fetches dependencies for the whole workspace and runs every code generator in order (translations → `api` → `design_system` → app). The built-in `melos bootstrap` (without `run`) only resolves dependencies; a fresh clone also needs the codegen, because generated files are not committed.

**4. Install iOS pods, if needed.** `flutter run` installs them on its own; run it by hand when that fails or after changing plugins:

```bash
cd ios && pod install && cd ..
```

**5. Verify the setup:**

```bash
melos run verify:quick     # analyze + format check, no tests
```

**6. Run the app** on iOS and on Android. List devices first, then pass the id with `-d`:

```bash
flutter devices
flutter run -t lib/main_dev.dart -d <ios-simulator-id>
flutter run -t lib/main_dev.dart -d <android-emulator-id>    # e.g. emulator-5554
```

**7. Install the git hooks** (once per clone):

```bash
melos run hooks:install
```

The pre-commit hook fixes, formats and analyzes the staged Dart files, and blocks the commit when the analyzer reports a problem. Skip it for one commit with `git commit --no-verify`.

Something failed? See [`docs/troubleshooting.md`](docs/troubleshooting.md).

## No committed `ios/` or `android/`

`.gitignore` excludes both, on purpose. They are not missing.

A platform folder is where the app's identity lives: bundle id and application id, signing certificates, provisioning profiles, team ids, Firebase plists, entitlements, push certificates. None of that is shared between the projects that start from this boilerplate, so committing one would hand every new app the same identity and a merge conflict on the first build. `flutter create` regenerates both folders from your own values in seconds, which is why they are yours to make rather than ours to ship.

What follows from that:

**Run `flutter create` before your first build.** Nothing in `lib/` depends on the platform folders, so `melos run bootstrap`, `melos run verify` and the unit and widget tests all work without them. Only building or running the app on a device needs them.

**Maestro picks the app from `APP_ID`.** Every flow header is `appId: ${APP_ID}`, and `tool/run_maestro.sh` passes it in. With `APP_ID` unset, the runner uses the ids `flutter create --org com.example` produces — `com.example.flutterBoilerplate` on iOS, `com.example.flutter_boilerplate` on Android — picked from the target device, and prints which one it chose. With a different `--org`, run `APP_ID=<your id> ./tool/run_maestro.sh`. No flow needs editing. See [E2E tests](#e2e-tests-maestro).

**The E2E job in CI skips itself here.** `.github/workflows/maestro.yml` checks whether `ios/` is tracked and stops with a notice if it is not, rather than failing on a condition the branch cannot fix. In this repo it always skips. In an app generated from this boilerplate, where `ios/` is committed, the same job runs the flows with no changes. The flows are verified either way, locally, with `melos run maestro` against a booted simulator.

## Daily workflow

```bash
git pull
melos bootstrap                                   # resolve dependencies (pubspecs may have changed)
melos run build                                   # regenerate code (annotations may have changed)
flutter run -t lib/main_dev.dart -d <device-id>
```

`melos run bootstrap` runs the middle two steps in one command.

**Codegen while you work.** MobX, Freezed, Retrofit, Injectable and AutoRoute generate code from annotations. After changing an annotation:

```bash
melos run build            # everything, in dependency order
melos run build:app        # lib/ only — faster when the packages did not change
melos run watch            # lib/ in watch mode: regenerates on every save
melos run translations     # after editing assets/translations/en-US.json
```

**Before every PR:**

```bash
melos run verify           # analyze, format check, tests, agent-file drift — read-only
melos run maestro:happy    # happy-path E2E flows, on a booted device with the dev build installed
```

`verify` and `verify:quick` never modify files. To fix what they report, run `melos run lint` and `melos run format`.

## Melos commands

The root app is not a melos package (`melos list` shows only `api` and `design_system`), so every script runs the app explicitly and then the packages.

| Command | What it does |
|---|---|
| **Setup** | |
| `melos run bootstrap` | Dependencies + full codegen |
| `melos run deps` | Resolve dependencies for the workspace |
| `melos run hooks:install` | Use the repo's git hooks (`tool/git-hooks/`) |
| **Codegen** | |
| `melos run build` | `translations` → `build:api` → `build:design_system` → `build:app` |
| `melos run build:api` / `build:design_system` / `build:app` | One package's `build_runner` |
| `melos run watch` | App codegen in watch mode |
| `melos run translations` | `LocaleKeys` from `assets/translations/en-US.json` |
| `melos run assets` | Design-system assets + translations |
| `melos run clean` | `build_runner clean` for the app and packages |
| `melos run clean:all` | Deep clean: `build_runner` caches, `lib/gen/*.g.dart`, `flutter clean` |
| `melos run rebuild` | `clean:all`, then `bootstrap` |
| **Quality** | |
| `melos run verify` | Analyze, format check, tests, agent-file drift — what CI checks, read-only |
| `melos run verify:quick` | Analyze + format check, no tests |
| `melos run analyze` | Analyzer for the app and packages |
| `melos run format` / `format:check` | Format, or fail on unformatted code |
| `melos run lint` | `dart fix --apply` |
| `melos run deps:check` | Outdated dependencies across the workspace (report only) |
| **Tests** | |
| `melos run test` | Unit + widget tests |
| `melos run test:coverage` | Tests with lcov output |
| `melos run maestro` | Every Maestro flow (`tool/run_maestro.sh`) |
| `melos run maestro:happy` | Happy-path flows only — the PR gate |
| **Agents** | |
| `melos run sync-agents` | Regenerate `CLAUDE.md`, `GEMINI.md`, Copilot and Cursor files from `AGENTS.md` |
| **Deployment** | |
| `melos run deploy-dev` | `pod install` + `fastlane dev` — needs a Fastlane setup in the app's `ios/` |

Run a command in one package: `melos exec --scope api -- "dart run build_runner build -d"`.

## Testing

### Unit and widget tests

```bash
melos run test
flutter test test/features/home/                          # one directory
flutter test test/features/home/mobx/home_store_test.dart # one file
flutter test --name 'should set error' --reporter expanded
```

Many unit tests, fewer widget tests, few E2E flows. The how-to is in [`write-tests`](.claude/skills/write-tests/SKILL.md); the shared widget-test harness is `test/helpers/pump_app.dart`.

### E2E tests (Maestro)

Build and install the dev flavor on a booted simulator or emulator, then:

```bash
melos run maestro                      # every flow
melos run maestro:happy                # happy-path flows only

APP_ID=com.yourcompany.yourApp DEVICE=<udid-or-adb-serial> melos run maestro
```

| Variable | Default | Meaning |
|---|---|---|
| `APP_ID` | `com.example.flutterBoilerplate` | Bundle id (iOS) or applicationId (Android) of the installed dev build |
| `DEVICE` | the single booted device | Simulator UDID or adb serial, when more than one is running |
| `OUT_DIR` | `.maestro/output` | JUnit report (`report.xml`) and debug output (logs, screenshots) |

Flows run against the dev flavor's mock interceptor, so they need no backend. Writing a flow: [`write-maestro-flow`](.claude/skills/write-maestro-flow/SKILL.md).

## Dependency health

```bash
melos run deps:check                 # outdated packages in the app and both packages
flutter pub deps --style=compact     # who depends on what
```

The app and both packages resolve together as one Dart workspace, so a dependency is upgraded in every pubspec that declares it, in one change. Run `melos run verify` after an upgrade.

## Profiling

Profile on a **physical device** — debug builds are unoptimized, and profile mode does not run on simulators or emulators.

```bash
flutter run --profile -t lib/main_dev.dart -d <device-id>
```

Open DevTools from the link `flutter run` prints: **Performance** for jank and slow frames, **Memory** for leaks, **CPU Profiler** for hot code.

App size, broken down by package and asset:

```bash
flutter build apk --analyze-size --target-platform android-arm64 -t lib/main_prod.dart
```

Open the size file it writes in DevTools → **App Size**.

## Release builds

Release builds use the prod entry point. Signing (an Apple team and provisioning profile, an Android upload keystore) is configured per app in `ios/` and `android/`, and never committed.

```bash
flutter build ipa -t lib/main_prod.dart                      # iOS archive for App Store Connect
flutter build appbundle --release -t lib/main_prod.dart      # Android App Bundle for Google Play
```

The version and build number come from `version:` in `pubspec.yaml` (`1.2.0+42`), or `--build-name` / `--build-number` on the command line.

### Pre-deployment checklist

- [ ] `melos run verify` passes on a clean tree (`melos run rebuild` first)
- [ ] `melos run maestro` passes on an iOS and an Android dev build
- [ ] Version and build number bumped; the build number is higher than the last upload
- [ ] `lib/core/configs/environments/production/production.json` holds production values: API URL, Sentry DSN, bundle id, third-party keys
- [ ] Built from `lib/main_prod.dart`; the mock interceptor is dev-only, and nothing logs request headers or bodies in production
- [ ] Signing configured for both platforms
- [ ] The release build installed on a physical iPhone and Android device, and the main journeys smoke-tested
- [ ] App size checked with `--analyze-size` for unexpected growth
- [ ] `melos run deps:check` reviewed
- [ ] Release notes and store metadata ready

## Project structure

```
lib/
  core/
    configs/           environment config (development/, production/ JSON)
    constants/         app-wide constants and enums
    extensions/        Dart extensions
    guards/            route guards (AuthGuard)
    navigation/        AppRouter + AppNavigator
    services/          FlavorService, DioService, IssueTrackingService, interceptors/
    state/             reusable MobX state helpers
    ui/                cross-feature widgets (TestId, ErrorNotice, …)
    use_cases/         use cases shared across features
    utils/             helpers
  features/{feature}/
    view/              page, page state, *_keys.dart, widgets/, use_cases/
    mobx/              stores, use_cases/
    core/use_cases/    use cases shared by layers of this feature
    models/  modals/  components/  constants/  overlays/     (only when needed)
  gen/                 GENERATED (LocaleKeys, assets) — never edit
  app.dart             MaterialApp.router, themes, localization
  injectable.dart      DI bootstrap (configureDependencies)
  main.dart            run(): bindings, localization, DI, Sentry
  main_dev.dart        dev entry point
  main_prod.dart       prod entry point
packages/
  api/                 Retrofit providers + freezed DTOs, one directory per resource
  design_system/       GeistTheme tokens, components, generated assets
assets/translations/   en-US.json
test/                  unit + widget tests, mirrors lib/
.maestro/              E2E flows: flows/{feature}/{feature}_{happy|failure|edge}.yaml
tool/                  sync_agents.sh, run_maestro.sh, git-hooks/
docs/                  adr/, troubleshooting.md
```

- Features are peers: a feature never contains a `features/` folder ([ADR-0005](docs/adr/0005-flat-feature-tree.md)).
- There is no `lib/shared/`. It is deprecated: stores live under their owning feature's `mobx/`, even `@singleton` ones, and cross-feature widgets live in `lib/core/ui/` ([ADR-0006](docs/adr/0006-feature-owned-singletons.md)).
- The full layout and naming rules are in [`AGENTS.md`](AGENTS.md#project-structure) and the [`create-feature`](.claude/skills/create-feature/SKILL.md) playbook.

## Routing

Routes are declared with AutoRoute in `lib/core/navigation/app_router.dart`. Pages carry `@RoutePage()`, and `melos run build` generates a `{Name}Route` class for each.

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
      guards: [_authGuard],
    ),
    AutoRoute(path: '/login', page: LoginRoute.page),
    AutoRoute(path: '/home', page: HomeRoute.page, guards: [_authGuard]),
    AutoRoute(
      path: '/todos/:id',
      page: TodoDetailsRoute.page,
      guards: [_authGuard],
    ),
  ];
}
```

Nothing navigates through the router directly. `AppNavigator` (`lib/core/navigation/app_navigator.dart`), a `@singleton`, owns the `AppRouter` and exposes the operations the app uses — `push`, `replace`, `pushAndPopAll`, `pop`, `showModal`:

```dart
@singleton
class AppNavigator {
  AppNavigator(AuthStore authStore)
    : _router = AppRouter(authGuard: AuthGuard(authStore));

  final AppRouter _router;

  RouterConfig<UrlState> get config => _router.config();

  Future<T?> push<T extends Object?>(PageRouteInfo route) => _router.push(route);
  // …
}
```

`app.dart` hands `getIt<AppNavigator>().config` to `MaterialApp.router`. Page states and navigation use cases inject `AppNavigator` and call it; pages never use `context.router` or `Navigator` ([ADR-0008](docs/adr/0008-appnavigator-routing-abstraction.md)):

```dart
@action
Future<void> onLogoutPressed() async {
  await _homeStore.logout();
  await _appNavigator.pushAndPopAll(const LoginRoute());
}
```

Adding a screen: [`add-route`](.claude/skills/add-route/SKILL.md).

## Flavors and entry points

There are two flavors, selected by entry point with `-t` (no `--flavor`):

| Flavor | Entry point | Config |
|---|---|---|
| dev | `lib/main_dev.dart` (also `lib/main.dart`) | `lib/core/configs/environments/development/development.json` |
| prod | `lib/main_prod.dart` | `lib/core/configs/environments/production/production.json` |

Both call `run()` in `lib/main.dart`, which sets up bindings and localization, registers dependencies for the flavor (`configureDependencies`, which picks `FlavorDev` or `FlavorProd`), and starts Sentry outside debug builds. Only the dev flavor installs the mock interceptor.

## Hide generated files

In Android Studio, open **Settings → Editor → File Types** and add to **Ignored Files and Folders**:

```
*.g.dart;*.freezed.dart;*.gr.dart;*.config.dart;
```

In VS Code, open **Settings**, search for `files.exclude`, and add:

```
**/*.g.dart
**/*.freezed.dart
**/*.gr.dart
```

## What's included

- Splash, login, home (todo list) and detail screens wired end to end
- Routing with AutoRoute behind an `AppNavigator` abstraction, with an auth guard
- MobX state management with page states and feature stores
- GetIt + Injectable dependency injection, with flavor-scoped bindings
- Dio + Retrofit typed API layer with freezed DTOs (`packages/api`)
- A dev-flavor mock interceptor with switchable scenarios for E2E tests
- Error tracking through `IssueTrackingService` and Sentry
- Design system package with Geist tokens, light and dark themes, generated assets (`packages/design_system`)
- Localization with easy_localization and generated `LocaleKeys`
- Connectivity handling and an app-update prompt
- Unit, widget and Maestro E2E tests, with a shared widget-test harness
- Melos workspace scripts, a pre-commit hook, CI workflows, and agent playbooks and ADRs

## Libraries

- [MobX](https://github.com/mobxjs/mobx.dart) and [flutter_hooks](https://pub.dev/packages/flutter_hooks) — state
- [AutoRoute](https://github.com/Milad-Akarie/auto_route_library) — routing
- [Dio](https://github.com/cfug/dio) and [Retrofit](https://pub.dev/packages/retrofit) — networking
- [Freezed](https://github.com/rrousselGit/freezed) and [json_serializable](https://github.com/google/json_serializable.dart) — immutable models and JSON
- [get_it](https://github.com/fluttercommunity/get_it) and [injectable](https://pub.dev/packages/injectable) — dependency injection
- [easy_localization](https://github.com/aissat/easy_localization) — localization
- [Sentry](https://pub.dev/packages/sentry_flutter) — error reporting
- [extended_image](https://github.com/fluttercandies/extended_image), [skeletonizer](https://pub.dev/packages/skeletonizer), [gap](https://pub.dev/packages/gap) — UI
- [mocktail](https://pub.dev/packages/mocktail) and [Maestro](https://maestro.dev) — testing
- [Melos](https://melos.invertase.dev/) — workspace management

## Contributing

Questions and improvements are welcome: open an issue or a pull request. Like any template, this can look over-architected for a small app. The structure pays off as the app and the team grow.
