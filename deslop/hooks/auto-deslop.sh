#!/usr/bin/env bash
# Stop hook: when a turn ends with code on the branch that has not been through a
# deslop pass, send Claude back to run the deslop skill once before the turn is
# allowed to finish. The scope is the branch's own files changed since the last
# recorded pass, so a small follow-up edit does not re-review the whole branch.
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

# Run a command with a 5 second cap. timeout is not installed by default on macOS,
# so fall back to perl's alarm, which is.
capped() {
  if command -v timeout >/dev/null 2>&1; then timeout 5 "$@"
  elif command -v perl >/dev/null 2>&1; then perl -e 'alarm 5; exec @ARGV' -- "$@"
  else "$@"
  fi
}

# Hash the input on stdin. Coarse fallback when no hasher exists, but it still
# suppresses a repeat trigger when nothing at all has changed.
hash_stdin() {
  if command -v shasum >/dev/null 2>&1; then shasum -a 256 | cut -d' ' -f1
  elif command -v sha256sum >/dev/null 2>&1; then sha256sum | cut -d' ' -f1
  else wc -c | tr -d ' '
  fi
}

# Base branch the work merges into. Same order as the deslop skill: the open PR's
# base, then origin's default branch, then main. A successful PR lookup is cached
# per branch. A failed one is not, so a branch that gets a PR later is picked up.
resolve_base() {
  local branch cache base
  branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null || echo detached)
  cache="$GIT_DIR/deslop-base-${branch//\//_}"
  if [ -s "$cache" ]; then cat "$cache"; return; fi
  if command -v gh >/dev/null 2>&1; then
    base=$(capped gh pr view --json baseRefName --jq .baseRefName 2>/dev/null || true)
    if [ -n "$base" ]; then
      printf '%s' "$base" >"$cache" 2>/dev/null || true
      printf '%s' "$base"
      return
    fi
  fi
  base=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)
  base=${base#origin/}
  printf '%s' "${base:-main}"
}

# Hash of the whole branch state: the diff against the base, plus untracked files
# by name and content. Empty output means there is nothing to review.
branch_state() {
  local diff untracked
  diff=$(git diff --merge-base "$REF" 2>/dev/null || git diff HEAD 2>/dev/null || true)
  untracked=$(git ls-files --others --exclude-standard 2>/dev/null)
  [ -n "$diff$untracked" ] || return 0
  {
    printf '%s\n' "$diff"
    printf '%s\n' "$untracked" | while IFS= read -r f; do
      [ -n "$f" ] || continue
      printf '%s\n' "$f"
      cat -- "$f" 2>/dev/null
    done
  } | hash_stdin
}

# Files in scope: the branch's own changed files (against its base, plus untracked),
# narrowed to those changed since the last recorded pass when a snapshot still
# exists. Intersecting keeps upstream changes that arrive with a rebase out of scope.
scope_files() {
  local snap=$1 branch since
  branch=$({
    git diff --name-only --merge-base "$REF" 2>/dev/null || git diff --name-only HEAD 2>/dev/null || true
    git ls-files --others --exclude-standard 2>/dev/null
  } | LC_ALL=C sort -u)
  if [ -n "$snap" ] && git cat-file -e "$snap^{commit}" 2>/dev/null; then
    since=$({
      git diff --name-only "$snap" 2>/dev/null || true
      git ls-files --others --exclude-standard 2>/dev/null
    } | LC_ALL=C sort -u)
    LC_ALL=C comm -12 <(printf '%s\n' "$branch") <(printf '%s\n' "$since")
  else
    printf '%s\n' "$branch"
  fi
}

# Snapshot of the working tree as a commit object, without touching the index or
# any ref. Falls back to HEAD on a clean tree.
take_snapshot() {
  local snap
  snap=$(git stash create 2>/dev/null || true)
  [ -n "$snap" ] || snap=$(git rev-parse --verify --quiet HEAD 2>/dev/null || true)
  printf '%s' "$snap"
}

