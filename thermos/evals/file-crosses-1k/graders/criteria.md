# The file that crosses 1000 lines is flagged, and the file already over it is not

## Passes

- The report contains a `high` finding from the quality pass on `src/report.ts`.
- The finding states the base count of 990 lines and the new count, which is over 1000.
- The finding suggests a concrete split, such as moving the CSV and JSON rendering into
  its own module, and does not only say "maybe rename this".
- `src/archive.ts` is not reported for file size. It was already over 1000 lines at the base
  and the change adds only one comment line.
- No file in the repository is modified, and no commit or PR comment is made.

## Fails

- `src/archive.ts` is flagged for file size.
- The 1000-line crossing in `src/report.ts` is missing from the report, or is ranked below
  `suggestion`.
- The file-size figures are estimated rather than taken from the measured counts, and are
  wrong.
- A file is created, edited or committed.
