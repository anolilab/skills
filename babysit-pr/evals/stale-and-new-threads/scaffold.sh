#!/usr/bin/env bash
# A PR whose head was pushed at 13:00 UTC on 2026-10-09. One old thread is for a
# problem the head already fixed. One new thread is a real rounding bug. The live
# GitHub API is unreachable here, so the PR state is a snapshot under .git/babysit.
set -euo pipefail

git init -q .
git config user.email eval@example.com
git config user.name Eval

mkdir -p src
cat >src/price.ts <<'BASE'
export function toCents(amount: number): number {
  return Math.round(amount * 100);
}
BASE

export GIT_AUTHOR_DATE="2026-10-08T10:00:00Z" GIT_COMMITTER_DATE="2026-10-08T10:00:00Z"
git add -A
git commit -qm "add price helper"
git branch -M main
git checkout -q -b feature/price-guard

cat >src/price.ts <<'CHANGE'
export function toCents(amount: number): number {
  if (!Number.isFinite(amount)) {
    throw new RangeError(`amount must be finite, got ${amount}`);
  }
  return Math.round(amount * 100);
}
CHANGE

export GIT_AUTHOR_DATE="2026-10-09T13:00:00Z" GIT_COMMITTER_DATE="2026-10-09T13:00:00Z"
git add -A
git commit -qm "guard non-finite amounts in toCents"

state="$(git rev-parse --git-path babysit)"
mkdir -p "$state"

cat >"$state/head.json" <<'HEAD'
{
  "headCommittedAt": "2026-10-09T13:00:00Z",
  "reviewDecision": "",
  "mergeStateStatus": "CLEAN"
}
HEAD

cat >"$state/threads.json" <<'THREADS'
[
  {
    "id": "thread-old-nan",
    "isResolved": false,
    "isOutdated": true,
    "path": "src/price.ts",
    "line": 2,
    "comments": [
      {
        "author": "review-bot",
        "createdAt": "2026-10-09T09:00:00Z",
        "body": "toCents does not reject NaN; NaN propagates into the cart total."
      }
    ]
  },
  {
    "id": "thread-new-rounding",
    "isResolved": false,
    "isOutdated": false,
    "path": "src/price.ts",
    "line": 4,
    "comments": [
      {
        "author": "maintainer",
        "createdAt": "2026-10-10T08:00:00Z",
        "body": "Math.round rounds halves toward positive infinity, so toCents(-0.125) gives -12 when it should give -13. Refunds come out one cent off."
      }
    ]
  }
]
THREADS

cat >"$state/checks.json" <<'CHECKS'
[
  {"name": "Validate", "conclusion": "SUCCESS", "completedAt": "2026-10-09T13:05:00Z"}
]
CHECKS
