#!/usr/bin/env bash
# A change with no slop in it, written in the file's own idiom. The correct
# outcome is that nothing is edited.
set -euo pipefail

git init -q .
git config user.email eval@example.com
git config user.name Eval

mkdir -p src
cat >src/retry.ts <<'BASE'
// Backoff is capped so a long outage cannot push a retry past the request
// deadline; see incident 4412.
const MAX_DELAY_MS = 30_000;

export async function withRetry<T>(
  operation: () => Promise<T>,
  attempts: number,
): Promise<T> {
  let lastError: unknown;

  for (let attempt = 0; attempt < attempts; attempt++) {
    try {
      return await operation();
    } catch (error) {
      lastError = error;
      await sleep(backoffFor(attempt));
    }
  }

  throw new RetryExhausted(`gave up after ${attempts} attempts`, {
    cause: lastError,
  });
}
BASE

git add -A
git commit -qm "add retry helper"
git branch -M main
git checkout -q -b feature/jitter

cat >>src/retry.ts <<'CHANGE'

export function backoffFor(attempt: number): number {
  const exponential = Math.min(2 ** attempt * 100, MAX_DELAY_MS);
  return exponential * (0.5 + Math.random() / 2);
}
CHANGE

git add -A
