#!/usr/bin/env bash
# A blog with posts but no article context file. The skill should build the context file
# from what the repo shows and ask for the rest, not write an article on guessed facts.
set -euo pipefail
git init -q .
git config user.email eval@example.com
git config user.name Eval
mkdir -p content/posts
printf "# blog\n" >README.md
git add -A
git commit -qm "empty blog"
git branch -M main
git checkout -q -b article
cat >content/posts/hello-world.md <<'MD'
---
title: "Hello world"
date: 2026-02-01
summary: "Why this blog exists."
draft: false
---

I write about running small web services cheaply.
MD
git add -A
