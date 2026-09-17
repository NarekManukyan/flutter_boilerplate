---
description: Senior PR review by a three-reviewer panel, with inline comments, review-round handling, a structured overview and a paste-ready fix prompt
argument-hint: <PR URL | PR number | owner/repo/pull/N>
allowed-tools: Bash(gh pr view:*), Bash(gh pr diff:*), Bash(gh pr checks:*), Bash(gh pr comment:*), Bash(gh api:*), Bash(gh repo view:*), Bash(git remote:*), Bash(git fetch:*), Bash(git show:*), Bash(git ls-files:*), Read, Grep, Glob
---

Review this pull request: **$ARGUMENTS**

You run a panel of **three senior reviewers**. Each keeps to their own lens. They disagree on emphasis, never on facts, and **every finding goes to exactly one reviewer**: the one whose lens fits best.

- **Reviewer A: Architecture.** Layer boundaries, State vs Store, use-case rules, DI, `AppNavigator`, Provider-based state access, widget construction and hook selection, error handling, feature layout and package boundaries.
- **Reviewer B: Correctness.** Logic bugs, null safety, async pitfalls and races, stream or subscription leaks, wrong state transitions, missing error paths, boundary inputs, time-zone, locale and precision traps, and whether the diff does what the PR and its ticket say.
- **Reviewer C: Performance and quality.** Unnecessary rebuilds, work inside `build()`, non-lazy lists, algorithmic cost, allocation on hot paths, readability, naming, dead code, and missing or weak tests.

## 1. Resolve the PR

- A URL `https://github.com/<owner>/<repo>/pull/<n>` or `<owner>/<repo>/pull/<n>` gives `owner`, `repo` and `n` directly.
- A bare number resolves against this checkout's `origin`: `gh repo view --json nameWithOwner -q .nameWithOwner`.

Only operate on that repository.

## 2. Load the conventions

- Read **`AGENTS.md`** in full and apply it throughout. Do **not** read `CLAUDE.md` for rules. It only contains an `@AGENTS.md` import, and reading the file directly does not expand that import, so you would review against an empty rule set.
- Open the ADRs under `docs/adr/` that the diff touches. The "Architectural decisions" list in AGENTS.md maps each rule to its ADR.
- For each kind of artifact the diff adds (store, use case, DTO, page, DS component, Maestro flow and so on), open its playbook in `.claude/skills/{name}/SKILL.md`. Open `DESIGN.md` if the diff touches UI.
- Do not load `.cursor/rules/*.mdc`. AGENTS.md overrides them.

## 3. Fetch everything at once

Run these in parallel:

```bash
gh pr view <n> --repo <o>/<r> --json number,title,body,url,author,baseRefName,headRefName,headRefOid,isDraft,files
gh pr diff <n> --repo <o>/<r>
gh pr checks <n> --repo <o>/<r>                                # CI: note every failing check by name (non-zero exit just means some check is not green)
gh api --paginate repos/<o>/<r>/pulls/<n>/comments             # inline comments and replies (in_reply_to_id)
gh api --paginate repos/<o>/<r>/issues/<n>/comments            # PR-level discussion, including earlier overviews
gh api --paginate repos/<o>/<r>/pulls/<n>/reviews
```

For thread ids and resolution state, use GraphQL:

```bash
gh api graphql -F owner=<o> -F repo=<r> -F n=<n> -f query='
query($owner:String!,$repo:String!,$n:Int!){repository(owner:$owner,name:$repo){pullRequest(number:$n){
  reviewThreads(first:100){nodes{id isResolved isOutdated path line
    comments(first:50){nodes{databaseId author{login} body createdAt}}}}}}}'
```

Read files **at the PR head**, not your working tree. If this checkout is the PR's repo, run `git fetch origin pull/<n>/head` and then `git show <headRefOid>:<path>`. Otherwise use `gh api -H "Accept: application/vnd.github.raw" "repos/<o>/<r>/contents/<path>?ref=<headRefOid>"`. Do not check the branch out.

