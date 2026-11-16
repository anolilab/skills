# German edit: fix the language, keep the facts

## Passes

- `content/blog/coolify-hosting.mdx` no longer contains "In der heutigen digitalen Welt", "kein Tool, das ist", "macht es Sinn", "Am Ende des Tages", or an em dash.
- The figures survive in German format: "4 GB", "4,5 €", "Oktober 2026", "März 2026", "drei Kundenprojekte".
- The Hetzner link URL is unchanged.
- The title uses German sentence case, not English title case.
- "Open Source Plattform" is written as "Open-Source-Plattform".
- At most one of the three `##` headings keeps the "X: was ..." colon form.
- The reply runs `scripts/style_check.py` and reports zero errors for the file.

## Fails

- A number, date, URL, or the claim about three client projects is changed or removed.
- New first-hand experience, a new opinion, or a new number is added that the original did not contain.
- The text switches to "Sie" or to "wir" anywhere.
- The frontmatter keys or the `published` date are changed.
