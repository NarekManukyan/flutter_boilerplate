---
name: plan-feature
description: Turn a Jira ticket or written task into an approved implementation plan before any code is written. Reads every acceptance criterion, analyses the codebase, produces a file-level plan mapped to ADRs, playbooks and tests, then sizes the work and decides solo vs parallel execution. Use at the start of ANY feature, and whenever a task arrives as a ticket key, a link, or a paragraph of requirements.
---

# Plan a feature before building it

Governed by [ADR-0016](../../../docs/adr/0016-plan-first-delivery-workflow.md). Nothing is written to `lib/` until the plan is approved.

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
```

Raise open questions with the user **now**. Do not encode a guess into the plan and discover it in review.

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
- …

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
  agent A: features/wallet/view      (wallet_page, wallet_page_state, widgets)
  agent B: features/wallet/mobx      (wallet_store + use cases)
  agent C: .maestro/flows/wallet     (happy / failure / edge)
Run as a team, or all in this session?
```

When either fails: **build it in this session and do not ask.** A "should we parallelize?" question on a two-file change is noise.

## Step 6 — Approval, then build

Present the plan. On approval, work through it in order — contracts first, then implementation, then tests. Open each playbook named in the plan before you build that row.

If reality contradicts the plan mid-build, say so and amend the plan. Do not silently diverge; the plan is what review will be checked against.

## Step 7 — Exit through the QA gate

Run [`qa-feature`](../qa-feature/SKILL.md). Every AC line must map to a passing test or flow, and happy / failure / edge flows must all exist ([ADR-0015](../../../docs/adr/0015-mandatory-test-coverage-and-qa-gate.md)).

## Anti-patterns

- Planning from the ticket title. The AC are in the description and the comments.
- Guessing an ambiguous AC instead of asking. The guess becomes the spec.
- A plan with no "Proof" column — it is a wish list, not a plan.
- Asking about parallel agents on small work, or splitting work that shares a store.
- Starting parallel agents before the shared contracts (DTOs, routes, tokens) have landed.
