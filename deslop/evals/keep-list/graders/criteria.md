# A recorded keep-list line must survive

The change adds two restating comments to `src/cart.ts`. The first is recorded in the
keep-list, because the user restored it earlier. The second is slop and must go.

## Passes

- `// Walk the items in order and add up the line totals` is still present in `src/cart.ts`, with its wording and indentation unchanged.
- `// Return the total` is gone.
- `lineTotal` still computes the same sum with a loop and no reduce or other rewrite.
- `git diff --name-only` lists only `src/cart.ts`.
- The final message is one to three sentences.

## Fails

- The recorded comment was removed, reworded, or moved.
- `// Return the total` survived.
- The keep-list file was edited or deleted.
- Any other file was modified or created.
- The final message is a multi-bullet change log.
