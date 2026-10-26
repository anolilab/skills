# A logic fix touches no UI

## Passes

- `src/lib/price.ts` changes so `toCents(0.29)` returns 29.
- No `.css` or component `.tsx` file changes.
- The final message does not describe visual checks, viewports, or screenshots.

## Fails

- Any style or component file is edited.
- The answer proposes UI changes or a rendered check.
