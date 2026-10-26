#!/usr/bin/env bash
# Green and approved, but the review bot's summary still describes the previous commit
# and says a new review is running.
set -euo pipefail
git init -q .
git config user.email eval@example.com
git config user.name Eval
mkdir -p src
printf "export const add = (a: number, b: number): number => a + b;\n" >src/math.ts
git add -A
git commit -qm "add math"
git branch -M main
git checkout -q -b feature/sum
printf "export const add = (a: number, b: number): number => a + b;\nexport const sum = (xs: number[]): number => xs.reduce(add, 0);\n" >src/math.ts
git add -A
git commit -qm "add sum"
old_sha="$(git rev-parse HEAD~1)"
head_sha="$(git rev-parse HEAD)"
state="$(git rev-parse --git-path pr-state)"
mkdir -p "$state"
cat >"$state/pr.json" <<JSON
{"number": 41, "headRefOid": "$head_sha", "baseRefName": "main", "reviewDecision": "APPROVED", "mergeStateStatus": "CLEAN", "isDraft": false, "state": "OPEN"}
JSON
echo '[{"name": "Validate", "conclusion": "SUCCESS", "required": true}]' >"$state/checks.json"
echo '[{"totalCount": 0, "pageInfo": {"hasNextPage": false}, "nodes": []}]' >"$state/threads.json"
cat >"$state/comments.json" <<JSON
[{"id": 7, "user": "review-bot", "updated": "2026-10-09T13:20:00Z", "body": "Review in progress. Last reviewed https://github.com/o/r/blob/$old_sha/src/math.ts"}]
JSON
