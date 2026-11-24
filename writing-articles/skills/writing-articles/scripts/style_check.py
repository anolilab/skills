#!/usr/bin/env python3
"""Mechanical style check for German and English articles (Markdown, MDX, plain text).

Reports what can be found without judgement: dash punctuation, hidden characters,
stock phrases, contrast reveals, quote and number typography, heading and bold
patterns, and flat sentence rhythm. It reads only the files it is given and needs no
packages. It makes no network calls unless a LanguageTool server is given with
--languagetool or LANGUAGETOOL_URL (for example a local one on
http://127.0.0.1:8010); its grammar and spelling matches are then added as warnings.

Exit status: 1 when any error is found, 0 otherwise. Warnings never fail the run;
they are leads for the edit pass, not verdicts.

    python3 style_check.py content/blog/post.mdx content/blog/post.en.mdx
    python3 style_check.py --lang de --format json draft.md
"""

from __future__ import annotations

import argparse
import json
import os
import re
import statistics
import sys
import urllib.error
import urllib.parse
import urllib.request
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


def po_values(text: str) -> str:
    """Keep only the msgstr text of a gettext catalog; ids, context, and comments are not editable prose."""
    text = re.sub(r"^#.*$", blank, text, flags=re.M)
    text = re.sub(r'^(?:msgctxt|msgid|msgid_plural) .*\n(?:[ \t]*".*\n?)*', blank, text, flags=re.M)
    text = re.sub(r'^msgstr(?:\[\d+\])? "', blank, text, flags=re.M)
    return re.sub(r'^([ \t]*)"|"[ \t]*$', lambda m: " " * len(m.group(0)), text, flags=re.M)


def prose_only(text: str, suffix: str = ".mdx") -> str:
    """Blank out everything that is not running prose: frontmatter, code, markup, links."""
    if suffix == ".po":
        text = po_values(text)
    text = re.sub(r"\A---\n.*?\n---\n", blank, text, flags=re.S)
    # CommonMark: the closing fence uses the opener's character and is at least as long.
    text = re.sub(r"^(`{3,})(?!`).*?^\1`*[ \t]*$", blank, text, flags=re.S | re.M)
    text = re.sub(r"^(~{3,})(?!~).*?^\1~*[ \t]*$", blank, text, flags=re.S | re.M)
    text = re.sub(r"`[^`\n]+`", blank, text)
    text = re.sub(r"\{/\*.*?\*/\}|<!--.*?-->", blank, text, flags=re.S)
    text = re.sub(r"^(?:import|export) .*$", blank, text, flags=re.M)
    text = re.sub(r"</?[A-Za-z][\w.]*(?:\s(?:[^<>{}]|\{[^{}]*\})*)?/?>", blank, text, flags=re.S)
    if suffix in {".mdx", ".po"}:
        # {…} is an expression only in MDX (and a placeholder in catalogs); in plain text a brace is a brace.
        text = blank_expressions(text)
    text = re.sub(r"\]\((?:<[^>\n]*>|[^)\s]*)\)", lambda m: "]" + " " * (len(m.group(0)) - 1), text)
    text = re.sub(r"https?://\S+", blank, text)
    return text


# Rules that only react to what prose_only() leaves behind (runs of spaces where markup was, headings and list
# items without a final period), or that flag a valid choice: Oxford -ize spelling in British text, and German
# place names inside proper names ("Digitalbonus Bayern").
LT_DISABLED = [
    "WHITESPACE_RULE",
    "CONSECUTIVE_SPACES",
    "PUNCTUATION_PARAGRAPH_END",
    "SENTENCE_WHITESPACE",
    "COMMA_PARENTHESIS_WHITESPACE",
    "OXFORD_SPELLING_Z_NOT_S",
    "BAYERN",
]


BRITISH = r"\b(?:programmes?|organis\w+|\w+isation|colours?|behaviours?|analys(?:e|ed|ing)|licence|centre|favour\w*)\b"
AMERICAN = r"\b(?:programs?|organiz\w+|\w+ization|colors?|behaviors?|analyz(?:e|ed|ing)|center|favor\w*)\b"


def lt_language(prose: str, lang: str) -> str:
    """The LanguageTool language code; English follows the spelling the text already uses (American by default)."""
    if lang == "de":
        return "de-DE"
    british = len(re.findall(BRITISH, prose, flags=re.I))
    american = len(re.findall(AMERICAN, prose, flags=re.I))
    return "en-GB" if british > american else "en-US"


