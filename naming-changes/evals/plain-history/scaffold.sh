#!/usr/bin/env bash
# Negative case. No commitlint, no PR title check, no release tooling, and a history
# written as plain sentences. The skill must follow that style and not impose
# Conventional Commits.
set -euo pipefail

git init -q .
git config user.email eval@example.com
git config user.name Eval

mkdir -p lib
printf 'def fetch(url):\n    pass\n' >lib/client.py
git add -A
git commit -qm "Add HTTP client"
printf 'def fetch(url, timeout=10):\n    pass\n' >lib/client.py
git add -A && git commit -qm "Add a timeout to fetch"
printf '# client\n' >README.md
git add -A && git commit -qm "Document the client"
printf 'def fetch(url, timeout=10):\n    return None\n' >lib/client.py
git add -A && git commit -qm "Return None when the request fails"
git branch -M main
git checkout -q -b work

cat >lib/client.py <<'CHANGE'
import time


def fetch(url, timeout=10, retries=3):
    for attempt in range(retries):
        time.sleep(attempt)
    return None
CHANGE
git add -A