## 4. Detect the round

This command marks its own output. Inline comments start with `**[Reviewer `, and the overview starts with `<!-- review-pr:round=N -->`.

- **Round 1:** no earlier overview from this command.
- **Round N:** the highest earlier `round=` plus one. Before looking for anything new, work through **every thread this command opened**:
  1. Group the inline comments into chains by `in_reply_to_id` and read each chain **in full**. Also read the issue comments, because authors often reply at PR level.
  2. Find the referenced code at the current head. `isOutdated: true` only means the lines moved. It does not mean the issue is fixed.
  3. Decide, then reply in the thread with exactly one of these:

     | What happened | Reply | Thread |
     |---|---|---|
     | The code now fixes it | `Resolved.` | resolve |
     | The author pushed back and the argument holds (the finding was wrong, or out of scope) | `Acknowledged, closing per the author's response.` | resolve |
     | The author deferred it to a follow-up PR or a ticket | `Deferred, tracked in <ref>.` | resolve |
     | Not fixed, and nothing from the author addresses it | `Still unresolved, see the original comment above.` | leave open |

     - **Clarification of intent:** re-evaluate with the new understanding first, then pick one of the rows above.
     - **A question back to the reviewer:** answer it in the thread and leave the thread open, with no status line.
     - **Pushback that does not hold:** reply once with the specific reason, then treat it as `Still unresolved`. Do not argue in circles.
     - **Already marked:** if the thread's last reply is already `Still unresolved` and nothing changed since, post nothing again. List it in the overview only.

     Reply with `gh api --method POST repos/<o>/<r>/pulls/<n>/comments/<comment_id>/replies -f body='…'`. Resolve with `gh api graphql -f id=<threadId> -f query='mutation($id:ID!){resolveReviewThread(input:{threadId:$id}){thread{isResolved}}}'`.
  4. **Auto-resolve threads whose code changed.** A thread this command opened whose referenced lines are gone, where the suggestion was applied or the flagged pattern no longer exists, is fixed. Reply `Resolved.` and resolve it, even when the author never replied.
  5. **Never resolve** a human reviewer's thread, a thread that is still valid, or a thread you are unsure about.
  6. **Never re-post a finding that was already discussed and dismissed**, whether acknowledged, deferred or closed by a human, even if the code looks unchanged.

Only after this, review the new changes.

## 5. Read around every hunk

For each non-trivial hunk, read **at least 30 lines of surrounding context** at the head, plus the directly related files: the symbols it calls and the code that calls it. Prefer the `code-review-graph` MCP tools (`get_review_context`, `query_graph` callers_of/callees_of, `get_impact_radius`) when they are available. Many diffs look fine alone and are wrong in context.

Check each change against AGENTS.md ("Rules that apply to every change", the layer table, file boundaries) and the ADRs it touches.

**Do not comment on:** generated files (the AGENTS.md "File Boundaries" list), formatting that `dart format` accepts, import style or other lints `analysis_options.yaml` already enforces, missing `///` docs on public APIs, `lowerCamelCase` enum values, or tests for trivial code.

## 6. Write the findings

Inline comments go on the **right side** of the diff, on one line or a line range. Body format:

```
**[Reviewer A|B|C — <category>]**
**Severity: P0 | P1 | P2**

<What is wrong, why it matters, and a concrete fix — a one-line replacement where possible.>
```

**Severity**

- **P0:** a crash, data loss, security hole, broken feature, or regression in a critical user flow. Must be fixed before merge.
- **P1:** a significant bug, an AGENTS.md or ADR violation, a leak, or a material performance regression. Should be fixed before merge.
- **P2:** a code smell, minor inefficiency, readability or naming issue, or a missing test. Fix when convenient.

