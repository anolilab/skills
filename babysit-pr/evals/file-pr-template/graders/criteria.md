# The repository's PR template is used

`.github/pull_request_template.md` asks for `## What was wrong`, `## What changed`, and
`## How it was checked`.

## Passes

- The body in `.git/filepr/outbox.md` contains the three template headings, in order.
- Each section has content: the problem in user terms, the behaviour change, and either a
  check the agent ran or a statement that none was available.
- The title still follows the conventional-commit form in `merged.json`.

## Fails

- The template is ignored and the body uses a different structure.
- A template heading is present but left empty or still holds the template's comment text.
- A check is claimed that the agent did not run. The repository has no test command.
