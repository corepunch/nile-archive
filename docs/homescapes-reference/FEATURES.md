# Homescapes lab feature reference

This document covers the implemented features of `prototypes/homescapes-match3`.
It describes a deterministic simulation of a subset of the local 9.2.601 bundle.
It does not claim a complete port or verified original-runtime parity.
[LAB_COVERAGE.md](LAB_COVERAGE.md) records the current executable coverage;
[BLOCKERS.md](BLOCKERS.md) and [GENERATORS.md](GENERATORS.md) give rule evidence,
interpretation limits, visual catalogues and reproduction commands.

## Resource loading and audit

| Feature | Behavior |
| --- | --- |
| Original archive reader | Decode the bundled Zstandard archive; compare all 6,184 extracted XML files byte-for-byte with the original |
| Level XML | Read cells/coordinates, model attributes, moves, local seed, goals/current progress, chip weights and random-chip palettes |
| Lossless retention | Preserve exact XML bytes and a generic element tree, including unknown tags, attributes, nested model settings and text |
| Supported-level loading | Reject unknown model/goal IDs and unsupported configurations; retain rejected source data for investigation |
| Corpus audit | Per-file vocabulary/configuration gaps, load/execution errors, initialized state, legal turns, goal progress, stalled state and generator emission counts |
| Original evidence inventory | Named VSO record offsets/digests/capability strings; direct-from-archive generator token/property/palette inventory with source examples and conflicts |
| Art mapping | Use extracted sprite files and the shared `model_sprites.json`; diagnostics identify states without verified artwork |

Initialization means that the lab accepts the represented mechanics. It does
not establish that every preserved script, spawn route or tuning field is
implemented. `originalRuntimeVerified` is false in every audit.

## Play, matching and power-ups

- Drag between adjacent cells, or select two cells, to try a swap. Invalid swaps
  restore the board and cost no move. Valid swaps and power-up activations cost
  one move. Swappable nonmatching pieces include cookies, hazelnuts and donuts.
- Match three or more equal colors horizontally/vertically. Four in a straight
  line creates a rocket; a 2×2 square creates a plane; an intersecting group of
  at least five creates a bomb; a straight run of at least five creates a
  rainbow ball. Larger overlapping groups merge and select a single reward.
- Rewards prefer the moved cells, then coordinate order, and cannot replace a
  retained restrained piece. Initial weighted random fill avoids matches where
  possible; fixed source pieces and scripted outputs are respected.
- Rockets clear a row/column and stop at cookies. A standalone bomb uses a
  3×3 lab footprint. A plane hits takeoff neighbors and a deterministically
  prioritized destination. A rainbow ball uses the swapped gem color or the
  most common available color. Other power-ups in a blast can chain.
- Simultaneous blast overlap damages each cell once. The lab is synchronous;
  original animation, multi-hit timing, plane targeting, bomb radius and exact
  resolution order are not reproduced.

| Pair | Implemented combination |
| --- | --- |
| Rocket + rocket | One row and one column through the destination, irrespective of their orientations |
| Bomb + rocket | Three rows and three columns |
| Bomb + bomb | 5×5 lab footprint |
| Plane + plane | Three distinct prioritized destinations plus takeoff area |
| Plane + rocket/bomb | Deliver the payload footprint to the selected destination |
| Rainbow + rocket/bomb/plane | Convert unrestrained gems of the most common color, then detonate them |
| Rainbow + rainbow | One simultaneous hit on every board cell |

Both ingredients are consumed once. Combination centres use the moved piece's
destination. These choices and held-piece exclusions are tested but still need
replay against the original version. The source-backed publisher references
are linked from the [package README](../../prototypes/homescapes-match3/README.md).

## Pieces, blockers, covers and objectives

| Source model(s) | Implemented rule | Goal credited |
| --- | --- | --- |
| `NORMAL`, `RANDOM_CHIP` | Fixed or restricted random gem; ordinary fill uses weighted seeded colors | `CHIPS`, with color subtype |
| `LINE`, `BOMB`, `FISH`, `LIGHTNING` | Load rockets, bomb, plane and rainbow ball | No power-up creation/activation goals yet |
| `BOX` | Fixed layered blocker; adjacent match/direct blast removes a layer | `BOX`, on final layer |
| `COLOR_BOX` | Layered blocker requiring an adjacent match of its color or direct blast | `COLOR_BOX`, on final layer |
| `TRASH` | Movable layered cookie; adjacent match/direct blast; stops rocket ray | `TRASH`, on final layer |
| `TRASH_STONE` | Movable layered hazelnut; direct blasts only | `TRASHSTONE`, on final layer |
| `ICE` | Holds a piece; direct match/blast removes a layer while preserving the held piece | `ICE`, on final layer |
| `LOCK` | Holds a piece; match/blast removes a layer; preserves `mirror` source state | `LOCK`, on final layer |
| `HONEY`, `CHERRY` | Jelly blocks a cell; adjacent matches and near/direct explosions reduce jelly; final removal releases/collects its cherry | `COLLECT_PIGGY` |
| `JELLY` | Carpet ground spreads through a matching group or blast initiated on carpet | `CELL_JELLY`, for newly covered cells |
| `CARRY`, `CARRY_EXIT` | Donuts fall/swap but do not match; reaching an unrestrained exit collects them | `CARRY` |
| `TARGET_GEN` | Apple platter with shared 2×2 footprint/count; one apple per hit resolution; vanishes at zero | `TARGET_GENERATOR`, per apple |
| `STATUE` | Fixed stone layers; direct blasts only | `STATUE`, on final layer |
| `COOKIE_BOX` | Three-layer stack; final hit queues three cookies in available gem cells | Generated cookies later credit `TRASH` |
| `BUBBLE_MEMBRANE` | Stationary ceramic tile: blast cracks strength 2; direct match/blast clears strength 1 | `BUBBLE_MEMBRANE`, once per cell |
| `SHUTTERS` | Shared vertical blind footprint rolls up from its lowest cell; covered pieces stay hidden/immovable | `SHUTTERS`, once per complete blind |
| `NONE_CHIP` | No authored starting piece; ordinary initialization/refill may populate the cell | None |

