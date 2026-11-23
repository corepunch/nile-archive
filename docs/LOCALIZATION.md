# Localization

Every game shows its words in the player's language. The engine owns the
mechanism: [`engine/lua/l10n.lua`](../engine/lua/l10n.lua) at runtime and
[`tools/l10n.py`](../tools/l10n.py) for catalogues and fonts. Games own their
text and their translations. Catalogues are standard GNU gettext PO files, so
any PO editor or translation service (Poedit, Weblate, Crowdin) can work on them.

| Game | Written in | Translations |
| --- | --- | --- |
| Relic Rush, Christmas Market, Emergency | English | German, Spanish, French, Italian, Brazilian Portuguese, Russian, Japanese, Korean, Simplified Chinese |
| Nile Archive | Russian | English, German, Spanish, French, Italian, Brazilian Portuguese, Japanese, Korean, Simplified Chinese |

## Marking text

Code holds the text in the language the game is written in and marks it. The
marked text is the gettext msgid, the key of every translation:

```lua
local l10n = require("l10n")
local tr, trn, trc, N_ = l10n.tr, l10n.trn, l10n.trc, l10n.N_

tr("Restart this level?")                          -- a phrase
tr("Unlocked in Advent %d"):format(n)              -- a template, formatted after
trn("%d move left", "%d moves left", n):format(n)  -- a counted phrase (ngettext)
trc("button", "Build")                             -- same text, different meaning (pgettext)
-- TRANSLATORS: %s is a building's name
tr("%s is ready")
```

- **Mark every word a player reads**: titles, buttons, notices, hints,
  dialogue, names, descriptions. Leave ids, keys, file names, colours, debug
  and test output alone.
- **Call the local alias with a literal.** xgettext reads `tr("…")`; it cannot see
  `l10n.tr("…")` (the check rejects it) or `tr(variable)`.
- **Keep keys apart from what is shown.** A value that is also a key (a
  building name a story beat refers to) is marked with `N_("Spring well")`,
  which returns it unchanged, and translated where it is drawn: `tr(name)`.
- **Mark whole sentences.** Never glue a sentence out of translated fragments;
  word order differs between languages. Use one template with `%s`/`%d`.
  Translators keep the directives in their order (the check enforces it).
- **Count with `trn`.** Russian has three forms and Japanese one. Give the
  source language's singular and plural; for a Russian source, the forms for 1 and for 5.
  The source's own catalogue (`ru.po` in Nile Archive) supplies the third.
- **Capitals with `l10n.upper`.** `string.upper` knows only ASCII.
- **`TRANSLATORS:` comments** on the line before a marked string reach the
  translator with it. Add them where a string is unclear by itself.

Strings resolve when the module that marks them loads, so data tables can
wrap their literals directly. The language is chosen before any game module runs.

## Choosing the language

When the engine's Lua loads, `l10n` matches the player's preferred languages
against the game's `data/common/l10n/languages.txt` (one tag per line, the
source language first):

- `app.languages()` gives the system's list. iOS and macOS read
  `NSLocale.preferredLanguages`, which honours the per-app language in iOS
  Settings. The web reads `navigator.languages`, Windows its UI languages,
  and Linux `LANGUAGE`/`LC_*`/`LANG`.
- `--lang TAG[,TAG…]` overrides it: `./build/relic-rush --lang ja`, or `?lang=de`
  on the web.
- Headless runs, captures, smoke runs and tests use the source language unless
  `--lang` is given, so their output never depends on the machine.
- Matching tries the tag, then the tag with subtags removed from the end
  (`de-AT` finds `de`), then another region of the same language (`pt-PT` finds
  `pt-BR`). Chinese matches by script: `zh-CN` finds `zh-Hans`, `zh-TW` never does.
- A new language takes effect at the next start, as iOS applies its per-app
  language.

The Xcode generator writes the same list into each app's `CFBundleLocalizations`,
so iOS offers the language setting and the App Store lists the languages.

## Catalogues

| Domain | Sources | Catalogues |
| --- | --- | --- |
| `engine` | `engine/lua/**` (English) | `engine/data/common/l10n/<tag>.po`, one per language any game offers |
| `<game>` | `games/<game>/lua/**` | `games/<game>/data/common/l10n/<tag>.po` |

A lookup tries the game's catalogue, then the engine's, then shows the msgid.
Untranslated and fuzzy entries show the source text.

```sh
python3 tools/l10n.py update                 # extract (xgettext) and merge (msgmerge) every domain
python3 tools/l10n.py update relic-rush      # one domain
python3 tools/l10n.py status                 # translated / total per catalogue
python3 tools/l10n.py strings relic-rush de  # the entries still to translate, as PO
python3 tools/l10n.py check                  # also part of make test-assets
```

`check` fails if a catalogue lags behind the code (new or stale entries), has
an untranslated or fuzzy entry, or has a plural count or header that differs from
the runtime's rule. It also fails when format directives differ from the msgid,
when `msgfmt --check` objects, or when a translated character is in no font the
game can draw. `tests/lua/localization.lua` covers the runtime: parsing, plural
rules, negotiation and upper case. It also loads every shipped catalogue.

**Changing source text** makes its old translations stale: `update` drops them
and the check asks for new ones. Translate in the PO files, then run
`update` once more to normalise them.

## Fonts and line breaks

A game's display fonts cover its source language. Every font chain ends in a global
fallback that `l10n` sets for the language. The chain comes from the engine's
`engine/data/common/fonts/`: subset Noto fonts (SIL Open Font License,
`OFL-Noto.txt`). Noto Sans Bold covers Latin, Greek and Cyrillic for
every language. Noto Sans CJK JP, KR and SC come first for Japanese, Korean
and Chinese, so Han characters take each language's own forms.

The fonts hold only the characters the catalogues use, plus ASCII and common
punctuation. After translating, refit them from the full Noto fonts
(github.com/notofonts/noto-cjk and github.com/notofonts/latin-greek-cyrillic):

```sh
python3 tools/l10n.py fonts --source ~/fonts/noto   # folder holding NotoSans-Bold.ttf, NotoSansCJK{jp,kr,sc}-Regular.otf
```

Text wraps Chinese and Japanese between any two characters, with the basic
kinsoku rules (no line starts with closing punctuation or a small kana, none
ends with an opening bracket). Korean wraps at its spaces. Story typing pauses
after full-width sentence punctuation.

## Checking a language in the game

```sh
./build/relic-rush --headless --mute --fresh --lang ja --size 480x900 --shot ja.png
build/test/all --suite=relic-rush "shot phone-board" -- --lang de
```

Look for clipped or shrunk text: German and Russian run about 30% longer than English.
`text_box` shrinks a line down to 60% before it overflows.
