# skills

Skills for Real Engineers. Straight from my .agents directory.

## Skills

| Skill | What it does |
| --- | --- |
| [`deslop`](skills/deslop/) | Strips AI-generated slop out of the changes on a branch: narrating comments, unasked-for defensive code, `any`/`unknown` casts, single-use wrappers, mock-heavy tests. Behaviour stays identical. |

## Install

### Quick start

```bash
# every skill, into every agent it detects, no prompts
npx skills add anolilab/skills --all

# or pick interactively
npx skills add anolilab/skills
```

Add `-g` to install globally (available in every project) instead of into the current
project only.

### A specific agent

Pass `-a` with the agent's slug. Repeat it to target several at once.

```bash
npx skills add anolilab/skills -a claude-code
npx skills add anolilab/skills -a codex
npx skills add anolilab/skills -a opencode

# several at once
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

### Claude Code plugin

Each skill is packaged as its own plugin, so you install only what you want. The
plugin route also brings the hook that runs `deslop` automatically (see below), which
the `npx` route does not.

```
/plugin marketplace add anolilab/skills
/plugin install deslop@anolilab
```

### Without installing

```bash
npx skills use anolilab/skills --skill deslop --agent claude-code
```

## Running deslop automatically

Installed as a Claude Code plugin, `deslop` runs on its own. A `Stop` hook checks the
branch when a turn ends, and if code changed it sends Claude back to do a deslop pass
before finishing.

It triggers once per set of changes, not once per turn, and it does nothing when the
branch is clean, when the directory is not a git repo, or when that exact diff already
went through a pass.

To turn it off without uninstalling:

```bash
export DESLOP_AUTO=0
```

Installing through `npx skills add` gives you the skill without the hook, so it fires
only when Claude judges it relevant or when you ask for it by name.

## Layout

One self-contained plugin directory per capability, each owning its skills, hooks,
and evals.

```
.claude-plugin/
└── marketplace.json     # lists every plugin by directory
deslop/
├── .claude-plugin/plugin.json
├── evals/               # graded cases for the skill
├── hooks/               # hooks.json + the Stop hook script
└── skills/deslop/
    ├── SKILL.md         # name + description frontmatter, then the instructions
    └── references/      # loaded on demand rather than up front
```

The `npx` installer copies only `skills/`, so hooks and evals sit at the plugin level
where they belong to the plugin rather than to the skill.

## Contributing

[AGENTS.md](AGENTS.md) has the rules for adding a skill: frontmatter limits, how to
write a description that actually gets matched, when to split content into
`references/`, and the bar for hooks. Validate before opening a PR:

```bash
claude plugin validate . --strict
npx skills add . --list
```

## License

MIT
