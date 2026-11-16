# Relic Rush resource expedition

Clear the marked ground or complete the crew's task. The matches made along the
way bring back Coins, Supplies and Food to restore the valley. The launch
campaign uses the existing 30 expeditions, ten restorations, nine quests and
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

The board has six base slots for resources, score pieces and story pieces.
Board 8 uses the orange slot for the relay pliers, so the camp's bonus has
its own seventh kind. Leaves and flowers add score in their authored slots and clear
plaques just like other matches. Board 4 takes
the Coins slot for the tide chart. The Well purchase that follows uses Coins
banked on earlier boards or earned from unused moves and replays.

Confirmed placements change openings and refills from the listed expedition
onward. Authored story pieces keep their slots. Pickaxes start with two uses.
Dynamite and Sunburst start empty and gain three charge points per matched
bonus piece. Twenty-seven points grant one use. Uses and partial charges
carry between attempts. Later boards select one unlocked bonus family by seed.

| Restoration | First board | Board payoff | How it funds the next restoration |
| --- | ---: | --- | --- |
| Expedition Camp | 2 | Dynamite charge pieces | Blast coin clusters or save moves for the Well. |
| Spring Well | 5 | Water buckets replace timber, 3 Food each | Feed the Workshop crew. |
| Artisan Workshop | 8 | Cut blocks replace dressed stone, 5 Supplies each | Pay the Market's Supplies. |
| Jungle Market | 10 | Ration jars replace red berries, 4 Food each | Feed the crew working on the Courtyard. |
| Sunstone Courtyard | 14 | Helmets replace sun coins, 6 Coins each | Pay the Lodge's Coin cost. |
| Explorer's Lodge | 17 | Grain bundles replace ration jars, 5 Food each | Pay the Archive's Food cost. |
| Lost-world Archive | 20 | Carved quartz replaces cut blocks, 7 Supplies each | Pay the Observatory's Supplies. |
| Star Observatory | 24 | Sunburst charge pieces | Clear coin or quartz across the board for the Fountain. |
| Jade Fountain | 27 | Shrimp replace water buckets, 6 Food each | Pay the Temple's Food cost. |
| Temple of the Sun | 30 | Emeralds earn 11 Coins each | The finale and its replays earn Coins for island purchases. |

One slot pays Coins. Expedition 3 uses the silver coin at 3 Coins. The
Courtyard unlocks helmets on expeditions 14–17, then the same slot pays 7 with
rings on 18–20, 8 with scarabs on 21–24, 9 with sandals on 25–27 and 10 with
harps from 28. The Temple promotes it to Emerald on expedition 30.
[Side-by-side Rome comparison](../../../docs/cradle-of-rome-reference/gem-correspondence.html)

An arrival message credits the restored building and names the new piece's
yield. The authored hint on board 5 trades one swap for three cleared plaques
and 9 Food. Board 9 pairs three plaques with 15 Supplies while leaving
the supply crate as the first-clear find. Coins pay for labor and materials,
Food keeps the workers supplied, and Supplies go into repairs.

## Restoration prices and earnings

The Camp uses Supplies and Food. Buying the Well with Coins unlocks a Food
source. The Workshop and Market use all three currencies.

| Clear | Restore | Coins | Supplies | Food |
| ---: | --- | ---: | ---: | ---: |
| 1 | Expedition camp | — | 8 | 3 |
| 4 | Spring well | 100 | — | — |
| 7 | Artisan workshop | 70 | 24 | 20 |
| 9 | Jungle market | 85 | 30 | 24 |
| 13 | Sunstone courtyard | 85 | 36 | 34 |
| 16 | Explorer's lodge | 130 | — | 35 |
| 19 | Lost-world archive | 145 | 40 | 85 |
| 23 | Star observatory | 155 | 70 | — |
| 26 | Jade fountain | 160 | 65 | — |
| 29 | Temple of the sun | 185 | 75 | 110 |

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
