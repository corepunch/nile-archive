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
5. **Tablets win the board.** Every board has tablets (`oil` in the engine).
   Clear them all to win. The move budget is set later by the tuner, not by
   you.
6. **Chains guard tablets.** In Cradle of Rome 869 of 871 chains sit on
   plaques; the other two are teaching gates. Put every chain and every ice
   on a tablet (`k K g G j J`). A chain or ice on a plain cell (`c C i I`) is
   allowed only as a gate, when breaking it lets pieces into cells below;
   otherwise the player never needs to break it, and the validator says so.
7. **Chains as gates.** Pieces fall only from the sky: a cell refills if
   nothing on the board lies above it in its column, or if a piece can reach
   it falling straight down or diagonally down from a fed, unchained cell. A
   chain, or a hole, closes that path. A cell that only a chain can feed
   starts empty and stays empty until the chain breaks. Then pieces trickle
   through and the tablets below can be cleared.
8. **Every feature by level 100.** Cradle of Rome's Adventure never uses ice
   or stones. We introduce both gradually: ice early (7), stones at 15, so the
   campaign uses every board feature we have. Each first appearance gets a
   one-line hint card naming the feature in the game's own terms.
9. **Follow the schedule below.** The validator rejects a feature before its
   first level.

## The 100-level schedule

Level N follows Cradle of Rome's Adventure level N: use the same features it
uses (read its row in `levels.json`). Its boards are about as big as ours.

| Levels | Tablets (share of cells) | Chains | What is new |
| --- | --- | --- | --- |
| 1–4 | 10–20% → 40% | none | Matching over tablets. Grow the area each board. |
| 5 | 30–50% | 1–2 single, as a gate | The first chain blocks the way into a lower chamber. |
| 6 | 50–60% | several, over tablets | Chained pieces sit on tablets. |
| 7 | 40–60% | optional | **Ice** on plain cells: it holds its piece, a match on the cell breaks it, and it gates the fall below it like a chain. Use 2–6, mirrored. |
| 8 | 40–60% | optional | Practice, one breather. |
| 9 | 50–70% | optional | Two wings joined by a narrow bridge (Cradle's first two-area board; ours stay one board). |
| 10 | 70–90%, nearly all double | none | The first double-tablet board: a test. |
| 11 | 60–80% | optional | **Ice on tablets:** the ice breaks first, then the tablet. |
| 12–14 | 60–90% | about half the boards, mostly gates | Combine known rules. Ice on about one board in three. |
| 15 | 60–80% | optional | **Carved stones:** a solid cell with no piece. An adjacent match breaks it. It also gates the fall below it. Use 2–6, mirrored. |
| 16–24 | 60–90% | about half the boards | Stones on about one board in four, ice on about one in three. |
| 25 | 60–90% | optional | **Double ice:** two hits. |
| 26–50 | 60–90% | about half the boards | Mix everything known; about one double-tablet board in ten. |
| 51 | 60–90% | double chains | The first double chain (Cradle). |
| 52–100 | 70–95% | about half the boards; most use double chains | Late combinations of every feature. Stones on about one board in four, ice on about one board in three, about one double-tablet board in ten. Bosses combine several. |

**Rhythm.** Inside every ten levels after the first ten, use the tiers
`easy, easy, normal, normal, hard, easy, normal, normal, hard, boss`. Levels
1–4 are `tutorial`. A boss is a dense, combined board, and the board after
it is a breather. The tier sets the share of games the bot must win within
the budget (tutorial 95%, easy 92%, normal 80%, hard 62%, boss 50%; see
[Move budgets](#move-budgets)).

**Shapes.** Make each board recognizable. Relic Rush uses ruins: temple fronts,
terraces, arches, stairways and courtyards. Christmas Market uses festive
silhouettes: a fir tree, a bell, a star, a snowflake, a sleigh, stalls in a
row. Reuse a family with a changed task instead of inventing an arbitrary
notch. Give every board a one-sentence intent (`teaches:`).

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
  they carry tablets, so every tablet still has two lines of three.
- **A gate must be breakable.** A chain or ice that gates cells must sit on a
  line of three whose other cells are filled while it holds. Ice at the foot
  of a one-cell spur, whose only line runs through the empty cell it gates,
  waits for pieces only it can let in: the board never ends. The validator
  checks this.
- **No separate parts.** The validator rejects a board that falls apart. A
  small tower joined by one cell still refills only through that cell, so give
  towers and wings a two-cell joint.
- **Every tablet has two ways in.** Each tablet must sit on straight runs of
  three playable cells (not stones) along at least two of the three axes. A
  tablet in a one-line pocket deadlocks: its three pieces never change, and
  no swap from outside can line them up. The bot showed boards stalling on
  the last few tablets for hundreds of moves.

## Check a board

```sh
python3 tools/hex_levels.py relic-rush --levels 1-20      # validate and summarize
python3 tools/hex_levels.py relic-rush --show 5           # print a board; ~ marks gated cells (The Neck: 31)
python3 tools/hex_levels.py relic-rush --lua              # write lua/boards.lua once all 100 pass
make level-sheets                                         # every board of both games on one image each
make level-sheets SHEET_GAMES=relic-rush LEVELS=41-60     # one game, a range
```

`make level-sheets` writes `docs/review/level-sheets/<game>.png`: tablets blue
(green when double), chains as gold rings (thick when double), ice as pale
rings, stones grey, holes outlined and gated cells marked with a red dot.
Regenerate it after changing boards and look at it before committing.

The validator checks the format, the mirror, the 70-cell minimum, tablets on
runs of three on two axes, every cell on a run of three, one connected board 9 to 12 rows tall, cells that stay unfed even with every
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

The greedy bot (`tests/lua/tune_moves.lua`) clears each board 40 times on
hashed seeds with no move limit. The budget is the number of moves it needed
in the tier's share of those games. Its rates order and space the boards;
they are not human win rates. Read `games/<game>/docs/level-moves.md`
afterwards: a board whose budget jumps far from its neighbours of the same
tier is usually a board that does not play as its `teaches:` line says.
