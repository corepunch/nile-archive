# Shared match-3 engine

The current default rules and original-art atlas are documented in [Homescapes on hexes](HOMESCAPES_HEX.md). Legacy opt-in flags and campaign-only elements below remain supported.

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
| `NO_THAW` | Disable neighboring ice damage from thawing kinds |
| `LINE_MATCHES` | Default: straight runs along three hex axes, plus four-cell rhombi at minimum three |

| Kind flag | Meaning |
| --- | --- |
| `GOAL` | Count toward the collection objective and last-wave collection |
| `THAW` | Clear neighboring ice when this kind is matched |
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
(`relics`), excavation target (`soil`), chains and ice counts. Optional `mask`
is a string of `CELLS` zero/one entries in axial column order; optional
`terrain` is a rank per cell for initial blockers. `ice_layers=2` permits
strong ice. Optional `goals` lists the HUD goals that win the level, in order,
from `score`, `idols`, `sand`, `locks` (every blocker), `discoveries`,
`deliveries`, `carpet` and `oil`. Without it, every counter on the board must be finished. Relic Rush
and Christmas Market name one to three per level and never `score`, as in
Homescapes. The
games' `campaign.lua` files contain these data; their
`rules.lua` modules only configure the engine, name kinds and handle the
restoration economy. Matching and input do not live in either game.

Optional stones, color crates, hidden-object footprints, growth, tunnels and
delivery objectives extend these descriptors. Their exact schema, timing,
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
`tiles` and immediate `from` maps: every move is a single neighboring edge,
except a directed tunnel transfer; negative sources enter from above that inlet.
Tunnel steps fade between endpoints instead of crossing unrelated cells.
Delivery tokens fall vertically or through tunnels, never diagonally.
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

An override is a data table `{path="match3.png", frames={name={x,y,w,h}, ...}}`.
Required names cover six kinds, three special axes, bomb/prism/plane, terrain,
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

Relic Rush uses one 2048×4096 atlas; Christmas Market uses one 2048×2048
atlas. All former theme-piece names alias the same six original Homescapes
pieces. Original sprites are uniformly fitted to the canonical hex object
bounds with alpha preserved; diagonal rocket aliases use documented rotations.
Outside-field backgrounds, portraits, controls and HUD art remain unchanged.
Legacy field art stays archived but is no longer drawn, except the provisional
quest-resource image. Flat hex geometry has no decorative frame; selection and
hints animate piece scale. Both games use overrides by default;
`--default-match3` exercises the shared Homescapes-piece fallback.

For a game view, initialize presentation data with `match3.view{...}`, then
call `rules.bind_view(state)`. The game supplies `HEX_R` and an optional authored `piece_width`;
rendering uses `cell_pos` and `piece_pose`.

The board screen's layout belongs to the engine and is the same in every game.
A game must not define or replace `state.layout`: `bind_view` and `board_input` assert this.
Call `state.layout()` once per frame. It is measured up from the bottom edge, at the size it has on a 480×1040 phone, so a shorter screen crops the top of the backdrop instead of squeezing the board:

- **`tools_y`:** the top of the tool row, 100 units above the bottom edge.
- **`board_origin` and `BOARD_CLIP`:** the board, centred 409 units above the bottom edge.
- **`hud_rect`:** a 64-unit band 782 units above the bottom edge, holding the Moves medallion, the goal row and Pause, all centred on its midline. Toasts sit just below it (`board_toast`).
- **`backdrop_rect(size, full)`:** where to draw the backdrop painting. It keeps at least its 1040-tall scale, covers the screen and stands on the bottom edge, so the painting's scenery always ends just above the HUD. Paint a backdrop's scenery in the top 22% of its height.

`match3.bind_board_ui` supplies the measured goal row (two rows above four goals), Moves medallion, Pause button
and tool row. Input checks use the same `board_pause` and `board_tool_bounds(k)`
rectangles. The Settings and Guide forms and the Results panel geometry also
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
