# Christmas Market · first 20 wishes

Noelle lights the old market at Bellmere. Winning a board banks the goods
cleared on it. Spending those goods puts a stall in the market and puts
that stall’s piece into the board pool. Story scenes pick up after the
building is placed or after a first clear when the next scene needs no
construction. A replay earns goods and leaves the story at its checkpoint.

## What the references establish

The local archives are [Cradle of Rome Beta 0.9.0 for Android and Cradle of
Rome 2 for Windows](../../../docs/cradle-of-rome-reference/README.md). The
first 20 files in each pack set `allow_ball_types` to 5. That setting does
not enumerate the runtime refill pool. Each piece table describes 16
numbered regular pieces (two for score and fourteen for resources), eight
bonus-piece types, and other special records. The first four verified
ordinary roles are leaf and flower for score, silver coin for 3 Gold and
gold coin for 5 Gold. The Android table also flags a score-only skull as
available. Its appearance in ordinary opening refills is unverified.
[Awem’s resource guide](https://support.awem.com/hc/en-gb/articles/200686242-Building-the-City)

| Purchase in the first two epochs | Rome I price | Adds | Purchase in Rome II | Rome II price | Adds |
| --- | ---: | --- | --- | ---: | --- |
| Sawmill | 500 / 0 / 0 | Lumber · 5 Supplies | Well | 500 / 0 / 0 | Water bucket · 3 Food |
| Forge | 1000 / 1000 / 0 | Hammer | Hunter’s Hut | 1000 / 0 / 1500 | Hammer |
| Quarry | 3000 / 2000 / 0 | Stone · 7 Supplies | Sawmill | 3000 / 0 / 2500 | Lumber · 5 Supplies |
| Mill | 4000 / 5000 / 0 | Flour · 4 Food | Village | 2000 / 3000 / 2000 | Bomb |
| Village | 3000 / 3000 / 2000 | Meat / bucket · 3 Food | Farm | 3000 / 2000 / 3000 | Meat · 4 Food |
| Field | 5000 / 4000 / 4000 | Watermelon · 6 Food | Mine | 5000 / 4000 / 4000 | Stone · 7 Supplies |
| Fountain | 5000 / 6000 / 5000 | Lightning | Mill | 6000 / 7000 / 8000 | Bread · 5 Food |
| Tavern | 7000 / 7000 / 6000 | Barrel · 5 Food | Thermae | 10000 / 12000 / 11000 | Fireball |

Price and wallet triples on this page are **Gold / Supplies / Food**. Each
listed Roman blueprint has the same resource threshold as its purchase.
The reference board XML gives pane positions, starting locks, time limits
and occasional fixed pieces. It does not specify final earnings or purchase
levels. Those depend on play and the source games’ refill, combo and
time-bonus logic. The two original editions were inspected as extracted
data. The earnings below come from running Christmas Market.

The reference sizes are the smallest rectangles that contain the **active**
cells. The XML allocates 30×20 storage in both releases. Christmas Market
uses its existing portrait hex field, nine coordinates across, with a
maximum of 61 active cells before shape cutouts. The Roman 10th and 20th
levels introduce and repeat all-double plaques in both versions. Christmas
Market mirrors that rhythm. [Board progression](board-progression.md)

| Wish | Rome I active width×height | Active / blue / double / locked | Rome II active width×height | Active / blue / double / locked |
| ---: | --- | ---: | --- | ---: |
| 1 | 10×8 | 72 / 6 / 0 / 0 | 13×10 | 126 / 8 / 0 / 0 |
| 2 | 12×9 | 80 / 8 / 0 / 0 | 14×11 | 128 / 8 / 0 / 0 |
| 3 | 13×10 | 99 / 27 / 0 / 0 | 15×12 | 143 / 38 / 0 / 0 |
| 4 | 14×10 | 100 / 62 / 0 / 0 | 15×12 | 114 / 35 / 0 / 1 |
| 5 | 13×10 | 92 / 58 / 0 / 1 | 14×12 | 130 / 78 / 0 / 0 |
| 6 | 14×9 | 94 / 80 / 0 / 12 | 15×12 | 136 / 38 / 0 / 8 |
| 7 | 12×10 | 80 / 68 / 0 / 0 | 17×12 | 158 / 144 / 0 / 0 |
| 8 | 14×10 | 124 / 52 / 0 / 12 | 16×12 | 160 / 148 / 0 / 0 |
| 9 | 14×10 | 62 / 39 / 0 / 1 | 17×12 | 166 / 110 / 0 / 5 |
| 10 | 14×10 | 92 / 88 / 88 / 0 | 16×12 | 118 / 118 / 118 / 0 |
| 11 | 14×10 | 104 / 70 / 0 / 0 | 17×12 | 145 / 97 / 0 / 2 |
| 12 | 14×10 | 98 / 94 / 0 / 4 | 17×12 | 122 / 82 / 0 / 0 |
| 13 | 16×10 | 106 / 76 / 0 / 12 | 17×12 | 186 / 146 / 0 / 18 |
| 14 | 14×10 | 104 / 74 / 0 / 0 | 16×12 | 168 / 136 / 0 / 24 |
| 15 | 14×10 | 86 / 70 / 0 / 2 | 15×12 | 148 / 124 / 0 / 0 |
| 16 | 14×10 | 82 / 78 / 0 / 0 | 17×12 | 140 / 130 / 0 / 0 |
| 17 | 14×10 | 100 / 74 / 0 / 0 | 17×12 | 157 / 151 / 0 / 0 |
| 18 | 14×10 | 92 / 92 / 0 / 2 | 17×12 | 165 / 165 / 0 / 0 |
| 19 | 14×10 | 100 / 100 / 0 / 0 | 15×12 | 160 / 118 / 0 / 36 |
| 20 | 14×10 | 116 / 116 / 116 / 0 | 17×12 | 143 / 143 / 143 / 0 |

## Bellmere’s loop

- Holly and a red mitten are score pieces. Silver and gold coins pay 3 and
  5 Gold per piece. The arch brings Theo’s firewood into the pool at
  5 Supplies each. The active pool grows to five ordinary kinds. A board
  can also feature one unlocked tool piece. Later pools rotate kinds to
  leave room for the new supplies and foods.
- Three pieces pay three base yields, four pay eight, five pay twenty.
  The per-piece multiplier for six and longer is six, matching Rome’s
  configured top multiplier. Cascades are paid. Two intersecting lines
  pay their shared piece once at the longer line’s rate. A tool clear
  pays the piece’s base yield. A hit absorbed by tinsel pays when the
  piece itself is subsequently cleared.
- The **only board condition** is to light all marked panes. A blue pane
  takes one hit and a green pane takes two. Matches beyond a triple feed the wallet without creating
  a power-up. Hammer and Lightning charge from their own matched pieces
  at 3 base charge per piece, with 200 charge per use. Hammer hits one
  cell and Lightning hits 15, prioritizing a blue pane as in the Android
  data. The debut boards are 5 and 20. After both tools unlock, a seed
  selects one piece family on other wishes. Uses and partial charge carry
  between wishes, and both unlocked tools remain available in the toolbar.
- The Roman price ratios through the tavern are preserved at one tenth
  of the source prices. The prototype keeps Bellmere’s story checkpoints,
  free placement and move limits. Purchases spend the actual wallet.
  Replays provide a route to any shortfall. There is no bonus for unused
  moves, delivery top-up during normal play, timed completion bonus or
  extra combo multiplier on currency.
- Construction produces goods by adding pieces to future boards. Stars
  from first clears still mark access to land and decorations. Visitor
  happiness, passive stall income, Roman citizen perks and blueprint
  puzzles are outside this prototype.

| Build after | Bellmere purchase | Cost | Following board adds | What it changes in the story |
| ---: | --- | ---: | --- | --- |
| 1 | Welcome arch | 50 / 0 / 0 | Firewood · 5 Supplies | A light greets people coming from the station. Theo recognizes his offcuts. |
| 4 | Lumber workshop | 100 / 100 / 0 | Hammer · 3 charge | Theo has enough timber to put up his workshop and leave a board for a seat. |
| 7 | Gingerbread bakery | 300 / 200 / 0 | Packing blocks · 7 Supplies | Agnes’s oven gives Bellmere another reason to stop and stay. |
| 9 | Hot cocoa kiosk | 400 / 500 / 0 | Cocoa · 4 Food | Mrs Alder leaves a cup paid for the next guest. Its mug appears on the result. |
| 13 | Toymaker’s workshop | 300 / 300 / 200 | Milk · 3 Food | Henrik opens his workshop and the small lanterns go out into the market. |
| 16 | Gift wrapping pavilion | 500 / 400 / 400 | Winter apple · 6 Food | Pip’s practice scarf is shown on the result. His mum’s scarf still needs a tag. |
| 19 | Candlelight shop | 500 / 600 / 500 | Lantern star · 3 Lightning charge | A light reveals Henrik’s undelivered letter. Agnes and Henrik can finally talk after wish 20. |
| 23 | Reindeer carousel | 700 / 700 / 600 | Gingerbread · 5 Food | Neighbors paint the carousel horses. |

## A measured run

The existing campaign bot used the same swaps, refills, payouts and
placement transactions as the game. It tried seeds 1 through 4 in order
and used the first win for each wish. It used zero tools and made zero
optional purchases or replays. These are example payouts for one
successful route. Individual wins vary with moves and cascades. The
stock column is after Collect and before the purchase shown.

| Wish | Earned | Stock | Story purchase | Moves left |
| ---: | ---: | ---: | --- | ---: |
| 1 | 803 / 0 / 0 | 803 / 0 / 0 | Arch | 16 |
| 2 | 139 / 40 / 0 | 892 / 40 / 0 | — | 20 |
| 3 | 139 / 55 / 0 | 1031 / 95 / 0 | — | 25 |
| 4 | 485 / 275 / 0 | 1516 / 370 / 0 | Lumber workshop | 12 |
| 5 | 108 / 100 / 0 | 1524 / 370 / 0 | — | 39 |
| 6 | 124 / 100 / 0 | 1648 / 470 / 0 | — | 45 |
| 7 | 151 / 195 / 0 | 1799 / 665 / 0 | Bakery | 38 |
| 8 | 45 / 284 / 0 | 1544 / 749 / 0 | — | 48 |
| 9 | 60 / 329 / 0 | 1604 / 1078 / 0 | Cocoa kiosk | 21 |
| 10 | 150 / 280 / 212 | 1354 / 858 / 212 | — | 54 |
| 11 | 60 / 161 / 120 | 1414 / 1019 / 332 | — | 37 |
| 12 | 30 / 154 / 84 | 1444 / 1173 / 416 | — | 62 |
| 13 | 85 / 196 / 148 | 1529 / 1369 / 564 | Toymaker | 34 |
| 14 | 55 / 63 / 171 | 1284 / 1132 / 535 | — | 56 |
| 15 | 300 / 196 / 318 | 1584 / 1328 / 853 | — | 40 |
| 16 | 215 / 161 / 265 | 1799 / 1489 / 1118 | Gift pavilion | 25 |
| 17 | 70 / 42 / 208 | 1369 / 1131 / 926 | — | 58 |
| 18 | 115 / 63 / 256 | 1484 / 1194 / 1182 | — | 58 |
| 19 | 175 / 126 / 162 | 1659 / 1320 / 1344 | Candlelight shop | 46 |
| 20 | 365 / 329 / 696 | 1524 / 1049 / 1540 | — | 62 |

For example, wish 3 paid **139 Gold and 55 Supplies**. After the arch
was bought on wish 1, the wallet held **1,031 Gold and 95 Supplies**.
Theo’s workshop costs 100 Gold and 100 Supplies. This route is five
Supplies short after wish 3. Wish 4 adds 275 Supplies, the workshop is
built, and wish 5 introduces the hammer. No extra currency is awarded
to make that purchase possible.

The full compatibility run finished 30 wishes in 33 attempts, built
all ten story stalls and played all 36 scenes. Reproduce it from the
repository root.

```sh
make CFLAGS="-O2 -g -Werror" christmas-market build/test/christmas-market
build/test/christmas-market --check --extended "rules campaign_play"
```

The runner writes each payout to `build/test/christmas-market.log`.
Reference layouts can be reproduced with
`python3 tools/cradle-of-rome-reference/analyze.py --level 3`.
Pass `--root reference/cradle-of-rome-2/resources` for the sequel.
