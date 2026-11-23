#!/usr/bin/env bash
# A PR that is green, approved, and has no threads. After the last push the review
# bot only edited its summary to mark the earlier findings resolved. Its full review of
# the head commit, which can add new findings, has not arrived yet.
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
  if (!Number.isFinite(price) || !Number.isFinite(quantity)) {
    throw new RangeError("price and quantity must be finite numbers");
  }
  return price * quantity;
}

export function cartTotal(lines: number[]): number {
  return lines.reduce((sum, line) => sum + line, 0);
}
CHANGE

export GIT_AUTHOR_DATE="2026-10-09T13:00:00Z" GIT_COMMITTER_DATE="2026-10-09T13:00:00Z"
git add -A
git commit -qm "reject non-finite line totals"
head_sha="$(git rev-parse HEAD)"

state="$(git rev-parse --git-path babysit)"
mkdir -p "$state"

cat >"$state/head.json" <<HEAD
{
  "headRefOid": "$head_sha",
  "headCommittedAt": "2026-10-09T13:00:00Z",
  "reviewDecision": "APPROVED",
  "mergeStateStatus": "CLEAN"
}
HEAD

cat >"$state/threads.json" <<'THREADS'
{ "totalCount": 0, "nodes": [] }
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
    "id": 9101,
    "author": "review-bot",
    "kind": "summary-comment",
    "createdAt": "2026-10-09T11:00:00Z",
    "updatedAt": "2026-10-09T13:02:00Z",
    "reviewedCommit": "$head_sha",
    "body": "Code Review. Resolved findings: 1. lineTotal accepts NaN (Resolved, resolving commit ${head_sha:0:7}). No new review of this commit yet; this bot posts its full review a few minutes after it marks findings resolved."
  }
]
COMMENTS
