#!/usr/bin/env bash
# A file whose existing style carries almost no comments, with a change that
# added six. One of the six explains a non-obvious vendor quirk and must survive.
set -euo pipefail

git init -q .
git config user.email eval@example.com
git config user.name Eval

mkdir -p src
cat >src/cart.ts <<'BASE'
export function subtotal(items: Item[]): number {
  return items.reduce((sum, item) => sum + item.price * item.quantity, 0);
}

export function applyDiscount(total: number, percent: number): number {
  return total * (1 - percent / 100);
}
BASE

git add -A
git commit -qm "add cart maths"
git branch -M main
git checkout -q -b feature/shipping

cat >>src/cart.ts <<'CHANGE'

// Calculate the shipping cost for an order
export function shippingCost(total: number, region: Region): number {
  // Get the base rate for the region
  const base = RATES[region];

  // Check if the order qualifies for free shipping
  if (total >= FREE_SHIPPING_THRESHOLD) {
    return 0;
  }

  // The carrier rounds up to the next 50c, so match that here or the
  // invoice total disagrees with what the customer was quoted.
  const rounded = Math.ceil(base * 2) / 2;

  // Return the final shipping cost
  return rounded;
}
CHANGE

git add -A
