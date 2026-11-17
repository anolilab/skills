---
name: file-pr
description: >
  Opens a concise pull request for finished work on a branch: checks that no PR exists yet,
  reviews the diff against the base, writes a title in the repository's own convention and a
  description that leads with the problem, checks both for secrets and local details, then
  opens a real PR. Use when the user says file a PR, open a PR, create a pull request, or
  push this up for review. Opens nothing when the branch already has an open PR. Not for
  review comments (leaving-pr-comments), and not for work that is still in progress. Hands off to
  babysit-pr only when the user asked for that.
---

# File PR

Turn a finished branch into a pull request that a reviewer can judge in one read. The
title and description are the product here, so most of the work is deciding what they say.

## Before you file

1. **Look for an existing PR.** `gh pr list --head <branch> --state all`. If one is open,
   do not create a second. Update its description if the user asked, or report its link.
   A closed or merged one is a fact to mention, not a reason to stop.
2. **Start from the right branch.** If you are on the default branch, create a branch
   first. Never push to the default branch.
3. **Bring the base in.** Fetch, then rebase onto the latest base unless someone else has
   pushed to the branch, in which case merge it. Push a rebased branch with
   `--force-with-lease`, never `--force`.
4. **Read the diff against the base** (`git diff origin/<base>...HEAD`) and check it
   against the goal the user gave you. A stray debug line, an unrelated formatting change,
   or a leftover scratch file is a defect in the PR. Remove it, or tell the user if it is
   not yours to remove.

   A secret in the diff is worse: dropping it in a new commit leaves it in the branch
   history, and pushing publishes that history. Remove the file or line from the commit
   that added it (a non-interactive rebase, or `git commit --fixup` with autosquash),
   confirm it is gone from `git log <base>..HEAD -p`, and tell the user to rotate it. If
   the commit was already pushed, stop and ask.
5. **Run the repository's own checks** for what changed. A PR that fails them on arrival
   wastes the first review round.

## Title

PR titles usually become the squash commit, so follow the repository's convention. Read
the last 10 merged PRs (`gh pr list --state merged --limit 10`) and match their form,
including a conventional-commit type and scope when they use one.

Say why the change matters, in words a user would use. Do not describe the mechanism.

```
# no
fix(cart): round line totals with Math.round after multiplying
# yes
fix(cart): stop totals drifting by a cent on discounted items
```

If the repo derives releases from the title, pick the type with that in mind: a fix is
`fix`, a new capability is `feat`, and neither applies to docs or CI changes.

## Description

Use the repository's pull request template when it has one (`.github/pull_request_template.md`
or the template directory) and fill every section it asks for. Otherwise write this:

1. **The problem**, in two or three sentences, taken from what the user originally asked
   for. Write it so someone who has not seen the thread understands what was wrong or
   missing.
2. **The fix**, briefly: the behaviour that changes now, not a list of files or functions.
3. **How you know it works**: one line naming the check you ran or the reproduction you
   watched pass. Only claim what you observed in this session.

```
# no
Replaced the float multiplication in lineTotal with integer cents and updated the
callers in checkout.ts, invoice.ts, and the CSV export.
# yes
Discounted items could be a cent off at checkout, so invoices did not match the cart.
Totals are now computed in whole cents.
```

Link the issue the change closes (`Closes #123`) when there is one. Add screenshots only
when they show something the text cannot.

End with the attribution line that the user's or the harness's instructions call for. If
none applies, add none, and never guess a model name.

## Check what you are about to publish

A description is public as soon as it is posted, and edits stay in the history. Read the
title, the description, and anything you attach for:

- secrets, tokens, and credentials, including inside quoted logs
- local paths, usernames, machine and worktree names
- names or details from private notes, tickets, or conversations that the reader of this
  repository cannot see

Remove them before posting. Keep the cause when you quote a log.

## Open it

Push the branch first, then write the body to a file and pass it with `--body-file`, so
quotes and backticks survive.

```bash
git push -u origin <branch>
gh pr create --base <base> --head <branch> --title "<title>" --body-file <file>
```

Open a real PR, not a draft, so review bots run. Open a draft only when the user asked for
one. If `gh pr create` fails because the GraphQL quota is spent, the REST quota is
separate:

```bash
gh api repos/<owner>/<repo>/pulls -f title="<title>" -f head=<branch> -f base=<base> -F body=@<file>
```

If the harness has a tool that links a PR to the current thread, call it with the new URL.

## After it is open

- Do not post a follow-up comment unless it serves the user's request. When one is
  needed, use `leaving-pr-comments`.
- If the user asked you to babysit the PR, continue with `babysit-pr`. Otherwise stop.
- Never merge, and never enable auto-merge, unless the user asked for it in this
  conversation.

Report the PR link, the base and head, what you checked before filing, and anything you
removed from the diff or left for the user to decide.
