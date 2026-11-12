# Homescapes: initial design reference

Inspected 2026-11-12: the App Store package matching the connected iPhone's
**Homescapes 9.2.601, build 10100292**, bundle ID
`com.playrix.gardenscapes-sweethome`. This is an initial source inventory and
player-guide study, not an extracted campaign or a playthrough. Spoilers are
limited to the premise. Player guides can change independently of this build.

See the [match-3 resource export](ART.md#bundled-resource-export),
[mechanics comparison](MECHANICS.md), [complete board ID inventory](BOARD_IDS.md),
and [opening story study](STORY.md).

## Source and reproducibility

The ignored local source is `reference/Homescapes.app/`. It was downloaded via
`ipatool` from the signed-in App Store account, not copied from the phone. The
IPA's `Info.plist` identity, version and build matched the phone's installed app.
The temporary IPA was removed after extraction. `base.zip` has SHA-256
`9bfdcbd368d6cfbc9def2ca1380f8c113d144b9b3569a38ad7849d3278cc701b`
. The app bundle occupies approximately 313 MB. Original
third-party assets remain ignored, as with the other reference apps.

Inspect without unpacking another copy:

```sh
unzip -l reference/Homescapes.app/base.zip
unzip -l reference/Homescapes.app/packs/Match3_Settings.zip
shasum -a 256 reference/Homescapes.app/base.zip
```

`base.zip` has 6,643 files and 934 directory entries; `packs/` contains 29 ZIP
archives. Paths and counts describe this package, not the entire live game.
For example, `base_mm/cluster1/CH_Hall/Quest.xml.au` and 47 other entries ending
in `/Quest.xml.au` identify possible quest sources, but do not establish chapter
counts, task sequences or dialogue. The quest files begin with a `BLK` container;
all 48 contain Zstandard frames and decompress into structured
binary data with readable identifiers. Other relevant files, including
`Match3LevelSelector.xml`, `Tutorials.xml`, and `Storyline.lua`, begin with `PLXE`
rather than readable XML or Lua. Their contents have not been decoded. Neither a
filename nor a string alone proves runtime behavior. The app may download other
content; no remote content or personal app data was acquired.

| Research target | Bundled starting point | Status |
| --- | --- | --- |
| Quest and day structure | `base_mm/cluster*/.../Quest.xml.au` | [48 structured area outlines](STORY.md#structured-outline); titles and dialogue remain encoded |
| Level selection and tuning | `base_mm/Match3/Match3LevelSelector.xml`, `Match3SpecialBalance/` | 6,184 bundled level XML files decoded; selection and campaign assignments remain encoded |
| Tutorials and localization | `base_mm/Tutorials.xml`, `Assets/Common/texts/` | Encoded; no transcript recovered |
| Story execution | `base_mm/fs_archives/screenplays.zstd`, `Storyline.lua` | 1,329 compiled scripts decoded; localization and scene order unknown |
| Content delivery | `base_mm/Assets/CDS/CdsPack.xml` | Encoded; remote inventory not recovered |
| Match-3 resources | `base_mm/` and `packs/*.zip` | [620 exported files](ART.md#bundled-resource-export); 98 readable images; board textures and regions still packed |

## Progression and economy

Playrix describes Austin renovating the mansion through match-3 levels, with
renovation choices and a family story. [App Store description](https://apps.apple.com/us/app/homescapes/id1195621598)
Its guide says sequential areas take 3–6 in-game days each and tasks cost 1–10
stars. Players track tasks on a tablet. These are published general rules, not
measurements of the installed build's opening or every task. [Area guide](https://playrix.helpshift.com/hc/en/14-homescapes/faq/1101-unlocking-new-areas-in-the-mansion/)

A puzzle win earns stars for restoration and coins for discretionary resources;
the guide says completed levels cannot be replayed. [Level guide](https://playrix.helpshift.com/hc/en/14-homescapes/faq/1087-how-do-i-play-match-3-levels/)
Coins can buy boosters, extra moves or lives, and can also come from tasks and
completed days. [Coin guide](https://playrix.helpshift.com/hc/en/14-homescapes/faq/1070-in-game-coins/)
This separates story entitlement from a flexible spending currency. Unlike the
Tropicats quest-to-specific-tier mapping documented in our reference, these
sources do not show that a particular Homescapes renovation requires a particular
numbered level. Do not infer that mapping without the decoded task data.

For our games, the useful pattern is a visible short-term task feeding a tangible
world change, grouped into a larger area and day. Price and ordering should be
authored for our own campaign; the guide's 1–10 range is not evidence of an
appropriate balance for a short game. Keep earned story progress separate from
optional help and rewards, and give each task a discernible result.

## Match-3 decisions

Playrix's [power-up guide](https://playrix.helpshift.com/hc/en/14-homescapes/faq/16313-power-ups-and-how-to-use-them/)
describes four in-board power-ups: four in a line creates a row/column Rocket;
L- or T-shaped five or six creates a Bomb; a square of four creates a Paper
Plane; five in a line creates a Rainbow Ball. Planes favor locked pieces or
goals but the guide calls their target random. A Rainbow Ball removes pieces of
a chosen adjacent type. The [combination guide](https://playrix.helpshift.com/hc/en/14-homescapes/faq/16363-what-power-up-combinations-are-available-in-the-game/)
describes, among other combinations, two Planes producing three, and a Ball
combined with a Rocket, Bomb or Plane converting pieces of the most common type
into that power-up. These are current published descriptions; ordering, edge
cases and this specific build are unverified.

The [booster guide](https://playrix.helpshift.com/hc/en/14-homescapes/faq/16364-what-are-boosters-and-how-to-use-them/)
distinguishes pre-level loadout choices from situational tools used during a
board. That creates two different decisions: committing before seeing play and
rescuing a specific position. For our board design, the square-to-plane match is
a useful option for irregular shapes, while goal-seeking must remain explicit
about targeting and randomness. Combination effects need their own rules and
tests; an icon match alone does not establish equivalent behavior.

## Remaining work

Extend the partially parsed `BLK` quest structure, decode dialogue localization in the `PLXE` resources
and content-delivery inventory, then cross-check decoded opening tasks, scene
text, level data and actual gameplay. Only then can a chapter-by-chapter story
handoff or level atlas comparable to Tropicats be claimed. No level counts,
quest costs, exact dialogue or runtime state mapping are asserted here.
