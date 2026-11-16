# Twenty campaign buildings for Relic Rush and Christmas Market

> Both twenty-step ladders are implemented and priced from measured campaign
> runs. Relic Rush uses [six matchable bonus gems](../../games/relic-rush/docs/board-progression.md#bonus-pieces)
> with dedicated artwork.

Both games have 30 boards and 10 story buildings today. Cradle of Rome has
20 purchases in five epochs of four, and every purchase adds exactly one
regular piece or one tool family. Twelve are pieces and eight are tools.
[All 20 Rome I purchases](GAME_DESIGN.md#5-every-building-in-the-original-20-purchase-ladder)

This proposal gives each game the same 12 + 8 split. It keeps the 10 existing
story buildings, their story beats and their current unlocks, and adds 10
buildings between them. Rome's skilled players finish all 20 purchases in
about 30 levels, so 20 buildings across 30 boards matches the source's pace
for a good player.
[Rome pacing](GAME_DESIGN.md#what-progression-is--and-is-not)

## The rules both ladders follow

These come straight from the Rome ladder.

1. **One purchase, one change.** Every building adds one piece or one bonus,
   from the next board on. No building is cosmetic.
2. **The new piece pays what the next price needs.** Rome's Sawmill costs Gold
   and adds Lumber, and the Forge after it needs Supplies. Each new building
   here sits after a piece that pays its scarcest currency.
3. **Pieces climb a slot's ladder, they don't add slots.** The hex board fits
   six kinds at most. A new piece replaces the one below it in the same slot,
   as the Well, Workshop and Market already do in Relic Rush.
4. **Gold treasures come late.** Rome's ring, pearl, diamond, goblet and brooch
   are all in the last three epochs. Gold is in surplus early in both of our
   games (Christmas Market holds 1,500 Gold by wish 4 in the measured run), so
   early new buildings add bonuses and Food or Supplies, not Gold.
5. **Eight tools don't fit on a phone.** The research says not to put Rome's
   whole tool bar on an iPhone, and the engine draws three tool buttons. The
   eight Rome tools therefore become three kinds of bonus, described next.

## What a bonus looks like

Rome's eight tools sort into what each one does for the player. On a
move-limited hex board they become three kinds.

| Kind | Rome tools it replaces | What the player gets | New art needed |
| --- | --- | --- | --- |
| **Tool** (one of the three buttons) | Hammer, Bomb, Lightning, Star | A tool on the bar, charged the game's existing way | None. Both games already have three tool icons in every state. |
| **Opening special** | Shield (row), Star (one icon), Mixer | Every board starts with one rocket, rainbow ball or paper plane already placed | None. Both atlases already have `ray-*`, `prism` and `plane`. |
| **Standing perk** | Hourglass, Plus | +3 moves, extra tool uses or tool charge, a bigger move bonus | A small guide icon each |

**Why opening specials.** Rome's Shield clears a row and its Star clears one
icon. A hex rocket clears a line and a rainbow ball clears a colour, so they
are the same effects with no new button to find. The player taps them on the
board like any other special. Christmas Market makes no specials from matches,
so in that game these three buildings are the only source of specials, as
building-granted bonuses are in Rome.

**Why +3 moves.** The Hourglass adds time to the amphora. Our games count
moves, so its equivalent is moves. `tools/tune_levels.py` must fit budgets
with the bonus included, or the campaign gets easier past that building.

**What Mixer becomes.** Both games already reshuffle a board with no moves
left, so a shuffle tool would rarely matter. The paper plane takes its slot.

## Relic Rush: the 20 restorations

Relic Rush has twelve resource upgrades and six matchable bonus gems.
Restoring the Water mill and Clock tower advances the building ladder.

★ marks the ten story restorations. The other buildings open after their
listed clear and come before the next story restoration.

| # | Build after | Building | From board | Adds | Price C / F / S |
| ---: | ---: | --- | ---: | --- | ---: |
| **I. The landing** |
| 1 | 1 | ★ Expedition camp | 2 | Dynamite gems | 0 / 10 / 20 |
| 2 | 4 | ★ Spring well | 5 | Water bucket, 3 Food | 130 / 0 / 0 |
| 3 | 7 | Trapper's cabin | 8 | Hammer gems *(from the Workshop)* | 80 / 55 / 75 |
| 4 | 7 | ★ Artisan workshop | 8 | Cut blocks, 5 Supplies | 145 / 105 / 150 |
| **II. The quay** |
| 5 | 9 | Water mill | — | Opens the Jungle market restoration | 75 / 50 / 75 |
| 6 | 9 | ★ Jungle market | 10 | Ration jar, 4 Food | 145 / 95 / 150 |
| 7 | 11 | Clock tower | — | Opens the Sunstone courtyard restoration | 180 / 140 / 200 |
| 8 | 13 | Stone amphitheatre | 14 | Shield gems *(from the Courtyard)* | 60 / 80 / 80 |
| **III. The terraces** |
| 9 | 13 | ★ Sunstone courtyard | 14 | Helmet, 6 Coins | 90 / 150 / 160 |
| 10 | 16 | ★ Explorer's lodge | 17 | Grain bundle, 5 Food | 300 / 340 / 0 |
| 11 | 17 | Trading post | 18 | Ring, 7 Coins *(from the Courtyard)* | 250 / 290 / 360 |
| 12 | 19 | Valley lighthouse | 20 | Lightning gems *(from the Archive)* | 100 / 110 / 120 |
| **IV. The wreck** |
| 13 | 19 | ★ Lost-world archive | 20 | Carved quartz, 7 Supplies | 195 / 230 / 240 |
| 14 | 20 | Beached schooner | 21 | Scarab, 8 Coins *(from the Courtyard)* | 190 / 190 / 190 |
| 15 | 22 | Cartographer's house | 23 | Plus gems charge the other sockets | 285 / 250 / 270 |
| 16 | 23 | ★ Star observatory | 24 | Star gems | 205 / 0 / 200 |
| **V. The temple** |
| 17 | 24 | Great aviary | 25 | Winged sandal, 9 Coins *(from the Courtyard)* | 200 / 240 / 180 |
| 18 | 26 | ★ Jade fountain | 27 | Shrimp, 6 Food | 280 / 0 / 300 |
| 19 | 27 | Relic museum | 28 | Harp, 10 Coins *(from the Courtyard)* | 220 / 420 / 220 |
| 20 | 29 | ★ Temple of the sun | 30 | Emerald, 11 Coins | 330 / 430 / 330 |

When two restorations unlock on the same clear (7, 9, 13 and 19), the
story restoration comes second. Expedition 10 introduces ration jars
alongside the Shutter Gear quest piece.

**Why each building gives what it does.**

- **Trapper's cabin, Hammer.** The trapper's tools. Rome's Forge.
- **Stone amphitheatre, Shield.** Rome's Colosseum.
- **Valley lighthouse, Lightning.** A beam striking the board.
- **Cartographer's house, Plus.** Rome's Tabularium, a record office. A charged
  Plus fills every other socket by half its threshold.
- **Trading post, Beached schooner, Great aviary, Relic museum.** The Coins
  slot's climb: trade goods, a wreck's cargo, winged sandals, a museum's harp.
  Rome's Arch, Ship, Statue and Temple of Saturn do the same.

The [bonus atlas](../../games/relic-rush/data/bonus-gems.png)
contains the gems and the five states of each button. All six sockets stay
visible in one row.

## Christmas Market: the 20 stalls

> **Revised 16 November 2026** so that no new art is needed: the first draft
> asked for six new pieces, a cracker charge piece and two new buildings.
> As built, the ten new stalls are existing Blender renders and the four new
> pieces reuse the game's earlier painted festive pieces. The Firecracker
> tool, which had no charge piece, became an opening firework bomb. Two of
> Rome's Gold treasures became citizen-style income, which Rome pays per level.

Christmas Market's first eight stalls already followed Rome I's first eight
purchases; the rink and tree added nothing. Now every stall adds one thing.
Prices are Gold / Food / Supplies and were set from the extended campaign run,
which places all twenty with one replay for income.

| # | Build after | Stall | From wish | Adds | Price G / F / S |
| ---: | ---: | --- | ---: | --- | ---: |
| 1 | 1 | ★ Welcome arch | 2 | Firewood, 5 Supplies | 50 / 0 / 0 |
| 2 | 2 | Reindeer stable | 3 | Opening shooting star (Rome's Shield) | 60 / 0 / 20 |
| 3 | 4 | ★ Lumber workshop | 5 | Hammer | 100 / 0 / 100 |
| 4 | 5 | Gingerbread house | 6 | +3 moves (Rome's Hourglass) | 150 / 0 / 80 |
| 5 | 7 | ★ Gingerbread bakery | 8 | Packing blocks, 7 Supplies | 300 / 0 / 200 |
| 6 | 9 | ★ Hot cocoa kiosk | 10 | Cocoa, 4 Food | 400 / 0 / 500 |
| 7 | 11 | Santa's workshop | 12 | Opening firework bomb (Rome's Bomb) | 200 / 150 / 100 |
| 8 | 13 | ★ Toymaker's workshop | 14 | Milk, 3 Food | 300 / 200 / 300 |
| 9 | 14 | North Pole post office | 15 | Tools charge twice as fast (Rome's Plus) | 250 / 250 / 100 |
| 10 | 16 | ★ Gift wrapping pavilion | 17 | Winter apple, 6 Food | 500 / 400 / 400 |
| 11 | 17 | Log cabin | 18 | Candy cane, 7 Food (Rome's fish) | 250 / 350 / 100 |
| 12 | 19 | ★ Candlelight shop | 20 | Lightning | 500 / 500 / 600 |
| 13 | 20 | Snowy chapel | 21 | Golden bell, 6 Gold (Rome's ring) | 120 / 250 / 40 |
| 14 | 21 | Igloo | 22 | Snowflake bauble, 7 Gold (Rome's pearl) | 130 / 300 / 40 |
| 15 | 23 | ★ Reindeer carousel | 24 | Gingerbread, 5 Food | 700 / 600 / 700 |
| 16 | 24 | Santa's sleigh | 25 | Opening paper plane (Rome's Mixer slot) | 150 / 350 / 50 |
| 17 | 25 | Giant bauble | 26 | Plum bauble, 8 Gold (Rome's diamond) | 160 / 400 / 50 |
| 18 | 26 | ★ Winter skating rink | 27 | +25 Gold every win (Rome's citizens) | 180 / 450 / 60 |
| 19 | 27 | Pile of presents | 28 | +20 Supplies every win (Rome's citizens) | 200 / 500 / 60 |
| 20 | 29 | ★ Christmas tree | 30 | Opening rainbow ball (Rome's Star) | 250 / 600 / 80 |

## When a building blocks the next board

Rome lets the player continue without the next purchase. Both games today
hold the next new board until the due story building is placed. With 20
buildings the hard gate would stop play every one or two boards.

**Recommendation: a soft gate.** The ladder is strictly in order: each
building appears in the shop once the one before it is placed. Only the ten
★ story buildings hold the next new board, and a story building can't be
bought until every building before it on the ladder is placed. A player
short on Supplies after board 5 can play on to board 7 before the Workshop
makes them build the Lighthouse. That gives Rome's slack without letting the
ladder fall behind the story.

The alternative is to gate on all 20, which is simpler to explain and test
but doubles the construction stops and the replays for shortfalls.

## What has to be built

### Engine

Items 1 and 2 are for Christmas Market; Relic Rush's Hourglass and Plus
are bonus effects in its bonus-gem system instead.

1. **Opening specials.** A loadout field, for example
   `opening_specials={"ray"}`, places that special on the opening board, on a
   seeded open cell that is neither chained nor under a plaque. It needs
   C/Lua tests for placement, refill and the hint, and a reset under
   `ENGINE_TEST`.
2. **Move bonus.** A loadout `extra_moves`, applied once at board start,
   shown in the HUD count and covered by the existing restart path.
3. **Starting charge.** Christmas Market's `tool_meter` can already start
   above zero. Relic Rush's per-board tool uses are game data.

### Games

1. **One unlock table per game.** Each row names its building key and either
   a slot and tier, a bonus, a special or a perk. Relic Rush's `E.unlocks`
   matches unlock *i* to city type *i − 1*; the promoted buildings have
   other type IDs, so rows must name their building key. Christmas Market's
   `ordinary` table is indexed by the number of stalls built and must become
   per-slot tiers. The catalogue row order stays as it is: it is save data.
2. **Save migration.** For a save already past a new building's board: count
   the building as placed if the player already bought it as a decoration.
   Otherwise offer it in the shop at its price, but don't let it block the
   next story building. Bump `CAMPAIGN_VERSION`.
3. **Prices and budgets.** Run the campaign bot over 30 seeded runs per
   game and record wallet before each purchase, shortfall and replays, as
   [the adaptation](ADAPTATION.md#how-to-judge-the-first-prototype) says.
   In Christmas Market, refit move budgets with the +3 moves included.
4. **Story.** Each new building needs an arrival line and the card text
   stating its unlock. They are not new scenes. Christmas Market's lines stay
   joyful. Both get a cold read per [STORY_WRITING.md](../STORY_WRITING.md).
5. **UI.** The building card says what it adds. The first board after a
   bonus building points at the new special or perk. The guide lists all
   twelve pieces and eight bonuses.

### Art

| Game | New art | How |
| --- | --- | --- |
| Relic Rush | Hourglass and Plus bonus gems with their toolbar states. All 10 buildings and 12 pieces exist. | The existing bonus-piece pipeline. Re-check the promoted buildings' footprints with `--footprints`. |
| Christmas Market | 6 pieces: silver bell, pocket watch, snow globe, music box, star topper, roast chestnuts. Plus the Christmas cracker, which charges the Firecracker. | One ImageGen atlas for all seven pieces together, in the existing market-goods style |
| Christmas Market | 2 buildings: Clockmaker's shop and Carol bandstand | New catalogue rows appended, then Blender, `make buildings`, and the paint pass in [BUILDING_STYLE.md](../BUILDING_STYLE.md) |
| Christmas Market | Guide icons for +3 moves and starting charge | Authored together in one atlas |

Each addition goes in the game's asset catalogue in the same PR. Gaps that
remain get a GitHub issue.

## Suggested order of work

1. Relic Rush first: the ladder data, soft gate and migration, moving the
   four doubled bonuses and four treasures to their new buildings. Then the
   Hourglass and Plus gems.
2. Engine: opening specials and extra moves, with tests, for Christmas Market.
3. Christmas Market's data and the three bonuses that need no new art
   (Firecracker, opening specials, perks), with placeholder pieces tracked
   in an issue.
4. Christmas Market's seven pieces and two buildings, then the final retune.

Citizen challenges, Rome's second payoff for a building, stay out of scope.
[Citizen upgrades](GAME_DESIGN.md#7-citizen-challenges-buildings-can-have-a-second-payoff)
