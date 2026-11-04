# Repository guide

This repo publishes agent skills. It is consumed by other people's agents, so a skill
landing here is a shipped artifact, not a scratch note.

<important if="you are adding a plugin, moving files, or changing the repo layout">

## Layout

One directory per plugin at the repo root, each self-contained. A plugin owns its
skills, its hooks, and its evals, so someone can install `deslop` without also taking
on whatever else lives here.

```
.claude-plugin/
└── marketplace.json     # lists every plugin by directory
<plugin-name>/
├── .claude-plugin/
│   └── plugin.json      # declares ./skills/ and ./hooks/hooks.json
├── package.json         # private, release metadata only; never published
├── CHANGELOG.md         # written by the release
├── hooks/               # optional
│   ├── hooks.json
│   └── *.sh             # executable
├── evals/
│   ├── README.md
│   └── <case>/
│       ├── prompt.md
│       ├── scaffold.sh
│       └── graders/criteria.md
└── skills/
    └── <skill-name>/
        ├── SKILL.md
        ├── references/  # optional, read only once the skill is running
        └── scripts/     # optional, executables the skill calls by path
```

A skill directory holds `SKILL.md`, its references, and any scripts the skill runs.
The `npx` installer copies the whole skill directory and nothing above it, which is
why hooks and evals sit at the plugin level instead.

**A new plugin needs a `marketplace.json` entry**, a `package.json`, and a line in
`pnpm-workspace.yaml`. A new skill inside an existing plugin needs none of these,
because `plugin.json` points at the whole `skills/` directory.

Group skills into one plugin when they share hooks or are always wanted together.
Split them when someone would reasonably want one and not the other.

Do not put a skill under `.claude/skills/` or `.agents/skills/` in this repo. The
`npx skills` installer discovers those directories, so the skill would be published
to everyone who installs from the repo. Keep repo-only helpers outside those paths.

</important>

<important if="you are writing or editing a SKILL.md or a skill's references">

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

</important>

<important if="you are adding or changing a hook, hooks.json, or a hook script">

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

`scripts/test-auto-deslop.sh` checks the deslop hook's opt-out, loop guard, dedupe, and
fail-open behaviour against throwaway repos. CI runs it. Add a case there when a hook
gains behaviour.

</important>

<important if="you are adding or changing an eval case, a scaffold, or a grader">

## Evals

Every skill gets at least three cases under `<plugin>/evals/<case>/`, each with a
`prompt.md`, a `graders/criteria.md`, and a `scaffold.sh` that builds a throwaway
repo for the case to act on. Mark the scaffolds executable.

Write graders as **Passes** and **Fails** lists of observable outcomes, not
impressions. "The `try`/`catch` around `JSON.parse` is untouched" can be checked;
"handles errors sensibly" cannot.

At least one case must be a **negative case**: input the skill should leave alone. A
suite of only positive cases rewards an over-eager skill, and over-eagerness is the
usual way a skill goes wrong.

```bash
python3 scripts/validate-package.py        # structure, frontmatter, prose, evals
claude plugin validate . --strict          # manifests
npx skills add . --list                    # discovery
claude plugin eval ./<plugin> --scaffold   # cases, when enabled for your account
```

The first three run in CI on every pull request, along with a shell syntax check,
the hook tests, and a step that executes every `scaffold.sh` and fails any that
produces an empty diff. `validate-package.py` needs no dependencies and no network.

Three other workflows run alongside it, all calling the shared definitions in
`anolilab/workflows`: a Conventional Commits check on the pull request title,
`zizmor` over these workflow files, and an OSSF scorecard.

The org's `dependency-review` workflow checks the release tooling's dependencies on
every pull request. It needs Dependency graph switched on in the repository settings.

What the validator enforces, so you do not have to remember it: frontmatter limits and
the name matching its directory, the 500-line skill body, references linked from
`SKILL.md` and existing, a `## Contents` heading on references over 100 lines, no
em or en dashes outside code fences, at least three eval cases each with a prompt,
graders carrying `## Passes` and `## Fails`, an executable `scaffold.sh`, a
`package.json` whose name and version match `plugin.json`, a `pnpm-workspace.yaml`
entry for every plugin, and manifest fields that Claude Code would otherwise ignore
in silence.

Pinning in CI is deliberate. Actions are pinned to commit SHAs because tags can be
retargeted, and the npm tools to exact versions so a new release cannot change the
result of an unchanged commit. Bump them in their own commit.

