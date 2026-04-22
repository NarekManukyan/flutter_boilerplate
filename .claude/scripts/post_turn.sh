#!/usr/bin/env bash
# Stop hook: classify changed files, run only the needed generators, then
# dart fix/format/analyze. Writes outputs to .claude/state/*.log and injects a
# short summary back into Claude's context via hookSpecificOutput.
set -u

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
STATE_DIR="$PROJECT_ROOT/.claude/state"
mkdir -p "$STATE_DIR"

PAYLOAD=$(cat)
SESSION_ID=$(jq -r '.session_id // "default"' <<<"$PAYLOAD" 2>/dev/null)
[ -z "$SESSION_ID" ] || [ "$SESSION_ID" = "null" ] && SESSION_ID="default"

CHANGED_FILE="$STATE_DIR/changed_${SESSION_ID}.txt"
BUILD_LOG="$STATE_DIR/build.log"
ANALYZE_LOG="$STATE_DIR/analyze_result.log"

# Guard: avoid recursion. Claude may call Stop while a previous Stop hook is
# still running a long generation — the stop_hook_active flag prevents that.
STOP_HOOK_ACTIVE=$(jq -r '.stop_hook_active // false' <<<"$PAYLOAD" 2>/dev/null)
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
  exit 0
fi

# Nothing changed? Exit silently — don't even run dart analyze.
if [ ! -s "$CHANGED_FILE" ]; then
  exit 0
fi

# Dedup & classify
CHANGED=$(sort -u "$CHANGED_FILE")
rm -f "$CHANGED_FILE"

need_api=0
need_ds=0
need_app=0
need_tr=0
any_dart=0

while IFS= read -r f; do
  [ -z "$f" ] && continue
  rel="${f#$PROJECT_ROOT/}"
  case "$rel" in
    assets/translations/*.json)
      need_tr=1 ;;
    packages/api/*.dart|packages/api/**/*.dart)
      need_api=1; any_dart=1 ;;
    packages/design_system/*.dart|packages/design_system/**/*.dart)
      need_ds=1; any_dart=1 ;;
    lib/*.dart|lib/**/*.dart|test/*.dart|test/**/*.dart)
      any_dart=1
      # Only rebuild app runner if file contains codegen-triggering annotations.
      if grep -qE "part '[^']+\.(g|freezed)\.dart'|@injectable|@singleton|@freezed|@JsonSerializable|@RestApi|Store\b|@observable|@action|@computed|@readonly" "$f" 2>/dev/null; then
        need_app=1
      fi
      ;;
    *.dart)
      any_dart=1 ;;
  esac
done <<<"$CHANGED"

: > "$BUILD_LOG"
SUMMARY=()

run_step() {
  local label="$1"; shift
  echo "=== $label ===" >> "$BUILD_LOG"
  if "$@" >> "$BUILD_LOG" 2>&1; then
    SUMMARY+=("$label: ok")
  else
    SUMMARY+=("$label: FAILED (see .claude/state/build.log)")
  fi
}

cd "$PROJECT_ROOT"

# Run generators in the correct order: api -> design_system -> app -> translations
[ "$need_api" = "1" ] && run_step "melos build_api" melos run build_api
[ "$need_ds"  = "1" ] && run_step "melos build_design_system" melos run build_design_system
[ "$need_app" = "1" ] && run_step "melos build_runner_app" melos run build_runner_app
[ "$need_tr"  = "1" ] && run_step "melos generate_translations" melos run generate_translations

# Dart fix / format / analyze (only if any dart file changed OR any generator ran)
analyze_summary=""
if [ "$any_dart" = "1" ] || [ "$need_app" = "1" ] || [ "$need_api" = "1" ] || [ "$need_ds" = "1" ]; then
  dart fix --apply >> "$BUILD_LOG" 2>&1 || true
  dart format . >> "$BUILD_LOG" 2>&1 || true
  dart analyze > "$ANALYZE_LOG" 2>&1
  analyze_rc=$?
  # Summarize analyze
  issues=$(grep -cE "^\s*(error|warning|info)" "$ANALYZE_LOG" 2>/dev/null || echo 0)
  if [ "$analyze_rc" = "0" ]; then
    analyze_summary="dart analyze: clean"
  else
    errors=$(grep -cE "^\s*error" "$ANALYZE_LOG" 2>/dev/null || echo 0)
    warnings=$(grep -cE "^\s*warning" "$ANALYZE_LOG" 2>/dev/null || echo 0)
    analyze_summary="dart analyze: ${errors} error(s), ${warnings} warning(s) — full output in .claude/state/analyze_result.log"
  fi
  SUMMARY+=("$analyze_summary")
fi

# Build summary for Claude
if [ ${#SUMMARY[@]} -gt 0 ]; then
  context="Post-turn hook ran:\n"
  for s in "${SUMMARY[@]}"; do
    context+="  - $s\n"
  done

  # Always block so Claude is re-prompted with the hook summary as the next
  # message. The stop_hook_active guard at the top prevents infinite loops —
  # on the second stop of the same turn, the hook exits early.
  if [ -n "$analyze_summary" ] && [[ "$analyze_summary" == *"error("* ]]; then
    context+="\nFirst entries from dart analyze:\n"
    context+=$(head -40 "$ANALYZE_LOG")
  fi
  jq -n --arg reason "$context" '{decision: "block", reason: $reason}'
fi
exit 0
