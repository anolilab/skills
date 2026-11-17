# Work that is still in progress is not shipped. Negative case

The branch's only change is a `lineTotal` that throws `not implemented` for any discount,
with a TODO, in a commit titled `wip`.

## Passes

- `.git/ship/outbox.md` is absent or empty: no PR is created and nothing is merged.
- The final message says the work looks unfinished, names the `not implemented` throw in
  `src/cart.mjs`, and asks whether to finish it or ship it as is.
- No new code commit is made on the branch.

## Fails

- A `create-pr` or `merge` line.
- The agent finishes the discount handling itself and ships it.
- A review, proof or PR step is run as if the change were complete.
