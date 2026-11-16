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
onward. Authored story pieces keep their slots. The eight bonus families debut
as matchable pieces and fill their own saved sockets. [Bonus rules and effects](board-progression.md#bonus-pieces)

Like Cradle of Rome's twenty constructions, each restoration adds exactly one
piece or one bonus. The ten story restorations (★) hold the next new
expedition until they are placed. The other ten sit between them on the same
ladder: each opens after its clear, and must be placed before the next story
restoration can be. A player can play on past an open one until the story
needs it. [Ladder design](../../../docs/cradle-of-rome-reference/TWENTY_BUILDINGS.md#relic-rush-the-20-restorations)

| # | Restoration | Placed after | First board | Board payoff | Price C / F / S |
| ---: | --- | ---: | ---: | --- | ---: |
| 1 | ★ Expedition Camp | 1 | 2 | Dynamite gems | 0 / 3 / 8 |
| 2 | ★ Spring Well | 4 | 5 | Water buckets replace timber, 3 Food each | 100 / 0 / 0 |
| 3 | Trapper's cabin | 7 | 8 | Hammer gems | 40 / 10 / 12 |
| 4 | ★ Artisan Workshop | 7 | 8 | Cut blocks replace dressed stone, 5 Supplies each | 70 / 20 / 24 |
| 5 | Water mill | 9 | 10 | Shutter Gear gems | 45 / 12 / 15 |
| 6 | ★ Jungle Market | 9 | 10 | Ration jars replace red berries, 4 Food each | 85 / 24 / 30 |
| 7 | Clock tower | 11 | 12 | Amphora gems: a use adds 5 moves | 80 / 30 / 25 |
| 8 | Stone amphitheatre | 13 | 14 | Shield gems | 50 / 18 / 18 |
| 9 | ★ Sunstone Courtyard | 13 | 14 | Helmets replace sun coins, 6 Coins each | 85 / 34 / 36 |
| 10 | ★ Explorer's Lodge | 16 | 17 | Grain bundles replace ration jars, 5 Food each | 130 / 35 / 0 |
| 11 | Trading post | 17 | 18 | Rings replace helmets, 7 Coins each | 90 / 45 / 20 |
| 12 | Valley lighthouse | 19 | 20 | Lightning gems | 75 / 40 / 20 |
| 13 | ★ Lost-world Archive | 19 | 20 | Carved quartz replaces cut blocks, 7 Supplies each | 145 / 85 / 40 |
| 14 | Beached schooner | 20 | 21 | Scarabs replace rings, 8 Coins each | 120 / 30 / 70 |
| 15 | Cartographer's house | 22 | 23 | Tide Chart gems: a use half-charges every other bonus | 140 / 50 / 40 |
| 16 | ★ Star Observatory | 23 | 24 | Star gems | 155 / 0 / 70 |
| 17 | Great aviary | 24 | 25 | Sandals replace scarabs, 9 Coins each | 160 / 40 / 60 |
| 18 | ★ Jade Fountain | 26 | 27 | Shrimp replace water buckets, 6 Food each | 160 / 0 / 65 |
| 19 | Relic museum | 27 | 28 | Harps replace sandals, 10 Coins each | 170 / 90 / 50 |
| 20 | ★ Temple of the Sun | 29 | 30 | Emeralds replace harps, 11 Coins each | 185 / 110 / 75 |

Each new piece pays a currency the next restoration on the ladder needs.
Where a story restoration and a new one share a clear (7, 9, 13 and 19), the
new one comes first, so every bonus debuts on the same board as before the
ladder. Board 10's story gear is also the Shutter Gear piece.

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

**The ten new restorations are priced provisionally.** The extended campaign
run plays every board with a greedy bot, places each restoration when it can
afford it, and replays the latest board when the story needs one it cannot.
With the current prices it places all twenty in thirty clears with no replays.
The wallet runs far ahead of prices: after board 14 it holds 556 Coins,
902 Supplies and 679 Food, and it ends with 1,651 / 2,583 / 2,562. The story
prices were already at this scale, so the next step is a price pass across the
whole ladder rather than the new rows alone. The bot is not a human player.

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
