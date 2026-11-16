# Cradle of Rome reference for Relic Rush

Cradle of Rome gives every board two jobs. Clearing the plaques wins the level.
Matching resource pieces pays for the city, and some purchases change the
pieces or tools on later boards. Relic Rush already has both jobs and one
city-to-board example in the Spring Well. The strongest next use of this
reference is to make that connection more legible and repeat it at another
restoration, with a board that gives the changed piece a reason to matter.

| Start here | What it covers |
| --- | --- |
| [Complete game-design reference](GAME_DESIGN.md) | Core loop, economy, all 20 Rome I buildings, all eight tool-building links, citizen tasks, version caveats and Christmas Market/Relic Rush implications. |
| [Gem correspondence sheet](gem-correspondence.html) | Side-by-side tile art, original names, Relic Rush counterparts and gaps for both editions. Open in a browser. |
| [Board design](BOARD_DESIGN.md) | All 115 numbered layouts, feature counts and worked examples of plaque placement, locks and supply. |
| [Resources and city](ECONOMY_AND_CITY.md) | Piece yields, the finish bonus, all 20 purchases across five epochs, and examples of citizen rewards. |
| [Applying it to Relic Rush](ADAPTATION.md) | What the game already does, which changes to prototype first, and how to check them. |
| [Tropicats reference](../tropicats-reference/README.md) | Companion research for quests, story pacing and board objectives. |

## Build and scope