**Complex logic.** Post a dedicated comment on **every complex function or non-trivial calculation** in the diff: what it does, and whether the logic is correct (including edge cases). When in doubt, flag it. These are the highest-value comments.

**Hygiene**

- When pointing elsewhere, cite the exact `file:line`.
- Quote at most a few lines of code.
- Suggest a concrete fix. A one-line change is ideal.
- Never raise the same finding from two reviewers.
- A finding on a line that is not in the diff cannot be anchored. Put it in the overview with its `file:line` instead of inventing a diff position.

## 7. Submit in two steps

**Step 1: the review, with all inline comments.** Send JSON through `--input`. Building a `comments` array out of `-f` flags is easy to get wrong.

```bash
gh api --method POST repos/<o>/<r>/pulls/<n>/reviews --input - <<'JSON'
{
  "commit_id": "<headRefOid>",
  "event": "COMMENT",
  "body": "_See the review overview in the comment below._",
  "comments": [
    { "path": "lib/…", "line": 42, "side": "RIGHT", "body": "…" },
    { "path": "lib/…", "start_line": 10, "start_side": "RIGHT", "line": 14, "side": "RIGHT", "body": "…" }
  ]
}
JSON
```

Pick the event:

| State after this round | Verdict | Event |
|---|---|---|
| Any P0 is open, whether new or carried over | Request changes | `REQUEST_CHANGES` |
| P1s open, no P0 | Request changes, or Approve with minor fixes if the P1s are small and need no re-review | `COMMENT` |
| Only P2s open | Approve with minor fixes | `COMMENT` |
| Nothing open | Approve | `APPROVE` |

`APPROVE` is only for an unconditional approval. GitHub refuses `APPROVE` and `REQUEST_CHANGES` on your own PR. In that case submit `COMMENT` and state the verdict in the overview.

**Step 2: the overview, posted last** as an issue comment so it lands below the inline comments: `gh pr comment <n> --repo <o>/<r> --body-file -`.

```markdown
<!-- review-pr:round=<N> -->
## Review Overview — Round <N>

**Summary:** 2–3 sentences on the purpose and overall quality of the PR.

**Resolved since last round:** fixed, acknowledged or deferred items, each with `file:line` (or `N/A` in round 1).

**Still open from earlier rounds:** each with `file:line` and severity (or `N/A`).

**New P0:** bullets with `file:line`, or `None`.

**New P1:** bullets with `file:line`, or `None`.

**New P2:** bullets with `file:line`, or `None`.

**Complex logic flagged:** function or calculation, `file:line`, and what to verify.

**CI:** green, or the failing checks by name.

**Verdict:** Approve | Approve with minor fixes | Request changes
```

End the overview with the fix prompt, collapsed:

````markdown
<details>
<summary>Fix prompt (paste into your coding agent)</summary>

```
Address these review findings on "<PR title>" (PR #<n>, branch <headRefName>), round <N>.

Still unresolved from earlier rounds:
- <finding> — file:line

New P0:
- <finding> — file:line

New P1:
- <finding> — file:line

New P2 (optional but recommended):
- <finding> — file:line

Complex logic to double-check:
- <function> — file:line — <concern>

Read AGENTS.md first and follow it (not CLAUDE.md, which only imports it). Never edit
generated files. After annotation changes run `melos run build`; after editing
assets/translations/en-US.json run `melos run translations`. If a Stop hook reported a
failure, fix it; if hooks are not active in your tool, run the commands yourself.
Run `melos run verify` before pushing. For each fix, say what you changed and why.
```

</details>
````

## Guardrails

- **Be frugal.** Five well-aimed comments beat thirty nits.
- **Never invent line numbers.** Comment only on lines that exist in the diff or at the head.
- **Never approve with an open P0.** When unsure between Approve with minor fixes and Request changes, pick Request changes.
- **Post nothing but** the inline comments, the thread replies and the overview. Scratch notes and per-reviewer drafts stay local.
- **Stay in the PR's repository.** Never write to any other.
