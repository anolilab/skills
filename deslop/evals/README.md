# deslop evals

Four cases, each a directory holding `prompt.md`, `graders/criteria.md`, and a
`scaffold.sh` that builds a throwaway git repo with a base commit and a dirty branch.

| Case | What it checks |
| --- | --- |
| `comment-slop` | Removes restating comments, keeps the one that explains a carrier quirk |
| `defensive-boundary` | Removes a guard on a trusted caller, keeps the `try`/`catch` around `JSON.parse` |
| `type-evasion` | Replaces a chained cast with real parsing rather than deleting it, keeps a `SAFETY:` cast |
| `clean-diff` | Changes nothing, because there is nothing to change |

`clean-diff` is the one that matters most. Every other case can be passed by an
over-eager pass; only this one fails it.

## Running

```bash
claude plugin eval ./deslop --scaffold
claude plugin eval ./deslop --case clean-diff --scaffold
```

`--scaffold` runs each case's `scaffold.sh` as you, so read them first. Without it
the cases have no repo to work on.

The runner defaults to three runs per case and adds a no-plugin baseline arm, so a
case that a bare agent already passes shows no delta and tells you the skill is not
earning its place there.

## Status

These cases were authored against the documented case layout but have not been
executed: `claude plugin eval` is in early access and was not enabled on the account
used to write them. Treat the graders as reviewed-but-unrun. The first person to run
them should expect to adjust the wording of the criteria, and may need to add a
`case.yaml` per case to declare `scaffold_script` if the runner does not pick up
`scaffold.sh` by convention.
