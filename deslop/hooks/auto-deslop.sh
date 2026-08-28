#!/usr/bin/env bash
# Stop hook: when a turn ends having changed code, send Claude back to run the
# deslop skill once before the turn is allowed to finish.
#
# Fails open. Every unexpected condition exits 0 so that a broken hook can never
# wedge a session in a blocked-stop loop.

set -uo pipefail

INPUT=$(cat)

# Read one top-level string/bool field from the hook payload. jq first, python3
# as the fallback. With neither available we cannot read stop_hook_active, and
# blocking without that guard risks a loop, so the caller exits 0 instead.
read_field() {
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$INPUT" | jq -r --arg k "$1" '.[$k] // empty'
  elif command -v python3 >/dev/null 2>&1; then
    printf '%s' "$INPUT" | python3 -c \
      'import json,sys; print(json.load(sys.stdin).get(sys.argv[1], ""))' "$1"
  else
    return 1
  fi
}

lower() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }

# Hash of the branch's current diff. Empty output means "nothing changed".
diff_hash() {
  local base diff
  base=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)
  if [ -n "$base" ] && git rev-parse --verify --quiet "$base" >/dev/null 2>&1; then
    diff=$(git diff --merge-base "$base" 2>/dev/null || git diff HEAD 2>/dev/null || true)
  else
    diff=$(git diff HEAD 2>/dev/null || true)
  fi
  [ -n "$diff" ] || return 0
  if command -v shasum >/dev/null 2>&1; then
    printf '%s' "$diff" | shasum -a 256 | cut -d' ' -f1
  elif command -v sha256sum >/dev/null 2>&1; then
    printf '%s' "$diff" | sha256sum | cut -d' ' -f1
  else
    # No hasher: fall back to a length marker. Coarser, but it still suppresses
    # a repeat trigger when nothing at all has changed.
    printf 'len-%s' "${#diff}"
  fi
}

# Opt out without uninstalling the plugin.
case "$(lower "${DESLOP_AUTO:-1}")" in
  0 | false | off | no) exit 0 ;;
esac

STOP_ACTIVE=$(read_field stop_hook_active) || exit 0
CWD=$(read_field cwd) || exit 0

[ -n "$CWD" ] && cd "$CWD" 2>/dev/null || exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

GIT_DIR=$(git rev-parse --git-dir 2>/dev/null) || exit 0
STATE="$GIT_DIR/deslop-auto-last"
HASH=$(diff_hash)

# Already continuing because this hook blocked. Record where the tree landed
# after the deslop pass and let the turn end, so the next stop with the same
# code does not trigger again.
if [ "$(lower "$STOP_ACTIVE")" = "true" ]; then
  if [ -n "$HASH" ]; then printf '%s' "$HASH" >"$STATE" 2>/dev/null || true
  else rm -f "$STATE" 2>/dev/null || true
  fi
  exit 0
fi

# Nothing changed on the branch.
if [ -z "$HASH" ]; then
  rm -f "$STATE" 2>/dev/null || true
  exit 0
fi

# This exact diff was already handled.
if [ -f "$STATE" ] && [ "$(cat "$STATE" 2>/dev/null)" = "$HASH" ]; then
  exit 0
fi

printf '%s' "$HASH" >"$STATE" 2>/dev/null || true

cat >&2 <<'MSG'
This turn changed code on the branch that has not been through a deslop pass.

Use the deslop skill now on the current diff, then finish. Keep behaviour
identical, and report the result in one to three sentences.

If the changes are not code (docs, config, generated files) or a deslop pass is
genuinely not warranted here, say so in one line and stop.
MSG
exit 2
