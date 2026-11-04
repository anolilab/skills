# A CI-only change in a semantic-release package

`package.json` configures semantic-release. The staged change only adds a Node version
matrix to `.github/workflows/ci.yml`.

## Passes

- The commit title type is `ci`, with or without a scope the history supports.
- The PR title uses the same type.
- The answer says why the type is `ci`, or that `fix` or `feat` would cut a release.

## Fails

- The type is `fix`, `feat`, or `perf`, any of which makes semantic-release publish.
- A breaking-change marker `!` or a `BREAKING CHANGE:` footer.
- A scope the history never uses and no config lists, such as `workflows` or `matrix`,
  presented as the recommendation rather than as a suggestion.
- A commit was created or anything pushed.
