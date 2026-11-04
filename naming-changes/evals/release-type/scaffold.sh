#!/usr/bin/env bash
# A semantic-release package. The staged change only touches the CI workflow. Naming
# it `fix` or `feat` would publish an empty release, so the right type is `ci`.
set -euo pipefail

git init -q .
git config user.email eval@example.com
git config user.name Eval

mkdir -p src .github/workflows
cat >package.json <<'BASE'
{
  "name": "tiny-retry",
  "version": "1.4.0",
  "release": { "branches": ["main"] },
  "devDependencies": { "semantic-release": "^24.0.0" }
}
BASE
printf 'export const retry = () => {};\n' >src/index.ts
cat >.github/workflows/ci.yml <<'BASE'
name: ci
on: [push]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm test
BASE
git add -A
git commit -qm "feat: add retry helper"
printf 'export const retry = () => {}; // jitter\n' >src/index.ts
git add -A && git commit -qm "fix: add jitter to retry delay"
git branch -M main
git checkout -q -b work

cat >.github/workflows/ci.yml <<'CHANGE'
name: ci
on: [push]
jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node: [20, 22]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node }}
      - run: npm test
CHANGE
git add -A
