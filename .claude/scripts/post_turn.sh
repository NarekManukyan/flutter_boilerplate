#!/usr/bin/env bash
# Stop hook, registered in .claude/settings.json.
#
# At the end of a turn, takes the files the agent edited (recorded by
# track_change.sh) and:
#   1. runs only the codegen those edits need, incrementally (never
#      build_runner clean), in the order `melos run build` uses:
#      translations -> build:api -> build:design_system -> build:app
#   2. runs `dart fix --apply` and `dart format` on exactly the edited Dart files
#   3. runs `dart analyze` like `melos run analyze`: the app (lib, test) with
#      fatal infos, plus each package that was touched
#
# Clean turn: prints nothing, clears the state file, exits 0.
# Something failed: prints {"decision":"block","reason":...} so the agent sees
# the failure and fixes it, and keeps the file list so the next stop checks it
# again. On the stop right after such a block (stop_hook_active=true) it checks
# again but does not block a second time: a failure that is still there becomes
# a warning to the user, so an unfixable error cannot keep the agent looping.
#
# Logs: .claude/state/build.log (codegen, fix, format) and
#       .claude/state/analyze_result.log
set -u

if ! command -v jq >/dev/null 2>&1; then
  echo "post_turn.sh: jq is not installed, so post-turn codegen/format/analyze is disabled. Install jq (macOS: brew install jq)." >&2
  # Stderr from a hook that exits 0 only reaches the debug log, so also show
  # the user a warning. The message is a fixed string, safe to print as JSON.
  printf '%s\n' '{"systemMessage": "post_turn.sh: jq is not installed, so post-turn codegen/format/analyze is disabled. Install jq (macOS: brew install jq)."}'
  exit 0
fi

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
STATE_DIR="$PROJECT_ROOT/.claude/state"
BUILD_LOG="$STATE_DIR/build.log"
ANALYZE_LOG="$STATE_DIR/analyze_result.log"

PAYLOAD=$(cat)
SESSION_ID=$(jq -r '.session_id // empty' <<<"$PAYLOAD" 2>/dev/null | tr -cd 'A-Za-z0-9_-')
SESSION_ID=${SESSION_ID:-default}
STOP_HOOK_ACTIVE=$(jq -r '.stop_hook_active // false' <<<"$PAYLOAD" 2>/dev/null)
PENDING="$STATE_DIR/changed_${SESSION_ID}.txt"
# The list being checked. If a previous run was killed (hook timeout), its
# leftover list is merged into this run.
SNAPSHOT="$STATE_DIR/processing_${SESSION_ID}.txt"

# Nothing edited: stay silent.
[ -s "$PENDING" ] || [ -s "$SNAPSHOT" ] || exit 0

# Subagents or teammates still running in the background may be mid-edit.
# Checking now would report half-finished work. Leave the list for the stop
# that follows their completion.
IN_FLIGHT=$(jq -r '[.background_tasks[]? | select(.type == "subagent" or .type == "teammate" or .type == "workflow")] | length' <<<"$PAYLOAD" 2>/dev/null)
[ "${IN_FLIGHT:-0}" = "0" ] || exit 0

if ! command -v dart >/dev/null 2>&1; then
  echo "post_turn.sh: dart is not on PATH, skipping post-turn codegen/format/analyze." >&2
  exit 0
fi
if command -v melos >/dev/null 2>&1; then
  MELOS=(melos)
else
  MELOS=(dart run melos)
fi

cd "$PROJECT_ROOT" || exit 0
if [ -f "$PENDING" ]; then
  mv "$PENDING" "$PENDING.taken" &&
    cat "$PENDING.taken" >> "$SNAPSHOT" &&
    rm -f "$PENDING.taken"
fi
CHANGED=$(sort -u "$SNAPSHOT")

