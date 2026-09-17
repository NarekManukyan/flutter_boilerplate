---
name: plan-feature
description: Turn a Jira ticket or written task into an approved implementation plan before any code is written. Reads every acceptance criterion, analyses the codebase, produces a file-level plan mapped to ADRs, playbooks and tests, then sizes the work and decides solo vs parallel execution. Use at the start of ANY feature, and whenever a task arrives as a ticket key, a link, or a paragraph of requirements.
---

# Plan a feature before building it

Governed by [ADR-0016](../../../docs/adr/0016-plan-first-delivery-workflow.md). Nothing is written to `lib/` until the plan is approved.

Concepts behind this playbook: [`architecture`](../../../docs/architecture.md), [`project-structure`](../../../docs/project-structure.md).

## Step 1 — Ingest the task in full

If a Jira key or URL is given, fetch the issue with the Atlassian MCP tools (`getJiraIssue`, then `getJiraIssueRemoteIssueLinks` for linked work). Read **all** of:

- description and **every** acceptance criterion
- comments — AC is frequently amended there and never moved into the description
- attachments and design links (Figma) — resolve them; a screen you have not seen is a screen you will get wrong
- linked issues, especially "blocks" / "is blocked by"
- the parent epic if one exists

If the task is prose rather than a ticket, treat the prose as the description and say explicitly that there are no formal AC.

**Never plan from the summary line alone.** If you fetched only the title, you have not done this step.

## Step 2 — Restate the AC as a checklist

Rewrite each criterion as one line with a *verifiable* outcome — something a test or a Maestro flow can assert.

```
AC1  Given a signed-in user on Home, tapping + opens the Add Todo modal.
AC2  Submitting a non-empty title creates the todo and it appears at the top of the list.
AC3  Submitting an empty title shows an inline error and does not call the API.
AC4  If POST /todos returns 5xx, the modal stays open and shows a retry-able error.
```

Anything you cannot phrase as a verifiable outcome is an **open question**, not a guess. Collect them:

```
OPEN  AC2 does not say whether the list re-sorts or the new item is prepended optimistically.
OPEN  No AC covers the offline case. Assume queue-and-retry, or fail fast?
OPEN  AC3 says a failed delete puts the row back. Must the user be told when it failed on a timeout?
```

Raise open questions with the user **now**. Do not encode a guess into the plan and discover it in review.

**When no human can answer** (a headless or CI run), do not decide silently. For each open question:

1. Write it into the plan under "Open questions", with the reading you chose.
2. Choose the most conservative reading of the AC: the one that hides nothing from the user and loses no data. For the timeout question above, that is: notify.
3. Flag it in the final report, so a human confirms or reverses it.

## Step 3 — Analyse the codebase

Read, do not assume. For each AC, find out:

- Which feature does this belong to? Does it exist under `lib/features/`? ([ADR-0005](../../../docs/adr/0005-flat-feature-tree.md) — features are peers, never nested.)
- Which store already holds this data? Is there a `*_store.dart` that owns it, or is a new one needed?
- Does the API endpoint exist in `packages/api/lib/src/providers/`? Does the DTO exist?
- Which routes are involved? Are they registered in `lib/core/navigation/`?
- Which design tokens and `LocaleKeys` already exist for these screens?
- What else reads the store/state you are about to change — the blast radius.

Prefer the `code-review-graph` MCP tools (`semantic_search_nodes`, `query_graph`, `get_impact_radius`) over grepping when the graph is populated for this repo.

## Step 4 — Write the plan

The plan is a file: `docs/plans/{TICKET}-{slug}.md` (for example `docs/plans/MONE-123-add-todo-from-home.md`). Without a ticket, use a short slug alone. It is committed with the feature, so review checks the code against it.

File-level, no prose padding. Every row names the governing ADR and the playbook that builds it.

