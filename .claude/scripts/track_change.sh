#!/usr/bin/env bash
# PostToolUse hook (matcher: Write|Edit|MultiEdit), registered in
# .claude/settings.json. Records the edited file, relative to the project root,
# in .claude/state/changed_<session>.txt. post_turn.sh (the Stop hook) reads that
# list at the end of the turn. Must stay fast: it runs after every edit.
set -u

if ! command -v jq >/dev/null 2>&1; then
  echo "track_change.sh: jq is not installed, so edits are not tracked and the post-turn codegen/format/analyze hook will not run. Install jq (macOS: brew install jq)." >&2
  exit 0
fi

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PROJECT_ROOT_PHYSICAL="$(cd "$PROJECT_ROOT" && pwd -P)"
STATE_DIR="$PROJECT_ROOT/.claude/state"

PAYLOAD=$(cat)
SESSION_ID=$(jq -r '.session_id // empty' <<<"$PAYLOAD" 2>/dev/null | tr -cd 'A-Za-z0-9_-')
SESSION_ID=${SESSION_ID:-default}
FILE=$(jq -r '.tool_input.file_path // empty' <<<"$PAYLOAD" 2>/dev/null)
[ -n "$FILE" ] || exit 0

# Only files inside this checkout. Store them project-relative.
case "$FILE" in
  "$PROJECT_ROOT"/*) REL=${FILE#"$PROJECT_ROOT"/} ;;
  "$PROJECT_ROOT_PHYSICAL"/*) REL=${FILE#"$PROJECT_ROOT_PHYSICAL"/} ;;
  *) exit 0 ;;
esac

# Edits inside .claude/ are not app code. That includes .claude/worktrees/*:
# a worktree is its own checkout, and running codegen for it in the main
# checkout would be wrong.
case "$REL" in
  .claude/*) exit 0 ;;
esac

mkdir -p "$STATE_DIR"
printf '%s\n' "$REL" >> "$STATE_DIR/changed_${SESSION_ID}.txt"
exit 0
