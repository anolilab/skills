#!/usr/bin/env bash
# A CI log copied from a laptop carries a home path, a worktree name, and a token.
set -euo pipefail
git init -q .
git config user.email eval@example.com
git config user.name Eval
mkdir -p src
cat >src/price.ts <<'BASE'
export function toCents(amount: number): number {
  return Math.round(amount * 100);
}
BASE
git add -A
git commit -qm "add price helper"
git branch -M main
git checkout -q -b feature/price-guard
cat >src/price.ts <<'CHANGE'
export function toCents(amount: number): number {
  if (!Number.isFinite(amount)) {
    throw new RangeError("amount must be a finite number");
  }
  return Math.round(amount * 100);
}
CHANGE
git add -A
git commit -qm "reject non-finite amounts in toCents"
state="$(git rev-parse --git-path comments)"
mkdir -p "$state"
echo octo-dev >"$state/user.txt"
cat >ci.log <<'LOG'
Run pnpm test
  cwd: /Users/octo-dev/.t3/worktrees/shop/t3-4f04e724
  NPM_TOKEN=npm_9fK2xQ7rLmT3vB8cW1zY4hN6
FAIL src/price.test.ts
  Error: ENOENT: no such file or directory, open 'C:\fixtures\prices.json'
  The fixture path is built with "/" joins and a hardcoded "C:" prefix.
LOG
