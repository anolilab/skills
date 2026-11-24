# German

Rules for articles written in German, on top of `style.md`'s general rules.
Write German directly. A German article drafted in English and translated sentence by
sentence keeps English word order, English idioms, and English punctuation, and
readers notice all three.

## Contents

- Register and address
- Word order and rhythm
- Verbs over nouns
- Anglicisms and calques
- Machine-written patterns in German
- Typography
- Numbers, dates, units
- Compounds and hyphens
- Gender and neutral wording
- What not to touch

## Register and address

- Use the context file's form of address, "du" or "Sie", everywhere: body text,
  headings, captions, components, calls to action, alt text. One "Sie" in a "du"
  article reads like a copy and paste from somewhere else.
- With "du", lowercase it ("du", "dein") in running text. Capitalising it is allowed in
  letters, not in articles.
- Keep the author's point of view. A single author writes "ich", never a corporate
  "wir". Do not add "ich" sentences the author did not supply; see "Never invent
  experience" in the skill.
- "Du" is not slang. Casual means short sentences and plain words, not "krass",
  "mega", or a modal particle in every sentence. One "ja", "eben", or "halt" in a
  paragraph is natural in a casual article; more reads forced. Formal articles use none.
- Legal and regulatory pages keep their formal register even when the blog uses "du".

## Word order and rhythm

German puts what links to the previous sentence in front, the new information at the
end. Machine-written German starts almost every sentence with its subject, copying
English, and the paragraph reads like a list.

```
Weak:   Der Server startet neu. Der Cache ist danach leer. Die erste Anfrage dauert 2 Sekunden.
Better: Nach dem Neustart ist der Cache leer, deshalb dauert die erste Anfrage 2 Sekunden.
```

- Move a time, a condition, an object, or a link word to the front where it carries the
  connection: "Danach", "Bei 10.000 Dokumenten", "Diesen Fehler", "Deshalb".
- Mix sentence lengths. A short sentence after two long ones lands; ten sentences of
  fifteen words each do not.
- Put the verb's second part where a reader can still hold the sentence. When the
  bracket ("Satzklammer") spans more than about 12 words, split the sentence.
- Use subordinate clauses where they show a relation (weil, wenn, obwohl, sodass).
  Strings of short main clauses lose the logic; nested clauses three deep lose the
  reader.

## Verbs over nouns

Turn nominal chains back into verbs when a person or process is behind them.

```
Weak:   Die Durchführung der Migration erfolgt nach der Erstellung eines Backups.
Better: Erstell zuerst ein Backup, dann migrierst du.
```

- "erfolgt", "findet statt", "kommt zum Einsatz", "stellt dar", "verfügt über",
  "fungiert als" usually hide "ist", "hat", or a plain verb. Use the plain one.
- Keep established terms and legal terms as nouns (Auftragsverarbeitung,
  Barrierefreiheitserklärung). Rewriting them changes the meaning.

## Anglicisms and calques

Keep English where German developers say the English word, and use it the same way
throughout: Deployment, Pull Request, Build, Container, Prompt, Token, Cache. Give an
English noun its usual German gender (der Commit, die Pipeline, das Deployment, der
Prompt, das Token or der Token as the project already uses it).

Replace English verbs and idioms that have a plain German form:

| Avoid | Write |
| --- | --- |
| macht Sinn | ergibt Sinn, ist sinnvoll |
| am Ende des Tages | letztlich, or the concrete result |
| in 2026 | 2026, im Jahr 2026 |
| einmal mehr | wieder, erneut |
| Das gesagt, ... | Trotzdem, Allerdings |
| der Test failt | der Test schlägt fehl |
| einen Fehler triggern | einen Fehler auslösen |
| null returnen | null zurückgeben |
| realisieren (for "notice") | merken, feststellen |
| eventuell (for "eventually") | schließlich, irgendwann |
| aktuell (for "actually") | tatsächlich |
| Peter's Blog | Peters Blog |
| Die Neue Version Im Test (title case) | Die neue Version im Test |
| adressieren (a problem) | angehen, lösen |
| basierend auf | auf Grundlage von, or rephrase with "nach" or "mit" |

A single loanword is not a finding. A paragraph whose structure is English (English
genitive, English word order, a literal idiom) is.

## Machine-written patterns in German

The general list in `style.md` applies. These are its German forms, and
the ones only German has:

- Contrast reveals: "Das ist kein X, das ist Y", "nicht nur X, sondern auch Y" in every
  other paragraph, "weniger X als vielmehr Y". One factual "nicht X, sondern Y" that
  corrects a misunderstanding is fine.
