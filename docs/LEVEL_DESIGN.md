# Designing match-3 levels

Relic Rush and Christmas Market each have 100 hex boards that follow Cradle of
Rome's progression. This guide says what a board must be, how to write one and
how to check it. The data behind it comes from Cradle of Rome's own level files:
[LEVELS.md](cradle-of-rome-reference/LEVELS.md) (tables, first appearances and
sample maps) and [levels.json](cradle-of-rome-reference/levels.json) (every field
of every level). Regenerate both with
`python3 tools/cradle-of-rome-reference/level_data.py`.

## What Cradle of Rome does

- **The board is the objective.** Every Adventure level is won by clearing its
  plaques (our blue tablets). Plaques cover about half the board in levels 1–10
  and 82–98% from level 11 on. There are no score or collection goals.
- **One new rule at a time.** Levels 1–4 have plaques only, and their area
  grows (6 → 8 → 27 → 62 plaques). Level 5 has the first chain, and that chain
  already blocks the fall into the cells under it. Level 6 puts chains over
  plaques. Level 9 is the first board in two separate areas. Level 10 is the
  first double-plaque board, and it is nearly all double plaques. Level 51
  brings the first double chain.
- **Chains are gates.** About half the boards have chains. On almost all of
  them, a chain stops pieces falling into cells below it until it breaks.
- **Double plaques are a test, not a rule.** Only about one board in ten has
  them, and that board is dense with them.
- **Double chains replace single chains late.** From 51, most chained boards
  use double chains.
- **No ice and no stones in the campaign.** Ice (`freeze`) and disabled cells
  appear only in two Extras levels (105 and 112), never in Adventure.
- **Mostly symmetric.** 71 of the 100 shapes and 68 layouts are left-right
  mirrors. Ours are all mirrors.

## Our rules

1. **A mirror board.** The shape, tablets and chains are all left-right
   symmetric.
2. **At least 49 cells** of the radius-4 hexagon's 61.
3. **Tablets win the board.** Every board has tablets (`oil` in the engine).
   Clear them all to win. The move budget is set later by the tuner, not by
   you.
4. **Chains as gates.** Pieces fall only from the sky: a cell refills if
   nothing on the board lies above it in its column, or if a piece can reach
   it falling straight down or diagonally down from a fed, unchained cell. A
   chain, or a hole, closes that path. A cell that only a chain can feed
   starts empty and stays empty until the chain breaks. Then pieces trickle
   through and the tablets below can be cleared.
5. **No ice, no stones** in levels 1–100, as in Cradle of Rome's Adventure.
6. **Follow the schedule below.** The validator rejects a feature before its
   first level.

## The 100-level schedule

Level N follows Cradle of Rome's Adventure level N: use the same features it
uses (read its row in `levels.json`). Adapt its coverage to our smaller board.

| Levels | Tablets (share of cells) | Chains | What is new |
| --- | --- | --- | --- |
| 1–4 | 10–20% → 40% | none | Matching over tablets. Grow the area each board. |
| 5 | 30–50% | 1–2 single, as a gate | The first chain blocks the way into a lower chamber. |
| 6 | 50–60% | several, over tablets | Chained pieces sit on tablets. |
| 7–8 | 40–60% | optional | Practice, one breather. |
| 9 | 50–70% | optional | Two separate areas, each open to the sky. |
| 10 | 70–90%, nearly all double | none | The first double-tablet board: a test. |
| 11–50 | 60–90% | about half the boards, mostly gates | Combine known rules. About one double-tablet board in ten. |
| 51 | 60–90% | double chains | The first double chain. |
| 52–100 | 70–95% | about half the boards; most use double chains | Late combinations. About one double-tablet board in ten. |

**Rhythm.** Inside every ten levels after the first ten, use the tiers
`easy, easy, normal, normal, hard, easy, normal, normal, hard, boss`. Levels
1–4 are `tutorial`. A boss is a dense, combined board, and the board after
it is a breather. The tier sets the bot win rate the tuner aims for (tutorial
100%, easy 92%, normal 80%, hard 62%, boss 50%; see
`games/relic-rush/lua/difficulty.lua`).

