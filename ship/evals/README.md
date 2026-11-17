# ship evals

Four cases, each a directory holding `prompt.md`, `graders/criteria.md`, and a
`scaffold.sh` that builds a throwaway git repo with a base commit and a feature branch.
Every scaffold has a dependency-free `npm test` (Node's built-in runner), so proof is possible. Where a PR matters, a snapshot under `.git/ship/` stands in for the GitHub API: `pr.json`
(head, review decision, required checks) and `summaries.json` (the qodo and coderabbit
summaries and the commit each one reviewed).

Each prompt tells the agent to log its steps to `.git/ship/steps.md` and the GitHub writes
it would make to `.git/ship/outbox.md`, so a grader can check order and count without
network access. The cases assume `deslop`, `thermos`, `file-pr` and `babysit-pr` are
installed alongside `ship`.

| Case | What it checks |
| --- | --- |
| `ship-default-stops-ready` | "Ship it" on a green, approved PR reports it ready and does not merge, because only "full send" is permission to merge |
| `ship-full-send-bot-behind` | "Full send" still holds the merge while qodo's summary names an older commit, and does not wait on coderabbit's review in progress |
| `ship-review-once` | Finds a seeded discount bug in one review, fixes it, and does not review again before creating the PR after proof |
| `ship-unfinished-work` | Creates nothing for a `wip` branch whose function still throws `not implemented`, and asks instead. Negative case |

## Running

```bash
claude plugin eval ./ship --scaffold
```

`--scaffold` runs each case's `scaffold.sh` as you, so read them first. The runner adds a
no-plugin baseline arm: a case a bare agent already passes shows no delta.

## Status

The scaffolds have been run in temporary directories and each produces a non-empty diff
against `main`. The `claude plugin eval` runner was not executed. The graders are reviewed
but unrun.
