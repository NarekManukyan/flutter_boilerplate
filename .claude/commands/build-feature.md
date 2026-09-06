---
description: Deliver a feature end to end — read the Jira AC, analyse, plan, size, build, and exit through the QA gate
argument-hint: <JIRA-KEY | issue URL | task description>
---

Deliver this task end to end, following the plan-first workflow in ADR-0016: **$ARGUMENTS**

Read `AGENTS.md` first. Then work the loop below. Do not skip to code.

## 1. Plan — invoke the `plan-feature` skill

Use the `plan-feature` skill and follow it fully:

- If the argument is a Jira key or URL, fetch the issue with the Atlassian MCP tools. Read the description, **every** acceptance criterion, the comments, attachments, design links and linked issues — not the summary alone.
- Restate the AC as a checklist of verifiable outcomes.
- List ambiguities as open questions and **raise them with me now**. Do not encode a guess.
- Analyse the codebase for what already exists and what the blast radius is. Prefer the `code-review-graph` MCP tools over grep.
- Produce the plan: contracts first, then implementation, then the Proof table mapping every AC line to a test or Maestro flow.

## 2. Size it, then ask — or don't

Count independent surfaces (screens / stores / API resources).

- **Large** (>3 surfaces, or beyond one session) **and separable** (disjoint file sets, sharing only existing or contract-first files) → present the plan *and* a concrete parallel split naming each agent's files, then ask whether to run it as a team or in this session.
- Otherwise → present the plan and say you will build it in this session. **Do not ask about parallelism.**

## 3. Wait for approval

Present the plan and stop. Build nothing until I approve it.

## 4. Build

Work the plan in order — contracts, implementation, tests. Open the playbook named in each row *before* building that row (`create-feature`, `create-page`, `create-store`, `create-use-case`, `create-dto`, `create-api-provider`, `add-localization`, `add-design-token`).

Run `melos run build` after any codegen-annotation change. Never edit a generated file.

If reality contradicts the plan, say so and amend the plan. Do not diverge silently.

## 5. Prove it

Use `write-tests` for unit + widget coverage, and `write-maestro-flow` for the mandatory happy / failure / edge trio. Every AC line needs a proof.

## 6. QA gate

Run the `qa-feature` skill. Report the gate honestly — a FAIL with specific findings beats a PASS that skipped the failure flow.

Finish with:

```
melos run verify
melos run maestro
```

and a summary: what landed, the AC→proof table, what is not covered and why.
