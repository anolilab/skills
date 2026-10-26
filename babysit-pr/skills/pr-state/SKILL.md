---
name: pr-state
description: >
  Reports, read-only, where the pull requests in play stand: checks, open review
  findings, review decision, mergeability, and the decisions still waiting on the user,
  in one table. Use when the user asks "state?", "what's the state", "where are we",
  "are the PRs green", "are all comments done", "what decisions are open", or "can we
  merge them". Never pushes, replies, resolves, or merges; to act on a PR, use
  babysit-pr.
---

# PR state

One table the user can read in ten seconds, built from live data. A PR you looked at an
hour ago has moved, so never answer from earlier turns.

This skill only reads. "Can we merge them?" is a question: answer it, and do not merge,
push, reply, or resolve.

## Pick the PRs

In order: the PRs the user names, the PRs the harness has linked to this conversation if
it tracks them, then the PR for the current branch. Note each one's base branch, so a
stack shows as a stack.

## Read each PR once

Every read below answers a question the others cannot, so run all of them:

```bash
gh pr view <n> --json headRefOid,baseRefName,reviewDecision,mergeStateStatus,mergeable,isDraft,state
gh pr checks <n> --required
gh api repos/<owner>/<repo>/pulls/<n>/reviews --paginate --jq '.[] | {user: .user.login, state, at: .submitted_at}'
gh api repos/<owner>/<repo>/issues/<n>/comments --paginate --jq '.[] | {id, user: .user.login, updated: .updated_at}'
```

Unresolved review threads come from GraphQL `reviewThreads(first: 100, after: $cursor)`
with `totalCount` and `pageInfo`. Page until `hasNextPage` is false: a PR with 117 threads
reads as "all resolved" if you stop after the first 100.

Bot summaries are edited in place, so compare their `updated` time, and read the body for
open findings and for the commit it reviewed (the SHA in its `/blob/<sha>/` links). A
summary that names an older commit, or says it is still running, means that reviewer is
not done.

When GraphQL quota runs out, `gh api repos/<owner>/<repo>/pulls/<n>` and
`gh api repos/<owner>/<repo>/commits/<sha>/check-runs` read the same state over REST.

## Call the state

A PR is `ready` only when all of these hold at the head commit:

- required checks pass;
- no review thread or bot finding is open;
- every review bot has read the head, except an advisory one such as `coderabbitai`;
- `reviewDecision` is approved, or the repository requires no review;
- `mergeStateStatus` is not `BEHIND`, `DIRTY`, or `BLOCKED`, and the PR is not a draft.

Anything less is `blocked`, followed by the first blocker in a few words.

## Background work

If you started agents or delegated tasks for these PRs, say which are running, finished,
or gone. A restart can end background work without a report, so check the ids you hold
and list the missing ones, so the user can choose to restart them.

## Answer

```
PR   base   checks   threads   bot findings   decision   state
#12  main   pass     0         2 open         approved   blocked: bot finding
#13  #12    pending  0         0              -          blocked: checks running
```

Then **Open decisions**, numbered, one line each with your recommendation, so the user
can answer "1 yes, 2 no". Collect them from deferred findings and from questions left
unanswered earlier. If there are none, say so in one line.

End with the single next action, and do not start it.
