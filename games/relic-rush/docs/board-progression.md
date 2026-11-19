# Relic Rush board progression

Every expedition asks the player to clear its plaques. Blue plaques take one
hit and green plaques take two. Chains hold their pieces until a match or tool
hit breaks the chain. A later hit clears the plaque beneath it. Ice and carved
stones can also cut off the route that feeds a chamber.

The campaign uses the [GameTop Windows edition of Cradle of Rome 2](../../../docs/cradle-of-rome-reference/README.md#adventure-comparison-sheets)
as its progression reference: the order of features, which boards carry
chains, ice and green plaques, and the tenth-board bosses. The authored
layouts use Relic Rush's hex geometry and three-piece matches with six kinds. The
[full sheet](../../../docs/review/level-sheets/relic-rush.png) shows all 100
boards, and the [30-level sheet](../../../docs/review/level-sheets/relic-rush-1-30.png)
focuses on the story expeditions.

## Length

An expedition is sized by moves, against the move budget of
[Homescapes level N](../../../docs/homescapes-reference/first-100-levels.md).
On a board without chains or ice the reference bot's median game is at most
twice that budget. The 55 boards the reference chains or freezes may run to
three times, so they can keep their blockers. The plaques were trimmed to
those limits with four-piece matches, where the campaign's median was 39 moves
on average. With three-piece matches and six kinds the same boards run to 21
moves on average, against 18.5 in Homescapes. Lengthening them again means
putting plaques back in the level files; the trim tool only removes them.

Cradle of Rome 2 covers 80–100% of a board with plaques because its levels run
on a timer; at that coverage the bot needed about 110 moves a board with
four-piece matches. Each board therefore keeps the plaques the bot clears
soonest, 29–48% of its cells per ten levels, and the rest is plain floor.
`python3 tools/balance_plaques.py relic-rush` lists the plaques that hold a
board up, and `--trim` removes them.

## Match-three difficulty

The first six boards use smaller objective fields. The Landing keeps the
seven-plaque hex at the centre of its nine-column board. Temple Steps sets two
objective groups along a diagonal, and Sunken Courtyard wraps its plaques around
an open court. Overgrown Terraces introduces a single chained plaque on level 4.
Vault Door expands the clearing area, then Vine-Bound Terraces brings back
chains on smaller target fields.

Jaguar Court and Overgrown Arches widen the plaque field on levels 7 and 8.
On level 9, Twin Terraces starts with 40 empty cells below a chained entrance.
The upper terrace has lines that can open the chain and start the fall.
Level 12 introduces ice and carved stones. Later boards vary the shape of the
routes with stepped edges, paired wells, pillars and diagonal bridges.

The bosses each have their own outline. Jaguar Throne (10) has a tall back and
low armrests. Heart of the Temple (20) has two lobes that taper to the base.
Hall of Pillars (30) frames an open courtyard and ends in two pillars. Its
centre plaque covers the signal plate used by the story scene.

Double chains arrive on the Jungle Bridge (62), following the sequel's schedule.

## Blocker density

A chained or frozen plaque needs two or three matches of four on one cell, so
chains and ice sit on plaques the bot clears early, and a trim removes plain
plaques before it touches them (`--keep-blockers`). Chains cover 1–7% of all
cells per ten levels (reference 3–9%) and ice up to 7% (reference up to 8%),
on the same boards as the reference. Ice has one layer, as in the reference.
A gate stays only where it holds back a plaque. Compare any range with
`python3 tools/reference/cradle-of-rome/compare_levels.py relic-rush`.

The chain and ice boards were built from the full-density boards in three
steps: trim to three times the Homescapes budget, put chains and ice on the
plaques the bot then cleared soonest, and trim again with
`--trim --keep-blockers --high 3`.

Every plaque on a boss board is green. The final board keeps double chains
and ice over green plaques.

## Board checks and captures

Each tablet has space for a match on two axes. Each gate has a three-piece line
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

Each expedition has six kinds. The starting pieces are two coins, a leaf, a flower, an amphora and quartz. Buying a campaign building introduces one resource or bonus piece. The crew's open requests put their pieces in the score slots still free. [Crew requests](match4-rules.md#crew-requests) Board 13 reserves one slot for the story note. The [building table](../README.md#buildings) lists all twenty purchases, their prices and the piece each introduces.

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
