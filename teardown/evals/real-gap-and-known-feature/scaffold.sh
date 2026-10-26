#!/usr/bin/env bash
# The source has retries with backoff, which users asked for repeatedly, and timeouts,
# which we already ship. Only retries is a gap.
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
## 3.2.0
- Retries with exponential backoff for 5xx and network errors (`retry: { attempts, baseMs }`).
## 3.1.0
- Per-request timeouts (`timeoutMs`).
MD
cat >.source/issues.json <<'JSON'
[
  {"number": 88, "state": "closed", "labels": ["enhancement"], "reactions": 41, "title": "Retry failed requests with backoff", "body": "We wrap every call in our own retry loop. Please build it in."},
  {"number": 90, "state": "closed", "labels": ["enhancement"], "reactions": 3, "title": "Timeout per request", "body": "Abort a request after N ms."}
]
JSON
git add -A
