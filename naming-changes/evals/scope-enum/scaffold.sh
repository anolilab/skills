#!/usr/bin/env bash
# A monorepo whose commitlint config closes the scope list. The staged change adds a
# component to the web app. The only valid scope is `web`; `ui` or `components` fail
# the linter even though they describe the change.
set -euo pipefail

git init -q .
git config user.email eval@example.com
git config user.name Eval

mkdir -p apps/web/src apps/api/src
cat >commitlint.config.js <<'BASE'
export default {
  extends: ["@commitlint/config-conventional"],
  rules: {
    "scope-enum": [2, "always", ["api", "web", "deps", "release"]],
  },
};
BASE
printf '{ "name": "@acme/web", "private": true }\n' >apps/web/package.json
printf '{ "name": "@acme/api", "private": true }\n' >apps/api/package.json
printf 'export const health = () => "ok";\n' >apps/api/src/health.ts
git add -A
git commit -qm "chore: set up workspace"
printf 'export const Home = () => null;\n' >apps/web/src/Home.tsx
git add -A && git commit -qm "feat(web): add home page"
printf 'export const version = () => "1";\n' >apps/api/src/version.ts
git add -A && git commit -qm "feat(api): expose version endpoint"
printf 'export const Layout = () => null;\n' >apps/web/src/Layout.tsx
git add -A && git commit -qm "fix(web): keep layout above the footer"
git branch -M main
git checkout -q -b work

cat >apps/web/src/DeployCard.tsx <<'CHANGE'
export function DeployCard({ name, ok }: { name: string; ok: boolean }) {
  return <div className="rounded-md border p-4">{name}: {ok ? "succeeded" : "failed"}</div>;
}
CHANGE
git add -A
