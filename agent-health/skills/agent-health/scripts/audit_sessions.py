#!/usr/bin/env python3
"""Summarise Claude Code session transcripts into health evidence.

Reads the top-level transcripts under a projects directory (default
~/.claude/projects), counts structured events only (tool calls, tool errors,
user messages outside subagent sidechains), and prints bounded, redacted
sections. Transcripts modified in the last few minutes are skipped so the
running session does not audit itself.

    audit_sessions.py [--projects-dir DIR] [--days 21] [--project SUBSTR]
                      [--since YYYY-MM-DD] [--skip-live-minutes 10]

--since splits every count into before and after that date, to measure
whether a change (a new rule, skill, or hook) moved behaviour.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import time
from collections import Counter, defaultdict
from pathlib import Path

TOP = 12
EXCERPT = 110

SECRET = re.compile(
    r"(gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|sk-[A-Za-z0-9_-]{20,}"
    r"|npm_[A-Za-z0-9]{20,}|xox[abprs]-[A-Za-z0-9-]{10,}|AKIA[0-9A-Z]{16}"
    r"|eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{10,}|[A-Fa-f0-9]{40,}|[A-Za-z0-9+/]{48,}={0,2})"
)
HOME = str(Path.home())
HARNESS_PREFIXES = (
    "<", "Update on pull request", "Stop hook feedback", "T3 Code ", "[Request interrupted",
    "Caveat:", "Note:", "This session is being continued", "[Image", "Delegated task",
)


def redact(text: str) -> str:
    text = SECRET.sub("<redacted>", text)
    text = text.replace(HOME, "~")
    text = re.sub(r"/(?:private/)?(?:tmp|var/folders)/\S+", "<tmp>", text)
    return " ".join(text.split())[:EXCERPT]


def normalise_error(text: str) -> str:
    first = next(
        (line for line in text.splitlines()
         if re.search(r"[A-Za-z]{3}", line) and not line.startswith(("Exit code", "Starting Git hook"))),
        text,
    )
    rules = [
        (r"zsh: =+ not found|\(eval\):\d+: =+ not found", "zsh: `=` word run as a command (EQUALS option)"),
        (r"no matches found", "zsh: unmatched glob (NOMATCH option)"),
        (r"command not found: EOF", "heredoc terminator run as a command"),
        (r"command not found: (\S+)", r"command not found: \1"),
        (r"unmatched [\"']", "shell: unmatched quote"),
        (r"Blocked: sleep", "harness blocked a sleep-then-read wait"),
        (r"Concurrent subagent limit", "subagent concurrency limit reached"),
        (r"Tool call interrupted", "tool call cut off by session end"),
        (r"No such tool available: (\S+)", r"wrong tool name: \1"),
        (r"Found \d+ matches of the string to replace", "Edit: old_string not unique"),
        (r"File has not been read yet|must Read the file", "Edit before Read"),
        (r"sed: .*(invalid command|illegal option|extra characters)", "BSD sed syntax"),
    ]
    for pattern, label in rules:
        match = re.search(pattern, text)
        if match:
            return match.expand(label) if "\\1" in label else label
    return redact(re.sub(r"\d+", "N", first))


def text_of(content) -> str:
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        parts = []
        for block in content:
            if isinstance(block, dict) and block.get("type") == "text":
                parts.append(block.get("text", ""))
        return " ".join(parts)
    return ""


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--projects-dir", default=os.path.expanduser("~/.claude/projects"))
    ap.add_argument("--days", type=int, default=21)
    ap.add_argument("--project", default="")
    ap.add_argument("--since", default="")
    ap.add_argument("--skip-live-minutes", type=int, default=10)
    args = ap.parse_args()

    root = Path(args.projects_dir)
    if not root.is_dir():
        print(f"no projects directory at {redact(str(root))}")
        return 1
    now = time.time()
    files = [
        f for f in root.glob("*/*.jsonl")
        if args.project in f.parent.name
        and now - args.days * 86400 < f.stat().st_mtime < now - args.skip_live_minutes * 60
    ]

    def phase(ts: str) -> str:
        if not args.since:
            return "all"
        return "before" if ts[:10] < args.since else "after"

    c = defaultdict(Counter)  # section -> counter
    by_phase = defaultdict(Counter)
    days = Counter()
    compacted = 0
    wake_noop = Counter()
    wake_pr = Counter()
    for f in files:
        session_compacted = False
        tool_names: dict[str, str] = {}
        pending_wake = None
        last_ts = ""
        try:
            lines = f.open(errors="ignore")
        except OSError:
            continue
        for line in lines:
            try:
                d = json.loads(line)
            except ValueError:
                continue
            ts = d.get("timestamp") or last_ts
            last_ts = ts
            if d.get("type") == "system" and d.get("subtype") == "compact_boundary":
                session_compacted = True
            if d.get("isSidechain"):
                continue
            msg = d.get("message") or {}
            content = msg.get("content")
            p = phase(ts)
            if d.get("type") == "assistant" and isinstance(content, list):
                for b in content:
                    if not isinstance(b, dict) or b.get("type") != "tool_use":
                        continue
                    name, inp = b.get("name", "?"), b.get("input") or {}
                    tool_names[b.get("id", "")] = name
                    c["tools"][name] += 1
                    by_phase["tool calls"][p] += 1
                    if pending_wake is not None:
                        pending_wake = None
                    if name == "Skill":
                        c["skills"][inp.get("skill", "?")] += 1
                    elif name == "Agent":
                        key = f"type={inp.get('subagent_type') or 'default'} model={inp.get('model') or 'unset'}"
                        if inp.get("isolation") == "worktree":
                            key += " worktree"
                        c["agents"][key] += 1
                        if not inp.get("model") and inp.get("isolation") == "worktree":
                            by_phase["writing agents with no model"][p] += 1
                    elif name == "Bash":
                        cmd = inp.get("command", "")
                        bare = re.sub(r"^\s*(?:cd\s+\S+\s*(?:&&|;)\s*)+", "", cmd)
                        c["bash heads"][redact(" ".join(bare.split()[:2]))[:40]] += 1
                        if re.match(r"\s*export PATH=", cmd):
                            by_phase["bash calls that patch PATH"][p] += 1
                        if re.search(r"\bsleep \d+", cmd):
                            by_phase["bash calls with sleep"][p] += 1
            elif d.get("type") == "user":
                if isinstance(content, list):
                    for b in content:
                        if isinstance(b, dict) and b.get("type") == "tool_result" and b.get("is_error"):
                            raw = b.get("content")
                            raw = raw if isinstance(raw, str) else text_of(raw) or json.dumps(raw)[:400]
                            tool = tool_names.get(b.get("tool_use_id", ""), "?")
                            c["errors"][f"{tool}: {normalise_error(raw)}"] += 1
                            by_phase["tool errors"][p] += 1
                text = text_of(content).strip()
                if not text or any(isinstance(b, dict) and b.get("type") == "tool_result" for b in (content if isinstance(content, list) else [])):
                    continue
                days[ts[:10]] += 1
                hook = re.match(r"Stop hook feedback:\s*\[([^\]]+)\]", text)
                if hook:
                    c["stop hooks"][redact(hook.group(1))] += 1
                    by_phase["stop hook blocks"][p] += 1
                    continue
                wake = re.match(r"Update on pull request #(\d+) \((\S+?)\)", text)
                if wake:
                    if pending_wake is not None:
                        wake_noop["noop"] += 1
                    pending_wake = wake.group(2)
                    wake_pr[wake.group(2)] += 1
                    by_phase["PR watcher wake-ups"][p] += 1
                    continue
                slash = re.search(r"<command-name>/?([^<]+)</command-name>", text)
                if slash:
                    c["slash commands"][slash.group(1)] += 1
                    continue
                if text.startswith(HARNESS_PREFIXES):
                    continue
                by_phase["user prompts"][p] += 1
                if len(text) <= 120:
                    c["repeated prompts"][redact(text.lower())] += 1
        if pending_wake is not None:
            wake_noop["noop"] += 1
        compacted += session_compacted

    print(f"=== SCOPE ===\ntranscripts: {len(files)}  days: {args.days}  project filter: {args.project or '(all)'}"
          f"  sessions compacted at least once: {compacted}")
    if args.since:
        print(f"split at: {args.since}")
    print("\n=== COUNTS" + (" (before / after)" if args.since else "") + " ===")
    for key in sorted(by_phase):
        v = by_phase[key]
        print(f"{key}: {v['before']} / {v['after']}" if args.since else f"{key}: {v['all']}")
    if wake_pr:
        total = sum(wake_pr.values())
        print(f"PR wake-ups answered with no tool call: {wake_noop['noop']} of {total}")
        print(f"PRs watched: {len(wake_pr)}  mean wake-ups per PR: {total / len(wake_pr):.1f}")
    for section in ("errors", "stop hooks", "agents", "skills", "slash commands", "tools", "bash heads"):
        if c[section]:
            print(f"\n=== {section.upper()} ===")
            for k, v in c[section].most_common(TOP):
                print(f"{v:6d}  {k}")
    if wake_pr:
        print("\n=== MOST-WOKEN PRS ===")
        for k, v in wake_pr.most_common(5):
            print(f"{v:6d}  {k}")
    repeats = [(k, v) for k, v in c["repeated prompts"].most_common(TOP) if v >= 3]
    if repeats:
        print("\n=== REPEATED PROMPTS (skill candidates) ===")
        for k, v in repeats:
            print(f"{v:6d}  {k}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
