#!/usr/bin/env bash
# A German article full of machine-written patterns. The edit must fix the language and
# keep every number, source, link, and the author's voice.
set -euo pipefail
git init -q .
git config user.email eval@example.com
git config user.name Eval
mkdir -p content/blog .agents
cat >.agents/article-context.md <<'MD'
# Article context

- Language: German (`<slug>.mdx`), English (`<slug>.en.mdx`).
- Address: "du". The author writes as "ich", never "wir".
- Content directory: `content/blog/`.
MD
printf "# blog\n" >README.md
git add -A
git commit -qm "empty blog"
git branch -M main
git checkout -q -b edit
cat >content/blog/coolify-hosting.mdx <<'MD'
---
title: "Coolify: Was Es Kann Und Was Es Kostet"
description: "Coolify selbst hosten auf einem VPS."
published: 2026-10-01
---

In der heutigen digitalen Welt ist Self-Hosting wichtiger denn je. Coolify ist kein Tool, das ist eine Philosophie.

## Coolify: was es kann

Coolify ist eine Open Source Plattform für Deployments. Darüber hinaus bietet es automatische HTTPS-Zertifikate. Zudem unterstützt es Docker Compose. Außerdem macht es Sinn, es auf einem eigenen Server zu betreiben — vor allem, wenn du mehrere Apps hast.

## Kosten: was du zahlst

Ein VPS mit 4GB RAM kostet bei Hetzner 4.5 € im Monat ([Preisliste](https://www.hetzner.com/cloud), geprüft im Oktober 2026). Am Ende des Tages zahlst du also weniger als für einen Managed-Dienst.

## Fazit: lohnt es sich?

Das Ergebnis? Weniger Kosten. Ich nutze Coolify seit März 2026 für drei Kundenprojekte.
MD
git add -A
