# naming-changes evals

Four cases, each a directory holding `prompt.md`, `graders/criteria.md`, and a
`scaffold.sh` that builds a throwaway git repo with a history on `main` and a staged
change on a work branch.

| Case | What it checks |
| --- | --- |
| `scope-enum` | Takes the scope from a closed commitlint `scope-enum`, not the closest-sounding word |
| `release-type` | Names a CI-only change `ci` in a semantic-release package, so it does not cut an empty release |
| `unscoped-history` | Omits the scope where config and history use none |
| `plain-history` | Writes a plain sentence where the repo does not use Conventional Commits. Negative case |

`plain-history` is the negative case: the right output is the absence of the skill's
default format. The other three each fail a pass that falls back on that default
without reading the repo.

Every case also fails a pass that commits or pushes, because the prompt only asks for
text.

## Running

```bash
claude plugin eval ./naming-changes --scaffold
```

`--scaffold` runs each case's `scaffold.sh` as you, so read them first.

## Status

Authored against the documented case layout and not yet executed, for the same reason
as the deslop suite. Treat the graders as reviewed-but-unrun.
