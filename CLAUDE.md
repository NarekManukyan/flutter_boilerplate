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
  - `/review-pr <PR URL | number>` — three-reviewer PR review with round handling, an overview and a fix prompt.
  - `/review-codequality`, `/review-functional-logic`, `/review-security-performance`, `/review-context-maintenance` — focused review passes.
  - `/context-prime`, `/sync-openapi`.
- **Agents** in `.claude/agents/`: `flutter-team`, `ios-team`, `android-team`, `mobile-orchestrator`. Agent teams are enabled through `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in `.claude/settings.json`.
- **Hooks** (`.claude/settings.json`): after each edit, `track_change.sh` records the file. When you finish a turn, `post_turn.sh` runs only the codegen those edits need, then `dart fix` and `dart format` on the edited files and `dart analyze`. It is silent when clean and blocks your stop with the errors when something fails — fix them. Needs `jq`. Edits inside `.claude/worktrees/` are not checked; run `melos run verify:quick` there.
- **Editing rules:** change `AGENTS.md`, never this file — it is overwritten by `melos run sync-agents`.
