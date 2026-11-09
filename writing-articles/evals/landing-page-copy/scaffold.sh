#!/usr/bin/env bash
# A site with a blog and an article context file, but the request is homepage copy.
# Negative case: no article should be written and the blog stays untouched.
set -euo pipefail
git init -q .
git config user.email eval@example.com
git config user.name Eval
mkdir -p content/blog src .agents
printf -- "---\ntitle: \"First post\"\npublished: \"2026-01-05\"\n---\n\nHello.\n" >content/blog/first-post.mdx
printf "# Article context\n\n## Format\n- content/blog/<slug>.mdx\n" >.agents/article-context.md
git add -A
git commit -qm "site with blog"
git branch -M main
git checkout -q -b copy
cat >src/hero.tsx <<'TSX'
export const Hero = () => (
    <section>
        <h1>We build websites</h1>
        <p>Web development for companies of every size.</p>
    </section>
);
TSX
git add -A
