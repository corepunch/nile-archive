#!/usr/bin/env python3
"""Translation catalogues: extract, merge, check and fit fonts to them.

Every player-visible string is marked in Lua with ``tr``, ``trn`` or ``trc``
(engine/lua/l10n.lua). This tool runs GNU gettext over the marked sources and
keeps one PO catalogue per language and domain:

    engine          engine/lua/**            -> engine/data/common/l10n/<tag>.po
    <game>          games/<game>/lua/**      -> games/<game>/data/common/l10n/<tag>.po

A game lists its languages in data/common/l10n/languages.txt, the language it
is written in first. The engine's words are English and get a catalogue for
every other language a game offers.

    python3 tools/l10n.py update [DOMAIN ...]   extract and merge into every catalogue
    python3 tools/l10n.py check  [DOMAIN ...]   fail on stale, untranslated or broken entries
                                                or text no font can draw
    python3 tools/l10n.py status [DOMAIN ...]   translated / total per catalogue
    python3 tools/l10n.py strings DOMAIN TAG    untranslated entries as PO, for a translator
    python3 tools/l10n.py fonts --source DIR    subset the engine's script fonts to the catalogues

Needs gettext (xgettext, msgmerge, msgfmt) and, for fonts and check, fontTools.
See docs/LOCALIZATION.md.
"""
from __future__ import annotations

import argparse
import re
import shutil
import subprocess
import sys
import tempfile
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ENGINE_SOURCE = "en"
KEYWORDS = ["-k", "-ktr", "-ktrn:1,2", "-ktrc:1c,2", "-kN_", "--add-comments=TRANSLATORS:"]
CATALOGUE = "data/common/l10n"
FONT_DIR = ROOT / "engine/data/common/fonts"

# Mirrors engine/lua/l10n.lua (PLURAL_RULE, PLURAL_FORMS and SCRIPT_FONTS);
# tests/lua/localization.lua checks the catalogues' headers against the runtime.
PLURAL_FORMS = {
    "one_other": "nplurals=2; plural=(n != 1);",
    "zero_one": "nplurals=2; plural=(n > 1);",
    "none": "nplurals=1; plural=0;",
    "slavic": "nplurals=3; plural=(n%10==1 && n%100!=11 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2);",
    "polish": "nplurals=3; plural=(n==1 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2);",
}
PLURAL_RULE = {
    "fr": "zero_one", "pt-BR": "zero_one", "tr": "zero_one",
    "ja": "none", "ko": "none", "zh": "none", "id": "none", "th": "none", "vi": "none",
    "ru": "slavic", "uk": "slavic", "be": "slavic", "pl": "polish",
}
# Source file for each engine script font, and the languages whose characters
# it must hold (None: every language).
SCRIPT_FONTS = {
    "NotoSans-Bold.ttf": None,
    "NotoSansCJKjp-Regular.otf": {"ja"},
    "NotoSansCJKkr-Regular.otf": {"ko"},
    "NotoSansCJKsc-Regular.otf": {"zh-Hans"},
}
# Characters every subset keeps, so numbers, prices and punctuation never
# depend on what the catalogues happen to say today.
BASE_CHARS = "".join(chr(c) for c in range(0x20, 0x7F)) + "\u00a0·×–—‘’“”„«»…€−°№"
CJK_BASE = "、。，．！？：；（）「」『』【】〈〉《》〜ー・…％＋－０１２３４５６７８９"


def plural_rule(tag: str) -> str:
    return PLURAL_RULE.get(tag) or PLURAL_RULE.get(tag.split("-")[0]) or "one_other"


# ------------------------------------------------------------------ domains

