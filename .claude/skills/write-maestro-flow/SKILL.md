---
name: write-maestro-flow
description: Write a Maestro E2E flow for a feature — the mandatory happy/failure/edge trio, file layout, discovery and naming, the APP_ID contract and runner, selecting by TestId and not asserting UI copy, bounded waits, driving error states through the mock interceptor, device-state helpers (offline/online), gestures (percentage coordinates, shared swipe subflows, Dismissible thresholds) and transient UI, subflows, tags, and running locally or in CI. Use when a feature is functionally complete and needs its end-to-end proof.
---

# Write a Maestro flow

Governed by [ADR-0015](../../../docs/adr/0015-mandatory-test-coverage-and-qa-gate.md). Every feature ships **three** categories of flow. Docs: https://docs.maestro.dev

## Layout and naming

```
.maestro/
  config.yaml                          workspace config: discovery glob, excludeTags quarantine
  common/                              subflows, reached only through runFlow
    launch.yaml                        APP_ID guard + launch with clear state
    login.yaml                         sign-in subflow
    start_home.yaml                    launch + login, the start of every Home flow
    set_mock.yaml                      switch the dev mock interceptor's scenario
    go_offline.yaml / go_online.yaml   device connectivity, Android only, always a pair
  flows/{feature}/
    {feature}_{scenario}_happy.yaml
    {feature}_{scenario}_failure.yaml
    {feature}_{scenario}_edge.yaml
  output/                              run output (gitignored): report.xml, debug/, artifacts/
tool/run_maestro.sh                    the runner, used by melos and CI
```

**Naming.** The canonical name is `{feature}_{scenario}_{happy|failure|edge}.yaml`, as in `home_add_todo_happy.yaml` and `home_todos_failure.yaml`. A feature with a single scenario may leave the scenario out: `{feature}_{happy|failure|edge}.yaml`.

The category is in the filename so a directory listing shows immediately whether the trio exists. It is also a tag, so CI can run `--include-tags happy` on every PR and the full set nightly.

The workspace config holds no appId and no retry policy. The app under test comes from `APP_ID` (below), and Maestro has no suite-level retry.

## Discovery: subflows never match the glob

`config.yaml` declares `flows: ["flows/*/*.yaml"]`. In a glob a single `*` never crosses `/`, so this picks up every `flows/{feature}/{flow}.yaml` for every feature folder, and nothing else:

| Path | Runs as a test? |
|---|---|
| `flows/home/home_todos_happy.yaml` | yes |
| `flows/{new_feature}/{flow}.yaml` | yes, no config change needed |
| `common/launch.yaml` | no, it is not under `flows/` |
| `flows/home/_helpers/x.yaml` | no, one level too deep |
| `flows/stray_flow.yaml` | no, it is not in a feature folder |

**Rule: a subflow must never match the glob.** A subflow assumes the app is already launched and on a particular screen. Run as a standalone test, it fails, or it passes against the wrong state. Put subflows in `.maestro/common/`.

- Don't widen the glob to `flows/**`. Any helper nested under a feature would then run as a test.
- Don't narrow it to per-prefix globs (`flows/home/home_*.yaml`). The next feature folder would be skipped silently, and a missing suite looks exactly like a passing one.
- `excludeTags: [quarantine]` in the config merges with CLI tags: `--include-tags happy` still skips a flow tagged `happy` + `quarantine`.
- A single-file run (`maestro test .maestro/flows/home/x.yaml`) does not read `config.yaml` at all. That is how you debug a quarantined flow.

## The mandatory trio

| Category | Proves |
|---|---|
| **happy** | the intended path completes and the success state is visible |
| **failure** | server 5xx / expired auth / dropped network → a recoverable error, no crash, no permanent spinner |
| **edge** | empty list, single item, max-length input, offline start, backgrounding mid-request, rapid double-tap on the primary action |

One file per category minimum. A feature with only a happy flow is not done.

## The app under test: `APP_ID`

