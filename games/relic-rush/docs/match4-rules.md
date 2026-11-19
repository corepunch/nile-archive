# Hex straight-line matching rules and boards

Relic Rush matches straight lines of three with six piece kinds. This supersedes the earlier line-of-four rule with five kinds, and the prototype's connected groups before it.

## Matching

- Exchange two side-adjacent movable relics, by swiping or tapping both.
- A contiguous **straight line of three or more identical relics** matches along any of the three hex axes. Bends, triangles, diamonds and rings do not count on their own, and neither does a pair. Side branches are not part of a line.
- A swap without a line through either swapped cell returns without spending a move.
- Any line clears normally, whatever its length. There are no special pieces of any kind: like Cradle of Rome, power comes only from the bonus tools along the bottom edge (Hammer/Dynamite, Shield/Lightning, Star/Star II, Plus/Plus II), charged by matching bonus gems and unlocked by restoring buildings.
- Crossing lines clear their union once. There are no T/L or ring recipes.
- Ice layers, chains, carved stones, blue tablets and tools each keep their own effects.
- A ready group is checked on the idle board before hints/input and after every completed fall. All cascade waves finish before victory/failure is checked. Automatic waves do not spend additional moves.
- The expedition's top bar shows the hexagonal Moves medallion, Coins, Supplies, Food and Settings. Blue tablets mark the objective on the board. Tools sit along the bottom edge. Settings opens the Explorer's Guide and lets the player resume, restart after confirmation, or quit to the island and resume the same board from Expeditions. See the [top bar review](screenshots/review/top-bar-moves/README.md).
- Hints highlight a legal swap after five idle seconds. If the hint search finds no swap, idle boards use the same free reshuffle as boards settling after a fall, with a “No moves. Board reshuffled.” notice. Recovery resets selection/tool targeting and stale hints, preserving move/tool budgets, objective progress, holes, sand, ice, chains and their locked relics. Victory and exhausted moves take precedence over reshuffling.

The shared engine's `LINE_MATCHES` flag selects this detector for both Relic Rush and Christmas Market. The engine has no special pieces at all. Generation, hints, reshuffling and cascades respect each game’s configured minimum.

## Why three, and what it costs

A line of three leaves room for a sixth kind. With lines of four, a sixth kind halved the legal moves and the board reshuffled eight times as often. With lines of three, six kinds give about four times the moves of the old rule, and the reference bot clears a board in about half the moves: its median game averages 21 moves across the campaign, against 39 with lines of four on the same boards. [Move budgets](level-moves.md) · [Board length](board-progression.md#length)

A board with a legal move never reshuffles, and with lines of three there is almost always one. Under the old rule the reshuffle also re-dealt the pieces in tight pockets. Now the last plaque in a pocket waits for a line through it or for a tool. Keep plaques out of dead-end pockets: on an earlier, denser set of boards the bot, which plays without tools, could not finish four of them.

## Crew requests

Between purchases the crew asks for things of its own. [Story and scenes](story.md#crew-requests) · [Request data](../lua/quests.lua)

- **A request has its own piece.** It stands on the boards only while the request is open and short of pieces. It matches like any other piece and banks nothing in the wallet. Each one matched counts toward the request. A tool hit does not count, as with resources.
- **Pieces bank on a win.** The counters above the board show the banked pieces plus this expedition's matches, up to the request's need. Only requests present on the board show a counter. A lost or abandoned board banks none. The results card lists them beside the resources.
- **Requests take the free score slots.** Open requests take the slots of quartz, the amphora and the flower, in that order, while no restoration's piece holds them. The leaf's slot belongs to the bonus gem. A request with no free slot waits for the next one, and its marker says so.
- **Two lines run side by side.** A request opens once its building stands and the one before it on its line is handed in. Expeditions 2–7 carry two requests at once; from the Sawmill on, one slot is left.
- **Hand it in on the island.** Round markers down the upper-left edge show the next building, then each open request with its piece and count. A filled request glows. The chart and cable hand-ins open an illustrated card before their dialogue. Requests remain optional.
- **Resume or replay from a request card.** A paused board updates its piece lineup when you return from the island, keeping its tiles and progress. After expedition 100, unfinished requests can replay Vault Door (expedition 5), which has two free score slots.
- **The amounts follow the boards.** A request asks for about four fifths of the pieces the bot banks on the expeditions it is written for: 25 on expeditions 2–4, 45 on 5–7 and 60 on 8–10.

## Board shape

Every board is authored on a 9 x 12 rectangle of flat-top hexes; holes and the outline make its shape ([level design guide](../../../docs/LEVEL_DESIGN.md), [board progression](board-progression.md)). Missing cells are excluded from rendering, matching, tile selection, swapping, tool targeting, obstacle placement and refill. Matching never crosses a gap. Gravity moves gems straight down whenever the cell beneath them is empty. Diagonal movement is allowed only when that cell is occupied, locked or missing. Every active cell with no active cell directly above spawns vertically before considering side donors, so the whole stepped top edge refills together. Interior cells spawn only when all upstream donors are blocked. Gems flow around holes and immovable blockers through real neighboring cells; they never jump a gap or consume a locked gem. The shared engine animates each edge and waits for the complete fall before checking a cascade. Tool hits may travel across gaps but only affect actual cells.

All 100 boards are won by clearing their blue tablets; green double tablets take two hits. Blockers are chains (single and double), ice (single and double) and carved stones, and they gate the fall below them. Boards spawn six piece kinds. The story and the twenty restorations run across boards 1-30; boards 31-100 are playable without story yet.

## Idol

The default Relics pack shows a round gold sun coin for idol matches and goals. See the [tile art comparison](tile-sets.md) for the optional packs.

See [shared engine and atlas contract](../../../docs/MATCH3_ENGINE.md) and [before/after trickling captures](review/trickling/README.md).

## Validation

- Seeded startup boards across all 100 boards: no pre-existing straight match and at least one legal opening move. Every opening exchange, including its cascades, leaves at least one tablet.
- Pair/three/four/six runs on all axes, rejected triangles/diamonds/rings, excluded branches, crossing lines, swap rollback, and hole-separated runs.
- Independent coordinate-based line oracle and exhaustive runs in both directions for every color and length.
- Existing blockers, gravity, tools, update-loop cascades, hints and reshuffles.

## Reference research

- [King's GDC Europe 2016 presentation: Level Design Saga, Jeremy Kang](https://media.gdcvault.com/gdceurope2016/presentations/KANG_Jeremy_LevelDesignSaga.pdf): level concept, layout, balancing and testing as separate design steps; board layouts support different gameplay situations.
- [Red Blob Games: Hexagonal Grids](https://www.redblobgames.com/grids/hexagons/): axial/cube coordinates, six edge neighbors, connected traversal and shaped grid regions. Used as a geometry/reference explanation, not copied game implementation.
- [Match 4 – Hex, developer page](https://dimcairion.itch.io/match-4-hex): an independent hex swap/match-4 prototype demonstrating the genre. No code or assets were imported.
- [Candy Crush official modes guide](https://candycrush.zendesk.com/hc/en-us/articles/360000754897-Which-game-modes-will-I-find): varying objectives and mixed modes complement level-layout variety.

Relic Rush uses three in a straight line; longer lines earn no extra piece.
