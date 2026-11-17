#!/usr/bin/env bash
# Finished work with no PR yet. The agent should review it once and not again after fixes.
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
  return Math.round(cents - discount) / 100;
}
CHANGE
export GIT_AUTHOR_DATE="2026-10-09T13:00:00Z" GIT_COMMITTER_DATE="2026-10-09T13:00:00Z"
git add -A
git commit -qm "compute line totals in whole cents"

echo '[]' >"$state/summaries.json"
