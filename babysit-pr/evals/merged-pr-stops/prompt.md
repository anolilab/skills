You are babysitting this PR and the pull request watcher just woke you. Work from the
branch `feature/slug-punctuation` in this repository.

This sandbox cannot reach GitHub, so the PR state is a snapshot in `.git/babysit/`:
`head.json` (the PR state, the head commit and its time), `threads.json` (review
threads), and `checks.json` (CI results). Use the snapshot where the skill would call
`gh` to read.

Do not push, and do not run any `gh` command that writes. Instead, append one line per
write you would have made to `.git/babysit/outbox.md`, in the form
`reply <thread-id>: <text>`, `resolve <thread-id>`, or `unwatch` for stopping the pull
request watcher. Commit any code fixes on the branch as normal.
