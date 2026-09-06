# Boilerplate Project

A boilerplate project created in flutter using MobX.

## Working in this repo — with or without an AI agent

| File | What it is |
|---|---|
| [`AGENTS.md`](AGENTS.md) | **Single source of truth.** Architecture rules, delivery workflow, naming, file boundaries, testing contract. Read by Codex, Cursor, Zed, Amp and Jules natively. |
| [`.claude/skills/`](.claude/skills/) | **Playbooks** — step-by-step guides for building one kind of thing (a DTO, a store, a page, a Maestro flow). Plain Markdown any agent can read; Claude Code registers them as invocable skills. Open the one you need; do not read them all. |
| [`docs/adr/`](docs/adr/README.md) | **Why** each rule exists, and what was rejected. |
| [`DESIGN.md`](DESIGN.md) | Visual system — palette, type, motion, component states, dark mode, accessibility, and the per-feature design-spec template. |

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

## Getting Started

The Boilerplate contains the minimal implementation required to create a new library or project. The repository code is preloaded with some basic components like basic app architecture, app theme, constants and required dependencies to create a new project. By using boilerplate code as standard initializer, we can have same patterns in all the projects that will inherit it. This will also help in reducing setup & development time by allowing you to use same code pattern and avoid re-writing from scratch.

## How to Use

**Step 1:**

Download or clone this repo by using the link below:

```
https://github.com/NarekManukyan/flutter_boilerplate
```

**Step 2:**

Install Melos globally (if not already installed):

```bash
dart pub global activate melos
```

**Step 3:**

Bootstrap the workspace to set up all dependencies and generate code:

```bash
melos bootstrap
```

This will:
- Install dependencies for all packages
- Generate code for all packages
- Set up the workspace

**Step 4:**

Generate the platform folders for your app:

```bash
flutter create --platforms=ios,android --org com.yourcompany .
```

