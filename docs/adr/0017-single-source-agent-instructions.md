# 17. Single-Source Agent Instructions (`AGENTS.md` + On-Demand Playbooks)

- Status: Accepted
- Date: 2026-09-06
- Deciders: Flutter team

## Context and Problem Statement

Two problems, one cause.

**Context cost.** `CLAUDE.md` had grown to 439 lines / ~20 KB and is injected into every session, every turn. Most of it is procedural how-to — the Retrofit provider pattern, use-case placement rules, the DI annotation table, the design-token addition steps. A session that renames a string constant pays for the DTO authoring guide. Rules that are *always* present are also rules the model skims; the ones that matter for the current task get no more attention than the ones that do not.

**Tool lock-in.** The same rules were duplicated across `CLAUDE.md`, `.cursor/rules/*.mdc`, and nothing at all for Codex, Copilot, Gemini, or Zed. Each copy drifted. A developer who switched editors got a different set of architectural rules, and updating a rule meant remembering three places.

## Decision Drivers

- The same rules must govern every agent, regardless of tool.
- Always-loaded context should be small and consist only of rules that apply to *every* change.
- Procedural how-to should load when the task needs it, and cost nothing when it does not.
- One editable source; derived files must be obviously derived and drift-checkable in CI.
- Tool-agnostic in substance — the how-to material must be plain Markdown any agent can read, not a Claude-only artifact.

## Considered Options

- **`AGENTS.md` as source + generated tool adapters + on-demand playbooks.**
- **Keep `CLAUDE.md` canonical, symlink other tools to it.**
- **Duplicate per tool, sync by hand.**
- **Everything in always-loaded context** (status quo).

## Decision Outcome

Chosen option: **`AGENTS.md` is the single source; tool-specific files are generated; procedural content moves to on-demand playbooks.**

### Layer 1 — `AGENTS.md`, always loaded, short

Contains only what applies to *every* change: project overview, commands, the layer table, naming patterns, file boundaries, the one-line form of each hard rule with a link to its ADR, the delivery workflow, and an index of the playbooks. Target: under 200 lines. If a section only matters when you are doing a specific kind of work, it does not belong here.

`AGENTS.md` is the emerging cross-tool convention — read natively by Codex, Cursor, Zed, Amp, Jules, and others — which is why it is the source rather than `CLAUDE.md`.

### Layer 2 — playbooks, loaded on demand

Each procedural guide lives at `.claude/skills/{name}/SKILL.md` as plain Markdown with a YAML frontmatter header (`name`, `description`). Claude Code registers these as invocable skills automatically. Every other agent reads them as ordinary files — `AGENTS.md` carries the index table with paths, so an agent about to write a DTO is told to open `create-dto` first.

The frontmatter is additive: it makes the file work as a Claude skill without making it unreadable to anything else. One file, two consumers.

### Layer 3 — ADRs, read for *why*

Unchanged. `docs/adr/` remains the source of truth for decisions with real alternatives. Playbooks say *how*, ADRs say *why*, `AGENTS.md` says *what, in one line*.

### Generated tool adapters

`tool/sync_agents.sh` regenerates from `AGENTS.md`:

| File | Tool | Form |
|---|---|---|
| `CLAUDE.md` | Claude Code | `@AGENTS.md` import + Claude-only section (skills, commands, hooks) |
| `.github/copilot-instructions.md` | GitHub Copilot | generated copy |
| `GEMINI.md` | Gemini CLI | generated copy |
| `.cursor/rules/000-agents.mdc` | Cursor | `alwaysApply` rule pointing at `AGENTS.md` |
| — | Codex, Zed, Amp, Jules | read `AGENTS.md` natively; nothing to generate |

Generated files carry a `DO NOT EDIT` header. `sync_agents.sh --check` fails on drift and runs in CI, so an edit to a generated copy is caught rather than silently overwritten.

Copies rather than symlinks: symlinks survive Git but break on Windows checkouts without developer mode, and several tools resolve their instruction file before following links.

### Consequences

- Good: always-loaded context drops from ~20 KB to under ~8 KB; the rules that remain are the ones that always apply.
- Good: a rule is edited in exactly one place, and CI proves the copies match.
- Good: developers on Codex, Cursor, Copilot, or Gemini get the same architecture rules as Claude users.
- Good: playbooks are versioned with the code they describe and reviewed in the same PR.
- Bad: one more generated-artifact class to keep in sync; a forgotten `melos run sync-agents` fails CI.
- Bad: an agent that ignores the playbook index will build from the one-line rule alone and produce shallower work than the old always-loaded guide did.
- Bad: `.cursor/rules/*.mdc` still holds substantial independent material (Firebase, mocktail, effective_dart) that is not yet folded into playbooks.

## Pros and Cons of the Options

### `AGENTS.md` source + generated adapters + playbooks
- Good: one source, cross-tool, small always-on footprint.
- Bad: generation step and CI drift check to maintain.

### `CLAUDE.md` canonical, symlink the rest
- Good: no generator.
- Bad: names the whole convention after one vendor; other tools' native file is `AGENTS.md`, so every non-Claude tool needs a link anyway.
- Bad: symlinks break on Windows checkouts and some tools do not follow them.

### Duplicate per tool, sync by hand
- Good: zero tooling.
- Bad: this is the status quo that drifted; it does not survive contact with a busy sprint.

### Everything always loaded
- Good: nothing to look up; the rule is present whether or not the agent thinks to fetch it.
- Bad: pays full context cost on every turn regardless of task.
- Bad: dilutes attention — the rules that matter now are buried among the ones that do not.

## Links

- [ADR-0016 Plan-first delivery workflow](0016-plan-first-delivery-workflow.md) — the workflow published through `AGENTS.md`
- [ADR-0015 Mandatory test coverage and QA gate](0015-mandatory-test-coverage-and-qa-gate.md)
- Source: [`AGENTS.md`](../../AGENTS.md), generator: [`tool/sync_agents.sh`](../../tool/sync_agents.sh)
- `AGENTS.md` convention: https://agents.md
