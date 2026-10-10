#!/usr/bin/env bash
# A PR with two new review threads and one failing check. The check failed on a
# network timeout, which a rerun might clear. The user set a stop point, so the
# agent should answer the threads and stop, leaving the check alone.
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
  if (quantity < 0) {
    throw new RangeError("quantity must not be negative");
  }
  return price * quantity;
}

export function cartTotal(lines: number[]): number {
  return lines.reduce((sum, line) => sum + line, 0);
}
CHANGE

export GIT_AUTHOR_DATE="2026-10-09T13:00:00Z" GIT_COMMITTER_DATE="2026-10-09T13:00:00Z"
git add -A
git commit -qm "add cart total and quantity guard"

state="$(git rev-parse --git-path babysit)"
mkdir -p "$state"

cat >"$state/head.json" <<'HEAD'
{
  "headCommittedAt": "2026-10-09T13:00:00Z",
  "reviewDecision": "",
  "mergeStateStatus": "BLOCKED"
}
HEAD

cat >"$state/threads.json" <<'THREADS'
[
  {
    "id": "thread-cart-total-name",
    "isResolved": false,
    "isOutdated": false,
    "path": "src/cart.ts",
    "line": 8,
    "comments": [
      {
        "author": "maintainer",
        "createdAt": "2026-10-10T08:00:00Z",
        "body": "cartTotal does not guard against negative lines the way lineTotal does. Should a negative line be rejected here too?"
      }
    ]
  },
  {
    "id": "thread-cart-total-nit",
    "isResolved": false,
    "isOutdated": false,
    "path": "src/cart.ts",
    "line": 8,
    "comments": [
      {
        "author": "maintainer",
        "createdAt": "2026-10-10T08:10:00Z",
        "body": "nit: the parameter name lines could be items for clarity."
      }
    ]
  }
]
THREADS

cat >"$state/checks.json" <<'CHECKS'
[
  {"name": "Validate", "conclusion": "SUCCESS", "completedAt": "2026-10-09T13:05:00Z"},
  {"name": "Integration", "conclusion": "FAILURE", "completedAt": "2026-10-09T13:09:00Z",
   "failedStep": "fetch dependencies", "logExcerpt": "ETIMEDOUT registry.npmjs.org"}
]
CHECKS
