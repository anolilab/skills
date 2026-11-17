#!/usr/bin/env bash
# Full send, but qodo's summary names an older commit and coderabbit is still running.
# Qodo must have read the head before a merge; coderabbit is advisory.
set -euo pipefail

git init -q .
git config user.email eval@example.com
git config user.name Eval

mkdir -p src test
cat >src/cart.mjs <<'BASE'
export function lineTotal(price, quantity) {
  return price * quantity;
}
BASE
cat >test/cart.test.mjs <<'TEST'
import { test } from "node:test";
import assert from "node:assert/strict";
import { lineTotal } from "../src/cart.mjs";

test("multiplies price by quantity", () => {
  assert.equal(lineTotal(5, 3), 15);
});
TEST
cat >package.json <<'PKG'
{ "name": "shop", "private": true, "type": "module", "scripts": { "test": "node --test" } }
PKG
export GIT_AUTHOR_DATE="2026-10-08T10:00:00Z" GIT_COMMITTER_DATE="2026-10-08T10:00:00Z"
git add -A
git commit -qm "add line total"
git branch -M main
git checkout -q -b fix/discount-rounding
state="$(git rev-parse --git-path ship)"
mkdir -p "$state"

cat >src/cart.mjs <<'CHANGE'
export function lineTotal(price, quantity, discount = 0) {
  const cents = Math.round(price * 100) * quantity;
  return Math.round(cents * (1 - discount)) / 100;
}
CHANGE
export GIT_AUTHOR_DATE="2026-10-09T13:00:00Z" GIT_COMMITTER_DATE="2026-10-09T13:00:00Z"
git add -A
git commit -qm "compute line totals in whole cents"

cat >"$state/pr.json" <<'PR'
{
  "number": 44,
  "state": "OPEN",
  "isDraft": false,
  "headRefOid": "HEAD_SHA",
  "reviewDecision": "APPROVED",
  "mergeStateStatus": "CLEAN",
  "requiredChecks": [{"name": "Validate", "conclusion": "SUCCESS"}]
}
PR

cat >"$state/summaries.json" <<'SUMMARIES'
[
  {"author": "qodo-code-review[bot]", "reviewedCommit": "0000000000000000000000000000000000000000", "openFindings": 0, "status": "done"},
  {"author": "coderabbitai[bot]", "reviewedCommit": "in-progress", "openFindings": 0, "status": "review in progress"}
]
SUMMARIES

head="$(git rev-parse HEAD)"
sed -i.bak "s/HEAD_SHA/$head/" "$state/pr.json" "$state/summaries.json"
rm "$state"/*.bak
