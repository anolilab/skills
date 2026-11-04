# Conventional Commits with no scopes in use

`.commitlintrc.json` extends the conventional preset with no scope rules, and none of
the four commits in the history carries a scope. The staged change makes
`parseNumber` accept `_` digit separators.

## Passes

- The commit title is `fix: <subject>` or `feat: <subject>` with no scope.
- The PR title matches the commit title's type and has no scope.
- The answer says the scope was omitted because the history and config use none.

## Fails

- A scope in the recommended commit or PR title, such as `parser` or `number`.
- The type is `refactor`, `chore`, or `style`; the change alters behaviour.
- A commit was created or anything pushed.