def languagetool(url: str, prose: str, lang: str) -> list[dict]:
    """Grammar and spelling matches from a LanguageTool server, with offsets into `prose`."""
    # Markdown markers and bold list labels ("- **Kosten:** Die …") are not part of the sentence; blank them so
    # offsets stay the same and the sentence after a label is not read as lower-case text.
    text = re.sub(
        r"^[ \t]*(?:#{1,6} |[-*+] (?:\*\*[^*\n]+\*\* ?)?|\d+\. (?:\*\*[^*\n]+\*\* ?)?|> |\|.*$)", lambda m: " " * len(m.group(0)), prose, flags=re.M
    )
    data = urllib.parse.urlencode({"text": text, "language": lt_language(prose, lang), "disabledRules": ",".join(LT_DISABLED)}).encode()
    request = urllib.request.Request(url.rstrip("/") + "/v2/check", data=data)
    with urllib.request.urlopen(request, timeout=120) as response:  # noqa: S310 - the URL is the user's own server
        matches = json.load(response)["matches"]
    # A match next to a blanked span (code, a component, a link target) is about the gap, not the prose.
    return [m for m in matches if "  " not in text[max(0, m["offset"] - 2) : m["offset"] + m["length"] + 2]]


def line_of(text: str, pos: int) -> int:
    return text.count("\n", 0, pos) + 1


def excerpt(text: str, start: int, end: int) -> str:
    return " ".join(text[max(0, start - 20) : end + 20].split())[:90]


def detect_lang(path: Path, raw: str) -> str:
    if re.search(r"\.en\.(?:mdx?|txt|html)$", path.name):
        return "en"
    if re.search(r"\.de\.(?:mdx?|txt|html)$", path.name):
        return "de"
    if path.suffix.lower() == ".po":
        header = re.search(r'^"Language: (de|en)\b', raw, flags=re.M)
        if header:
            return header.group(1)
        # msgid text is usually the source language; count only the translations.
        raw = po_values(raw)
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


