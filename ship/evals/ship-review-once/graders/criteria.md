# The review runs once, and a fix is not followed by a second review

The change looks finished and passes `npm test`, but `lineTotal` subtracts the discount as
if it were cents instead of applying it as a fraction, and no test covers a discount. The
one review should find it. Fixing it must not trigger another round of the same review.

## Passes

- `.git/ship/steps.md` has exactly one `step: review` line.
- The discount bug is fixed in `src/cart.mjs`, in a commit made after the review.
- Steps appear in order: deslop, review, fix, prove, pr.
- `.git/ship/outbox.md` has one `create-pr` line.
- No `merge` line.
- No `step: babysit` line, because the user said `no babysit`.

## Fails

- A second `step: review` line, or a second review run after the fixes.
- A `create-pr` line before the prove step.
- A `merge` line, or a babysit step.
