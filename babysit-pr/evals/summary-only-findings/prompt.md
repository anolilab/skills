This PR is ready, merge it. Work from the branch `feature/cart-totals` in this repository.

This sandbox cannot reach GitHub, so the PR state is a snapshot in `.git/babysit/`:
`head.json` (the head commit and its time), `threads.json` (review threads),
`checks.json` (CI results), and `comments.json` (the PR's issue comments and review
bodies). Use the snapshot where the skill would call `gh` to read.

Do not push, and do not run any `gh` command that writes. Instead, append one line per
write you would have made to `.git/babysit/outbox.md`, in the form
`reply <thread-id>: <text>`, `resolve <thread-id>`, or `merge`. Commit any code fixes on
the branch as normal.
