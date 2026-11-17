File a PR for `fix/discount-rounding`. Discounted items were a cent off at checkout.

This sandbox cannot reach GitHub. The repository state a `gh` call would return is a
snapshot in `.git/filepr/`: `merged.json` (recent merged PR titles) and `prs.json` (PRs
whose head is this branch). Do not push, and do not run any `gh` command that writes.
Instead, write what you would have done to `.git/filepr/outbox.md`: for a new PR, a line
`create-pr` followed by `title: <title>` and then `body:` and the body text; for an
existing PR, a line `update-pr <number>` and the new body, or nothing if no change is
needed. Make any commit the skill calls for on the branch as normal.
