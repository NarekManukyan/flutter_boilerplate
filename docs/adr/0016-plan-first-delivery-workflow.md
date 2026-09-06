# 16. Plan-First Delivery Workflow

- Status: Accepted
- Date: 2026-09-06
- Deciders: Flutter team

## Context and Problem Statement

Agents start writing code roughly one second after reading a task title. The expensive failures in this repo are not bad Dart — the linter and the ADRs catch that. They are *building the wrong thing*: a screen that satisfies the ticket summary but misses three acceptance criteria buried in the Jira description, or a feature built as one 900-line page state when the ticket described four independent screens that three people could have built in parallel.

Both failures are decided before the first line of code. Once an agent has produced a large diff, nobody re-reads the AC to check it — the diff becomes the spec.

There is a second, subtler problem. Splitting work across parallel agents is genuinely valuable on large tickets and pure overhead on small ones. Left to its own judgment mid-task, an agent either never parallelizes or shards a two-file change into five sessions that then conflict.

## Decision Drivers

- Acceptance criteria are the contract — they must be read and restated before code, not after review.
- Cheap correction — a wrong plan costs a paragraph to fix; a wrong 900-line diff costs a day.
- Explicit human checkpoint — the one moment worth interrupting a human for is *before* the build, not during.
- Parallelism must be a deliberate, sized decision, not an unconscious default in either direction.
- The workflow must produce an artifact a reviewer can diff the implementation against.

## Considered Options

- **Mandatory plan gate** — read AC → analyze → written plan → human approval → build.
- **Build then reconcile** — implement, then check the result against the AC in review.
- **Plan only for large tickets** — a size heuristic decides whether a plan is required.

## Decision Outcome

Chosen option: **Mandatory plan gate before any feature work**.

### The loop

1. **Ingest the task.** Fetch the Jira issue (or the written task). Read the description, every acceptance criterion, the comments, attachments, and linked issues — not just the summary.
2. **Restate the AC as a checklist.** Each criterion becomes one line with a verifiable outcome. Ambiguous or missing criteria are listed as open questions; they are raised, not guessed.
3. **Analyze against the codebase.** Which features, stores, DTOs, routes, and design tokens already exist? What is reused, what is new, what is the blast radius? This step reads code — it does not assume.
4. **Write the plan.** File-level: what is created, what is modified, which ADR governs each piece, which playbook builds it, and the test + Maestro flows that will prove each AC line.
5. **Size it and decide the execution shape** (below).
6. **Get approval**, then build. The plan is the spec; deviations are stated, not silent.
7. **Exit through the QA gate** — [ADR-0015](0015-mandatory-test-coverage-and-qa-gate.md). Every AC line maps to at least one test or flow.

### Solo vs team — a sizing decision, asked only when it is real

After the plan exists, the work is sized. The question of splitting across parallel agents is asked **only when the work is both large and genuinely separable**:

- **Large** — more than roughly 3 independent surfaces (screens / stores / API resources), or an estimate beyond a single working session.
- **Separable** — the pieces touch disjoint file sets and share only already-existing contracts (DTOs, routes, tokens). If two pieces would edit the same store or the same route table, they are not separable.

If both hold, the user is asked how to run it, with a proposed split naming each agent's files and the shared contracts that must land first. If either fails, the work runs in one session and **the question is not asked** — a needless "should we parallelize?" on a two-file change is noise.

Contract-first ordering is non-negotiable when splitting: DTOs, API providers, routes, and design tokens land before the parallel agents start, so no two agents generate the same file.

### Consequences

- Good: acceptance criteria are read before code exists, when correcting course is cheap.
- Good: the plan is a durable artifact — review compares implementation to plan, not to intent.
- Good: parallelism becomes an explicit, sized choice with a stated split.
- Good: open questions surface at the start of the ticket instead of at review time.
- Bad: adds a round trip before any code exists; trivial tickets pay a plan they did not need.
- Bad: the plan can go stale mid-build and must be updated rather than abandoned.
- Bad: depends on Jira AC actually being written; a ticket with an empty description produces a plan that is mostly open questions — which is the correct outcome, but it blocks.

## Pros and Cons of the Options

### Mandatory plan gate
- Good: catches misread requirements at the cheapest possible moment.
- Good: gives review an explicit spec to check against.
- Bad: ceremony on small tickets.

### Build then reconcile
- Good: fastest path to a running screen.
- Bad: the diff becomes the spec — nobody re-reads AC against a large diff.
- Bad: rework is a rewrite, not an edit.

### Plan only for large tickets
- Good: no ceremony on small work.
- Bad: the size estimate is itself made before the analysis that would make it accurate; small-looking tickets with buried AC are exactly the ones that go wrong.
- Bad: creates an argument about the threshold on every ticket.

## Links

- [ADR-0015 Mandatory test coverage and QA gate](0015-mandatory-test-coverage-and-qa-gate.md) — the exit criterion
- [ADR-0017 Single-source agent instructions](0017-single-source-agent-instructions.md) — where the workflow is published to agents
- Playbook: [`plan-feature`](../../.claude/skills/plan-feature/SKILL.md), command: [`/build-feature`](../../.claude/commands/build-feature.md)
