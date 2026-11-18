# Winter wish board progression

Light every marked pane on every board. A match or tool lights the pane when
it clears the treat above it. One hit untangles tinsel. A later hit clears
the freed treat and lights the pane underneath. A tinsel tie on a brown
cell may stay when the board is won. Panes never spread. Green double panes turn blue after the first hit.

The 100 boards are authored, one file each, in [../levels](../levels), on Cradle
of Rome's feature schedule: tinsel ties (chains) from 5, frost (ice) from 7,
two areas from 9, green double panes from 10, carved stones from 15 and double
ties from 51. [docs/LEVEL_DESIGN.md](../../../docs/LEVEL_DESIGN.md) is the
guide; `make levels-preview` draws every board on
[one sheet](../../../docs/review/level-sheets/christmas-market.png). Move
budgets are fitted by `python3 tools/tune_moves.py christmas-market` and listed
with each board's tier in [level-moves.md](level-moves.md).

On first clears of 24, 25 and 28 the completed board gives way to a
[painting and scene](asset-catalogue.md#story-floors) before Collect.
The [resource prototype](resource-prototype.md) records the Roman layouts, prices and measured payouts for the first twenty wishes.

The bot test plays each wish from up to four fixed starts without tools.
It checks that the objectives are reachable through actual swaps and cascades.
Difficulty describes the board design and awaits human playtesting.