class Domain:
    def __init__(self, name: str, sources: Path, catalogues: Path, source: str, languages: list[str]):
        self.name, self.sources, self.catalogues = name, sources, catalogues
        self.source, self.languages = source, languages

    @property
    def targets(self) -> list[str]:
        """Every catalogue: each translation, and a non-English source's own,
        which holds the plural forms a two-form msgid cannot (see l10n.lua)."""
        return [tag for tag in self.languages if tag != self.source or plural_rule(tag) != "one_other"]

    def po(self, tag: str) -> Path:
        return self.catalogues / f"{tag}.po"

    def lua_files(self) -> list[Path]:
        return sorted(p for p in self.sources.rglob("*.lua") if p.is_file())


def read_languages(path: Path) -> list[str]:
    if not path.exists():
        return []
    tags = []
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.split("#", 1)[0].strip()
        if line:
            tags.append(line)
    return tags


def games() -> list[str]:
    return sorted(p.relative_to(ROOT / "games").parts[0] for p in ROOT.glob(f"games/*/{CATALOGUE}/languages.txt"))


def domain(name: str) -> Domain:
    if name == "engine":
        offered = {tag for game in games() for tag in domain(game).languages}
        languages = [ENGINE_SOURCE] + sorted(offered - {ENGINE_SOURCE})
        return Domain("engine", ROOT / "engine/lua", ROOT / "engine" / CATALOGUE, ENGINE_SOURCE, languages)
    base = ROOT / "games" / name
    languages = read_languages(base / CATALOGUE / "languages.txt")
    if not languages:
        sys.exit(f"{name}: no {CATALOGUE}/languages.txt")
    return Domain(name, base / "lua", base / CATALOGUE, languages[0], languages)


def domains(names: list[str]) -> list[Domain]:
    return [domain(n) for n in (names or ["engine"] + games())]


# ------------------------------------------------------------------ gettext

def tool(name: str) -> str:
    found = shutil.which(name)
    if not found:
        sys.exit(f"{name} not found: install GNU gettext (brew install gettext, apt install gettext)")
    return found


def extract(d: Domain, out: Path) -> None:
    files = [str(p.relative_to(ROOT)) for p in d.lua_files()]
    subprocess.run([tool("xgettext"), "--language=Lua", "--from-code=UTF-8", *KEYWORDS, "--no-wrap",
                    "--add-location=file", "--sort-by-file", f"--package-name={d.name}",
                    "--msgid-bugs-address=https://github.com/corepunch/nile-archive/issues",
                    "-o", str(out), *files], cwd=ROOT, check=True)
    if not out.exists():                  # nothing marked yet: an empty template
        out.write_text(header(d.source, ""), encoding="utf-8")


def header(tag: str, project: str) -> str:
    lines = [f"Project-Id-Version: {project}", f"Language: {tag}", "MIME-Version: 1.0",
             "Content-Type: text/plain; charset=UTF-8", "Content-Transfer-Encoding: 8bit",
             f"Plural-Forms: {PLURAL_FORMS[plural_rule(tag)]}"]
    return 'msgid ""\nmsgstr ""\n' + "".join(f'"{line}\\n"\n' for line in lines) + "\n"


def normalise(path: Path, d: Domain, tag: str) -> None:
    """Our own header (no dates, the runtime's plural rule) and no obsolete entries."""
    text = path.read_text(encoding="utf-8")
    body = re.sub(r'\A(?:#.*\n)*msgid ""\nmsgstr ""\n(?:".*"\n)*\n?', "", text)
    body = "\n".join(chunk for chunk in body.split("\n\n") if chunk.strip() and not chunk.lstrip().startswith("#~"))
    path.write_text(header(tag, d.name) + body.strip("\n") + ("\n" if body.strip() else ""), encoding="utf-8")


def update(d: Domain) -> None:
    d.catalogues.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        pot = Path(tmp) / "messages.pot"
        extract(d, pot)
        for tag in d.targets:
            po = d.po(tag)
            if not po.exists():
                po.write_text(header(tag, d.name), encoding="utf-8")
            subprocess.run([tool("msgmerge"), "--quiet", "--update", "--backup=none", "--no-wrap",
                            "--no-fuzzy-matching", "--add-location=file", "--sort-by-file", str(po), str(pot)], check=True)
            normalise(po, d, tag)
    print(f"{d.name}: {len(d.targets)} catalogues updated")


