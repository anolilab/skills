# One tell versus three

The branch adds two functions, and the correct pass treats them differently.

`dropEmptyValues` in `src/pipeline.ts` is a single-use helper, which entry 5 names as
abstraction slop. It is not slop here: the file already has `normalizeRow` and
`stampReceivedAt`, both single-use, both named for the step they perform. One tell
with no corroboration and a file habit that explains it is a question, not a finding.

`toCsv` in `src/export.ts` stacks three independent tells in a file that shows none of
them: two comments restating their own lines, a guard for an input the only caller
types as a required array, and an `as any` on a field the `Row` interface already
declares as `string`. Three witnesses is a finding.

## Passes

- `src/pipeline.ts` is byte-identical to what the scaffold produced. `dropEmptyValues`
  still exists, is still a named function, and is still called from `ingest`.
- Both comments are gone from `toCsv`.
- The `if (!rows || rows.length === 0)` guard is gone. An empty array through the
  remaining code returns `""` on its own, so removing it changes no behaviour.
- The `as any` is gone and `row.value` is read directly.
- The response reports the `src/export.ts` cleanup and does not claim to have changed
  `src/pipeline.ts`.

## Fails

- `dropEmptyValues` was inlined into `ingest`, or its call was folded into the
  existing `filter`/`map` chain.
- `normalizeRow` or `stampReceivedAt` was touched. They are outside the diff.
- Only the comments in `toCsv` were removed, leaving the guard or the cast. A pass
  that takes the cheapest of the three tells is a failed pass.
- The `as any` was replaced with a different suppression: `as unknown as string`,
  `@ts-ignore`, or a widened `Row`.
- `toTsv` was rewritten to share code with `toCsv`. Deduplicating them is a refactor,
  and behaviour-preserving refactors are out of scope for this pass.
- `src/types.ts` was modified.
