#!/usr/bin/env bash
# main has two files. src/report.ts sits at 990 lines and the branch pushes it past 1000.
# src/archive.ts is already 1200 lines on main and the branch only edits one line in it, so
# its size is not a finding.
set -euo pipefail
git init -q .
git config user.email eval@example.com
git config user.name Eval
mkdir -p src
{
  for i in $(seq 1 330); do
    printf 'export function row%d(x: number): string {\n  return "r" + String(x + %d);\n}\n' "$i" "$i"
  done
} >src/report.ts
{
  for i in $(seq 1 400); do
    printf 'export function entry%d(x: number): number {\n  return x * %d;\n}\n' "$i" "$i"
  done
} >src/archive.ts
printf "# our-client\n\nReport and archive helpers.\n" >README.md
git add -A
git commit -qm "report and archive helpers"
git branch -M main
git checkout -q -b add-csv-export
{
  cat <<'OURS'
export type ReportFormat = "text" | "csv" | "json";

export function renderRow(format: ReportFormat, cells: string[]): string {
  if (format === "csv") {
    return cells.map((c) => (c.includes(",") ? '"' + c.replace(/"/g, '""') + '"' : c)).join(",");
  }
  if (format === "json") {
    return JSON.stringify(cells);
  }
  return cells.join("\t");
}

export function renderHeader(format: ReportFormat, names: string[]): string {
  if (format === "csv") {
    return names.join(",");
  }
  if (format === "json") {
    return JSON.stringify(names);
  }
  return names.join("\t");
}
OURS
} >>src/report.ts
{ echo "// report helpers"; cat src/archive.ts; } >src/archive.tmp && mv src/archive.tmp src/archive.ts
git add -A
