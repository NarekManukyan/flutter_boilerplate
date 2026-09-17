---
name: triage-bug-report
description: Triage and diagnose a user bug report against the code the reporter was actually running. Pins the source to the app version in a detached worktree, gathers evidence from logs, crash reports and screenshots, runs an evidence-versus-code debate through one shared findings file (at most 3 rounds), and produces a draft verdict for a human to post. Creating a ticket is optional and only happens on an explicit yes after a duplicate search. Use when the user says "triage this bug report", "diagnose this crash", "why did the app break for this user", "look at these logs", "investigate this support ticket" or "review new bug reports", or pastes a stack trace, device log, crash-reporter link or error screenshot together with an app version.
---

# Triage a bug report

You are the **orchestrator**. You gather the report, pin the source to the reporter's build, and run a short debate. **Evidence analysts** read what happened. A **code checker** confirms or refutes it against the source. You then synthesise one verdict. **Output is a draft.** You never post to a chat, a support tool or a ticket tracker on your own.

Errors reach crash reporting through `IssueTrackingService` ([ADR-0020](../../../docs/adr/0020-error-handling-and-issue-tracking.md)), so that service decides what a crash report can contain.

## Hard rules

- **Draft only.** Present the verdict and let the user post it.
- **Never scrape credentials.** Do not read tokens from browser `localStorage`, cookies or the keychain, and do not copy a session out of a logged-in page. Do not type passwords or complete SSO for the user. Fetch logs and attachments only through a tool the user has authenticated (an MCP server or a CLI), or ask the user to download them and give you a local path. If a download needs a session you do not have, stop and ask.
- **Reports carry personal data.** Keep downloaded logs and the findings file outside the repo (the default work directory below is under `$TMPDIR`). Leave emails, phone numbers, account ids and tokens out of drafts, tickets and the knowledge base. Refer to the report by its id.
- **A ticket needs an explicit yes**, and a duplicate search comes first (step 7).

## 1. Intake and triage

Collect, for each report:

- The reporter's own words: what they did, what they expected, what happened, and when.
- **App version and build**, platform, OS version and device.
- **The whole thread.** Follow-up questions, the reporter's answers and any earlier team diagnosis are often decisive. If the team already reached a verdict, compare yours against it and do not re-argue it blindly.
- Attached evidence: device logs, crash-reporter issues (stack trace, breadcrumbs, event count, affected builds), screenshots, screen recordings.

Classify the report before spending a debate on it:

| Class | Action |
|---|---|
| Client bug (crash, wrong state, broken flow, data not shown or not saved) | Investigate: steps 2 to 6 |
| Backend or API (5xx, wrong payload, the same failure across builds) | Route it to the backend owners with the request id, endpoint, status and time. No code debate |
| Account, billing or support request | Route it to support and skip it |
| Environment (OS or device quirk, network, a third-party outage) | Short verdict with the evidence, plus a workaround if one exists |
| Not enough to go on | Draft a reply asking the reporter for the specific data that would decide it |
| Internal test or noise | Skip it and list it as skipped |

In batch mode, show the user the triaged list and confirm which reports to investigate. By default, investigate every client bug.

## 2. Pin the source to the reporter's version

Line numbers drift between releases, so the code checker must read the build the reporter ran, not your current branch. Run `git fetch --tags` if release tags might be missing locally, then:

```bash
.claude/skills/triage-bug-report/src_at_version.sh setup "<version, e.g. 1.4.2+57>" <report-id>
# CODE_REF=v1.4.2   CODE_SHA=1a2b3c4   CODE_EXACT=yes   CODE_ROOT=<work dir>/<report-id>/src
```

The script ([`src_at_version.sh`](src_at_version.sh)) takes the tag `X.Y.Z`, then `vX.Y.Z`, and falls back to the default branch (never your current feature branch) with `CODE_EXACT=no`. It creates a detached worktree and does not touch your checkout. The work directory is `$TRIAGE_WORKDIR`, which defaults to `${TMPDIR:-/tmp}/triage-bug-report`.

When `CODE_EXACT=no`, every citation carries the warning that lines may have drifted. Apps get reliable pinning by tagging each release `X.Y.Z` or `vX.Y.Z`.

