# Article context file

The project's `.agents/article-context.md`. Fill every section from what the repo
shows first; ask the user only for the rest. Keep it short: facts, not essays.

```markdown
# Article context

## Audience
Who reads the blog, what they are trying to get done, what they already know.
Link the positioning doc if one exists (e.g. `.agents/product-marketing-context.md`).

## Language and voice
- Language(s) and how they are chosen per article (frontmatter field?).
- Form of address (e.g. German "Sie" or "du"; English "you").
- Point of view: first person singular ("I"), plural ("we"), or none.
- Words and phrases the brand uses; words it avoids.

## Author
Name, role, the experience they can speak from first-hand, profile/about URL.

## Format
- Content directory and file type (e.g. `content/blog/<slug>.mdx`).
- Frontmatter fields with their rules (required, types, date format).
- Draft mechanism (e.g. `draft: true`).
- How code samples, tables, and images are written; where images live.

## Components
Each component the article may use, its props, and when to use it.
Example: `<ServiceCta slug="...">` once per article, after the main answer.

## Calls to action
Services or offers an article can lead to, with the identifier the component needs
and the topics that fit each.

## Affiliate links
- Registry file and link format (e.g. `src/data/affiliates.ts`, `<Affiliate id="...">`).
- Programs available, and recommendations that pay nothing.
- Market for disclosure rules (e.g. Germany, US) and how the site labels paid links.

## Internal links
Sections worth linking from articles (services, glossary, guides, location pages),
with their URL patterns.

## Never
Claims the brand does not make, competitors not to name, topics out of scope.
```
