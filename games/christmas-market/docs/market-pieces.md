# From Rome to Bellmere

The [building reward comparison](../../../docs/cradle-of-rome-reference/building-rewards.html)
shows the live rewards and their yields beside Cradle of Rome 2. Bellmere uses
three wallet slots in save order: **Tokens**, **Treats**
and **Materials**. Sun coins, cocoa and bundled pine identify those
totals on the board, in town, and in prices and results.

The opening has a green snowy fir, a light-blue knitted mitten, a silver snowflake
coin, a gold Sun coin and a red-and-ivory candy cane. The first four echo the
green leaf, blue flower, silver coin and gold coin in the GameTop Windows
release of Cradle of Rome 2. Its first purchase adds a water bucket worth 3
Food. In Christmas Market, the Welcome arch replaces the candy cane with red
spiced fruit punch worth 3 Treats. The blue mitten distinguishes the score piece from
the punch. The bakery's brown gingerbread man and the kiosk's ivory cocoa
mug follow in the same Treats slot. The stable brings the Farrier's hammer, which charges a
single-cell blow. The lumber workshop brings natural pine, which replaces the mitten. The
chapel replaces it with the same slate-gray dressed stone used in Relic Rush.
Its blocky profile and matte faces distinguish it from the bright round coin.
The Firework bundles three indigo crackers and stands out beside the red spiced fruit punch.

## Construction sequence

Twenty purchases open at levels 1, 6, 11 … 96, four per Advent. Each unlocks exactly one item, in the same resource and tool order as Cradle of Rome 2. Story stalls in bold play a placement scene. Earlier stalls must be built before the next story stall. The Gingerbread house, Giant bauble and Pile of presents stay in the decoration shop. `python3 tools/balance.py christmas-market` fits prices to the bot's measured income.

| After level | Stall | Reward | Price (Tokens / Treats / Materials) |
| ---: | --- | --- | ---: |
| 1 | **Welcome arch** | Spiced fruit punch +3 Treats | 45 / 0 / 0 |
| 6 | Reindeer stable | Farrier's hammer (single-cell blow) | 720 / 255 / 0 |
| 11 | **Lumber workshop** | Bundled pine +5 Materials | 1695 / 620 / 0 |
| 16 | Firework stall | Firework Bomb | 1500 / 555 / 565 |
| 21 | **Gingerbread bakery** | Gingerbread man +4 Treats | 1635 / 600 / 895 |
| 26 | Snowy chapel | Dressed stone +7 Materials | 1545 / 685 / 910 |
| 31 | **Hot cocoa kiosk** | Hot cocoa +5 Treats | 1665 / 800 / 1305 |
| 36 | Ice house (was Igloo) | Frost shield | 1620 / 920 / 1360 |
| 41 | Lakeside smokehouse (was Log cabin) | Smoked trout +6 Treats | 1620 / 980 / 1395 |
| 46 | Station kiosk | Station clock (adds five moves) | 1905 / 1335 / 1650 |
| 51 | **Toymaker's workshop** | Toy blocks +6 Tokens | 1885 / 1370 / 1640 |
| 56 | **Candlelight shop** | Candle lantern (Lightning) | 2165 / 1475 / 1745 |
| 61 | **Gift wrapping pavilion** | Wrapped gift +7 Tokens | 2210 / 1470 / 1745 |
| 66 | North Pole post office | Wish cross (Plus) | 2325 / 1435 / 1675 |
| 71 | Glassblower's stall | Glass bauble +8 Tokens | 2355 / 1430 / 1655 |
| 76 | **Reindeer carousel** | Wind-up top (Mixer) | 2450 / 1390 / 1610 |
| 81 | **Winter skating rink** | Ice skates +9 Tokens | 2490 / 1370 / 1600 |
| 86 | Woodcarvers' hall (was Santa's workshop) | Carved reindeer +10 Tokens | 2575 / 1330 / 1560 |
| 91 | **Christmas tree** | Star | 2705 / 1280 / 1505 |
| 96 | Santa's sleigh | Santa hat +11 Tokens | 2735 / 1270 / 1495 |

Confirmed placement turns on a new piece from the following level. Replays use
the regular goods of their own level. A save that already passed a stall's
gate can buy it from the shop.

## In-game review

[Reindeer stable's hammer, clock, skates and tool states](screenshots/review/building-rewards/README.md)

### Earlier palette studies

| Size | Board after the Welcome arch | Guide |
| --- | --- | --- |
| 480 × 900 | [Light-blue mitten and spiced fruit punch](screenshots/review/blue-mitten/board-480.jpg) | [Untangle tinsel](screenshots/review/blue-mitten/guide-480.jpg) |
| 390 × 844 | [Light-blue mitten and spiced fruit punch](screenshots/review/blue-mitten/board-390.jpg) | [Untangle tinsel](screenshots/review/blue-mitten/guide-390.jpg) |

| Board | Before | After |
| --- | --- | --- |
| 480 × 900 | [Mitten](screenshots/review/winter-stalls/board-480.jpg) | [Winter vase](screenshots/review/rome-coverage/vase-480.jpg) |
| 390 × 844 | [Mitten](screenshots/review/winter-stalls/board-390.jpg) | [Winter vase](screenshots/review/rome-coverage/vase-390.jpg) |
| 480 × 900 | [Single cracker](screenshots/review/winter-stalls/final-480.jpg) | [Three-cracker bundle](screenshots/review/rome-coverage/board-480.jpg) |
| 390 × 844 | [Single cracker](screenshots/review/winter-stalls/final-390.jpg) | [Three-cracker bundle](screenshots/review/rome-coverage/board-390.jpg) |

[Opening board](screenshots/review/winter-stalls/opening.jpg) ·
[Previous Hammer](screenshots/review/winter-stalls/hammer-toolbar.jpg) ·
[Chapel reward](screenshots/review/winter-stalls/chapel.jpg) ·
[Previous Reindeer stable rewards](screenshots/review/rome-coverage/stable.jpg) ·
[All market goods](screenshots/review/rome-coverage/pieces.jpg) ·
[Eight bonuses in five states](screenshots/review/rome-coverage/bonus-states.jpg) ·
[Spent bonus](screenshots/review/winter-stalls/spent.jpg) ·
[Registration and prompts](asset-catalogue.md#market-goods-and-tools)

## Earlier red mitten review

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