# Records the branch state and a snapshot of the tree. Called on a block, so the
# state is recorded before the pass (a stop that never continues is not re-blocked),
# and again on the continued stop, which overwrites it with the post-pass tree.
record_state() {
  printf '%s' "$HASH" >"$STATE" 2>/dev/null || true
  take_snapshot >"$SNAP_STATE" 2>/dev/null || true
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
SNAP_STATE="$GIT_DIR/deslop-auto-snap"

REF_BASE=$(resolve_base)
REF="origin/$REF_BASE"
git rev-parse -q --verify "$REF" >/dev/null 2>&1 || REF="$REF_BASE"

HASH=$(branch_state)

# Already continuing because this hook blocked. Record where the tree landed
# after the deslop pass and let the turn end, so the next stop with the same
# code does not trigger again.
if [ "$(lower "$STOP_ACTIVE")" = "true" ]; then
  if [ -n "$HASH" ]; then record_state
  else rm -f "$STATE" "$SNAP_STATE" 2>/dev/null || true
  fi
  exit 0
fi

# Nothing changed on the branch.
if [ -z "$HASH" ]; then
  rm -f "$STATE" "$SNAP_STATE" 2>/dev/null || true
  exit 0
fi

# This exact branch state was already handled.
if [ -f "$STATE" ] && [ "$(cat "$STATE" 2>/dev/null)" = "$HASH" ]; then
  exit 0
fi

SNAP=""
[ -f "$SNAP_STATE" ] && SNAP=$(cat "$SNAP_STATE" 2>/dev/null || true)
SINCE_PASS=false
if [ -n "$SNAP" ] && git cat-file -e "$SNAP^{commit}" 2>/dev/null; then SINCE_PASS=true; fi

# Docs, lockfiles, snapshots, images and generated output have no slop to cut. Leaving
# them to the model costs a full turn that ends in "not warranted".
NONCODE='(\.(md|mdx|lock|lockb|snap|svg|png|jpe?g|gif|ico|woff2?)$|(^|/)(package-lock\.json|pnpm-lock\.yaml)$|(^|/)(_generated|generated|__snapshots__|dist|\.changeset)/)'
FILES=$(scope_files "$SNAP" | grep -v '^$' | grep -Ev "$NONCODE" || true)
COUNT=$(printf '%s\n' "$FILES" | grep -c . || true)

# Only upstream changes moved, or nothing in scope: nothing for this branch to review.
if [ "$COUNT" -eq 0 ]; then
  record_state
  exit 0
fi

record_state

if [ "$SINCE_PASS" = true ]; then
  SCOPE_NOTE="changes since the last deslop pass on this branch"
  DIFF_CMD="git diff ${SNAP:0:12} -- <the files above>"
else
  SCOPE_NOTE="the branch's changes against $REF"
  DIFF_CMD="git diff --merge-base $REF -- <the files above>"
fi

{
  echo "This branch has code changes that have not been through a deslop pass: $SCOPE_NOTE, $COUNT file(s)."
  echo
  echo "Files in scope:"
  printf '%s\n' "$FILES" | head -n 40 | sed 's/^/  /'
  if [ "$COUNT" -gt 40 ]; then echo "  ... and $((COUNT - 40)) more"; fi
  echo
  echo "Diff: $DIFF_CMD"
  echo
  if [ "$COUNT" -gt 20 ]; then
    echo "More than 20 files: batch them by directory, run every batch, and do not stop to ask which batch to start with."
    echo
  fi
  echo "Use the deslop skill on the files above now, then finish. Review only those files,"
  echo "but read their untouched neighbours for conventions. Keep behaviour identical, and"
  echo "report the result in one to three sentences."
  echo
  echo "If the changes are not code (docs, config, generated files) or a deslop pass is"
  echo "genuinely not warranted here, say so in one line and stop."
} >&2
exit 2
