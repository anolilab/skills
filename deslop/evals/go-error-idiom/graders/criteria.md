# Go, where entry 2 inverts

`store.go` wraps every error with `fmt.Errorf("...: %w", err)`, comments nothing, and
trusts its callers. The branch adds `Save`, `Keys`, and a `keyOf` helper.

This is the case that catches a pass reading Go through TypeScript eyes. Four
`if err != nil` blocks pattern-match as entry 2 defensive slop and are the language's
idiom. What is actually slop here is the check that cannot fire and the wrapper that
hides an unchecked type assertion.

Every removal below is behaviour-preserving. The second `err != nil` in `Save` is
unreachable, since the first returns whenever `err` is non-nil. The `Keys` guard is
redundant twice over: `records == nil` is subsumed by `len(records) == 0`, and
`make([]string, 0, len(records))` followed by a range over a nil slice already returns
the same non-nil empty slice the guard returns.

## Passes

- All four wrapped error checks survive verbatim: both in `Load`, and the
  `json.Marshal` and `os.WriteFile` checks in `Save`. Their `fmt.Errorf` wrapping and
  `%w` verbs are unchanged.
- The dead second `if err != nil { return err }` in `Save` is gone, along with the
  comment above it.
- `keyOf` is gone and the loop reads `record.Key` directly.
- The `if records == nil || len(records) == 0` guard is gone, along with its comment.
- `make([]string, 0, len(records))` still preallocates. `Keys(nil)` still returns a
  non-nil empty slice.
- The package still builds: `go build ./...` and `go vet ./...` are clean.

## Fails

- Any of the four wrapped `if err != nil` blocks was removed, collapsed, or rewritten
  to return the bare `err`. This is the headline failure of the case.
- `errors.Is`, `errors.As`, `panic`, or a sentinel error was introduced. Changing the
  error strategy is a refactor, not a deslop pass.
- `keyOf` was kept and merely retyped from `interface{}` to `Record`, or to a generic
  type parameter. It is a single-use wrapper over a field read; the fix is deletion.
- The type assertion was kept and made comma-ok. That hardens a line that should not
  exist.
- The `Keys` guard was kept and only half-simplified to `len(records) == 0`.
- `Keys` was changed to return `nil` on empty input, or the preallocation was dropped.
  Both change what callers observe.
- Doc comments were added to `Load`, `Save`, `Keys`, or `Record` because Go convention
  documents exported identifiers. The file documents none of its exports, and adding
  them is the pass writing in its own voice rather than the file's.
- `go.mod` was modified.
