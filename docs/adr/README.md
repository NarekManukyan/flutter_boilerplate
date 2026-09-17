# Architecture Decision Records

ADRs codify the **why** behind architectural rules in this repo. [`AGENTS.md`](../../AGENTS.md) carries the one-line form of each rule (always loaded by every agent); the [playbooks](../../.claude/skills/) carry the step-by-step how-to (loaded on demand). This directory is the source of truth for decisions that had real alternatives.

Format: [MADR 3.0](https://adr.github.io/madr/), with metadata as bullets under the title (`Status`, `Date`, `Deciders`, plus optional `Consulted` and `Informed`). New ADRs state how the decision is confirmed (a **Confirmation** section) and may carry an **AI Implementation Guidelines** section with an `<ai_context_rules>` block for coding agents. See [`0000-template.md`](0000-template.md).

## Status values

| Status | Meaning |
|---|---|
| `Proposed` | Under discussion. Not enforced yet. |
| `Accepted` | Describes how the codebase works now. This is the normal status here. |
| `Rejected` | Considered and turned down. Kept so the same discussion is not repeated. |
| `Deprecated` | No longer applies, and nothing replaced it. |
| `Superseded by ADR-NNNN` | Replaced by a later ADR, which links back to this one. |

## Index

| # | Title | Status |
|---|---|---|
| [0001](0001-layered-architecture.md) | Layered architecture with adjacent-only access | Accepted |
| [0002](0002-state-vs-store-separation.md) | State vs Store separation | Accepted |
| [0003](0003-no-use-case-to-use-case-dependencies.md) | Use cases never depend on other use cases | Accepted |
| [0004](0004-use-case-taxonomy-and-colocation.md) | Use case taxonomy and colocation by consumer | Accepted |
| [0005](0005-flat-feature-tree.md) | Flat feature tree (no nested `features/`) | Accepted |
| [0006](0006-feature-owned-singletons.md) | Feature-owned singletons (no `lib/shared/`) | Accepted |
| [0007](0007-di-scopes-and-constructor-injection.md) | DI scopes and constructor injection | Accepted |
| [0008](0008-appnavigator-routing-abstraction.md) | `AppNavigator` routing abstraction | Accepted |
| [0009](0009-provider-based-state-access.md) | Provider-based state access in widgets | Accepted |
| [0010](0010-hookwidget-default.md) | `HookWidget` as the default stateful widget | Accepted |
| [0011](0011-retrofit-typed-api-layer.md) | Retrofit + freezed typed API layer | Accepted |
| [0012](0012-mandatory-localization.md) | Mandatory localization (no hardcoded UI strings) | Accepted |
| [0013](0013-design-system-tokens-only.md) | Design-system tokens only in `lib/` | Accepted |
| [0014](0014-melos-package-split.md) | Melos package split: `api` and `design_system` | Accepted |
| [0015](0015-mandatory-test-coverage-and-qa-gate.md) | Mandatory test coverage and QA gate | Accepted |
| [0016](0016-plan-first-delivery-workflow.md) | Plan-first delivery workflow | Accepted |
| [0017](0017-single-source-agent-instructions.md) | Single-source agent instructions (`AGENTS.md` + playbooks) | Accepted |
| [0018](0018-widget-construction-discipline.md) | Widget construction discipline: no widget-returning methods, no `BuildContext` parameters | Accepted |
| [0019](0019-hook-selection.md) | Hook selection: `useValueNotifier` over `useState`, `useMemoized` whenever it applies | Accepted |
| [0020](0020-error-handling-and-issue-tracking.md) | Error handling: every caught error is tracked through `IssueTrackingService` | Accepted |

## Adding a new ADR

1. Copy `0000-template.md` to `NNNN-kebab-slug.md`, using the next free number.
2. Fill in the MADR fields. List at least 2 alternatives with concrete trade-offs. Fill in **Confirmation** with the lint rule, CI check, review checklist item or test that upholds the decision. Fill in **AI Implementation Guidelines** when agents need explicit constraints; otherwise delete that section, and delete `Consulted` / `Informed` if unused.
3. Add a row above.
4. If superseding an existing ADR, set its status to `Superseded by ADR-NNNN` (in the ADR and in its index row), and link the two ADRs both ways.
5. If the decision changes a rule referenced from `AGENTS.md`, update the `AGENTS.md` "Architectural decisions" table, then run `melos run sync-agents`.
6. If the decision adds a procedure, add or update the matching playbook under `.claude/skills/`.
