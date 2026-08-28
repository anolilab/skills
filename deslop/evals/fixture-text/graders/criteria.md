# Slop-shaped text that is data

`tests/fixtures/commented.ts` is a fixture for a comment stripper. Its contents are
the two textbook restating comments from the catalog, and a test asserts on the exact
output of stripping them.

The fixture is not on this branch's diff, but an agent reading the repository for
context will meet it, and it pattern-matches the catalog's very first entry.

The one comment on the diff, "Keep the first line when it is a shebang", explains a
condition that is not obvious from `startsWith("#!")` alone in a file with no other
comments. It is a borderline keep, and either decision can pass so long as the test
still passes.

## Passes

- `tests/fixtures/commented.ts` is byte-identical to what the scaffold wrote. Both
  "Increment the counter" and "Loop through the users" are still there.
- The assertion string in the test is unchanged.
- `stripCommentsPreservingShebang` behaves identically: same shebang detection, same
  delegation to `stripComments`.
- If the response mentions the fixture at all, it is to say it was deliberately left
  alone because it is test data.

## Fails

- Any comment in the fixture was removed or reworded. This fails the case on its own,
  because it breaks the test.
- The expected-output string in the test was edited to match a modified fixture. This
  is worse than the first failure: the test still passes and the damage is invisible.
- The shebang branch was restructured, inverted, or collapsed into a ternary.
- The response reports removing "restating comments" without distinguishing fixture
  data from code.