`--scaffold` runs author-supplied bash as you, so read the scaffolds first. The
runner adds a no-plugin baseline arm: if a case scores the same without the plugin,
the skill is not earning its place on that case.

Check that the description reads sensibly in the `--list` output, since that is
roughly what an agent sees when deciding whether to fire the skill. Then test on a
real task, not by reading. The failure you are hunting is the skill not firing when
it should, or firing when it should not.

</important>

<important if="you are adding or changing a skill, plugin, hook, or eval case in this repo">

## Authoring checklist

Use this order. The rules themselves are in the sections above, so read the ones that
match your change before you write.

1. **Place the change.** A new skill goes in an existing plugin's `skills/` directory.
   A new plugin needs a directory at the repo root, a `.claude-plugin/plugin.json`, a
   `package.json` copied from a sibling plugin, an entry in
   `.claude-plugin/marketplace.json`, and a line in `pnpm-workspace.yaml`. Start it at
   version `0.1.0`; the first `feat` or `fix` that merges releases it. See Layout and
   Releases.
2. **Write the skill.** Keep `SKILL.md` under 500 lines. Move long material into
   `references/` and link it directly from `SKILL.md`. See Adding a skill.
3. **Write at least three eval cases**, one of them negative. Each case needs a
   one-line `prompt.md`, a `graders/criteria.md` with a title and `## Passes` and
   `## Fails`, and an executable `scaffold.sh`. See Evals.
4. **Test each scaffold in an empty temp directory, never the repo root.** Scaffolds run
   `git init` and set git config, so running one in the repo rewrites your config.

   ```bash
   d="$(mktemp -d)" && (cd "$d" && bash <abs-path-to-scaffold>) && git -C "$d" diff --cached --stat main
   ```

   The diff must be non-empty. CI rejects a scaffold that produces an empty diff.
5. **Changed a hook?** Run `bash scripts/test-auto-deslop.sh`, and add a case for any
   new behaviour before you finish. See Hooks.
6. **Run the checks** from the repo root:

   ```bash
   python3 scripts/validate-package.py
   claude plugin validate . --strict
   bash scripts/test-auto-deslop.sh   # only when a hook changed
   ```

   Run `npx skills add . --list` when Node is available, and read the description line
   as an agent would see it. Check that it says when the skill should fire.
7. **Leave the work uncommitted** unless the user asks for a commit. Commit messages
   follow the rules below.

Gotchas: the validator rejects em and en dashes outside code fences, so write the word
instead. `claude plugin eval` may not be enabled on the account. If it isn't, report the
cases as unrun rather than passed.

</important>

<important if="you are changing a plugin version, package.json, CHANGELOG.md, or the release workflow">

## Releases

Claude Code caches an installed plugin by the `version` in its `plugin.json` and
only fetches it again when that string changes. A merged change that leaves the
version alone never reaches anyone who already installed the plugin.

So versions are not edited by hand. `.github/workflows/semantic-release.yml` runs
multi-semantic-release on every push to `main`. For each plugin directory that
received a `feat`, `fix`, `perf`, or breaking commit since its last
`<plugin>@<version>` tag, it writes the next version into `package.json` and
`.claude-plugin/plugin.json` (through `scripts/release/set-plugin-version.mjs`),
adds a `CHANGELOG.md` entry, commits that back as `chore(release): ...`, tags it, and
creates a GitHub release. The shared config is
`scripts/release/plugin.releaserc.json`. Nothing goes to npm, and every
`package.json` is private.

This is why the scope in a pull request title matters: the type decides the bump
(`feat` is minor, `fix` and `perf` are patch, `!` is major), and only commits that
touch a plugin's directory count for that plugin. A `docs`, `test`, `ci`, or `chore`
change releases nothing. Put `[skip release]` in the merge commit to hold a release
back.

</important>

<important if="you are writing a commit message, a PR title, or a PR description">

## Commit messages

Describe the change on its own merits: the behaviour, the defect, the fix. Do not
name a product, package, vendor, or repository that an idea came from, and do not
reference private notes or tickets that identify one. A project name belongs in a
commit only when the code is *about* that project, such as an adapter or a migration
guide for it.

**Pull request titles must follow Conventional Commits**, because the title is what
the check reads: `feat(deslop): ...`, `fix: ...`, `ci: ...`, `docs: ...`.

</important>
