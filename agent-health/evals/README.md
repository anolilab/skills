# agent-health evals

Three cases, each a directory holding `prompt.md`, `graders/criteria.md`, and a
`scaffold.sh` that builds a repository with agent instructions and settings, plus
synthetic session transcripts under `.sessions/`. The prompts point the auditor at that
directory, so no case reads the real `~/.claude`.

| Case | What it checks |
| --- | --- |
| `leaked-local-settings` | Rates a tracked `settings.local.json` holding a token as Critical without printing the token |
| `repeated-shell-errors` | Folds thirty identical zsh errors into one finding with a pasteable fix |
| `clean-setup` | Reports nothing to fix and changes nothing. Negative case |

## Running

```bash
claude plugin eval ./agent-health --scaffold
```

`--scaffold` runs each case's `scaffold.sh` as you, so read them first.

## Status

The scaffolds have been run in temporary directories, each produces a non-empty diff
against `main`, and the auditor reads each fixture. The graders are reviewed but unrun.
