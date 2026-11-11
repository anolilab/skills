#!/usr/bin/env bash
# main has a paginated list helper and an unrelated legacy module with a SQL injection
# that this branch does not touch. The branch changes the pagination loop's stop condition,
# which drops every page after the first whenever a page is full. The legacy module must
# not be reported: it is outside the diff.
set -euo pipefail
git init -q .
git config user.email eval@example.com
git config user.name Eval
mkdir -p src
cat >src/pages.ts <<'OURS'
export type Fetcher<T> = (page: number, size: number) => Promise<T[]>;

export async function listAll<T>(fetchPage: Fetcher<T>, size = 100): Promise<T[]> {
  const out: T[] = [];
  let page = 1;
  let hasMore = true;
  while (hasMore) {
    const items = await fetchPage(page, size);
    out.push(...items);
    hasMore = items.length === size;
    page += 1;
  }
  return out;
}
OURS
cat >src/legacy.ts <<'OURS'
import { db } from "./db";

export function findUserByName(name: string) {
  return db.query("SELECT * FROM users WHERE name = '" + name + "'");
}
OURS
printf "# our-client\n\nA small client with paginated listing.\n" >README.md
git add -A
git commit -qm "paginated listing helper"
git branch -M main
git checkout -q -b fix-listing
cat >src/pages.ts <<'OURS'
export type Fetcher<T> = (page: number, size: number) => Promise<T[]>;

export async function listAll<T>(fetchPage: Fetcher<T>, size = 100): Promise<T[]> {
  const out: T[] = [];
  let page = 1;
  let hasMore = true;
  while (hasMore) {
    const items = await fetchPage(page, size);
    out.push(...items);
    hasMore = items.length > size;
    page += 1;
  }
  return out;
}
OURS
git add -A