The source is Awem's Android **Cradle of Rome Beta 0.9.0** (`com.awem.cor.beta`).
Its main `game_cfg.xml` enables soft release and sets `soft_release_levels="40"`.
The shared `game_settings.xml` specifies Adventure 1–100, Extras 101–115,
Tourney 1–115 and Blitz 1–100. The archive ships all 115 numbered files and
`level_empty.xml`. Treat 1–40 as the beta's configured range, 1–100 as the wider
Adventure data, and 101–115 as separate Extras data. A file's presence does
not establish that it was accessible in this APK. The full desktop release
is a cross-check for the player-facing loop. [GameHouse walkthrough](https://www.gamehouse.com/blog/2016/04/cradle-of-rome-walkthrough/)

This is a static audit. XML establishes authored layout, thresholds and
prices. English strings explain the intended player-facing rules. Where the
desktop guide, event predicates or internal artwork names differ, the notes
identify the source explicitly. The APK was not run. Runtime spawn weights,
fill routes, shop state transitions, precise payout and measured difficulty
remain unverified.

## Source inventory

Paths are relative to the local, ignored
`reference/cradle-of-rome/resources/` directory. The original APK, its
hashes and download URL are recorded in
[SOURCE.txt](../../reference/cradle-of-rome/SOURCE.txt).

| What to inspect | File and lookup |
| --- | --- |
| Beta cap and mode ranges | `settings/game_cfg.xml` and `settings/scenes/game/game_settings.xml` → `Common`. |
| Layout and initial layers | `settings/scenes/game/levels/level_N.xml` → `Settings`, `Field/Cell`. Join `Tile` and `Ball` at each `x,y`. |
| Player-facing rules and names | `settings/locale.xml` → `Puzzle_cell`, `Double_puzzle_cell`, `Lock`, `Timer`, `Pieces_*`, `People_bonus_*`, `Episode_title_*`. |
| Per-piece yield and tool charge | `settings/scenes/game/game_balls.xml` → `Ball` / `BonusBall`, joined by numeric `type` to `field_balls.xml` in the same folder. |
| Hint for the last puzzle tiles | `settings/scenes/game/game_settings.xml` → `PuzzleLeftGlow` sets a three-tile threshold, a four-second start delay and a nine-second period. `particles/cell_hint_blue.ptc` and `particles/cell_hint_green.ptc` name a `perimeter` emitter and use `Star_16.png` and `Star_02_16.png`. |
| Time, scoring and bonuses | `settings/scenes/game/game_settings.xml` → `Adventure`; `game.xml` builds the results view and `bonuses.xml` configures tool effects. |
| Prices, plan access and building payoff | `settings/scenes/shop/epochs.xml` → `Epoch/Construction`. Read `Price`, `PlanAccess` and `Ball type` separately. `shop.xml` describes shop, plan and epoch-completion UI. |
| Location, name and citizen | Join construction `id` to `settings/scenes/city/city_view.xml` for position and `enable_user_events`, to `city_info_dialog.xml` page `<id>_0` for the localized title, and to `settings/user_events.xml` for predicates and effects. |

## Browse the artwork

With Pillow available, run `python3 tools/cradle-of-rome-reference/export_art.py`
after unpacking the APK and resource pack. Open `board-pieces.png` and
`board-backgrounds.png` in the resulting `reference/cradle-of-rome/visuals/`
directory for an overview.

| Local path under `visuals/` | Contents |
| --- | --- |
| `sprites/settings/scenes/game/game_graphics/` | Individual chips (`gmbn_*`), bonus pieces (`bns_*_fld`), locks, plaques, effects and all 21 board backdrops (`gm_back_*`, cropped to 1024×768 as specified by the game). |
| `sprites/` | Crops from all graphics XML tables, including the city, shop, menus and Japanese overrides. Animations have numbered frame PNGs. The crops retain source alpha and atlas orientation. |
| `textures/` | Full-size PNG decodes of all 24 ETC1 textures, including the padding present in the source textures. Original PNG and JPEG atlases are in `resources/textures/`. |

The APK's separate audio and splash files are under `reference/cradle-of-rome/apk/assets/`.

## Cradle of Rome 2 artwork

The sequel reference comes from the [GameTop Windows release](https://www.gametop.com/download-free-games/cradle-of-rome-2/).
The local `reference/cradle-of-rome-2/resources/` directory contains all 1,426
files from its resource pack. Browse `visuals/board-pieces.png` and
`visuals/board-backgrounds.png` in the same reference folder. The individual
PNGs are under `visuals/sprites/settings/scenes/game/game_graphics/`. The 21 board
backgrounds are also available as the original JPEGs in
`resources/textures/scenes/game/backs/`.

### Last puzzle tile glow

`settings/scenes/game/game_settings.xml` names `LastPuzzlesGlow` in the Windows
release. Its threshold is three puzzle tiles, with a four-second initial delay
and a nine-second repeat period. `particles/cell_hint_blue.ptc` and
`particles/cell_hint_green.ptc` define the color variants and contain identical
`Star_02_16.png` and `Star_16.png` images. The original 16×16 PNGs sit at byte
offsets 16873 and 20199. Extract them with
`python3 tools/cradle-of-rome-reference/export_cell_hint_particles.py`, then
pack them with `python3 tools/match3_atlas.py`.

The supplied screen recording shows an electric-blue wash under the piece,
with a soft cyan wake moving clockwise along the bevel. The glow lasts about
3.6 seconds and the bright spot takes about 2.65 seconds to make a lap. The
hex adaptation follows its six bevel edges and starts with the shared move hint.

### Other artwork

The Well unlocks the water bucket (`gmbn_5.png`), a 44×44 crop at `(0, 46)`
in `textures/scenes/game/balls/gmf_balls_2.png`. Each matched bucket gives 3
Food. This PC release also has a separate meat tile (`gmbn_7`).
[Awem's resource guide](https://support.awem.com/hc/en-gb/articles/200686242-Building-the-City)

Run from the repository root with `innoextract` 1.9 or later and Pillow available.

```sh
curl -fL https://cdn7.gametop.com/games/Cradle-of-Rome-2.exe -o /tmp/Cradle-of-Rome-2.exe
printf '%s  %s\n' 6413521557996b116fd83605944225931164f7748039dd925d0a2e8f1948d767 /tmp/Cradle-of-Rome-2.exe | shasum -a 256 -c
innoextract --extract --lowercase --include app/resources.pak --include app/splashes --output-dir reference/cradle-of-rome-2 /tmp/Cradle-of-Rome-2.exe
python3 tools/cradle-of-rome-reference/extract_pak.py reference/cradle-of-rome-2/app/resources.pak reference/cradle-of-rome-2/resources
python3 tools/cradle-of-rome-reference/export_art.py --root reference/cradle-of-rome-2/resources --board-only
```

The extracted pack's SHA-256 is
`9ec46272ab4d9b4a2f40cd09781f7910775dbda72f9fa6830cdff81d8809f9d5`.

## Cradle of Rome 2 economy data

The [Windows economy export](rome-2-economy.json) records the 20 priced
constructions in order, their blueprint requirements, the tile or tool each
construction unlocks, the exact credits by tile, and Adventure multipliers.
The source files are `settings/scenes/shop/epochs.xml` and
`settings/scenes/game/{game_balls,field_balls,game_settings}.xml`.

| First epoch | Gold | Supplies | Food | Unlock |
| --- | ---: | ---: | ---: | --- |
| Well | 500 | 0 | 0 | Water bucket, 3 Food |
| Hunter's Hut | 1,000 | 0 | 1,500 | Hammer tile, 3 Hammer charge |
| Sawmill | 3,000 | 0 | 2,500 | Lumber, 5 Supplies |
| Village | 2,000 | 3,000 | 2,000 | Bomb tile, 3 Bomb charge |

The opening pool has leaves and flowers for score, and coins worth 3 or 5 Gold.
The Well is the first Food source. Food pays for the Hunter's Hut and Sawmill,
then lumber supplies the Village. Relic Rush uses this purchase-to-tile loop
with its own three wallets, expedition lengths and story milestones.

```sh
python3 tools/cradle-of-rome-reference/export_economy.py reference/cradle-of-rome-2/resources > docs/cradle-of-rome-reference/rome-2-economy.json
```

## Reproduce the counts

Run these commands from the repository root with the downloaded APK and fresh output paths.

```sh
unzip -q reference/cradle-of-rome/cradle-of-rome-beta-0.9.0.apk -d reference/cradle-of-rome/apk
python3 tools/cradle-of-rome-reference/extract_pak.py reference/cradle-of-rome/apk/assets/resources.pak reference/cradle-of-rome/resources
python3 tools/cradle-of-rome-reference/analyze.py > /tmp/cradle-of-rome.json
python3 tools/cradle-of-rome-reference/analyze.py --level 35
```

The [analyzer](../../tools/cradle-of-rome-reference/analyze.py) emits per-level
metrics, feature lists by mode, piece credits and joined city tables as JSON.
The level option prints terrain and piece layers side by side. It runs with
Python's standard library. The notes and analyzer work from the repository,
with the decoded assets kept as local research inputs.
