#!/usr/bin/env python3
"""Check that every plugin and skill in this repo is well formed.

Reports problems in plain language and exits 1. Nothing here reaches the
network, so it runs the same locally and in CI.
"""

from __future__ import annotations

import json
import re
import stat
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# From the published skill frontmatter rules.
NAME_PATTERN = re.compile(r"^[a-z0-9-]+$")
NAME_MAX = 64
DESCRIPTION_MAX = 1024
RESERVED_NAME_WORDS = ("anthropic", "claude")

# Authoring guidance: split a skill body before it gets unreadable, and give a
# long reference file a table of contents so a partial read still shows scope.
SKILL_BODY_MAX_LINES = 500
REFERENCE_TOC_THRESHOLD_LINES = 100

# The repo's own prose rule. Code fences are exempt because a dash can be
# meaningful inside a command or a literal.
BANNED_PROSE_CHARS = {"—": "em dash", "–": "en dash"}

EVAL_MIN_CASES = 3

problems: list[str] = []


def problem(message: str) -> None:
    problems.append(message)


def read_text(path: Path) -> str | None:
    """Read a UTF-8 file, recording a plain-language problem on failure."""
    try:
        return path.read_text(encoding="utf-8")
    except FileNotFoundError:
        problem(f"{rel(path)}: file is missing")
    except UnicodeDecodeError:
        problem(f"{rel(path)}: file is not valid UTF-8")
    except OSError as error:
        problem(f"{rel(path)}: cannot be read ({error.strerror})")
    return None


def read_json(path: Path) -> dict | None:
    text = read_text(path)
    if text is None:
        return None
    try:
        parsed = json.loads(text)
    except json.JSONDecodeError as error:
        problem(f"{rel(path)}: is not valid JSON (line {error.lineno}: {error.msg})")
        return None
    if not isinstance(parsed, dict):
        problem(f"{rel(path)}: must contain a JSON object")
        return None
    return parsed


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(ROOT))
    except ValueError:
        return str(path)


def parse_frontmatter(text: str, path: Path) -> dict[str, str] | None:
    """Pull the YAML frontmatter block without requiring a YAML library.

    Only the two scalar fields the skill contract defines are read, so a
    hand-rolled parser is enough and CI needs no dependencies.
    """
    if not text.startswith("---\n"):
        problem(f"{rel(path)}: must open with a --- frontmatter block")
        return None
    end = text.find("\n---\n", 3)
    if end == -1:
        problem(f"{rel(path)}: frontmatter block is never closed with ---")
        return None

    block = text[4 : end + 1]
    fields: dict[str, str] = {}
    key = None
    folded: list[str] = []

    for line in block.split("\n"):
        if not line.strip():
            continue
        match = re.match(r"^([A-Za-z_][A-Za-z0-9_-]*):\s*(.*)$", line)
        if match and not line.startswith((" ", "\t")):
            if key is not None:
                fields[key] = " ".join(folded).strip()
            key, value = match.group(1), match.group(2).strip()
            folded = [] if value in (">", "|", ">-", "|-") else [value]
        elif key is not None:
            folded.append(line.strip())

    if key is not None:
        fields[key] = " ".join(folded).strip()

    return fields


def check_frontmatter(path: Path, fields: dict[str, str]) -> None:
    name = fields.get("name", "")
    description = fields.get("description", "")

    if not name:
        problem(f"{rel(path)}: add a name to the frontmatter")
    else:
        if len(name) > NAME_MAX:
            problem(f"{rel(path)}: name is {len(name)} characters, over the {NAME_MAX} limit")
        if not NAME_PATTERN.match(name):
            problem(f"{rel(path)}: name '{name}' must use only lowercase letters, numbers, and hyphens")
        for word in RESERVED_NAME_WORDS:
            if word in name.lower():
                problem(f"{rel(path)}: name '{name}' contains the reserved word '{word}'")
        if name != path.parent.name:
            problem(f"{rel(path)}: name '{name}' does not match its directory '{path.parent.name}'")

    if not description:
        problem(f"{rel(path)}: add a description to the frontmatter")
    elif len(description) > DESCRIPTION_MAX:
        problem(
            f"{rel(path)}: description is {len(description)} characters, over the {DESCRIPTION_MAX} limit"
        )


def check_prose_dashes(path: Path, text: str) -> None:
    """Flag banned dashes outside fenced code blocks."""
    in_fence = False
    for number, line in enumerate(text.split("\n"), start=1):
        if line.lstrip().startswith("```"):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        for char, label in BANNED_PROSE_CHARS.items():
            if char in line:
                problem(f"{rel(path)}:{number}: uses an {label}; rewrite it as punctuation")


def check_executable(path: Path) -> None:
    if not path.exists():
        problem(f"{rel(path)}: file is missing")
        return
    if not path.stat().st_mode & stat.S_IXUSR:
        problem(f"{rel(path)}: is not executable; run chmod +x")