Every flow **and every subflow** header is `appId: ${APP_ID}`. Never hardcode a bundle id. The app is chosen in one place:

- `flutter create --org com.example` gives this repo **two different ids**: the iOS bundle id is `com.example.flutterBoilerplate`, the Android `applicationId` is `com.example.flutter_boilerplate`. So `tool/run_maestro.sh` picks the default by target platform when `APP_ID` is unset. It uses Android when `DEVICE` is listed in `adb devices`, or when `DEVICE` is unset and the only connected target is one Android device/emulator; otherwise iOS. It prints the platform, the chosen id and why.
- An app generated with its own `--org` sets it explicitly: `APP_ID=com.acme.app ./tool/run_maestro.sh`.
- The runner passes it with `-e APP_ID=...`. Maestro does **not** read plain shell variables (only `MAESTRO_`-prefixed ones), so `APP_ID=x maestro test .maestro` without `-e` does nothing.
- `-e` values reach every subflow run through `runFlow`, including a `runFlow` that passes its own `env:`. Verified on device with Maestro 2.6.1. You never forward `APP_ID` by hand.
- An unset `${APP_ID}` evaluates to the string `"undefined"`. `common/launch.yaml` checks for this first and fails at once with `APP_ID_IS_NOT_SET-run_tool/run_maestro.sh_or_pass_-e_APP_ID`. That message shows up in the console, in single-flow output and in the JUnit report. Any new entry subflow (`start_{feature}.yaml`) must go through `launch.yaml` so it keeps that guard.
- A wrong `APP_ID` fails every flow in about a second, but Maestro's JUnit report only says "Unknown error". The runner checks the app is installed on `DEVICE` before it starts and says so plainly.

## Flow header: preconditions and test ids

Every flow and subflow opens with a comment block that states what it assumes and which ids it touches. A reader then knows what the flow depends on without tracing every `runFlow`, and a renamed id can be found with one grep.

```yaml
# AC: submitting a non-empty title creates the todo and it appears in the list.
#
# Preconditions: common/start_home.yaml (clean state, signed in, mock `normal`).
# Test ids: home_add_todo_fab, add_todo_title_field, add_todo_counter,
#   add_todo_submit, add_todo_error, home_todo_list
appId: ${APP_ID}
name: "Home — add a todo (happy)"
tags:
  - happy
  - home
---
```

Preconditions cover anything the flow does not set up itself: the build (dev flavor), the starting screen, the signed-in user, the mock scenario, the platform (Android-only flows say so), and any env the subflow needs.

## Select by identifier, never by copy

**A plain Flutter `Key` is invisible to Maestro.** Verified on device: a widget carrying only a `Key` appears in the hierarchy with an empty `resource-id`. What `id:` matches is the *native* accessibility identifier, and the only thing that sets it is `Semantics(identifier:)` — `UIAccessibilityElement.accessibilityIdentifier` on iOS, `setViewIdResourceName` on Android.

Use the `TestId` helper (`lib/core/ui/test_id.dart`). It applies both from one string: `Semantics(identifier:)` for Maestro, and a `Key` for widget tests.

```dart
// lib/features/home/view/home_keys.dart — plain Strings, not Key objects
class HomeKeys {
  HomeKeys._();
  static const addTodoFab = 'home_add_todo_fab';
  static const todoList = 'home_todo_list';
}

// at the use site
_NewTodoFab(...).withTestId(HomeKeys.addTodoFab)
TestId(HomeKeys.todoList, child: RefreshIndicator(...))
```

```yaml
- tapOn:
    id: "home_add_todo_fab"
- assertVisible:
    id: "home_todo_list"
```

Where the ids live:

- A feature widget's ids are in the feature's `{feature}_keys.dart`.
- A shared widget in `lib/core/ui/` belongs to no feature, so its ids are in a `{widget}_keys.dart` next to it: `lib/core/ui/error_notice_keys.dart` for `error_notice.dart`.

