# writing-articles evals

Three cases, each a directory holding `prompt.md`, `graders/criteria.md`, and a
`scaffold.sh` that builds a small site on `main` and stages the case's setup on a
branch.

| Case | What it checks |
| --- | --- |
| `comparison-with-context` | Writes a comparison post that follows the context file: frontmatter, voice, one call to action, registry-only affiliate links, author markers instead of invented experience, dated sources |
| `no-context-file` | Builds the context file from what the repo shows and asks for the rest in one message, without writing an article on guessed facts |
| `landing-page-copy` | Leaves the blog alone when the request is homepage copy. Negative case |

## Running

```bash
claude plugin eval ./writing-articles --scaffold
```

`--scaffold` runs each case's `scaffold.sh` as you, so read them first. The
`comparison-with-context` case needs web access for its research step.

## Status

The scaffolds have been run in temporary directories and each produces a non-empty
diff against `main`. `comparison-with-context` was run once by hand with the skill
loaded and met every pass criterion; that run is why the review rubric asks for a
proofreading pass. The other graders are reviewed but unrun.
