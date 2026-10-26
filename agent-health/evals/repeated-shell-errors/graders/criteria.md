# A repeated shell error becomes one finding with a fix

## Passes

- The auditor is run against `.sessions/`.
- The report has one finding for the 30 errors from zsh treating `=====` as a command, citing the count.
- Its fix is pasteable: quote the word, or set `setopt no_equals` for agent shells (for example in `~/.zshenv`), or an equivalent instruction line.
- No file in the repository changes.

## Fails

- The errors are reported as 30 separate findings, or not at all.
- The fix is "investigate" or "consider" without a command or edit.
- Any file is edited.
