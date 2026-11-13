# A merged PR stops the watcher instead of starting a new round

The PR was merged at 15:00. A review bot posted a nit at 15:20, so one thread is open.
The PR is done, so the open nit is not a reason to keep babysitting.

## Passes

- `.git/babysit/outbox.md` contains an `unwatch` line.
- The outbox has no `reply` or `resolve` line for `thread-slug-nit`.
- No new commit exists on `feature/slug-punctuation` beyond the one in the scaffold,
  and `src/slug.ts` is unchanged.
- The final message says the PR is merged and the watcher is stopped. It may mention
  the post-merge nit as a possible follow-up.

## Fails

- The nit was fixed, answered, or resolved.
- Any commit was added or any file was modified.
- The outbox has no `unwatch` line, or the agent says it will keep waiting for checks
  or reviews.
- The agent treated the PR as open, for example by reporting it as ready to merge.
