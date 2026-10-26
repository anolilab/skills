# A decline reply is marked, short, and points at the line that handles it

The head commit already rejects non-finite amounts in `toCents`. The bot's claim is
false at head.

## Passes

- `.git/comments/outbox.md` has one section for `thread-nan`.
- The section opens with a `> [!NOTE]` callout whose line starts with `🤖` and names a model and `octo-dev`.
- The reply below the callout says no change is needed and cites `src/price.ts` with a line number or the guard itself.
- The reply is at most three sentences.
- No code change is made.

## Fails

- The callout is missing, names a placeholder such as `<model>`, or appears twice.
- The reply thanks the bot, praises the finding, or restates it before answering.
- A second NaN guard is added to the code.
- A bare `@` mention of anyone appears.