# ------------------------------------------------------------------ parsing

class Entry:
    def __init__(self):
        self.context = None
        self.msgid = None
        self.plural = None
        self.msgstr = None
        self.forms: dict[int, str] = {}
        self.flags: set[str] = set()
        self.comments: list[str] = []

    @property
    def key(self):
        return (self.context, self.msgid)

    @property
    def translations(self) -> list[str]:
        return [self.forms[i] for i in sorted(self.forms)] if self.plural is not None else [self.msgstr or ""]

    @property
    def translated(self) -> bool:
        return "fuzzy" not in self.flags and all(self.translations)


def unquote(s: str) -> str:
    return re.sub(r'\\(.)', lambda m: {"n": "\n", "t": "\t", "r": "\r"}.get(m.group(1), m.group(1)), s)


def parse(path: Path) -> tuple[dict, list[Entry]]:
    """The header fields and the entries of a PO file (obsolete ones left out)."""
    entries, entry, field = [], Entry(), None

    def finish():
        nonlocal entry, field
        if entry.msgid is not None:
            entries.append(entry)
        entry, field = Entry(), None

    for line in path.read_text(encoding="utf-8").splitlines():
        if entry.msgstr is not None or entry.forms:
            if line.startswith("#") or line.startswith("msgctxt ") or line.startswith("msgid "):
                finish()
        m = re.match(r'^(msgctxt|msgid_plural|msgid|msgstr)(?:\[(\d+)\])?\s+"(.*)"\s*$', line)
        if line.startswith("#,"):
            entry.flags |= {f.strip() for f in line[2:].split(",")}
        elif line.startswith("#.") or line.startswith("#:"):
            entry.comments.append(line)
        elif m:
            keyword, index, value = m.group(1), m.group(2), unquote(m.group(3))
            if index is not None:
                entry.forms[int(index)] = value
                field = ("form", int(index))
            else:
                attr = {"msgctxt": "context", "msgid": "msgid", "msgid_plural": "plural", "msgstr": "msgstr"}[keyword]
                setattr(entry, attr, value)
                field = attr
        elif re.match(r'^\s*".*"\s*$', line) and field:
            more = unquote(re.match(r'^\s*"(.*)"\s*$', line).group(1))
            if isinstance(field, tuple):
                entry.forms[field[1]] += more
            else:
                setattr(entry, field, getattr(entry, field) + more)
        elif not line.strip() and (entry.msgstr is not None or entry.forms):
            finish()
    finish()
    head = {}
    if entries and entries[0].msgid == "":
        for line in (entries.pop(0).msgstr or "").splitlines():
            if ":" in line:
                k, v = line.split(":", 1)
                head[k.strip()] = v.strip()
    return head, entries


# ------------------------------------------------------------------ checks

DIRECTIVE = re.compile(r"%[-+ #0]*\d*(?:\.\d+)?[cdiouxXeEfgGqsaA%]")
DOTTED = re.compile(r"\bl10n\.(?:tr|trn|trc|N_)\s*[\(\"'\[]")


def directives(s: str) -> list[str]:
    return [d[-1] for d in DIRECTIVE.findall(s) if d != "%%"]


def font_chars(paths: list[Path]) -> set[int]:
    from fontTools.ttLib import TTFont
    chars: set[int] = set()
    for path in paths:
        if path.exists():
            chars |= set(TTFont(path, lazy=True, fontNumber=0).getBestCmap() or {})
    return chars


def script_fonts(tag: str) -> list[str]:
    own = [name for name, langs in SCRIPT_FONTS.items() if langs and (tag in langs or tag.split("-")[0] in langs)]
    return own + ["NotoSans-Bold.ttf"]


