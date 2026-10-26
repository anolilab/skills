#!/usr/bin/env python3
"""Check a Claude Code setup for faults that can be proven from files alone.

Reads the global config directory (default ~/.claude) and one project, and prints
one line per finding: severity, location, and what is wrong. Never prints a
secret value, only its file, line, and kind.

    check_setup.py [--project DIR] [--claude-dir DIR] [--no-global]

Checks: settings files that are not valid JSON, hook commands whose script is
missing or not executable, a settings.local.json tracked by git, secrets in
instruction, settings, and memory files, paths named in memory or instructions
that no longer exist, MCP servers whose command is not installed, and skills
that shadow each other or describe the same triggers.
"""

from __future__ import annotations

import argparse
import itertools
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))
from audit_sessions import KEY_VALUE, SECRET, redact  # noqa: E402

SECRET_KINDS = [
    (r"^gh[pousr]_|^github_pat_", "GitHub token"),
    (r"^sk-", "API key (sk-)"),
    (r"^npm_", "npm token"),
    (r"^xox", "Slack token"),
    (r"^AKIA", "AWS access key id"),
    (r"^eyJ", "JWT"),
]
PATH_IN_TEXT = re.compile(r"`((?:~|/Users|/home|/opt|/usr/local)/[^`\s*?<>]+)`")
STOP = set(
    "about after also and any are asks before both but can code does each etc for from "
    "has have into its make not only other over said says such than that the their them "
    "then there these they this through use used user uses using want wants what when "
    "where which while will with without work your".split()
)

INTERPRETERS = {"bash", "sh", "zsh", "python", "python3", "node", "bun", "deno", "ruby", "npx", "tsx", "uv", "env"}

findings: list[tuple[str, str, str]] = []
PROJECT = Path(".")


def add(severity: str, where: str, what: str) -> None:
    prefix = str(PROJECT) + os.sep
    where = where[len(prefix):] if where.startswith(prefix) else where
    findings.append((severity, redact(where), what))


def kind_of(value: str) -> str:
    for pattern, kind in SECRET_KINDS:
        if re.search(pattern, value):
            return kind
    return "credential"


def scan_secrets(path: Path) -> None:
    try:
        lines = path.read_text(errors="ignore").splitlines()
    except OSError:
        return
    for n, line in enumerate(lines, 1):
        hit = SECRET.search(line)
        if hit:
            add("critical", f"{path}:{n}", f"{kind_of(hit.group(0))} in plain text")
            continue
        kv = KEY_VALUE.search(line)
        if kv and len(line[kv.end(1):kv.end()].strip("\"' ")) >= 12:
            add("critical", f"{path}:{n}", "credential assigned in plain text")


def scan_paths(path: Path, label: str) -> None:
    try:
        lines = path.read_text(errors="ignore").splitlines()
    except OSError:
        return
    for n, line in enumerate(lines, 1):
        for raw in PATH_IN_TEXT.findall(line):
            target = Path(os.path.expanduser(raw.rstrip(".,:;)")))
            if not target.exists():
                add("structural", f"{path}:{n}", f"{label} names `{redact(raw)}`, which does not exist")


def load_json(path: Path):
    try:
        return json.loads(path.read_text())
    except OSError:
        return None
    except ValueError as err:
        add("critical", str(path), f"not valid JSON ({err.msg} at line {err.lineno}); the whole file is ignored")
        return None


def check_hooks(settings: dict, where: Path, base: Path) -> None:
    hooks = settings.get("hooks") if isinstance(settings, dict) else None
    if not isinstance(hooks, dict):
        return
    for event, groups in hooks.items():
        for group in groups if isinstance(groups, list) else []:
            for hook in (group.get("hooks") or []) if isinstance(group, dict) else []:
                cmd = hook.get("command", "") if isinstance(hook, dict) else ""
                words = cmd.split()
                for i, written in enumerate(words):
                    written = written.replace('"', "").replace("'", "")
                    if os.path.basename(written) in INTERPRETERS:
                        continue
                    token = re.sub(r"\$\{?CLAUDE_PROJECT_DIR\}?", str(PROJECT), written)
                    token = os.path.expandvars(os.path.expanduser(token))
                    if "$" in token or not re.search(r"\.(sh|py|js|mjs|cjs|ts|rb)$|^(~|\.{1,2})?/", token):
                        continue
                    target = Path(token)
                    target = target if target.is_absolute() else base / target
                    shown = redact(written)
                    if not target.exists():
                        add("critical", f"{where} hooks.{event}", f"runs `{shown}`, which does not exist")
                    elif i == 0 and not os.access(target, os.X_OK):
                        add("critical", f"{where} hooks.{event}", f"runs `{shown}` directly, but it is not executable")
                    break


