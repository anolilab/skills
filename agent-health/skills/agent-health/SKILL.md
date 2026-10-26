---
name: agent-health
description: >
  Audits a coding agent's own setup and how it has actually been working: instruction
  files, settings, hooks, MCP servers, memory, installed skills, and the session
  transcripts (tool errors, blocked commands, hook churn, subagent models and errors,
  PR wake-ups, user corrections, repeated prompts). Reports findings with evidence and a pasteable fix. Use when the
  user asks to check the agent setup, audit Claude Code config, says the agent ignores
  instructions or keeps hitting the same errors, or asks how the last weeks of agent
  work went. Report-only. Not for application health checks, bugs, or PR review.
---

# Agent health

Find where the agent setup and the agent's actual behaviour disagree, show the
evidence, and give a fix the user can paste. Change nothing: this is a report.

## Rules

- **Report only.** Read files and transcripts and run the bundled auditor. Do not run
  the project's builds, tests, installers, or formatters, and do not edit config, even
  when a fix is obvious. Fixing is the next request.
- **Never print a secret.** Name the file, the line, and the kind of secret (`npm token`,
  `GitHub PAT`), never the value. Write home paths as `~`.
- **Measured, not guessed.** A finding cites a count from the auditor or a `file:line`.
  A large file, many skills, or a long CLAUDE.md is not a finding until it is tied to a
  failure, a risk, or a contradiction.
- **Global once.** Findings in `~/.claude` (global CLAUDE.md, user settings, global
  skills, global hooks) are labelled `global` and reported once, not per project.

## 1. Read the setup

Run the bundled setup check first. It proves what can be proven from files, and prints
one line per finding with its severity:

```bash
python3 -I <this skill's dir>/scripts/check_setup.py --project <repo>
```

It reports settings that are not valid JSON, hook commands whose script is missing or
not executable, a tracked `settings.local.json`, secrets in settings, instructions, and
memory (file, line, and kind, never the value), paths named in memory or instructions
that no longer exist, MCP servers whose command is not installed, skills with the same
name in two places, and skills whose descriptions use near-identical wording. Pass
`--no-global` to leave `~/.claude` out.

Its skill-overlap check is lexical. Two skills that do the same job in different words
score low, so still read the descriptions of skills in one domain (UI, review, PR work)
and judge which ones compete for the same requests.

Then read every surface that shapes the agent, global first, then project:

- instructions: `~/.claude/CLAUDE.md`, the project's `CLAUDE.md`, `.claude/CLAUDE.md`,
  `CLAUDE.local.md`, and `AGENTS.md`, and any file they import. By default Claude Code
  reads `AGENTS.md` only when none of those three project `CLAUDE.md` files exists in the
  working directory or above it; when one does, `AGENTS.md` is ignored unless a
  `CLAUDE.md` imports it. The **Project instructions** setting can change this, and
  older Claude Code versions do not read `AGENTS.md` at all. Check both before
  reporting instructions as unreachable.
- settings: `~/.claude/settings.json`, `.claude/settings.json`, and
  `.claude/settings.local.json`, which overrides both. A tracked `settings.local.json`
  is a leak risk: check `git ls-files`.
- hooks: each configured command exists and is executable; note its opt-out.
- MCP servers and plugins: which are enabled, and from what source.
- memory: `~/.claude/projects/*/memory/`. Look for facts the setup has since made false
  (a memory that tells the agent to patch PATH after PATH was fixed), contradictions
  with CLAUDE.md, and secrets.
- skills: names and descriptions. Two skills whose descriptions claim the same trigger
  phrases compete, and the wrong one fires. A third-party skill tracking a moving
  branch can change under the user.
- env: `CLAUDE_CODE_SUBAGENT_MODEL` and concurrency limits, against what the
  instructions say each model is for.

## 2. Read the behaviour

Run the auditor bundled with this skill:

```bash
python3 -I <this skill's dir>/scripts/audit_sessions.py --days 21
python3 -I <this skill's dir>/scripts/audit_sessions.py --days 21 --since <YYYY-MM-DD>
python3 -I <this skill's dir>/scripts/audit_sessions.py --project <name-substring>
```

It counts structured events only, skips transcripts still being written, redacts
tokens and paths, reads subagent transcripts (`<session>/subagents/`) separately from
the main sessions, and prints these sections:

| Section | What to look for |
| --- | --- |
| ERRORS | one class repeated dozens of times is a setup gap, not bad luck: a shell option, a missing PATH entry, a tool the harness blocks |
| STOP HOOKS | a hook that blocks far more often than its skill runs is asking for passes nobody needs |
| AGENTS | agents that edit files (`worktree`) with `model=unset` run on the session default; check that default |
| COUNTS, wake-ups | many PR wake-ups answered with no tool call, or a few PRs with very high counts, mean review loops without a stop |
| SUBAGENTS, SUBAGENT ERRORS | tool calls and error classes per subagent type and model; an error class that appears only under one model points at that model's role, not the setup |
| CORRECTIONS | prompts that start by pushing back ("no", "wrong", "I said", "revert"); the same correction more than once is an instruction that is not working. The match is on the first word only, so read the listed text: "no worries" is not a correction |
| REPEATED PROMPTS | the same short instruction typed many times is a skill or a default waiting to be written |
| BASH HEADS | the same prefix on thousands of calls (`export PATH=...`) is a workaround for a broken environment |

When the user changed something on a known date, run with `--since` and compare before
and after. A rule that did not move its number has not worked yet, however well it
reads.

Tie each pattern back to a cause in step 1: the instruction, memory, hook, or setting
that produces it, or the missing one that would prevent it.

## 3. Report

```
Agent health: <project or global> (<N> transcripts, <D> days)

Passing (at most five rows)

[!] Critical: <symptom> (<file:line>)
    Why: <one line>
    Fix: <exact command or edit>
[~] Structural: ...
[-] Minor: ...
```

- **Critical:** a secret in a tracked file or in memory, a permission that lets the agent
  publish or delete without a gate, a hook that can block forever.
- **Structural:** a repeated error class with a known cause, instructions that
  contradict each other or the settings, stale memory, a model default that sends
  writing agents to the wrong model, overlapping skills.
- **Minor:** cleanup with no measured cost.

Every `Fix:` is pasteable: a command, or an edit with its file and the exact text. If
the fix is unknown, give the command that would find it. Drop a finding you refute
while writing it. If nothing qualifies, say `All checks passed. Nothing to fix.`

End with the two or three fixes that would remove the most failures, numbered, so the
user can answer "1 yes, 2 no".
