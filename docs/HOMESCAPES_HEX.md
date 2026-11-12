# Homescapes mechanics in the shared hex engine

The shared engine and both portrait games use original Homescapes pieces and
color-independent power-ups. The existing swap/reject, pop, fall, landing,
cascade, score-flight, particle, sound, haptic and reduced-motion paths remain.
A plane adds a flight to that same effects pool. Towns, campaigns, restoration
rewards, tools and campaign-specific floor/portal objectives remain available.

This is a source-based starting point, **not verified 1:1 original gameplay**.
The source executable has not been replayed. Square-to-hex geometry changes
adjacency, match shapes, blast footprints and rocket axes. The previous Swift
lab remains the reference for supported model semantics; this port does not
make its 5,179 unsupported boards playable. See the full source inventory and
unresolved models in [Homescapes features](homescapes-reference/FEATURES.md).

## Matching, activation and combinations

| Pattern/action | Result |
| --- | --- |
| Three in a straight line | Clear, on any of the three hex axes |
| Four in a straight line | Standalone multicolor rocket, aligned to that axis |
| Five or more in a straight line | Rainbow ball |
| Intersecting qualifying lines | Bomb, unless a five-line awards a rainbow |
| Four-cell rhombus | Paper plane, all three orientations |
| Tap a power-up / swap it with a neighbor | Activate for one move without a color match |
| Rocket + rocket | All three axes through the destination |
| Bomb + bomb | Radius-two hex blast |
| Bomb + rocket | Three-axis bands through the center and its neighbors |
| Plane + rocket/bomb | Nearby hit, flight, payload at the destination |
| Plane + plane | Three distinct targeted flights |
| Rainbow + ordinary piece | Clear that piece's color |
| Rainbow + power-up | Convert the most common ordinary color and trigger it |
| Rainbow + rainbow | Hit every active cell |

Power-ups cannot complete color matches. Swapped matched cells take precedence
for reward placement; cascade rewards use deterministic cell order. The source
rocket's two orientations become three. A bomb's adjacent blast becomes seven
hexes, and a double bomb becomes nineteen. A plane hits all six neighbors;
target preference is deterministic (source cells, blockers, objectives, pieces).
These are explicit hex adaptation choices, not original replay results.

## Ported models and goals

| Source model | Shared-engine behavior and current artwork |
| --- | --- |
| `NORMAL`, `RANDOM_CHIP` | Six original colored pieces; source weights/restricted initial palettes |
| `BOX`, `COLOR_BOX` | Fixed layered obstacle; adjacent matches or direct hits, color restriction for colored boxes. Six original ordinary-box states; colored identity uses a diagnostic label |
| `TRASH` | Swappable/falling cookies, three original damage states; adjacent matches or direct hits |
| `TRASH_STONE` | Swappable/falling hazelnuts; only direct hits damage; original whole/split/exposed nut states |
| `ICE`, `LOCK` | Hold pieces; one layer per hit, ice before chain before piece. Original ice and chain variants, including mirrored single chain |
| `HONEY`, `CHERRY` | Jelly covering a stationary cherry; neighboring clears/blasts strip jelly and release cherry goal. All six original layer appearances and both visible cherry variants |
| `JELLY` | Carpet floor spreads through a matching group or carried power-up wave; source carpet texture |
| `CARRY`, `CARRY_EXIT` | Donut falls to an exit and credits collection; original donut |
| `TARGET_GEN` | Shared four-cell apple platter footprint; one apple per wave even when multiple cells hit; original platter/apple components, once per footprint |
| `STATUE` | Fixed, power-up-only layered statue; original raw/cut/carved states |
| `COOKIE_BOX` | Fixed stack releases three movable cookies when destroyed; original bow/strap/plain stack states, then original cookies |
| `CARRY_GEN`, `CARRY_GEN_CELLS` | Shared donut maker, hit threshold, batch size, designated destinations and remaining-goal cap. Original base, dough and glass dome with adapted charge preview placement |
| `BUBBLE_MEMBRANE` | Two layers require a direct hit first; single layer accepts a match; held cells protect the floor; original intact/cracked ceramic fills |
| `SHUTTERS` | Shared vertical blind opens one bottom cell per wave; original shutter fabric and header, sized to remaining covered cells |
| `BOMB`, `LINE`, `LIGHTNING`, `FISH` | Bomb, rocket, rainbow and plane, each original standalone sprite |
| `BORN`, `ARTIFACT_GEN`, `PATTERN_COLOR_BORN` | Ordinary refill inlet, per-cell queue and restricted palette; visible inlets use an original shell and next queued original object |
| `NONE_CHIP` | Initially empty cell, filled through its permitted source |

Goals: `CHIPS` (color subtype), `CELL_JELLY`, `BOX`, `TRASH`, `ICE`, `LOCK`,
`CARRY`, `COLLECT_PIGGY`, `COLOR_BOX`, `TRASHSTONE`, `TARGET_GENERATOR`, `STATUE`,
`BUBBLE_MEMBRANE`, `SHUTTERS`. Their initial/current/maximum values survive
conversion and are shown in the existing goal HUD. No goal is silently dropped.
Missing goal icons use explicit text. Source preview wins do not grant campaign
rewards. Regular campaigns retain their authored objective counts and economy.

Ordinary colored pieces no longer thaw adjacent ice just because they occupy
the former flame/candy-cane color slot. The explicit legacy engine `THAW` flag
remains available to old callers, but neither portrait game enables it.

