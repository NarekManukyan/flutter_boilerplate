---
allowed-tools: mcp__github_inline_comment__create_inline_comment,mcp__github__add_issue_comment,mcp__github__get_pull_request,mcp__github__add_pull_request_review_comment_to_pending_review,mcp__github__pull_request_read,mcp__github__resolve_review_thread,mcp__github__get_me,Bash(gh pr comment:*),Bash(gh pr diff:*),Bash(gh pr view:*)
description: Review code quality of a pull request
---

Read `CLAUDE.md` and run `git ls-files` to understand the context of the project. `CLAUDE.md` is the single source of truth — do NOT load `.cursor/rules/*.mdc` during review.

## Step 1 — Auto-resolve previously fixed Claude comments

Before posting any new feedback:

1. Use `mcp__github__pull_request_read` (method `get_review_comments`) to fetch all existing review threads on the PR.
2. Filter to comments authored by the Claude reviewer bot (the same identity this command posts as — use `mcp__github__get_me` if unsure).
3. For each such comment, check whether the issue still exists in the latest diff. If the referenced lines are gone, the suggestion was applied, or the flagged pattern is no longer present → the comment is FIXED.
4. For every FIXED thread, call `mcp__github__resolve_review_thread` with its `threadId`. NEVER resolve threads from human reviewers, threads that are still valid, or threads where you are uncertain.
5. Briefly note how many threads you auto-resolved in your top-level summary.

## Step 2 — Review the PR

Review code quality of the pull request.

Do NOT raise comments about: missing `///` doc comments on public APIs, enum values using `lowerCamelCase`, package-vs-relative import preferences, `dart format`-accepted style nits, tests for trivial code, or generated files. See `CLAUDE.md` for the full list.

Provide feedback using inline comments for specific issues.
Use top-level comments for general observations or praise.
Keep feedback concise.
---
