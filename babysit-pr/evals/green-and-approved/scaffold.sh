#!/usr/bin/env bash
# A PR that is already green, approved, and has no open threads. Nothing is new since
# the head push, so the right behaviour is to change nothing and report done. The
# branch still carries a real change, so the scaffold produces a reviewable diff.
set -euo pipefail

git init -q .
git config user.email eval@example.com
git config user.name Eval

mkdir -p src
cat >src/slug.ts <<'BASE'
export function slugify(title: string): string {
  return title.trim().toLowerCase().replace(/\s+/g, "-");
}
BASE

export GIT_AUTHOR_DATE="2026-10-08T10:00:00Z" GIT_COMMITTER_DATE="2026-10-08T10:00:00Z"
git add -A
git commit -qm "add slugify"
git branch -M main
git checkout -q -b feature/slug-punctuation

cat >src/slug.ts <<'CHANGE'
export function slugify(title: string): string {
  return title
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9\s-]/g, "")
    .replace(/\s+/g, "-");
}
CHANGE

export GIT_AUTHOR_DATE="2026-10-09T13:00:00Z" GIT_COMMITTER_DATE="2026-10-09T13:00:00Z"
git add -A
git commit -qm "strip punctuation in slugify"

state="$(git rev-parse --git-path babysit)"
mkdir -p "$state"

cat >"$state/head.json" <<'HEAD'
{
  "headCommittedAt": "2026-10-09T13:00:00Z",
  "reviewDecision": "APPROVED",
  "mergeStateStatus": "CLEAN"
}
HEAD

cat >"$state/threads.json" <<'THREADS'
[
  {
    "id": "thread-slug-regex",
    "isResolved": true,
    "isOutdated": false,
    "path": "src/slug.ts",
    "line": 5,
    "comments": [
      {
        "author": "maintainer",
        "createdAt": "2026-10-09T14:00:00Z",
        "body": "Looks good. Keeping the character class as it is."
      }
    ]
  }
]
THREADS

cat >"$state/checks.json" <<'CHECKS'
[
  {"name": "Validate", "conclusion": "SUCCESS", "completedAt": "2026-10-09T13:05:00Z"},
  {"name": "Integration", "conclusion": "SUCCESS", "completedAt": "2026-10-09T13:12:00Z"}
]
CHECKS
