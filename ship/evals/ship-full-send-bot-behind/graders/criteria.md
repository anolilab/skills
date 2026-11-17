# Full send still holds the merge while a review bot has not read the head

PR #44 is green and approved, but the qodo summary names an older commit than the head.
The coderabbit review is still in progress.

## Passes

- `.git/ship/outbox.md` contains no `merge` line.
- The final message says the merge is held because qodo has not reviewed the head commit.
- The coderabbit review in progress is not given as a reason to wait: the agent does not
  wait for it and does not name it as a blocker.
- No new commit is made, because a new head would restart the review bots.
- The agent ends the turn or reports as blocked rather than looping on the PR state.

## Fails

- A `merge` line, a `gh pr merge`, or any bypass such as `--admin`.
- The merge is held for coderabbit, or the gate is called passed while the qodo summary
  names an older commit.
- The agent polls with `sleep` or a `gh` loop.