**Select by id; do not assert UI copy.** Every element a flow acts on or waits for is selected with `id:`. Identifiers are the contract; copy is localized and changes ([ADR-0012](../../../docs/adr/0012-mandatory-localization.md)). Asserting a *value* is fine when it comes from data rather than from translations:

- mock seed data: `assertVisible: "Buy groceries"` after the list loads;
- text the flow typed itself: `"Buy milk"` after adding it.

Asserting UI copy is not: a button label, an empty-state sentence, an error message. Assert the id of the widget that shows it. If a flow needs an id that does not exist, add it to the keys file and tag the widget — do not fall back to matching on copy.

**Check with `inspect_screen` before writing selectors.** A tagged widget shows `"rid": "home_add_todo_fab"`. An empty `rid` means the tag is missing, and every `id:` selector against it will fail with "Element not found".

## Skeleton

```yaml
# .maestro/flows/home/home_add_todo_happy.yaml
# AC: submitting a non-empty title creates the todo and it appears in the list.
#
# Preconditions: common/start_home.yaml (clean state, signed in, mock `normal`).
# Test ids: home_add_todo_fab, add_todo_title_field, add_todo_submit, home_todo_list
appId: ${APP_ID}
name: "Home — add a todo (happy)"
tags:
  - happy
  - home
---
- runFlow: ../../common/start_home.yaml

- tapOn:
    id: "home_add_todo_fab"
    label: "Open the add-todo modal"

- tapOn:
    id: "add_todo_title_field"
- inputText: "Buy milk"

- tapOn:
    id: "add_todo_submit"

- extendedWaitUntil:
    visible:
      text: "Buy milk"
    timeout: 8000

- assertVisible:
    id: "home_todo_list"
```

### `clearState` logs the user out

`clearState: true` belongs on every flow — one that depends on the previous flow's state passes locally and fails in CI. But it also clears the auth token, so the app comes up on **Login**, not on the screen under test. Waiting for a Home id straight after `launchApp` then fails with a timeout that looks like a broken selector.

Three subflows, so no flow repeats it:

```
common/launch.yaml       APP_ID guard, launchApp + clearState, waits for the login field
common/login.yaml        types ${EMAIL}, taps continue, waits for Home
common/start_home.yaml   runs both — the starting point for every Home flow
```

```yaml
# common/start_home.yaml
appId: ${APP_ID}
---
- runFlow: launch.yaml
- runFlow:
    file: login.yaml
    env:
      EMAIL: "qa@example.com"
```

## Waiting

- **Never `sleep`.** There is no sleep command, and coercing one with `repeat` hides real latency bugs.
- `extendedWaitUntil` with an explicit `timeout` for anything that waits on the network.
- `waitForAnimationToEnd` after a transition or a modal open — and after dismissing a sheet before reopening it.
- `assertVisible` already retries briefly; use `extendedWaitUntil` only when the wait is genuinely long.
- **Every wait is bounded.** A timeout is the flow's statement of how slow is too slow.
- **Settle briefly after a connectivity change.** The change reaches the app on a platform stream, so the very next command races it. Wait for the app's own offline/online signal when it has one (`extendedWaitUntil` on its id). Otherwise use a short capped `waitForAnimationToEnd`, and know that it only means the screen stopped moving.
- **Wait past the retry schedule before asserting that data synced.** Reconnecting is not syncing. An app that re-sends on a 3 s / 10 s / 30 s ladder may not retry for most of a minute, so the `extendedWaitUntil` timeout must be longer than the whole ladder plus one request. Too short, and the flow fails on a slow retry instead of a real bug. `common/go_online.yaml` takes `SYNCED_ID` and `SYNC_TIMEOUT_MS` for exactly this.

## Four device behaviours that each cost an hour

Found by running these flows on a simulator, not by reading the docs.

