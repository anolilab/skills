# Text that reads as written by a person

## Contents

- What detectors and readers react to
- The author's own words
- The rhythm pass
- Checking with a detector
- What not to do

## What detectors and readers react to

AI-text detectors score two things: how predictable each next word is, and how little
that predictability changes from sentence to sentence. A model-written draft picks the
likely word every time and keeps every sentence at the same length and shape. Readers
notice the same thing without a tool: the text is correct and has no edges.

Restyling a model draft only moves the score a little. In a test on one German article,
removing colons and semicolons and varying sentence length moved the detector's "human"
share from 19 % to 37 %, and it still classified the text as AI. Word choice stays
predictable when a model picks the words. What moves the score, and the reader, is
material a model would not have produced: the author's own sentences, opinions,
judgements, and details.

## The author's own words

Every article needs passages the author said or wrote themselves. Ask for them in the
brief, not after the draft:

- three to five sentences in their own words on the article's question: what they
  would tell a client across the table, what annoys them about the usual advice, what
  they would do first;
- one decision with its reason ("I would take X, because last time Y");
- any phrase they use that a textbook would not.

A voice note transcript or a few chat lines are enough. Keep their wording, including
an unusual verb or an incomplete thought; fix only spelling and facts, and only with
their consent. Put these passages where the article gives its verdict, not in a box
at the end. Until they arrive, leave `TODO(author)` markers; never write them yourself.

## The rhythm pass

After the draft and before the review, go through the text once for rhythm only:

- Mix sentence lengths on purpose. About one sentence in six has eight words or fewer;
  a few run past 25 words. Ten sentences of 15 words each read as generated.
- Turn most colons inside sentences into two sentences or a subordinate clause.
  "Wichtig für Projekte mit Dienstleistern: Bei Auftragsforschung zählen 70 %" reads as
  a template; "Lässt du extern entwickeln, zählen 70 % des Auftragswerts" does not.
- Drop semicolons in running text. Use a period or a conjunction.
- Give a figure its own clause instead of appending it after a comma ("…, also 35 %").
- Break symmetric pairs that weigh two options in one balanced sentence ("X gehört nicht
  dazu, Y kann dazugehören"). Say which one matters and why.
- Vary how sentences open. Front a time, a condition, an object, or a link word instead
  of starting sentence after sentence with the article.
- Vary paragraph shape. Not every paragraph is claim, detail, source.

`scripts/style_check.py` reports the measurable part: `flat-rhythm`, `few-short`,
`colon-density`, `label-colon`, `semicolons`, `appended-figure`, `same-openers`.

## Checking with a detector

A detector is a lead, not a gate. When one is available, scan the two or three most
generic sections, not the whole article. A high AI share there means the section needs
the author's material or a rhythm pass. A detector also flags plain, factual text
written by people, especially text full of numbers and legal terms, so never rewrite
a correct passage into something vaguer to lower a score.

## What not to do

- No "humanizer" tricks: deliberate typos, odd synonyms, random filler, or swapped word
  order. Readers lose clarity, and detectors are trained on exactly this output.
- No invented anecdotes, opinions, or "I tried" sentences to sound human. That breaks
  the rule against invented experience, whatever a detector says.
- No casual filler ("ehrlich gesagt", "krass") sprinkled in for effect.
