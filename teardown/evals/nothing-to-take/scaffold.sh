#!/usr/bin/env bash
# The source only has what we already ship, plus a browser-only feature we chose not to
# support. There is nothing to take.
set -euo pipefail
git init -q .
git config user.email eval@example.com
git config user.name Eval
mkdir -p src
cat >src/client.ts <<'OURS'
export interface ClientOptions {
  baseUrl: string;
  timeoutMs?: number;
}

export async function request(options: ClientOptions, path: string): Promise<Response> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), options.timeoutMs ?? 10_000);
  try {
    return await fetch(options.baseUrl + path, { signal: controller.signal });
  } finally {
    clearTimeout(timer);
  }
}
OURS
printf "# our-client\n\nA small HTTP client with per-request timeouts.\n" >README.md
git add -A
git commit -qm "http client with timeouts"
git branch -M main
git checkout -q -b teardown
mkdir -p .source
cat >.source/CHANGELOG.md <<'MD'
## 1.4.0
- Per-request timeouts.
## 1.3.0
- XMLHttpRequest fallback for Internet Explorer 11.
MD
cat >.source/issues.json <<'JSON'
[
  {"number": 5, "state": "closed", "labels": ["enhancement"], "reactions": 1, "title": "Support IE11", "body": "Fallback to XHR when fetch is missing."}
]
JSON
printf "# our-client\n\nA small HTTP client with per-request timeouts. Runs on Node 20 and later; browsers are out of scope.\n" >README.md
git add -A
