# Twenty campaign buildings for Relic Rush and Christmas Market

> **Status:** proposal, 16 November 2026. Nothing here is implemented yet.
> The Relic Rush section was revised the same day to build on its new bonus gems.
> Prices are starting points for the campaign bot and `tools/tune_levels.py`,
> not tuned values.

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

> **Revised 16 November 2026.** Since this proposal was first written, Relic
> Rush has gained six of Rome's eight tools as matchable bonus gems with a
> scaling toolbar (Dynamite, Hammer, Shutter Gear, Shield, Lightning, Star).
> [Bonus pieces](../../games/relic-rush/docs/board-progression.md#bonus-pieces)
> The opening specials and perks described above do not apply to Relic Rush.
> Its ladder builds on those bonus gems instead. They remain the plan for
> Christmas Market.

Today four story restorations give two things each: the Workshop, Market,
Courtyard and Archive add a resource piece *and* a bonus gem. The Courtyard
also brings rings, scarabs, sandals and harps on a timer. Rome gives each
building one thing. So the ten new buildings take over those four bonuses and
four treasures, and add Rome's two missing tools, the Hourglass and the Plus.
That is exactly Rome I's set: twelve pieces and all eight tools.

★ marks a story restoration. Its price and story beat are unchanged; it keeps
its piece and gives up its second unlock. Every debut board stays where it is
today, so the fitted budgets still hold. All ten new buildings are shop
buildings with Blender renders today and move into the campaign.

| # | Build after | Building | From board | Adds | Price C / F / S |
| ---: | ---: | --- | ---: | --- | ---: |
| **I. The landing** |
| 1 | 1 | ★ Expedition camp | 2 | Dynamite gems | 0 / 3 / 8 |
| 2 | 4 | ★ Spring well | 5 | Water bucket, 3 Food | 100 / 0 / 0 |
| 3 | 7 | Trapper's cabin | 8 | Hammer gems *(from the Workshop)* | 40 / 10 / 12 |
| 4 | 7 | ★ Artisan workshop | 8 | Cut blocks, 5 Supplies | 70 / 20 / 24 |
| **II. The quay** |
| 5 | 9 | Water mill | 10 | Shutter Gear gems *(from the Market)* | 45 / 12 / 15 |
| 6 | 9 | ★ Jungle market | 10 | Ration jar, 4 Food | 85 / 24 / 30 |
| 7 | 11 | Clock tower | 12 | **Hourglass gems, new:** +5 moves | 80 / 30 / 25 |
| 8 | 13 | Stone amphitheatre | 14 | Shield gems *(from the Courtyard)* | 50 / 18 / 18 |
| **III. The terraces** |
| 9 | 13 | ★ Sunstone courtyard | 14 | Helmet, 6 Coins | 85 / 34 / 36 |
| 10 | 16 | ★ Explorer's lodge | 17 | Grain bundle, 5 Food | 130 / 35 / 0 |
| 11 | 17 | Trading post | 18 | Ring, 7 Coins *(from the Courtyard)* | 90 / 45 / 20 |
| 12 | 19 | Valley lighthouse | 20 | Lightning gems *(from the Archive)* | 75 / 40 / 20 |
| **IV. The wreck** |
| 13 | 19 | ★ Lost-world archive | 20 | Carved quartz, 7 Supplies | 145 / 85 / 40 |
| 14 | 20 | Beached schooner | 21 | Scarab, 8 Coins *(from the Courtyard)* | 120 / 30 / 70 |
| 15 | 22 | Cartographer's house | 23 | **Plus gems, new:** charge the other sockets | 140 / 50 / 40 |
| 16 | 23 | ★ Star observatory | 24 | Star gems | 155 / 0 / 70 |
| **V. The temple** |
| 17 | 24 | Great aviary | 25 | Winged sandal, 9 Coins *(from the Courtyard)* | 160 / 40 / 60 |
| 18 | 26 | ★ Jade fountain | 27 | Shrimp, 6 Food | 160 / 0 / 65 |
| 19 | 27 | Relic museum | 28 | Harp, 10 Coins *(from the Courtyard)* | 170 / 90 / 50 |
| 20 | 29 | ★ Temple of the sun | 30 | Emerald, 11 Coins | 185 / 110 / 75 |

Where a story restoration and the new building that took its bonus share a
clear (7, 9, 13 and 19), the new one comes first on the ladder. The story
building then requires it, so the bonus still debuts on the same board.
Board 10 needs this most: its story gear is also the Shutter Gear piece.

**Why each building gives what it does.**

- **Trapper's cabin, Hammer.** The trapper's tools. Rome's Forge.
- **Water mill, Shutter Gear.** A turning wheel and gears, which shuffle.
- **Clock tower, Hourglass.** Rome's Pantheon adds time to the amphora. Here a
  charged Hourglass adds 5 moves, which saves a nearly finished board.
- **Stone amphitheatre, Shield.** Rome's Colosseum.
- **Valley lighthouse, Lightning.** A beam striking the board.
- **Cartographer's house, Plus.** Rome's Tabularium, a record office. A charged
  Plus fills every other socket by half its threshold.
- **Trading post, Beached schooner, Great aviary, Relic museum.** The Coins
  slot's climb: trade goods, a wreck's cargo, winged sandals, a museum's harp.
  Rome's Arch, Ship, Statue and Temple of Saturn do the same.

**What new art this needs.** Two bonus gems, the Hourglass and the Plus, each
with its toolbar button states, made through the existing bonus-piece pipeline
(`art/bonus-pieces/`). Every building and every other piece exists.

**Eight buttons on a phone.** The bonus toolbar shrinks its buttons to fit the
unlocked sockets. With all eight at 390 points wide, each is about 40 points,
under the usual 44-point touch target. Check this at 390×844 before
committing to eight. If it is too small, the fallback is to show only charged
sockets and the one this board charges.

## Christmas Market: the 20 stalls

Christmas Market's first eight stalls already follow Rome I's first eight
purchases. The rink and the tree add nothing today. This gives them bonuses
and adds ten stalls. The stalls fill Rome I's remaining twelve roles: the
Rostra's bomb, the Pantheon's hourglass, the Tabularium's plus, three Shield,
Star and Mixer bonuses, and the five Gold treasures and one Food piece of
epochs III–V.

Eight of the ten new stalls are existing cottages and decorations with
Blender renders. Two need new models.

| # | Build after | Stall | From wish | Adds | Kind | Price G / S / F |
| ---: | ---: | --- | ---: | --- | --- | ---: |
| **I. First lights** |
| 1 | 1 | ★ Welcome arch | 2 | Firewood, 5 Supplies | Piece | 50 / 0 / 0 |
| 2 | 2 | Reindeer stable | 3 | One shooting star on every opening board | Special | 60 / 20 / 0 |
| 3 | 4 | ★ Lumber workshop | 5 | Toy hammer · Hammer | Tool | 100 / 100 / 0 |
| 4 | 5 | Gingerbread house | 6 | +3 moves on every wish | Perk | 150 / 120 / 0 |
| **II. The bakery lane** |
| 5 | 7 | ★ Gingerbread bakery | 8 | Packing blocks, 7 Supplies | Piece | 300 / 200 / 0 |
| 6 | 9 | ★ Hot cocoa kiosk | 10 | Cocoa, 4 Food | Piece | 400 / 500 / 0 |
| 7 | 11 | Santa's workshop | 12 | Christmas cracker · Firecracker | Tool | 250 / 250 / 150 |
| 8 | 13 | ★ Toymaker's workshop | 14 | Milk, 3 Food | Piece | 300 / 300 / 200 |
| **III. Gifts and letters** |
| 9 | 14 | North Pole post office | 15 | Every tool starts each wish half charged | Perk | 350 / 300 / 300 |
| 10 | 16 | ★ Gift wrapping pavilion | 17 | Winter apple, 6 Food | Piece | 500 / 400 / 400 |
| 11 | 17 | Log cabin | 18 | Roast chestnuts, 7 Food | Piece | 450 / 400 / 450 |
| 12 | 19 | ★ Candlelight shop | 20 | Lantern star · Lightning | Tool | 500 / 600 / 500 |
| **IV. Bells and clocks** |
| 13 | 20 | Snowy chapel | 21 | Silver bell, 6 Gold (replaces the silver coin) | Piece | 550 / 550 / 600 |
| 14 | 21 | Clockmaker's shop *(new model)* | 22 | Pocket watch, 7 Gold (replaces the gold coin) | Piece | 600 / 600 / 600 |
| 15 | 23 | ★ Reindeer carousel | 24 | Gingerbread, 5 Food | Piece | 700 / 700 / 600 |
| 16 | 24 | Santa's sleigh | 25 | One paper plane on every opening board | Special | 650 / 650 / 650 |
| **V. Christmas Eve** |
| 17 | 25 | Igloo | 26 | Snow globe, 8 Gold (replaces the bell) | Piece | 700 / 700 / 750 |
| 18 | 26 | ★ Winter skating rink | 27 | One rainbow ball on every opening board | Special | 750 / 700 / 700 |
| 19 | 27 | Carol bandstand *(new model)* | 28 | Music box, 9 Gold (replaces the watch) | Piece | 800 / 750 / 800 |
| 20 | 29 | ★ Christmas tree | 30 | Star topper, 10 Gold (replaces the globe) | Piece | 900 / 850 / 900 |

Twelve pieces, eight bonuses: three tools, three opening specials and two
perks, Rome I's exact split. Christmas prices are Gold / Supplies / Food,
the order the resource prototype uses. The rink and tree prices above are
new: their current prices (160 / 42 / 20 and 175 / 50 / 25) sit far below
their neighbours and would make them free in a 20-stall economy.

**Why each stall gives what it does.**

- **Reindeer stable, shooting star.** A reindeer's streak across the sky; it
  is the hex rocket and teaches specials on wish 3.
- **Gingerbread house, +3 moves.** A snack that keeps everyone going. It
  arrives as the first prices with Supplies make players earn deliberately.
- **Santa's workshop, Firecracker.** Christmas crackers. The Firecracker icon
  and all five button states are already in the tool atlas and unused. It
  charges from its own matched cracker pieces like the Hammer.
- **North Pole post office, half-charged tools.** This is the Plus: parcels of
  tools arrive before the wish starts. A meter starts at 100 of 200.
- **Log cabin, roast chestnuts.** By the fire. At 7 Food it tops the Food
  ladder, as Rome's Port fish does.
- **Chapel, clockmaker, igloo, bandstand, tree.** The five Gold treasures:
  bells, watches, snow globes, music boxes and the tree's star topper, each
  replacing the Gold piece below it, as Rome's ring through brooch do.
- **Santa's sleigh, paper plane.** The sleigh flies to the pane it needs.
- **Skating rink, rainbow ball.** Skaters swirl the colours. This is the Mixer
  slot.

**The Gold ladder needs two slots.** Christmas Market pays Gold from both
silver (3) and gold (5) coins. The bell and globe climb the silver slot. The
watch and music box climb the gold slot. The star topper replaces whichever
of those is lower.

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
