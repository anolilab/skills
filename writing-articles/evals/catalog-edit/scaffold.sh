#!/usr/bin/env bash
# A German translation catalog with literal translations. The edit must improve the
# German msgstr values and leave msgid, placeholders, and markup indexes untouched.
set -euo pipefail
git init -q .
git config user.email eval@example.com
git config user.name Eval
mkdir -p src/locales/de .agents
cat >.agents/article-context.md <<'MD'
# Article context

- Languages: English (default) and German. German address: "du".
MD
printf "# site\n" >README.md
git add -A
git commit -qm "empty site"
git branch -M main
git checkout -q -b edit
cat >src/locales/de/messages.po <<'PO'
msgid ""
msgstr ""
"Language: de\n"

msgid "Book a call"
msgstr "Buchen Sie einen Anruf"

msgid "It makes sense to start small."
msgstr "Es macht Sinn, klein zu starten."

msgid "Read {count} articles about <0>self-hosting</0>"
msgstr "Lese {count} Artikel über <0>Self-Hosting</0>"

msgid "Last updated on {date}"
msgstr "Zuletzt geupdated am {date}"
PO
git add -A
