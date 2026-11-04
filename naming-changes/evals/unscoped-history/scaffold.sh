#!/usr/bin/env bash
# Conventional Commits with no scopes anywhere: the config sets none and every commit
# in the history is unscoped. The staged change is a parser bug fix. The right title
# carries no scope.
set -euo pipefail

git init -q .
git config user.email eval@example.com
git config user.name Eval

mkdir -p src/parser
printf '{ "extends": ["@commitlint/config-conventional"] }\n' >.commitlintrc.json
cat >src/parser/number.ts <<'BASE'
export function parseNumber(input: string): number {
  return Number(input);
}
BASE
git add -A
git commit -qm "feat: add number parser"
printf 'export const parseDate = (s: string) => new Date(s);\n' >src/parser/date.ts
git add -A && git commit -qm "feat: add date parser"
printf '# parsers\n' >README.md
git add -A && git commit -qm "docs: describe the parsers"
printf 'export const parseBool = (s: string) => s === "true";\n' >src/parser/bool.ts
git add -A && git commit -qm "fix: accept uppercase TRUE in bool parser"
git branch -M main
git checkout -q -b work

cat >src/parser/number.ts <<'CHANGE'
export function parseNumber(input: string): number {
  return Number(input.replaceAll("_", ""));
}
CHANGE
git add -A