- Empty openers: "In der heutigen digitalen Welt", "Im Zeitalter der KI", "Wenn es um
  X geht", "Es ist wichtig zu beachten, dass".
- Announcements: "Schauen wir uns an", "Im Folgenden erfährst du", "Lass uns
  eintauchen", "Und genau hier wird es spannend". Start with the content.
- Additive connectors as glue: "Darüber hinaus", "Zudem", "Außerdem", "Ferner" opening
  sentence after sentence. Usually the order already shows the link; delete them.
- Inflated vocabulary in clusters: nahtlos, ganzheitlich, vielschichtig, beleuchten,
  eintauchen, maßgeschneidert, essenziell, bahnbrechend, "spielt eine entscheidende
  Rolle", "die digitale Landschaft". Name the concrete thing.
- Appended verdicts: "..., was die Bedeutung von X unterstreicht", "und zeigt damit,
  dass". A relative clause that adds no fact; cut it.
- Colon headings as a template: "Sonnet 5.5: das Arbeitstier", "Kosten: was du
  zahlst", repeated across the article. One is fine; when every heading has the
  form, rewrite most of them as plain statements or questions.
- Bold lead-ins on every list item ("- **Kosten:** ...") and bold scattered through
  paragraphs. Bold the one term a skimmer must catch.
- One-line drama paragraphs ("Genau das ist das Problem.") as a habit.
- Synonym rotation for the same thing (die Studie, die Untersuchung, die Analyse). Pick
  one word and keep it; German readers take a new word for a new thing.
- Forced casualness: "Ehrlich gesagt", "Spoiler:", "Kurz gesagt:" as openers.
- Colons as hinges inside sentences: "Wichtig für X: …", "Das Verfahren hat zwei
  Stufen: …", "Bei fast allen gilt: …". One per paragraph at most; otherwise two
  sentences or a "weil", "wenn", "denn".
- Semicolons in running text. German web writing hardly uses them.
- A figure appended after a comma: "…, also 35 %", "…, d. h. rund 40 Stunden".
- Balanced pairs that weigh two cases in one symmetric sentence: "X gehört nicht dazu,
  Y kann dazugehören". Say which case matters.

Fixing a pattern means rewriting the sentence, not swapping in a less suspicious
word. If removing the pattern leaves nothing, the sentence had nothing to say.

## Typography

- Quotes: „so“ (U+201E, U+201C). Nested: ‚so‘. Never "so" in running text and never
  „so” with an English closing mark. Code, JSX props, and frontmatter keep straight
  quotes.
- Dashes: no em dash. The spaced en dash is the German Gedankenstrich and is correct,
  but use at most one pair per paragraph and never as a dramatic pause. A hyphen with
  spaces is never a dash.
- Ranges and "bis": "9 bis 17 Uhr" in text; an unspaced en dash only in tables.
- Ellipsis: one character (…), with a space before it when it replaces words.
- Abbreviations with a narrow space or a normal space: "z. B.", "d. h.", "u. a.".
  Spell them out at the start of a sentence ("Zum Beispiel").
- Lists: fragments without a final period; full sentences with one. Do not mix in one
  list.

## Numbers, dates, units

- Decimal comma, period for thousands: 3,5 GB, 10.000 Anfragen, 1.790 $.
- A space between number and unit or symbol: 4 GB, 20 %, 5 €. The euro sign follows the
  number.
- Dates: 2. Dezember 2026, or 02.12.2026 in tables. Never "December 2" or "12/02".
- Times: 14:30 Uhr.
- Write out one to twelve in running text when no unit follows ("drei Server"), digits
  with a unit ("3 GB").
- Product versions keep their point: Opus 5.5, Node 22.3.

## Compounds and hyphens

- German compounds are one word: Datenbankserver, Wartungsvertrag.
- Hyphenate compounds that contain an English word, an abbreviation, a digit, or a
  name: Docker-Container, KI-Verordnung, API-Schlüssel, 2-Faktor-Login,
  Next.js-Projekt. Hyphenate the whole chain, not half of it: "Open-Source-Lizenz",
  not "Open Source-Lizenz".
- Never split a compound with a space ("Datenbank Server").

## Gender and neutral wording

Follow the context file. When it says nothing, prefer neutral forms that need no
special characters: Entwicklungsteam, Kundschaft, Teilnehmende, "wer einen Shop
betreibt". Do not alternate between systems within one article.

## What not to touch

- Quoted law text, quoted sources, and official names of laws, products, and
  authorities.
- Code, commands, file names, error messages, and UI labels quoted from a product.
- Fixed legal terms in legal pages and legal explainers.
- Numbers, dates, and citations. Typography may change (3.5 to 3,5); the value may not.
