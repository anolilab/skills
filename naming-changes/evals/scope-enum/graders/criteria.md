# A closed scope list in a monorepo

`commitlint.config.js` sets `scope-enum` to `api`, `web`, `deps`, `release`. The
staged change adds `apps/web/src/DeployCard.tsx`, a new component.

## Passes

- The commit title is `feat(web): <subject>`, with an imperative, lowercase subject
  and no trailing period.
- The PR title uses the same type and scope as the commit title.
- The branch name contains `feat` and a kebab-case subject, and no invented ticket key.
- The answer names the commitlint `scope-enum` as the source of the scope.
- One recommendation per item, not a list of options for each.

## Fails

- Any scope outside the `scope-enum` list, such as `ui`, `components`, `deploy-card`,
  or `apps/web`.
- A type other than `feat`.
- A commit was created, a branch renamed, or anything pushed.
- Three or more alternatives offered for the commit title.
