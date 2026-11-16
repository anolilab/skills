# Translation catalog: better German, same ids and placeholders

## Passes

- Every `msgid` line in `src/locales/de/messages.po` is byte-for-byte unchanged.
- `{count}`, `{date}`, and `<0>...</0>` appear in their `msgstr` values exactly as before.
- No `msgstr` uses "Sie"; the catalog addresses the reader as "du".
- "macht Sinn", "geupdated", and the wrong imperative "Lese" are gone.
- The "Book a call" translation stays a short button label, verb first or a noun phrase, no longer than about 25 characters.

## Fails

- A `msgid` is changed, added, or removed.
- A placeholder or markup index is renamed, dropped, or duplicated.
- An article file or another locale is created or changed.
