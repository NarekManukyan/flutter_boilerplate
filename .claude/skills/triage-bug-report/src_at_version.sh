#!/usr/bin/env bash
# Expose the source a bug reporter was actually running, in a throwaway detached
# git worktree, so code reads and file:line citations match their build.
#
#   src_at_version.sh setup   <version> <label>   # prints CODE_REF, CODE_SHA, CODE_EXACT, CODE_ROOT
#   src_at_version.sh cleanup <label>             # removes that worktree
#
# <version>  anything containing X.Y.Z, e.g. "1.4.2", "v1.4.2", "1.4.2+57", "1.4.2 (57)".
#            Resolves to tag X.Y.Z, then vX.Y.Z; otherwise the default branch
#            (CODE_EXACT=no, so line numbers may have drifted).
# <label>    a ticket id or any short name; [A-Za-z0-9._-] only.
#
# Non-destructive: never touches the current working tree or branch, never fetches.
# Worktrees live under $TRIAGE_WORKDIR (default: ${TMPDIR:-/tmp}/triage-bug-report).
set -euo pipefail

die() { echo "error: $*" >&2; exit 2; }

REPO="$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel 2>/dev/null)" \
  || die "not inside a git repository"
WORKDIR="${TRIAGE_WORKDIR:-${TMPDIR:-/tmp}}"
WORKDIR="${WORKDIR%/}"
[ -n "${TRIAGE_WORKDIR:-}" ] || WORKDIR="$WORKDIR/triage-bug-report"

check_label() {
  case "$1" in
    ''|*[!A-Za-z0-9._-]*|.|..) die "label must match [A-Za-z0-9._-]+ (got: '$1')" ;;
  esac
}

default_branch() {
  local ref
  # origin/HEAD, when the clone recorded it
  if ref="$(git -C "$REPO" symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null)"; then
    echo "$ref"; return 0
  fi
  for ref in origin/main origin/master main master; do
    if git -C "$REPO" rev-parse -q --verify "$ref^{commit}" >/dev/null; then
      echo "$ref"; return 0
    fi
  done
  return 1
}

cmd="${1:-}"
case "$cmd" in
  setup)
    [ $# -eq 3 ] || die "usage: $0 setup <version> <label>"
    version="$2"; label="$3"; check_label "$label"

    semver="$(printf '%s\n' "$version" | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' | head -n 1 || true)"
    ref=""; exact="no"
    if [ -n "$semver" ]; then
      for cand in "$semver" "v$semver"; do
        if git -C "$REPO" rev-parse -q --verify "refs/tags/$cand^{commit}" >/dev/null; then
          ref="$cand"; exact="yes"; break
        fi
      done
      [ -n "$ref" ] || echo "note: no tag $semver or v$semver locally (git fetch --tags may help); using the default branch" >&2
    else
      echo "note: no X.Y.Z in '$version'; using the default branch" >&2
    fi
    if [ -z "$ref" ]; then
      ref="$(default_branch)" || die "cannot find a default branch (origin/HEAD, main or master)"
    fi

    wt="$WORKDIR/$label/src"
    git -C "$REPO" worktree remove --force "$wt" >/dev/null 2>&1 || true
    rm -rf "$wt"
    git -C "$REPO" worktree prune
    mkdir -p "$(dirname "$wt")"
    git -C "$REPO" worktree add --detach "$wt" "$ref^{commit}" >/dev/null 2>&1 \
      || die "git worktree add failed for $ref"

    echo "CODE_REF=$ref"
    echo "CODE_SHA=$(git -C "$wt" rev-parse --short HEAD)"
    echo "CODE_EXACT=$exact"
    echo "CODE_ROOT=$wt"
    ;;
  cleanup)
    [ $# -eq 2 ] || die "usage: $0 cleanup <label>"
    label="$2"; check_label "$label"
    wt="$WORKDIR/$label/src"
    git -C "$REPO" worktree remove --force "$wt" >/dev/null 2>&1 || true
    rm -rf "$wt"
    git -C "$REPO" worktree prune
    rmdir "$WORKDIR/$label" 2>/dev/null || true   # only if nothing else (e.g. findings.md) is left
    echo "removed $wt"
    ;;
  *)
    die "usage: $0 setup <version> <label> | cleanup <label>"
    ;;
esac
