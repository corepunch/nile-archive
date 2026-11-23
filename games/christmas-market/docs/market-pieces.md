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
mulled wine worth 3 Treats. The blue mitten distinguishes the score piece from
the wine. The bakery's brown gingerbread man and the kiosk's ivory cocoa
mug follow in the same Treats slot. The stable brings the Farrier's hammer, which charges a
single-cell blow. The lumber workshop brings natural pine, which replaces the mitten. The
chapel replaces it with the same slate-gray dressed stone used in Relic Rush.
Its blocky profile and matte faces distinguish it from the bright round coin.
The Firework bundles three indigo crackers and stands out beside the red mulled wine.

## Construction sequence

Twenty purchases open at levels 1, 6, 11 … 96, four per Advent. Each unlocks exactly one item, in the same resource and tool order as Cradle of Rome 2. Story stalls in bold play a placement scene. Earlier stalls must be built before the next story stall. The Gingerbread house, Giant bauble and Pile of presents stay in the decoration shop. `python3 tools/balance.py christmas-market` fits prices to the bot's measured income.

| After level | Stall | Reward | Price (Tokens / Treats / Materials) |
| ---: | --- | --- | ---: |
| 1 | **Welcome arch** | Mulled wine +3 Treats | 50 / 0 / 0 |
| 6 | Reindeer stable | Farrier's hammer (single-cell blow) | 835 / 300 / 0 |
| 11 | **Lumber workshop** | Bundled pine +5 Materials | 1975 / 735 / 0 |
| 16 | Firework stall | Firework Bomb | 1795 / 655 / 670 |
| 21 | **Gingerbread bakery** | Gingerbread man +4 Treats | 1995 / 735 / 1090 |
| 26 | Snowy chapel | Dressed stone +7 Materials | 1875 / 850 / 1105 |
| 31 | **Hot cocoa kiosk** | Hot cocoa +5 Treats | 2040 / 980 / 1610 |
| 36 | Ice house (was Igloo) | Frost shield | 1940 / 1115 / 1655 |
| 41 | Lakeside smokehouse (was Log cabin) | Smoked trout +6 Treats | 1940 / 1180 / 1695 |
| 46 | Station kiosk | Station clock (adds five moves) | 2300 / 1605 / 2040 |
| 51 | **Toymaker's workshop** | Toy blocks +6 Tokens | 2275 / 1655 / 2015 |
| 56 | **Candlelight shop** | Candle lantern (Lightning) | 2615 / 1760 / 2070 |
| 61 | **Gift wrapping pavilion** | Wrapped gift +7 Tokens | 2660 / 1740 / 2055 |
| 66 | North Pole post office | Wish cross (Plus) | 2765 / 1690 / 2010 |
| 71 | Glassblower's stall | Glass bauble +8 Tokens | 2790 / 1680 / 2005 |
| 76 | **Reindeer carousel** | Wind-up top (Mixer) | 2895 / 1655 / 1930 |
| 81 | **Winter skating rink** | Ice skates +9 Tokens | 2950 / 1630 / 1910 |
| 86 | Woodcarvers' hall (was Santa's workshop) | Carved reindeer +10 Tokens | 3055 / 1590 / 1850 |
| 91 | **Christmas tree** | Star | 3305 / 1535 / 1830 |
| 96 | Santa's sleigh | Santa hat +11 Tokens | 3310 / 1545 / 1825 |

Confirmed placement turns on a new piece from the following level. Replays use
the regular goods of their own level. A save that already passed a stall's
gate can buy it from the shop.

## In-game review

[Reindeer stable's hammer, clock, skates and tool states](screenshots/review/building-rewards/README.md)

### Earlier palette studies

| Size | Board after the Welcome arch | Guide |
| --- | --- | --- |
| 480 × 900 | [Light-blue mitten and mulled wine](screenshots/review/blue-mitten/board-480.jpg) | [Untangle tinsel](screenshots/review/blue-mitten/guide-480.jpg) |
| 390 × 844 | [Light-blue mitten and mulled wine](screenshots/review/blue-mitten/board-390.jpg) | [Untangle tinsel](screenshots/review/blue-mitten/guide-390.jpg) |

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
