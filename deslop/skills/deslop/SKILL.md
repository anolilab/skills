---
name: deslop
description: >
  Removes AI-generated slop from a branch's changes: narrating comments, needless
  defensive code, `any`/`unknown` casts, single-use wrappers, mock-heavy tests,
  anything foreign to the file's own style. Use proactively once a batch of code
  edits is finished and before review or commit, and whenever the user says deslop,
  desloppify, or anti-slop. Not for bug hunting, security review, or refactoring;
  behaviour stays identical.
---

# Deslop

An agent wrote code into this branch. It works, and it reads like an agent wrote it.
Your job is to make the diff indistinguishable from one a careful human author of
these files would have produced, without changing what the code does.

## The bar

For every added or modified line, ask one question:

> Would the person who wrote the rest of this file have written this line?

Answer it from evidence in the repository, not from taste. Open the whole file, look
at its neighbours, look at how the same problem is solved three directories over. The
codebase already has a comment density, an error-handling posture, a naming scheme, a
test style. Slop is whatever deviates from them.

Two corollaries that decide most calls:

- **Consistency beats correctness-in-the-abstract.** A guard clause that is textbook
  defensive programming is still slop if every sibling function trusts its caller.
  Conversely, do not strip a `try`/`catch` from a module where everything else has one.
- **Evidence beats hedging.** Code that pre-emptively handles a case that cannot occur
  on any real path is the agent papering over its own uncertainty. Delete it.

## Procedure

### 1. Establish the review scope

```bash
git symbolic-ref --quiet --short refs/remotes/origin/HEAD   # e.g. origin/main
git diff --merge-base origin/main --stat
git diff --merge-base origin/main
```

`--merge-base` covers committed *and* uncommitted work on the branch, which is what
you want. Substitute the real integration branch if the repo uses something other
than `main`/`master`.

If HEAD *is* the integration branch, fall back to the uncommitted work only:
`git status --short` and `git diff HEAD`.

Confirm the scope in one line before editing ("42 files changed against `origin/main`")
and stop if the diff is empty.

### 2. Learn the local conventions

Before touching anything, read what the repo already tells you:

- `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`, and any style docs.
- The lint and formatter config: `eslint`/`oxlint`/`biome`/`ruff`/`golangci-lint`.
  A rule that is already configured is not your call to relitigate; a pattern the
  linter cannot see is exactly where slop hides.
- For each changed file, the **untouched** parts of that file and one or two of its
  siblings. That is your reference sample, and skipping it is how these passes go wrong.

### 3. Pass over each file

Work file by file, whole file in context, not hunk by hunk. For each changed region,
classify every added line against the catalog in
[`references/catalog.md`](references/catalog.md):

| Category | Smell in one line |
| --- | --- |
| Comment slop | Comments that restate the code, narrate the edit, or mark sections |
| Defensive slop | Guards, `try`/`catch`, and fallbacks for cases that cannot happen here |
| Type-evasion slop | `any`, bare `unknown`, chained casts, `@ts-ignore`, `# type: ignore` |
| Control-flow slop | Nesting where the file uses early returns; redundant conditionals |
| Abstraction slop | Single-use helpers, wrappers, config objects, premature interfaces |
| Duplication and dead code | Both the old and new path kept, unused exports, orphan files |
| Test slop | Mocked-out seams, assertions on the mock, tautological tests |
| Prose slop | Marketing-voice docs, emoji headers, unrequested README and changelog edits |
| Structural slop | Files, configs, or dependencies added outside the project's layout |

Read the catalog for the "not slop" side of each. Several of these have legitimate
forms that you must leave alone.

Apply fixes as you go, smallest edit that removes the smell. Do not batch a rewrite.

For a diff over ~20 files, process in batches grouped by directory so that each batch
shares a convention sample.

### 4. Do the work properly

Size is not a reason to skip. If removing a single-use abstraction means touching
twelve call sites, touch twelve call sites. If the fix is deleting one comment, delete
the one comment. A pass that only picks off the comments is a failed pass.

The one thing that caps scope: **behaviour must not change.** If a cleanup would alter
observable behaviour, leave it and report it instead. The two exceptions:

- The slop is itself a bug (a swallowed error, an unreachable branch, a cast that hides
  a real mismatch). Fix it and say so.
- The user explicitly asked for behaviour changes too.

### 5. Verify

Run whatever the repo actually runs, discovered from `package.json` scripts, `Makefile`,
`justfile`, or CI config: typecheck, lint, and the tests covering the touched files, in
that order. Never claim a clean pass you did not run; if the suite was already red before
your edits, say that explicitly.

Re-read your own diff (`git diff`) as the final check. These passes fail most often by
introducing slop of their own.

### 6. Report

One to three plain sentences with no preamble, saying what you removed in aggregate.

Add bullets only for judgement calls the user needs to rule on: a suspected bug you
left in place, or a removal you were unsure about. Three bullets maximum. If there is
nothing to flag, do not invent a section for it.

## Guardrails

Never remove, on the grounds that it "looks like AI":

- Comments explaining *why*: a workaround, a non-obvious invariant, a link to an
  issue, a `SAFETY:` note justifying a cast.
- Error handling on a real boundary: I/O, network, parsing, user input, FFI, any
  `catch` that maps an error into a domain type.
- Validation of anything crossing a trust boundary, even when it looks redundant.
- Licence headers, generated-file banners, `// eslint-disable` with a stated reason,
  and pragmas the build depends on.
- Anything in generated, vendored, or lockfile-managed paths.
- Tests, purely because they are verbose. Delete a test only when it asserts nothing
  or duplicates another test exactly.

And never, in this pass: rename things for taste, reorganise files, upgrade
dependencies, or "improve" untouched code outside the diff.
