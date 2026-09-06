---
description: Regenerate the tool-specific agent instruction files from AGENTS.md
allowed-tools: Bash(./tool/sync_agents.sh:*), Bash(melos run sync-agents:*), Bash(git status:*), Bash(git diff:*)
---

`AGENTS.md` is the single source for agent instructions (ADR-0017). Everything else is generated.

Run:

```
./tool/sync_agents.sh
```

This regenerates:

- `CLAUDE.md` — `@AGENTS.md` import plus the Claude-only section (skills, commands)
- `GEMINI.md`
- `.github/copilot-instructions.md` — with root-relative links rewritten one level up
- `.cursor/rules/000-agents.mdc` — always-applied pointer rule

Then show `git diff --stat` for those files.

If any of them had been edited by hand, the diff will show the hand edit being reverted. When that happens, tell me what was lost so the change can be re-applied to `AGENTS.md` — the source — instead.

CI runs `./tool/sync_agents.sh --check`, which fails on drift.
