---
allowed-tools: mcp__github_inline_comment__create_inline_comment,mcp__github__add_issue_comment,mcp__github__get_pull_request,mcp__github__add_pull_request_review_comment_to_pending_review,mcp__github__pull_request_read,mcp__github__resolve_review_thread,mcp__github__get_me,Bash(gh pr comment:*),Bash(gh pr diff:*),Bash(gh pr view:*)
description: Review a pull request
---

You are a senior software engineer with 10+ years of experience.
Read `CLAUDE.md` and run `git ls-files` to understand the context of the project. `CLAUDE.md` is the single source of truth for conventions and lists the comment categories that MUST be suppressed (public-API doc comments, lowerCamelCase enum values, import-style nits, generated files, etc.). Do NOT load `.cursor/rules/*.mdc` — `CLAUDE.md` already covers everything needed for review and overrides those files where they conflict.

## Step 1 — Auto-resolve previously fixed Claude comments

Before posting any new feedback:

1. Use `mcp__github__pull_request_read` (method `get_review_comments`) to fetch all existing review threads on the PR.
2. Filter to comments authored by the Claude reviewer bot (the same identity this command posts as — typically `claude[bot]`, `github-actions[bot]`, or whatever account `mcp__github__get_me` returns).
3. For each such comment, check whether the issue it raised still exists in the latest diff:
   - If the referenced lines are gone, the suggestion was applied, or the file no longer contains the flagged pattern → the comment is FIXED.
   - If the thread is already resolved, skip it.
4. For every FIXED thread, call `mcp__github__resolve_review_thread` with its `threadId`. Do NOT resolve threads that are still valid, threads from human reviewers, or threads where you are uncertain.
5. Briefly summarize how many threads you auto-resolved in your top-level review comment.

## Step 2 — New review

Perform a comprehensive code review using subagents for key areas:

- code-quality-reviewer
- performance-reviewer
- test-coverage-reviewer
- documentation-accuracy-reviewer
- security-code-reviewer

Instruct each to only provide noteworthy feedback. Once they finish, review the feedback and post only the feedback that you also deem noteworthy.

Provide feedback using inline comments for specific issues.
Use top-level comments for general observations or praise.
Keep feedback concise.

---
