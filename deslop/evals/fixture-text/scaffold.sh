#!/usr/bin/env bash
# Slop-shaped text that is data, not code. The fixture's whole purpose is to
# contain narrating comments, and a test asserts on them byte for byte.
set -euo pipefail

git init -q .
git config user.email eval@example.com
git config user.name Eval

mkdir -p src tests/fixtures
cat >src/strip-comments.ts <<'BASE'
export function stripComments(source: string): string {
  return source.replace(/^\s*\/\/.*$\n?/gm, "");
}
BASE

cat >tests/fixtures/commented.ts <<'FIXTURE'
// Increment the counter
counter += 1;
// Loop through the users
for (const user of users) {
}
FIXTURE

cat >tests/strip-comments.test.ts <<'BASETEST'
test("leaves uncommented source alone", () => {
  expect(stripComments("const a = 1;\n")).toBe("const a = 1;\n");
});
BASETEST

git add -A
git commit -qm "add comment stripper"
git branch -M main
git checkout -q -b feature/preserve-shebang

cat >>src/strip-comments.ts <<'CHANGE'

export function stripCommentsPreservingShebang(source: string): string {
  // Keep the first line when it is a shebang
  if (source.startsWith("#!")) {
    const [first, ...rest] = source.split("\n");
    return `${first}\n${stripComments(rest.join("\n"))}`;
  }
  return stripComments(source);
}
CHANGE

cat >>tests/strip-comments.test.ts <<'CHANGETEST'
test("strips every comment from the fixture", () => {
  const fixture = read("tests/fixtures/commented.ts");
  expect(stripComments(fixture)).toBe("counter += 1;\nfor (const user of users) {\n}\n");
});
CHANGETEST

git add -A
