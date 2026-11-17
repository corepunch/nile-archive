# Relic Rush resource expedition

Clear the marked ground or complete the crew's task. The matches made along the
way bring back Coins, Supplies and Food to restore the valley. The launch
campaign uses the existing 30 expeditions, twenty restorations, nine quests and
the signal finale. Each restoration should feel like spending what the crew
just brought home.

## What the reference games do

The [extracted Cradle of Rome reference](../../../docs/cradle-of-rome-reference/README.md)
covers the Android beta’s boards and city prices.

| Question | Cradle of Rome | Cradle of Egypt, GameTop Windows edition |
| --- | --- | --- |
| What clears a board? | Match on every blue plaque before time runs out. Chains limit access to the pieces above the plaques. | The atlas has beige ordinary, blue single-hit and orange two-hit cells. All 115 numbered board files use marked cells. 102 only use single-hit targets, and 13 also have two-hit targets. |
| How do matches pay? | Pieces produce Gold, Food or Supplies according to their type. Lines of four or five pay more per piece than a line of three. The time left can also pay out. | The piece table gives a resource and yield to each earning piece. The four opening types include two filler pieces and two coins. Tomato and brick enter the pool through city construction. |
| Do the piece types change? | Buying a building can introduce a resource piece or a bonus on later boards. Sawmill lumber and quarry stone both feed Supplies. | Level 1 permits four types and 114 subsequent numbered level files permit five. Some levels pin specific opening pieces. The construction table unlocks different spawnable pieces or bonuses over the campaign. |
| How many currencies does a building cost? | The city uses three purses, and prices depend on the building. | Of 20 buildings, two cost Gold alone, one costs Gold and Food, and 17 use all three. The Clay Pit raises the Food requirement before it introduces bricks. |

