# Shared match-3 engine

The current default rules and original-art atlas are documented in [Homescapes on hexes](HOMESCAPES_HEX.md). Legacy opt-in flags below remain supported; board elements are limited to those in Homescapes' story levels.

`require("match3")` is built into the engine on native, iOS and WebAssembly.
`engine/match3.lua` owns the hex grid, matching, specials, swaps, blockers,
collection, seeded refill, free reshuffle, hints, tools, objectives and move
budget. It also owns board selection, tap/swipe input, phase transitions,
cascade timing and piece animation poses. Games provide graphics, level data
and integer flags. There are no game-supplied behavior callbacks.

```lua
local match3 = require("match3")
local rules = match3.new{
    flags = 0,          -- all standard engine behaviors
    radius = 4, colors = 6, match_min = 4,
    levels = require("campaign").levels,
    kind_flags = {[0]=match3.GOAL, [2]=match3.WOOD, [4]=match3.STONE},
}
local skin = match3.skin()  -- no override: embedded neutral resources
-- Or match3.skin(require("match3_skin")): one game atlas + frame rectangles.
```

## Mission banner, kudos and sounds

`R.mission(text, title)` queues the level's mission. Once dialogue and dialogs
are gone it slides in across the middle of the screen, holds for 3.6 s and
slides away; a tap sends it on, and it blocks board input while shown. Games
call it from their level start and draw it with `R.draw_board_banners(dt)`
after the board's effects.

Cascades from the third wave and special-combo swaps award kudos once per
move at their highest level once the move has fully resolved (the board is
idle again): a word from `R.kudos_words` (four, game-supplied)
pops over the board with a rising arpeggio and a combo haptic.
`R.award_kudos(level)` shows one directly (`--kudos N` in the portrait games).

`R.play(name, level)` is the board's sound bank on `sfx.note`: `select`,
`swap`, `reject`, `match` (climbs with the cascade), `special`, `blast`,
`tool`, `mission`, `kudos`, `win` and `lose`. It is silent while `R.sound` is
false or sfx is disabled.

## Behavior flags

`flags` is a nonnegative integer bitmask; zero enables the standard behavior.
Combine exceptions with `|`. Unknown/noninteger bits are rejected. Per-kind
flags are a separate integer bitmask and may be combined for one kind.

| Board flag | Behavior |
| --- | --- |
| `NO_TRICKLE` | Use vertical column segments instead of diagonals |
| `NO_SPECIALS` | Do not create new specials from large matches |
| `NO_TOOLS` | Disable tool use and preserve charges |
| `NO_HINTS` | Suppress idle hint search/highlighting |
| `NO_RESHUFFLE` | Do not automatically reshuffle a dead board at settlement |
| `LINE_MATCHES` | Default: straight runs along three hex axes, plus four-cell rhombi at minimum three |
| `NO_RHOMBI` | With `LINE_MATCHES`, accept only straight runs. Hints and refill use the same shape rule. |
| `COLOR_TOOL` | Sunburst hits all pieces of the tapped kind. A chain absorbs a hit on its piece. |

| Kind flag | Meaning |
| --- | --- |
| `GOAL` | Count toward the collection objective and last-wave collection |
| `WOOD` | Count the piece toward the second resource total |
| `STONE` | Count it toward the third resource total |

The current topology is an axial hexagon, configurable from radius 1 to 16,
with arbitrary missing cells. The default is `match_min=3` with `LINE_MATCHES`;
explicit `flags=0` retains legacy connected-group matching.
Straight four creates an axis rocket, a four-cell rhombus creates a plane,
intersecting runs of at least five cells create a bomb, and straight five or
more creates a rainbow ball. Overlapping shapes form one group, count each
cell once, and use rainbow > bomb > rocket > plane reward priority. The swapped
cell is preferred for the reward. Power-ups are separate activatable objects
and do not participate in ordinary color matches. See the current
[shape and combination contract](HOMESCAPES_HEX.md) for the hex adaptation.

Level descriptors are content: name/lesson, moves, score, collection target
(`relics`), chains and ice counts. Optional `mask`
is a string of `CELLS` zero/one entries in axial column order; optional
`terrain` is a rank per cell for initial blockers. `ice_layers=2` permits
strong ice. Each entry in `stones` reserves a cell for one carved hex stone.
An adjacent match or a direct hit clears that stone. Optional `goals` lists
the HUD goals that win the level, in order,
from `score`, `idols`, `locks` (every blocker), `deliveries`, `carpet` and
`oil`. Without it, every counter on the board must be finished. Relic Rush
and Christmas Market name one to three per level and never `score`, as in
Homescapes. The
games' `campaign.lua` files contain these data; their
`rules.lua` modules only configure the engine, name kinds and handle the
restoration economy. Matching and input do not live in either game.

