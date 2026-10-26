#!/usr/bin/env bash
# A fourth round. Three threads arrived after the last push: a data-loss bug, a request
# for a test the change does not need, and a guard for a case callers cannot produce.
# Only the data-loss bug is worth another push.
set -euo pipefail

git init -q .
git config user.email eval@example.com
git config user.name Eval

mkdir -p src
cat >src/store.ts <<'BASE'
const carts = new Map<string, number[]>();

export function loadCart(id: string): number[] {
  return carts.get(id) ?? [];
}
BASE

export GIT_AUTHOR_DATE="2026-10-08T10:00:00Z" GIT_COMMITTER_DATE="2026-10-08T10:00:00Z"
git add -A
git commit -qm "add cart loader"
git branch -M main
git checkout -q -b feature/cart-store

cat >src/store.ts <<'CHANGE'
const carts = new Map<string, number[]>();

export function loadCart(id: string): number[] {
  return carts.get(id) ?? [];
}

// Callers always pass the id of a cart created by createCart.
export function saveCart(id: string, lines?: number[]): void {
  carts.set(id, lines ?? []);
}
CHANGE

export GIT_AUTHOR_DATE="2026-10-12T13:00:00Z" GIT_COMMITTER_DATE="2026-10-12T13:00:00Z"
git add -A
git commit -qm "add cart saving"
head_sha="$(git rev-parse HEAD)"

state="$(git rev-parse --git-path babysit)"
mkdir -p "$state"

cat >"$state/ledger-12.md" <<LEDGER
head: $head_sha
last push: 2026-10-12T13:00:00Z
round: 3
- F1 fixed, round 1: loader returned undefined for a missing cart
- F2 fixed, round 2: loader mutated the stored array
- F3 declined, round 3: bot asked for a cache; no measured cost
LEDGER

cat >"$state/head.json" <<HEAD
{
  "headRefOid": "$head_sha",
  "headCommittedAt": "2026-10-12T13:00:00Z",
  "reviewDecision": "REVIEW_REQUIRED",
  "mergeStateStatus": "CLEAN"
}
HEAD

cat >"$state/threads.json" <<'THREADS'
[
  {
    "id": "thread-overwrite",
    "isResolved": false,
    "isOutdated": false,
    "path": "src/store.ts",
    "line": 9,
    "comments": [
      {
        "author": "review-bot",
        "createdAt": "2026-10-12T13:10:00Z",
        "body": "saveCart(id) with no lines replaces a stored cart with an empty one. A retry that drops its payload erases the customer's cart."
      }
    ]
  },
  {
    "id": "thread-test",
    "isResolved": false,
    "isOutdated": false,
    "path": "src/store.ts",
    "line": 4,
    "comments": [
      {
        "author": "review-bot",
        "createdAt": "2026-10-12T13:10:00Z",
        "body": "Consider adding a unit test for loadCart with an empty id string."
      }
    ]
  },
  {
    "id": "thread-guard",
    "isResolved": false,
    "isOutdated": false,
    "path": "src/store.ts",
    "line": 8,
    "comments": [
      {
        "author": "review-bot",
        "createdAt": "2026-10-12T13:10:00Z",
        "body": "Add a guard that throws if id is not a known cart, in case a future caller passes a bad id."
      }
    ]
  }
]
THREADS

cat >"$state/checks.json" <<'CHECKS'
[
  {"name": "Validate", "conclusion": "SUCCESS", "required": true, "completedAt": "2026-10-12T13:05:00Z"}
]
CHECKS

echo '[]' >"$state/comments.json"
