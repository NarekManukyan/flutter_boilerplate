Read `AGENTS.md` first — it is the single source of truth for this repo's architecture rules, delivery workflow, naming, file boundaries and testing contract.

Then:

1. Run `git ls-files` to see the file layout.
2. Skim the **Playbooks** table in `AGENTS.md` so you know which `.claude/skills/{name}/SKILL.md` to open before building each kind of artifact — do not read them all now, open them on demand.
3. Skim `docs/adr/README.md` for the decision index. Read an individual ADR only when you need the *why*.
4. Read `DESIGN.md` only if the task touches UI.

Do not load `.cursor/rules/*.mdc` wholesale — `AGENTS.md` plus the playbooks cover everything, and those files are language/library detail to consult on demand.