Optional stones, deliveries, carpet and oil extend these descriptors. Their exact schema, timing,
artwork and board-design rationale are in [Match-3 elements](MATCH3_ELEMENTS.md).

## Diagonal refill

A gravity step moves each gem at most one downward hex edge. A gem falls
straight down whenever its cell below is empty and movable. Only when that
cell is occupied, locked or missing may the gem slide diagonally. Each empty
destination takes the gem directly above before considering eligible side
donors; it never waits for a distant side donor instead of falling straight.
Eligibility uses the board at the start of the simultaneous step. Equal side
choices alternate deterministically by position without spending RNG. Two
destinations cannot consume the same gem in one step.

Every active cell with no active cell directly above it is an inlet: it
spawns vertically before considering side donors. All exposed column tops,
including the stepped edges and cells immediately below holes, refill together
instead of borrowing diagonally from the highest cell. Interior cells still
trickle around chains and ice; they spawn only if all upstream donors are
inactive or locked. Pieces never cross a missing cell or a locked donor.

`game_collapse(g)` fills the board and returns `from, steps`. `from[cell]` is
its original source ID (negative for a new gem). Each animation step contains
`tiles` and immediate `from` maps: every move is a single neighboring edge;
negative sources enter from above that inlet. Delivery tokens fall vertically,
never diagonally.
The controller displays all
steps at `FALL_STEP` seconds per step, then the landing interval, before it
checks another cascade or a terminal result. Reduced motion shortens the
same schedule; it does not skip rule steps.

## Graphics and the one-atlas skin

`match3.skin()` loads `engine/data/match3.png` from its resource directory.
The six pieces, rockets, bomb, rainbow ball, plane and available blocker states
come from the original Homescapes resources. Existing controls, HUD and effect
frames remain in the same atlas. The [registration manifest](../engine/art/match3/manifest.json)
records source hashes and transforms; the retired original-art
[prompt](../engine/art/match3/prompt.txt) remains historical provenance.

Both game atlases use `{path="filename.png", frames={name={x,y,w,h}, ...}}`.
`match3.skin(override)` loads the board atlas with chips, powers, floors,
blockers, selection, backgrounds and effects. `match3.hud(override)` loads
the HUD atlas with score, completion and the normal, selected, pressed, hover
and disabled states of pickaxe, dynamite, sunburst and Pause. The engine
neutral preview uses its built-in atlas for both. The loaders check frame
bounds and required names.

`texture.region(atlas, rectangle)` returns a borrowed ordinary texture view.
Every sprite retains its own dimensions while sharing the atlas's GPU
storage, so `gfx.image`, `gfx.image_part`, forms and particles draw the authored
regions directly. Nested views compose. Invalid bounds return an empty
texture. Keep the owner alive; freeing a view leaves the owner intact.
`image.additive=true` affects just that view, permitting additive glows and
alpha-blended pieces in one atlas. Font glyphs, engine shape primitives and
transient beam/particle geometry remain normal renderer facilities.

