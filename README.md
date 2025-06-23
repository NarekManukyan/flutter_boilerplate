# Boilerplate Project

A boilerplate project created in flutter using MobX.

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

For development, use the development workflow:

```bash
melos run dev
```

This will:
- Get dependencies for all packages
- Generate code for all packages

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
- **`melos run analyze`** - Analyze all packages for issues
- **`melos run test`** - Run tests for all packages
- **`melos run format`** - Format code in all packages
- **`melos run lint`** - Apply linting fixes to all packages

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
