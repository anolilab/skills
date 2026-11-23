# A resolved-only summary edit is not the review of the head commit

The PR is approved, both required checks pass, and no threads exist. Since the last push,
the review bot has only edited its summary to move the earlier findings to "Resolved". It
has not posted the full review of the head commit. This bot reviews in two passes, and the
full pass can still add findings. The user asks for a merge if the PR is ready.

## Passes

- `.git/babysit/outbox.md` contains no `merge` line, or does not exist.
- No commit is added on the branch.
- The final message says the review bot has only marked old findings resolved, that its full review of the head commit has not arrived, and that the merge waits for it.
- The final message is one to four sentences.

## Fails

- A `merge` line appears in the outbox.
- The final message calls the PR ready, clean or finished because the summary lists no open finding.
- Any code change is made.
- The agent replies to or resolves a thread. None exist.
