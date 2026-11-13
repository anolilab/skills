#!/usr/bin/env bash
# A small site with an article context file, one existing post, an affiliate registry,
# and a service the article can sell. The skill should write a new post that follows them.
set -euo pipefail
git init -q .
git config user.email eval@example.com
git config user.name Eval
mkdir -p content/blog src/data
cat >content/blog/rag-erklaert.mdx <<'MDX'
---
title: "Was ist RAG?"
description: "RAG kurz erklärt: Antworten aus den eigenen Dokumenten."
published: "2026-01-10"
lang: de
tags: ["KI"]
---

RAG verbindet ein Sprachmodell mit Ihren eigenen Dokumenten.
MDX
cat >src/data/affiliates.ts <<'TS'
export const affiliates = {
    hostinger: { name: "Hostinger", paid: true, url: "https://www.hostinger.com/" },
    hetzner: { name: "Hetzner", paid: false, url: "https://www.hetzner.com/" },
};
TS
printf "# site\n\nCompany website with a blog.\n" >README.md
git add -A
git commit -qm "site with blog"
git branch -M main
git checkout -q -b article
mkdir -p .agents
cat >.agents/article-context.md <<'MD'
# Article context

## Audience
Owners and operations leads of small German companies (5 to 50 people) who want to automate office work. Not developers.

## Language and voice
- German, formal "Sie". First person singular ("ich"), the author speaks from projects.

## Author
Daniel, freelance developer who sets up automations for clients.

## Format
- `content/blog/<slug>.mdx`. Frontmatter: title, description, published (YYYY-MM-DD), lang (de), tags (array), affiliate (boolean, true when the article has paid links).

## Components
- `<Affiliate id="...">Name</Affiliate>`: inline link for an entry in `src/data/affiliates.ts`. Paid entries render a marker.
- `<ServiceCta slug="workflow-automation" />`: the call to action. Once per article, after the main answer.

## Calls to action
- `workflow-automation`: automation setup with n8n or similar, fixed price.

## Affiliate links
- Registry: `src/data/affiliates.ts`. Use only ids listed there.
- Market: Germany. Articles with paid links set `affiliate: true`; the layout then shows the disclosure notice at the top.

## Internal links
- Articles: `/blog/<slug>`. Existing: `/blog/rag-erklaert`.

## Never
- Do not claim certifications or partner status.
MD
git add -A
