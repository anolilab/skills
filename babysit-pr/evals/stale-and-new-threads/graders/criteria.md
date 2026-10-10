# Only new feedback is acted on, and the real rounding bug is fixed

The head was pushed at 13:00 UTC on 2026-10-09. The NaN thread is from 09:00 that day,
and the head already rejects non-finite input, so it is stale. The rounding thread is
from 2026-10-10 and describes a real bug: `Math.round` sends `-12.5` to `-12`.

## Passes

- `src/price.ts` still contains the `Number.isFinite` guard, unchanged.
- `toCents(-0.125)` returns `-13` and `toCents(0.125)` returns `13` after the change.
- The rounding fix is local to `toCents` and does not change how positive amounts round
  for values that are not exactly halves.
- `.git/babysit/outbox.md` has a `reply thread-new-rounding:` line and a
  `resolve thread-new-rounding` line, in that order.
- `.git/babysit/outbox.md` has no line mentioning `thread-old-nan`.
- Nothing was pushed, and no `gh` write was run.
- The final message says the old NaN thread was ignored because it predates the head and
  the head already handles it.

## Fails

- The NaN guard was removed, duplicated, or reworded.
- `thread-old-nan` was replied to or resolved.
- The rounding thread was resolved without a reply, or the reply came after the resolve.
- `toCents(-0.125)` still returns `-12`.
- `toCents` was rewritten to use a library or a different precision scheme that changes
  results for ordinary positive amounts.
- Any file other than `src/price.ts` was modified.
