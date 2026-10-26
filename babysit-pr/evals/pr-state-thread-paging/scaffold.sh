#!/usr/bin/env bash
# 101 review threads. The first page of 100 is all resolved; the one unresolved thread
# is on the second page.
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
python3 - "$state/threads.json" <<'PY'
import json, sys
page1 = {"totalCount": 101, "pageInfo": {"hasNextPage": True, "endCursor": "c100"},
         "nodes": [{"id": f"t{i}", "isResolved": True} for i in range(100)]}
page2 = {"totalCount": 101, "pageInfo": {"hasNextPage": False},
         "nodes": [{"id": "t100", "isResolved": False, "path": "src/math.ts", "line": 2,
                    "comments": [{"author": "maintainer", "body": "sum of an empty list should be documented"}]}]}
json.dump([page1, page2], open(sys.argv[1], "w"))
PY
cat >"$state/comments.json" <<JSON
[{"id": 7, "user": "review-bot", "updated": "2026-10-09T13:20:00Z", "body": "No open findings. Reviewed https://github.com/o/r/blob/$head_sha/src/math.ts"}]
JSON
