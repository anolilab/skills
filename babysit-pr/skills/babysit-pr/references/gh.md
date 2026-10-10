# GitHub calls for babysitting a PR

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
query($owner: String!, $repo: String!, $number: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $number) {
      reviewThreads(first: 100) {
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
or whose code still has the problem. If `reviewThreads` reports more than 100 nodes,
page with `pageInfo { hasNextPage endCursor }` and an `after:` argument.

## Checks

```bash
gh pr checks <number>                       # summary
gh pr view <number> --json statusCheckRollup \
  --jq '.statusCheckRollup[] | {name, conclusion, status, detailsUrl}'
gh run view <run-id> --log-failed           # the failing steps only
```

Wait for checks to finish with `gh pr checks <number> --watch --interval 60`. Add
`--fail-fast` to stop at the first failure.

To rerun only the failed jobs of a run: `gh run rerun <run-id> --failed`.

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
