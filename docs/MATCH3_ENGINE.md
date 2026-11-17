# Shared match-3 engine

The engine follows Cradle of Rome: matches only clear, and the board elements are chains, ice, carved stones and tablets. See [Match-3 elements](MATCH3_ELEMENTS.md).

`require("match3")` is built into the engine on native, iOS and WebAssembly.
`engine/match3.lua` owns the hex grid, matching, swaps, blockers,
collection, seeded refill, free reshuffle, hints, tools, objectives and move
budget. It also owns board selection, tap/swipe input, phase transitions,
cascade timing and piece animation poses. Games provide graphics, level data
and integer flags. There are no game-supplied behavior callbacks.

```lua
local match3 = require("match3")
local rules = match3.new{
    flags = 0,          -- all standard engine behaviors
    columns = 9, rows = 12, colors = 5, match_min = 3,
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

Cascades from the third wave award kudos once per
move at their highest level once the move has fully resolved (the board is
idle again): a word from `R.kudos_words` (four, game-supplied)
pops over the board with a rising arpeggio and a combo haptic.
`R.award_kudos(level)` shows one directly (`--kudos N` in the portrait games).

`R.play(name, level)` is the board's sound bank on `sfx.note`: `select`,
`swap`, `reject`, `match` (climbs with the cascade),
`tool`, `mission`, `kudos`, `win` and `lose`. It is silent while `R.sound` is
false or sfx is disabled.

## Behavior flags

`flags` is a nonnegative integer bitmask; zero enables the standard behavior.
Combine exceptions with `|`. Unknown/noninteger bits are rejected. Per-kind
flags are a separate integer bitmask and may be combined for one kind.

| Board flag | Behavior |
| --- | --- |
| `NO_TRICKLE` | Use vertical column segments instead of diagonals |
| `NO_TOOLS` | Disable tool use and preserve charges |
| `NO_HINTS` | Suppress idle hint search/highlighting |
| `NO_RESHUFFLE` | Do not automatically reshuffle a dead board at settlement |
| `LINE_MATCHES` | Default: straight runs along three hex axes. Hints and refill use the same shape rule. |
| `COLOR_TOOL` | Sunburst hits all pieces of the tapped kind. A chain absorbs a hit on its piece. |

| Kind flag | Meaning |
| --- | --- |
| `GOAL` | Count toward the collection objective and last-wave collection |
| `WOOD` | Count the piece toward the second resource total |
| `STONE` | Count it toward the third resource total |

Both games use a `columns` x `rows` rectangle of flat-top hexes (9 x 12, odd
columns half a cell lower) with arbitrary missing cells. The hexagon mode
(`radius`, 1 to 16) still exists and the engine tests use it. The default is
`match_min=3` with `LINE_MATCHES`; explicit `flags=0` retains legacy
connected-group matching. A match is a straight line of three or more pieces
of one kind along the three hex axes. Matches only clear. As in Cradle of
Rome, no line length or shape creates a special piece; a player's extra power
comes from the game's tools and boosters. Overlapping runs form one group and
count each cell once. Longer runs can still pay more through
`resource_multipliers`.

Level descriptors are content. Each game's boards are text files in
`games/<game>/levels`, validated by `tools/hex_levels.py` (see
[Level design](LEVEL_DESIGN.md)), which generates `lua/boards.lua`; move
budgets come from `tools/tune_moves.py`. A descriptor holds the name, lesson,
moves, tablets (`oil`), chains and ice. Optional `mask`
is a string of `CELLS` zero/one entries in axial column order; optional
`terrain` is a rank per cell for initial blockers. `ice_layers=2` permits
strong ice, and `double_chains=N` makes the first N of `chains` take two hits. Each entry in `stones` reserves a cell for one carved hex stone.
An adjacent match or a direct hit clears that stone. Optional `goals` lists
the HUD goals that win the level, in order,
from `score`, `idols`, `locks` (every blocker) and `oil` (tablets). Without
it, every counter on the board must be finished. Relic Rush and Christmas
Market win every board by clearing its tablets. The
games' `campaign.lua` files contain these data; their
`rules.lua` modules only configure the engine, name kinds and handle the
restoration economy. Matching and input do not live in either game.

Optional stones and tablets extend these descriptors. Their exact schema, timing,
artwork and board-design rationale are in [Match-3 elements](MATCH3_ELEMENTS.md).

Resource campaigns can pass a loadout to `game_start`. Its `kinds` feed
both the seeded opening and refills. Its `multipliers` apply to the longest
straight match through each clearing piece. Resource entries credit a
wallet `slot` or a `tool` meter. An ordinary match can fill a tool meter
and turn each full meter into one charge. The `tool_meter` keys identify
unlocked slots. A campaign can supply `tool_slots` as an ordered list of
descriptors with an `action`, `icon`, `rank` and `effect` (targeting hint).
The slot index owns the meter and the target geometry across descriptor
changes. `match3.TOOL_SIZE` (86 points) is the toolbar's button width. The
slots and Pause share one row with 4-point gaps and margins, and narrower
screens shrink all five evenly. At 480 points a button's glyph draws about a
fifth larger than a board piece; keep it at least piece-sized everywhere.
Relic Rush uses `single_charge_tools` to cap a slot at one use.
Christmas Market keeps a count and a remainder. Both games persist the
inventory through `update_bonus_charges` as waves resolve. Tool hits still
earn the base wallet yield. A game can supply `sunburst_targets` for the
legacy earned tool so the preview and hit share the same cell mask.

Targeted slot actions include `hit`, `blast`, `row`, `row_lightning`,
`color` and `color_pierce`. The row-lightning preview runs the same
selection against a copy of the seed. Color pierce removes at most one lock
per targeted gem and clears the gem if exposed. The instant `charge` action
fills the other unlocked meters by their threshold divided by its descriptor's
`charge_divisor` (default two). It keeps its own use if there is nothing to
charge. Legacy `extra_tools` names the effects after the first three tools.
`game_tool` returns the effect's name for an action that clears nothing, so
the view can display `R.tool_done_notes[name]` without starting a clear wave.

A loadout's `extra_moves` adds moves to the level's budget.

`match3.game.campaign_ladder(island, unlocks, journey, slots)` gives a game a
Cradle of Rome ladder: catalogue buildings bought in order, with optional
piece and bonus unlocks. Story buildings keep the journey's schedule and hold the next
new level; the others open after their clear and must be placed before the
next story building. It installs the gate, reserve, shop order and waivers
for older saves on the island module. Both portrait games use it. A game whose
campaign buildings are more than story types `0..WONDERS-1` in
order supplies three island hooks, which the ladder installs. `next_build(city, level)` names the
building to place next. `ladder_blocked(city, level, kind)` returns
`"built"`, `"later"` with the clear it waits for, `"earlier"`, false when the
building can be placed, or nil for shop items. `catalogue_order` lists catalogue
rows in shop order. Relic Rush's twenty-step ladder uses all three; without
them the engine keeps the story-only rules.

A swap into a chain sends the movable gem halfway toward the blocked cell
and back. The chained gem stays in place. This plays the ordinary rejected
swap's sound and haptic and spends zero moves. Reduced motion shortens the
out-and-back animation.

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
negative sources enter from above that inlet.

`refill_damping=N` in `match3.new` damps long cascades. From wave N of a
move's cascade (`g.combo`), every piece the refill spawns takes a kind that
completes no match where such a kind exists. Pieces already on the board still
fall and can match, so long chains stay possible but rare. It is off by default.
The controller displays each step for `FALL_STEP` seconds. A gem briefly
squashes and rebounds upward when it comes to rest in its slot, even if other
gems are still falling. The last arrivals use the existing landing interval
before the next cascade or result check. Reduced motion shortens the same
schedule and omits the rebound.

## Graphics: one atlas per kind of art

`match3.skin()` loads the engine's default skin from `engine/data/board/` in
its resource directory: one atlas each for pieces, blockers, cells, boosters,
HUD and effects, and a separate background. The pieces, controls, HUD, blockers and effect
frames come from the engine's own authored art. The [registration manifest](../engine/art/match3/manifest.json)
records source hashes and transforms; the retired original-art
[prompt](../engine/art/match3/prompt.txt) remains historical provenance.

A skin definition lists typed atlases under `sheets`, each
`{path="board/pieces.png", frames={name={x,y,w,h}, ...}}`, standalone
`images` such as backgrounds, and `aliases`; a plain `{path=, frames=}` is a
one-sheet definition, and `engine=true` reads paths with `texture.load_engine`.
`match3.atlas(definition)` flattens all of it into one table of named images,
loading each sheet once. `match3.skin(override)` loads the board: pieces,
blockers, cells, effects and boosters, with the backgrounds. `match3.hud(override)`
loads the HUD and boosters atlases: score, completion, the five states of Pause
and the game's booster buttons. A board without booster slots falls back to the
default skin's pickaxe, dynamite and sunburst buttons.
The engine neutral preview uses its built-in skin for both. The loaders check
frame bounds and required names. [Asset layout](ASSET_LAYOUT.md) lists which
frames go in which atlas.

`texture.region(atlas, rectangle)` returns a borrowed ordinary texture view.
Every sprite retains its own dimensions while sharing the atlas's GPU
storage, so `gfx.image`, `gfx.image_part`, forms and particles draw the authored
regions directly. Nested views compose. Invalid bounds return an empty
texture. Keep the owner alive; freeing a view leaves the owner intact.
`image.additive=true` affects just that view, permitting additive glows and
alpha-blended pieces in one atlas. Font glyphs, engine shape primitives and
transient beam/particle geometry remain normal renderer facilities.

Relic Rush and Christmas Market each ship `data/board/pieces.png`,
`blockers.png`, `cells.png`, `boosters.png`, `hud.png` and `fx.png`, with
backgrounds as separate JPEGs in `data/board/backs/`. Goal displays can reuse
the board's chip and objective frames. The generated `lua/match3_atlases.lua`
gives each atlas's frames; `lua/match3_skin.lua` and `lua/match3_hud.lua` pick
the atlases, images and aliases for the board and its HUD.
The shared floor renderer in `match3.elements_view` draws an edge-to-edge
backing and insets each face by `R.GROUND.seam_width` (0.18 design units by
default) at its radius. The seam shows the backing colour through that inset.
`elements.cradle_ground(R)` applies the shared Cradle of Rome preset
(`E.CRADLE_GROUND`) for the frame, soft drop shadow, dark brown grout
(`seam`, `seam_width`) and cell-state tiles. Games supply the fallback face
colour as the skin's `board_face`.
`elements.load_frame` loads each game's stone atlas and generated join coordinates.
The renderer checks each active cell's six neighbours and places atlas
regions along the exposed edges, inward corners and outward corners,
including the edges of holes. It keeps those placements relative to the board
origin for shake and resize, and rebuilds them when the active mask changes.
The atlas also provides the rim under each cell during the entrance.
The soft shadow follows the settled outline. The renderer grows the union
of the active hexes to the rim, shifts it down and draws one signed-distance
mask. Equal distances from that shifted outline get the same opacity. The
mask is cached with the frame layout and follows board shake and resize.
The renderer can substitute decorated atlas regions at outward tips and
the inner shoulders above an opening. The source join contains the stone,
front-facing ornament and contact shadow. The decorated joins are drawn over
the tile faces, with the playable pieces drawn above them. An open-top channel can use larger
sprigs baked into its inward tips.
An optional atlas slot adds snow to the highest horizontal north edges of the
outer rim. Inner channel edges use bare stone.
Imported and neutral boards use the default ground geometry.
[Frame generator, paint guide and in-game review](review/board-frame-atlas/README.md).
[Painted join atlas and in-game review](review/board-frame-decorations/front.md).
[Board shadow before and after](review/board-frame-decorations/shadow.md).
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
Floors can set `tablet_hint=true` to help players spot the last one to three
tablets. The reminder shares the move suggestion's five-second idle delay
and resets with it on board interaction. A blue wash lights the floor while
the original particle sprites sweep clockwise along the six bevel edges. A
double tablet uses green. The 3.6-second pulse repeats every nine seconds of
continued inactivity. Reduce Motion hides it. See the
[Cradle of Rome 2 glow reference](cradle-of-rome-reference/README.md#last-puzzle-tile-glow).
`--level N --cell-states` shows them all at once. Selection and hints animate piece scale.
When a hit removes a floor layer (ice, a double tablet's green face or a
tablet), `engine/match3_shatter.lua` breaks that cell's own artwork apart.
At bind it makes eight Voronoi fractures of the unit hex; each break picks one
and one of the hex's twelve symmetries. The pieces are cut from the layer's
texture with `gfx.image_poly`. Cracks glow for 0.07 s, then the shards burst outwards,
spin and tumble (a darker side face shows their thickness), fall under gravity
and fade over about 0.55 s above a puff of earth-coloured dust (`S.DUST`). No
art is baked, so new tile art and packs shatter unchanged.
`E.layer_art` names the art `E.ground` paints, and a game's `R.board_floor()`
returns the floor dress both use. Reduce Motion shows nothing. Review it
with `--fx shatter` (`reel fx-shatter` in Relic Rush and Christmas Market).
[In-game board review](review/match3-board-seams/README.md).

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
configuration; shared gravity tests run against both games across every
board mask, including holes, locks, piece identity, donor competition,
conservation, deterministic replay and inlet spawning. The actual update
loop checks normal/reduced-motion timing. `build/test-platform` verifies
nested UVs, partial drawing, additive views and ownership with real pixels.

See the [default skin review](review/match3/README.md) and each game's
`docs/review/trickling/README.md` for checked game captures.
