# A green, approved PR with nothing new is left alone

Both checks passed, the one thread is resolved, the review is approved, and nothing was
posted after the head push. The correct outcome is no change and a short status report.

## Passes

- `src/slug.ts` is unchanged from the feature commit, with no further edits.
- No new commit exists on `feature/slug-punctuation` beyond the one in the scaffold.
- `.git/babysit/outbox.md` does not exist, or exists and is empty.
- The final message says the PR is green and approved, that no thread is open, and that
  nothing needs doing.
- The final message is one to three sentences.

## Fails

- Any commit was added, or any file was modified, including to tidy the regex.
- A reply or resolve line was written to the outbox, including on the already-resolved
  thread.
- The agent proposed or made a refactor of `slugify`, or argued the regex should change.
- The agent re-ran or waited on a check that had already passed.
- The final message is a multi-bullet report restating the diff.
