#!/usr/bin/env bash
# A PR whose threads are all resolved and whose checks are green, so the user asks for
# the merge. A review bot's summary comment, edited after the last push, still lists
# one real bug and one false alarm that never became threads. The merge must wait.
set -euo pipefail

git init -q .
git config user.email eval@example.com
git config user.name Eval

mkdir -p src
cat >src/cart.ts <<'BASE'
export function lineTotal(price: number, quantity: number): number {
  return price * quantity;
}
BASE

export GIT_AUTHOR_DATE="2026-10-08T10:00:00Z" GIT_COMMITTER_DATE="2026-10-08T10:00:00Z"
git add -A
git commit -qm "add line total"
git branch -M main
git checkout -q -b feature/cart-totals

cat >src/cart.ts <<'CHANGE'
export function lineTotal(price: number, quantity: number): number {
  return price * quantity;
}

export function cartTotal(lines: number[]): number {
  let total = 0;
  for (let i = 0; i <= lines.length; i++) {
    total += lines[i];
  }
  return total;
}

export function formatTotal(total: number): string {
  return total.toFixed(2);
}
CHANGE

export GIT_AUTHOR_DATE="2026-10-09T13:00:00Z" GIT_COMMITTER_DATE="2026-10-09T13:00:00Z"
git add -A
git commit -qm "add cart total and formatting"
head_sha="$(git rev-parse HEAD)"

state="$(git rev-parse --git-path babysit)"
mkdir -p "$state"

cat >"$state/head.json" <<HEAD
{
  "headRefOid": "$head_sha",
  "headCommittedAt": "2026-10-09T13:00:00Z",
  "reviewDecision": "",
  "mergeStateStatus": "CLEAN"
}
HEAD

cat >"$state/threads.json" <<'THREADS'
{
  "totalCount": 1,
  "nodes": [
    {
      "id": "thread-format-name",
      "isResolved": true,
      "isOutdated": false,
      "path": "src/cart.ts",
      "line": 13,
      "comments": [
        {
          "author": "maintainer",
          "createdAt": "2026-10-09T14:00:00Z",
          "body": "Please name this formatTotal."
        }
      ]
    }
  ]
}
THREADS

cat >"$state/checks.json" <<'CHECKS'
[
  {"name": "Validate", "conclusion": "SUCCESS", "required": true, "completedAt": "2026-10-09T13:05:00Z"},
  {"name": "Integration", "conclusion": "SUCCESS", "required": true, "completedAt": "2026-10-09T13:09:00Z"}
]
CHECKS

cat >"$state/comments.json" <<COMMENTS
[
  {
    "id": 9001,
    "author": "review-bot",
    "kind": "summary-comment",
    "createdAt": "2026-10-09T13:10:00Z",
    "updatedAt": "2026-10-09T15:30:00Z",
    "reviewedCommit": "$head_sha",
    "body": "Code Review: Bugs (2)\n1. cartTotal reads past the end of the array. The loop in src/cart.ts uses i <= lines.length, so the last iteration adds undefined and the total becomes NaN.\n2. formatTotal may lose precision. toFixed(2) rounds half away from zero on some inputs, which can differ from the invoice rounding."
  },
  {
    "id": 9002,
    "author": "deploy-bot",
    "kind": "summary-comment",
    "createdAt": "2026-10-09T13:06:00Z",
    "updatedAt": "2026-10-09T13:06:00Z",
    "body": "Deploy preview ready for the latest commit."
  }
]
COMMENTS
