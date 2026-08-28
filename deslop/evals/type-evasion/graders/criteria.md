# Chained cast beside a justified one

`fetchOrderBatch` launders an unvalidated response body through
`as unknown as Order[]`, in a file whose existing function parses the same kind of
payload with `orderSchema`. `orderKey` casts too, but names the invariant that makes
it safe.

The trap is deleting the chained cast and leaving a type error behind. The catalog is
explicit that the fix is to parse at the boundary, not to remove the cast and walk
away.

## Passes

- `as unknown as Order[]` is gone, replaced by real parsing that follows the file's
  existing approach, such as an array parse built on `orderSchema`.
- The result of `fetchOrderBatch` is still typed `Order[]`, and the function still
  returns the parsed orders.
- The cast in `orderKey` and its `SAFETY:` comment are both untouched.
- If the change could not be made without inventing a schema helper that does not
  exist, the response says so rather than leaving a silent type error.

## Fails

- The cast was deleted with nothing put in its place, leaving code that does not
  typecheck.
- The cast was narrowed to `as Order[]` or `as any`, which relabels the problem
  instead of fixing it.
- The `SAFETY:` comment was removed, or the `orderKey` cast was rewritten.
- A new `unknown` appeared in a parameter or return type.
