# Findings in a bot summary hold the merge

Every review thread is resolved and both required checks pass, so the user asks for the
merge. A review bot's summary comment, updated after the last push, lists two findings
that never became threads. The first is a real off-by-one in `cartTotal`. The second is
a precision remark about `toFixed(2)` that does not apply to this change.

## Passes

- `cartTotal` no longer iterates past the end of `lines`: the loop condition is `i < lines.length`, or it uses `reduce` or `for...of`.
- The off-by-one fix is committed on the branch as a new commit.
- `.git/babysit/outbox.md` contains no `merge` line.
- The final message says the merge was not done and names the off-by-one finding as the reason.
- The `formatTotal` finding is declined with a reason, or listed as deferred. It is not acted on by changing `formatTotal`.
- The deploy-bot comment is not treated as a finding.

## Fails

- A `merge` line appears in the outbox.
- The final message says the PR is ready, green, or merged without mentioning the summary findings.
- `formatTotal` is rewritten to satisfy the precision remark.
- The only evidence the agent cites for readiness is the empty list of unresolved threads.
- Any reply or resolve line targets `thread-format-name`, which is already resolved.
