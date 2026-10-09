#!/usr/bin/env bash
# Behavioural checks for deslop/hooks/auto-deslop.sh. Each case runs the hook
# against a throwaway repo and asserts the exit code and the stderr message.
# Needs only bash, git, and jq or python3, the same as the hook itself.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOOK="$ROOT/deslop/hooks/auto-deslop.sh"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

failures=0
pass() { echo "ok   - $1"; }
fail() { echo "FAIL - $1" >&2; failures=$((failures + 1)); }

# run_hook <cwd> <stop_hook_active: true|false> [VAR=value ...]
# Sets RC to the exit code and ERR to whatever the hook wrote to stderr.
run_hook() {
    local cwd="$1" active="$2"
    shift 2
    ERR="$(printf '{"cwd": "%s", "stop_hook_active": %s}' "$cwd" "$active" \
        | env "$@" bash "$HOOK" 2>&1 >/dev/null)"
    RC=$?
}

# new_repo <name>: a repo with one commit and an uncommitted change to file.txt.
new_repo() {
    local dir="$WORK/$1"
    mkdir -p "$dir"
    git -C "$dir" init -q
    git -C "$dir" config user.email test@example.com
    git -C "$dir" config user.name test
    echo one >"$dir/file.txt"
    git -C "$dir" add -A
    git -C "$dir" commit -qm base
    echo two >"$dir/file.txt"
    printf '%s' "$dir"
}

# 1. The opt-out variable disables the hook even on a dirty tree.
repo="$(new_repo optout)"
run_hook "$repo" false DESLOP_AUTO=0
[ "$RC" -eq 0 ] && [ -z "$ERR" ] && pass "DESLOP_AUTO=0 exits 0 silently" \
    || fail "DESLOP_AUTO=0 should exit 0 silently (rc=$RC err=$ERR)"

run_hook "$repo" false DESLOP_AUTO=off
[ "$RC" -eq 0 ] && pass "DESLOP_AUTO=off exits 0" \
    || fail "DESLOP_AUTO=off should exit 0 (rc=$RC)"

# 2. Outside a git repository there is nothing to review.
mkdir -p "$WORK/plain"
run_hook "$WORK/plain" false
[ "$RC" -eq 0 ] && pass "non-git directory exits 0" \
    || fail "non-git directory should exit 0 (rc=$RC)"

# 3. A clean tree has nothing to deslop.
repo="$(new_repo clean)"
git -C "$repo" checkout -q -- file.txt
run_hook "$repo" false
[ "$RC" -eq 0 ] && [ -z "$ERR" ] && pass "clean tree exits 0 silently" \
    || fail "clean tree should exit 0 silently (rc=$RC err=$ERR)"

# 4. A dirty tree blocks the first stop once, with the deslop message.
repo="$(new_repo dirty)"
run_hook "$repo" false
if [ "$RC" -eq 2 ] && printf '%s' "$ERR" | grep -q 'deslop skill'; then
    pass "dirty tree blocks the first stop with the deslop message"
else
    fail "dirty tree should exit 2 with the deslop message (rc=$RC)"
fi

# 5. The same diff does not block a second time.
run_hook "$repo" false
[ "$RC" -eq 0 ] && pass "unchanged diff does not re-trigger" \
    || fail "unchanged diff should not re-trigger (rc=$RC)"

# 6. Loop guard: when the hook is already continuing, it never blocks.
repo="$(new_repo loopguard)"
run_hook "$repo" true
[ "$RC" -eq 0 ] && pass "stop_hook_active=true never blocks" \
    || fail "stop_hook_active=true should exit 0 (rc=$RC)"

# 7. After a continued stop records the post-pass state, the same tree stays quiet.
repo="$(new_repo recorded)"
run_hook "$repo" true
run_hook "$repo" false
[ "$RC" -eq 0 ] && pass "tree recorded after a continued stop stays quiet" \
    || fail "recorded tree should stay quiet (rc=$RC)"

# 8. Fail open: payloads the hook cannot parse must not block the session.
repo="$(new_repo garbage)"
printf 'not json' | bash "$HOOK" >/dev/null 2>&1
[ "$?" -eq 0 ] && pass "unparseable payload exits 0" \
    || fail "unparseable payload should exit 0"

printf '' | bash "$HOOK" >/dev/null 2>&1
[ "$?" -eq 0 ] && pass "empty payload exits 0" \
    || fail "empty payload should exit 0"

if [ "$failures" -gt 0 ]; then
    echo "$failures check(s) failed" >&2
    exit 1
fi
echo "all auto-deslop hook checks passed"