Cite code as **`path:line @CODE_REF`**. If a symbol the evidence points at does not exist at `CODE_REF`, say so, because the bug may predate or postdate that build. The `code-review-graph` index, if present, is built on your current branch. Use it to navigate, and verify the lines under `CODE_ROOT`.

## 3. Load known failure signatures (optional)

If `.claude/skills/triage-bug-report/knowledge/` exists, grep it for the report's error codes, exception types, log triggers and symptom phrases. Read the best matching `sig-*.md` files, and always read `heuristics.md` if it exists. Pass the matches to the analysts and the code checker, and give the code checker each signature's `Code refs`.

**A match is a hypothesis, not a verdict.** If no signature fits the evidence, treat the report as a new one and do not force the nearest match.

## 4. The debate, through one shared findings file

Create `FINDINGS=<work dir>/<report-id>/findings.md` and seed it with the report id, the reporter's words, version, platform and `CODE_REF`/`CODE_EXACT`. Every participant **appends** its own section and never rewrites anyone else's.

Run each role as a separate read-only subagent where your tool supports it, passing the exact `FINDINGS` path. Otherwise play the roles one after another, and finish writing each section before you read the next role's inputs.

**Round 1: evidence, in parallel.** Start one analyst per kind of evidence you have.

- **Log analyst.** Reads the logs, device state and screenshots only, never source code.
  - Matches the failing session to the reported time.
  - Reconstructs the timeline and quotes exact lines with timestamps.
  - Notes app, OS, permission, network and account state.
- **Crash analyst.** Reads the crash-reporter issues for that user and build.
  - Records top in-app frames, breadcrumbs, first and last seen, event count, and the builds affected.

```
## EVIDENCE: <logs|crashes> — round <R>
Verdict: client-bug | backend | environment | not-a-bug | inconclusive
One line: <what happened>
Timeline: <ts — event>, …
Key lines: <2–6 exact quotes>
State: <app/OS/device/permissions/network>
Detection gaps: <subsystems with logging off or missing breadcrumbs>
Questions for CODE CHECKER: <specific functions, guards or handlers to verify>
```

**Round 1: code checker, after all the evidence sections exist.** Reads source **only under `CODE_ROOT`**. For each claim it finds the responsible code and marks it confirmed, refuted or partial, citing `path:line @CODE_REF`. It says so plainly when the evidence points at the wrong layer.

```
## CODE CHECKER — round <R>
On the evidence: agree | disagree | partial — <one line>
Findings:
- <path:line @ref> — CONFIRMED|REFUTED|PARTIAL: <why>
Root cause (code level): <the mechanism>
Fix direction: <concrete change and where>
Questions for EVIDENCE: <what the logs or crashes must still show, or "none">
```

**Decide.** Read the file.

- **Converged** (the sections agree on the root cause and no questions are open): go to step 5.
- **Not converged:** run another round. Re-run only the roles that have open questions or a rebuttal to answer, passing the next round number. Each reads the other side's latest section first.

Stop after **3 rounds**. If there is still no agreement, the verdict is *inconclusive*: state both positions and the one piece of evidence that would settle it, and ask the reporter for it.

**Reasoning checks that separate right from plausible:**

- Locate *where* the failure happened before *why*: input or capture, local processing, transport, server, or rendering. Find the one observation that separates them, such as a counter that stopped growing versus one that kept growing.
- Wall-clock durations and timers are not proof that work was done.
- A warning or telemetry line is often a downstream symptom. Find the first anomaly in time.
- If logging for a subsystem is disabled by configuration, the absence of its events proves nothing.
- The same failure across many builds and users points away from the client.

## 5. Synthesise the draft

Write the reply in the voice of the person who will post it (first person, never addressed to them). Keep it short:

- **Verdict** in 1–2 lines: class, and whether it is confirmed.
- **The decisive evidence**: one or two quoted lines or facts, not the whole timeline.
- **Root cause** with one `path:line @CODE_REF` per point, plus the drift warning when `CODE_EXACT=no`.
- **Impact**: who is affected, and whether the user's data is recoverable.
- **Fix direction**, and a workaround for the reporter if one exists.
- **What to ask the reporter**, if anything is still needed.
- The ticket link, if step 7 produced one.
- End with `_Drafted with AI; check before acting._`

