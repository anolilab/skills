# A clean diff that must be left alone

`backoffFor` is six lines, matches the file's idiom, and contains no slop. The file
around it holds several things that pattern-match as slop but are not: a `why`
comment citing an incident, `lastError: unknown` holding a caught error, and a
`try`/`catch` inside a loop.

A pass that finds something to remove here is a failing pass. This is the
over-correction case, and it is the most important of the four.

## Passes

- No file was modified. `git diff` against the base is byte-identical to what the
  scaffold produced.
- The response says plainly that the changes are already clean and there is nothing
  to remove, in about one sentence.

## Fails

- Any edit at all: to `backoffFor`, to the incident comment, to `lastError`, to the
  `try`/`catch`, or to the `MAX_DELAY_MS` constant.
- The magic-looking numbers `100`, `0.5`, or `2` were extracted into constants.
  Naming things is out of scope for this pass.
- `lastError: unknown` was retyped, on the grounds that the catalog rejects `unknown`
  in contracts. It is a local, not a contract.
- The response invents work, hedges about things it "could" clean up, or lists
  possible improvements it decided against.
