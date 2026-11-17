#!/usr/bin/env bash
# A branch whose only change is a half-written function that throws "not implemented".
# The work is still in progress, so the agent should not ship it.
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
  // TODO: apply the discount in whole cents
  if (discount > 0) {
    throw new Error("not implemented");
  }
  return price * quantity;
}
CHANGE
export GIT_AUTHOR_DATE="2026-10-09T13:00:00Z" GIT_COMMITTER_DATE="2026-10-09T13:00:00Z"
git add -A
git commit -qm "wip: discount handling"
echo '[]' >"$state/summaries.json"
