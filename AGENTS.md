# Repository guide

This repo publishes agent skills. It is consumed by other people's agents, so a skill
landing here is a shipped artifact, not a scratch note.

## Layout

```
.claude-plugin/
├── marketplace.json     # Claude Code marketplace; one plugin sourced from the repo root
└── plugin.json          # that plugin's manifest
hooks/
├── hooks.json           # plugin-level hooks, auto-discovered from this path
└── *.sh                 # hook scripts, executable
skills/
└── <skill-name>/
    ├── SKILL.md
    └── references/      # optional, read only once the skill is running
```

Both install paths read `skills/`, so a new skill needs no manifest edit. Add the
directory and it is picked up by `npx skills add` and by the Claude Code plugin alike.

## Adding a skill

### Frontmatter

Two required fields, both strings.

`name`: lowercase letters, numbers, and hyphens; 64 characters maximum. It cannot
contain `anthropic` or `claude`, which are reserved. Prefer a gerund (`reviewing-prs`)
or a plain action (`deslop`) over a vague noun. Never `helper`, `utils`, or `tools`.

`description`: 1,024 characters maximum, though far shorter is better because it is
preloaded into every session whether or not the skill fires. It must say **what the
skill does and when to use it**, including when not to. Write the "what" clause in the
third person, because the string is injected into a system prompt and a shifting
point of view hurts discovery:

```yaml
# yes
description: Removes AI-generated slop from a branch's changes: ... Use proactively
  once a batch of code edits is finished. Not for bug hunting or refactoring.

# no
description: I can help you clean up your code
description: Helps with code quality
```

Include the literal words a user would type. That is what routing matches on.

### Body

Keep `SKILL.md` under 500 lines. Assume the reader is already a competent engineer:
cut anything a capable agent already knows, and keep only what is specific to this
task, this repo, or this domain. Every paragraph should justify its tokens.

Match specificity to how fragile the task is. Where several approaches are valid,
give direction and let the agent choose. Where a sequence must be exact, give the
exact command and say not to deviate.

Move anything long or lookup-shaped into `references/`. Those files cost nothing until
they are read. Link them **directly from `SKILL.md`**, never from another reference
file: nested links get partially read and produce half-answers. Give any reference
file over 100 lines a table of contents at the top, so a partial read still reveals
the full scope.

Offer one default rather than a menu of options. Use forward slashes in every path.
Avoid anything that dates: no "as of 2026", no "the new API".

### Prose

Write it the way you would write for a colleague. No marketing voice, no emoji
headers, no em dashes, no rule-of-three padding, no summary section restating the
document. The `deslop` skill's own catalog is the reference for what to avoid, and it
applies to skills in this repo as much as to the code they review.

## Hooks

Hooks in `hooks/hooks.json` are active for everyone who installs the plugin, so they
need a higher bar than a skill does:

- **Fail open.** Every unexpected condition exits 0. A hook that errors must never be
  able to wedge someone's session.
- **Guard against loops.** A `Stop` hook must read `stop_hook_active` from its stdin
  payload and exit 0 when it is true. Claude Code overrides a Stop hook after eight
  consecutive blocks, and hitting that cap is a bug, not a safety net.
- **Give an opt-out.** An environment variable that disables the hook without
  uninstalling the plugin.
- **Do nothing when there is nothing to do.** Check real state first, such as whether
  the branch actually has changes.
- Mark scripts executable (`chmod +x`) and commit the bit.

## Before opening a PR

```bash
claude plugin validate . --strict     # manifests
npx skills add . --list               # discovery and frontmatter
bash -n hooks/*.sh                    # hook syntax
```

Check that the description renders sensibly in the `--list` output, since that is
roughly what an agent sees when deciding whether to fire the skill.

Test a skill by installing it and using it on a real task, not by reading it. The
failure mode you are looking for is the skill not triggering when it should, or
triggering when it should not.

## Commit messages

Describe the change on its own merits: the behaviour, the defect, the fix. Do not
name a product, package, vendor, or repository that an idea came from, and do not
reference private notes or tickets that identify one. A project name belongs in a
commit only when the code is *about* that project, such as an adapter or a migration
guide for it.
