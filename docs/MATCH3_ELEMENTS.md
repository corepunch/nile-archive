# Match-3 elements and board design

The current default rules and original-art atlas are documented in [Homescapes on hexes](HOMESCAPES_HEX.md). The engine keeps only mechanics found in Homescapes' story levels: stones (boxes), chains, ice, deliveries, carpet and oil.

Relic Rush and Christmas Market share rules, but author their own shapes,
terrain priorities, element placements and teaching order. The playable
campaigns are in each game's `lua/campaign.lua`; their design notes are in
[Relic Rush](../games/relic-rush/docs/board-progression.md) and
[Christmas Market](../games/christmas-market/docs/board-progression.md).

## Reference and adaptation

The [Tropicats reference](tropicats-reference/README.md) records extracted
content separately from inferred behavior. This implementation is our own
design: exact Tropicats cascade timing was not recovered from its encrypted
executable.

Saga's dragon objectives also establish delivery as a distinct task from
matching colors: clear a route to a destination.
[Official Saga modes](https://candycrush.zendesk.com/hc/en-us/articles/360000754897-Which-game-modes-will-I-find).

| Family | Implemented behavior | Design purpose |
| --- | --- | --- |
| Stone / box | A solid cell with 1–3 hits, no piece inside. Adjacent ordinary matches or direct special/tool hits remove one layer per wave. | Gate a bridge or divide work into successive openings. A three-hit wall needs repeated access, not just more score. |
| Relic parcel / present delivery | A nonmatching, unswappable token. It falls straight down and is consumed once at a marked exit. Blasts cannot destroy it; shuffles keep it in place. | Turn clearing into route preparation. Unlike normal pieces it cannot drift diagonally into an unintended bottom pocket. |

The lock counter includes all remaining chain, ice and stone hits. Delivery,
carpet and oil have independent goal counters. A level's `goals` list names
the goals it shows and needs; without one, victory requires every positive
goal. A board with more than four goals uses two HUD rows.

Earlier versions also had colour crates, hidden-object footprints under snow,
spreading ribbon/vines, tunnels, oil cans and a thaw rule. None of them is in
Homescapes' story levels, so they were removed from the engine.

## Shape before decoration

The user's three hex-board screenshots demonstrate a useful hierarchy:

1. **Two long interior channels:** central spine, side lanes, and deliberate
   top/bottom connections. Put gates at the connections and targets in the
   lanes; a hole changes access and useful ray directions.
2. **A broad bowl with a narrow cap:** generous matching space below, a small
   constrained work area above. Concentrate targets instead of shaving
   arbitrary perimeter cells to make another mask.
3. **Separated chambers:** broad negative-space channels make rooms readable.
   A narrow connection determines how one chamber feeds another.

Recognizable families may return. Change the task within the shape: first
open a bridge, later clear a color gate there, finally deliver through it.
Do not invent an unrelated nick in the edge merely to make every mask unique.
Small boards are useful; population is a pacing choice, not a score of quality.

For each board, author a one-sentence intended decision, its working regions,
the connection between them, and the placement of goals. Validate that every
target can be reached, every playable tip participates in a match line, and
every delivery has a complete vertical path. Keep opening lessons and
breathers simple. Introduce one unfamiliar rule, repeat it with a changed
constraint, then combine known rules. A board with six mechanics is a late
combination, not a tutorial.

## Level schema and runtime

Optional descriptor fields use **zero-based engine cell IDs**. The campaign's
`cell(q,r)` helper converts authored axial coordinates. Omitted fields are empty.

```lua
stones = {{cell=stone_cell, hp=3}}
deliveries = {tokens={token_cell}, exits={destination_cell}}
carpet = {seed_cell, another_seed}
oil = {oil_cell, another_oil_cell}
```

Every element must occupy an active cell; overlaps, invalid strengths and
unreachable delivery routes fail at level creation. Explicit elements are
reserved before the scalar `chains` and `ice` counts are placed by terrain rank.
`carpet` seeds Homescapes' carpet: a match group touching a carpeted cell, or a
move begun on one, carpets every cell it hits (`g.carpet`). The `carpet` goal
counts the active cells still uncovered (`g.carpet_total - g.carpeted`).
`oil` is Homescapes' oil: one layer under a piece, cleared by a match
on its cell or a blast (`g.oil`). After a move that clears none, it spreads to
one random neighbouring cell. The `oil` goal counts the oil left
(`g.oil_left`), so it rises when oil spreads.

`engine/match3.lua` owns all rules. Mutable state lives on each game instance:
`chain`, `ice`, `stone_hp`, `carpet`, `oil`, `delivered`, `delivery_total` and
the turn's `oil_cleared` flag. Delivery exits remain fixed. `game_copy` isolates
mutable state for hint/bot search. A wave deals at most one hit to each stone.

`engine/match3_elements_view.lua` loads and draws the shared presentation.
Carpet and oil are each one patch (`E.patch`); oil adds two drifting bubble
layers, and `R.patch_tint` lets a game recolour one. For carpet, `E.patch` builds a signed distance field of the carpeted
hexes with rounded outer corners and filleted inner ones (`texture.hex_field`),
rebuilt only when the carpet changes, and draws the tiled swatch through it with
a shaded rim (`gfx.sdf_mask`), as SDF fonts are drawn.
Smaller pieces leave special floor artwork visible; this is spatial scaling
of the original sprite, not a recolored state. The guide uses the same atlas keys
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
These are historical assets, no longer drawn on the field; only the stone and delivery frames are still loaded. The current atlases use original Homescapes sprites; see [the port contract](HOMESCAPES_HEX.md) for replacements and missing states.

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

Rule tests cover stone strength, one damage per wave, state copying, shuffles,
delivery conservation, carpet and oil spreading, and victory gating. Campaign tests check topology,
opening moves and seeded bot completion. Bot feasibility does not establish
human difficulty; completion rates and comprehension need playtesting.
