# Winter wish board progression

Light every marked pane on every board. A match or tool lights the pane when
it clears the treat above it. One hit untangles tinsel. A later hit clears
the freed treat and lights the pane underneath. A tinsel tie on a brown
cell may stay when the board is won. Panes never spread. Green double panes on wishes 10 and 20 turn blue after the first hit.

The authored coordinates in `lua/campaign.lua` shape the lights into windows,
paired doorways, lanes and finally the Christmas tree. The same four court
silhouettes offer different ways to reach the panes. The narrow spine on twin
lanes stays clear of mandatory panes so a player can focus on either side.
Fairy Lights and The Last Train give the story room to breathe.

| Level | Board | Family | Marked panes | Double panes | Tinsel ties | Moves |
| ---: | --- | --- | ---: | ---: | ---: | ---: |
| 1 | Welcome Lights | Tapered bowl | 7 | 0 | 0 | 20 |
| 2 | Lumber Lane | Tapered bowl | 8 | 0 | 0 | 24 |
| 3 | Gingerbread Swirl | Tapered bowl | 14 | 0 | 0 | 30 |
| 4 | Cocoa Corner | Twin lanes | 24 | 0 | 0 | 57 |
| 5 | Toymaker Lane | Two chambers | 25 | 0 | 1 | 60 |
| 6 | Ribbon Wishes | Compact court | 26 | 0 | 5 | 62 |
| 7 | Candlelight Circle | Two chambers | 28 | 0 | 0 | 64 |
| 8 | Carousel Stars | Tapered bowl | 23 | 0 | 5 | 58 |
| 9 | Skating Evening | Twin lanes | 20 | 0 | 1 | 58 |
| 10 | Under the Big Fir | Tapered bowl | 22 | 22 | 0 | 78 |
| 11 | Carols and Crumbs | Two chambers | 28 | 0 | 0 | 63 |
| 12 | Word from Fenwick | Tapered bowl | 32 | 0 | 2 | 69 |
| 13 | Sawdust Row | Twin lanes | 29 | 0 | 5 | 65 |
| 14 | The Bench by the Fir | Tapered bowl | 29 | 0 | 0 | 65 |
| 15 | Tangled Tinsel | Tapered bowl | 28 | 0 | 1 | 64 |
| 16 | Paper and String | Twin lanes | 22 | 0 | 0 | 69 |
| 17 | Twelve Horses | Tapered bowl | 30 | 0 | 0 | 66 |
| 18 | Fairy Lights | Tapered bowl | 32 | 0 | 1 | 72 |
| 19 | A Hundred Flames | Two chambers | 32 | 0 | 0 | 70 |
| 20 | A Letter Forty Years Late | Tapered bowl | 25 | 25 | 0 | 84 |
| 21 | Carolers Court | Tapered bowl | 9 | 0 | 0 | 34 |
| 22 | Many Hands | Tapered bowl | 12 | 0 | 6 | 38 |
| 23 | Painted Horses | Twin lanes | 10 | 0 | 5 | 39 |
| 24 | A Ribbon for Home | Tapered bowl | 14 | 0 | 4 | 40 |
| 25 | Word from the Station | Tapered bowl | 14 | 0 | 6 | 42 |
| 26 | First Skate | Tapered bowl | 14 | 0 | 4 | 44 |
| 27 | Every Light in Bellmere | Two chambers | 16 | 0 | 5 | 44 |
| 28 | The Last Train | Tapered bowl | 10 | 0 | 2 | 44 |
| 29 | The Big Fir | Twin lanes | 13 | 0 | 8 | 46 |
| 30 | Light the Christmas Tree | Tapered bowl | 17 | 0 | 8 | 48 |

On first clears of 24, 25 and 28 the completed board gives way to a
[painting and scene](asset-catalogue.md#story-floors) before Collect.
The [resource prototype](resource-prototype.md) records the Roman layouts, prices and measured payouts for the first twenty wishes.

The bot test plays each wish from up to four fixed starts without tools.
It checks that the objectives are reachable through actual swaps and cascades.
Difficulty describes the board design and awaits human playtesting.
