# Relic Rush resource expedition

Clear all blue plaques to win the expedition. The matches made along the
way bring back Coins, Supplies and Food to restore the valley. The story
campaign runs across boards 1-30 (three episodes) with twenty restorations and
the signal finale; boards 31-100 are playable without story yet. Each restoration should feel like spending what the crew
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
the pale stone; a green double tablet takes two hits. A chained piece takes one hit to free and a later hit to clear
the tablet beneath it. Ice and carved stones also gate the cells below them. Each blue cell marks a target on the board.

Every expedition marks the work site with blue tablets. Clearing all of
them wins. Chapter 1 tells its story through island construction. Board 13 features a story item, and board 30 shows the signal plate and Ines’s reply.
Move limits fit short portrait play and give deliberate resource matches a
visible cost.

| Regular piece | Family | Yield per matched piece |
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

Every board spawns five kinds. Board 13 keeps a story kind in one slot; see
[board progression](board-progression.md). Leaves and flowers add score and clear
tablets. The Well costs Coins banked by matching sun or silver coins.

Confirmed placements change openings and refills from the listed expedition
onward. Authored story pieces keep their slots. The four bonus families debut
as matchable pieces and fill their own saved slots across both levels. [Bonus rules and effects](board-progression.md#bonus-pieces)

The ten story restorations (★) keep the journey's schedule but never block the next new expedition. Nine more purchases sit between them on the same ladder. Each opens after
its clear and must be placed before the next story restoration. A player can play on past an open one until the story
needs it. [Ladder design](../../../docs/cradle-of-rome-reference/TWENTY_BUILDINGS.md#relic-rush-the-20-restorations)

| # | Restoration | Placed after | First board | Board payoff | Price C / F / S |
| ---: | --- | ---: | ---: | --- | ---: |
| 1 | ★ Expedition Camp | 1 | 2 | Hammer gems | 0 / 10 / 20 |
| 2 | ★ Spring Well | 4 | 5 | Water buckets replace timber, 3 Food each | 125 / 0 / 0 |
| 3 | ★ Trapper's cabin | 7 | 8 | Dynamite upgrades Hammer | 65 / 40 / 45 |
| 4 | ★ Artisan Workshop | 10 | 11 | Repairs the quay and adds cut blocks worth 5 Supplies | 120 / 80 / 90 |
| 5 | Water mill | 10 | — | Opens the miller’s cascade challenge | 65 / 35 / 60 |
| 6 | Clock tower | 11 | 12 | Star gems | 150 / 200 / 150 |
| 7 | Stone amphitheatre | 13 | 14 | Shield gems | 35 / 50 / 35 |
| 8 | ★ Sunstone Courtyard | 13 | 14 | Helmets replace sun coins, 6 Coins each | 55 / 95 / 65 |
| 9 | ★ Explorer's Lodge | 16 | 17 | Grain bundles replace ration jars, 5 Food each | 330 / 325 / 0 |
| 10 | Trading post | 17 | 18 | Rings replace helmets, 7 Coins each | 170 / 215 / 290 |
| 11 | Valley lighthouse | 19 | 20 | Lightning upgrades Shield | 70 / 70 / 55 |
| 12 | ★ Lost-world Archive | 19 | 20 | Carved quartz replaces cut blocks, 7 Supplies each | 140 / 145 / 110 |
| 13 | Beached schooner | 20 | 21 | Scarabs replace rings, 8 Coins each | 145 / 140 / 125 |
| 14 | Cartographer's house | 22 | 23 | Plus gems give a quarter charge to other unlocked bonuses | 275 / 230 / 180 |
| 15 | ★ Star Observatory | 23 | 24 | Star II upgrades Star | 120 / 0 / 85 |
| 16 | Great aviary | 24 | 25 | Sandals replace scarabs, 9 Coins each | 210 / 285 / 175 |
| 17 | ★ Jade Fountain | 26 | 27 | Shrimp replace water buckets, 6 Food each | 315 / 0 / 225 |
| 18 | Relic museum | 27 | 28 | Harps replace sandals, 10 Coins each. Plus II upgrades Plus | 205 / 420 / 115 |
| 19 | ★ Temple of the Sun | 29 | 30 | Emeralds replace harps, 11 Coins each | 435 / 450 / 260 |

Each new piece pays a currency the next restoration on the ladder needs.
The Water Mill follows the Workshop. Clears 13 and 19 each open an intermediate purchase before the story restoration. The optional Jungle Market becomes available after board 10 and adds ration jars worth 4 Food each from board 11.

One slot pays Coins. Expedition 3 uses the silver coin at 3 Coins. From there
the slot climbs one treasure per restoration: helmet (6), ring (7), scarab (8),
sandal (9), harp (10) and emerald (11). A board shows the best treasure placed
by its expedition.
[Side-by-side Rome comparison](../../../docs/cradle-of-rome-reference/gem-correspondence.html)

A save from before the ladder keeps playing. When it loads, the new
restorations before its latest earned story restoration become optional:
they stay on sale and never hold an expedition.

An arrival message credits the restored building and names the new piece's
yield. The opening water match on board 5 earns Food and the opening cut-block match on board 9 earns Supplies. Coins pay for labor and materials,
Food keeps the workers supplied, and Supplies go into repairs.

## Restoration prices and earnings

The Camp uses Supplies and Food. Buying the Well with Coins unlocks a Food
source. Every restoration after it uses at least two currencies. The prices
are in the ladder table above.

**Prices come from averaged board income.** For the price fit, the balance runner played every
board 40 times with the greedy bot and the unlocks the ladder has delivered by
then, using only the rules: no screen, story or animation. It reports each
board's win rate, moves left and mean income per won board, then walks the
expected campaign: bank each board's mean income and, at each stop, spend 80%
of what the wallet holds in every currency the stop's restorations use, split
by their previous prices. The rest carries over, so every currency runs low
somewhere and none piles up unused. The current seeded campaign check uses the live match ledger, plays the story expeditions and replays boards when a building needs more resources.

The bot wins many boards in fewer than half its attempts (board 28 in 8 of
40), since matches make no special pieces. Win rates and moves left are
in the same report.

```sh
make CFLAGS="-O2 -g -Werror" relic-rush build/test/relic-rush
make test-balance                       # 10 plays per board and the full economy report
make test-balance BALANCE_RUNS=40       # 40 plays per board for price tuning
build/test/relic-rush --extended "rules campaign_play"                  # one seeded campaign
```

The reports are in `build/test/relic-rush.log`.

A piece earns its resource amount when a match or cascade clears it. A direct tool hit can clear a piece, and any resulting matches earn their normal yields. Breaking a chain leaves its piece in place until a later hit. Each first clear advances progress. Chapter 1 scenes wait for confirmed island work.
The result card shows the three resource totals and what is still due for the next restoration.

Record attempt earnings until a successful clear. Claim persists the first
clear, resources and story progress together. A resumed result
can be claimed once. Restart and loss discard unbanked matches. Quitting to the island keeps the active board available for the current session.
Optional replays bank the matches from each won attempt and advance no story.
When a restoration costs more than is in the wallet, replay a cleared board
with the missing resource and bank the earnings. Optional purchases reserve
the price of any earned restoration. Confirmed placement debits the price
once and Cancel returns the preview. Boards cleared remain access requirements for land and shop stock.
Citizen events can improve what an individual resource match yields. Wallet totals on Results come from the board’s match ledger.

A save version identifies the Food and Supplies slots. Existing Coins,
placements, unlocks, claimed levels and story checkpoints are
preserved. Legacy Wood and Stone are combined into Supplies. Migration covers
any gap on a restoration already earned before the price changes. The wallet, catalogue and result
screen should all use the same ordering and amount formatting. Use resource
shapes and readable labels alongside color in the guide and price rows.

## Release status and checks

All 100 boards use pale stone with fixed blue targets. They share the
same clear condition. The [current review](review/blue-plaque-campaign/README.md)
shows the board, new resource artwork and common wallet at both phone sizes.

For release balancing, play the first restoration through a fresh save on
both supported phone sizes and sample a migrated save midway through chapter two.
Verify that matching every resource kind, including through a cascade, agrees with the result and the wallet after a restart. Confirm the
shop's price and reserve through Confirm, Cancel, exhausted tool counts, replay
and claim interruption. The seeded campaign test plays the 30 story boards with
the live wallet and confirms all ten purchases. For release tuning, record
wallet shortfalls across more seeds and watch people play on both phone sizes.
Review tablet and story piece recognition with Reduce Motion enabled at
390×844 and 480×900.
