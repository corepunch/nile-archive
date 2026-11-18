# Match-3 elements and board design

The engine follows Cradle of Rome. A board has chains, ice, carved stones and
tablets (blue plaques). Matches only clear and there are no special pieces; power comes from tools.

Relic Rush and Christmas Market share rules, but author their own shapes,
terrain priorities, element placements and teaching order. The playable
campaigns are 100 boards each, text files in `games/<game>/levels` validated by `tools/hex_levels.py` (see [Level design](LEVEL_DESIGN.md)); their design notes are in
[Relic Rush](../games/relic-rush/docs/board-progression.md) and
[Christmas Market](../games/christmas-market/docs/board-progression.md).

## Reference and adaptation

The [Tropicats reference](tropicats-reference/README.md) records extracted
content separately from inferred behavior. This implementation is our own
design: exact Tropicats cascade timing was not recovered from its encrypted
executable.

| Family | Implemented behavior | Design purpose |
| --- | --- | --- |
| Carved stone | A solid cell with one hit and no piece inside. An adjacent ordinary match or a direct tool hit breaks it. | Gate a bridge or open a connection between work areas. |
| Tablet | One or two layers under a piece (`oil`, `oil_double`). A match on its cell or a tool hit removes a layer. Tablets never spread. | The campaigns' win condition: clear every tablet. |

The lock counter includes all remaining chain, ice and stone hits. Tablets
have their own goal counter. A level's `goals` list names the goals it shows
and needs; without one, victory requires every positive goal. A board with
more than four goals uses two HUD rows.

**Buried finds.** `reveal = {picture=<art>, icon=<goal art>, floor="oil", object=true, bark=<line>}`
draws one image across the level's tablet cells (each uncovered cell shows its part beneath the
piece), uses `icon` for the tablet goal, speaks `bark` once half the cells are clear, and on a first
clear fades the pieces and holds the whole object before the result. The picture carries its own
transparent margin so every covering cell samples inside it. Without `object`, the picture covers the whole board and peeks through
the cleared tablets. On the win the game fades pieces and blockers by
`elements.reveal_cover(R, rules)`, and the first-clear beat waits for
`elements.reveal_holding(R, rules)`, so the finished picture is seen before anyone speaks. Replays
show the picture without the fade, hold or notice. `--level N --reveal F` clears the share `F` of
the tablets for review; `--reveal 1` wins the board as a first clear and plays its beat.

Earlier versions also had colour crates, hidden-object footprints, spreading
growth, tunnels, deliveries, carpet, spreading oil and other imported
blockers. The engine no longer has any of them.

## Shape before decoration

The user's three hex-board screenshots demonstrate a useful hierarchy:

1. **Two long interior channels:** central spine, side lanes, and deliberate
   top/bottom connections. Put gates at the connections and targets in the
   lanes; a hole changes access.
2. **A broad bowl with a narrow cap:** generous matching space below, a small
   constrained work area above. Concentrate targets instead of shaving
   arbitrary perimeter cells to make another mask.
3. **Separated chambers:** broad negative-space channels make rooms readable.
   A narrow connection determines how one chamber feeds another.

Recognizable families may return. Change the task within the shape: first
open a bridge, later clear tablets behind it.
Do not invent an unrelated nick in the edge merely to make every mask unique.
Small boards are useful; population is a pacing choice, not a score of quality.

For each board, author a one-sentence intended decision, its working regions,
the connection between them, and the placement of goals. Validate that every
target can be reached and every playable tip participates in a match line.
Keep opening lessons and breathers simple. Introduce one unfamiliar rule,
repeat it with a changed constraint, then combine known rules.

## Level schema and runtime

Optional descriptor fields use **zero-based engine cell IDs**. The generated
`lua/boards.lua` holds them, written from the level text files. Omitted fields are empty.

```lua
stones = {{cell=stone_cell}}
oil = {tablet_cell, another_tablet_cell}
oil_double = {tablet_cell}   -- among `oil`: takes two hits
```

Every element must occupy an active cell; overlaps fail at level creation.
Stones are reserved before the scalar `chains` and `ice` counts are placed by
terrain rank.

`engine/lua/match3.lua` owns all rules. Mutable state lives on each game instance:
`chain`, `ice`, `stone_hp` and `oil`. `game_copy` isolates mutable state for
hint/bot search. A wave deals at most one hit to each stone.

`engine/lua/match3/elements_view.lua` draws the board. Tablets use the Cradle of
Rome tablet tiles (`tile-tablet-single`, `tile-tablet-double`), or the game's
`floor.covered` tile. Each carved stone is one face-on hex sprite. The guide
and HUD use the same goal icons.

## Artwork and verification

The [element master](../engine/art/match3-elements/source.png) holds 48 painted
surface states, 24 per game. Only the three stone strengths are registered; the
other cells served mechanics the engine no longer has. The
[exact prompt](../engine/art/match3-elements/prompt.txt) and
[registration manifest](../engine/art/match3-elements/manifest.json) are retained.
The catalogues document the
[Relic Rush](../games/relic-rush/docs/asset-catalogue.md#themed-board-art) and
[Christmas Market](../games/christmas-market/docs/asset-catalogue.md#themed-board-art)
atlases.

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
recoloring artwork or deriving one strength from another. Every registered tile
surface passes the strict coverage, edge and spill check. See the
[historical review](review/match3-elements/README.md).

Rule tests cover stone strength, one damage per wave, state copying, shuffles,
tablets that never spread, and victory gating. Campaign tests check topology,
opening moves and seeded bot completion. Bot feasibility does not establish
human difficulty; completion rates and comprehension need playtesting.
