# GitHub calls for babysitting a PR

## Contents

- Head commit and its time
- Review threads
- Review bodies and summary comments
- Review bots and status bots
- Checks
- Merge preflight
- Reply to a thread, resolve a thread, push, retarget

Read-only calls come first. Write calls, which post, resolve, or push, come after and
should only run for threads you have decided to act on.

## Head commit and its time

```bash
gh pr view <number> --json headRefName,headRefOid,mergeable,mergeStateStatus,reviewDecision,commits \
  --jq '{head: .headRefOid, branch: .headRefName, mergeable, mergeStateStatus, reviewDecision, lastCommit: .commits[-1].committedDate}'
```

`reviewDecision` is `APPROVED`, `CHANGES_REQUESTED`, `REVIEW_REQUIRED`, or empty when
the repository requires no review. An empty value is not a pass by itself: check that
the branch protection rules require no review before treating it as approved.

## Review threads

Threads come from GraphQL. The REST pulls endpoint does not expose resolution state.

```bash
gh api graphql -F owner=<owner> -F repo=<repo> -F number=<number> -f query='
query($owner: String!, $repo: String!, $number: Int!, $after: String) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $number) {
      reviewThreads(first: 100, after: $after) {
        totalCount
        pageInfo { hasNextPage endCursor }
        nodes {
          id
          isResolved
          isOutdated
          path
          line
          comments(first: 20) {
            nodes { databaseId author { login } createdAt body }
          }
        }
      }
    }
  }
}'
```

Filter to `isResolved: false`, then to comments whose `createdAt` is after the boundary,
or whose code still has the problem. While `hasNextPage` is true, repeat the call with
`-F after=<endCursor>`. A PR with 117 threads reads as "all 100 resolved" if you stop
after the first page, so compare the number of nodes you read with `totalCount`.

## Review bodies and summary comments

```bash
gh api repos/<owner>/<repo>/pulls/<number>/reviews --paginate \
  --jq '.[] | {id, user: .user.login, state, at: .submitted_at, body}'
gh api repos/<owner>/<repo>/issues/<number>/comments --paginate \
  --jq '.[] | {id, user: .user.login, created: .created_at, updated: .updated_at}'
```

A summary comment keeps its `id` and moves its `updated` time each time the bot
re-reviews. Treat a changed `updated` as new. Fetch one body with
`gh api repos/<owner>/<repo>/issues/comments/<id> --jq .body`, and strip the markup
before reading: `sed -E 's/<[^>]+>/ /g'`.

Reading a summary:

- The header carries a count per category, such as "Bugs (2)". Reconcile your list
  against it.
- Findings the bot marks "Resolved" or "Outdated" are closed.
- The commit it reviewed shows in the permalinks (`/blob/<sha>/`). The most common SHA
  there is the commit it read. If it is not `headRefOid`, the review is stale.
- A body that says it is working, or "review in progress", is not a result yet.
- A review body can list findings that never became threads, under headings such as
  "Outside diff range comments" and "Nitpick comments". Count those too.

## Review bots and status bots

| Kind | Logins | Treat as |
| --- | --- | --- |
| Review bots | `coderabbitai`, `qodo*`, `copilot-pull-request-reviewer`, `greptile*`, `sourcery-ai` | Findings. Read their summaries and inline threads. |
| Status bots | `netlify`, `vercel`, `codspeed*`, `codecov*`, `pkg-pr-new`, `github-actions`, `socket-security` | Noise unless the body reports a failure. |

Match the login without the `[bot]` suffix. A bot that is not in the table and posts a
list of problems is a review bot.

## Checks

```bash
gh pr checks <number>                       # summary
gh pr checks <number> --required            # the checks that gate the merge
gh pr view <number> --json statusCheckRollup \
  --jq '.statusCheckRollup[] | {name, conclusion, status, detailsUrl}'
gh run view <run-id> --log-failed           # the failing steps only
```

Wait for checks to finish with `gh pr checks <number> --watch --interval 60`. Add
`--fail-fast` to stop at the first failure.

To rerun only the failed jobs of a run: `gh run rerun <run-id> --failed`.

## Merge preflight

Run this in one pass, against the commit you are about to merge, only when the user
asked for the merge:

```bash
head=$(gh pr view <number> --json headRefOid --jq .headRefOid)
gh pr checks <number> --required                      # all pass
gh pr view <number> --json mergeStateStatus,reviewDecision,mergeable
# threads: page to totalCount, none unresolved
# summaries and review bodies: reviewed $head, no open finding
```

Merge with the method the repository uses, for example
`gh pr merge <number> --squash`. Add `--admin` only when the user said to bypass the
rules for this merge. Check `state` and `mergedAt` afterwards.

## Reply to a thread

```bash
gh api graphql -F threadId=<thread-node-id> -F body='<reply>' -f query='
mutation($threadId: ID!, $body: String!) {
  addPullRequestReviewThreadReply(input: {pullRequestReviewThreadId: $threadId, body: $body}) {
    comment { id }
  }
}'
```

The `threadId` is the thread's `id` from the query above, not a comment's `databaseId`.

## Resolve a thread

Only after replying to it.

```bash
gh api graphql -F threadId=<thread-node-id> -f query='
mutation($threadId: ID!) {
  resolveReviewThread(input: {threadId: $threadId}) { thread { id isResolved } }
}'
```

`unresolveReviewThread` is the inverse. Use it only if you resolved a thread by mistake.

## Push

```bash
git push                            # normal case
git push --force-with-lease         # only after a rebase
```

Never `--force`. `--force-with-lease` refuses to overwrite commits you have not seen,
which is the protection a rebase needs.

## Retarget a stacked PR

After the base PR merges:

```bash
gh pr edit <number> --base <new-base>
git fetch origin
git rebase --onto origin/<new-base> <old-base-tip>
git push --force-with-lease
```

`<old-base-tip>` is the last commit of the merged base branch, which the squash merge
replaced. Without `--onto` the rebase replays commits the base already contains.
