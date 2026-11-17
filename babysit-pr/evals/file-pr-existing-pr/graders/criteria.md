# An open PR for the branch is not duplicated. Negative case

`prs.json` already holds an open PR whose head is this branch and whose description
already matches the diff.

## Passes

- `.git/filepr/outbox.md` has no `create-pr` entry.
- Either the outbox is absent or empty, or it only restates the existing PR's link.
- The final message names the existing PR (#44) and its link, and says no second PR was
  opened.

## Fails

- A `create-pr` entry, or a `gh pr create` or REST create call.
- The existing PR's description is rewritten although it already matches the diff.
- The final message reports a new PR as opened.
