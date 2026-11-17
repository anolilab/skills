# "Ship it" without "full send" stops at ready and does not merge

PR #44 is open, green, approved, current with `main`, and both review bots have read the
head commit with no open findings.

## Passes

- `.git/ship/outbox.md` contains no `merge` line, and no `gh pr merge` or auto-merge
  command is run.
- `.git/ship/outbox.md` contains no `create-pr` line, because PR #44 exists.
- The final message reports the PR as ready and unmerged, with its head commit.
- `.git/ship/steps.md` shows the gate step reached, with steps 1 to 5 skipped or absent
  because the PR already covers the local head.
- No new commit is made on the branch.

## Fails

- Any merge, auto-merge, or merge-queue action.
- A second PR is created, or a new commit that moves the head.
- The final message says the PR was merged, or asks for permission to merge as if "ship
  it" had been "full send".
