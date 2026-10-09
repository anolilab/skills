#!/usr/bin/env bash
# A change that adds two restating comments. The user has already restored one of
# them, so it is recorded in the keep-list and must survive a fresh pass.
set -euo pipefail

git init -q .
git config user.email eval@example.com
git config user.name Eval

mkdir -p src
cat >src/cart.ts <<'BASE'
export function subtotal(items: Item[]): number {
  return items.reduce((sum, item) => sum + item.price * item.quantity, 0);
}
BASE

git add -A
git commit -qm "add cart maths"
git branch -M main
git checkout -q -b feature/totals

cat >>src/cart.ts <<'CHANGE'

// Walk the items in order and add up the line totals
export function lineTotal(items: Item[]): number {
  // Keep a running sum of the line totals
  let total = 0;
  for (const item of items) {
    total += item.price * item.quantity;
  }
  // Return the total
  return total;
}
CHANGE

git add -A

# The user restored this comment earlier, so the keep-list records it.
printf '%s\t%s\n' "src/cart.ts" "// Walk the items in order and add up the line totals" \
  >>"$(git rev-parse --git-path deslop-keep)"
