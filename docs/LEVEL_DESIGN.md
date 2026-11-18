# Designing match-3 levels

Relic Rush and Christmas Market each have 100 hex boards that follow Cradle of
Rome's progression. This guide says what a board must be, how to write one and
how to check it. The data behind it comes from Cradle of Rome's own level files:
[LEVELS.md](cradle-of-rome-reference/LEVELS.md) (tables, first appearances and
sample maps) and [levels.json](cradle-of-rome-reference/levels.json) (every field
of every level). Regenerate both with
`python3 tools/reference/cradle-of-rome/level_data.py`.

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
- **No ice and no stones in Adventure.** Ice (`freeze`) and disabled cells
  appear only in two Extras levels (105 and 112). We add both; see our rules.
- **Mostly symmetric.** 71 of the 100 shapes and 68 layouts are left-right
  mirrors. Ours are all mirrors.

## Our rules

1. **A symmetric board.** The shape, tablets and blockers are a left-right
   mirror, or the same after a half turn (180 degrees about the middle cell,
   `q, r -> -q, -r`), which is how an S or a Z is symmetric. A half-turn board
   has no partner for the top cell of each even column (the first line of
   the file), so leave those slots as holes; check it with `--show`.
2. **Use the space.** The envelope is 9 columns by 12 rows of flat-top hexes
   (108 cells), with the odd columns half a cell lower, as in King's Blossom
   Blast. A board is 9 to 12 rows tall: vary it, and make about a third of the
   boards shorter than 12 (tutorials and breathers especially). Use at least
   60 cells. Holes and the outline make the shape: a temple, a tree, a tower
   over a vault.
3. **One board.** Every cell connects to every other. Parts may be joined by
   a single cell (a neck), but join wide parts by two or more cells. Two
   halves side by side read as two puzzles, not one board.
4. **Use the hex.** A hex grid has diagonals a square grid lacks. Prefer
   shapes only it can make: an S or a Z, a zigzag, a chevron, a slanted
   staircase, and **diagonal tunnels** running at 60 degrees. Pieces slide
   down a diagonal tunnel one cell at a time when nothing lies straight above
   them, so a tunnel from one chamber to another trickles pieces at an angle.
   Put a few such boards in every ten.
