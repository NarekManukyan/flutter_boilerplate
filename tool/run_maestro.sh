#!/usr/bin/env bash
# Run the Maestro E2E suite and write a JUnit report plus debug artifacts.
#
#   ./tool/run_maestro.sh                              # every flow
#   ./tool/run_maestro.sh --include-tags happy         # extra args go to `maestro test`
#   ./tool/run_maestro.sh .maestro/flows/home/x.yaml   # one flow (or a directory) instead of the suite
#   DEVICE=<udid|adb serial> ./tool/run_maestro.sh     # pick a device when several are booted
#   APP_ID=com.acme.app ./tool/run_maestro.sh          # the app under test
#
# It runs `maestro test .maestro`: the workspace root, so .maestro/config.yaml
# decides which flows run (flows/*/*.yaml, quarantine excluded). Pointed at
# .maestro/flows instead, Maestro finds no config there and no flows.
#
# Environment:
#   APP_ID   Bundle id (iOS) / applicationId (Android) of the installed dev build.
#            Every flow header is `appId: ${APP_ID}`, so this is the one place
#            the app under test is chosen. It is passed with `-e`, because
#            Maestro does not read plain shell variables.
#            When unset, the default depends on the target platform, because
#            `flutter create --org com.example` gives this repo two different ids:
#              iOS      com.example.flutterBoilerplate
#              Android  com.example.flutter_boilerplate
#            The target is Android when DEVICE is listed in `adb devices`, or when
#            DEVICE is unset and the only connected target is one Android
#            device/emulator (no booted iOS simulator). Otherwise it is iOS.
#   DEVICE   Passed as `--device`. Optional when only one device is booted.
#   OUT_DIR  Where the report goes. Default: .maestro/output
#              $OUT_DIR/report.xml   JUnit
#              $OUT_DIR/debug/       maestro.log, per-flow command JSON and failure
#                                    screenshots, under .maestro/tests/<timestamp>/
#              $OUT_DIR/artifacts/   `takeScreenshot` output (screenshots/). Without
#                                    --test-output-dir those land in the current
#                                    directory, i.e. the repo root.
#
# Exits with maestro's exit code. Before maestro runs it exits 127 if maestro is
# missing, and 1 if DEVICE is a booted simulator/emulator without APP_ID
# installed. Works with the bash 3.2 that ships on macOS.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKSPACE="$ROOT/.maestro"

IOS_DEFAULT_APP_ID="com.example.flutterBoilerplate"
ANDROID_DEFAULT_APP_ID="com.example.flutter_boilerplate"

if ! command -v maestro >/dev/null 2>&1; then
  echo "error: 'maestro' is not on PATH." >&2
  echo "Install it:  curl -fsSL \"https://get.maestro.mobile.dev\" | bash" >&2
  echo "then add \$HOME/.maestro/bin to PATH. Docs: https://docs.maestro.dev" >&2
  exit 127
fi

DEVICE="${DEVICE:-}"

# Serials of the Android devices adb can talk to, one per line.
android_serials() {
  command -v adb >/dev/null 2>&1 || return 0
  adb devices 2>/dev/null | awk 'NR > 1 && $2 == "device" { print $1 }'
}

is_android_serial() {
  # No `grep -q`: exiting early can SIGPIPE the producer, and pipefail then
  # reports a match as a failure.
  android_serials | grep -xF "$1" >/dev/null
}

booted_ios_simulators() {
  command -v xcrun >/dev/null 2>&1 || { echo 0; return 0; }
  xcrun simctl list devices booted 2>/dev/null | grep -c '(Booted)' || true
}

# --- Target platform -> default APP_ID --------------------------------------
if [ -n "$DEVICE" ]; then
  # A comma-separated DEVICE list (sharding) is assumed to be one platform.
  if is_android_serial "${DEVICE%%,*}"; then
    PLATFORM=android
    PLATFORM_REASON="DEVICE is listed in adb devices"
  else
    PLATFORM=ios
    PLATFORM_REASON="DEVICE is not listed in adb devices"
  fi
else
  android_count="$(android_serials | awk 'END { print NR }')"
  ios_count="$(booted_ios_simulators)"
  if [ "$android_count" -eq 1 ] && [ "$ios_count" -eq 0 ]; then
    PLATFORM=android
    PLATFORM_REASON="the only connected target is an Android device"
  else
    PLATFORM=ios
    PLATFORM_REASON="$android_count Android device(s), $ios_count booted iOS simulator(s)"
  fi
fi

if [ -n "${APP_ID:-}" ]; then
  APP_ID_SOURCE="from the APP_ID env var"
elif [ "$PLATFORM" = android ]; then
  APP_ID="$ANDROID_DEFAULT_APP_ID"
  APP_ID_SOURCE="Android default"
else
  APP_ID="$IOS_DEFAULT_APP_ID"
  APP_ID_SOURCE="iOS default"
