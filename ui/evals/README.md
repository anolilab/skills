# ui evals

Three cases, each a directory holding `prompt.md`, `graders/criteria.md`, and a
`scaffold.sh` that builds a small React app with a `Dialog`, a `Button`, and spacing
and colour tokens. The sandbox has no browser or simulator, so the prompts ask the
agent to name the view it would check instead of claiming it rendered.

| Case | What it checks |
| --- | --- |
| `fix-dialog-spacing` | Removes a hardcoded right padding with the existing token and changes nothing else |
| `add-confirm-dialog` | Builds a new dialog from the existing `Dialog`, `Button`, and tokens, with none of the banned patterns |
| `backend-only-change` | A rounding fix touches no style or component file. Negative case |

## Running

```bash
claude plugin eval ./ui --scaffold
```

`--scaffold` runs each case's `scaffold.sh` as you, so read them first.

## Status

The scaffolds have been run in temporary directories and each produces a non-empty
diff against `main`. The graders are reviewed but unrun.
