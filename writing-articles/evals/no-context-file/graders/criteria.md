# Missing context file: build it, ask, do not guess

## Passes

- `.agents/article-context.md` is created.
- It records the content directory `content/posts/` and the frontmatter fields seen in `hello-world.md` (`title`, `date`, `summary`, `draft`).
- The reply asks the user, in one message, for what the repo does not show, such as the audience, the voice, or the author.
- No new article file is written under `content/posts/` before those answers arrive.

## Fails

- A Plausible article is written into `content/posts/` in this turn.
- The context file invents an author name, credentials, or an audience that nothing in the repo states, without marking them as questions.
- The reply asks a series of separate questions over several turns instead of one message.
