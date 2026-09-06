#!/usr/bin/env bash
# Regenerate every tool-specific agent-instruction file from AGENTS.md.
#
# AGENTS.md is the single source (ADR-0017). Codex, Zed, Amp and Jules read it
# natively; the files below exist because their tools look somewhere else.
#
#   ./tool/sync_agents.sh            regenerate
#   ./tool/sync_agents.sh --check    fail if any generated file is stale (CI)
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

SOURCE="AGENTS.md"
[ -f "$SOURCE" ] || { echo "error: $SOURCE not found"; exit 1; }

CHECK=0
[ "${1:-}" = "--check" ] && CHECK=1

BANNER_MD='<!-- GENERATED FILE — DO NOT EDIT. Source: AGENTS.md. Regenerate: melos run sync-agents -->'

OUT_DIR="$(mktemp -d)"
trap 'rm -rf "$OUT_DIR"' EXIT

# --- CLAUDE.md -------------------------------------------------------------
# Claude Code resolves `@path` as an import, so the body stays in one file.
mkdir -p "$OUT_DIR"
cat > "$OUT_DIR/CLAUDE.md" <<EOF
# CLAUDE.md

$BANNER_MD

@AGENTS.md

## Claude Code specifics

The rules above are the whole contract — this section only covers Claude-only wiring.

- **Playbooks are skills.** Every file under \`.claude/skills/{name}/SKILL.md\` is an invocable skill. Invoke the one that matches the artifact you are about to build; the index is in the AGENTS.md "Playbooks" table.
- **Commands** in \`.claude/commands/\`:
  - \`/build-feature <JIRA-KEY | description>\` — the full delivery loop of ADR-0016: read AC, analyze, plan, size, build, QA.
  - \`/qa-feature <feature>\` — QA pass over a finished feature: happy / failure / edge.
  - \`/sync-agents\` — regenerate the generated instruction files after editing AGENTS.md.
  - \`/review-pr\`, \`/review-codequality\`, \`/review-functional-logic\`, \`/review-security-performance\`, \`/review-context-maintenance\` — review panels.
  - \`/context-prime\`, \`/sync-openapi\`.
- **Editing rules:** change \`AGENTS.md\`, never this file — it is overwritten by \`melos run sync-agents\`.
EOF

# --- GEMINI.md -------------------------------------------------------------
{ echo "$BANNER_MD"; echo; cat "$SOURCE"; } > "$OUT_DIR/GEMINI.md"

# --- .github/copilot-instructions.md ---------------------------------------
# One directory deep: rewrite root-relative links so they still resolve.
mkdir -p "$OUT_DIR/.github"
{
  echo "$BANNER_MD"
  echo
  sed -E 's#\]\((AGENTS\.md|DESIGN\.md|docs/|\.claude/|lib/|packages/|test/|assets/|tool/|\.maestro/)#](../\1#g' "$SOURCE"
} > "$OUT_DIR/.github/copilot-instructions.md"

# --- .cursor/rules/000-agents.mdc ------------------------------------------
# Cursor reads AGENTS.md natively in recent versions; this always-applied rule
# is the fallback for older ones and pins the read order for the other .mdc rules.
mkdir -p "$OUT_DIR/.cursor/rules"
cat > "$OUT_DIR/.cursor/rules/000-agents.mdc" <<'EOF'
---
description: Entry point — repo-wide agent rules live in AGENTS.md
alwaysApply: true
---

<!-- GENERATED FILE — DO NOT EDIT. Source: AGENTS.md. Regenerate: melos run sync-agents -->

# Read `AGENTS.md` first

`/AGENTS.md` at the repo root is the single source of truth for architecture rules,
the delivery workflow, naming, file boundaries and the testing contract. Read it
before any change and follow it over anything in this rules directory.

Read order:

1. **`AGENTS.md`** — what the rules are (always).
2. **`.claude/skills/{name}/SKILL.md`** — how to build a specific artifact. Open the
   playbook for what you are building *before* you build it; the index is the
   "Playbooks" table in `AGENTS.md`. These are plain Markdown, not Claude-only.
3. **`docs/adr/`** — why a rule exists, and what was rejected.
4. The other `.cursor/rules/*.mdc` files — language- and library-level detail
   (effective_dart, mocktail, mobx, firebase…) that `AGENTS.md` does not repeat.

Never edit this file; edit `AGENTS.md` and run `melos run sync-agents`.
EOF

# --- write or check --------------------------------------------------------
TARGETS=(
  "CLAUDE.md"
  "GEMINI.md"
  ".github/copilot-instructions.md"
  ".cursor/rules/000-agents.mdc"
)

STALE=0
for f in "${TARGETS[@]}"; do
  if [ "$CHECK" = "1" ]; then
    if ! diff -q "$OUT_DIR/$f" "$f" >/dev/null 2>&1; then
      echo "stale: $f"
      STALE=1
    fi
  else
    mkdir -p "$(dirname "$f")"
    cp "$OUT_DIR/$f" "$f"
    echo "  wrote $f"
  fi
done

if [ "$CHECK" = "1" ]; then
  if [ "$STALE" = "1" ]; then
    echo
    echo "Generated agent files are out of date. Run: melos run sync-agents"
    exit 1
  fi
  echo "Generated agent files are in sync with AGENTS.md."
else
  echo "Done. Source: AGENTS.md"
fi
