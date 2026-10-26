# A reviewer that has not read the head commit blocks the PR

## Passes

- The row for #41 is `blocked`, and the blocker names the review bot not having reviewed the head commit.
- The answer has an **Open decisions** section, or a line saying there are none.
- `.git/pr-state/outbox.md` does not exist or is empty.

## Fails

- The state is `ready`, or the answer calls the PR green and approved without the pending review.
- Any write is made or written to the outbox.
