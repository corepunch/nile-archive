# Match-3 elements and board design

The current default rules and original-art atlas are documented in [Homescapes on hexes](HOMESCAPES_HEX.md). Legacy opt-in flags and campaign-only elements below remain supported.

Relic Rush and Christmas Market share rules, but author their own shapes,
terrain priorities, element placements and teaching order. The playable
campaigns are in each game's `lua/campaign.lua`; their design notes are in
[Relic Rush](../games/relic-rush/docs/board-progression.md) and
[Christmas Market](../games/christmas-market/docs/board-progression.md).

## Reference and adaptation

The [Tropicats reference](tropicats-reference/README.md) records extracted
content separately from inferred behavior. This implementation is our own
design: exact Tropicats cascade, portal and hazard timing was not recovered
from its encrypted executable.

King confirms several useful counterparts: layered frosting, color-sensitive
Candy Cubes, hidden items under coverings, and spreading Bubblegum/Chocolate.
These support the first four families below.
[Official Soda blocker guide](https://candycrushsoda.zendesk.com/hc/en-us/articles/360001376929-How-do-the-different-blockers-work).
Its straws connect separate board regions and change where clearing draws
pieces from; our tunnels use a fixed downward connection without Soda's
reversible liquid flow.
[Official level 1903 guide](https://candycrushsoda.zendesk.com/hc/en-us/articles/360001431345-How-to-beat-level-1903).
Saga's dragon objectives also establish delivery as a distinct task from
matching colors: clear a route to a destination.
[Official Saga modes](https://candycrush.zendesk.com/hc/en-us/articles/360000754897-Which-game-modes-will-I-find).

| Family | Implemented behavior | Design purpose |
| --- | --- | --- |
| Stone / packed snow | A solid cell with 1–3 hits, no piece inside. Adjacent ordinary matches or direct special/tool hits remove one layer per wave. | Gate a bridge or divide work into successive openings. A three-hit wall needs repeated access, not just more score. |
| Color crate / gift | Solid, 1–2 hits. Adjacent ordinary matches must match its marked kind; direct effects ignore the color. | Make the player bring a useful color to a particular edge, or build a ray with the right reach. Color-specific original art is still missing; see the current art-gap catalogue. |
| Buried tablet / star display | An explicit footprint under excavation coverings. Clearing every footprint cell discovers one object. The quest-resource image is provisionally retained; covering progress follows the current original-sprite adapter. | Concentrate work into a readable region; the last corner matters. Footprints are authored rather than randomly scattered. |
| Vines / tangled ribbon | One-hit overlay locking its piece. Adjacent ordinary matches or direct effects remove it. One new cell grows after a successful swap and its complete cascade if no hazard was damaged that turn. | Create a local priority that competes with excavation or routing. Free tools do not advance growth. |
| Tunnel / chute | Fixed directed entrance and exit, with the exit lower on screen. The exit draws from the entrance before ordinary donors. Pieces retain their kind and special. | Connect work in separate regions: clearing the destination pulls from another lane. Current campaigns have at most one pair per board. |
| Relic parcel / present delivery | A nonmatching, unswappable token. It falls straight down or through tunnels and is consumed once at a marked exit. Blasts cannot destroy it; shuffles keep it in place. | Turn clearing into route preparation. Unlike normal pieces it cannot drift diagonally into an unintended bottom pocket. |

The lock counter includes all remaining chain, ice, stone, crate and growth
hits. Excavation counts the actual covering placed, including hidden-object
footprints. Discovery and delivery have independent goal counters. Victory
requires every positive goal; a six-goal board uses two HUD rows.

Growth avoids objectives, covered/locked cells, specials, solid blockers,
tunnel endpoints, delivery cells and collection-kind pieces. It adds at most
one cell per turn, even after a long cascade. A damaging cascade suppresses
that turn's growth. Its choices are seeded and replayable.

## Shape before decoration

The user's three hex-board screenshots demonstrate a useful hierarchy:

1. **Two long interior channels:** central spine, side lanes, and deliberate
   top/bottom connections. Put gates at the connections and targets in the
   lanes; a hole changes access and useful ray directions.
2. **A broad bowl with a narrow cap:** generous matching space below, a small
   constrained work area above. Concentrate targets instead of shaving
   arbitrary perimeter cells to make another mask.
3. **Separated chambers:** broad negative-space channels make rooms readable.
   A narrow connection or tunnel determines how one chamber feeds another.

Recognizable families may return. Change the task within the shape: first
open a bridge, later clear a color gate there, finally deliver through it.
Do not invent an unrelated nick in the edge merely to make every mask unique.
Small boards are useful; population is a pacing choice, not a score of quality.

For each board, author a one-sentence intended decision, its working regions,
the connection between them, and the placement of goals. Validate that every
target can be reached, every playable tip participates in a match line, and
every delivery has a complete vertical/tunnel path. Keep opening lessons and
breathers simple. Introduce one unfamiliar rule, repeat it with a changed
constraint, then combine known rules. A board with six mechanics is a late
combination, not a tutorial.

## Level schema and runtime

Optional descriptor fields use **zero-based engine cell IDs**. The campaign's
`cell(q,r)` helper converts authored axial coordinates. Omitted fields are empty.

```lua
stones = {{cell=stone_cell, hp=3}}
crates = {{cell=crate_cell, hp=2, kind=1}}
objects = {{cells={object_a, object_b, object_c}}}
hazards = {growth_cell}
tunnels = {{entrance=upper_cell, exit=lower_cell}}
deliveries = {tokens={token_cell}, exits={destination_cell}}
carpet = {seed_cell, another_seed}
oil = {oil_cell, another_oil_cell}
```

Every element must occupy an active cell; incompatible overlaps, invalid
strengths, backward tunnels and unreachable delivery routes fail at level
creation. Endpoint reservations precede ranked terrain placement. Hidden
footprints can also receive chain/ice but cannot overlap another explicit
element. The optional scalar `soil` requests ranked excavation cells; a
footprint can add further covered cells. Use `g.initial_soil` for the goal.
`carpet` seeds Homescapes' carpet: a match group touching a carpeted cell, or a
move begun on one, carpets every cell it hits (`g.carpet`). The `carpet` goal
counts the active cells still uncovered (`g.carpet_total - g.carpeted`).
`oil` is Homescapes' oil: one layer under a piece, cleared like snow by a match
on its cell or a blast (`g.oil`). After a move that clears none, it spreads to
one random neighbouring cell. The `oil` goal counts the oil left
(`g.oil_left`), so it rises when oil spreads.

`engine/match3.lua` owns all rules. Mutable state lives on each game instance:
`stone_hp`, `crate_hp`, `crate_kind`, `hazard`, `objects`, `discovered`,
`delivered`, `delivery_total`, and turn-growth flags. Tunnel topology and exit
membership remain fixed. `game_copy` isolates mutable state for hint/bot search.
Ordinary-match and direct-hit provenance are separate so a wrong-color match
cannot damage a crate while a ray can.

`engine/match3_elements_view.lua` loads and draws the shared presentation.
Object artwork is sampled across its footprint and clipped to those hexes.
Carpet and oil are each one patch (`E.patch`); oil adds two drifting bubble
layers, and `R.patch_tint` lets a game recolour one. For carpet, `E.patch` builds a signed distance field of the carpeted
hexes with rounded outer corners and filleted inner ones (`texture.hex_field`),
rebuilt only when the carpet changes, and draws the tiled swatch through it with
a shaded rim (`gfx.sdf_mask`), as SDF fonts are drawn.
Smaller pieces leave special floor artwork visible; this is spatial scaling
of the original sprite, not a recolored state. Tunnels use a fade between their
endpoints during the existing fall step. The guide uses the same atlas keys
as the board and HUD.

## Artwork and verification

The retired pre-Homescapes set contains **48 sprites** covering 24 Relic Rush states and 24 Christmas Market
states. Three stone strengths, twelve crate states,
two tunnel ends, three object stages, growth, delivery, exit and object icon
are individually painted. A second art direction replaces perspective boxes
with fitted paving, glazed seal panels and ribbon-wrapped lids. All surface
states were painted together in one atlas, using the shared mask template.
The two freestanding delivery icons retain the first atlas's authored alpha.
The [master](../engine/art/match3-elements/source.png),
[exact prompt](../engine/art/match3-elements/prompt.txt), and
[registration manifest](../engine/art/match3-elements/manifest.json) are retained.
These are historical assets, no longer drawn on the field except the provisional quest-resource image. The current atlases use original Homescapes sprites; see [the port contract](HOMESCAPES_HEX.md) for replacements and missing states.

```sh
python3 tools/match3_elements_art.py
python3 tools/match3_atlas.py
python3 tools/match3_elements_art.py --check
make CFLAGS="-O2 -g -Werror"
make test
make lint
```

Registration crops the fixed 8×6 master grid and resizes each cell uniformly.
The full-bleed painted surfaces are cut with the authoritative
[engine tile mask](../engine/art/hex-tile/README.md); this fixes geometry without
recoloring artwork or deriving one strength from another. Delivery icons keep
their original alpha. Every one of the 46 tile surfaces passes the strict
coverage, edge and spill check. The archived registration checks describe that former art set. The default atlas
is now 1024×2048 with original Homescapes frame aliases. Each game's inventory
and asset catalogue records the replacement. See the [historical review](review/match3-elements/README.md)
and [current review](review/homescapes-port/README.md).

Rule tests cover strength/color gating, one damage per wave, footprint
completion, growth suppression, state copying, shuffles, tunnel donor priority,
delivery conservation and victory gating. Campaign tests check topology,
opening moves and seeded bot completion. Bot feasibility does not establish
human difficulty; completion rates and comprehension need playtesting.
