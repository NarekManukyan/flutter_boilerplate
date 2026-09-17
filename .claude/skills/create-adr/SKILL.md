---
name: create-adr
description: Write a new Architecture Decision Record in MADR format — when a decision deserves an ADR versus a playbook edit, numbering, real alternatives with honest trade-offs, and the index/AGENTS.md updates that must follow. Use when introducing, changing or superseding an architectural rule.
---

# Create an ADR

Format: [MADR 3.0](https://adr.github.io/madr/). Template: [`docs/adr/0000-template.md`](../../../docs/adr/0000-template.md). Index: [`docs/adr/README.md`](../../../docs/adr/README.md).

## Does this need an ADR?

An ADR is for a decision that **had real alternatives** and constrains future work.

| Write an ADR | Do not |
|---|---|
| Choosing MobX over Bloc | Adding one more `@readonly` field |
| Banning use-case → use-case dependencies | Documenting how to write a use case → that is a playbook |
| Moving from `integration_test` to Maestro | Adding a Maestro flow |
| Deprecating `lib/shared/` | Moving one file out of it |

If the answer is a *procedure*, it belongs in a playbook under `.claude/skills/`. If it is a *rule with a rejected alternative*, it is an ADR. If it is a one-line constraint everyone must always follow, it goes in `AGENTS.md` — usually pointing at an ADR.

## Numbering and status

Next free number, zero-padded, kebab slug: `0018-short-decision-title.md`. Numbers are never reused, and an ADR is never deleted.

- **Proposed** — under discussion. Do not enforce it yet.
- **Accepted** — describes how the codebase works now. This is the normal status here: an ADR is written when the rule is real, not aspirational.
- **Rejected** — considered and turned down. Keep the file so the same proposal is not argued again from scratch.
- **Deprecated** — no longer applies, nothing replaced it.
- **Superseded by ADR-NNNN** — replaced. Set the old ADR's status to `Superseded by ADR-NNNN`; do not delete it. The new one links back.

Metadata is a bullet list under the title: `Status`, `Date`, `Deciders`. `Consulted` (people whose opinion was asked for) and `Informed` (people kept up to date) are optional; delete the bullets you do not use.

## The part that matters: alternatives

**List at least two alternatives, each with a concrete trade-off.** An ADR whose alternatives are strawmen is worse than no ADR — it launders a preference as a decision, and the next person cannot tell what was actually weighed.

For each option, give real "Good" and "Bad" bullets. The chosen option gets `Bad` bullets too. If you cannot name a downside of your own choice, you have not understood it.

```markdown
### Hexagonal / ports-and-adapters
- Good: maximum decoupling of domain from frameworks.
- Bad: overkill for a Flutter UI app — domain logic is thin, most code is presentation + IO.
- Bad: introduces ports/adapters/domain entities that duplicate DTOs.
```

## Consequences, honestly

`### Consequences` under the decision outcome carries both directions. The "Bad" bullets are what make the ADR worth reading in a year — they are the cost the team knowingly accepted, and the reason someone might revisit it. Use a "Neutral" bullet for a side effect that is neither good nor bad but that a reader should know about (for example, a directory that now exists in every feature).

## Confirmation

`### Confirmation` says how the team knows the decision is implemented and still upheld: a lint rule, a CI check (a step in `melos run verify`), a review checklist item, or a test. Name the mechanism concretely. "Reviewers check it" is acceptable only when you also say what they look for, such as an import of `DioService` in a `*_state.dart` file. A rule nothing can check drifts, and the Confirmation section is where that becomes visible.

## AI Implementation Guidelines

The last section holds an `<ai_context_rules>` block for coding agents. Fill in all four fields, or delete the whole section when the decision needs no agent-specific handling.

- **Autonomy level**
  - `Full`: the agent applies the rule without asking.
  - `Guardrailed (human review required)`: the agent may implement, and a human reviews before merge.
  - `Human-in-the-loop`: the agent proposes, and a human decides before any code is written.
- **Architecture constraints**: the hard limits, phrased as do / never pairs the agent can check a diff against.
- **File paths affected**: globs of the files the ADR governs, e.g. `lib/features/**/*_use_case.dart`.
- **Verification command**: what the agent runs to confirm its change, usually `melos run verify` or a narrower `melos run analyze`.

## Write for the reader who disagrees

The audience is a developer six months from now who thinks the rule is wrong. Give them the context, the drivers, and the alternatives so they can either be persuaded or make a well-informed case to supersede it. Prose, not bullet soup — two or three paragraphs of context beat ten fragments.

## After writing

1. Add a row to the table in `docs/adr/README.md`.
2. Add the one-line form to the **Architectural decisions** list in [`AGENTS.md`](../../../AGENTS.md), then run `melos run sync-agents`.
3. If it introduces a procedure, add or update the playbook and add it to the AGENTS.md **Playbooks** table.
4. Link related ADRs both ways. If the new ADR supersedes an existing one, set that ADR's status to `Superseded by ADR-NNNN` and update its index row.
5. Link to the code the decision governs, so the ADR can be checked against reality.

## Checklist

- [ ] Real decision with real alternatives — not a procedure in disguise
- [ ] Next free number; MADR sections from the template
- [ ] ≥ 2 alternatives, each with honest Good/Bad
- [ ] Chosen option has stated downsides
- [ ] Confirmation names a concrete lint rule, CI check, checklist item or test
- [ ] AI Implementation Guidelines filled in (all four fields) or the section deleted
- [ ] Unused `Consulted` / `Informed` bullets deleted
- [ ] Context is prose, written for someone who disagrees
- [ ] `docs/adr/README.md` index row added
- [ ] `AGENTS.md` one-liner added and `melos run sync-agents` run
- [ ] Superseded ADRs updated, links both ways