See [No committed `ios/` or `android/`](#no-committed-ios-or-android) for why this step exists.

**Step 5:**

For development, use the development workflow:

```bash
melos run dev
```

This will:
- Get dependencies for all packages
- Generate code for all packages

## No committed `ios/` or `android/`

`.gitignore` excludes both, on purpose. They are not missing.

A platform folder is where the app's identity lives: bundle id and application id, signing certificates, provisioning profiles, team ids, Firebase plists, entitlements, push certificates. None of that is shared between the projects that start from this boilerplate, so committing one would hand every new app the same identity and a merge conflict on the first build. `flutter create` regenerates both folders from your own values in seconds, which is why they are yours to make rather than ours to ship.

What follows from that:

**Run `flutter create` before your first build.** Nothing in `lib/` depends on the platform folders, so `melos bootstrap`, `melos run verify` and the unit and widget tests all work without them. Only building or running the app on a device needs them.

**Set the bundle id in the Maestro flows.** `.maestro/common/*.yaml` carry an `appId`. Point it at whatever `--org` you used, or the flows will look for an app that is not installed.

**The E2E job in CI skips itself here.** `.github/workflows/maestro.yml` checks whether `ios/` is tracked and stops with a notice if it is not, rather than failing on a condition the branch cannot fix. In this repo it always skips. In an app generated from this boilerplate, where `ios/` is committed, the same job runs the flows with no changes. The flows are verified either way, locally, with `melos run maestro` against a booted simulator.

## Monorepo Management with Melos

This project uses [Melos](https://melos.invertase.dev/) to manage the monorepo structure. Melos provides powerful tools for managing multiple packages in a single repository.

### Prerequisites

Install Melos globally:

```bash
dart pub global activate melos
```

### Initial Setup

1. **Bootstrap the workspace:**
   ```bash
   melos bootstrap
   ```
   This command will:
   - Install dependencies for all packages
   - Generate code for all packages
   - Set up the workspace

2. **Get dependencies for all packages:**
   ```bash
   melos run deps
   ```

### Available Melos Commands

#### Development Workflow
- **`melos run dev`** - Complete development setup (deps, generate)
- **`melos run deps`** - Get dependencies for all packages
- **`melos run generate`** - Generate code for all packages
- **`melos run build`** - Build all packages (generate code)
- **`melos run clean`** - Clean all packages

#### Code Quality
- **`melos run verify`** - Everything CI runs except E2E: lint, analyze, format check, tests, agent-file drift. **Run before every PR.**
- **`melos run analyze`** - Analyze the app and both packages
- **`melos run format`** / **`melos run format:check`** - Format, or fail on unformatted code
- **`melos run lint`** - Apply mechanical lint fixes

#### Testing — ADR-0015
- **`melos run test`** - Unit + widget tests
- **`melos run test:coverage`** - Tests with lcov output
- **`melos run maestro`** - Every Maestro E2E flow (needs a booted device with the app installed)
- **`melos run maestro:happy`** - Happy-path flows only — the PR gate

#### Agent instructions — ADR-0017
- **`melos run sync-agents`** - Regenerate `CLAUDE.md`, `GEMINI.md`, `.github/copilot-instructions.md` and the Cursor rule from `AGENTS.md`

#### Asset Generation
- **`melos run assets`** - Generate assets and translations
- **`melos run translations`** - Generate translation keys

#### Workspace Management
- **`melos run bootstrap`** - Complete workspace setup

#### Deployment
- **`melos run deploy-dev`** - Deploy to development environment

### Package Structure

The monorepo contains the following packages:

- **`flutter_boilerplate`** (root) - Main Flutter application
- **`packages/api`** - API client and network layer
- **`packages/design_system`** - Reusable UI components and themes

### Working with Packages

- **Run commands on specific packages:**
  ```bash
  melos exec --scope api -- "dart run build_runner build"
  melos exec --scope design_system -- "dart test"
  ```

- **Run commands on all packages except specific ones:**
  ```bash
  melos exec --ignore="**/test/**" -- "dart analyze"
  ```

- **Add a new package:**
  1. Create a new directory in `packages/`
  2. Add a `pubspec.yaml` file
  3. Run `melos bootstrap` to set up the new package

### IDE Integration

Melos provides IDE integration for:
- **VS Code** - Enhanced workspace management
- **IntelliJ/Android Studio** - Better package navigation

### Migration from Derry

If you were using derry before, here are the equivalent Melos commands:

| Old Derry Command | New Melos Command |
|-------------------|-------------------|
| `derry generate_translations` | `melos run translations` |
| `derry delete_generated_files` | `melos run clean` |
| `derry build_runner` | `melos run build` |
| `derry build_api` | `melos exec --scope api -- "dart run build_runner build -d"` |
| `derry build_design_system` | `melos exec --scope design_system -- "dart run build_runner build -d"` |
| `derry build_all` | `melos run build` |
| `derry generate` | `melos run dev` |
| `derry deploy_dev` | `melos run deploy-dev` |

## Hide Generated Files

In-order to hide generated files, navigate to `Android Studio` -> `Preferences` -> `Editor` -> `File Types` and paste the below lines under `ignore files and folders` section:

```
*.inject.summary;*.inject.dart;*.g.dart;
```

In Visual Studio Code, navigate to `Preferences` -> `Settings` and search for `Files:Exclude`. Add the following patterns:

```
**/*.inject.summary
**/*.inject.dart
**/*.g.dart
```

## Boilerplate Features:

- Splash Screen
- Login Page
- Dashboard
- Routing with AutoRoute
- Theme Management
- SVG Support
- Dio for HTTP Requests
- Local Database Integration
- Shared Preferences
- Modal Bottom Sheet
- Freezed for Immutable Classes
- ExtendedImage for Advanced Image Handling
- MobX for State Management
- Code Generation
- Dependency Injection with GetIt
- Dark Theme Support
- Multilingual Support
- Flavor Configuration
- Environment-Based Configurations
- **Monorepo Management with Melos**

### Up-Coming Features:

- Connectivity Support
- Background Fetch Support
- More Examples

## Libraries & Tools Used

- [Dio](https://github.com/flutterchina/dio)
- [Routing](https://github.com/Milad-Akarie/auto_route_library)
- [MobX](https://github.com/mobxjs/mobx.dart) (State Management)
- [SVG support](https://github.com/dnfield/flutter_svg)
- [Modal bottom sheet](https://github.com/jamesblasco/modal_bottom_sheet)
- [Multilingual Support](https://github.com/aissat/easy_localization)
- [ExtendedImage](https://github.com/fluttercandies/extended_image) (Official extension image)
- [Shared preferences](https://github.com/flutter/plugins/tree/master/packages/shared_preferences/shared_preferences) (Platform-specific persistent storage for simple data)
- [Json Serialization](https://github.com/dart-lang/json_serializable)
- [Freezed](https://github.com/rrousselGit/freezed) (Code generation for immutable classes)
- [Dependency Injection](https://github.com/fluttercommunity/get_it)
- [Melos](https://melos.invertase.dev/) (Monorepo Management)
- **Local Libraries:**
  - `packages/api` - Handles API-related logic and network requests.
  - `packages/design_system` - Contains reusable UI components, themes, and design elements.

### Folder Structure

Here is the core folder structure which flutter provides.

```
flutter-app/
|- assets
|- build
|- lib
|- test
```

Here is the folder structure we have been using in this project:

```
lib/
|- core/
|- features/
|- gen/
|- shared/
|- app.dart
|- main.dart
|- main_dev.dart
|- main_prod.dart
|- injectable.dart
|- injectable.config.dart
packages/
|- api/
|- design_system/
```

Now, let's dive into the `lib` folder which has the main code for the application:

1. **core** - Contains core utilities, constants, and configurations.
2. **features** - Contains feature-specific modules and their respective UI, logic, and data layers.
3. **gen** - Contains generated files.
4. **shared** - Contains shared components like widgets, themes, and utilities.
5. **app.dart** - The main app widget and configurations.
6. **main.dart** - The entry point of the application.
7. **main_dev.dart** - Entry point for the development environment.
8. **main_prod.dart** - Entry point for the production environment.
9. **injectable.dart** - Dependency injection setup.
10. **injectable.config.dart** - Generated configuration for dependency injection.
11. **packages/api** -Contains API client setup, endpoints, and interceptors for handling network requests.
12. **packages/design_system** -CProvides reusable UI components and themes to maintain design consistency.

### Routes

This file contains all the routes for your application.

```dart
import 'package:auto_route/auto_route.dart';

import 'features/dashboard/dashboard_page.dart';
import 'features/login/login_page.dart';
import 'features/splash/splash_screen.dart';

export 'router.gr.dart';

@AdaptiveAutoRouter(
  preferRelativeImports: true,
  replaceInRouteName: 'Page,Route',
  routes: [
    AdaptiveRoute(
      page: SplashScreenPage,
      initial: true,
      fullscreenDialog: true,
    ),
    AdaptiveRoute(
      page: LoginPage,
      fullscreenDialog: true,
    ),
    AdaptiveRoute(
      page: DashboardPage,
    ),
  ],
)
class $Router {}
```

### Main

This is the starting point of the application. All the application level configurations are defined in this file i.e., theme, routes, title, orientation, etc.

```dart
import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flavorbanner/flavor_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/injection.dart';

Future<void> run({Flavor env = Flavor.DEV}) async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await EasyLocalization.ensureInitialized();

  registerGetIt(env);

  FlavorConfig(
    flavor: env,
    color: Colors.grey,
    values: FlavorValues(
      baseUrl: 'https://dev.com/',
      showBanner: env != Flavor.PROD,
    ),
  );
  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en', 'US'),
      ],
      startLocale: const Locale('en', 'US'),
      fallbackLocale: const Locale('en', 'US'),
      path: 'assets/translations',
      child: const MyApp(),
    ),
  );
}

Future<void> main() async {
  await run();
}
```

## Conclusions

I will be happy to answer any questions that you may have on this approach, and if you want to lend a hand with the boilerplate then please feel free to submit an issue and/or pull request 🙂

Again to note, this example can appear as over-architected for what it is - but it is an example only. If you liked my work, don't forget to ⭐ star the repo to show your support.