```markdown
## Plan — MONE-123 Add todo from Home

### Contracts (land first)
| File | Action | Playbook | ADR |
|---|---|---|---|
| packages/api/.../models/src/todo_create_request_dto.dart | exists — reuse | — | 0011 |
| assets/translations/en-US.json | add addTodo_* keys | add-localization | 0012 |

### Implementation
| File | Action | Playbook | ADR |
|---|---|---|---|
| lib/features/home/modals/add_todo_modal/mobx/add_todo_modal_state.dart | modify — add validation | create-page | 0002, 0009 |
| lib/features/home/modals/add_todo_modal/use_cases/create_todo_use_case.dart | modify — surface error | create-use-case | 0003, 0004 |
| lib/features/home/mobx/home_store.dart | modify — prepend on success | create-store | 0002, 0006 |
| lib/features/home/view/home_keys.dart | create — widget keys for E2E | write-maestro-flow | 0015 |

### Proof — every AC line maps to a test
| AC | Proof |
|---|---|
| AC1 | `.maestro/flows/home/home_add_todo_happy.yaml` |
| AC2 | unit `add_todo_modal_state_test.dart` + happy flow |
| AC3 | unit `add_todo_modal_state_test.dart` — empty title, verify use case not called |
| AC4 | `.maestro/flows/home/home_add_todo_failure.yaml` + store unit test |

### Open questions
- … (headless run: the question, the conservative reading chosen, and "flagged in report")

### Out of scope
- …
```

The "Proof" table is not optional. An AC line with no proof row is an AC line you are not going to implement.

## Step 5 — Size it, and decide solo vs parallel

Count **independent surfaces**: distinct screens, stores, or API resources.

Ask the user how to run it **only when both hold**:

- **Large** — more than ~3 independent surfaces, or clearly beyond one working session.
- **Separable** — the pieces touch disjoint file sets and share only contracts that already exist or land first.

Two pieces that would both edit `home_store.dart` or both add routes to the same router are **not** separable — no matter how large.

When both hold, propose the split concretely:

```
Large (5 surfaces) and separable. Suggested split:
  contracts first (this session): DTOs, provider, routes, LocaleKeys
  flutter-team A: features/wallet/view      (wallet_page, wallet_page_state, widgets)
  flutter-team B: features/wallet/mobx      (wallet_store + use cases)
  flutter-team C: .maestro/flows/wallet     (happy / failure / edge)
Run as a team, or all in this session?
```

When either fails: **build it in this session and do not ask.** A "should we parallelize?" question on a two-file change is noise.

When the user chooses a team, name the agent for each slice:

- **Dart-only work:** one [`flutter-team`](../../agents/flutter-team.md) agent per slice.
- **Any slice that touches `ios/` or `android/`** (a platform channel, a permission that needs the manifest and `Info.plist`, background modes, push notifications, deep links): [`mobile-orchestrator`](../../agents/mobile-orchestrator.md). It agrees the channel contract first, then runs `flutter-team`, `ios-team` and `android-team` in parallel. Treat that contract like any other shared contract: it lands before the slices start.

Claude Code agent teams, where teammates message each other and share a task list, need `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`. This repo sets it in [`.claude/settings.json`](../../settings.json). Teammates are only spawned in an interactive session. Without the variable, or in a non-interactive run such as `claude -p`, the same agents run as ordinary subagents, which is fine for disjoint slices. Other tools can read the agent files in `.claude/agents/` as plain briefs.

## Step 6 — Approval, then build

Present the plan and wait for approval. In a headless or CI run where the task itself states the plan is pre-approved, write the plan file, record open questions as described above, and proceed without waiting. On approval, work through it in order — contracts first, then implementation, then tests. Open each playbook named in the plan before you build that row.

If reality contradicts the plan mid-build, say so and amend the plan file. Do not silently diverge; the plan is what review will be checked against.

## Step 7 — Exit through the QA gate

Run [`qa-feature`](../qa-feature/SKILL.md). Every AC line must map to a passing test or flow, and happy / failure / edge flows must all exist ([ADR-0015](../../../docs/adr/0015-mandatory-test-coverage-and-qa-gate.md)).

## Anti-patterns

- Planning from the ticket title. The AC are in the description and the comments.
- Guessing an ambiguous AC instead of asking. The guess becomes the spec.
- In a headless run, deciding an open question without writing it into the plan and the final report.
- A plan that lives only in the chat. It goes in `docs/plans/` and is committed with the feature.
- A plan with no "Proof" column — it is a wish list, not a plan.
- Asking about parallel agents on small work, or splitting work that shares a store.
- Starting parallel agents before the shared contracts (DTOs, routes, tokens, platform-channel contracts) have landed.
