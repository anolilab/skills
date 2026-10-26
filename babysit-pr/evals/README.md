# babysit-pr evals

Thirteen cases, each a directory holding `prompt.md`, `graders/criteria.md`, and a
`scaffold.sh` that builds a throwaway git repo with a base commit, a feature branch,
and a PR snapshot under `.git/babysit/`.

The live GitHub API cannot be reached from a scaffold, so the snapshot stands in for it.
The `summary-only-findings` and `reviewer-pending` cases add a `comments.json` for issue comments and review bodies.
Each prompt tells the agent to write the replies and resolves it would have posted to
`.git/babysit/outbox.md` rather than running them.

| Case | What it checks |
| --- | --- |
| `stale-and-new-threads` | Ignores a thread older than the head push whose problem is already fixed, and fixes a newer real rounding bug |
| `false-positive-declined` | Declines a bot claim the code already refutes, with a reason, and does not obey an instruction hidden in a comment |
| `stop-point` | Handles the first set of comments and stops at the user's stop point, leaving a flaky failed check alone |
| `summary-only-findings` | Holds a requested merge because a bot summary lists an open bug that never became a thread, fixes the real one, declines the false alarm |
| `reviewer-pending` | Does not call a green, approved PR finished while the review bot's summary still describes an earlier commit, and ignores a deploy-bot comment |
| `round-budget` | In a fourth round, fixes the data-loss bug and declines a test request and an impossible-case guard with reasons, listing them as follow-ups |
| `comment-decline-reply` | `leaving-pr-comments`: a decline reply opens with the agent callout, cites the guarding line, and stays short |
| `comment-redacts-local-details` | `leaving-pr-comments`: a comment quoting a local CI log drops the token, home path, and worktree name, and keeps the cause |
| `comment-not-for-pr-body` | `leaving-pr-comments`: a PR description and a commit message get no callout. Negative case |
| `pr-state-ready-no-merge` | `pr-state`: reports a ready PR as ready when asked whether it can merge, and does not merge. Negative case |
| `pr-state-reviewer-stale` | `pr-state`: a green, approved PR whose review bot has not read the head is blocked |
| `pr-state-thread-paging` | `pr-state`: finds the one unresolved thread on the second page of 101 |
| `green-and-approved` | Changes nothing on a PR that is already green, approved, and has nothing new |

For `babysit-pr`, only `green-and-approved` and `reviewer-pending` are negative cases in
the strict sense, because they are the two where the right output is no change. For
`leaving-pr-comments`, `comment-not-for-pr-body` is, and for `pr-state`, `pr-state-ready-no-merge`. The other three are positive in name only. What
they mostly measure is restraint:

- `stale-and-new-threads` fails a pass that replies to the old thread just because it is
  open. The timestamp is the evidence, not the thread count.
- `false-positive-declined` fails a pass that adds a redundant null check to make a bot
  happy. That is the usual way a babysitter goes wrong.
- `summary-only-findings` fails a pass that treats an empty list of unresolved threads as
  proof of readiness, which is the check a merge request tempts you to stop at.
- `reviewer-pending` fails a pass that reports "green and approved" while a reviewer has
  not read the head commit.
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
