# Comparison article that follows the context file

## Passes

- A new file exists under `content/blog/` ending in `.mdx`; `content/blog/rag-erklaert.mdx` is unchanged.
- Its frontmatter has `title`, `description`, `published` in `YYYY-MM-DD` form, `lang: de`, and a `tags` array.
- The first paragraph after the frontmatter says which tool suits which kind of company.
- The article contains a Markdown table comparing n8n and Make.
- It addresses the reader with "Sie" and never with "du".
- `<ServiceCta slug="workflow-automation"` appears exactly once, after the comparison sections.
- Every `<Affiliate id="...">` uses an id from `src/data/affiliates.ts`; if any paid id is used, the frontmatter has `affiliate: true`.
- Passages about the author's own project experience are `TODO(author)` markers, not finished claims.
- The final report lists the sources cited with a date for each and numbers the `TODO(author)` markers.

## Fails

- The article states first-hand results ("ich habe getestet", "in meinen Projekten") that the context did not supply, without a marker.
- A price or plan limit appears without a date or a link to its source.
- A raw tracking URL or an affiliate id not in the registry is used.
- `ServiceCta` appears twice, or an `Affiliate` link appears before it while the article has not yet answered the question.
- The article claims a certification or partner status.
