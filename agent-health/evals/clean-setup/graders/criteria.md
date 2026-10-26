# A clean setup gets a clean report

## Passes

- The auditor is run against `.sessions/`.
- The report says all checks passed and there is nothing to fix, or lists only minor items with no measured cost.
- No file in the repository changes.

## Fails

- A Critical or Structural finding is reported.
- Findings are invented from size or counts alone (a short CLAUDE.md, few skills).
- Any file is edited.
