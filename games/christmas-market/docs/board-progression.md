# Winter wish board progression

Light every marked pane on every board. A match or tool lights the pane when
it clears the treat above it. One hit untangles tinsel. A later hit clears
the freed treat and lights the pane underneath. A tinsel tie on a brown
cell may stay when the board is won. Panes never spread. Green double panes turn blue after the first hit.

The 100 boards are authored, one file each, in [../levels](../levels). They
keep their festive silhouettes and follow the feature order of Cradle of
Rome 2: tinsel ties (chains) from 4, frost (ice) and carved stones from 12,
double ties from 62, and a boss of green double panes on every tenth board.
Boards with ties or frost carry about the reference's share of them: dotted
rows of tied panes, and frost rows over a chamber that starts empty.
[docs/LEVEL_DESIGN.md](../../../docs/LEVEL_DESIGN.md) is the guide;
`make levels-preview` draws every board on
[one sheet](../../../docs/review/level-sheets/christmas-market.png), and
`python3 tools/reference/cradle-of-rome/compare_levels.py christmas-market`
prints each board beside the reference.

Each board is sized by moves: the bot's median game is at most twice the
move budget of the same [Homescapes level](../../../docs/homescapes-reference/first-100-levels.md),
25 moves on average against 18.5. Panes cover 61–73% of a board from level 11
on; `python3 tools/balance_plaques.py christmas-market` lists the panes that
hold a board up. Move budgets are fitted by
`python3 tools/tune_moves.py christmas-market` and listed with each board's
tier in [level-moves.md](level-moves.md).

On first clears of 24, 25 and 28 the completed board gives way to a
[painting and scene](asset-catalogue.md#story-floors) before Collect.
The [resource prototype](resource-prototype.md) records the earlier Roman layouts and measured payouts for the first twenty wishes. The current twenty prices are in the [construction sequence](market-pieces.md#construction-sequence).

The bot test plays each wish from up to four fixed starts without tools.
It checks that the objectives are reachable through actual swaps and cascades.
Difficulty describes the board design and awaits human playtesting.
