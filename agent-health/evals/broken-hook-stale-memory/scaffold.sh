#!/usr/bin/env bash
# A Stop hook points at a deleted script, a memory names a tool path that no longer
# exists, and the user has corrected the same mistake three times.
set -euo pipefail
git init -q .
git config user.email eval@example.com
git config user.name Eval
printf "# app\n" >README.md
git add -A
git commit -qm "init"
git branch -M main
git checkout -q -b agent-setup
mkdir -p .claude/memory .sessions/app
printf '.sessions/\n' >.gitignore
cat >CLAUDE.md <<'MD'
# Project instructions

- Use pnpm, never npm.
MD
cat >.claude/settings.json <<'JSON'
{ "hooks": { "Stop": [ { "hooks": [ { "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/check-done.sh" } ] } ] } }
JSON
cat >.claude/memory/build.md <<'MD'
---
name: build-tool
description: how to build this repo
metadata:
  type: project
---

Build with `/opt/legacy-build/bin/build.sh` before running tests.
MD
python3 - .sessions/app/s1.jsonl <<'PY'
import json, os, sys, time
path = sys.argv[1]
ts = time.strftime("%Y-%m-%dT%H:%M:%S.000Z", time.gmtime(time.time() - 86400))
with open(path, "w") as f:
    for i in range(3):
        f.write(json.dumps({"type": "user", "timestamp": ts, "message": {"role": "user", "content": "add lodash"}}) + "\n")
        f.write(json.dumps({"type": "assistant", "timestamp": ts, "message": {"role": "assistant", "content": [
            {"type": "tool_use", "id": f"t{i}", "name": "Bash", "input": {"command": "npm install lodash"}}]}}) + "\n")
        f.write(json.dumps({"type": "user", "timestamp": ts, "message": {"role": "user", "content": [
            {"type": "tool_result", "tool_use_id": f"t{i}", "is_error": False, "content": "added 1 package"}]}}) + "\n")
        f.write(json.dumps({"type": "user", "timestamp": ts, "message": {"role": "user", "content": "no, I said use pnpm"}}) + "\n")
old = time.time() - 86400
os.utime(path, (old, old))
PY
git add -A
