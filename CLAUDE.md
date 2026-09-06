# CLAUDE.md

<!-- GENERATED FILE — DO NOT EDIT. Source: AGENTS.md. Regenerate: melos run sync-agents -->

@AGENTS.md

## Claude Code specifics

The rules above are the whole contract — this section only covers Claude-only wiring.

- **Playbooks are skills.** Every file under `.claude/skills/{name}/SKILL.md` is an invocable skill. Invoke the one that matches the artifact you are about to build; the index is in the AGENTS.md "Playbooks" table.
- **Commands** in `.claude/commands/`:
  - `/build-feature <JIRA-KEY | description>` — the full delivery loop of ADR-0016: read AC, analyze, plan, size, build, QA.
  - `/qa-feature <feature>` — QA pass over a finished feature: happy / failure / edge.
  - `/sync-agents` — regenerate the generated instruction files after editing AGENTS.md.
  - `/review-pr`, `/review-codequality`, `/review-functional-logic`, `/review-security-performance`, `/review-context-maintenance` — review panels.
  - `/context-prime`, `/sync-openapi`.
- **Editing rules:** change `AGENTS.md`, never this file — it is overwritten by `melos run sync-agents`.
