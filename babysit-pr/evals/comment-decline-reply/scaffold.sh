#!/usr/bin/env bash
# A thread reply that declines a bot finding the code already handles.
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
