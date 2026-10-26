---
name: leaving-pr-comments
description: >
  Formats and posts a GitHub comment that an agent writes on the user's behalf: PR and
  issue comments, inline review comments, thread replies, and the reason given before
  resolving a thread. Marks it as agent-written, keeps it short, strips secrets and local
  details, and posts it without shell quoting damage. Use whenever you comment, reply,
  or review on GitHub. Not for PR descriptions, commit messages, or text the user asks
  to post word for word.
---

# Leaving PR comments

A comment posted from the user's account reads as the user's own words. Mark it as
written by an agent, say one useful thing, and make sure it arrives intact.

## Shape

Open with a note callout that names the model and the person it speaks for. Put the
comment itself below it:

```md
> [!NOTE]
> 🤖 **<model> responding on behalf of <login>**

<the comment>
```

- `<model>` is the public model name the harness reports for this session. If it
  reports none, use the harness name. Never guess.
- `<login>` comes from `gh api user --jq .login`.
- One callout per comment. No signature, no horizontal rule, no heading above or below.
- Editing an earlier agent comment keeps its callout. Update the model if a different
  model made the edit.

## The comment

- Lead with the conclusion: fixed, declined, or needs a decision.
- Back it with something checkable: a commit SHA, a `path:line`, a command and its
  output, a test name.
- Keep fact and judgment apart. "The guard at `src/cart.ts:12` already rejects NaN" is a
  fact; "a second guard would be noise" is judgment, so say it as one.
- One or two sentences is usually enough. No thanks, no "great catch", no restating the
  reviewer's point, no status narration.
- A bare `@name` notifies that person. Write one only for a real login you mean to
  notify; put roles, placeholders, and package scopes (`@types/node`) in backticks.

## What must not leave the machine

Read the whole body, including quoted text and log excerpts, before posting. Remove:

- tokens, keys, passwords, and connection strings, even partial ones;
- absolute local paths (`/Users/...`, `/home/...`), worktree names, temp paths, and
  session or thread ids;
- internal hostnames, private repository names, and private tickets or notes;
- the name of another project an idea was taken from, unless the work is about that
  project.

Quote the smallest excerpt of a log that makes the point.

## Posting

Write the body to a file and pass the file, so backticks, `$`, and quotes survive:

```bash
f=$(mktemp)
cat >"$f" <<'BODY'
...
BODY
gh pr comment <number> --body-file "$f"                    # top-level PR comment
gh api repos/<owner>/<repo>/issues/<number>/comments -F body=@"$f" --jq .html_url
```

For a review thread reply, pass the same body to the GraphQL
`addPullRequestReviewThreadReply` mutation with `-F body=@"$f"`.

Before posting after a restart or a resumed session, check whether the same reply is
already there. A second copy of an agent comment is noise.

After posting, confirm GitHub returned the comment's URL or id. Resolve a thread only
once its reply has posted.
