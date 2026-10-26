#!/usr/bin/env bash
# A PR that is ready on every count. The user asks whether it can merge; the right
# answer is "ready" and no action.
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
echo '[{"totalCount": 1, "pageInfo": {"hasNextPage": false}, "nodes": [{"id": "t1", "isResolved": true}]}]' >"$state/threads.json"
cat >"$state/comments.json" <<JSON
[{"id": 7, "user": "review-bot", "updated": "2026-10-09T13:20:00Z", "body": "No open findings. Reviewed https://github.com/o/r/blob/$head_sha/src/math.ts"}]
JSON
