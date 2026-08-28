#!/usr/bin/env bash
# Two guards of opposite character in one change: one on a trusted internal
# caller, one wrapping a real parse boundary. Only the first is slop.
set -euo pipefail

git init -q .
git config user.email eval@example.com
git config user.name Eval

mkdir -p src
cat >src/profile.ts <<'BASE'
export function displayName(user: User): string {
  return `${user.firstName} ${user.lastName}`;
}

export function initials(user: User): string {
  return `${user.firstName[0]}${user.lastName[0]}`;
}
BASE

git add -A
git commit -qm "add profile helpers"
git branch -M main
git checkout -q -b feature/avatar

cat >>src/profile.ts <<'CHANGE'

export function avatarUrl(user: User): string {
  if (!user) {
    return "";
  }
  if (!user.id) {
    return "";
  }
  return `${CDN}/avatars/${user.id}.png`;
}

export function loadPreferences(raw: string): Preferences {
  try {
    return preferencesSchema.parse(JSON.parse(raw));
  } catch (error) {
    throw new PreferencesError("stored preferences are not readable", {
      cause: error,
    });
  }
}
CHANGE

git add -A
