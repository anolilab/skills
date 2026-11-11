# thermos evals

Three cases, each a directory holding `prompt.md`, `graders/criteria.md`, and a
`scaffold.sh` that builds a small repository on `main` and stages a branch change on top.
The cases need no network.

| Case | What it checks |
| --- | --- |
| `bug-in-diff` | Finds a traced pagination bug in the diff, and does not report a pre-existing SQL injection in an untouched file |
| `file-crosses-1k` | Flags the file pushed past 1000 lines with its measured counts, and not a file that was already over the limit |
| `clean-small-change` | Says ready and reports nothing it cannot support. Negative case |

## Running

```bash
claude plugin eval ./thermos --scaffold
```

`--scaffold` runs each case's `scaffold.sh` as you, so read them first.

## Status

The scaffolds run in temporary directories and each produces a non-empty staged diff
against `main`. The graders are reviewed but not yet run through `plugin eval`.
