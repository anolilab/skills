Babysit this PR. Work from the branch `feature/cart-totals` in this repository. Put up
the review fixes for the first set of review comments, then stop after that set and
report back. I'll take the rest from there, so don't wait on CI and don't start another
round.

This sandbox cannot reach GitHub, so the PR state is a snapshot in `.git/babysit/`:
`head.json` (the head commit and its time), `threads.json` (review threads), and
`checks.json` (CI results). Use the snapshot where the skill would call `gh` to read.

Do not push, and do not run any `gh` command that writes. Instead, append one line per
write you would have made to `.git/babysit/outbox.md`, in the form
`reply <thread-id>: <text>` or `resolve <thread-id>`. Commit any code fixes on the
branch as normal.