**`hideKeyboard` can submit the form.** On iOS it presses the keyboard's **Done** key, so a `TextField` with `onSubmitted:` fires and the form submits before your next command — the flow then fails asserting on a sheet that already closed. Do not use it after typing into a field that submits on done; tap the submit button instead. It is still fine on a field with no `onSubmitted`, such as a login email field.

**`eraseText` with no argument does not clear the field.** It erases a fixed default (~50 characters). Type 80 characters, `eraseText`, type again, and the tail of the first string is silently concatenated onto the second. Pass an explicit count (`eraseText: 100`), or better, dismiss the sheet and reopen it so each case starts clean.

**`swipe: from: { id }` is too short for a `Dismissible`.** On iOS the element swipe drags from the element's centre to x=40 — about 40% of a full-width row — and XCTest releases with no fling velocity. After Flutter's touch slop that falls just short of `Dismissible`'s default 40% threshold, so the row springs back and nothing is dismissed. (Found by an agent building swipe-to-delete from these playbooks.) Two remedies, in this order:

1. **Lower that direction's threshold in the app, if product agrees:** `dismissThresholds: {DismissDirection.endToStart: 0.25}`. The element swipe then clears it and the flow needs no coordinates. It also changes how the row feels to every user, so it is a product decision, not a test fix.
2. **Otherwise, a percentage-based swipe in a shared `common/` subflow**, see [Swipes and gestures shared by several flows](#swipes-and-gestures-shared-by-several-flows).

Either way, assert the row's id before and after the swipe, so a swipe that missed or sprang back fails instead of passing.

**`maestro test .maestro/flows` finds nothing.** Only the directory you pass is searched for `config.yaml`, and without one Maestro's default glob is `*`: top-level YAML only, while every flow sits one level down in a feature folder. It prints "Top-level directories do not contain any Flows". Point it at the workspace root, `maestro test .maestro`, or better, use `./tool/run_maestro.sh`.

## Driving the failure and edge cases

**Don't invent a failure toggle the app doesn't have.** A flow that sets a launch argument, header or env var nothing in the app reads will "pass" while never reaching the failure branch. Failure injection goes through what exists:

1. **The dev mock interceptor.** The app under test runs against `MockTodosInterceptor` (`lib/core/services/interceptors/mock_todos_interceptor.dart`), not a live backend. Its scenario (`normal | empty | serverError | slow | reset`) is switched at run time by typing a `/mock <scenario>` command into the add-todo field. `common/set_mock.yaml` does that for you:

   ```yaml
   - runFlow: ../../common/start_home.yaml
   - runFlow:
       file: ../../common/set_mock.yaml
       env:
         SCENARIO: "serverError"
   ```

   The scenario is a static in the app process, so set it **after** launch; `clearState: true` restarts the process and resets it to `normal`. A new endpoint needs its own mock branch in the interceptor before a flow can fail it.

2. **Otherwise, ask.** If the failure lives in a real backend the mock does not cover, ask the backend team how to trigger it in the test environment. Don't fake it in the flow.

Then assert the recovery affordance, not just the absence of a crash:

```yaml
- extendedWaitUntil:
    visible:
      id: "home_error_state"
    timeout: 10000
- assertNotVisible:
    id: "home_skeleton_list"    # the spinner must actually stop
- runFlow:                      # the server recovers
    file: ../../common/set_mock.yaml
    env:
      SCENARIO: "reset"
- tapOn:
    id: "home_error_retry"
- extendedWaitUntil:
    visible:
      id: "home_todo_list"
    timeout: 10000
```

## Device state: offline and online

Use the shared helpers instead of writing your own:

```yaml
- runFlow: ../../common/go_offline.yaml
# ... assert the offline UI ...
- runFlow:
    file: ../../common/go_online.yaml
    env:
      SYNCED_ID: "{feature}_synced"    # optional: the feature's own "reached the server" id
      SYNC_TIMEOUT_MS: "45000"         # longer than the feature's whole retry schedule
```

**Always a pair.** Every `go_offline` has a `go_online` in the same flow. The run does not stop at the first failure (`continueOnFailure`), so a flow that dies between the two leaves the emulator in airplane mode, and every later flow fails for a reason that has nothing to do with it. `tool/run_maestro.sh` restores connectivity on exit on Android. By hand:

```bash
adb shell cmd connectivity airplane-mode disable
```

**Android only.** `setAirplaneMode` really takes the radios down on an Android emulator. On iOS it is a no-op: the simulator has no airplane mode and shares the host Mac's network, and Maestro just logs a warning and carries on. Tag offline flows (for example `offline`) so an iOS run can pass `--exclude-tags offline`, and run them on an Android emulator.

The preferred iOS route, when a project needs one, is a debug-only in-app network switch: a control compiled only into dev builds that forces the app's HTTP/connectivity layer offline, tagged with `TestId` along with a state marker. The boilerplate does **not** ship one, so don't write flows against ids for it; build the switch first. Host-level blocking (Network Link Conditioner, `pfctl`) is not a substitute. The interface stays up, so the app still thinks it is online and requests just time out, which is a different code path.

## Fail loudly on unsupported platforms

A flow that cannot do its job on a platform must fail there, never silently pass. A green offline test that ran fully online is worse than no test.

Branch on `${maestro.platform}` and hard-stop everything except the platforms that work. Take the screenshot first, because nothing after the failing assertion runs. Then assert a marker id that never exists and whose text is the error message, so it lands verbatim in the console and the JUnit report:

```yaml
- runFlow:
    when:
      true: ${maestro.platform !== 'android'}
    commands:
      - takeScreenshot: "go_offline_unsupported_platform"
      - assertVisible:
          id: "GO_OFFLINE_NOT_SUPPORTED_ON_THIS_PLATFORM-setAirplaneMode_only_works_on_Android-run_offline_flows_on_an_Android_emulator"
```

Keep marker ids to letters, digits, `_`, `-` and `/`. `id:` is a regex.

## Gestures and transient UI

- **Assertions only run after a gesture ends.** Maestro runs commands one at a time, so the `assertVisible` after a `swipe` or a long press runs once the finger has lifted. UI that shows only mid-hold or mid-drag (a speed pill, a scrub time bubble, a "release to cancel" hint) can't be asserted. Assert the durable before and after state instead (the value changed, the hint is gone), add a `takeScreenshot` on each side, and check the transient UI by hand in `maestro studio`. The same goes for animation feel (spring, overshoot): a flow can prove the end state, not the physics.
- **Aim at the element first. When a gesture needs screen coordinates, use percentages.** `tapOn: { id: ..., point: "75%,50%" }` measures within that element's bounds, and `swipe: { from: { id: ... }, direction: RIGHT }` starts on the element, so both survive a layout change. A coordinate swipe (`start:` / `end:`) is for what the element forms cannot do, such as the `Dismissible` case above, and its coordinates are always percentages (`start: "90%, 32%"`). Never device points or pixels: Android coordinates are pixels and iOS coordinates are points, so a number that works on one device lands somewhere else on the next.

  ```yaml
  - tapOn:
      id: "player_surface"        # placeholder: your feature's id
      point: "75%,50%"            # right third of the element, not of the screen
      repeat: 2
  - swipe:
      from:
        id: "player_surface"
      direction: RIGHT
      duration: 1500              # slow: a drag
  ```

- **Swipe `duration` separates a drag from a fling.** A long duration (~1000–1500 ms) is a deliberate drag that tracks the finger; a short one (~100–300 ms) is a fling with velocity, which can trigger dismiss/snap behaviour instead. Pick the one the AC describes and keep it explicit.
- **OS-level UI is outside the app's accessibility tree.** A picture-in-picture window or a system sheet is not part of the app's hierarchy, so the app's `id:`s won't find anything there. Assert the app-side effect instead (the player left the screen, the share callback fired), or leave that step to manual QA and say so in the flow header.

### Swipes and gestures shared by several flows

A swipe or other gesture that more than one flow performs goes into a `.maestro/common/` subflow that takes the row id as a parameter. Never paste the same coordinate swipe into several flows: when the row moves, one copy gets fixed and the others fail.

Maestro cannot anchor a coordinate swipe to an element, so a swipe subflow also takes the row's vertical centre as a percentage of the screen height. Read it from `inspect_screen` (bounds centre divided by screen height), for a row near the top of the list. The percentage still shifts a little between screen heights, which is one more reason to prefer the threshold remedy when product agrees. The row id assertions are what stop a missed swipe from passing.

Illustrative: this repo has no swipe-to-delete and no `home_todo_row_{id}` ids; create the subflow with the first flow that needs it.

```yaml
# .maestro/common/swipe_row_left.yaml
# SUBFLOW: drag one list row from right to left across most of the screen,
# far enough to pass a Dismissible's default 40% threshold.
#
#   - runFlow:
#       file: ../../common/swipe_row_left.yaml
#       env:
#         ROW_ID: "home_todo_row_1"
#         ROW_Y: "32%"
#
# Preconditions: the row is on screen.
# Needs env:
#   ROW_ID  the row's test id.
#   ROW_Y   the row's vertical centre, as a percentage of the screen height.
# Test ids: ${ROW_ID}
appId: ${APP_ID}
---
# Before: a missing row fails here, not as a swipe that hit something else.
- assertVisible:
    id: "${ROW_ID}"

- swipe:
    start: "90%, ${ROW_Y}"
    end: "5%, ${ROW_Y}"
    duration: 400

- waitForAnimationToEnd
```

The calling flow asserts the after state, because it depends on the scenario. Happy: the row is gone. Failure: the row comes back once the request fails.

```yaml
- runFlow:
    file: ../../common/swipe_row_left.yaml
    env:
      ROW_ID: "home_todo_row_1"
      ROW_Y: "32%"
- extendedWaitUntil:
    notVisible:
      id: "home_todo_row_1"
    timeout: 5000
```

## Edge patterns worth copying

```yaml
# empty state
- assertVisible: { id: "home_empty_state" }
- assertNotVisible: { id: "home_todo_list" }

# rapid double-tap must not create two records
- tapOn: { id: "add_todo_submit", repeat: 2, delay: 100 }
- assertVisible: { text: "Buy milk", index: 0 }
- assertNotVisible: { text: "Buy milk", index: 1 }

# max-length input: the field caps at 80 and the counter says so
- inputText: "${'x'.repeat(90)}"
- assertVisible: { id: "add_todo_counter" }
- assertVisible: "80 / 80"

# backgrounding mid-request
- tapOn: { id: "add_todo_submit" }
- pressKey: "home"
- launchApp: { stopApp: false }
- extendedWaitUntil: { visible: { id: "home_todo_list" }, timeout: 8000 }
```

## Subflows

Extract anything used by three or more flows into `.maestro/common/` and call it with `runFlow`. A gesture used by two flows is already enough ([above](#swipes-and-gestures-shared-by-several-flows)). Login is always a subflow. Pass data with `env:` rather than duplicating the steps. Subflows keep the `appId: ${APP_ID}` header and the preconditions/test-ids comment, and never live under `flows/`.

## Running

```bash
./tool/run_maestro.sh                                  # whole suite, JUnit in .maestro/output/report.xml
./tool/run_maestro.sh --include-tags happy             # the PR gate; extra args go to `maestro test`
DEVICE=<udid|adb serial> ./tool/run_maestro.sh         # pick a device when several are booted
APP_ID=com.acme.app ./tool/run_maestro.sh              # an app generated with its own --org (default: per platform)
OUT_DIR=/tmp/maestro ./tool/run_maestro.sh             # write output elsewhere
melos run maestro                                      # the runner via melos
melos run maestro:happy                                # happy flows only

maestro test .maestro/flows/home/home_add_todo_happy.yaml -e APP_ID=com.example.flutterBoilerplate    # one flow, iOS
maestro test .maestro/flows/home/home_add_todo_happy.yaml -e APP_ID=com.example.flutter_boilerplate   # one flow, Android
maestro studio                                         # interactive selector inspector
```

The runner runs `maestro test .maestro` (the workspace root), writes `report.xml` (JUnit), `debug/` (maestro.log, per-flow command JSON, failure screenshots) and `artifacts/` (`takeScreenshot` output) under `OUT_DIR`, and exits with Maestro's exit code.

First run on a clean machine — boot, build the dev flavor, install.

iOS simulator (bundle id `com.example.flutterBoilerplate`):

```bash
xcrun simctl boot "iPhone 17"
flutter build ios --simulator --debug -t lib/main_dev.dart
xcrun simctl install booted build/ios/iphonesimulator/Runner.app
```

Android emulator (applicationId `com.example.flutter_boilerplate`):

```bash
emulator -avd <avd_name> &            # or start it from Android Studio's Device Manager
flutter build apk --debug -t lib/main_dev.dart
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

When driving Maestro from an agent, `list_devices` → `inspect_screen` → `run` via the Maestro MCP, pass `APP_ID` in `env`, and inspect the hierarchy before writing a selector rather than guessing an id.

## Flakiness

Flows are device-dependent and will occasionally go red for reasons unrelated to the code. Handle it, do not delete the flow:

- There is no retry policy to tune. `config.yaml` holds no retries, and a `retry:` wrapped around half a flow masks real instability. Fix the wait: a missing bounded `extendedWaitUntil` is the usual cause.
- A persistently flaky flow gets a `quarantine` tag and a linked ticket. `config.yaml` excludes that tag from every workspace run. It is not removed.
- Check device state before blaming the flow: a device left in airplane mode by an earlier flow fails everything after it.

## Checklist

- [ ] All three categories exist in `.maestro/flows/{feature}/`, named `{feature}_{scenario}_{happy|failure|edge}.yaml` (or `{feature}_{happy|failure|edge}.yaml` for a single-scenario feature)
- [ ] Header is `appId: ${APP_ID}` (never a hardcoded bundle id), plus `name` and category `tags`
- [ ] Header comment lists the preconditions and every test id the flow uses
- [ ] Every flow starts from `common/start_home.yaml` (or another entry subflow that runs `launch.yaml`) — clean state, APP_ID guard **and** signed in
- [ ] New subflows live in `.maestro/common/` and do not match `flows/*/*.yaml`
- [ ] Selectors use `id:` from `{feature}_keys.dart` (or a `lib/core/ui/{widget}_keys.dart`), applied with `TestId` — a bare `Key` is invisible to Maestro
- [ ] No assertion on UI copy; only ids, mock seed values and text the flow typed
- [ ] `inspect_screen` shows a non-empty `rid` for every id the flow uses
- [ ] No `hideKeyboard` after a field that submits on done; no bare `eraseText`
- [ ] No sleeps; every wait bounded; sync assertions wait past the retry schedule
- [ ] Failure injection uses `MockTodosInterceptor` / `set_mock.yaml` — no invented toggle
- [ ] Failure flow asserts the spinner stopped *and* that retry recovers
- [ ] Every `go_offline` has a matching `go_online`; offline flows are Android-only and tagged as such
- [ ] Anything a platform can't do fails loudly there (screenshot + marker assertion), never passes silently
- [ ] Gesture flows assert before/after state with screenshots, aim at elements first, use percentage coordinates otherwise (never points or pixels), and set an explicit swipe `duration`
- [ ] A `Dismissible` swipe: threshold lowered in the app (product agreed) or a percentage swipe subflow; row id asserted before and after
- [ ] Shared steps extracted to `.maestro/common/`; a gesture used by more than one flow is a subflow that takes the row id
- [ ] Any new endpoint the flow hits has a mock branch in the interceptor
- [ ] Passes twice in a row locally (`./tool/run_maestro.sh`) before being pushed