5. **Tablets win the board.** Every board has
   tablets (`oil` in the engine); clear them all to win. Our levels count
   moves, not time: Cradle covers 80–95% of a board because its levels run on
   a timer. A board holds at least 6 tablet layers (a double tablet is two)
   and as many as its length allows; see
   [How long a board is](#how-long-a-board-is). Put the tablets
   where they make the board's point: behind the gate, in the far corner of
   the vault, along the tunnel. The move budget is set later by the tuner.
6. **Chains guard tablets.** In Cradle of Rome 869 of 871 chains sit on
   plaques; the other two are teaching gates. Put every chain and every ice
   on a tablet (`k K g G j J f`). A chain or ice on a plain cell (`c C i I`) is
   allowed only as a gate, when breaking it lets pieces into cells below;
   otherwise the player never needs to break it, and the validator says so.
7. **Chains as gates.** Pieces fall only from the sky: a cell refills if
   nothing on the board lies above it in its column, or if a piece can reach
   it falling straight down or diagonally down from a fed, unchained cell. A
   chain, or a hole, closes that path. A cell that only a chain can feed
   starts empty and stays empty until the chain breaks. Then pieces trickle
   through and the tablets below can be cleared.
8. **Every feature by level 100.** The first Cradle of Rome uses ice and
   disabled cells in Extras. The Windows sequel introduces both in Adventure
   level 12: a row of ice tablets, and under it the cells that stay frozen
   (`disable`) until the ice breaks. Our match is an ice row over a chamber
   that starts empty. Give each first appearance a short hint in the game's own terms.
9. **Follow the schedule below.** The validator rejects a feature before its
   first level.

## The default 100-level schedule

The table follows the first Cradle of Rome's Adventure boards in
`levels.json` and is the validator's default for a new game. Relic Rush and
Christmas Market follow the Windows sequel instead; see **Both campaigns**
below the table.

| Levels | Tablet layers | Chains | What is new |
| --- | --- | --- | --- |
| 1–4 | 6 → 16 | none | Matching over tablets. Grow the area each board. |
| 5 | 12–18 | 1–2 single, as a gate | The first chain blocks the way into a lower chamber; most tablets sit behind it. |
| 6 | 14–20 | several, over tablets | Chained pieces sit on tablets. |
| 7 | 14–20 | optional | **Ice** on plain cells: it holds its piece, a match on the cell breaks it, and it gates the fall below it like a chain. Use 2–6, symmetric. |
| 8 | 14–20 | optional | Practice, one breather. |
| 9 | 16–24 | optional | Two wings joined by a narrow bridge (Cradle's first two-area board; ours stay one board). |
| 10 | 30–40, nearly all double | none | The first double-tablet board: a test. |
| 11 | 16–24 | optional | **Ice on tablets:** the ice breaks first, then the tablet. |
| 12–14 | up to the tier | about half the boards, mostly gates | Combine known rules. Ice on about one board in three. |
| 15 | up to the tier | optional | **Carved stones:** a solid cell with no piece. An adjacent match breaks it. It also gates the fall below it. Use 2–6, symmetric. |
| 16–24 | up to the tier | about half the boards | Stones on about one board in four, ice on about one in three. |
| 25 | up to the tier | optional | **Double ice:** two hits. |
| 26–50 | up to the tier | about half the boards | Mix everything known; about one double-tablet board in ten. |
| 51 | up to the tier | double chains | The first double chain (Cradle). |
| 52–100 | up to the tier | about half the boards; most use double chains | Late combinations of every feature. Stones on about one board in four, ice on about one board in three, about one double-tablet board in ten. Bosses combine several. |

**Rhythm.** Inside every ten levels after the first ten, use the tiers
`easy, easy, normal, normal, hard, easy, normal, normal, hard, boss`. Levels
1–4 are `tutorial`. A boss is a dense, combined board, and the board after
it is a breather. The tier sets the margin over the bot's median game that
the budget allows (tutorial 2.5, easy 2, normal 1.4, hard 1.2, boss 1; see
[Move budgets](#move-budgets)).

**Shapes.** Make each board recognizable. Relic Rush uses ruins: temple fronts,
terraces, arches, stairways and courtyards. Christmas Market uses festive
silhouettes: a fir tree, a bell, a star, a snowflake, a sleigh, stalls in a
row. Reuse a family with a changed task instead of inventing an arbitrary
notch. Give every board a one-sentence intent (`teaches:`).

**Both campaigns** follow the Windows sequel's schedule: chains debut on
level 4, ice and carved stones on level 12 and double chains on level 62.
Every plaque on a tenth-level boss is a green double. The sequel covers
80–100% of a board with plaques because it is timed; our boards count moves,
so each keeps the share of plaques that fits its length (next section). See the
[Relic Rush board progression](../games/relic-rush/docs/board-progression.md).

## How long a board is

The bot's median game on level N should be 1.5 to 2 times the move budget of
[Homescapes level N](homescapes-reference/first-100-levels.md): about 28 to
37 moves on average, since our boards are less casual. A board that runs
longer has plaques the bot reaches late: under chains or ice, behind a gate,
in a corner with one match line. Find and remove them:

```sh
python3 tools/balance_plaques.py relic-rush --levels 31-40   # each board's median and its latest plaques
python3 tools/balance_plaques.py relic-rush --trim           # remove the latest plaques, pair by pair
```

`--trim` plays every board, removes the plaques cleared last in symmetric
pairs, and repeats until the median is at most twice the Homescapes figure. A
chain or ice whose plaque goes stays only if it still holds back a plaque
below it. Tutorials 1–4 are left as authored.

Chained and frozen plaques are the slowest on a board, so a plain trim removes
them first. Boards that should keep them get more room and a trim that takes
plain plaques first: `--trim --keep-blockers --high 3 --levels 44,99`. Put
chains and ice on plaques the report shows the bot clears early. Relic Rush
allows three times the Homescapes budget on its 55 chain and ice boards.

## The level file

One file per level: `games/<game>/levels/level_NNN.txt` (three digits). A few
header lines, a blank line, then the board as a 24-line honeycomb:

```text
name: The Neck
tier: easy
teaches: Break the chain at the neck so pieces can fall into the vault below.

. . . . .
 . . . .
. . p . .
 . p p .
. p . p .
 . p p .
. . p . .
 . . . .
. . . . .
 . . . .
x . . . x
 x . . x
x x c x x
 x x x x
x x p x x
 x p p x
x p p p x
 p p p p
p p p p p
 p p p p
p p p p p
 p p p p
x p p p x
 x x x x
```

Each line holds up to 9 characters. Two lines make one row of the board: the
even columns (1, 3, 5, 7, 9) on the first line and the odd columns (2, 4, 6,
8), half a cell lower, on the second, as the empty template shows. Every board
slot gets a symbol; the spaces between slots stay spaces. **A mirror board
reads the same reversed**, line by line.

Empty template (all 108 cells plain):

```text
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
. . . . .
 . . . .
. . . . .
 . . . .
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
| `i` | Ice (one hit) on a plain cell |
| `I` | Double ice (two hits) on a plain cell |
| `j` | Ice on a blue tablet |
| `J` | Double ice on a blue tablet |
| `f` | Ice on a green double tablet |
| `s` | Carved stone: solid, no piece, one hit from an adjacent match or a tool |

### Reading the honeycomb

- **Down the page is down.** A cell's column is its character column. The cell
  straight above it is two lines up in the same column. Its upper diagonals are
  one line up, one column left and one column right. A piece falls straight
  down or slides diagonally down into an empty cell.
- **The sky.** A cell is open to the sky when nothing on the board lies above it
  in its column. Only those cells create new pieces. A hole inside the board
  is a roof: the cells under it are fed from their upper diagonals, or not at
  all.
- **Every blocker is a gate.** Chains, ice and stones all stop pieces falling
  through their cell until they break. Ice and chains keep their own piece;
  a stone has none.
- **A neck.** To make one cell the only way into a chamber, close every slot
  that could feed the chamber around it: the slots beside the neck on its own
  line, the slots straight above the chamber's top cells, and the chamber's
  outer upper diagonals. In `The Neck`, lines 13–15 close every slot around
  the chain at line 13, so the vault fills only through it.
- **A funnel.** Below a one-cell neck, pieces spread one slot wider every line.
  A lower chamber wider than that cone has corners that are never fed, and the
  validator rejects it. Widen chambers gradually, or open more necks.
- **A diagonal tunnel.** A run of cells along a 60-degree diagonal, with the
  slots straight above each cell closed, fills by sliding: each piece drops
  to the next cell down the slant. Make tunnels at least two cells wide where
  they carry tablets, so every tablet still has two axes that fit a complete match.
- **A gate must be breakable.** A chain or ice must sit on a full match line
  whose other cells fill while it holds, now or once an earlier gate has
  broken; gates in series (two vault doors) are fine. Ice at the foot of a
  one-cell spur, whose only line runs through the empty cell it gates, waits
  for pieces only it can let in: the board never ends. The validator breaks
  the gates in order and rejects any that never break.
- **No separate parts.** The validator rejects a board that falls apart. A
  small tower joined by one cell still refills only through that cell, so give
  towers and wings a two-cell joint.
- **Every tablet has two ways in.** Each tablet must sit on straight runs of
  four playable cells in Relic Rush or three in Christmas Market, along at least
  two axes. Stones interrupt these runs. In narrow pockets too few neighbours
  can supply a missing piece. The bot showed boards stalling on
  the last few tablets for hundreds of moves.

## Check a board

```sh
python3 tools/hex_levels.py relic-rush --levels 1-20      # validate and summarize
python3 tools/hex_levels.py relic-rush --show 5           # print a board; ~ marks gated cells (The Neck: 31)
python3 tools/hex_levels.py relic-rush --lua              # write lua/boards.lua once all 100 pass
make levels-preview                                        # 100 boards per game, one image each
make levels-preview SHEET_GAMES=relic-rush                 # one game, all 100 boards
make levels-preview SHEET_GAMES=relic-rush LEVELS=1-30     # one game, a range
```

`make levels-preview` writes `docs/review/level-sheets/<game>.png`. Range previews
include the range in the filename, for example `relic-rush-1-30.png`. Each sheet
shows blue tablets, green double tablets, gold chain rings, pale ice rings,
grey stones, outlined holes and red dots on gated cells. Regenerate the sheet
after changing boards and look at it before committing. `make level-sheets`
is an alias.

`make reference-levels-preview` renders the same grid for
[both Cradle of Rome Adventure campaigns](cradle-of-rome-reference/README.md#adventure-comparison-sheets)
from the local reference extractions.

The validator checks the format, the mirror, the 60-cell minimum, tablets with a full match line
on two axes, every playable cell on at least one full line, one connected board 9 to 12 rows tall, cells that stay unfed even with every
chain broken, and the schedule's first levels. It prints each board's cells,
tablets, chains and gated cells. A board is done when it passes and
does what its `teaches:` line says.

## Move budgets

You never write a move budget. Once the boards pass, compile them and fit the
budgets:

```sh
python3 tools/hex_levels.py relic-rush --lua           # lua/boards.lua
make build/test/relic-rush
python3 tools/tune_moves.py relic-rush                # lua/level_moves.lua, docs/level-moves.md
python3 tools/tune_moves.py relic-rush --levels 41-50 # after changing a few boards
```

The greedy bot (`tests/lua/tune_moves.lua`) attempts each board on 40
hashed seeds with a 250-move calibration ceiling. The budget is its median game
times the tier's margin, rounded up. The median is used because the bot's
slowest games vary wildly from board to board: a budget read from that tail
gave neighbouring boards two and three and a half times their typical game.
The table's "Within budget" column is how many of the bot's games fit; it
orders and spaces the boards and is not a human win rate. Read `games/<game>/docs/level-moves.md`
afterwards: a board whose budget jumps far from its neighbours of the same
tier is usually a board that does not play as its `teaches:` line says.
