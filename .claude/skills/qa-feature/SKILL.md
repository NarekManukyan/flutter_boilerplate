---
name: qa-feature
description: Run the QA gate on a finished feature before it can be called done — map every acceptance criterion to a passing test or flow, then walk the happy, failure and edge matrix covering states, input, network, navigation, accessibility, theming and localization. Use at the end of every feature, before opening a PR, and when reviewing someone else's.
---

# QA gate

Governed by [ADR-0015](../../../docs/adr/0015-mandatory-test-coverage-and-qa-gate.md). This is the exit criterion of the delivery loop ([ADR-0016](../../../docs/adr/0016-plan-first-delivery-workflow.md)). A feature that has not passed this gate is not done, regardless of how complete the diff looks.

## Step 1 — AC traceability

Take the AC checklist from the plan. Every line gets a row, and every row names a **specific file** that proves it.

| AC | Proof | Status |
|---|---|---|
| AC1 tapping + opens the modal | `.maestro/flows/home/home_add_todo_happy.yaml` | ✅ passing |
| AC2 non-empty title creates the todo | `home_store_test.dart` + happy flow | ✅ passing |
| AC3 empty title shows inline error | `add_todo_modal_state_test.dart` | ✅ passing |
| AC4 5xx keeps modal open with retry | `home_add_todo_failure.yaml` | ❌ missing |

"Manually verified" is not a proof. An AC with no automated proof is an open item; list it and say so plainly rather than marking the gate passed.

## Step 2 — the three categories

### Happy

- [ ] The primary journey completes end to end on a device.
- [ ] The success state is visibly distinct — the user can tell it worked.
- [ ] Data persists across a kill-and-relaunch where the AC implies it should.

### Failure

- [ ] **Server 5xx** → recoverable error surface, spinner stopped, retry actually re-runs the request.
- [ ] **Server 4xx** (validation, conflict) → the specific message, not the generic one.
- [ ] **Expired / missing auth** → refresh or redirect to login; never an infinite retry loop.
- [ ] **Network dropped mid-request** → no crash, no permanent spinner, clear recovery.
- [ ] **Timeout** → the 32s Dio timeout is handled, not left to hang.
- [ ] No raw `DioException`, stack trace, or English-only fallback string reaches the user.

### Edge

- [ ] **Empty** — zero results renders the empty state, distinct from loading and from error.
- [ ] **One item** — no layout assumption that breaks below two.
- [ ] **Many items** — long list scrolls; pagination loads; no jank on a mid-range device.
- [ ] **Max-length input** — long strings truncate or wrap; no overflow.
- [ ] **Special characters and emoji** in every text field.
- [ ] **Rapid double-tap** on the primary action creates one record, not two.
- [ ] **Backgrounding mid-request** — resumes or fails cleanly.
- [ ] **Offline at launch** — the connection wrapper handles it; no white screen.
- [ ] **Slow network** — the loading state is reachable and readable, not a 50 ms flash.

## Step 3 — cross-cutting checks

### States

- [ ] Loading, error, empty and content all implemented, each with its own key.
- [ ] Loading uses `skeletonizer`, not a bare centred spinner on first load.
- [ ] No state can be reached where the user has no action available.

### Navigation

- [ ] Back from every screen lands somewhere sensible; no dead end.
- [ ] Deep link into the feature works from a cold start.
- [ ] No `context.router` anywhere ([ADR-0008](../../../docs/adr/0008-appnavigator-routing-abstraction.md)).

### Accessibility

- [ ] Every interactive widget has a `Semantics` label sourced from `LocaleKeys`.
- [ ] Touch targets ≥ 44×44 pt.
- [ ] Screen reader can traverse the screen in a sensible order.
- [ ] Text scales to 200% without clipping or overlap.
- [ ] Colour is never the sole carrier of meaning.

### Theming

- [ ] Light **and** dark both correct — the feature was actually opened in dark mode.
- [ ] Every foreground/background pair meets WCAG AA in both.
- [ ] No raw colour, `TextStyle` composite, radius, duration or `BoxShadow` stack in `lib/` ([ADR-0013](../../../docs/adr/0013-design-system-tokens-only.md)).

### Localization

- [ ] No literal user-visible string anywhere, including errors and semantics labels.
- [ ] Every locale file carries the same key tree — no raw key paths rendering.
- [ ] Long translations do not overflow their container.

### Architecture

- [ ] State has no `DioService`; page has no store; no use case injects another use case.
- [ ] Stores live under their owning feature's `mobx/`; nothing added to `lib/shared/`.
- [ ] No `getIt<>()` inside a class except `Provider(create:)`.
- [ ] No generated file edited by hand.

## Step 4 — run everything

```bash
melos run verify        # lint + analyze + format + test
melos run maestro       # all flows, on a booted device
```

Both green, and the AC table has a proof for every row. Anything red or missing is reported as a finding, not waved through.

## Step 5 — report

```markdown
## QA — MONE-123

**Gate: PASS / FAIL**

AC coverage: 4/4 with automated proof
Flows: happy ✅  failure ✅  edge ✅
verify: pass    maestro: 3/3 pass

### Findings
- P1 …
- P2 …

### Not covered
- …  (with the reason, and a ticket if it is deliberate)
```

Be honest about the gate. A FAIL with three specific findings is far more useful than a PASS that quietly omitted the failure flow.

## Anti-patterns

- Marking the gate passed with "manually tested" as the proof column.
- Testing only the happy path and calling the feature done.
- Treating dark mode and accessibility as follow-up tickets — they are part of this feature.
- Writing an edge flow that only re-tests the happy path with different data.
