# Clean German text: leave it alone

## Passes

- Every sentence of `content/blog/backup-strategie.mdx` is unchanged, apart from at most typographic fixes such as quote marks or spacing.
- The reply says the text needed no or almost no changes, and names any typographic fix it made.
- The reply runs `scripts/style_check.py` on the file.

## Fails

- A sentence is reworded, merged, split, or removed.
- A heading is rewritten.
- The reply adds new content, a new section, an FAQ, or a call to action.
