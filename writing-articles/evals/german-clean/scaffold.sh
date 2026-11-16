#!/usr/bin/env bash
# A German article a careful author wrote. The edit should leave it alone, or change only
# typography, and say that nothing else needed changing. Negative case.
set -euo pipefail
git init -q .
git config user.email eval@example.com
git config user.name Eval
mkdir -p content/blog .agents
cat >.agents/article-context.md <<'MD'
# Article context

- Language: German. Address: "du". The author writes as "ich".
- Content directory: `content/blog/`.
MD
printf "# blog\n" >README.md
git add -A
git commit -qm "empty blog"
git branch -M main
git checkout -q -b edit
cat >content/blog/backup-strategie.mdx <<'MD'
---
title: "Backups für kleine Server: die 3-2-1-Regel in der Praxis"
description: "Wie du einen kleinen Server mit der 3-2-1-Regel sicherst, ohne viel Geld auszugeben."
published: 2026-09-12
---

Drei Kopien, zwei Speicherarten, eine davon außer Haus: Mehr braucht ein kleiner Server nicht. Bei mir sind das der Server selbst, ein Snapshot beim Hoster und ein verschlüsseltes Archiv in einem zweiten Rechenzentrum.

## Was ein Snapshot nicht kann

Ein Snapshot liegt beim selben Anbieter wie der Server. Sperrt der Anbieter dein Konto oder fällt sein Rechenzentrum aus, sind beide weg. Deshalb zählt er nur als zweite Kopie, nie als die außer Haus.

## Wie oft du sichern solltest

Das hängt davon ab, wie viel Arbeit du verlieren kannst. Für meinen Blog reicht eine nächtliche Sicherung. Bei einem Shop mit Bestellungen würde ich stündlich sichern und die Datenbank zusätzlich mit Point-in-Time-Recovery betreiben.

Teste die Wiederherstellung mindestens einmal im Quartal. Eine Sicherung, die du nie zurückgespielt hast, ist eine Hoffnung.
MD
git add -A
