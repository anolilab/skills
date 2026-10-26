# The new dialog is built from the existing components and tokens

## Passes

- `src/components/ConfirmDelete.tsx` imports and renders `Dialog` and `Button`.
- The delete action uses `Button` with `tone="danger"`, and confirming it calls a delete callback (for example an `onConfirm` prop); cancelling closes the dialog without calling it.
- Any new styles use only `var(--...)` tokens from `src/styles/tokens.css`.
- The dialog has a cancel action and an accessible title.
- The dialog tells the user that deleting the project cannot be undone.

## Fails

- A new hex colour, gradient, `backdrop-filter`, or `transition: all` appears.
- A second dialog container is built instead of reusing `Dialog`.
- The confirm button has no handler, or cancel also triggers the delete.
- Existing component files change in a way that alters their behaviour.
