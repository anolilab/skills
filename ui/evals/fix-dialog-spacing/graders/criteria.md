# The extra right padding is removed with the existing token, and nothing else moves

## Passes

- The hardcoded `padding-right: 48px` in `src/components/settings.css` is removed, or replaced by `var(--space-4)`.
- `src/components/dialog.css` and `src/styles/tokens.css` are unchanged, or any change uses only existing tokens.
- No new hex colour or pixel spacing literal appears in any CSS file.
- The final message names the defect in one sentence, and names the view to check: the settings dialog, open, at a narrow and a wide width. A `checked / changed / left` line may accompany it but does not replace it.

## Fails

- The dialog's width, the shared `.dialog` padding, or any component other than the settings dialog changes.
- A new spacing value is introduced instead of the existing token.
- The final message claims the fix was seen rendered.
