# Relic Rush resource expedition

Clear all blue plaques to win the expedition. The matches made along the
way bring back Coins, Supplies and Food to restore the valley. The story
campaign runs across twenty square boards and opens fourteen restorations.
The third episode and signal finale remain in the story archive. Each
restoration spends the resources the crew brought home.

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
the tablet beneath it. Each blue cell marks a target on the board.

Every expedition marks the work site with blue tablets. Clearing all of
them wins. Chapter 1 tells its story through island construction. Chapter 2
uses first-clear and restoration scenes to tell the story of Ines’s return.
Move limits fit short portrait play and give deliberate resource matches a
visible cost.

The opening pool contains sun coins (5 Coins), silver coins (3 Coins), leaves, flowers and amphoras. The latter three pay score. Construction introduces the twelve resource pieces and eight bonus pieces in the [purchase table](../README.md#buildings). The Well adds the first Food and the Sawmill adds the first Supplies. A confirmed purchase can replace the live bonus piece on a parked expedition.

## Restoration prices and earnings

The currencies and their order of introduction follow the [Windows economy export](../../../docs/cradle-of-rome-reference/rome-2-economy.json). The [square campaign balance check](square-match3.md#construction-balance) measures income from the active boards and confirms each purchase in order. The source prices live in `art/building-catalogue/story.json`. Run `python3 games/relic-rush/tools/prepare_buildings.py` to regenerate the runtime catalogue after an edit.

## Release status and checks

All twenty boards use blue targets on the papyrus floor. The
[square campaign captures](square-match3.md#captures) show the board and
wallet at both phone sizes.

For release balancing, play the first restoration through a fresh save on
both supported phone sizes and sample a migrated save midway through chapter two.
Verify that matching every resource kind, including through a cascade, agrees with the result and the wallet after a restart. Confirm the
shop's price and reserve through Confirm, Cancel, exhausted tool counts, replay
and claim interruption. The seeded campaign test plays all twenty square boards with
the live wallet and confirms every ladder purchase. For release tuning, record
wallet shortfalls across more seeds and watch people play on both phone sizes.
Review tablet and resource piece recognition with Reduce Motion enabled at
390×844 and 480×900.
