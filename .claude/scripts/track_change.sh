#!/usr/bin/env bash
# PostToolUse hook (Write|Edit|MultiEdit): append changed file path to a per-session list.
set -u
PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
STATE_DIR="$PROJECT_ROOT/.claude/state"
mkdir -p "$STATE_DIR"

PAYLOAD=$(cat)
SESSION_ID=$(jq -r '.session_id // "default"' <<<"$PAYLOAD" 2>/dev/null)
[ -z "$SESSION_ID" ] || [ "$SESSION_ID" = "null" ] && SESSION_ID="default"

# MultiEdit/Edit/Write all expose file_path on tool_input
FILE=$(jq -r '.tool_input.file_path // empty' <<<"$PAYLOAD" 2>/dev/null)
[ -z "$FILE" ] && exit 0

# Only track files under the project
case "$FILE" in
  "$PROJECT_ROOT"/*) ;;
  *) exit 0 ;;
esac

echo "$FILE" >> "$STATE_DIR/changed_${SESSION_ID}.txt"
exit 0