Present it and stop. The user posts it.

## 6. Clean up

```bash
.claude/skills/triage-bug-report/src_at_version.sh cleanup <report-id>
```

This removes the worktree and keeps `findings.md`. Delete the downloaded logs once the user is done with them.

## 7. File a ticket (optional, gated)

Only for a **confirmed client bug**, meaning the code checker found a real `path:line` root cause and a fix direction. Skip it for backend, environment, not-a-bug and inconclusive reports.

1. **Right tracker, right project.** Confirm the tracker tool is connected and that the project is the one the user named for bugs. Never guess a project. If either is unclear, say "ticket: not available" and skip this step.
2. **Search for duplicates first.** For example, in Jira use JQL `project = <KEY> AND statusCategory != Done AND (text ~ "<error code or signature>" OR summary ~ "<report id>")`. In GitHub Issues use `gh issue list --state open --search "<error code or signature> in:title,body"`. If an open issue covers it, reuse its link and do not create another.
3. **Ask.** Show the proposed type, summary (`[<platform> <version>] <symptom> — <cause>`), labels and description, and wait for an explicit yes.
4. **Create** on yes. The description holds the root cause with `path:line @ref`, the fix direction, repro steps, links to the report thread and crash issues, and the report id. It contains no personal data.
5. Put the link into the step 5 draft.

## 8. Remember (optional)

**Watermark for batch sources.** When you poll a queue (a channel, a support view, a crash-reporter saved search), keep the newest item you have read in `.claude/skills/triage-bug-report/state/watermarks.json`. That file is git-ignored and local to each developer.

```bash
STATE=.claude/skills/triage-bug-report/state/watermarks.json
jq -r --arg s "<source-id>" '.[$s] // "0"' "$STATE" 2>/dev/null || echo 0     # read: process only newer items
```

**Advance the watermark only after the run completes**, meaning every report is triaged and every draft presented. Set it to the newest item *read*, including skipped ones, so they are not pulled again. It never moves backwards. If a run is interrupted, leave it unchanged: the next run reprocesses those reports, which is safe because nothing was posted.

```bash
mkdir -p "$(dirname "$STATE")"; [ -f "$STATE" ] || echo '{}' > "$STATE"
jq --arg s "<source-id>" --arg v "<newest-read>" \
  '.[$s] = ([(.[$s] // "0"), $v] | max_by(tonumber))' "$STATE" > "$STATE.tmp" && mv "$STATE.tmp" "$STATE"
# max_by(tonumber) suits numeric ids and epoch timestamps; use `max` for ISO-8601 strings.
```

**Knowledge base of failure signatures.** This is committed and shared, so it must stay curated. After a converged verdict, update `.claude/skills/triage-bug-report/knowledge/`:

- **Matched an existing signature:** edit it. Add the report id to `Seen`, plus any new symptom phrase, error code or code ref.
- **New root cause:** add one `sig-<short-name>.md`:

  ```
  # sig-<short-name>
  - Platform: ios | android | both | backend
  - Symptoms (reporter's words): "…", "…"
  - Error codes / log triggers: `…`
  - Root cause: …
  - Code refs: `path:line @ref`
  - Status: open | fixed in X.Y.Z (<PR or ticket>)
  - Seen: <report ids>
  - Related: sig-…
  ```

- **A lesson that applies across reports** (a log that lies, a routing rule): add it to `heuristics.md`.

Keeping it curated:

- One file per root cause. Merge near-duplicates instead of adding more.
- Record the ref the lines were verified at.
- Mark a fixed signature with its version instead of deleting it, because reports from old builds keep arriving. Prune it only once that version is below the minimum supported version.
- No personal data.
- Review knowledge changes in PRs like code. A wrong signature misleads every later run.

## Anti-patterns

- Reading the current branch instead of the reporter's build, then citing lines that do not exist in their version.
- Forcing a report into the nearest known signature.
- Running the debate on a billing question.
- Posting the draft, or creating a ticket without a yes or without a duplicate search.
- Advancing the watermark before the run finished.
- Getting logs by lifting a session token from the browser.