Rome's blue plaques and income are an especially good fit. A player can
decide whether to take the match that clears a remote plaque, take a colour
needed at home, or satisfy both with one move. Egypt is an adequate reference
for that loop and gives us inspectable data. The exact ratios belong to the
specific reference build. For example, the official Egypt tile guide gives
silver/gold coins yields of 3/5, while the Windows files set them to 2/4.
[GameHouse's Rome walkthrough](https://www.gamehouse.com/blog/2016/04/cradle-of-rome-walkthrough/),
[Awem's Egypt tile guide](https://support.awem.com/hc/en-gb/articles/201076871-Tiles),
[GameTop's Egypt edition](https://www.gametop.com/download-free-games/cradle-of-egypt/).

### The water bucket in Cradle of Rome 2

Big Fish publishes the exact level 4 screenshot from the discussion. Its
board has green leaves, blue flowers, silver coins, gold coins and buckets
of water. The bucket produces **3 Food per piece**, so a match of three
produces 9 Food at base value. The blue marble is the level objective and the
large water vessel on the right is the timer. Awem credits later Food pieces
such as meat, bread and shrimp at 4, 5 and 6 per piece. Buying buildings adds
more valuable pieces and bonuses to the pool. The Windows Well costs 500 Gold
and unlocks tile 5, the water bucket. The Sawmill subsequently requires Food and unlocks lumber.
See the [full Windows economy export](../../../docs/cradle-of-rome-reference/rome-2-economy.json).
[Big Fish level 4 screenshot](https://cdn-content.bigfishgames.com/prodstatic/games/es_cradle-of-rome-2/screen1.jpg),
[Well construction in the recorded run](https://www.youtube.com/watch?v=AOBES8G3LGU&t=150s),
[Awem on resources and construction](https://support.awem.com/hc/en-gb/articles/200686242-Building-the-City),
[Awem on level completion](https://support.awem.com/hc/en-gb/articles/200721201).

### Extracted evidence

The [Cradle of Rome 2 Windows extraction](../../../docs/cradle-of-rome-reference/README.md#cradle-of-rome-2-economy-data)
has all 1,426 resource entries. `game_balls.xml` supplies the tile yields.
`epochs.xml` supplies the prices, blueprint requirements and tile unlocks.
The original chips are available locally for comparison with `--rome-reference-art`.

## Board rules and palette

A beige cell is open ground. Clear the piece on a blue cell once to expose
the pale stone. A chained piece takes one hit to free and a later hit to clear
the plaque beneath it. Each blue cell marks a target on the board.

Every expedition marks the work site with blue plaques. Clearing all of
them wins. The first clear can recover a story item shown in an ordinary
colour slot, and board 30 reveals the signal plate and Ines’s reply.
Move limits fit short portrait play and give deliberate resource matches a
visible cost.

| Regular piece | Family | Yield per removed piece |
| --- | --- | ---: |
| Gold sun coin | Coins | 4 |
| Red berries | Food | 1 |
| Green apple | Food | 1 |
| Timber bundle | Supplies | 2 |
| Purple dressed stone | Supplies | 3 |

Buy or restore a building using the family totals. Timber and stone are
separate match kinds within Supplies, just as berries and green apples are
separate kinds within Food. The town and board show Coins, Supplies and Food
with a sun coin, a timber-and-stone bundle and a food basket. Pending earnings
are visible on the board and bank on a win. The completion dialog shows score.

Five types is the normal palette. A 4+1 recovery has four regular kinds and a
story kind in the fifth slot. A 5+1 recovery has six total kinds and should
earn that complexity through layout and enough legal opening swaps. Board 1
uses five regular resources. Boards 4 and 9 use 5+1. Board 8 puts the relay
pliers in the orange slot and omits red berries, leaving room for cut blocks in
a 4+1 palette. Leaves and flowers add score in their authored slots and clear
plaques just like other matches. Board 4 takes
the Coins slot for the tide chart. The Well purchase that follows uses Coins
banked on earlier boards or earned from unused moves and replays.

Confirmed placements change openings and refills from the listed expedition
onward. Authored story pieces keep their slots. The four bonus families debut
as matchable pieces and fill their own saved slots across both levels. [Bonus rules and effects](board-progression.md#bonus-pieces)

The ten story restorations (★) hold the next new expedition until they are
placed. The other ten sit between them on the same ladder. Each opens after
its clear and must be placed before the next story restoration. A player can play on past an open one until the story
needs it. [Ladder design](../../../docs/cradle-of-rome-reference/TWENTY_BUILDINGS.md#relic-rush-the-20-restorations)

| # | Restoration | Placed after | First board | Board payoff | Price C / F / S |
| ---: | --- | ---: | ---: | --- | ---: |
| 1 | ★ Expedition Camp | 1 | 2 | Hammer gems | 0 / 10 / 20 |
| 2 | ★ Spring Well | 4 | 5 | Water buckets replace timber, 3 Food each | 130 / 0 / 0 |
| 3 | Trapper's cabin | 7 | 8 | Dynamite upgrades Hammer | 80 / 55 / 75 |
| 4 | ★ Artisan Workshop | 7 | 8 | Cut blocks replace dressed stone, 5 Supplies each | 145 / 105 / 150 |
| 5 | Water mill | 9 | — | Opens the Jungle Market restoration | 75 / 50 / 75 |
| 6 | ★ Jungle Market | 9 | 10 | Ration jars replace red berries, 4 Food each | 145 / 95 / 150 |
| 7 | Clock tower | 11 | 12 | Star gems | 180 / 140 / 200 |
| 8 | Stone amphitheatre | 13 | 14 | Shield gems | 60 / 80 / 80 |
| 9 | ★ Sunstone Courtyard | 13 | 14 | Helmets replace sun coins, 6 Coins each | 90 / 150 / 160 |
| 10 | ★ Explorer's Lodge | 16 | 17 | Grain bundles replace ration jars, 5 Food each | 300 / 340 / 0 |
| 11 | Trading post | 17 | 18 | Rings replace helmets, 7 Coins each | 250 / 290 / 360 |
| 12 | Valley lighthouse | 19 | 20 | Lightning upgrades Shield | 100 / 110 / 120 |
| 13 | ★ Lost-world Archive | 19 | 20 | Carved quartz replaces cut blocks, 7 Supplies each | 195 / 230 / 240 |
| 14 | Beached schooner | 20 | 21 | Scarabs replace rings, 8 Coins each | 190 / 190 / 190 |
| 15 | Cartographer's house | 22 | 23 | Plus gems give a quarter charge to other unlocked bonuses | 285 / 250 / 270 |
| 16 | ★ Star Observatory | 23 | 24 | Star II upgrades Star | 205 / 0 / 200 |
| 17 | Great aviary | 24 | 25 | Sandals replace scarabs, 9 Coins each | 200 / 240 / 180 |
| 18 | ★ Jade Fountain | 26 | 27 | Shrimp replace water buckets, 6 Food each | 280 / 0 / 300 |
| 19 | Relic museum | 27 | 28 | Harps replace sandals, 10 Coins each. Plus II upgrades Plus | 220 / 420 / 220 |
| 20 | ★ Temple of the Sun | 29 | 30 | Emeralds replace harps, 11 Coins each | 330 / 430 / 330 |

Each new piece pays a currency the next restoration on the ladder needs.
Where two restorations share a clear (7, 9, 13 and 19), the story restoration
comes second. Board 10 features the Shutter Gear quest piece alongside the
market's new ration jars.

One slot pays Coins. Expedition 3 uses the silver coin at 3 Coins. From there
the slot climbs one treasure per restoration: helmet (6), ring (7), scarab (8),
sandal (9), harp (10) and emerald (11). A board shows the best treasure placed
by its expedition.
[Side-by-side Rome comparison](../../../docs/cradle-of-rome-reference/gem-correspondence.html)

A save from before the ladder keeps playing. When it loads, the new
restorations before its latest earned story restoration become optional:
they stay on sale and never hold an expedition.

An arrival message credits the restored building and names the new piece's
yield. The authored hint on board 5 trades one swap for three cleared plaques
and 9 Food. Board 9 pairs three plaques with 15 Supplies while leaving
the supply crate as the first-clear find. Coins pay for labor and materials,
Food keeps the workers supplied, and Supplies go into repairs.

## Restoration prices and earnings

The Camp uses Supplies and Food. Buying the Well with Coins unlocks a Food
source. Every restoration after it uses at least two currencies. The prices
are in the ladder table above.

**Prices come from a measured run.** The extended campaign run plays every
board with a greedy bot, places each restoration when it can afford it, and
replays the latest board when the story needs one it cannot. Each stop's price
is about 80% of what the boards since the previous stop pay (smoothed over five
boards), in the building's own mix of currencies, then rounded. With these
prices the bot places all twenty in thirty clears with three replays: two at
clear 13, whose board pays almost no Coins, and one at clear 23. Every currency
runs low at some stop, and it ends with 334 Coins, 229 Supplies and 299 Food.
It also builds the Beached schooner a clear late, after saving for it. The bot
is not a human player; human sessions should confirm the shortfalls.

```sh
make CFLAGS="-O2 -g -Werror" relic-rush build/test/relic-rush
build/test/relic-rush --extended "rules campaign_play"   # per-board wallet in build/test/relic-rush.log
```

A piece earns its base amount when a match, cascade or tool clears it.
Breaking a chain leaves its piece in place. A later hit clears the piece and
earns its resources. The first clear awards the story item and Discovery Stars.
The result card shows the three resource totals and what is still due for the next restoration.

Record attempt earnings until a successful clear. Claim persists the first
clear, resources, story progress and discovery stars together. A resumed result
can be claimed once. Restart and loss discard unbanked matches. Quitting to the island keeps the active board available for the current session.
Optional replays bank the matches from each won attempt and advance no story.
When a restoration costs more than is in the wallet, replay a cleared board
with the missing resource and bank the earnings. Optional purchases reserve
the price of any earned restoration. Confirmed placement debits the price
once and Cancel returns the preview. Stars remain access requirements.
Confirmed restorations add four Happiness. Each confirmed optional building
or decoration adds one Happiness and earns one bonus Coins per win, capped at
ten Coins. Moving items preserves the score and bonus. Both derive from saved
placements.

A save version identifies the Food and Supplies slots. Existing Coins,
stars, placements, lives, unlocks, claimed levels and story checkpoints are
preserved. Legacy Wood and Stone are combined into Supplies. Migration covers
any gap on a restoration already earned before the price changes. The wallet, catalogue and result
screen should all use the same ordering and amount formatting. Use resource
shapes and readable labels alongside color in the guide and price rows.

## Release status and checks

Eight seeded runs through level 20 funded all 56 restoration purchases from
first clears after the Camp price was lowered to 3 Food. The sample used
greedy matches and allowed expedition tools when four moves remained.

All 30 boards use pale stone with fixed blue targets. They share the
same clear condition. The [current review](review/blue-plaque-campaign/README.md)
shows the board, new resource artwork and common wallet at both phone sizes.

For release balancing, play the first restoration through a fresh save on
both supported phone sizes and sample a migrated save midway through chapter two.
Verify that matching every resource kind, including through a cascade or
special, agrees with the result and the wallet after a restart. Confirm the
shop's price and reserve through Confirm, Cancel, exhausted tool counts, replay
and claim interruption. The seeded campaign test plays all 30 boards with
the live wallet and confirms all ten purchases. For release tuning, record
wallet shortfalls across more seeds and watch people play on both phone sizes.
Review plaque and story piece recognition with Reduce Motion enabled at
390×844 and 480×900.
