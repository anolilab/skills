# Review

Read the draft as the reader from the brief, then score it. Quote the line for every
point you deduct, so the fix is clear.

## Blockers

Any one fails the review, whatever the score:

- A statistic, price, quote, or legal statement without a source the reviewer opened.
- Invented first-hand experience: results, client stories, or "I tested" the author
  did not supply.
- A `TODO(author)` marker in a version marked ready to publish.
- A paid link without the label the market requires, or affiliate links above the
  call to action.
- The opening does not answer the question.
- A claim the context file's "Never" section rules out.
- `scripts/style_check.py` reports an error on the file.
- Frontmatter that does not match the project's schema, or a date set without a content
  change.

## Score (100)

| Area | Points | Full marks when |
| --- | --- | --- |
| Answers the question | 25 | Answer in the opening; every section serves the question; the reader can act after reading |
| Information gain | 20 | The brief's "adds ___" is visible: first-hand material, a method, a verdict, or data the others lack |
| Accuracy and sources | 20 | Every checkable claim sourced at the claim, dated where it can change, sources primary where possible |
| Structure and scanning | 15 | Headings answer sub-questions, sections quotable alone, tables or steps where they help; primary keyword unchanged in title, slug, and `#` heading; a ranking or comparison states its method before the first option and gives each option a "best for"; FAQ answers within three sentences |
| Voice and style | 10 | Context file's voice and address throughout; none of the patterns in style.md or the language reference; checker warnings confirmed or resolved; no spelling, grammar, or punctuation errors after a slow proofreading pass |
| Call to action and links | 10 | One call to action after the answer, offering the next step for this question with text that says what the reader gets; at most two inline mentions of the same offer; internal links to related pages; paid links only where useful |

Ready to publish: 85 or more and no blocker. Ready for the author's input: no blocker
other than open `TODO(author)` markers.

## After three rounds

Stop. Report the score, the deductions still open with their quoted lines, and what
would fix each. Do not call it done.