**Shapes.** Make each board recognizable. Relic Rush uses ruins: temple fronts,
terraces, arches, stairways and courtyards. Christmas Market uses festive
silhouettes: a fir tree, a bell, a star, a snowflake, a sleigh, stalls in a
row. Reuse a family with a changed task instead of inventing an arbitrary
notch. Give every board a one-sentence intent (`teaches:`).

## The level file

One file per level: `games/<game>/levels/level_NNN.txt` (three digits). A few
header lines, a blank line, then the board as a 17-line honeycomb:

```text
name: The Neck
tier: normal
teaches: Break the chain at the neck so pieces can fall into the treasure room below.

    .
   . .
  . . .
 . . . .
. . . . .
 . . . .
. . p . .
 . p p .
. . p . .
 . . . .
. . . . .
 . x x .
. x c x .
 x p p x
  p p p
   p p
    p
```

Each line holds up to 9 characters. The board slots alternate between even
columns (1, 3, 5, 7, 9) on odd lines and odd columns (2, 4, 6, 8) on even
lines, as the empty template shows. Every board slot gets a symbol; the
spaces between slots stay spaces. **A mirror board reads the same reversed**,
line by line.

Empty template (all 61 cells plain):

```text
    .
   . .
  . . .
 . . . .
. . . . .
 . . . .
. . . . .
 . . . .
. . . . .
 . . . .
. . . . .
 . . . .
. . . . .
 . . . .
  . . .
   . .
    .
```

| Symbol | Cell |
| --- | --- |
| `.` | Plain cell |
| `x` | Hole: not part of the board |
| `p` | Blue tablet (one hit) |
| `P` | Green double tablet (two hits) |
| `c` | Chain (one hit) on a plain cell |
| `C` | Double chain (two hits) on a plain cell |
| `k` | Chain on a blue tablet |
| `K` | Double chain on a blue tablet |
| `g` | Chain on a green double tablet |
| `G` | Double chain on a green double tablet |

### Reading the honeycomb

- **Down the page is down.** A cell's column is its character column. The cell
  straight above it is two lines up in the same column. Its upper diagonals are
  one line up, one column left and one column right. A piece falls straight
  down or slides diagonally down into an empty cell.
- **The sky.** A cell is open to the sky when nothing on the board lies above it
  in its column. Only those cells create new pieces. A hole inside the board
  is a roof: the cells under it are fed from their upper diagonals, or not at
  all.
- **A neck.** To make one cell the only way into a chamber, close every slot
  that could feed the chamber around it: the slots beside the neck on its own
  line, the slots straight above the chamber's top cells, and the chamber's
  outer upper diagonals. In `The Neck`, lines 12–14 close six slots around
  the chain. The open cells at the ends of lines 12 and 13 are dead ends:
  they fill from above but feed nothing below.
- **A funnel.** Below a one-cell neck, pieces spread one slot wider every line.
  A lower chamber wider than that cone has corners that are never fed, and the
  validator rejects it. Widen chambers gradually, or open more necks.
- **Two areas.** Separate areas each need a cell open to the sky.

## Check a board

```sh
python3 tools/hex_levels.py relic-rush --levels 1-20      # validate and summarize
python3 tools/hex_levels.py relic-rush --show 5           # print a board; ~ marks gated cells (The Neck: 8)
python3 tools/hex_levels.py relic-rush --lua              # write lua/boards.lua once all 100 pass
```

The validator checks the format, the mirror, the 49-cell minimum, tablets,
connectivity, an inlet in every area, cells that stay unfed even with every
chain broken, and the schedule's first levels. It prints each board's cells,
tablets, chains, gated cells and areas. A board is done when it passes and
does what its `teaches:` line says. Move budgets come from
`python3 games/relic-rush/tools/tune_levels.py` afterwards.
