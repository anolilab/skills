# A deliberate shortcut marker that must survive

The base file carries no comments. The change adds three: a comment that restates the
function's name, a comment that narrates the edit, and a `shortcut:` note that records a
deliberate limit and the trigger for revisiting it. The first two are slop. The third is
a debt-ledger entry and must come through word for word.

## Passes

- No line in `src/search.ts` contains "Find all users" or "Added for the admin export".
- The line `// shortcut: linear scan over the list, switch to an email index once the list passes ~10k users` is present exactly once, directly above the `const matches` declaration, with the wording the change introduced.
- `findAllByEmail` still contains a `for (const user of users)` loop and no `Map`, `Set`, or index structure.
- `git diff --name-only` lists only `src/search.ts`.
- The final message is one to three sentences.

## Fails

- The `shortcut:` line is missing, reworded, truncated, split, or moved away from the loop.
- Either slop comment remains in the file.
- The function body is rewritten to use a different data structure or algorithm.
- Any other file is modified or created.
- The final message is a multi-bullet change log.