fi

OUT_DIR="${OUT_DIR:-$WORKSPACE/output}"
mkdir -p "$OUT_DIR"
OUT_DIR="$(cd "$OUT_DIR" && pwd)"
# A report left over from the previous run must not pass for this one.
rm -f "$OUT_DIR/report.xml"

# Airplane mode is the one device state a flow can leave behind: a flow that
# dies between common/go_offline.yaml and common/go_online.yaml keeps the device
# offline for every later run. Hand connectivity back on the way out.
#
# Android only. iOS simulators have no airplane mode, and the helpers refuse to
# run there. With DEVICE set, only the entries adb knows are touched (an iOS
# UDID is skipped). With DEVICE unset, every attached Android device is
# restored. Airplane mode off is the normal state, so that is safe on a device
# that never ran a flow.
restore_connectivity() {
  command -v adb >/dev/null 2>&1 || return 0

  local serials serial
  if [ -n "$DEVICE" ]; then
    serials="$(printf '%s' "$DEVICE" | tr ',' ' ')"
  else
    serials="$(android_serials)"
  fi

  for serial in $serials; do
    is_android_serial "$serial" || continue
    if adb -s "$serial" shell cmd connectivity airplane-mode disable >/dev/null 2>&1; then
      echo "Restored connectivity on Android device $serial (airplane mode off)."
    fi
  done
  return 0
}
trap restore_connectivity EXIT
# Let Ctrl-C and TERM go through the EXIT trap once, with the conventional code.
trap 'exit 130' INT
trap 'exit 143' TERM

echo "Maestro   : $(maestro --version 2>/dev/null | tail -n 1)"
echo "Workspace : $WORKSPACE"
echo "Device    : ${DEVICE:-<maestro picks the booted device>}"
echo "Platform  : $PLATFORM ($PLATFORM_REASON)"
echo "APP_ID    : $APP_ID ($APP_ID_SOURCE)"
echo "Report    : $OUT_DIR/report.xml"
echo "Debug     : $OUT_DIR/debug"
echo "Artifacts : $OUT_DIR/artifacts"
echo

# Preflight: is APP_ID installed on DEVICE? Without this, a wrong or missing app
# fails every flow in about a second, but the console only prints "[Failed]" and
# the JUnit report says "Unknown error". The real cause is buried in the debug
# JSON. This check only runs when DEVICE names one adb device or one booted
# simulator; anything else (no DEVICE, a device list, a physical iPhone) is left
# to Maestro.
if [ -n "$DEVICE" ] && [ "${DEVICE#*,}" = "$DEVICE" ]; then
  installed=unknown
  if [ "$PLATFORM" = android ]; then
    installed=no
    adb -s "$DEVICE" shell pm path "$APP_ID" 2>/dev/null | grep '^package:' >/dev/null && installed=yes
  elif command -v xcrun >/dev/null 2>&1 &&
    xcrun simctl list devices booted 2>/dev/null | grep -F "$DEVICE" >/dev/null; then
    installed=no
    xcrun simctl get_app_container "$DEVICE" "$APP_ID" app >/dev/null 2>&1 && installed=yes
  fi
  if [ "$installed" = no ]; then
    echo "error: $APP_ID is not installed on $DEVICE ($PLATFORM)." >&2
    echo "Install the dev build (see the write-maestro-flow playbook), or set APP_ID to the id you built." >&2
    echo "flutter create --org com.example gives $IOS_DEFAULT_APP_ID on iOS and $ANDROID_DEFAULT_APP_ID on Android." >&2
    exit 1
  fi
fi

# A flow file or directory given as the last argument replaces the workspace
# root, so `./tool/run_maestro.sh .maestro/flows/home/home_todos_happy.yaml`
# runs that one flow instead of the whole suite plus that flow.
TARGET="$WORKSPACE"
if [ "$#" -gt 0 ]; then
  last="${!#}"
  case "$last" in
    -*) ;;
    *)
      if [ -d "$last" ] || { [ -f "$last" ] && case "$last" in *.yaml | *.yml) true ;; *) false ;; esac; }; then
        TARGET="$last"
        set -- "${@:1:$(($# - 1))}"
      fi
      ;;
  esac
fi

# Build the argument list on "$@", not an array: an empty array under `set -u`
# is an error in bash 3.2. Extra CLI args stay last, so they can add tags or
# further `-e` values.
set -- \
  --format junit \
  --output "$OUT_DIR/report.xml" \
  --debug-output "$OUT_DIR/debug" \
  --test-output-dir "$OUT_DIR/artifacts" \
  -e "APP_ID=$APP_ID" \
  "$@"
if [ -n "$DEVICE" ]; then
  set -- --device "$DEVICE" "$@"
fi

status=0
maestro test "$@" "$TARGET" || status=$?
exit "$status"
