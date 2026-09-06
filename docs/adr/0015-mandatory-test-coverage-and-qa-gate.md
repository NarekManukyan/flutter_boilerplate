# 15. Mandatory Test Coverage and QA Gate

- Status: Accepted
- Date: 2026-09-06
- Deciders: Flutter team

## Context and Problem Statement

The repo has an architecture that is unusually easy to test — every layer has a mockable seam (State fakes Stores, Store fakes `DioService`, use cases fake services) — and yet ships with no `test/` directory, no `integration_test/`, and no end-to-end coverage. `melos run test` runs `dart test`, which cannot execute Flutter widget tests at all. In practice "tested" has meant "the author ran the app once on the happy path".

Two failure modes follow. First, regressions land silently: a change to `AuthStore` breaks the splash redirect and nobody notices until QA opens the app. Second, agent-written code has no objective pass/fail signal — an agent can produce plausible code, satisfy every architectural rule, and still ship a screen that crashes on an empty list.

We need a definition of done that a machine can check, covering the three things that actually break: unit logic, widget wiring, and the real user journey on a real device.

## Decision Drivers

- Machine-checkable done — an agent must be able to prove a feature works, not assert it.
- Layer-appropriate cost — widget-pumping every branch is slow; pure logic should be tested where it is cheap.
- Real-device truth — routing, DI bootstrap, localization loading, and platform channels only break on a device.
- Non-happy paths — most production incidents are the error and empty branches, which are exactly what manual testing skips.
- Reviewability — a reviewer should be able to open one directory and see what the feature promises.

## Considered Options

- **Three-tier mandatory coverage** — unit tests for logic, widget tests for wiring, Maestro flows for the journey; QA reviews happy / failure / edge for every feature.
- **Unit tests only** — test stores and use cases, treat UI as unverifiable.
- **`integration_test` (Flutter driver) instead of Maestro** — stay inside Dart for E2E.
- **No mandate, coverage threshold in CI** — set a global line-coverage gate and let developers choose what to test.

## Decision Outcome

Chosen option: **Three-tier mandatory coverage with an explicit QA gate**.

### The three tiers

| Tier | Location | Covers | Seam faked |
|---|---|---|---|
| Unit | `test/features/{feature}/` | Stores, states, use cases, services, extensions | `DioService`, services, `AppNavigator` |
| Widget | `test/features/{feature}/view/` | Page renders each state; widgets emit correct callbacks | State class (real object, fake collaborators) |
| E2E (Maestro) | `.maestro/flows/{feature}/` | The user journey on a booted device against the mock interceptor | Network via `MockTodosInterceptor` / flavor mocks |

A feature is not done until all three exist. "All three" means at least one flow per tier, not exhaustive permutation.

### The QA gate — happy / failure / edge

Every feature ships Maestro flows for three named categories. This is the QA contract, and it is what the `qa-feature` playbook checks:

- **Happy** — the intended path completes and the user sees the success state.
- **Failure** — the server errors (5xx), auth expires, or the network drops; the app shows a recoverable error and does not crash or hang on a spinner.
- **Edge** — empty list, single item, maximum-length input, offline start, backgrounding mid-request, rapid double-tap on the primary action.

Flow files are named `{feature}_{category}.yaml` (e.g. `todo_create_failure.yaml`) so the category is visible in a directory listing and selectable by Maestro tag.

### Widget keys are part of the feature

Maestro selects by accessibility identifier. Every widget an E2E flow drives carries a stable `Key`, and every interactive widget carries a `Semantics` label sourced from `LocaleKeys` ([ADR-0012](0012-mandatory-localization.md)). Keys live in a per-feature `{feature}_keys.dart` constants file so the flow and the widget cannot drift apart silently.

### Consequences

- Good: a feature has an executable definition of done that an agent or CI can evaluate.
- Good: the failure and edge categories force the error branches to be designed, not discovered.
- Good: widget keys plus semantics labels make the app measurably more accessible as a side effect.
- Good: unit tests stay fast because widget tests are limited to wiring, not logic.
- Bad: feature cost rises — roughly 30–40% more work per feature up front.
- Bad: Maestro is an external toolchain (JVM + CLI) that every developer and CI runner must install.
- Bad: flows are device-dependent and will flake; they need retry policy and a quarantine tag rather than being deleted on first red.

## Pros and Cons of the Options

### Three-tier mandatory coverage
- Good: each tier tests what it is cheapest to test at that level.
- Good: E2E on a real device catches DI, routing, and localization bootstrap failures that no widget test sees.
- Bad: three toolchains to keep green.

### Unit tests only
- Good: fastest to write and run; no device needed.
- Bad: the layer that actually breaks for users — the screen — stays unverified.
- Bad: gives false confidence; a fully green unit suite is compatible with a black screen on launch.

### `integration_test` instead of Maestro
- Good: one language, runs via `flutter test integration_test`, no extra toolchain.
- Bad: flows are Dart code that must be compiled with the app, so QA cannot read or write them.
- Bad: weaker at cross-app steps (system permission dialogs, deep links, backgrounding) which is exactly where the edge cases live.
- Bad: couples E2E to the app's own widget tree, so a refactor breaks the test for reasons unrelated to behavior.

### Coverage threshold, no mandate
- Good: zero process; the number goes up over time.
- Bad: line coverage rewards testing getters and punishes nothing; the error branches stay uncovered because they are hard, not because they are unimportant.
- Bad: gives an agent no instruction about *what* to test.

## Links

- [ADR-0016 Plan-first delivery workflow](0016-plan-first-delivery-workflow.md) — the QA gate is the exit criterion of the delivery loop
- [ADR-0012 Mandatory localization](0012-mandatory-localization.md) — semantics labels come from `LocaleKeys`
- [ADR-0001 Layered architecture](0001-layered-architecture.md) — the layer seams the unit tier fakes
- Playbooks: [`write-tests`](../../.claude/skills/write-tests/SKILL.md), [`write-maestro-flow`](../../.claude/skills/write-maestro-flow/SKILL.md), [`qa-feature`](../../.claude/skills/qa-feature/SKILL.md)
- Maestro docs: https://docs.maestro.dev
