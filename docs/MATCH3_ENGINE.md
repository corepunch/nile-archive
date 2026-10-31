# Shared match-3 engine

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
    kind_flags = {[0]=match3.GOAL, [1]=match3.THAW,
                  [2]=match3.WOOD, [4]=match3.STONE},
}
local skin = match3.skin()  -- no override: embedded neutral resources
-- Or match3.skin(require("match3_skin")): one game atlas + frame rectangles.
```

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
| `NO_THAW` | Disable neighboring ice damage from thawing kinds |

| Kind flag | Meaning |
| --- | --- |
| `GOAL` | Count toward the collection objective and last-wave collection |
| `THAW` | Clear neighboring ice when this kind is matched |
| `WOOD` | Count the piece toward the second resource total |
| `STONE` | Count it toward the third resource total |

The current topology is an axial hexagon, configurable from radius 1 to 16,
with arbitrary missing cells. `match_min` defaults to three connected pieces;
both existing games select four. Five/six-piece rewards on those games derive
from the configured minimum plus one/two. Tile kinds and specials remain
separate, so a moving special retains its kind and behavior.

Level descriptors are content: name/lesson, moves, score, collection target
(`relics`), excavation target (`soil`), chains and ice counts. Optional `mask`
is a string of `CELLS` zero/one entries in axial column order; optional
`terrain` is a rank per cell for initial blockers. `ice_layers=2` permits
strong ice. The games' `campaign.lua` files contain these data; their
`rules.lua` modules only configure the engine, name kinds and handle the
restoration economy. Matching and input do not live in either game.

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
`tiles` and immediate `from` maps: every move is a single neighboring edge,
and negative sources enter from above that inlet. The controller displays all
steps at `FALL_STEP` seconds per step, then the landing interval, before it
checks another cascade or a terminal result. Reduced motion shortens the
same schedule; it does not skip rule steps.

## Graphics and the one-atlas skin

`match3.skin()` loads the engine's embedded `engine/data/match3.png`: neutral
gold, brick, timber, grain, stone, water, fruit and fish, plus board layers,
specials, all five authored states for four controls, HUD elements and effect
frames. Resources were informed by [Cradle of Rome's collection categories](https://www.gamehouse.com/blog/2016/04/cradle-of-rome-walkthrough/);
the art is original. The [full prompt](../engine/art/match3/prompt.txt) and
[registration](../engine/art/match3/manifest.json) preserve its origin.

An override is a data table `{path="match3.png", frames={name={x,y,w,h}, ...}}`.
Required names cover six kinds, three special axes, bomb/prism, terrain,
selection/hint, guide/cell mask, score/completion, a background, and the five
normal/selected/pressed/hover/disabled states of pickaxe, dynamite, sunburst
and pause. Incomplete or out-of-bounds skins fail loudly. Optional entries
include extra packs, scenes, portraits, panels and effect frames.

`texture.region(atlas, rectangle)` returns a borrowed ordinary texture view.
Every sprite retains its own dimensions while sharing the atlas's GPU
storage, so `gfx.image`, `gfx.image_part`, forms and particles draw the authored
regions directly. Nested views compose. Invalid bounds return an empty
texture. Keep the owner alive; freeing a view leaves the owner intact.
`image.additive=true` affects just that view, permitting additive glows and
alpha-blended pieces in one atlas. Font glyphs, engine shape primitives and
transient beam/particle geometry remain normal renderer facilities.

Relic Rush packs all three piece sets, both scenes, the fallback background,
board/control/HUD art and its light sprite in one 2048×4096 atlas. Christmas
Market uses one 2048×2048 atlas, including the winter background and Noelle's
board portrait. Packing copies existing RGBA canvases without resizing,
recoloring or manufacturing states. The old source files remain available to
the art tools and non-board screens. Both games use overrides by default;
`--default-match3` exercises the neutral fallback in the actual game.

For a game view, initialize presentation data with `match3.view{...}`, then
call `rules.bind_view(state)`. Layout supplies `board_origin`, `HEX_R`, optional authored `piece_width` and
`BOARD_CLIP`; rendering uses `cell_pos` and `piece_pose`. Engine methods
`reset_board`, `board_update`, `board_input` and `select_tool` own the changes
to interaction state. `notice`, `tone` and `vfx_wave` are presentation outputs,
not rule customization hooks. The game still owns story, city and screen
navigation.

## Reproduction and verification

```sh
python3 -m pip install -r tools/requirements-assets.txt  # pinned authoring toolchain
python3 tools/match3_atlas.py       # defaults + both game atlases/frame data
make gen                          # embeds Lua, frame data and default PNG
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