Relic Rush and Christmas Market each use a 2048×4096 `data/match3.png`
for board imagery and a 1024×1024 `data/match3-hud.png` for UI. Goal displays
can reuse the board's chip and objective frames. The generated
`lua/match3_skin.lua` and `lua/match3_hud.lua` register both textures.
The shared floor renderer in `match3.elements_view` draws an edge-to-edge
backing and insets each face by `R.GROUND.seam_width` (0.18 design units by
default) at its radius. The seam shows the backing colour through that inset.
`R.GROUND.frame` lists the board's outline bands from the cells outwards, each
`{width, top, bottom}`. Every band is drawn for every cell under the faces, so
only the silhouette's outline remains, and as a vertical gradient, so the
board's top edges catch the light and its bottom edges fall into shade.
Once the board has settled, the frame is drawn along the silhouette's own
edges (`E.silhouette_edges`) as thick lines with a disc at each corner, which
rounds the outline's corners; while cells fly in, each cell grows its own hexes.
`elements.cradle_ground(R)` applies the shared Cradle of Rome preset
(`E.CRADLE_GROUND`), after the first game's frame pieces: a tan inner lip, a
rusty line and dark brown wood; `inner_shadow` (`{width, alpha, steps}`), the
frame's shade on the cells along the board's edge; `leaves`, a sprite drawn on
the board's north-west, north-east and south-east outer corners;
dark brown grout (`seam`, `seam_width`) and the cell-state
tiles. Games supply the fallback face colour as the skin's `board_face`.
Imported and neutral boards use the same geometry without a frame.
Floor tiles are ordinary hex sprites. `tools/board_tiles.py` bakes the eight
shared Cradle of Rome slots from `engine/art/board-tiles/tiles.json` into each
listed game's `data/board-tiles/`: a bevel lit from above, a top-to-bottom face
gradient and a neutral stained-paper grain (`tools/board_grain.py`), cut by the
canonical flat-top mask.
`R.GROUND.tiles` maps cell states to those sprites' art keys. A game that
sets it gets Cradle of Rome's states drawn as whole tiles over the floor and
under the pieces: `selected`, `hover` (mouse only, from `inp.hover`), `bonus`
(every cell `rules.game_tool_area(g, tool, cell)` returns for the armed tool
at the hovered or pressed cell), `ice` (under iced pieces), `double` (a
plaque with two layers) and `wave` (the light that sweeps across the board
in its entrance, in place of the halo). A level's `oil_double` lists `oil`
cells that take two hits; each still counts once toward the goal.
`--level N --cell-states` shows them all at once. Selection and hints animate piece scale.
[In-game board review](review/match3-board-seams/README.md), [frame](review/match3-board-frame/README.md).

For a game view, initialize presentation data with `match3.view{...}`, then
call `rules.bind_view(state)`. The game supplies `HEX_R` and an optional authored `piece_width`;
rendering uses `cell_pos` and `piece_pose`. Draw the floor with
`elements.ground(state, rules, shake_x, floor)` before pieces and blockers.
The floor table can supply authored texture keys for ordinary and covered
cells. The shared renderer also draws the floor's entrance flash.

The board screen's layout belongs to the engine and is the same in every game.
A game must not define or replace `state.layout`: `bind_view` and `board_input` assert this.
Call `state.layout()` once per frame. It is measured up from the bottom edge, at the size it has on a 480×1040 phone, so a shorter screen crops the top of the backdrop instead of squeezing the board:

- **`tools_y`:** the top of the tool row, 100 units above the bottom edge.
- **`board_origin` and `BOARD_CLIP`:** the board, centred 409 units above the bottom edge.
- **`hud_rect`:** a 64-unit band 772 units above the bottom edge. The themed signboard joins the Moves medallion, goals and Settings on its midline. Toasts sit just below it (`board_toast`).
- **`backdrop_rect(size, full, min_height)`:** where to draw the backdrop painting. It covers the screen and stands on the bottom edge. The default minimum is 1040 units tall. Christmas Market uses 960 units to keep its stall windows visible on shorter phones. Paint a backdrop's scenery in the top 22% of its height.

`match3.bind_board_ui` measures the goal rows between Moves and Settings.
Goals wrap to a second row when they exceed the available width. The
`signboard_goal` skin variant paints the icon, count or completion tick
directly on the atlas backplate. The Settings hit box follows its artwork
during the entrance animation. The Settings and Guide forms and the Results panel geometry also
come from `match3`. Games provide the skin, guide content and screen actions.

Engine methods `reset_board`, `board_update`, `board_input` and `select_tool`
own changes to interaction state. `notice`, `tone` and `vfx_wave` are presentation
outputs. Games own story, city and screen navigation.

## Reproduction and verification

```sh
python3 -m pip install -r tools/requirements-assets.txt  # pinned authoring toolchain
python3 tools/match3_atlas.py       # defaults + both game atlases/frame data
make gen                          # only needed when engine/api.xml changes
make CFLAGS="-O2 -g -Werror"
make test
make lint
python3 tools/capture_trickling.py
./build/relic-rush --headless --fresh --mute --default-match3 --level 7 --shot default.png
./build/relic-rush --headless --fresh --mute --smoke
./build/christmas-market --headless --fresh --mute --smoke
```

Use Xvfb on Linux for the renderer/smoke commands. `make test` checks generated
code, the atlas registrations and per-pixel preservation of every override
source. Engine tests cover independent instances, radius/minimum/flag
configuration; shared gravity tests run against both games across all ten
masks, including holes, locks, special identity, donor competition,
conservation, deterministic replay and inlet spawning. The actual update
loop checks normal/reduced-motion timing. `build/test-platform` verifies
nested UVs, partial drawing, additive views and ownership with real pixels.

See the [default skin review](review/match3/README.md) and each game's
`docs/review/trickling/README.md` for checked game captures.
