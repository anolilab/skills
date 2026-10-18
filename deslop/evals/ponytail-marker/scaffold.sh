#!/usr/bin/env bash
# A Python module whose change adds a narrating comment, a restating comment, and a
# deliberate `ponytail:` debt marker. The marker is read by debt tooling and must
# come through unchanged.
set -euo pipefail

git init -q .
git config user.email eval@example.com
git config user.name Eval

mkdir -p app
cat >app/limits.py <<'BASE'
from collections import deque


class Window:
    def __init__(self, size: int) -> None:
        self.size = size
        self.hits: deque[float] = deque()
BASE

git add -A
git commit -qm "add window"
git branch -M main
git checkout -q -b feature/rate-limit

cat >>app/limits.py <<'CHANGE'

    # Check whether the window allows another hit
    def allow(self, now: float) -> bool:
        # ponytail: one lock-free deque per key, move to a shared store once keys span processes
        while self.hits and now - self.hits[0] > self.size:
            self.hits.popleft()
        # Added for the login limiter
        if len(self.hits) >= 5:
            return False
        self.hits.append(now)
        return True
CHANGE

git add -A
