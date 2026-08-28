#!/usr/bin/env bash
# A chained cast that launders an unparsed response into a typed one, next to a
# cast that is already justified by a SAFETY comment.
set -euo pipefail

git init -q .
git config user.email eval@example.com
git config user.name Eval

mkdir -p src
cat >src/orders.ts <<'BASE'
import { orderSchema } from "./schema.ts";

export async function fetchOrder(id: OrderId): Promise<Order> {
  const response = await http.get(`/orders/${id}`);
  return orderSchema.parse(response.body);
}
BASE

git add -A
git commit -qm "add order fetching"
git branch -M main
git checkout -q -b feature/order-batch

cat >>src/orders.ts <<'CHANGE'

export async function fetchOrderBatch(ids: OrderId[]): Promise<Order[]> {
  const response = await http.post("/orders/batch", { ids });
  return response.body as unknown as Order[];
}

export function orderKey(order: Order): OrderKey {
  // SAFETY: orderSchema guarantees a non-empty id, and OrderKey is a branded
  // string over exactly that shape.
  return order.id as OrderKey;
}
CHANGE

git add -A
