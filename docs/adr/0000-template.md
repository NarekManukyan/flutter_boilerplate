# NNNN. Short Decision Title

- Status: Proposed | Accepted | Rejected | Deprecated | Superseded by ADR-XXXX
- Date: YYYY-MM-DD
- Deciders: <names or roles>
- Consulted: <people whose opinion was asked for, two-way> (optional, delete if unused)
- Informed: <people kept up to date, one-way> (optional, delete if unused)

## Context and Problem Statement

What is the situation? What forces are at play? What problem must be solved? Two or three short paragraphs is enough.

## Decision Drivers

- driver 1
- driver 2

## Considered Options

- Option A
- Option B
- Option C

## Decision Outcome

Chosen option: **Option X**, because <one-line justification>.

### Consequences

- Good: ...
- Neutral: <side effect that is neither good nor bad>
- Bad / trade-off: ...

### Confirmation

How we confirm the decision is implemented and upheld: a lint rule, a CI check (e.g. a step in `melos run verify`), a review checklist item, or a test. Name the concrete mechanism, not "code review" in general. Delete this section only if nothing can check the decision.

## Pros and Cons of the Options

### Option A
- Good: ...
- Neutral: ...
- Bad: ...

### Option B
- Good: ...
- Bad: ...

## Links

- Related ADR: [ADR-XXXX](XXXX-slug.md)
- External reference: <url>

## AI Implementation Guidelines

<!-- For coding agents. Delete the whole section if the decision needs no agent-specific handling. -->

<ai_context_rules>
- **Autonomy level:** Full | Guardrailed (human review required) | Human-in-the-loop
- **Architecture constraints:** Hard limits for the agent. e.g. inject `AppNavigator`, never call `context.router`; use `LocaleKeys.*.tr()`, never hardcode UI strings.
- **File paths affected:** Globs this ADR governs. e.g. `lib/features/**/*_state.dart`, `lib/features/**/*_page.dart`.
- **Verification command:** The command the agent runs to confirm the change. e.g. `melos run verify`, or `melos run analyze` when only a static check applies.
</ai_context_rules>
