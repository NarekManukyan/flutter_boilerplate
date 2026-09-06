---
name: write-maestro-flow
description: Write a Maestro E2E flow for a feature — the mandatory happy/failure/edge trio, file layout and naming, selecting by widget Key, waiting without sleeps, driving error states through the mock interceptor, subflows, tags, and running locally or in CI. Use when a feature is functionally complete and needs its end-to-end proof.
---

# Write a Maestro flow

Governed by [ADR-0015](../../../docs/adr/0015-mandatory-test-coverage-and-qa-gate.md). Every feature ships **three** categories of flow. Docs: https://docs.maestro.dev

## Layout and naming

```
.maestro/
  config.yaml                          workspace config: appId, includeTags, flakiness retries
  common/
    launch.yaml                        launch + clear state, reused by every flow
    login.yaml                         sign-in subflow
  flows/{feature}/
    {feature}_{scenario}_happy.yaml
    {feature}_{scenario}_failure.yaml
    {feature}_{scenario}_edge.yaml
```

The category is in the filename so a directory listing shows immediately whether the trio exists. It is also a tag, so CI can run `--include-tags happy` on every PR and the full set nightly.

## The mandatory trio

| Category | Proves |
|---|---|
| **happy** | the intended path completes and the success state is visible |
| **failure** | server 5xx / expired auth / dropped network → a recoverable error, no crash, no permanent spinner |
| **edge** | empty list, single item, max-length input, offline start, backgrounding mid-request, rapid double-tap on the primary action |

One file per category minimum. A feature with only a happy flow is not done.

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

Text is localized and will change; identifiers are the contract ([ADR-0012](../../../docs/adr/0012-mandatory-localization.md)). If a flow needs an id that does not exist, add it to `{feature}_keys.dart` and tag the widget — do not fall back to matching on copy.

**Check with `inspect_screen` before writing selectors.** A tagged widget shows `"rid": "home_add_todo_fab"`. An empty `rid` means the tag is missing, and every `id:` selector against it will fail with "Element not found".

## Skeleton

```yaml
# .maestro/flows/home/home_add_todo_happy.yaml
appId: com.example.flutterBoilerplate
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
common/launch.yaml       launchApp + clearState, waits for the login field
common/login.yaml        types ${EMAIL}, taps continue, waits for Home
common/start_home.yaml   runs both — the starting point for every Home flow
```

```yaml
# common/start_home.yaml
appId: com.example.flutterBoilerplate
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

## Three device behaviours that each cost an hour

Found by running these flows on a simulator, not by reading the docs.

**`hideKeyboard` can submit the form.** On iOS it presses the keyboard's **Done** key, so a `TextField` with `onSubmitted:` fires and the form submits before your next command — the flow then fails asserting on a sheet that already closed. Do not use it after typing into a field that submits on done; tap the submit button instead. It is still fine on a field with no `onSubmitted`, such as a login email field.

**`eraseText` with no argument does not clear the field.** It erases a fixed default (~50 characters). Type 80 characters, `eraseText`, type again, and the tail of the first string is silently concatenated onto the second. Pass an explicit count (`eraseText: 100`), or better, dismiss the sheet and reopen it so each case starts clean.

**`maestro test .maestro/flows` finds nothing.** The directory runner does not recurse on its own. Point it at the workspace root — `maestro test .maestro` — where `config.yaml` declares `flows: ["flows/**"]`.

## Driving the failure and edge cases

The app under test runs against `MockTodosInterceptor` (`lib/core/services/interceptors/`), not a live backend. To exercise a failure, add a mock branch keyed on something the flow can set — a header, a magic input value, or a launch env var — then trigger it from the flow:

```yaml
- launchApp:
    clearState: true
- runFlow:
    file: ../../common/launch.yaml
    env:
      MOCK_MODE: "server_error"
```

Then assert the recovery affordance, not just the absence of a crash:

```yaml
- extendedWaitUntil:
    visible:
      id: "home_error_state"
    timeout: 5000
- assertNotVisible:
    id: "home_loading"          # the spinner must actually stop
- tapOn:
    id: "home_error_retry"
- assertVisible:
    id: "home_todo_list"
```

For offline behaviour, `setAirplaneMode` is Android-only — on iOS simulators drive it through the mock/connectivity layer instead.

## Edge patterns worth copying

```yaml
# empty state
- assertVisible: { id: "home_empty_state" }
- assertNotVisible: { id: "home_todo_list" }

# rapid double-tap must not create two records
- tapOn: { id: "add_todo_submit", repeat: 2, delay: 100 }
- assertVisible: { text: "Buy milk", index: 0 }
- assertNotVisible: { text: "Buy milk", index: 1 }

# max-length input
- inputText: "${'x'.repeat(280)}"
- assertVisible: { id: "add_todo_length_error" }

# backgrounding mid-request
- tapOn: { id: "add_todo_submit" }
- pressKey: "home"
- launchApp: { stopApp: false }
- extendedWaitUntil: { visible: { id: "home_todo_list" }, timeout: 8000 }
```

## Subflows

Extract anything used by three or more flows into `.maestro/common/` and call it with `runFlow`. Login is always a subflow. Pass data with `env:` rather than duplicating the steps.

## Running

```bash
maestro test .maestro/flows/home/home_add_todo_happy.yaml   # one flow
maestro test .maestro                                       # whole suite (NOT .maestro/flows)
maestro test .maestro --include-tags happy                  # the PR gate
melos run maestro                                           # same, needs a booted device
maestro studio                                              # interactive selector inspector
```

First run on a clean machine — boot, build the dev flavor, install:

```bash
xcrun simctl boot "iPhone 17"
flutter build ios --simulator --debug -t lib/main_dev.dart
xcrun simctl install booted build/ios/iphonesimulator/Runner.app
```

Boot a simulator first (`xcrun simctl boot …`) and install the dev build. When driving Maestro from an agent, `list_devices` → `inspect_screen` → `run` via the Maestro MCP, and inspect the hierarchy before writing a selector rather than guessing an id.

## Flakiness

Flows are device-dependent and will occasionally go red for reasons unrelated to the code. Handle it, do not delete the flow:

- Retry policy in `.maestro/config.yaml` rather than `retry:` wrapped around half a flow — a broad `retry:` masks real instability.
- A persistently flaky flow gets a `quarantine` tag and is excluded from the blocking CI run, with a linked ticket. It is not removed.

## Checklist

- [ ] All three categories exist: `_happy`, `_failure`, `_edge`
- [ ] `appId`, `name`, and category `tags` in the header
- [ ] Every flow starts from `common/start_home.yaml` — clean state **and** signed in
- [ ] Selectors use `id:` from `{feature}_keys.dart`, applied with `TestId` — a bare `Key` is invisible to Maestro
- [ ] `inspect_screen` shows a non-empty `rid` for every id the flow uses
- [ ] No `hideKeyboard` after a field that submits on done; no bare `eraseText`
- [ ] No sleeps; `extendedWaitUntil` with explicit timeouts
- [ ] Failure flow asserts the spinner stopped *and* that retry recovers
- [ ] Shared steps extracted to `.maestro/common/`
- [ ] Any new endpoint the flow hits has a mock branch in the interceptor
- [ ] Passes twice in a row locally before being pushed
