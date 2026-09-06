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

## Select by `Key`, never by copy

Flutter exports a widget's `Key` as its accessibility identifier, which Maestro matches with `id:`. Text is localized and will change; keys are a contract ([ADR-0012](../../../docs/adr/0012-mandatory-localization.md)).

```yaml
- tapOn:
    id: "home_add_todo_fab"        # HomeKeys.addTodoFab
- assertVisible:
    id: "home_todo_list"
```

Keys live in the feature's `{feature}_keys.dart` ([`create-page`](../create-page/SKILL.md)). If a flow needs a key that does not exist, add it to that file — do not fall back to matching on text.

## Skeleton

```yaml
# .maestro/flows/home/home_add_todo_happy.yaml
appId: com.example.flutterBoilerplate
name: "Home — add a todo (happy)"
tags:
  - happy
  - home
---
- runFlow: ../../common/launch.yaml

- assertVisible:
    id: "home_todo_list"

- tapOn:
    id: "home_add_todo_fab"
    label: "Open the add-todo modal"

- tapOn:
    id: "add_todo_title_field"
- inputText: "Buy milk"
- hideKeyboard

- tapOn:
    id: "add_todo_submit"

- extendedWaitUntil:
    visible:
      text: "Buy milk"
    timeout: 5000

- assertVisible:
    id: "home_todo_list"
```

`common/launch.yaml`:

```yaml
appId: com.example.flutterBoilerplate
---
- launchApp:
    clearState: true
    clearKeychain: true
    permissions:
      notifications: allow
      all: unset
```

`clearState: true` on every flow. A flow that depends on the previous flow's state is a flow that passes locally and fails in CI.

## Waiting

- **Never `sleep`.** There is no sleep command, and coercing one with `repeat` hides real latency bugs.
- `extendedWaitUntil` with an explicit `timeout` for anything that waits on the network.
- `waitForAnimationToEnd` after a transition or a modal open.
- `assertVisible` already retries briefly; use `extendedWaitUntil` only when the wait is genuinely long.

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
maestro test .maestro/flows/home/home_add_todo_happy.yaml
maestro test .maestro/flows --include-tags happy
melos run maestro                       # whole suite, needs a booted device
maestro studio                          # interactive selector inspector
```

Boot a simulator first (`xcrun simctl boot …`) and install the dev build. When driving Maestro from an agent, `list_devices` → `inspect_screen` → `run` via the Maestro MCP, and inspect the hierarchy before writing a selector rather than guessing an id.

## Flakiness

Flows are device-dependent and will occasionally go red for reasons unrelated to the code. Handle it, do not delete the flow:

- Retry policy in `.maestro/config.yaml` rather than `retry:` wrapped around half a flow — a broad `retry:` masks real instability.
- A persistently flaky flow gets a `quarantine` tag and is excluded from the blocking CI run, with a linked ticket. It is not removed.

## Checklist

- [ ] All three categories exist: `_happy`, `_failure`, `_edge`
- [ ] `appId`, `name`, and category `tags` in the header
- [ ] Every flow starts from `clearState: true`
- [ ] Selectors use `id:` from `{feature}_keys.dart`, not localized text
- [ ] No sleeps; `extendedWaitUntil` with explicit timeouts
- [ ] Failure flow asserts the spinner stopped *and* that retry recovers
- [ ] Shared steps extracted to `.maestro/common/`
- [ ] Any new endpoint the flow hits has a mock branch in the interceptor
- [ ] Passes twice in a row locally before being pushed
