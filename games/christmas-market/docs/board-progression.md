# Winter wish board progression

Clear every red pane on every board. A match or tool lights the pane when
it clears the treat above it. One hit untangles tinsel. A later hit clears
the freed treat and lights the pane underneath. A tinsel tie on a brown
cell may stay when the board is won. Red panes never spread.

The authored coordinates in `lua/campaign.lua` shape the lights into windows,
paired doorways, lanes and finally the Christmas tree. The same four court
silhouettes offer different ways to reach the panes. The narrow spine on twin
lanes stays clear of mandatory panes so a player can focus on either side.
Fairy Lights and The Last Train give the story room to breathe.

| Level | Board | Family | Red panes | Tinsel ties | Moves |
| ---: | --- | --- | ---: | ---: | ---: |
| 1 | Welcome Lights | Tapered bowl | 7 | 0 | 20 |
| 2 | Lumber Lane | Tapered bowl | 8 | 0 | 24 |
| 3 | Gingerbread Swirl | Tapered bowl | 9 | 0 | 26 |
| 4 | Cocoa Corner | Twin lanes | 9 | 4 | 30 |
| 5 | Toymaker Lane | Two chambers | 10 | 4 | 36 |
| 6 | Ribbon Wishes | Compact court | 10 | 0 | 38 |
| 7 | Candlelight Circle | Two chambers | 10 | 4 | 40 |
| 8 | Carousel Stars | Tapered bowl | 11 | 4 | 42 |
| 9 | Skating Evening | Twin lanes | 10 | 5 | 46 |
| 10 | Under the Big Fir | Tapered bowl | 13 | 6 | 46 |
| 11 | Carols and Crumbs | Two chambers | 8 | 0 | 32 |
| 12 | Word from Fenwick | Tapered bowl | 10 | 5 | 35 |
| 13 | Sawdust Row | Twin lanes | 11 | 6 | 36 |
| 14 | The Bench by the Fir | Tapered bowl | 12 | 7 | 37 |
| 15 | Tangled Tinsel | Tapered bowl | 13 | 9 | 38 |
| 16 | Paper and String | Twin lanes | 9 | 4 | 40 |
| 17 | Twelve Horses | Tapered bowl | 14 | 5 | 41 |
| 18 | Fairy Lights | Tapered bowl | 8 | 2 | 42 |
| 19 | A Hundred Flames | Two chambers | 13 | 6 | 44 |
| 20 | A Letter Forty Years Late | Tapered bowl | 14 | 7 | 46 |
| 21 | Carolers Court | Tapered bowl | 9 | 0 | 34 |
| 22 | Many Hands | Tapered bowl | 12 | 6 | 38 |
| 23 | Painted Horses | Twin lanes | 10 | 5 | 39 |
| 24 | A Ribbon for Home | Tapered bowl | 14 | 4 | 40 |
| 25 | Word from the Station | Tapered bowl | 14 | 6 | 42 |
| 26 | First Skate | Tapered bowl | 14 | 4 | 44 |
| 27 | Every Light in Bellmere | Two chambers | 16 | 5 | 44 |
| 28 | The Last Train | Tapered bowl | 10 | 2 | 44 |
| 29 | The Big Fir | Twin lanes | 13 | 8 | 46 |
| 30 | Light the Christmas Tree | Tapered bowl | 17 | 8 | 48 |

On first clears of 24, 25 and 28 the completed board gives way to a
[painting and scene](asset-catalogue.md#story-floors) before Collect.
The [story script](story.md#levels) connects the objectives to the market.

The bot test plays each wish from up to four fixed starts without tools.
It checks that the objectives are reachable through actual swaps and cascades.
Difficulty describes the board design and awaits human playtesting.
