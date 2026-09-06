---
description: Run the QA gate over a feature — AC traceability plus the happy / failure / edge matrix
argument-hint: <feature name | JIRA-KEY | path under lib/features>
---

Run the QA gate on: **$ARGUMENTS**

Invoke the `qa-feature` skill and follow it fully. In short:

1. **AC traceability** — fetch the ticket if a Jira key was given; otherwise derive the AC from the feature's plan or its tests. Build the table mapping every acceptance criterion to a *specific file* that proves it. "Manually verified" is not a proof.
2. **The three categories** — walk happy, failure and edge. Check the Maestro trio exists in `.maestro/flows/{feature}/` and that the failure flow asserts the spinner stopped *and* that retry recovers.
3. **Cross-cutting** — states (loading/error/empty/content), navigation, accessibility (semantics labels, 44pt targets, 200% text), theming (light **and** dark, WCAG AA both), localization (no literals, no missing keys), architecture (layer rules, no `getIt` inside classes, no hand-edited generated files).
4. **Run it**:
   ```
   melos run verify
   melos run maestro
   ```
   Boot a simulator first if none is running. Use the Maestro MCP (`list_devices` → `run`) when driving flows from here.
5. **Report** — gate PASS/FAIL, the AC→proof table, findings ranked P1/P2/P3, and an explicit "not covered" list with reasons.

Be honest about the verdict. Do not mark the gate passed with an AC row that has no automated proof; list it as an open item instead.