def check_mcp(config: dict, where: Path) -> None:
    servers = config.get("mcpServers") if isinstance(config, dict) else None
    for name, spec in (servers or {}).items():
        cmd = spec.get("command") if isinstance(spec, dict) else None
        if cmd and not shutil.which(os.path.expanduser(cmd)):
            add("structural", f"{where} mcpServers.{name}", f"command `{redact(cmd)}` is not installed or not on PATH")


def skill_description(skill_md: Path) -> str:
    try:
        text = skill_md.read_text(errors="ignore")
    except OSError:
        return ""
    head = text.split("\n---", 2)[0] if text.startswith("---") else ""
    match = re.search(r"^description:\s*(>-?|\|-?)?\s*(.*?)(?=^\w[\w-]*:|\Z)", head, re.S | re.M)
    return " ".join(match.group(2).split()) if match else ""


def check_skills(dirs: list[Path]) -> None:
    seen: dict[str, Path] = {}
    words: dict[str, set[str]] = {}
    for d in dirs:
        for skill_md in sorted(d.glob("*/SKILL.md")):
            name = skill_md.parent.name
            if name in seen and seen[name].resolve() != skill_md.parent.resolve():
                add("structural", str(skill_md.parent), f"skill `{name}` also exists at {redact(str(seen[name]))}; one shadows the other")
                continue
            seen[name] = skill_md.parent
            desc = skill_description(skill_md).lower()
            words[name] = {w for w in re.findall(r"[a-z][a-z-]{3,}", desc) if w not in STOP}
    pairs = []
    for a, b in itertools.combinations(sorted(words), 2):
        wa, wb = words[a], words[b]
        if len(wa) < 6 or len(wb) < 6:
            continue
        score = len(wa & wb) / len(wa | wb)
        if score >= 0.25:
            pairs.append((score, a, b))
    for score, a, b in sorted(pairs, reverse=True)[:8]:
        add("structural", f"skills {a} + {b}", f"descriptions overlap {score:.0%}; check which one should own the shared triggers")


def tracked(project: Path, rel: str) -> bool:
    try:
        out = subprocess.run(["git", "-C", str(project), "ls-files", "--error-unmatch", rel],
                             capture_output=True, timeout=10)
    except (OSError, subprocess.TimeoutExpired):
        return False
    return out.returncode == 0


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--project", default=".")
    ap.add_argument("--claude-dir", default=os.path.expanduser("~/.claude"))
    ap.add_argument("--no-global", action="store_true", help="skip the global config directory")
    args = ap.parse_args()
    global PROJECT
    project = PROJECT = Path(args.project).resolve()
    home = Path(args.claude_dir)

    sources: list[tuple[Path, Path, str]] = []  # settings file, base dir, label
    if not args.no_global:
        sources.append((home / "settings.json", home, "global"))
    for name in ("settings.json", "settings.local.json"):
        sources.append((project / ".claude" / name, project, "project"))
    for path, base, _ in sources:
        if not path.is_file():
            continue
        scan_secrets(path)
        if path.name == "settings.local.json" and tracked(project, ".claude/settings.local.json"):
            add("critical", str(path), "tracked by git; it is meant to be personal and often holds tokens")
        settings = load_json(path)
        if settings is not None:
            check_hooks(settings, path, base)

    for mcp in [project / ".mcp.json"] + ([] if args.no_global else [home.parent / ".claude.json"]):
        config = load_json(mcp)
        if config is not None:
            check_mcp(config, mcp)

    instructions = [project / n for n in ("CLAUDE.md", "CLAUDE.local.md", "AGENTS.md", ".claude/CLAUDE.md")]
    if not args.no_global:
        instructions.append(home / "CLAUDE.md")
    for path in instructions:
        if path.is_file():
            scan_secrets(path)
            scan_paths(path, "instructions")

    memory_dirs = [project / ".claude" / "memory"]
    if not args.no_global:
        memory_dirs += sorted(home.glob("projects/*/memory"))
    for d in memory_dirs:
        for path in sorted(d.glob("*.md")):
            scan_secrets(path)
            scan_paths(path, "memory")

    skill_dirs = [project / ".claude" / "skills"]
    if not args.no_global:
        skill_dirs += [home / "skills", home.parent / ".agents" / "skills"]
    check_skills([d for d in skill_dirs if d.is_dir()])

    order = {"critical": 0, "structural": 1, "minor": 2}
    print(f"=== SETUP CHECK === project: {redact(str(project))}  global: {'no' if args.no_global else redact(str(home))}")
    if not findings:
        print("no findings")
    for severity, where, what in sorted(set(findings), key=lambda f: (order[f[0]], f[1])):
        print(f"[{severity}] {where}: {what}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
