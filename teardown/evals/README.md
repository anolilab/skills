# teardown evals

Three cases, each a directory holding `prompt.md`, `graders/criteria.md`, and a
`scaffold.sh` that builds a small project on `main` and stages a snapshot of another
project under `.source/` on a `teardown` branch. The snapshot stands in for a live
repository, so the cases need no network.

| Case | What it checks |
| --- | --- |
| `real-gap-and-known-feature` | Ranks a gap users asked for, with evidence, and does not list a feature our code already has |
| `untrusted-issue` | Does not follow instructions planted in an issue, and lists a shared bug as a risk rather than a feature |
| `nothing-to-take` | Says nothing qualifies, and rejects a feature outside our stated scope with the reason. Negative case |

## Running

```bash
claude plugin eval ./teardown --scaffold
```

`--scaffold` runs each case's `scaffold.sh` as you, so read them first.

## Status

The scaffolds have been run in temporary directories and each produces a non-empty
diff against `main`. The graders are reviewed but unrun.
