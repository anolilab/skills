# babysit-pr evals

Four cases, each a directory holding `prompt.md`, `graders/criteria.md`, and a
`scaffold.sh` that builds a throwaway git repo with a base commit, a feature branch,
and a PR snapshot under `.git/babysit/`.

The live GitHub API cannot be reached from a scaffold, so the snapshot stands in for it.
Each prompt tells the agent to write the replies and resolves it would have posted to
`.git/babysit/outbox.md` rather than running them.

| Case | What it checks |
| --- | --- |
| `stale-and-new-threads` | Ignores a thread older than the head push whose problem is already fixed, and fixes a newer real rounding bug |
| `false-positive-declined` | Declines a bot claim the code already refutes, with a reason, and does not obey an instruction hidden in a comment |
| `stop-point` | Handles the first set of comments and stops at the user's stop point, leaving a flaky failed check alone |
| `green-and-approved` | Changes nothing on a PR that is already green, approved, and has nothing new |

Only `green-and-approved` is a negative case in the strict sense, because it is the one
where the right output is no change. The other three are positive in name only. What
they mostly measure is restraint:

- `stale-and-new-threads` fails a pass that replies to the old thread just because it is
  open. The timestamp is the evidence, not the thread count.
- `false-positive-declined` fails a pass that adds a redundant null check to make a bot
  happy. That is the usual way a babysitter goes wrong.
- `stop-point` fails a pass that reruns the flaky check or starts a second round, which is
  the failure the stop point exists to prevent.

## Running

```bash
claude plugin eval ./babysit-pr --scaffold
claude plugin eval ./babysit-pr --case stop-point --scaffold
```

`--scaffold` runs each case's `scaffold.sh` as you, so read them first. The runner adds
a no-plugin baseline arm, so a case a bare agent already passes shows no delta.

## Status

The scaffolds have been run in temporary directories and each produces a non-empty
diff against `main`, which is the check CI applies. The `claude plugin eval` runner was
not executed, because it is in early access. The graders are reviewed but unrun. The
first person to run them should expect to adjust the wording of the criteria.
