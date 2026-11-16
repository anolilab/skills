#!/usr/bin/env python3
"""Mechanical style check for German and English articles (Markdown, MDX, plain text).

Reports what can be found without judgement: dash punctuation, hidden characters,
stock phrases, contrast reveals, quote and number typography, heading and bold
patterns, and flat sentence rhythm. It reads only the files it is given, needs no
packages, and makes no network calls.

Exit status: 1 when any error is found, 0 otherwise. Warnings never fail the run;
they are leads for the edit pass, not verdicts.

    python3 style_check.py content/blog/post.mdx content/blog/post.en.mdx
    python3 style_check.py --lang de --format json draft.md
"""

from __future__ import annotations

import argparse
import json
import re
import statistics
import sys
from dataclasses import asdict, dataclass
from pathlib import Path

EM_DASH = "—"
EN_DASH = "–"
HIDDEN = re.compile("[​‌‍⁠﻿­‪-‮⁦-⁩]")


@dataclass
class Finding:
    line: int
    level: str  # "error" or "warn"
    code: str
    message: str
    excerpt: str = ""


# Phrases that are almost never wanted in an article. Matched case-insensitively.
STOCK = {
    "de": [
        r"in der heutigen (?:schnelllebigen |digitalen |modernen )?(?:welt|zeit)",
        r"im (?:digitalen )?zeitalter (?:der|des)",
        r"es ist (?:wichtig|erwähnenswert) zu (?:beachten|betonen|erwähnen)",
        r"es sei darauf hingewiesen",
        r"lass(?:t)? uns (?:eintauchen|einen (?:genaueren )?blick werfen)",
        r"tauchen wir (?:ein|tiefer)",
        r"schauen wir uns (?:das|dies|an)",
        r"zusammenfassend lässt sich sagen",
        r"im folgenden (?:werden|wird|erfährst|erfahren)",
        r"ich hoffe,? (?:das|dies) hilft",
        r"(?:aber|und) (?:jetzt|hier) kommt der (?:clou|haken)",
        r"und genau (?:hier|da) wird es spannend",
        r"game[- ]?changer",
        r"die (?:digitale|dynamische|sich wandelnde) landschaft",
        r"spielt eine (?:entscheidende|zentrale|wichtige) rolle",
        r"steht als zeugnis",
        r"die möglichkeiten sind (?:grenzenlos|endlos)",
    ],
    "en": [
        r"in today'?s (?:fast-paced |digital |modern )?(?:world|age|landscape)",
        r"it(?:'s| is) (?:important|worth) (?:to note|noting)",
        r"let'?s dive (?:in|into)",
        r"\bdelv(?:e|es|ing)\b",
        r"game[- ]?changer",
        r"navigat(?:e|ing) the (?:complex |ever-changing )?landscape",
        r"unlock(?:s|ing)? the (?:full )?(?:power|potential)",
        r"\bin conclusion\b",
        r"i hope this helps",
        r"here'?s the (?:kicker|catch|thing)",
        r"plays? a (?:crucial|pivotal|vital) role",
        r"stands as a testament",
        r"the possibilities are endless",
    ],
}

# Single words that are fine once and a tell in a cluster.
MARKER_WORDS = {
    "de": r"\b(?:nahtlos\w*|ganzheitlich\w*|vielschichtig\w*|beleuchte\w*|eintauch\w*|bahnbrechend\w*|revolution\w+|essenziell\w*|maßgeschneidert\w*|unverzichtbar\w*)\b",
    "en": r"\b(?:seamless\w*|leverag\w+|robust|holistic|pivotal|tapestry|bustling|cutting-edge|revolutioni\w+|unparalleled|meticulous\w*)\b",
}

# "It is not X, it is Y" and its relatives. Errors: the reveal; warnings: the softer forms.
REVEAL = {
    "de": r"\b(?:ist|sind|war) (?:nicht|kein\w*) [^.!?;:]{1,40}, (?:es|das|dies|sie|er) (?:ist|sind|war)\b",
    "en": r"(?:'s|’s|\bis|\bare|\bwas) not (?:just |only |about )?[^.!?;:]{1,40}[,;:] (?:it|this|that|they)(?:'s|’s| is| are| was)\b",
}
CONTRAST = {
    "de": r"\bnicht nur\b[^.!?]{1,80}\bsondern auch\b|\bweniger\b[^.!?]{1,40}\bals vielmehr\b",
    "en": r"\bnot (?:just|only)\b[^.!?]{1,80}\bbut(?: also)?\b",
}