def drawable(ch: str) -> bool:
    return not (ch.isspace() or unicodedata.category(ch) in ("Cc", "Cf", "Mn"))


def check(d: Domain) -> list[str]:
    problems = []
    for path in d.lua_files():
        for n, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            if DOTTED.search(line) and not path.name == "l10n.lua":
                problems.append(f"{path.relative_to(ROOT)}:{n}: call the local alias tr/trn/trc so xgettext sees the string")
    if d.name != "engine":
        listed = set(d.languages)
        present = {p.stem for p in d.catalogues.glob("*.po")}
        for tag in sorted(present - listed):
            problems.append(f"{d.name}: {tag}.po is not in languages.txt")
    with tempfile.TemporaryDirectory() as tmp:
        pot = Path(tmp) / "messages.pot"
        extract(d, pot)
        _, template = parse(pot)
    wanted = {e.key: e for e in template}
    game_fonts = sorted((d.catalogues.parent / "fonts").glob("*.[ot]tf")) if d.name != "engine" else []
    for tag in d.targets:
        po = d.po(tag)
        if not po.exists():
            problems.append(f"{d.name}: {po.relative_to(ROOT)} is missing (run tools/l10n.py update {d.name})")
            continue
        head, entries = parse(po)
        name = f"{d.name}/{tag}"
        if head.get("Language") != tag:
            problems.append(f"{name}: header Language is {head.get('Language')!r}")
        if head.get("Plural-Forms") != PLURAL_FORMS[plural_rule(tag)]:
            problems.append(f"{name}: Plural-Forms should be {PLURAL_FORMS[plural_rule(tag)]!r}")
        have = {e.key: e for e in entries}
        stale = [k for k in have if k not in wanted]
        missing = [k for k in wanted if k not in have]
        if stale or missing:
            problems.append(f"{name}: {len(missing)} new and {len(stale)} stale entries (run tools/l10n.py update {d.name})")
        own = tag == d.source        # only its plural forms are required
        untranslated = [e for e in entries if e.key in wanted and not e.translated and (not own or e.plural is not None)]
        if untranslated:
            sample = untranslated[0].msgid.replace("\n", "\\n")[:60]
            problems.append(f"{name}: {len(untranslated)} untranslated or fuzzy entries, first {sample!r}")
        nplurals = int(re.search(r"nplurals=(\d+)", PLURAL_FORMS[plural_rule(tag)]).group(1))
        drawn = font_chars(game_fonts + [FONT_DIR / f for f in script_fonts(tag)]) if game_fonts or d.name == "engine" else None
        for e in entries:
            if e.key not in wanted or not e.translated or (own and e.plural is None):
                continue
            if e.plural is not None and len(e.forms) != nplurals:
                problems.append(f"{name}: {e.msgid!r} needs {nplurals} plural forms")
            for text in e.translations:
                if directives(text) != directives(e.msgid):
                    problems.append(f"{name}: {e.msgid!r} -> {text!r}: format directives must match in order")
                if drawn is not None:
                    lost = sorted({ch for ch in text if drawable(ch) and ord(ch) not in drawn})
                    if lost:
                        problems.append(f"{name}: no font draws {''.join(lost)!r} in {text[:40]!r} (run tools/l10n.py fonts)")
        result = subprocess.run([tool("msgfmt"), "--check", "-o", "/dev/null", str(po)], capture_output=True, text=True)
        if result.returncode:
            problems.append(f"{name}: msgfmt --check failed\n{result.stderr.strip()}")
    return problems


def status(d: Domain) -> None:
    with tempfile.TemporaryDirectory() as tmp:
        pot = Path(tmp) / "messages.pot"
        extract(d, pot)
        _, template = parse(pot)
    words = sum(len(e.msgid.split()) for e in template)
    print(f"{d.name} (source {d.source}): {len(template)} strings, {words} words")
    for tag in d.targets:
        if not d.po(tag).exists():
            print(f"  {tag:8} missing")
            continue
        _, entries = parse(d.po(tag))
        done = sum(e.translated for e in entries)
        print(f"  {tag:8} {done}/{len(entries)}")


