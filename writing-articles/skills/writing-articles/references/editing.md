# Editing existing text

How to improve the language of text that already exists: published articles, drafts,
and site copy such as page text and translation catalogs. The goal is text a careful
native author would have written, with every fact, claim, and promise unchanged.

## Contents

- Locks
- Order of work
- When to change a sentence
- When to stop
- Site copy and translation catalogs
- Both languages
- Report

## Locks

Before the first edit, list what must survive. Compare it again after the last edit.

- **Claims:** numbers, prices, dates, names, versions, quotes, citations, links, and
  legal references. Typography may change (3.5 to 3,5 in German); the value may not.
  A sentence that becomes shorter must keep its conditions ("bis zu", "in der Regel",
  "ab 1. Juli").
- **Voice:** the form of address, the author's "ich", their opinions and verdicts.
  Do not add experience, anecdotes, or opinions the text does not contain. Do not
  soften a verdict into a hedge.
- **Structure that others rely on:** slugs, heading anchors that are linked from
  elsewhere, frontmatter keys, component names and props, translation message ids
  and placeholders.
- **Legal text:** quoted law, imprint, privacy policy, terms, consent texts, and
  disclosure labels. Fix only typos there, and list each fix in the report.

## Order of work

1. Read the whole text once as the reader. Note where you lost the thread, where a
   paragraph answered nothing, and where the tone changed.
2. Run the checker on the file and keep its output:

   ```bash
   python3 <skill-dir>/scripts/style_check.py <file>
   ```

   Errors must be gone at the end. Warnings are leads: confirm each one in context
   before acting.
3. Fix substance first: a paragraph that repeats the previous one, a sentence that
   says nothing, an unclear reference ("dies", "das" with no clear antecedent).
4. Then the language rules for the text's language: `german.md` or
   `english.md`, and the general list in `style.md`.
5. Then typography and numbers.
6. Read it once more aloud in your head, slowly, for spelling, grammar, and agreement
   (German case endings and gender after edits are where new errors appear).
7. Run the checker again and compare the locks.

## When to change a sentence

- A hard pattern (stock phrase, contrast reveal, em dash, wrong quote mark, hidden
  character, calque, a claim drifting from its source) is fixed where it appears.
- A soft pattern (a connector, a colon heading, one bold term, a subject-first
  sentence) is a finding only when it repeats. One is the author's choice.
- Make the smallest change that removes the problem. Rewriting a whole paragraph to fix
  one phrase changes the author's voice and makes the change hard to review.
- Never make text worse to look less machine-written: no inserted typos, slang,
  filler, or fragments.

## When to stop

A careful author's text can come back with no changes, or only typography. That is a
normal result: say so and stop. Editing to show effort is the most likely mistake in
this mode.

## Site copy and translation catalogs

- In catalogs (`.po`, JSON, YAML), change only the translation, never the message id or
  key. Keep placeholders (`{0}`, `{name}`, `<0>...</0>`), their order where the
  grammar allows, and any trailing space or punctuation the UI relies on.
- Buttons and navigation labels stay about as long as before; a longer label can break
  the layout. Check the rendered page when one grows by more than a few characters.
- Use one term for one thing across the whole site, and match the term the articles
  use.
- Calls to action keep their verb first and their promise unchanged.

## Both languages

When an article exists in German and English, edit each in its own language, then
compare the pair: same facts, numbers, sources, links, and sections. Fix a fact in
both or in neither. The sentences do not need to match.

## Report

End with:

- files changed, and files checked and left unchanged;
- per file: the checker's errors before and after, and the kinds of changes made
  (for example "12 calques, 5 colon headings, quote marks");
- every lock that needed care, such as a shortened sentence whose condition you kept;
- anything you did not change because it needs the author: an unclear claim, a missing
  source, a section that adds nothing.