CONNECTORS = {
    "de": r"(?:^|[.!?]\s+)(?:Darüber hinaus|Außerdem|Zudem|Ferner|Des Weiteren|Zusätzlich|Ebenso)\b",
    "en": r"(?:^|[.!?]\s+)(?:Additionally|Furthermore|Moreover|In addition|Also),",
}

# Calques and anglicisms that have a plain German form.
CALQUES = [
    (r"\b(?:macht|machen|machte) (?:\w+ )?(?:keinen |wenig |viel |mehr )?sinn\b", "\"ergibt Sinn\" or \"ist sinnvoll\""),
    (r"\bsinn machen\b", "\"sinnvoll sein\""),
    (r"\bam ende des tages\b", "\"letztlich\" or the concrete result"),
    (r"\bdas gesagt,", "\"Trotzdem\" or \"Allerdings\""),
    (r"\b(?:ge)?trigger(?:t|n|st)\b", "\"auslösen\""),
    (r"\b(?:ge)?fail(?:t|ed|en)\b", "\"schlägt fehl\""),
    (r"\b(?:ge)?return(?:t|en)\b", "\"zurückgeben\""),
    (r"\beinmal mehr\b", "\"wieder\" or \"erneut\""),
    (r"(?<![\w-])in 20\d\d\b", "\"2026\" or \"im Jahr 2026\""),
    (r"\bin (?:der|einer) gleichen zeit\b", "\"gleichzeitig\""),
    (r"\bnicht wirklich\b", "a precise statement (often fine in casual text)"),
]

ABBREVIATIONS = [
    "z. B.", "z.B.", "d. h.", "d.h.", "u. a.", "u.a.", "bzw.", "ca.", "etc.", "evtl.", "ggf.", "inkl.",
    "Nr.", "S.", "Abs.", "Art.", "vgl.", "usw.", "e.g.", "i.e.", "vs.", "approx.", "Dr.", "Mr.", "Ms.",
]

def blank(match: re.Match[str]) -> str:
    """Replace a match with spaces but keep its newlines, so line numbers survive."""
    return re.sub(r"[^\n]", " ", match.group(0))


def blank_expressions(text: str) -> str:
    """Blank MDX expressions such as {[ ... ]} and {props}, including nested braces."""
    out = list(text)
    depth = 0
    for i, ch in enumerate(text):
        if ch == "{":
            depth += 1
        if depth and ch != "\n":
            out[i] = " "
        if ch == "}" and depth:
            depth -= 1
    return "".join(out)


def prose_only(text: str) -> str:
    """Blank out everything that is not running prose: frontmatter, code, markup, links."""
    text = re.sub(r"\A---\n.*?\n---\n", blank, text, flags=re.S)
    text = re.sub(r"^(`{3,}|~{3,}).*?^\1[ \t]*$", blank, text, flags=re.S | re.M)
    text = re.sub(r"`[^`\n]+`", blank, text)
    text = re.sub(r"\{/\*.*?\*/\}|<!--.*?-->", blank, text, flags=re.S)
    text = re.sub(r"^(?:import|export) .*$", blank, text, flags=re.M)
    text = re.sub(r"</?[A-Za-z][\w.]*(?:\s(?:[^<>{}]|\{[^{}]*\})*)?/?>", blank, text, flags=re.S)
    text = blank_expressions(text)
    text = re.sub(r"\]\([^)\s]*\)", lambda m: "]" + " " * (len(m.group(0)) - 1), text)
    text = re.sub(r"https?://\S+", blank, text)
    return text


def line_of(text: str, pos: int) -> int:
    return text.count("\n", 0, pos) + 1


def excerpt(text: str, start: int, end: int) -> str:
    return " ".join(text[max(0, start - 20) : end + 20].split())[:90]


def detect_lang(path: Path, raw: str) -> str:
    if re.search(r"\.en\.(?:mdx?|txt|html)$", path.name):
        return "en"
    if re.search(r"\.de\.(?:mdx?|txt|html)$", path.name):
        return "de"
    front = re.match(r"\A---\n(.*?)\n---", raw, flags=re.S)
    if front:
        lang = re.search(r"^(?:lang|language|locale):\s*[\"']?(de|en)", front.group(1), flags=re.M)
        if lang:
            return lang.group(1)
    words = re.findall(r"\b\w+\b", raw.lower())
    de = sum(w in {"und", "der", "die", "das", "nicht", "ist", "mit", "für", "du", "ich"} for w in words)
    en = sum(w in {"and", "the", "not", "is", "with", "for", "you", "this", "that", "of"} for w in words)
    return "de" if de > en else "en"