# A Dart file needs codegen when it declares a generated part, or carries an
# annotation or MobX marker that one of the builders reads. A file that no
# longer exists counts too: generated code (injectable.config.dart, the router)
# may still reference it.
CODEGEN_RE='^[[:space:]]*part[[:space:]]+[^;]*\.(g|freezed|gr|config|gen|tailor)\.dart'
CODEGEN_RE+='|@(injectable|Injectable|singleton|Singleton|lazySingleton|LazySingleton|module|preResolve|InjectableInit|RoutePage|AutoRouterConfig|freezed|Freezed|unfreezed|JsonSerializable|RestApi|tailorMixin|TailorMixin|observable|action|computed|readonly)([^A-Za-z0-9_]|$)'
CODEGEN_RE+='|with[[:space:]]+([A-Za-z0-9_<>, ]+,[[:space:]]*)?Store([^A-Za-z0-9_]|$)'

needs_codegen() {
  [ ! -e "$1" ] || grep -qE "$CODEGEN_RE" "$1"
}

is_generated() {
  case "$1" in
    *.g.dart | *.freezed.dart | *.gr.dart | *.config.dart | *.gen.dart | *.tailor.dart | lib/gen/* | */lib/gen/*) return 0 ;;
  esac
  return 1
}

need_tr=0 need_api=0 need_ds=0 need_app=0
touched_api=0 touched_ds=0 touched_app=0
DART_FILES=() # hand-written Dart files that still exist: fixed and formatted
OTHER_DART=() # Dart files outside lib/, test/ and the packages: analyzed by path

while IFS= read -r rel; do
  [ -n "$rel" ] || continue
  case "$rel" in
    assets/translations/*)
      need_tr=1
      continue
      ;;
    packages/api/pubspec.yaml | packages/api/build.yaml)
      need_api=1
      continue
      ;;
    packages/design_system/pubspec.yaml | packages/design_system/build.yaml | packages/design_system/assets/*)
      need_ds=1
      continue
      ;;
    build.yaml)
      need_app=1
      continue
      ;;
    *.dart) ;;
    *) continue ;;
  esac

  case "$rel" in
    packages/api/*)
      touched_api=1
      needs_codegen "$rel" && need_api=1
      ;;
    packages/design_system/*)
      touched_ds=1
      needs_codegen "$rel" && need_ds=1
      ;;
    lib/* | test/*)
      touched_app=1
      needs_codegen "$rel" && need_app=1
      ;;
    *)
      [ -f "$rel" ] && OTHER_DART+=("$rel")
      ;;
  esac
  if [ -f "$rel" ] && ! is_generated "$rel"; then
    DART_FILES+=("$rel")
  fi
done <<<"$CHANGED"

any_app_input=$((need_tr + need_api + need_ds + need_app + touched_api + touched_ds + touched_app))
if [ "$any_app_input" -eq 0 ] && [ ${#DART_FILES[@]} -eq 0 ]; then
  # Only files the checks do not care about (docs, config) changed.
  rm -f "$SNAPSHOT"
  exit 0
fi

mkdir -p "$STATE_DIR"
: >"$BUILD_LOG"
: >"$ANALYZE_LOG"
FAILED=()
BUILD_ERRORS="" # the tail of each failed codegen/format step's own output

# log_run <command...>: run it, appending the command line and output to build.log.
log_run() {
  printf '\n$ %s\n' "$*" >>"$BUILD_LOG"
  "$@" >>"$BUILD_LOG" 2>&1
}

step() { # step <command...>: log_run, recording a failure under the command's name.
  local first_line
  first_line=$(($(wc -l <"$BUILD_LOG") + 2)) # skip the blank line log_run writes first
  if ! log_run "$@"; then
    FAILED+=("$*")
    BUILD_ERRORS+=$'\n\n'"$(tail -n +"$first_line" "$BUILD_LOG" | tail -n 25)"
  fi
}

# 1. Codegen.
# Prefer the melos script. A repo that installed these hooks without the
# boilerplate's scripts falls back to build_runner in the package directly, so
# the hook keeps working instead of failing every turn.
has_script() { grep -qE "^[[:space:]]+$1:[[:space:]]*$" pubspec.yaml 2>/dev/null; }
codegen() { # codegen <melos script> <package dir>
  if has_script "$1"; then
    step "${MELOS[@]}" run "$1"
  elif [ -f "$2/pubspec.yaml" ]; then
    step sh -c "cd '$2' && dart run build_runner build -d"
  fi
}
if [ "$need_tr" -eq 1 ]; then
  if has_script translations; then
    step "${MELOS[@]}" run translations
  else
    FAILED+=("translations")
    BUILD_ERRORS+=$'\n\n'"assets/translations changed, but pubspec.yaml has no \`translations\` melos script. Regenerate the locale keys, or add the script."
  fi
fi
[ "$need_api" -eq 1 ] && codegen build:api packages/api
[ "$need_ds" -eq 1 ] && codegen build:design_system packages/design_system
[ "$need_app" -eq 1 ] && codegen build:app .

# 2. Fix and format only the edited files.
if [ ${#DART_FILES[@]} -gt 0 ]; then
  for f in "${DART_FILES[@]}"; do
    # `dart fix` takes one file or directory per run. Its failures are not
    # reported separately: anything it could not fix shows up in analyze.
    log_run dart fix --apply "$f" || true
  done
  step dart format "${DART_FILES[@]}"
fi

# 3. Analyze.
analyze() { # analyze <label> <dart analyze arguments...>
  local label=$1
  shift
  printf '\n$ dart analyze %s\n' "$*" >>"$ANALYZE_LOG"
  dart analyze "$@" >>"$ANALYZE_LOG" 2>&1 || FAILED+=("$label")
}

ROOT_TARGETS=()
if [ "$any_app_input" -gt 0 ]; then
  # Package and translation changes feed the app, so the app is analyzed too.
  [ -d lib ] && ROOT_TARGETS+=(lib)
  [ -d test ] && ROOT_TARGETS+=(test)
fi
[ ${#OTHER_DART[@]} -gt 0 ] && ROOT_TARGETS+=("${OTHER_DART[@]}")
# --fatal-infos matches `flutter analyze`, which `melos run analyze` uses for the app.
[ ${#ROOT_TARGETS[@]} -gt 0 ] && analyze "dart analyze ${ROOT_TARGETS[*]}" --fatal-infos "${ROOT_TARGETS[@]}"
[ $((touched_api + need_api)) -gt 0 ] && analyze "dart analyze packages/api" packages/api
[ $((touched_ds + need_ds)) -gt 0 ] && analyze "dart analyze packages/design_system" packages/design_system

if [ ${#FAILED[@]} -eq 0 ]; then
  rm -f "$SNAPSHOT"
  exit 0
fi

# Failed: keep the list so the next stop checks these files again.
cat "$SNAPSHOT" >>"$PENDING"
rm -f "$SNAPSHOT"

failed_steps=$(printf '%s; ' "${FAILED[@]}")
failed_steps=${failed_steps%; }
ISSUE_RE='^[[:space:]]*(error|warning|info) - '

reason="Post-turn checks failed for the files edited this turn: ${failed_steps}."
if [ -n "$BUILD_ERRORS" ]; then
  reason+="$BUILD_ERRORS"
fi
if grep -qE "$ISSUE_RE" "$ANALYZE_LOG"; then
  errors=$(grep -cE '^[[:space:]]*error - ' "$ANALYZE_LOG" || true)
  warnings=$(grep -cE '^[[:space:]]*warning - ' "$ANALYZE_LOG" || true)
  infos=$(grep -cE '^[[:space:]]*info - ' "$ANALYZE_LOG" || true)
  reason+=$'\n\n'"dart analyze: ${errors} error(s), ${warnings} warning(s), ${infos} info(s). First issues:"
  reason+=$'\n'"$(grep -E "$ISSUE_RE" "$ANALYZE_LOG" | head -n 30)"
fi
reason+=$'\n\n'"Fix these before finishing. Full output: .claude/state/build.log and .claude/state/analyze_result.log. Re-check by hand with \`melos run verify:quick\`."

if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
  jq -n --arg msg "Post-turn checks still failing after a fix attempt: ${failed_steps}. See .claude/state/build.log and .claude/state/analyze_result.log. They run again at the end of the next turn." \
    '{systemMessage: $msg}'
else
  jq -n --arg reason "$reason" '{decision: "block", reason: $reason}'
fi
exit 0