def check_skill(skill_dir: Path) -> None:
    skill_md = skill_dir / "SKILL.md"
    text = read_text(skill_md)
    if text is None:
        return

    fields = parse_frontmatter(text, skill_md)
    if fields is not None:
        check_frontmatter(skill_md, fields)

    body = text.split("\n---\n", 1)[-1]
    body_lines = len(body.split("\n"))
    if body_lines > SKILL_BODY_MAX_LINES:
        problem(
            f"{rel(skill_md)}: body is {body_lines} lines, over the {SKILL_BODY_MAX_LINES} "
            "line guidance; move detail into references/"
        )

    check_prose_dashes(skill_md, text)

    # Every referenced file must exist, and every reference file must be linked
    # from SKILL.md so it is never reached through another reference.
    linked: set[Path] = set()
    for target in re.findall(r"\]\((?!https?://)([^)#]+)\)", text):
        resolved = (skill_dir / target).resolve()
        if not resolved.exists():
            problem(f"{rel(skill_md)}: links to {target}, which does not exist")
            continue
        linked.add(resolved)

    references = skill_dir / "references"
    if references.is_dir():
        for reference in sorted(references.rglob("*.md")):
            if reference.resolve() not in linked:
                problem(
                    f"{rel(reference)}: is not linked from SKILL.md; references must be "
                    "one level deep so they are read whole"
                )
            reference_text = read_text(reference)
            if reference_text is None:
                continue
            check_prose_dashes(reference, reference_text)
            line_count = len(reference_text.split("\n"))
            if line_count > REFERENCE_TOC_THRESHOLD_LINES and "## Contents" not in reference_text:
                problem(
                    f"{rel(reference)}: is {line_count} lines and has no '## Contents' "
                    "section; a partial read would hide its scope"
                )


def check_evals(plugin_dir: Path, skill_names: list[str]) -> None:
    evals = plugin_dir / "evals"
    if not evals.is_dir():
        problem(f"{rel(plugin_dir)}: has no evals/ directory")
        return

    cases = sorted(path for path in evals.iterdir() if path.is_dir())
    if len(cases) < EVAL_MIN_CASES:
        problem(
            f"{rel(evals)}: has {len(cases)} case(s); every plugin needs at least "
            f"{EVAL_MIN_CASES}, including one the skill should leave alone"
        )

    for case in cases:
        if not (case / "prompt.md").is_file():
            problem(f"{rel(case)}: is missing prompt.md")

        graders = sorted((case / "graders").glob("*.md")) if (case / "graders").is_dir() else []
        if not graders:
            problem(f"{rel(case)}: is missing graders/*.md")

        for grader in graders:
            grader_text = read_text(grader)
            if grader_text is None:
                continue
            check_prose_dashes(grader, grader_text)
            missing = [h for h in ("## Passes", "## Fails") if h not in grader_text]
            if missing:
                problem(f"{rel(grader)}: is missing {' and '.join(missing)}")

        scaffold = case / "scaffold.sh"
        if scaffold.is_file():
            check_executable(scaffold)
        else:
            problem(f"{rel(case)}: is missing scaffold.sh")

    # Skills are unused context if nothing exercises them.
    if skill_names and not cases:
        problem(f"{rel(evals)}: no cases exercise {', '.join(skill_names)}")


def check_plugin(entry: dict, marketplace_path: Path) -> None:
    name = entry.get("name")
    source = entry.get("source")

    if not name:
        problem(f"{rel(marketplace_path)}: a plugin entry has no name")
        return
    if not source:
        problem(f"{rel(marketplace_path)}: plugin '{name}' has no source")
        return

    plugin_dir = (ROOT / source).resolve()
    if not plugin_dir.is_dir():
        problem(f"{rel(marketplace_path)}: plugin '{name}' points at {source}, which is not a directory")
        return

    manifest_path = plugin_dir / ".claude-plugin" / "plugin.json"
    manifest = read_json(manifest_path)
    if manifest is None:
        return

    if manifest.get("name") != name:
        problem(
            f"{rel(manifest_path)}: name '{manifest.get('name')}' does not match the "
            f"marketplace entry '{name}'"
        )

    # A misplaced field is silently ignored at load time, which is worse than an error.
    if "category" in manifest:
        problem(f"{rel(manifest_path)}: category belongs in the marketplace entry, not plugin.json")

    hooks_field = manifest.get("hooks")
    if isinstance(hooks_field, str):
        hooks_path = (plugin_dir / hooks_field).resolve()
        if read_json(hooks_path) is not None:
            for script in sorted(hooks_path.parent.glob("*.sh")):
                check_executable(script)

    skills_dir = plugin_dir / "skills"
    if not skills_dir.is_dir():
        problem(f"{rel(plugin_dir)}: has no skills/ directory")
        return

    skill_names = []
    for skill_dir in sorted(path for path in skills_dir.iterdir() if path.is_dir()):
        skill_names.append(skill_dir.name)
        check_skill(skill_dir)

    if not skill_names:
        problem(f"{rel(skills_dir)}: contains no skills")

    check_evals(plugin_dir, skill_names)


def main() -> int:
    marketplace_path = ROOT / ".claude-plugin" / "marketplace.json"
    marketplace = read_json(marketplace_path)

    if marketplace is not None:
        plugins = marketplace.get("plugins")
        if not isinstance(plugins, list) or not plugins:
            problem(f"{rel(marketplace_path)}: needs a non-empty plugins array")
        else:
            for entry in plugins:
                if isinstance(entry, dict):
                    check_plugin(entry, marketplace_path)
                else:
                    problem(f"{rel(marketplace_path)}: every plugin entry must be an object")

    for doc in ("README.md", "AGENTS.md"):
        text = read_text(ROOT / doc)
        if text is not None:
            check_prose_dashes(ROOT / doc, text)

    if problems:
        print(f"Found {len(problems)} problem(s):\n", file=sys.stderr)
        for message in problems:
            print(f"  {message}", file=sys.stderr)
        return 1

    print("Package is valid.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
