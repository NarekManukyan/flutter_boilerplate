# Boilerplate Project

A boilerplate project created in flutter using MobX.

## Getting Started

The Boilerplate contains the minimal implementation required to create a new library or project. The repository code is preloaded with some basic components like basic app architecture, app theme, constants and required dependencies to create a new project. By using boiler plate code as standard initializer, we can have same patterns in all the projects that will inherit it. This will also help in reducing setup & development time by allowing you to use same code pattern and avoid re-writing from scratch.

## How to Use

**Step 1:**

Download or clone this repo by using the link below:

```
https://github.com/NarekManukyan/flutter_boilerplate
```

**Step 2:**

Go to project root and execute the following command in console to get the required dependencies:

```
flutter create .
```

**Step 3:**

This project uses `inject` library that works with code generation, execute the following command to generate files:

```
flutter packages pub run build_runner build --delete-conflicting-outputs
```

or watch command in order to keep the source code synced automatically:

```
flutter packages pub run build_runner watch
```

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

* Splash
* Login
* Dashboard
* Routing
* Theme
* SVG support
* Dio
* Database
* Shared preferences
* Modal bottom sheet
* Freezed (Code generation for immutable classes)
* ExtendedImage (Official extension image)
* MobX (State Management)
* Code Generation
* Dependency Injection
* Dark Theme Support 
* Multilingual Support 
* MobX example

### Up-Coming Features:

* Connectivity Support
* Background Fetch Support
* More examples

### Libraries & Tools Used

* [Dio](https://github.com/flutterchina/dio)
* [Database](https://github.com/tekartik/sembast.dart)
* [Routing](https://github.com/Milad-Akarie/auto_route_library)
* [MobX](https://github.com/mobxjs/mobx.dart) (State Management)
* [SVG support](https://github.com/dnfield/flutter_svg) 
* [Modal bottom sheet](https://github.com/jamesblasco/modal_bottom_sheet)
* [Multilingual Support](https://github.com/aissat/easy_localization)
* [ExtendedImage](https://github.com/fluttercandies/extended_image) (Official extension image)
* [Shared preferences](https://github.com/flutter/plugins/tree/master/packages/shared_preferences/shared_preferences) (Platform-specific persistent storage for simple data)
* [Json Serialization](https://github.com/dart-lang/json_serializable)
* [Freezed](https://github.com/rrousselGit/freezed) (Code generation for immutable classes)
* [Dependency Injection](https://github.com/fluttercommunity/get_it)

### Folder Structure
Here is the core folder structure which flutter provides.

```
flutter-app/
|- assets
|- build
|- lib
|- test
```

Here is the folder structure we have been using in this project

```
lib/
|- constants/
|- environments/
|- extensions/
|- http/
|- mixins/
|- models/
|- providers/
|- pages/
|- store/
|- themes/
|- utils/
|- widgets/
|- app.dart
|- main.dart
|- main_dev.dart
|- main_test.dart
|- main_staging.dart
|- main_prod.dart
|- router.dart
```

Now, lets dive into the lib folder which has the main code for the application.

```
1- constants - All the application level constants are defined in this directory with-in their respective files. This directory contains the constants for `theme`, `dimentions`, `api endpoints`, `preferences` and `strings`.
2- environments - Contains the configurations for environments.
3- extensions - Contains the extensions on context, Widgets.
4- http - Contains the Dio repositories and interceptors.
5- mixins - Contains the mixins.
6- models - Contains the models.
7- providers - Contains the providers.
8- pages - Contains the UI parts of pages.
9- store - Contains store(s) for state-management of your application, to connect the reactive data of your application with the UI. 
10- themes - Contains the themes, colors, and styles. 
11- utils — Contains the utilities/common functions of your application.
12- widgets — Contains the common widgets for your applications. For example, Button, TextField etc.
13- router.dart — This file contains all the routes for your application.
14- main.dart - This is the starting point of the application. All the application level configurations are defined in this file i.e, theme, routes, title, orientation etc.
```

### Routes

This file contains all the routes for your application. 

```dart
import 'package:auto_route/auto_route.dart';

import 'pages/dashboard/dashboard_page.dart';
import 'pages/login_page/login_page.dart';
import 'pages/splash_screen/splash_screen.dart';

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

This is the starting point of the application. All the application level configurations are defined in this file i.e, theme, routes, title, orientation etc.

```dart
import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flavorbanner/flavor_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'providers/get_it.dart';

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

## Conclusion

I will be happy to answer any questions that you may have on this approach, and if you want to lend a hand with the boilerplate then please feel free to submit an issue and/or pull request 🙂

Again to note, this is example can appear as over-architectured for what it is - but it is an example only. If you liked my work, don’t forget to ⭐ star the repo to show your support.
