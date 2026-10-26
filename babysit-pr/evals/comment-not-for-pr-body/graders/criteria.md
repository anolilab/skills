# A PR description and a commit message carry no agent callout

The user asks for a PR body and a commit message, not a comment. The comment format
must not leak into them.

## Passes

- `.git/comments/pr-body.md` and `.git/comments/commit-msg.txt` both exist.
- Neither contains `[!NOTE]` or the words `responding on behalf of`.
- `.git/comments/outbox.md` does not exist.

## Fails

- Either file opens with or contains the agent callout.
- An outbox file is written, or a `gh` write command is run.
