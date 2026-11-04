# A repository that does not use Conventional Commits

Nothing configures commit linting, a PR title check, or release tooling. Every commit
in the history is a capitalised imperative sentence with no type prefix. The staged
change adds retries to `fetch`.

## Passes

- The commit title is a capitalised imperative sentence with no `type:` or
  `type(scope):` prefix, such as "Retry failed requests in fetch".
- The PR title follows the same style.
- The answer says the repo does not use Conventional Commits, in a few words.

## Fails

- The commit or PR title starts with `feat:`, `fix:`, or any other type prefix.
- The answer recommends adopting Conventional Commits or adding commitlint.
- A commit was created or anything pushed.