Goal counters start from XML `current`, cap at XML `max`, and the board wins
when all goals reach their maxima. An exhausted move budget loses; a board
without a legal move can stall. Identifier acceptance does not validate every
possible strength/property combination for older mechanics; exact supported
ranges and assumptions are recorded in the implementation notes.

## Generation, gravity and turn resolution

| Source/configuration | Implemented behavior |
| --- | --- |
| `BORN` | Birth-point marker reachable through an open column; source `isLooped` is retained but its independent meaning is unresolved |
| `ARTIFACT_GEN` + `BornPatterns` | Independent per-cell piece queues; loop/finite states, fixed colors, random gems, power-ups, cookies, hazelnuts; strict reference/token validation |
| New-format pattern properties | Repetition counts, 100% drop chance, fixed strengths and named color weights; unresolved variants rejected |
| `PATTERN_COLOR_BORN` + `ColorChipsPattern` | Restrict new gems from that source to the serialized zero-based palette |
| `CarryChips`, `TrashChips`, `TrashStoneChips` | Chance, population cap, strength, remaining-goal cap, target overrides and explicit source coordinates |
| `CARRY_GEN`, `CARRY_GEN_CELLS` | Shared maker counter; source-configured activation period and batch; marked output cells; wait when occupied; outstanding-goal cap |
| Cookie stack output | Queue three cookies on destruction; fill available unheld gem positions, retaining unplaced output |

The generator grammar and every implemented property are detailed in
[GENERATORS.md](GENERATORS.md), including interpretations not proven by the
original engine. Maker scheduling/default refill assumptions are in
[BLOCKERS.md](BLOCKERS.md).

Gravity moves existing pieces downward through open contiguous cells. Donut
exits settle repeatedly before random refill. Cascades repeat for at most 64
resolution passes; reaching that defensive bound marks the board stalled.
When a settled board has no move, the lab tries up to 24 deterministic recolor
attempts before stalling. Initial no-move boards are reported directly. Neither
reshuffle algorithm nor RNG matches a recovered original implementation.
Portals, diagonals, alternate gravity, scripted/tutorial restrictions and
unsupported generators remain gaps.

## Mac interface and command-line tools

| Control/option | Behavior |
| --- | --- |
| Board picker | Choose among the loaded relative source paths; source IDs are not campaign numbering |
| Restart | Restore the board using the current seed offset |
| New seed | Increment the offset and restart |
| Hint | Highlight a legal swap or activatable power-up |
| Piece input | Drag/click a pair to swap; select a special twice to activate |
| Status | Move budget, each goal's progress, win/out-of-moves/stall messages |
| Diagnostics | Text for incomplete blocker states; visible generators show emitted count; stacked labels wrap within one cell |
| `--root PATH` | Locate reference levels, sprites and mapping under a checkout |
| `--level RELATIVE.xml` | Load one path beneath the levels directory; reject traversal outside it |
| `--all-levels` | Populate the picker with every board that constructs successfully |
| `--check` | Exercise the loaded sample boards for up to 12 legal moves and check mapped image files |
| `--audit` | Emit the full corpus JSON report; actual load/execution errors cause nonzero exit |
| `--audit --exercise` | Also play up to 12 legal moves per accepted board; known unsupported mechanics are reported as gaps rather than execution failures |
| App bundle keys | `LabRoot` supplies the root; `LabAllLevels=true` selects all accepted boards when launching a packaged Mac app |

Default startup loads eight samples. SpriteKit renders static states without
animation/audio. The UI is a lab viewer, not the original mansion, economy,
level selector, campaign, live-operations or booster inventory. No reference
source is changed by playing or auditing.

## Tests and known gaps

The Swift suite covers special shapes, all power-up pair dispatches, restraints,
fall/refill and donut exits, layered/shared blockers, source queues and palettes,
property validation, unsupported-data reporting and all source XML retention.
Python checks tie resource inventories and extracted XML to the original
compressed bundle. Representative native captures are catalogued in the two
implementation notes; missing authored artwork remains linked to issue #98.

The full current unknown model/goal lists, pattern configuration gaps, initial
stalls and measured verification results live in [LAB_COVERAGE.md](LAB_COVERAGE.md).
The lab still rejects thousands of levels. Retaining their data, recognizing a
token, executing hints and reproducing the original game are separate milestones.
