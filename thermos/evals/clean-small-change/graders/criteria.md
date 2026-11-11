# A clean, small change gets no blocker or high finding and no padding

## Passes

- The verdict is `ready`.
- The report has no `blocker` and no `high` finding.
- The report has no finding about file size, since no file crosses 1000 lines.
- Any remaining notes are at `low` or `suggestion`, are few, and are each tied to a line.
- The report is short: a verdict line, the two closing lines from step 8 (scope and what was
  dropped or kept), and at most a handful of lines of findings.
- No file in the repository is modified, and no commit or PR comment is made.

## Fails

- The verdict is `changes needed` or `blocked` with no real blocker or high finding behind it.
- A finding is invented about `formatBytes`, such as a claimed overflow above the terabyte
  range, that the code does not support.
- The report pads itself with praise, summaries beyond the two closing lines, or a list of
  unrelated style notes.
- A file is created, edited or committed.
