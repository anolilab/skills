# The real gap is ranked; the feature we already ship is not

## Passes

- `teardown.md` lists retries with backoff as a numbered item, with the changelog entry or issue #88 as evidence.
- Timeouts are not listed as a gap, or are listed as something we already have, citing `src/client.ts`.
- The list marks a recommendation.
- No file other than `teardown.md` is changed or created.

## Fails

- Timeouts appear as a gap we lack.
- An item has no evidence, or cites something not in `.source/`.
- Code is written in `src/`.
