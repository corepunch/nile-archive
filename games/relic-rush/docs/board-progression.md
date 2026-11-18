# Relic Rush board progression

Every expedition asks the player to clear its plaques. Blue plaques take one
hit and green plaques take two. Chains hold their pieces until a match or tool
hit breaks the chain. A later hit clears the plaque beneath it. Ice and carved
stones can also cut off the route that feeds a chamber.

The campaign uses the [GameTop Windows edition of Cradle of Rome 2](../../../docs/cradle-of-rome-reference/README.md#adventure-comparison-sheets)
as its progression reference. The authored layouts use Relic Rush’s hex
geometry and four-piece matches. Plaque coverage tracks the reference after
level 6, with a minimum of 80% of all board cells. Each tenth expedition is a
boss with green double plaques on every cell. The [full sheet](../../../docs/review/level-sheets/relic-rush.png)
shows all 100 boards, and the [30-level sheet](../../../docs/review/level-sheets/relic-rush-1-30.png)
focuses on the story expeditions.

## Match-four difficulty

The first six boards use smaller objective fields. The Landing keeps the
seven-plaque hex at the centre of its nine-column board. Temple Steps sets two
objective groups along a diagonal, and Sunken Courtyard wraps its plaques around
an open court. Overgrown Terraces introduces a single chained plaque on level 4.
Vault Door expands the clearing area, then Vine-Bound Terraces brings back
chains on smaller target fields.

Jaguar Court and Overgrown Arches introduce dense clearing on levels 7 and 8.
On level 9, Twin Terraces starts with 40 empty cells below a chained entrance.
The upper terrace has lines of four that can open the chain and start the fall.
Level 12 introduces ice and carved stones. Later boards vary the shape of the
routes with stepped edges, paired wells, pillars and diagonal bridges.

The bosses each have their own outline. Jaguar Throne (10) has a tall back and
low armrests. Heart of the Temple (20) has two lobes that taper to the base.
Hall of Pillars (30) frames an open courtyard and ends in two pillars. Its
centre plaque covers the signal plate used by the story scene.

The Sundered Gallery (34) brings back an empty lower chamber. From Twin Sanctums
(35) onward, ice or carved stones punctuate the sequence of chained boards.
The Jungle Bridge (62) introduces double chains. Twin Shrines (79) holds the
lower chamber until both links on the gate chains have been broken. The Valley
Temple (100) combines double chains and ice over green plaques.

## Boss blockers

The sequel leaves bosses 10, 20, 30 and 80 free of blockers. Bosses 40, 50 and
60 step up the chain count. The Observatory (70) and the Altar (90) chain
about a fifth of the field. The final boss mixes double chains and ice.
Relic Rush scales the counts by board area and groups blockers symmetrically.

| Boss | Cradle of Rome 2 | Relic Rush |
| --- | --- | --- |
| 10, 20, 30, 80 | No chains or ice | No chains or ice |
| 40 | 4 chains | 2 chains |
| 50 | 6 chains | 3 chains |
| 60 | 12 chains | 6 chains |
| 70 | 44 chains | 14 chains |
| 90 | 32 chains | 14 chains |
| 100 | 10 double chains and 8 frozen cells | 4 double chains and 3 frozen cells |

The final board uses cutouts for open space. Its ice and chains sit over
green plaques and absorb hits before the plaque layers.

## Board checks and captures

Each tablet has space for a match on two axes. Each gate has a four-piece line
on its fed side. The level validator checks symmetry, feed routes and coverage
before compiling the 100 source boards in [../levels](../levels). Every opening
deal has a legal move and is rejected if one exchange could clear every plaque.
Move budgets come from 40 seeded deals per board played by a bot without tools.
The results are listed in [level-moves.md](level-moves.md).

Each in-game comparison shows the previous board on the left and the revised
one on the right.

| Board | 480 × 900 | 390 × 844 |
| --- | --- | --- |
| 9 · Twin Terraces | [Opening deal](screenshots/review/rome-2-campaign/terraces-480.jpg) | [Opening deal](screenshots/review/rome-2-campaign/terraces-390.jpg) |
| 12 · Choked Gateway | [Opening deal](screenshots/review/rome-2-campaign/gateway-480.jpg) | [Opening deal](screenshots/review/rome-2-campaign/gateway-390.jpg) |
| 30 · Hall of Pillars | [Opening deal](screenshots/review/rome-2-campaign/hall-480.jpg) | [Opening deal](screenshots/review/rome-2-campaign/hall-390.jpg) |
| 44 · Chained Cloisters | [Opening deal](screenshots/review/rome-2-campaign/cloisters-480.jpg) | [Opening deal](screenshots/review/rome-2-campaign/cloisters-390.jpg) |
| 65 · Star Chamber | [Opening deal](screenshots/review/rome-2-campaign/star-chamber-480.jpg) | [Opening deal](screenshots/review/rome-2-campaign/star-chamber-390.jpg) |
| 100 · The Valley Temple | [Opening deal](screenshots/review/rome-2-campaign/valley-temple-480.jpg) | [Opening deal](screenshots/review/rome-2-campaign/valley-temple-390.jpg) |

## Piece progression

Each expedition has five kinds. The starting pieces are two coins, a leaf, a flower and an amphora. Buying a campaign building introduces one resource or bonus piece. Board 13 reserves one slot for the story note. The [building table](../README.md#buildings) lists all twenty purchases, their prices and the piece each introduces.

### Bonus pieces

Four sockets hold one charge each. A new tool takes over its socket and replaces the old collectible on the board, including when returning to a parked expedition. Matching six ordinary bonus pieces fills one charge. The painted piece appears from the bottom as the charge arrives. After using the tool its recessed silhouette is visible again. Each board can feature one active bonus family.

- Hunter's Hut — Unlocks Hammer. Hit one cell.
- Village — Unlocks Bomb. Hit a cell and its six neighbors.
- Thermae — Unlocks Shield. Hit the row through a chosen cell.
- Curia Octavia — Unlocks Hourglass. Add five moves.
- House of the Vestals — Unlocks Lightning. Strike up to fifteen random cells.
- Lighthouse — Unlocks Plus. Choose a resource piece for 100 resources or another bonus to add a quarter charge.
- Mausoleum of Augustus — Unlocks Mixer. Shuffle the pieces.
- Forum — Unlocks Star. Clear all pieces of a chosen kind.
