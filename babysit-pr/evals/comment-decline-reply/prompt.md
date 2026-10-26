A review bot says `toCents` in `src/price.ts` does not reject NaN. Reply on that thread
(`thread-nan`) with why no change is needed, then say you would resolve it.

This sandbox cannot reach GitHub. Do not run any `gh` command that writes. Write the
exact Markdown body you would have posted to `.git/comments/outbox.md`, one comment per
section headed `## <target>`. The GitHub login of the user is in `.git/comments/user.txt`;
use it where the skill would call `gh api user`.
