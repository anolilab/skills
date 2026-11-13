<div align="center">

# anolilab skills

**Skills for Real Engineers. Straight from my `.agents` directory.**

[**Skills**](#skills) · [**Install**](#install) · [**Claude Code plugins**](#claude-code-plugins) · [**Contributing**](#contributing)

<br />

[![Validate][validate-badge]][validate]
[![OpenSSF Scorecard][scorecard-badge]][scorecard]
[![MIT licence][license-badge]][license]
[![PRs Welcome][prs-welcome-badge]][prs-welcome]

</div>

---

<div align="center">
    <p>
        <sup>
            Daniel Bannert's open source work is supported by the community on <a href="https://github.com/sponsors/prisis">GitHub Sponsors</a>
        </sup>
    </p>
</div>

---

## What is this?

Agent skills for the parts of the job that go wrong when an agent does them on
autopilot: cleaning up its own diff, carrying a PR through review rounds, building UI
that matches the product, and checking the agent setup itself. They work with Claude
Code, Codex, OpenCode, Cursor, Gemini CLI, and the other agents the
[`skills`](https://www.npmjs.com/package/skills) installer supports, and every one
also ships inside a Claude Code plugin.

## Quick start

```bash
npx skills add anolilab/skills
```

The installer lists the skills, asks which to install, and detects which agents you
use. Add `--all` to take everything without prompts, or `-g` to install globally
rather than into the current project.

## Skills

| Plugin | Skill | What it does |
| --- | --- | --- |
| `deslop` | [`deslop`](deslop/skills/deslop/) | Strips AI-generated slop out of the changes on a branch: narrating comments, unasked-for defensive code, `any`/`unknown` casts, single-use wrappers, mock-heavy tests. Behaviour stays identical. Can run on its own when a turn ends. |
| `babysit-pr` | [`babysit-pr`](babysit-pr/skills/babysit-pr/) | Takes an open PR you wrote through review and CI rounds: fixes the real findings, answers and resolves the rest, pushes, and stops at green and approved or at a stop point you set. Merges only when you ask. |
| | [`leaving-pr-comments`](babysit-pr/skills/leaving-pr-comments/) | Formats every GitHub comment an agent posts for you: marks it as agent-written, keeps it short and checkable, strips secrets and local paths, and posts it without quoting damage. |
| | [`pr-state`](babysit-pr/skills/pr-state/) | Answers "state?" with one table of the PRs in play: required checks, open threads and bot findings, review decision, mergeability, and the decisions waiting on you. Read-only. |
| `teardown` | [`teardown`](teardown/skills/teardown/) | Compares another project against yours and returns a ranked, evidence-backed list of what it has that you lack, checked against your code first. Builds nothing until you pick items. |
| `thermos` | [`thermos`](thermos/skills/thermos/) | Runs a thermo-nuclear review of a branch: one Opus pass for bugs, breakage, security and feature-gate leaks, one for maintainability and file size, each checked against the code, merged into one report. Edits nothing. |
| `ui` | [`ui`](ui/skills/ui/) | Builds and fixes web and React Native or Expo interfaces in the product's own style, from a complaint or a screenshot, and checks the result rendered in a browser or simulator. |
| `agent-health` | [`agent-health`](agent-health/skills/agent-health/) | Audits your agent setup and recent session transcripts (instructions, settings, hooks, memory, skills, repeated errors, blocked commands, review loops) and reports each problem with evidence and a pasteable fix. Report-only. |

## Why these skills

**They match the repo, not a house style.** Every skill reads the codebase it works
in first: its conventions, lint config, history, and neighbouring files. "Would the
person who wrote the rest of this file have written this line?" is the bar.

**Restraint is tested.** Each skill has graded eval cases, and at least one per skill
is a negative case where the right answer is to change nothing. Over-eager edits are
the usual way an agent skill goes wrong, so most cases are aimed at that.

**Repository text is data.** Diffs, review comments, fixtures, and commit messages are
material to work on, never instructions to follow. A comment addressed to an agent is
reported, not obeyed.

**They are cheap to carry.** Descriptions stay short because they load into every
session. Long material sits in `references/` and is read only when the skill runs.

## Install

### A specific agent

Pass `-a` with the agent's slug. Repeat it to target several at once.

```bash
npx skills add anolilab/skills -a claude-code
npx skills add anolilab/skills -a claude-code -a codex -a opencode

# every detected agent
npx skills add anolilab/skills --agent '*'
```

Where the files land:

| Agent | `-a` slug | Project path | Global path (`-g`) |
| --- | --- | --- | --- |
| Claude Code | `claude-code` | `.claude/skills/` | `~/.claude/skills/` |
| Codex | `codex` | `.agents/skills/` | `~/.codex/skills/` |
| OpenCode | `opencode` | `.agents/skills/` | `~/.config/opencode/skills/` |
| Cursor | `cursor` | `.agents/skills/` | `~/.cursor/skills/` |
| Gemini CLI | `gemini-cli` | `.agents/skills/` | `~/.gemini/skills/` |
| GitHub Copilot | `github-copilot` | `.agents/skills/` | `~/.copilot/skills/` |
| Amp | `amp` | `.agents/skills/` | `~/.config/agents/skills/` |
| Zed, Cline, Warp | `zed`, `cline`, `warp` | `.agents/skills/` | `~/.agents/skills/` |

Around 77 agents are supported in total. `npx skills add anolilab/skills --list` shows
what is in this repo before you install anything.

### One skill only

```bash
npx skills add anolilab/skills --skill deslop
```

### Without installing

```bash
npx skills use anolilab/skills --skill deslop --agent claude-code
```

## Claude Code plugins

Each plugin installs on its own, so you take only what you want. The plugin route also
brings the `deslop` hook, which the `npx` route does not.

```
/plugin marketplace add anolilab/skills

/plugin install deslop@anolilab
/plugin install babysit-pr@anolilab
/plugin install teardown@anolilab
/plugin install thermos@anolilab
/plugin install ui@anolilab
/plugin install agent-health@anolilab
```

### Running deslop automatically

Installed as a plugin, `deslop` runs on its own. A `Stop` hook checks the branch when a
turn ends, and if code changed it sends Claude back to do a deslop pass before
finishing.

It triggers once per set of changes, not once per turn. The scope is the branch's own
files, measured against the open PR's base branch, and after a first pass only the files
changed since then. It does nothing when the branch is clean, when the directory is not a
git repo, when that exact state already went through a pass, or when the only files in
scope are docs, lockfiles, snapshots, images, or generated output.

To turn it off without uninstalling:

```bash
export DESLOP_AUTO=0
```

To stop one-file follow-up edits from each costing a pass, set a minimum number of code
files changed since the last pass. Smaller follow-ups wait and are reviewed together once
the count is reached. The first pass on a branch always runs. The default is 1.

```bash
export DESLOP_MIN_FILES=3
```

Installed through `npx skills add`, `deslop` has no hook, so it fires only when the agent
judges it relevant or when you ask for it by name.

## Layout

One self-contained plugin directory per capability, each owning its skills, hooks,
and evals.

```
.claude-plugin/
└── marketplace.json        # lists every plugin by directory
<plugin>/
├── .claude-plugin/plugin.json
├── evals/                  # graded cases, each with a scaffold repo
├── hooks/                  # optional: hooks.json and its scripts
└── skills/<skill>/
    ├── SKILL.md            # name and description frontmatter, then the instructions
    └── references/         # loaded on demand rather than up front
```

The `npx` installer copies only `skills/<skill>/`, so hooks and evals sit at the plugin
level, where they belong to the plugin rather than to the skill.

## Contributing

[AGENTS.md](AGENTS.md) has the rules for adding a skill: frontmatter limits, how to
write a description that actually gets matched, when to split content into
`references/`, and the bar for hooks and evals. Validate before opening a PR:

```bash
python3 scripts/validate-package.py
claude plugin validate . --strict
npx skills add . --list
```

CI runs all three on every pull request, plus a shell syntax check, the hook tests, and
a step that executes every eval scaffold. Pull request titles follow
[Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).

## License

[MIT](./LICENSE) © 2026 Anolilab

<!-- badges -->

[validate-badge]: https://img.shields.io/github/actions/workflow/status/anolilab/skills/validate.yml?branch=main&style=for-the-badge&label=Validate
[validate]: https://github.com/anolilab/skills/actions/workflows/validate.yml
[scorecard-badge]: https://api.scorecard.dev/projects/github.com/anolilab/skills/badge?style=for-the-badge
[scorecard]: https://scorecard.dev/viewer/?uri=github.com/anolilab/skills
[license-badge]: https://img.shields.io/badge/license-MIT-blue.svg?style=for-the-badge
[license]: ./LICENSE
[prs-welcome-badge]: https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=for-the-badge
[prs-welcome]: ./AGENTS.md
