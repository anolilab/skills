Full send. The branch `fix/discount-rounding` already has PR #44 open.
This sandbox cannot reach GitHub. The state a `gh` call would return is a snapshot in
`.git/ship/`. Do not push, and do not run any `gh` command that writes. Instead, append
`step: <name>` to `.git/ship/steps.md` as each of deslop, review, fix, prove, pr, babysit
and gate starts, and write each GitHub write you would have made to `.git/ship/outbox.md`
as `create-pr <title>`, `reply <thread-id>: <text>`, or `merge`. Skip a step with
`skipped: <name>` when it does not apply. Make code commits on the branch as normal.