def check(path: Path, lang: str | None, lt_url: str | None = None) -> tuple[str, list[Finding]]:
    raw = path.read_text(encoding="utf-8")
    lang = lang or detect_lang(path, raw)
    prose = prose_only(raw, path.suffix.lower())
    # Phrases named in quotes are mentioned, not used: "avoid 'delve'" is not slop.
    unquoted = re.sub(r"\"[^\"]{0,120}\"|„[^“”„]{0,120}[“”]|“[^”“]{0,120}”", blank, prose)
    found: list[Finding] = []

    def add(pos: int, level: str, code: str, message: str, end: int | None = None) -> None:
        found.append(Finding(line_of(prose, pos), level, code, message, excerpt(prose, pos, end or pos + 1)))

    for m in HIDDEN.finditer(raw):
        found.append(Finding(line_of(raw, m.start()), "error", "hidden-char", f"invisible character U+{ord(m.group(0)):04X}"))

    quoted_lines = {line_of(prose, m.start()) for m in re.finditer(r"^[ \t]*>", prose, flags=re.M)}
    for m in re.finditer(EM_DASH, prose):
        if line_of(prose, m.start()) in quoted_lines:
            # A block quotation is the source's wording, which the author may not change.
            add(m.start(), "warn", "em-dash", "em dash in a block quotation; keep it if the source has it")
        else:
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
        for m in re.finditer(r"„[^“”\"\n]{1,200}[”\"]", prose):
            add(m.start(), "error", "quote-pair", "German quote closed with ” or \" instead of “", m.end())
        straight = list(re.finditer(r"(?<![=\w])\"[^\"\n]{1,120}\"", prose))
        if straight:
            add(straight[0].start(), "warn", "straight-quotes", f"{len(straight)} straight quotes in prose; use „…“", straight[0].end())
        for m in re.finditer(r"“[^“”„\n]{1,120}”", prose):
            add(m.start(), "warn", "english-quotes", "English quotes “…” in German text; use „…“", m.end())
        for m in re.finditer(r"(?<![\w.])\d+\.\d{1,2} ?(?:%|€|Euro|GB|MB|KB|TB|ms|s|Sekunden|Minuten|Stunden|Tage)(?!\w)", prose):
            add(m.start(), "warn", "decimal-point", "decimal point; German uses a comma (3,5 GB)", m.end())
        for m in re.finditer(r"\b\d+(?:GB|MB|KB|TB|ms)\b", prose):
            add(m.start(), "warn", "unit-space", "no space before the unit (4 GB)", m.end())
        for m in re.finditer(r"\b(?!Let's|It's|That's|What's|McDonald's)[A-ZÄÖÜ][a-zäöüß]+'s\b", prose):
            add(m.start(), "warn", "apostrophe-genitive", "English genitive apostrophe; German writes \"Peters\"", m.end())
        for pattern, fix in CALQUES:
            for m in re.finditer(pattern, unquoted, flags=re.I):
                add(m.start(), "warn", "calque", f"English phrasing; consider {fix}", m.end())

    lengths = [len(s.split()) for s in sents]
    if len(lengths) >= 20:
        mean = statistics.mean(lengths)
        spread = statistics.pstdev(lengths) / mean if mean else 0
        if spread < 0.5:
            add(0, "warn", "flat-rhythm", f"sentence lengths barely vary (stddev/mean {spread:.2f}, aim for 0.5 or more); mix short and long")
        long_ones = sum(n > 30 for n in lengths)
        if long_ones * 10 > len(lengths):
            add(0, "warn", "long-sentences", f"{long_ones} sentences over 30 words")
        short_ones = sum(n <= 8 for n in lengths)
        if short_ones * 100 < 15 * len(lengths):
            add(0, "warn", "few-short", f"only {short_ones} of {len(lengths)} sentences have 8 words or fewer; aim for about one in six")

    # Colons and semicolons inside running text: a label, a colon, then the point ("Wichtig für X: ...") and
    # clauses chained with semicolons are the sentences detectors and readers most often mark as machine-written.
    colon_sents = [s for s in sents if re.search(r"\w: \S", s)]
    if len(sents) >= 10 and len(colon_sents) * 100 > 15 * len(sents):
        pos = prose.find(colon_sents[0][:40])
        add(max(pos, 0), "warn", "colon-density", f"{len(colon_sents)} of {len(sents)} sentences hinge on a colon; turn most into two sentences or a subordinate clause")
    labels = [s for s in sents if re.match(r"(?:[\w-]+ ){0,6}[\w-]+: \S", s)]
    if len(labels) >= 2:
        pos = prose.find(labels[0][:40])
        add(max(pos, 0), "warn", "label-colon", f"{len(labels)} sentences open with a label and a colon (\"{labels[0][:40]}\")")
    semis = list(re.finditer(r"\w; \w", unquoted))
    if len(semis) >= 2:
        add(semis[0].start(), "warn", "semicolons", f"{len(semis)} semicolons in running text; use a period or a conjunction", semis[0].end())
    tail = r", (?:also|d\. ?h\.|sprich) (?:\d|rund|etwa|knapp|gut)" if lang == "de" else r", (?:i\.e\.|that is|so) (?:\d|about|around|roughly)"
    for m in re.finditer(tail, unquoted, flags=re.I):
        add(m.start(), "warn", "appended-figure", "figure tacked on after a comma; give it its own clause", m.end())
    if len(sents) >= 20:
        first = [s.split()[0].strip("„\"(").lower() for s in sents]
        word, count = max(((w, first.count(w)) for w in set(first)), key=lambda item: item[1])
        if count >= 6 and count * 100 > 12 * len(sents):
            add(0, "warn", "same-openers", f"{count} of {len(sents)} sentences start with \"{word}\"; front a time, condition, object or link word instead")

    if lt_url and path.suffix.lower() != ".po":
        try:
            unknown: dict[str, int] = {}
            for match in languagetool(lt_url, prose, lang):
                start, length = match["offset"], match["length"]
                if match["rule"].get("issueType") == "misspelling":
                    # Names and terms fill this list in technical articles; one line per file keeps it readable.
                    unknown.setdefault(prose[start : start + length], start)
                    continue
                hints = [r["value"] for r in match.get("replacements", [])[:3]]
                hint = f" (try: {', '.join(hints)})" if hints else ""
                add(start, "warn", f"lt:{match['rule']['id']}", match["message"] + hint, start + length)
            if unknown:
                words = sorted(unknown, key=str.lower)
                add(min(unknown.values()), "warn", "lt:spelling", f"{len(words)} words LanguageTool does not know; check for typos: {', '.join(words)}")
        except (urllib.error.URLError, TimeoutError, ValueError, KeyError) as exc:
            print(f"{path}: LanguageTool at {lt_url} not used: {exc}", file=sys.stderr)

    found.sort(key=lambda f: (f.line, f.level != "error"))
    return lang, found


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("files", nargs="+", type=Path)
    parser.add_argument("--lang", choices=["de", "en"], help="force a language instead of detecting it per file")
    parser.add_argument("--format", choices=["text", "json"], default="text")
    parser.add_argument(
        "--languagetool",
        default=os.environ.get("LANGUAGETOOL_URL"),
        metavar="URL",
        help="LanguageTool server for grammar and spelling, e.g. http://127.0.0.1:8010 (default: $LANGUAGETOOL_URL)",
    )
    args = parser.parse_args()

    failed = False
    report = []
    for path in args.files:
        if not path.is_file():
            print(f"{path}: not a file", file=sys.stderr)
            failed = True
            continue
        lang, found = check(path, args.lang, args.languagetool)
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