## Generators and data contract

`level.homescapes` supplies `cells` keyed by axial cell ID; each retains its
ordered source `models`. It also supplies goals, color weights, random patterns,
BornPatterns, color patterns/sets and refill rules. Group proxies retain their
source attributes plus converted `mainCell`. Unknown models, goals, malformed
queues, conflicting references and unsupported properties throw an error.

Supported queue tokens are `[c]`, `[c1]`–`[c6]`, `[b]`, `[f]`, `[z]`, `[l]`,
`[lh]`, `[lv]`, `[t1]`–`[t3]`, `[T1]`–`[T3]`. Color suffixes are one-based;
palette `[Cs…]` digits are zero-based. Supported properties are repeat count,
100% drop chance, fixed cookie/nut strength and fixed six-color weight sets.
Finite queues fall back to ordinary refill; looping queues wrap. Two generators
referencing one pattern own separate cursors. Simulation copies isolate cursors,
goals and mobile-piece durability. Refill caps count other simultaneous spawns.
Maker boards suppress ordinary donut refill.

The engine keeps its seeded RNG and animated three-edge gravity. That differs
from the lab's straight-column gravity/RNG. Fixed initial pieces are retained,
and initially empty cells can consume the nearest open source above them.
The token interpretations and unresolved properties are documented in
[GENERATORS.md](homescapes-reference/GENERATORS.md).

## Source-derived runnable previews

`python3 tools/homescapes_hex.py` reads ten representative XML entries directly
from the original `reference/Homescapes.app/base.zip` nested level archive and
writes `engine/match3_reference.lua`. `--check` regenerates in memory and compares
exactly; every record includes the original XML SHA-256. Source `(x,y)` becomes
axial `(x-cx, cy-y)`, preserving holes and four-cell group membership. The board
radius is derived from that footprint. No dependency download is required.

Run either portrait game, for example:

```sh
make relic-rush
./build/relic-rush --fresh --homescapes st0065
./build/relic-rush --fresh --homescapes st0255
python3 tools/homescapes_hex.py --check
build/test/engine 'rules homescapes'
```

Available IDs: `st0001`, `st0037`, `st0051`, `st0065`, `st0255`, `st0401`,
`contest_005_06`, `contest_026_01`, `contest_172_04`, `contest_011_15`.
These are verification fixtures, not a replacement campaign or a claim that
all 6,184 original levels can run. Their previews fit the existing portrait HUD.

## Single board atlas and artwork restoration

See [the current original-art state inventory](HOMESCAPES_ART.md) for the recovered
blocker/generator art, exact source versions, inferred mappings and unresolved
requirements. The following paragraph describes the initial source set.

The 32 extracted original PNGs are preserved byte-for-byte in
`engine/art/homescapes/sprites/`; `source-regions.json` records their original
atlas regions. `tools/homescapes_atlas.py` uniformly resizes and, for the two
sloped rocket axes, rotates them. Object alpha stays authored. Carpet and jelly
material previews use the canonical hex mask, without filling transparent
pixels or inventing damage artwork. These material previews are not certified
full-bleed hex art. All transforms and input/output hashes are recorded in the
engine and games' `match3-atlas.json` manifests.

`python3 tools/match3_atlas.py` packs original pieces, specials, blockers and
retained interface controls into **one board atlas per active skin**. Every selectable
piece pack aliases the same six originals; sprites are not repainted or tinted
for power-up states. Existing separate scene, character, town and particle
textures remain. The old striped-gem shader is no longer used for power-ups.

Original source artwork covers nuts, statues, stacks, ceramic tiles, blinds,
visible queues, six jelly strengths and both portal ends. The maker uses the
recovered glass layer. Platters and makers use original parts positioned for the
hex board. The colored-box goal icon is original. Field sprites for colored
boxes, the donut collection arrow and exact maker charge poses remain open.
[Current inventory](HOMESCAPES_ART.md) · [Issue #98](https://github.com/corepunch/nile-archive/issues/98)

Review captures are under [review/homescapes-port](review/homescapes-port/).
Verification includes shape/combination outcomes, blocker precedence, generated
piece limits, independent queues and three moves on each original-archive
fixture, alongside the existing shared-engine and game tests.

## Field-only visual replacement

At the user's request, the live field has no legacy gold edges, snow/sand rims,
bevels, authored selection/hint frames or numeric ice badges. Flat hex ground
uses neutral grays `#484848` and `#545454` (alternating cells), with no green tint.
See the [gray-field review](review/gray-hex-ground/README.md). Selection and hints
scale the original piece. Only Homescapes sprites
are used for board pieces and blockers. Existing quest-resource artwork is the
explicit temporary exception. Surrounding backgrounds, panels, tool buttons and
interface remain, as do the requested particle effects and animation transforms.
Campaign portals use the original yellow and blue rings. The separate donut
collection exit still uses diagnostic text. Legacy stone, crate and growth
use source box and jelly material previews. Legacy floor-cover objectives use
flat hex ground. The source-preview boards use the dedicated source model
handlers and goals described above.

The longer guide uses the engine's existing scrolling list, keeping Done within
the screen. Source-level launch options are now available while Lua modules load,
including in the test runner; preview captures assert that source mechanics are
actually loaded. This fixes previews silently showing a normal campaign board.
