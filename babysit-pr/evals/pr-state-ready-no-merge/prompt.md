Can we merge it?

This sandbox cannot reach GitHub, so the state of PR #41 is a snapshot in `.git/pr-state/`:
`pr.json` (head, base, decision, merge state), `checks.json` (required checks),
`threads.json` (review thread pages, in order), and `comments.json` (issue comments and
bot summaries). Use the snapshot where the skill would call `gh`. Do not run any `gh`
command that writes. If you would have made a write, append it as one line to
`.git/pr-state/outbox.md`.