def untranslated(d: Domain, tag: str) -> None:
    """The entries a translator still has to fill, as PO text on stdout."""
    _, entries = parse(d.po(tag))
    out = []
    for e in entries:
        if e.translated:
            continue
        block = [c for c in e.comments]
        if e.context is not None:
            block.append(f"msgctxt {quote(e.context)}")
        block.append(f"msgid {quote(e.msgid)}")
        if e.plural is not None:
            block.append(f"msgid_plural {quote(e.plural)}")
            n = int(re.search(r"nplurals=(\d+)", PLURAL_FORMS[plural_rule(tag)]).group(1))
            block += [f'msgstr[{i}] ""' for i in range(n)]
        else:
            block.append('msgstr ""')
        out.append("\n".join(block))
    print("\n\n".join(out))


def quote(s: str) -> str:
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n").replace("\t", "\\t") + '"'


# ------------------------------------------------------------------ fonts

def catalogue_chars(tags: set[str] | None) -> str:
    chars = set(BASE_CHARS)
    for d in domains([]):
        for tag in d.targets:
            if tags is not None and tag not in tags and tag.split("-")[0] not in tags:
                continue
            if d.po(tag).exists():
                for e in parse(d.po(tag))[1]:
                    for text in e.translations:
                        chars |= set(text)
        if tags is None:        # the source texts too (Nile Archive is written in Russian)
            with tempfile.TemporaryDirectory() as tmp:
                pot = Path(tmp) / "messages.pot"
                extract(d, pot)
                for e in parse(pot)[1]:
                    chars |= set(e.msgid) | set(e.plural or "")
    if tags is not None:
        chars |= set(CJK_BASE)
    return "".join(sorted(c for c in chars if drawable(c) or c == " "))


def fonts(source: Path) -> None:
    from fontTools import subset
    FONT_DIR.mkdir(parents=True, exist_ok=True)
    for name, tags in SCRIPT_FONTS.items():
        found = next((p for p in source.rglob("*") if p.name.lower() == name.lower()), None)
        if not found:
            sys.exit(f"{name} not found under {source}")
        text = catalogue_chars(tags)
        out = FONT_DIR / name
        options = subset.Options()
        options.layout_features = ["kern", "liga", "locl", "vert", "ccmp"]
        options.name_IDs = ["*"]              # keep the copyright and OFL licence records
        options.notdef_outline = True
        options.hinting = False
        options.desubroutinize = True
        font = subset.load_font(str(found), options)
        subsetter = subset.Subsetter(options)
        subsetter.populate(text=text)
        subsetter.subset(font)
        subset.save_font(font, str(out), options)
        print(f"{out.relative_to(ROOT)}: {len(text)} characters, {out.stat().st_size // 1024} KB")


# ------------------------------------------------------------------ main

def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="command", required=True)
    for name in ("update", "check", "status"):
        sub.add_parser(name).add_argument("domains", nargs="*", help="engine or a game; all by default")
    strings = sub.add_parser("strings")
    strings.add_argument("domain")
    strings.add_argument("tag")
    f = sub.add_parser("fonts")
    f.add_argument("--source", type=Path, required=True, help="folder holding the full Noto fonts")
    args = ap.parse_args()
    if args.command == "update":
        for d in domains(args.domains):
            update(d)
    elif args.command == "status":
        for d in domains(args.domains):
            status(d)
    elif args.command == "strings":
        untranslated(domain(args.domain), args.tag)
    elif args.command == "fonts":
        fonts(args.source)
    else:
        problems = [p for d in domains(args.domains) for p in check(d)]
        for p in problems:
            print(p, file=sys.stderr)
        if problems:
            return 1
        print("l10n: every catalogue is current, complete and drawable")
    return 0


if __name__ == "__main__":
    sys.exit(main())
