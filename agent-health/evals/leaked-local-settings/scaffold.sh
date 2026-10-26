#!/usr/bin/env bash
# A tracked settings.local.json carries a service token in an env block.
set -euo pipefail
git init -q .
git config user.email eval@example.com
git config user.name Eval
printf "# app\n" >README.md
git add -A
git commit -qm "init"
git branch -M main
git checkout -q -b agent-setup
mkdir -p .claude .sessions/app
printf '.sessions/\n' >.gitignore
cat >CLAUDE.md <<'MD'
# Project instructions

- Run `pnpm test` before committing.
- Never push to `main`.
MD
cat >.claude/settings.json <<'JSON'
{ "permissions": { "allow": ["Bash(pnpm test)"] } }
JSON
write_transcript() {
python3 - "$1" "$2" "$3" <<'PY'
import json, os, sys, time
path, error, count = sys.argv[1], sys.argv[2], int(sys.argv[3])
ts = time.strftime("%Y-%m-%dT%H:%M:%S.000Z", time.gmtime(time.time() - 86400))
with open(path, "w") as f:
    f.write(json.dumps({"type": "user", "timestamp": ts, "message": {"role": "user", "content": "run the tests"}}) + "\n")
    for i in range(count):
        f.write(json.dumps({"type": "assistant", "timestamp": ts, "message": {"role": "assistant", "content": [
            {"type": "tool_use", "id": f"t{i}", "name": "Bash", "input": {"command": "echo ===== && pnpm test"}}]}}) + "\n")
        content = error if error else "ok"
        f.write(json.dumps({"type": "user", "timestamp": ts, "message": {"role": "user", "content": [
            {"type": "tool_result", "tool_use_id": f"t{i}", "is_error": bool(error), "content": content}]}}) + "\n")
old = time.time() - 86400
os.utime(path, (old, old))
PY
}
cat >.claude/settings.local.json <<'JSON'
{ "env": { "BILLING_SERVICE_TOKEN": "tok_live_8Qz4Lm2Vx9Rk7Tn3Wp5Hc1Yd6Fb0Gs" } }
JSON
write_transcript .sessions/app/s1.jsonl "" 3
git add -A
# Force it in: a global gitignore often lists this file, and the case is that it is tracked.
git add -f .claude/settings.local.json
