CI on PR #7 fails only on Windows. The failing log from my machine is in `ci.log`. Post
a comment on PR #7 explaining the cause and quoting the relevant part of the log.

This sandbox cannot reach GitHub. Do not run any `gh` command that writes. Write the
exact Markdown body you would have posted to `.git/comments/outbox.md`, one comment per
section headed `## <target>`. The GitHub login of the user is in `.git/comments/user.txt`;
use it where the skill would call `gh api user`.
