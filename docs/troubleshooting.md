# Troubleshooting

Common problems when setting up, building, testing and running an app built from this boilerplate. Each entry gives the **symptom** you see, the usual **cause**, and the **fix**.

Start with the basics when something is broken and you do not know why:

```bash
flutter doctor -v          # toolchain, Xcode, Android SDK, licenses
melos run verify:quick     # does the code analyze and format cleanly?
```

Contents: [Setup](#setup) · [Codegen](#codegen) · [Runtime](#runtime) · [Packages and dependencies](#packages-and-dependencies) · [Tests](#tests) · [Performance](#performance) · [Devices](#devices) · [Maestro](#maestro) · [Asking for help](#asking-for-help)

---

## Setup

### `melos: command not found`

- **Symptom:** the shell cannot find `melos` after `dart pub global activate melos`.
- **Cause:** globally activated Dart executables are installed in `$HOME/.pub-cache/bin`, which is not on `PATH` by default.
- **Fix:** add it to your shell profile (`~/.zshrc`, `~/.bashrc`) and open a new terminal:

  ```bash
  export PATH="$PATH:$HOME/.pub-cache/bin"
  melos --version
  ```

  Melos is also a dev dependency of the workspace, so `dart run melos <command>` works without a global install.

### `flutter doctor` reports problems

- **Symptom:** red or yellow items in `flutter doctor`; builds fail for one platform only.
- **Cause:** a missing or outdated part of the toolchain: Xcode command-line tools, CocoaPods, the Android SDK, or unaccepted Android licenses.
- **Fix:** fix what `flutter doctor -v` names, then run it again. For Android licenses:

  ```bash
  flutter doctor --android-licenses
  ```

### CocoaPods fails (`pod install`)

- **Symptom:** `pod install` or an iOS build fails with *"CocoaPods could not find compatible versions for pod …"*, or an error about the Podfile.lock being out of sync.
- **Cause:** the local CocoaPods spec repo is older than the version a plugin needs, or a previous pod integration left stale state behind.
- **Fix:** update the spec repo and install again; if that is not enough, remove the integration and reinstall:

  ```bash
  cd ios
  pod repo update
  pod install
  # still failing:
  pod deintegrate && pod install
  cd ..
  ```

### Gradle build fails (Android)

- **Symptom:** `flutter run` or `flutter build apk` fails in a Gradle task, often after a dependency or plugin upgrade.
- **Cause:** stale Gradle build output or cache from before the change.
- **Fix:** clean Gradle and Flutter, then fetch dependencies again:

  ```bash
  cd android && ./gradlew clean && cd ..
  flutter clean
  flutter pub get
  ```

  If the error says the Gradle or Android Gradle Plugin version is too old, it names the minimum version. Raise `distributionUrl` in `android/gradle/wrapper/gradle-wrapper.properties` to that version or newer. Never lower it.

### `ios/` or `android/` is missing

- **Symptom:** `flutter run` says there is no iOS or Android project.
- **Cause:** the boilerplate does not commit platform folders; each app generates its own with its own bundle id. See the [README](../README.md#no-committed-ios-or-android).
- **Fix:**

  ```bash
  flutter create --platforms=ios,android --org com.yourcompany .
  ```

### A build behaves strangely after switching branches

- **Symptom:** errors that make no sense for the code in front of you, or that disappear on a teammate's machine.
- **Cause:** build output, generated code or resolved dependencies from the other branch.
- **Fix:** clean and fetch dependencies, then regenerate:

  ```bash
  flutter clean && flutter pub get
  melos run build
  ```

  `melos run rebuild` does the deep version of this in one step.

---

## Codegen

### Generated code is stale

- **Symptom:** analyzer errors inside `*.g.dart`, `*.freezed.dart`, `*.gr.dart` or `injectable.config.dart`; a `_$Something` mixin is missing members you just added; `build_runner` stops with *"Conflicting outputs"*.
- **Cause:** annotations changed and the generated files were not rebuilt, or a build was interrupted and left a half-written cache.
- **Fix:** clean everything and rebuild in dependency order:

  ```bash
  melos run clean:all   # build_runner caches, lib/gen/*.g.dart, flutter clean
  melos run build       # translations → api → design_system → app
  ```

  `melos run rebuild` runs `clean:all` and then `bootstrap` (dependencies and codegen) in one go. While editing annotations in `lib/`, `melos run watch` keeps the app's generated code current.

### Generated files are missing

- **Symptom:** *"Target of URI hasn't been generated: 'x.g.dart'"*, or `LocaleKeys` is undefined, on a fresh clone.
- **Cause:** generated files are not committed (`.gitignore` excludes `*.g.dart`, `*.freezed.dart`, `*.config.dart`), so a new checkout has none until codegen runs.
- **Fix:**
  1. Check the builder configuration a generator needs is still there: `build.yaml` at the root, and `packages/design_system/build.yaml` for `flutter_gen` and Theme Tailor.
  2. Fetch dependencies: `flutter pub get` (or `melos bootstrap`).
  3. Run the full build: `melos run build`.
  4. `lib/gen/locale_keys.g.dart` comes from the translations step. On its own: `melos run translations`.

  A missing `part 'x.g.dart';` directive also stops a file from being generated — check the file declares it.

### Injectable generation or resolution fails

- **Symptom:** at build time, `injectable.config.dart` does not contain a class you annotated. At runtime, *"GetIt: Object/factory with type X is not registered inside GetIt"*, or a stack overflow while resolving a type.
- **Causes and fixes:**
  - **Missing annotation import.** Without `import 'package:injectable/injectable.dart';` the `@injectable` annotation does not resolve, and the generator skips the class. Add the import and rebuild.
  - **Missing `part` directive.** A MobX store needs `part '{file}.g.dart';` before its `_$Store` mixin exists. Without it the class does not compile, and nothing that depends on it is registered.
  - **Circular dependency.** A needs B, and B needs A (directly or through a chain). Break the cycle: pass the data as a method argument, or move the shared logic into a service both depend on ([ADR-0003](adr/0003-no-use-case-to-use-case-dependencies.md)).
  - **Wrong environment.** A class annotated with `env: ['DEVELOPMENT']` is not registered in the prod flavor. Check the `env` list against the flavor you run.
  - **Stale config.** Run `melos run build:app` (or `melos run build`) after any change to an annotation or constructor.

---

## Runtime

### MobX UI does not update

- **Symptom:** the store changes (you can see it in a log or a test) but the widget keeps showing the old value.
- **Cause and fix — check in this order:**
  1. **An `Observer` wraps the widget that reads the value**, and the read happens inside its `builder`. A value read in `build()` outside the `Observer`, or passed into a child as a plain parameter, is not tracked.
  2. **The field is `@observable` or `@readonly`.** A plain field is not reactive. After adding the annotation, run `melos run build`.
  3. **The mutation happens inside an `@action`** (or `runInAction`). A write outside an action is not batched and can be rejected in strict mode.
  4. **Collections are `ObservableList` / `ObservableMap`.** `addAll` on a plain `List` held in an observable changes the list, not the observable, so nothing rebuilds.
  5. **DTOs are replaced, not mutated.** Changing a field inside an element is invisible; assign `list[i] = item.copyWith(...)`.

  Details: [`create-store`](../.claude/skills/create-store/SKILL.md).

### API calls fail

- **Symptom:** requests error out, return unexpected data, or never reach the backend.
- **Cause and fix — check in this order:**
  1. **Read the log interceptor output.** Outside production, Dio's `LogInterceptor` logs each request and response under the `BE` log name: DevTools → Logging, or your IDE's debug console. It shows the final URL, the status code and the response body.
  2. **Check the base URL.** It comes from `FlavorService.config.apiUrl`, which is read from `lib/core/configs/environments/development/development.json` or `…/production/production.json`. Make sure you are running the flavor you think: `-t lib/main_dev.dart` or `-t lib/main_prod.dart`.
  3. **Check whether the dev mock answered.** In the dev flavor, `MockTodosInterceptor` answers `/todos` requests itself and the backend is never called. Its scenario may also be forcing errors: a build made with `--dart-define=MOCK_SCENARIO=serverError` always starts in it, and a `/mock serverError` command typed into the app stays active until `/mock reset` or an app restart.
  4. **Offline?** A connectivity error is not reported to Sentry and shows no notice, by design ([ADR-0020](adr/0020-error-handling-and-issue-tracking.md)); the connection page covers it.
  5. **`401`?** `AuthInterceptor` logs the user out and returns to login.

### The app crashes on launch

- **Symptom:** the app closes or shows a red screen immediately.
- **Fix:** run it attached and read the first error, not the last:

  ```bash
  flutter run -t lib/main_dev.dart -d <device-id>
  flutter logs              # for an app already running
  ```

  A GetIt *"not registered"* error here is an injectable problem (see [Codegen](#codegen)).

---

## Packages and dependencies

### A workspace package is not found

- **Symptom:** *"Couldn't resolve the package 'api'"*, or *"Target of URI doesn't exist: 'package:design_system/…'"*.
- **Cause:** the workspace has not been resolved on this machine, or `.dart_tool/` was deleted (for example by `flutter clean`).
- **Fix:**

  ```bash
  melos bootstrap     # resolves the whole workspace
  melos list          # should list api and design_system
  ```

  `melos list` shows only the two packages: the root app is not a melos package. That is expected.

### Version conflicts

- **Symptom:** `pub get` fails with *"Because X depends on Y ^2.0.0 and Z depends on Y ^1.0.0, version solving failed."*
- **Cause:** the app, `packages/api` and `packages/design_system` resolve together as one Dart workspace, so a constraint in any of the three pubspecs, or in a transitive dependency, can conflict with another.
- **Fix:**
  1. Read the solver message: it names the package and both constraints.
  2. See who pulls the package in:

     ```bash
     flutter pub deps --style=compact
     ```

  3. Align the constraint in every pubspec that declares it, then `melos bootstrap`.
  4. See what is outdated across the app and both packages (report only, it changes nothing):

     ```bash
     melos run deps:check
     ```

---

## Tests

### A test fails and you need detail

- **Fix:** run the single file, or the single test, with one line per test:

  ```bash
  flutter test test/features/home/mobx/home_store_test.dart --reporter expanded
  flutter test --name 'should set error' --reporter expanded
  ```

### `'when' is imported from both …`

- **Symptom:** a test file does not compile after importing both `package:mobx/mobx.dart` and `package:mocktail/mocktail.dart`.
- **Cause:** both packages export a top-level `when`.
- **Fix:** import only what you need from MobX:

  ```dart
  import 'package:mobx/mobx.dart' show ObservableList;
  ```

### A widget test finds nothing, or times out

- **Symptom:** every finder returns nothing with no error, on the second `testWidgets` in a file; or `pumpAndSettle` times out after 10 seconds.
- **Cause:** `EasyLocalization` mounted per test never finishes loading under `pump()`; skeleton and FAB animations never settle.
- **Fix:** use the harness in `test/helpers/pump_app.dart`: `setUpAll(initLocalizationForTests)`, `tester.pumpApp(...)`, and `tester.settleFrames()` instead of `pumpAndSettle`. See [`write-tests`](../.claude/skills/write-tests/SKILL.md).

### A test passes alone and fails with the others

- **Cause:** state leaking between tests: a `getIt` registration without `tearDown(getIt.reset)`, an undisposed MobX reaction, a mock method-call handler left on a channel, or mock interceptor state (`MockTodosInterceptor.reset()`).
- **Fix:** reset each of those in `tearDown`.

---

## Performance

### The app is slow or janky

- **Cause:** often debug mode itself. Debug builds are unoptimized and much slower than release; never judge performance in debug.
- **Fix:** profile on a **physical device** (profile mode does not run on simulators or emulators):

  ```bash
  flutter run --profile -t lib/main_dev.dart -d <device-id>
  ```

  Open DevTools from the link `flutter run` prints and use the Performance view to find the slow frames. Common fixes:
  - `const` constructors wherever the widget allows it, so unchanged subtrees are not rebuilt.
  - `Observer` scoped to the smallest subtree that reads the observable, not the whole page.
  - A `RepaintBoundary` around a subtree that repaints often (an animation, a progress indicator) next to one that does not.
  - Filtering and sorting in a `@computed` or `useMemoized`, never directly in `build()` ([ADR-0019](adr/0019-hook-selection.md)).

### Memory keeps growing

- **Symptom:** memory use climbs as you move between screens and never comes back down.
- **Cause:** something outlives its screen: a controller, a stream subscription, a timer, or a MobX reaction that was never disposed.
- **Fix:**
  - Controllers from hooks (`useTextEditingController`, `useScrollController`, …) dispose themselves; ones created with `useMemoized` need a disposing `useEffect`.
  - Page states cancel their reactions and subscriptions in `dispose()`, which the page's `Provider` calls.
  - Use DevTools → Memory to take a snapshot before and after opening and closing the screen, and look for instances of its state class that are still alive.

### The app is too big

- **Fix:** see what takes the space:

  ```bash
  flutter build apk --analyze-size --target-platform android-arm64 -t lib/main_prod.dart
  ```

  Open the generated size file in DevTools → App Size.

---

## Devices

### No device shows up

- **Fix:** list what Flutter can see, then boot what you need:

  ```bash
  flutter devices                   # connected devices and running simulators/emulators
  flutter emulators                 # emulators and simulators Flutter can launch

  # iOS
  xcrun simctl list devices         # every simulator and its state
  xcrun simctl boot <udid>
  open -a Simulator

  # Android
  emulator -list-avds
  emulator -avd <avd_name>
  adb devices
  ```

  If `emulator` is not found, add `$ANDROID_HOME/emulator` to `PATH`.

### A simulator is broken

- **Symptom:** a simulator hangs on boot or the app will not install.
- **Fix:** erase that simulator. This deletes every app and its data on it:

  ```bash
  xcrun simctl shutdown <udid>
  xcrun simctl erase <udid>
  ```

---

## Maestro

### Maestro cannot find an element by `id`

- **Symptom:** `tapOn: { id: "…" }` or `assertVisible` fails although the widget is on screen.
- **Cause:** the widget has only a Flutter `Key`. A `Key` is not exported to the native accessibility tree, so Maestro cannot see it. Only `Semantics(identifier:)` sets a native accessibility id.
- **Fix:** tag the widget with `TestId` (`lib/core/ui/test_id.dart`) using the constant from the feature's `*_keys.dart`; it sets both the `Semantics` identifier and the `Key`. To see what Maestro actually sees:

  ```bash
  maestro hierarchy
  ```

  Details: [`write-maestro-flow`](../.claude/skills/write-maestro-flow/SKILL.md).

### Every flow fails within a second

- **Symptom:** all flows report `[Failed]` almost immediately, with an unhelpful error in the report.
- **Cause:** the app under test is not installed on the device, or `APP_ID` does not match it. `flutter create --org com.example` gives iOS the bundle id `com.example.flutterBoilerplate` but Android the applicationId `com.example.flutter_boilerplate`.
- **Fix:** install the dev build on the device, and pass the id that platform uses:

  ```bash
  APP_ID=com.yourcompany.yourApp DEVICE=<udid-or-adb-serial> melos run maestro
  ```

  The report and debug output (screenshots, logs) are under `.maestro/output/`, or `OUT_DIR` if you set it.

### An Android device stays offline after a run

- **Cause:** a flow failed between `common/go_offline.yaml` and `common/go_online.yaml`.
- **Fix:** `tool/run_maestro.sh` restores connectivity when it exits. By hand:

  ```bash
  adb shell cmd connectivity airplane-mode disable
  ```

---

## Asking for help

Try the fixes above first, then `flutter clean && flutter pub get` and `melos run build`. If the problem is still there, include:

- **The exact error**, copied as text, starting from the first error rather than the last line.
- **What you ran**, and whether it worked before (which commit or branch).
- **Steps to reproduce**, as short as you can make them.
- **Environment:** the output of `flutter doctor -v`, your OS, and the device or simulator (model and OS version).
- **The flavor** (`main_dev.dart` or `main_prod.dart`) and, for API problems, the request and response from the log.
- **For a failing test or flow:** the test name, the `--reporter expanded` output, or the Maestro report and screenshots from `.maestro/output/`.
- **What you already tried**, so nobody suggests it again.

Never paste tokens, API keys, `.env` contents or signing files.
