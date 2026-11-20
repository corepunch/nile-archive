# From Rome to Bellmere

The [side-by-side correspondence sheet](../../../docs/cradle-of-rome-reference/gem-correspondence.html)
compares the actual art and yields in Cradle of Rome, Relic Rush and Christmas
Market. Bellmere uses three wallet slots in save order: **Tokens**, **Treats**
and **Materials**. Sun coins, cocoa and bundled pine identify those
totals on the board, in town, and in prices and results.

The opening has five kinds: a green snowy fir, a cranberry knitted mitten,
a silver snowflake coin, a gold Sun coin and an ivory-striped candy cane.
The mitten has opaque red wool and a cream snowflake. Mulled wine takes the candy
cane's place. The bakery's brown gingerbread man and the kiosk's ivory cocoa
mug follow in the same Treats slot. The stable brings a cobalt vase for score,
which replaces the mitten. The lumber workshop brings natural pine, which takes that slot. The
chapel replaces it with the same slate-gray dressed stone used in Relic Rush.
Its blocky profile and matte faces distinguish it from the bright round coin.
The Firework bundles three indigo crackers and stands out beside the red mulled wine.

## Construction sequence

Twenty purchases, one available after every fifth level (1, 6, 11 … 96), four per Advent of twenty levels. Story stalls are in bold: they play a placement scene and hold the next level, and the others must be bought before the next story stall. The order follows Cradle of Rome 2 except that the gift pavilion (gold) comes before the candle shop (Lightning), because story stalls keep catalogue order. The Gingerbread house, Giant bauble and Pile of presents left the ladder and stay in the shop. `python3 tools/balance.py christmas-market` fits the prices to the bot's measured income, so the expected campaign needs no replays.

| After level | Stall | Reward | Price (Tokens / Treats / Materials) |
| ---: | --- | --- | ---: |
| 1 | **Welcome arch** | Mulled wine +3 Treats | 40 / 0 / 0 |
| 6 | Reindeer stable | Farrier's hammer; winter vase (score) | 465 / 170 / 0 |
| 11 | **Lumber workshop** | Bundled pine +5 Materials | 880 / 315 / 0 |
| 16 | Firework stall | Firework Bomb | 775 / 275 / 310 |
| 21 | **Gingerbread bakery** | Gingerbread man +4 Treats | 875 / 0 / 495 |
| 26 | Snowy chapel | Dressed stone +7 Materials | 960 / 0 / 560 |
| 31 | **Hot cocoa kiosk** | Hot cocoa +5 Treats | 990 / 925 / 785 |
| 36 | Ice house (was Igloo) | Frost shield; ice pendant +6 Tokens | 1045 / 770 / 895 |
| 41 | Lakeside smokehouse (was Log cabin) | Smoked trout +6 Treats | 1175 / 700 / 945 |
| 46 | Station kiosk | Hourglass; pretzel +7 Treats | 1175 / 740 / 910 |
| 51 | **Toymaker's workshop** | Toy blocks +7 Tokens | 1285 / 925 / 1005 |
| 56 | **Gift wrapping pavilion** | Wrapped gift +8 Tokens | 1335 / 925 / 960 |
| 61 | **Candlelight shop** | Candle lantern (Lightning) | 1595 / 1050 / 1050 |
| 66 | North Pole post office | Wish cross (Plus) | 1605 / 1035 / 1060 |
| 71 | Glassblower's stall | Glass bauble +9 Tokens | 1630 / 1020 / 1055 |
| 76 | **Reindeer carousel** | Wind-up top (Mixer); +30 Treats per win | 1685 / 995 / 1030 |
| 81 | **Winter skating rink** | Ceramic snowman +10 Tokens | 1690 / 1070 / 960 |
| 86 | Woodcarvers' hall (was Santa's workshop) | Carved reindeer +11 Tokens | 1715 / 1060 / 955 |
| 91 | **Christmas tree** | Star | 1900 / 1090 / 1005 |
| 96 | Santa's sleigh | Santa hat +12 Tokens | 1895 / 1120 / 990 |

Confirmed placement turns on a new piece from the following level. Replays use
the regular goods of their own level. A save that already passed a stall's
gate can buy it from the shop.

## In-game review

| Board | Before | After |
| --- | --- | --- |
| 480 × 900 | [Mitten](screenshots/review/winter-stalls/board-480.jpg) | [Winter vase](screenshots/review/rome-coverage/vase-480.jpg) |
| 390 × 844 | [Mitten](screenshots/review/winter-stalls/board-390.jpg) | [Winter vase](screenshots/review/rome-coverage/vase-390.jpg) |
| 480 × 900 | [Single cracker](screenshots/review/winter-stalls/final-480.jpg) | [Three-cracker bundle](screenshots/review/rome-coverage/board-480.jpg) |
| 390 × 844 | [Single cracker](screenshots/review/winter-stalls/final-390.jpg) | [Three-cracker bundle](screenshots/review/rome-coverage/board-390.jpg) |

[Opening board](screenshots/review/winter-stalls/opening.jpg) ·
[Charged hammer](screenshots/review/winter-stalls/hammer-toolbar.jpg) ·
[Chapel reward](screenshots/review/winter-stalls/chapel.jpg) ·
[Reindeer stable rewards](screenshots/review/rome-coverage/stable.jpg) ·
[All market goods](screenshots/review/rome-coverage/pieces.jpg) ·
[Eight bonuses in five states](screenshots/review/rome-coverage/bonus-states.jpg) ·
[Spent bonus](screenshots/review/winter-stalls/spent.jpg) ·
[Registration and prompts](asset-catalogue.md#market-goods-and-tools)

## Red mitten review

| Opening board | Before | After |
| --- | --- | --- |
| 480 × 900 | [Blue mitten](screenshots/review/red-mitten/opening-480-before.jpg) | [Cranberry mitten](screenshots/review/red-mitten/opening-480.jpg) |
| 390 × 844 | [Blue mitten](screenshots/review/red-mitten/opening-390-before.jpg) | [Cranberry mitten](screenshots/review/red-mitten/opening-390.jpg) |

## Shared Sun coin review

| Opening board and wallet | Before | After |
| --- | --- | --- |
| 480 × 900 | [Bell coin](screenshots/review/red-mitten/opening-480.jpg) | [Sun coin](screenshots/review/sun-coin/opening-480.jpg) |
| 390 × 844 | [Bell coin](screenshots/review/red-mitten/opening-390.jpg) | [Sun coin](screenshots/review/sun-coin/opening-390.jpg) |

[Sun coin on the stable's price card](screenshots/review/sun-coin/stable.jpg)
