#!/usr/bin/env bash
# A PR that is green, approved, and has no threads. The review bot's summary still
# describes the previous commit and says a new review is running, and a deploy bot
# has commented. Nothing is actionable yet, and the PR is not finished.
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
  return lines.reduce((sum, line) => sum + line, 0);
}
CHANGE

export GIT_AUTHOR_DATE="2026-10-09T13:00:00Z" GIT_COMMITTER_DATE="2026-10-09T13:00:00Z"
git add -A
git commit -qm "add cart total"
old_sha="$(git rev-parse HEAD~1)"
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
    "id": 9001,
    "author": "review-bot",
    "kind": "summary-comment",
    "createdAt": "2026-10-09T11:00:00Z",
    "updatedAt": "2026-10-09T13:20:00Z",
    "reviewedCommit": "$old_sha",
    "body": "Review in progress. This summary covers an earlier commit and will update when the new review finishes."
  },
  {
    "id": 9002,
    "author": "deploy-bot",
    "kind": "summary-comment",
    "createdAt": "2026-10-09T13:06:00Z",
    "updatedAt": "2026-10-09T13:21:00Z",
    "body": "Deploy preview ready for the latest commit."
  }
]
COMMENTS
