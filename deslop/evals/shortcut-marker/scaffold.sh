#!/usr/bin/env bash
# A file whose base carries no comments, with a change that adds a restating
# comment, a narrating comment, and a deliberate shortcut marker. The marker is a
# debt-ledger entry and must come through unchanged.
set -euo pipefail

git init -q .
git config user.email eval@example.com
git config user.name Eval

mkdir -p src
cat >src/search.ts <<'BASE'
export interface User {
  id: string;
  email: string;
}

export function findUserByEmail(users: User[], email: string): User | undefined {
  return users.find((user) => user.email === email);
}
BASE

git add -A
git commit -qm "add user search"
git branch -M main
git checkout -q -b feature/admin-export

cat >>src/search.ts <<'CHANGE'

// Find all users whose email matches the given address
export function findAllByEmail(users: User[], email: string): User[] {
  // shortcut: linear scan over the list, switch to an email index once the list passes ~10k users
  const matches: User[] = [];
  for (const user of users) {
    if (user.email === email) {
      matches.push(user);
    }
  }
  // Added for the admin export
  return matches;
}
CHANGE

git add -A
