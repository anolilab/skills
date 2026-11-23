---
name: ship
description: >
  Takes finished work on a branch through deslop, one thermos review, proof, a PR, and
  babysit-pr, and merges it once the gate passes when the user says full send. Use when
  the user says ship it, ship, full send, full stop, or asks to open a PR for work that is
  done and have it carried through. Stops with the PR ready and unmerged unless the user
  said full send. Not for work still in progress, not for someone else's PR, and not for
  opening a PR alone (file-pr).
---

# Ship

The sequence otherwise typed out by hand: clean, review, fix, prove, open, babysit, merge.
Each step ends on a check you can run. Stop at the first step that cannot meet its check
and report.

This skill orchestrates `deslop`, `thermos`, `file-pr` and `babysit-pr`. If one is not
installed, do that step's job directly and say so in the report.

## Modes

- **Default, or "full stop":** end with the PR ready and unmerged.
- **"Full send":** also merge at the gate in step 7, and force-push this branch with
  `--force-with-lease` after a rebase. That phrase is the user's permission to merge.
  Nothing weaker counts: "ship it" alone does not merge.
- **`stop before pr`** ends after step 4. **`no babysit`** ends after step 5.

Either mode is the user's permission for the test methods step 4 needs (running the app,
a browser, screenshots), even where a project file says to ask first.

The user is often away while this runs. Ask through the harness's question tool, with the
PR link, the blocker, and your recommended option first, because a plain message goes
unread and the thread looks finished. If the harness has none, leave the PR open and
unmerged and start the final message with the question.

## 0. Check there is something to ship

Confirm the branch has a diff against its base and that the work is finished: no `wip`
commits, no stubbed or `not implemented` code, no leftover TODO for the goal, and the
repo's checks pass. If not, stop and ask whether to finish it or ship it as it is.

If the branch already has an open PR whose head is your local `HEAD`, steps 1 to 5 are
done: log them as skipped and resume at step 6. Commit nothing, because a new head
restarts every review bot.

## 1. Deslop

Run the `deslop` skill on the branch. Done when it reports and the repo's typecheck and
lint pass on the touched files. Reviewers should not spend findings on slop a cheap pass
removes.

## 2. Review, once

Run the `thermos` skill one time on the diff, with its reviewers on the strongest model available.
Done when both have returned and you have one deduplicated list.

Do not run it again after the fixes. The PR's review bots, such as qodo and coderabbit,
read every push, so a second internal review only repeats what step 6 collects. If the
repository or the user asks for an independent review before every push, that rule wins:
follow it in step 6 too.

## 3. Fix

Fix every finding that is real, in parallel where the files do not overlap, with each
agent that edits files on an explicit capable model, never the small one meant for
searching. Decline false alarms with the line that refutes them. A finding that needs a
product decision goes on a numbered deferred list. Done when the repo's own checks pass
and each finding is fixed, declined, or deferred.

## 4. Prove it

Proof is evidence you observed in this session, not a claim. Reproduce the original
failure, apply the fix, then show the same reproduction passing. Run the checks CI runs.
For UI or runtime behaviour, run the app and look at it, because green mocked tests do
not show the experience works. Done when every change in the diff has proof and you have
one line saying how. That line goes in the PR body. If a change cannot be proven, ask.

## 5. Open the PR

Run the `file-pr` skill against the branch's real base, which is not always `main`. It
opens nothing when the branch already has a PR, so a resumed ship carries on with that
one. If the harness can link a PR to the thread, link it. Done when the PR exists.

## 6. Babysit

Run the `babysit-pr` skill. It treats qodo as a reviewer that must read the head commit,
and coderabbit as advisory: its findings get handled when they arrive, and its review is
never waited for. Get proof for each fix before you push it. Wait with the harness's PR
watcher and end the turn, and stop the watcher before the final message or any question.

## 7. Merge gate

All of these hold on the latest head commit:

- proof covers every change in the diff;
- required checks pass (`gh pr checks --required`);
- every review bot except the advisory one has reviewed the head, and each finding is
  fixed or declined with a written reason;
- no human review requests changes;
- the branch is not conflicting, and it is not `BEHIND` or touched by a base commit since
  the last green run. With a merge queue, `BEHIND` alone is fine: the queue tests the PR
  on the latest base.

Default and full stop: report the PR as ready and stop. Full send: run the merge
preflight in the `babysit-pr` skill, then merge with the method the repo uses (check
recent merges), and stay until GitHub reports it merged if a queue or auto-merge is in
use. Until it lands, every wake checks the review bots again: if one starts a new review
after you queued the PR, take it out of the queue (or turn auto-merge off) and queue it
again only once that review is done and clean. Never pass `--admin` or bypass a rule
unless the user asked for that merge to bypass them. A gate that cannot pass goes to the
user as a question.

## Ask only when stuck

Ask only when you cannot prove a change, the gate cannot pass and you cannot fix it, the
next step would delete data, touch production, close a PR, or force-push another branch,
or another PR makes this one obsolete. Decide everything else yourself and list the
decisions in the report.

## Final message

The PR link, the merge commit or the ready head, the proof, and the decisions you made,
numbered. Say which steps ran and which you skipped.