def sentences(prose: str) -> list[str]:
    flat = prose
    for abbr in ABBREVIATIONS:
        flat = flat.replace(abbr, abbr.replace(".", "․"))
    blocks = []
    for block in re.split(r"\n\s*\n", flat):
        lines = [ln for ln in block.splitlines() if ln.strip() and not re.match(r"\s*(?:#|\||[-*+] |\d+\. |>)", ln)]
        if lines:
            blocks.append(" ".join(ln.strip() for ln in lines))
    out = []
    for block in blocks:
        out += [s.strip() for s in re.split(r"(?<=[.!?])\s+(?=[\"„(]?[A-ZÄÖÜ0-9])", block) if len(s.split()) >= 3]
    return out


def check(path: Path, lang: str | None) -> tuple[str, list[Finding]]:
    raw = path.read_text(encoding="utf-8")
    lang = lang or detect_lang(path, raw)
    prose = prose_only(raw)
    # Phrases named in quotes are mentioned, not used: "avoid 'delve'" is not slop.
    unquoted = re.sub(r"\"[^\"]{0,120}\"|„[^“”„]{0,120}[“”]|“[^”“]{0,120}”", blank, prose)
    found: list[Finding] = []

    def add(pos: int, level: str, code: str, message: str, end: int | None = None) -> None:
        found.append(Finding(line_of(prose, pos), level, code, message, excerpt(prose, pos, end or pos + 1)))

    for m in HIDDEN.finditer(raw):
        found.append(Finding(line_of(raw, m.start()), "error", "hidden-char", f"invisible character U+{ord(m.group(0)):04X}"))

    for m in re.finditer(EM_DASH, prose):
        add(m.start(), "error", "em-dash", "em dash; use a period, comma, colon, or parentheses")
    for m in re.finditer(r"(?<=\w) (?:-|--) (?=\w)", prose):
        add(m.start(), "error", "hyphen-dash", "hyphen used as a dash")
    for para in re.finditer(r"(?:[^\n]+\n?)+", prose):
        dashes = [d.start() + para.start() for d in re.finditer(f" {EN_DASH} ", para.group(0))]
        if lang == "en" and dashes:
            add(dashes[0], "warn", "en-dash", "spaced en dash as punctuation; prefer a comma or period")
        elif lang == "de" and len(dashes) > 1:
            add(dashes[0], "warn", "dash-cluster", f"{len(dashes)} Gedankenstriche in one paragraph")

    for pattern in STOCK[lang]:
        for m in re.finditer(pattern, unquoted, flags=re.I):
            add(m.start(), "error", "stock-phrase", "stock phrase; say the concrete thing or cut it", m.end())
    for m in re.finditer(REVEAL[lang], unquoted, flags=re.I):
        add(m.start(), "error", "contrast-reveal", "\"it is not X, it is Y\"; state Y with its reason", m.end())
    contrasts = list(re.finditer(CONTRAST[lang], unquoted, flags=re.I))
    if len(contrasts) >= 2:
        add(contrasts[0].start(), "warn", "contrast-cluster", f"{len(contrasts)} \"not only ... but\" constructions", contrasts[0].end())

    markers = list(re.finditer(MARKER_WORDS[lang], unquoted, flags=re.I))
    if len(markers) >= 3:
        words = sorted({m.group(0).lower() for m in markers})
        add(markers[0].start(), "warn", "marker-words", f"{len(markers)} inflated words: {', '.join(words)}")

    connectors = list(re.finditer(CONNECTORS[lang], prose))
    sents = sentences(prose)
    if len(connectors) >= 4 and len(connectors) * 25 > len(sents):
        add(connectors[0].start(), "warn", "connectors", f"{len(connectors)} sentences open with an additive connector")

    for m in re.finditer(r"(?:^|(?<=[.!]\s))(?:\w+ ){0,2}\w+\? (?=[A-ZÄÖÜ])", prose, flags=re.M):
        add(m.start(), "warn", "label-question", "short question that labels your own point; state it", m.end())

    headings = re.findall(r"^#{2,3} (.+)$", prose, flags=re.M)
    colon = [h for h in headings if ":" in h]
    if len(colon) >= 3 and len(colon) * 4 >= len(headings):
        pos = prose.find(colon[0])
        add(pos, "warn", "colon-headings", f"{len(colon)} of {len(headings)} headings use the \"X: Y\" form", pos + len(colon[0]))

    words = len(re.findall(r"\b\w+\b", prose))
    bold = [m for m in re.finditer(r"\*\*[^*\n]+\*\*", prose) if not prose[prose.rfind("\n", 0, m.start()) + 1 :].lstrip().startswith("|")]
    if len(bold) >= 5 and len(bold) * 1000 > 4 * max(words, 1):
        add(bold[0].start(), "warn", "bold", f"{len(bold)} bold spans in {words} words; bold only what a skimmer must catch")

    short = [p for p in re.split(r"\n\s*\n", prose) if p.strip() and not p.lstrip().startswith(("#", "|", "-", "*", ">")) and len(p.split()) <= 7 and p.strip()[-1:] in ".!"]
    if len(short) >= 3:
        pos = prose.find(short[0].strip())
        add(pos, "warn", "drama-paragraphs", f"{len(short)} one-line paragraphs used for effect")

    if lang == "de":
        for m in re.finditer(r"„[^“”\n]{1,200}”", prose):
            add(m.start(), "error", "quote-pair", "German quote closed with ” instead of “", m.end())
        straight = list(re.finditer(r"(?<![=\w])\"[^\"\n]{1,120}\"", prose))
        if straight:
            add(straight[0].start(), "warn", "straight-quotes", f"{len(straight)} straight quotes in prose; use „…“", straight[0].end())
        for m in re.finditer(r"“[^“”„\n]{1,120}”", prose):
            add(m.start(), "warn", "english-quotes", "English quotes “…” in German text; use „…“", m.end())
        for m in re.finditer(r"(?<![\w.])\d+\.\d{1,2} ?(?:%|€|Euro|GB|MB|KB|TB|ms|s|Sekunden|Minuten|Stunden|Tage)(?!\w)", prose):
            add(m.start(), "warn", "decimal-point", "decimal point; German uses a comma (3,5 GB)", m.end())
        for m in re.finditer(r"\b\d+(?:GB|MB|KB|TB|ms)\b", prose):
            add(m.start(), "warn", "unit-space", "no space before the unit (4 GB)", m.end())
        for m in re.finditer(r"\b[A-ZÄÖÜ][a-zäöüß]+'s\b", prose):
            add(m.start(), "warn", "apostrophe-genitive", "English genitive apostrophe; German writes \"Peters\"", m.end())
        for pattern, fix in CALQUES:
            for m in re.finditer(pattern, unquoted, flags=re.I):
                add(m.start(), "warn", "calque", f"English phrasing; consider {fix}", m.end())

    lengths = [len(s.split()) for s in sents]
    if len(lengths) >= 20:
        mean = statistics.mean(lengths)
        spread = statistics.pstdev(lengths) / mean if mean else 0
        if spread < 0.4:
            add(0, "warn", "flat-rhythm", f"sentence lengths barely vary (stddev/mean {spread:.2f}); mix short and long")
        long_ones = sum(n > 30 for n in lengths)
        if long_ones * 10 > len(lengths):
            add(0, "warn", "long-sentences", f"{long_ones} sentences over 30 words")

    found.sort(key=lambda f: (f.line, f.level != "error"))
    return lang, found


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("files", nargs="+", type=Path)
    parser.add_argument("--lang", choices=["de", "en"], help="force a language instead of detecting it per file")
    parser.add_argument("--format", choices=["text", "json"], default="text")
    args = parser.parse_args()

    failed = False
    report = []
    for path in args.files:
        if not path.is_file():
            print(f"{path}: not a file", file=sys.stderr)
            failed = True
            continue
        lang, found = check(path, args.lang)
        failed = failed or any(f.level == "error" for f in found)
        report.append({"file": str(path), "lang": lang, "findings": [asdict(f) for f in found]})

    if args.format == "json":
        print(json.dumps(report, ensure_ascii=False, indent=2))
    else:
        for entry in report:
            errors = sum(f["level"] == "error" for f in entry["findings"])
            warns = len(entry["findings"]) - errors
            print(f"{entry['file']} [{entry['lang']}]: {errors} errors, {warns} warnings")
            for f in entry["findings"]:
                tail = f"  | {f['excerpt']}" if f["excerpt"] else ""
                print(f"  {f['line']}: {f['level']} {f['code']}: {f['message']}{tail}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
