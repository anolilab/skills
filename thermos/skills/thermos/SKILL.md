---
name: thermos
description: Runs a thermo-nuclear review of a branch's diff. Two Opus reviewers run in parallel, one for bugs, breakage, security, devex and feature-gate leaks, one for maintainability and code-judo, then their findings are checked and merged into one report. Use for thermos, thermo nuclear, thermonuclear, deep review, double review, or review before merge. Pass bugs or quality to run one pass only. For a PR, check it out first with gh pr checkout. Not for fixing findings, and not for a single question about a line of code.
---

# Thermos

Two reviewers audit the same diff from different angles. The first looks for things that
break: bugs, security holes, behaviour changes nobody asked for. The second looks for
things that rot: files that grow past a healthy size, branches that tangle, abstractions
that add indirection without removing any. Each reviewer returns findings with evidence.
You check them, merge the two lists, and report.

This skill reads and reports. It edits no file, posts nothing to the PR and fixes nothing.

## 1. Resolve the scope

Pick the base. Use the PR's base branch if the current branch has an open PR
(`gh pr view --json baseRefName --jq .baseRefName 2>/dev/null`). If `gh` is missing, not
logged in, or the branch has no open PR, that command prints nothing: treat it as no PR, skip
step 7, and go on to the next source. Otherwise use the remote's default branch
(`git symbolic-ref --short refs/remotes/origin/HEAD`, without the `origin/` prefix). The user
can name a base; that wins.

When a remote exists, fetch the base and compare against `origin/<base>`. When there is no
remote, use the local branch of that name. Then resolve the merge base and fail fast if
either step is empty:

```bash
git fetch --quiet origin "<base>" 2>/dev/null || true   # skipped when there is no remote
base=origin/<base>                                      # the local name when there is no remote
git rev-parse --verify --quiet "$base" >/dev/null || { echo "base does not resolve"; exit 1; }
mb=$(git merge-base "$base" HEAD)
git diff --stat "$mb" && git ls-files --others --exclude-standard
```

Diff the working tree against `$mb`, not `$base...HEAD`. That covers committed, staged and
unstaged changes. It does not cover untracked files, which the second command lists. If the
stat is empty and no untracked file exists, stop and say there is nothing to review.

Record the changed file list: `git diff --name-only "$mb"` plus the untracked files.

## 2. Measure file size against the base

For each changed file, compare its line count at the base with its count now:

```bash
git show "$mb:$f" 2>/dev/null | wc -l   # 0 for a new file
wc -l < "$f"
```

Note every file that moves from 1000 lines or fewer to more than 1000. A file that was
already over 1000 at the base is not a finding by itself. Pass the counts to the quality
reviewer.

## 3. Build the reviewer briefs

Read both rubrics:

- [references/review-rubric.md](references/review-rubric.md) for the bug and breakage reviewer.
- [references/quality-rubric.md](references/quality-rubric.md) for the quality reviewer.

Each reviewer gets a brief containing only:

- the base name and `$mb`, and the diff command to run;
- the changed file list, including untracked files, and for the quality reviewer the line
  counts from step 2. Untracked files are not in the diff, so the reviewer must read each one
  in full;
- its rubric, pasted in full;
- the output contract below.

Do not paste session history or your own conclusions. The reviewer forms its view from
the code. Tell each reviewer to read the code it cites, to trace callers and callees of
changed functions, and to stay read-only: no edits, no commits, no PR comments.

## 4. Launch both reviewers

Send both `Agent` calls in one message, each with `subagent_type: "general-purpose"`,
`model: "opus"` and `run_in_background: false`. The harness runs subagents in the background
unless told otherwise, and synthesis needs both results, so the flag must be set explicitly.
Give each reviewer the brief from step 3, and nothing else.

If the user asked for one pass (`bugs` or `quality`), launch only that reviewer.

## 5. Output contract for reviewers

Each reviewer returns a list, nothing else. Each finding has:

- severity: `blocker`, `high`, `medium`, `low` or `suggestion`;
- `file:line` for the code it is about;
- one sentence stating the defect;
- a trigger and a consequence, with concrete inputs and the wrong output;
- confidence: `confirmed` when it traced the path to the end, `plausible` when it could not.

No summary, no praise, no padding. An empty list is a valid answer. Ideas that improve
the code without fixing a defect are `suggestion` at most.

## 6. Check the findings before you report them

For every `blocker` and `high` finding, read the cited line yourself and confirm the
claim still holds against the code as it is. Drop a finding that does not hold, and say
in one line why. Keep a finding that holds but that you could not trace end to end as
`plausible`, and say what would settle it.

Merge the two lists. Remove duplicates where both reviewers flag the same line for the
same reason, and keep the higher severity. Keep the two passes' findings labelled by pass,
so the reader can see which lens found each one.

## 7. Check the PR discussion

Only after both reviews are in: if the branch has an open PR, read its review comments
and bot findings with `gh`. Validate each one against the code the same way. Add the
valid ones that the reviewers missed, and mark them as coming from the PR.

## 8. Report

Open with one verdict line:

- `ready` when there are no blocker or high findings;
- `changes needed` when there is at least one blocker or high that holds;
- `blocked` when a finding stops the change from shipping at all.

Then list the findings grouped by severity, blockers first. Each entry gives its pass,
`file:line`, the defect, and the evidence. After that, list the suggestions in a separate
section so they are not read as required work.

End with two short lines: what was reviewed (base, merge base, file count, any file the
reviewers could not read), and what was dropped or kept as plausible in step 6. Skip
anything the reader can get from the findings above.
