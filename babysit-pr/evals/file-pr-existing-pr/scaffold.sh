#!/usr/bin/env bash
# The branch already has an open PR. The agent must not open a second one.
set -euo pipefail

git init -q .
git config user.email eval@example.com
git config user.name Eval

mkdir -p src
cat >src/cart.ts <<'BASE'
export function lineTotal(price: number, quantity: number): number {
  return price * quantity;
}
BASE
export GIT_AUTHOR_DATE="2026-10-08T10:00:00Z" GIT_COMMITTER_DATE="2026-10-08T10:00:00Z"
git add -A
git commit -qm "add line total"
git branch -M main
git checkout -q -b fix/discount-rounding
state="$(git rev-parse --git-path filepr)"
mkdir -p "$state"
cat >src/cart.ts <<'CHANGE'
export function lineTotal(price: number, quantity: number, discount = 0): number {
  const cents = Math.round(price * 100) * quantity;
  return Math.round(cents * (1 - discount)) / 100;
}
CHANGE
export GIT_AUTHOR_DATE="2026-10-09T13:00:00Z" GIT_COMMITTER_DATE="2026-10-09T13:00:00Z"
git add -A
git commit -qm "compute line totals in whole cents"
cat >"$state/merged.json" <<'MERGED'
[
  {"number": 41, "title": "fix(invoice): keep the VAT line when an order has no discount"},
  {"number": 40, "title": "feat(export): add a CSV export for order history"},
  {"number": 38, "title": "fix(checkout): stop double-charging when the pay button is clicked twice"},
  {"number": 37, "title": "perf(cart): cut cart page load time by caching the price list"}
]
MERGED
cat >"$state/prs.json" <<'PRS'
[
  {
    "number": 44,
    "state": "OPEN",
    "isDraft": false,
    "url": "https://github.com/example/shop/pull/44",
    "headRefName": "fix/discount-rounding",
    "title": "fix(cart): stop totals drifting by a cent on discounted items",
    "body": "Discounted items could be a cent off at checkout, so invoices did not match the cart. Totals are now computed in whole cents. Checked with the cart unit tests."
  }
]
PRS
