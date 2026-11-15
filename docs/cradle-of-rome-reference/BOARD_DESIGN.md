# Board design

## What the level records mean

The numbered files all use a 20×14 square coordinate envelope. Count a cell
as part of the board when `Ball active="1"`. This count includes any active
cell with a `disable` flag. Other serialized cells include the decorative
frame. On active cells the plaque layer is `Tile puzzle_count`, with values
0 for plain, 1 for single and 2 for double. The English tutorial teaches matching over
every plaque before time runs out, with two matches for a double plaque.
`Ball lock` is a different layer: one or two matches involving the chained
piece according to the tutorial. The fixed piece type is recorded on every
locked cell in this sample. These layers can overlap. The file alone does
not establish whether one hit pays down both.

`Ball generator="1"` marks authored supply points. The analyzer groups active
cells by orthogonal adjacency and reports generators within each group.
This describes the authored layout. Some groups have plaques and zero
generator markers, so exact refill needs stronger evidence. Every numbered
board has `allow_ball_types="5"`. The city controls which new piece types
become available, so this setting alone cannot tell us what spawns.
[Level and tutorial source inventory](README.md#source-inventory)

## What changes over the campaign

The beta row is a subset of Adventure. Table entries count boards containing
a feature, except the area and plaque ranges, which count cells.

| Configured range | Active cells, min–max (mean) | Plaques, min–max | Double plaques | Single locks | Double locks | Plaques under locks | Multiple active groups |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Beta 1–40 | 62–124 (100.08) | 6–124 | 4 | 18 | 0 | 16 | 13 |
| Adventure 1–100 | 62–126 (104.42) | 6–126 | 11 | 24 | 31 | 53 | 28 |
| Extras 101–115 | 82–120 (102.80) | 82–120 | 3 | 2 | 5 | 6 | 1 |

The Adventure time budget is 300 seconds at 1–11, 480 at 12, 660 at
13–29, 770 at 30–36, 660 at 37 and 770 at 38–100. Extras use 660 seconds
through 114 and 770 at 115. These are authored caps. The first single
lock is at 5, first locked plaque at 6, first double plaque at 10 and
first double lock at 51. `freeze` and `disable` appear in two Extras
boards (105 and 112) and zero Adventure boards. The only nonzero
`puzzle_ball_probability` entries are Extras 103, 109, 113 and 114.
These are serialized first appearances. Tutorial triggers and player
exposure may follow a different order.

## Board examples

| Source level | Authored setup | What to study |
| --- | --- | --- |
| **1–3** | Active area grows 72 → 80 → 99. Plaques grow 6 → 8 → 27. All use 300 seconds and have no locks. Level 1 spreads six targets across three pairs. | Keep room to build matches while teaching where to aim them. Increase the objective footprint before adding another rule. |
| **5 → 6** | Level 5 has 58 plaques and one chain on a plain tile. Level 6 has 80 plaques and 12 single chains, all over plaques. Six locked pieces are type 4 (gold coin) and six are type 6 (lumber). | Give the player one example of a new layer, then put it between them and the goal. A locked resource also makes the payoff for opening that target visible. |
| **9 and 25** | Level 9 has two 31-cell groups with 20 and 19 plaques and generator counts 9 and 0. Level 25 puts 46 of its 48 plaques in the group with zero markers, with 14 generators in the other group. | Compare how much work the two sides ask for. Test their actual supply before using an uneven split in hexes. |
| **10 → 20** | Level 10 has 88 double plaques out of 92 active cells and two generators. Level 20 has 116 double plaques filling all 116 cells, with 12 generators. Neither has chains. | Use a high-density repeat of a known objective as a deliberate test of the mechanic. More required hits and more refill markers can coexist. |
| **31 → 35** | Level 31 has one 112-cell area, with 32 single chains over 104 plaques. Level 35 has two substantial areas (60 and 50 cells), each with supply markers (6 and 5) and targets (36 and 30). All 22 chains sit over plaques in horizontal bands in those areas. | Switch from one dense field to two local problems. Relief should come from opening a line or a route the player can see. |
| **40, 51 and 80** | Level 40 combines 112 double plaques with eight single chains. Level 51 introduces 20 double chains over single plaques. Level 80 combines 72 double plaques with six double chains in the same area. | Introduce each extra hit cost separately before stacking them. Read the coupled state in actual play. |

Level 1's active footprint and plaque positions, cropped from source origin
`(1,1)`. Spaces are outside the active board. A dot is plain and `p` is a plaque.

```text
  ......
..........
....pp....
..........
..pp..pp..
..........
..........
  ......
```

For any example, run
`python3 tools/cradle-of-rome-reference/analyze.py --level 35` with its
number. The inspector separates the terrain and piece layers and lists
four-neighbor group sizes, plaque counts, and generator counts. For example,
level 18 is three substantial groups of 42, 25 and 25 cells, all covered in
plaques, with all 12 generator markers in the largest group.
[Reproduction and evidence limits](README.md#reproduce-the-counts)

For Relic Rush the design variables worth keeping are the target footprint,
the location of a restriction relative to the target and reusable matching
space. Rebuild those relationships around the three hex axes and the game's
actual refill rules. A square layout, its timer or its number of plaque hits
is insufficient to set a hex move budget.
[Adaptation examples](ADAPTATION.md#board-briefs)
