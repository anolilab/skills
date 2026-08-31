#!/usr/bin/env bash
# Two added functions. One carries a single tell that the file's own habit
# explains, and must survive. The other stacks three independent tells and
# must be cleaned.
set -euo pipefail

git init -q .
git config user.email eval@example.com
git config user.name Eval

mkdir -p src

# A file that names every step, including steps used exactly once.
cat >src/pipeline.ts <<'BASE'
import type { Row } from "./types";

function normalizeRow(row: Row): Row {
  return { ...row, key: row.key.trim().toLowerCase() };
}

function stampReceivedAt(row: Row, at: Date): Row {
  return { ...row, receivedAt: at.toISOString() };
}

export function ingest(rows: Row[], at: Date): Row[] {
  return rows.map(normalizeRow).map((row) => stampReceivedAt(row, at));
}
BASE

# A file that comments nothing, trusts its callers, and types everything.
cat >src/export.ts <<'BASE'
import type { Row } from "./types";

export function toTsv(rows: Row[]): string {
  return rows.map((row) => `${row.key}\t${row.value}`).join("\n");
}
BASE

cat >src/types.ts <<'BASE'
export interface Row {
  key: string;
  value: string;
  receivedAt?: string;
}
BASE

git add -A
git commit -qm "add ingest pipeline and tsv export"
git branch -M main
git checkout -q -b feature/csv

# One tell, and the file's two existing single-use helpers explain it.
cat >src/pipeline.ts <<'CHANGE'
import type { Row } from "./types";

function normalizeRow(row: Row): Row {
  return { ...row, key: row.key.trim().toLowerCase() };
}

function stampReceivedAt(row: Row, at: Date): Row {
  return { ...row, receivedAt: at.toISOString() };
}

function dropEmptyValues(rows: Row[]): Row[] {
  return rows.filter((row) => row.value !== "");
}

export function ingest(rows: Row[], at: Date): Row[] {
  return dropEmptyValues(rows)
    .map(normalizeRow)
    .map((row) => stampReceivedAt(row, at));
}
CHANGE

# Three tells stacked in one function, in a file that has none of them.
cat >src/export.ts <<'CHANGE'
import type { Row } from "./types";

export function toTsv(rows: Row[]): string {
  return rows.map((row) => `${row.key}\t${row.value}`).join("\n");
}

export function toCsv(rows: Row[]): string {
  // Guard against missing input before building the CSV rows.
  if (!rows || rows.length === 0) {
    return "";
  }

  // Build each line by joining the key and the value with a comma.
  const lines = rows.map((row) => `${row.key},${(row as any).value}`);

  return lines.join("\n");
}
CHANGE

git add -A
