# Shared match-3 engine

The engine follows Cradle of Rome: matches only clear, and the board elements are chains, ice, carved stones and tablets. See [Match-3 elements](MATCH3_ELEMENTS.md).

`require("match3")` is built into the engine on native, iOS and WebAssembly.
`engine/lua/match3.lua` owns the board grid, matching, swaps, blockers,
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
| `LINE_MATCHES` | Default: straight runs along the grid axes. Hints and refill use the same shape rule. |
| `COLOR_TOOL` | Sunburst hits all pieces of the tapped kind. A chain absorbs a hit on its piece. |

| Kind flag | Meaning |
| --- | --- |
| `GOAL` | Count toward the collection objective and last-wave collection |
| `WOOD` | Count the piece toward the second resource total |
| `STONE` | Count it toward the third resource total |

Relic Rush and Christmas Market use `square=true`, `columns=9` and `rows=12`.
Each tile has four swap neighbors and two match axes. Refills may also slide
diagonally around obstructions. A square blast hits the active cells in a
3 × 3 area. Without `square=true`, rectangular fields use flat-top hexes, as
does the hexagonal `radius` mode. The default is `match_min=3` with
`LINE_MATCHES`. Overlapping runs clear each cell once.

Each square campaign authors its maps in `lua/campaign.lua` using
`match3.shapes.square_levels`. A descriptor holds the name, lesson, move
budget, targets (`oil` and `oil_double`) and chains. Its mask is a string of `CELLS` zero/one entries in axial column order; optional
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
The square campaigns use `match3.square_campaign` for their common rules
and `match3.bonuses` for four fixed slots and their ranks. An ordinary
match adds three points for each bonus piece. A full meter holds one
use at 90 points and stops filling. Spending empties the slot. An upgrade
inherits the same meter and replaces its earlier piece and icon. The shared
campaign binder persists those meters and refreshes a parked board after
construction. Resources pay their per-piece value from matches.

Targeted slot actions include `hit`, `blast`, `row`, `row_lightning`,
`color` and `color_pierce`. The row-lightning preview runs the same
selection against a copy of the seed. Color pierce removes at most one lock
per targeted gem and clears the gem if exposed. The instant `charge` action
fills the other unlocked meters by their threshold divided by its descriptor's
`charge_divisor` (default two). It keeps its own use if there is nothing to
charge. Legacy `extra_tools` names the effects after the first three tools.
`game_tool` returns the effect's name for an action that clears nothing, so
the view can display `R.tool_done_notes[name]` without starting a clear wave.
`game_shuffle` returns the source cell of each moved piece, keyed by destination,
alongside its success flag. Automatic recovery passes that map through
`game_check_end`; the Mixer passes it as the third result of `game_tool`.
The view uses it for the staggered flights in `PH_SHUFFLE`.

A loadout's `extra_moves` adds moves to the level's budget.

The final move resolves every cascade before the board can end. At zero moves
the end check counts remaining plaques from the settled floor. Clearing all
the level's goals on that move wins.

`match3.game.campaign_ladder(island, unlocks, journey, slots)` gives a game a
Cradle of Rome ladder: catalogue buildings bought in order, with optional
piece and bonus unlocks. First clears unlock levels. Players can start and resume the current level with
unread dialogue or outstanding purchases. Story buildings keep the journey's
schedule. The other buildings open after their clear and must be placed before
the next story building. It installs the gate, reserve, shop order and waivers
for older saves on the island module. Both portrait games use it. A game whose
campaign buildings are more than story types `0..WONDERS-1` in
order supplies three island hooks, which the ladder installs. `next_build(city, level)` names the
building to place next. `ladder_blocked(city, level, kind)` returns
`"built"`, `"later"` with the clear it waits for, `"earlier"`, false when the
building can be placed, or nil for shop items. `catalogue_order` lists catalogue
rows in shop order. Relic Rush's and Christmas Market's twenty-step ladders use all three; without
them the engine keeps the story-only rules.

A swap into a chain, ice or a carved stone sends the movable gem halfway toward
the blocked cell and back. The blocked cell stays in place. This plays the
ordinary rejected swap's sound and haptic and spends zero moves. Reduced motion
shortens the out-and-back animation. A swap that starts on a chained, iced or
stone cell plays the same sound and haptic with the notice and no motion. A swap into
a hole or an empty cell is ignored: no sound, haptic or notice.

## Diagonal refill

A gravity step moves each gem one cell straight down or diagonally down. A gem falls
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

Rules-only simulations may use `game_collapse(g, true)`. It runs the same
simultaneous gravity, seeded spawns and refill damping, returns the same
`from` map, and omits `steps`. It reuses intermediate tile/source buffers;
callers must not retain animation snapshots from this path. Live play keeps
the default animation-producing call.

`game_probe_swap(g, a, b, match)` previews the first wave on a **settled**
board and returns `legal, progress, score`. It fills `match.mask`, `hits`,
`ordinary`, any resource match lengths and any special awards. Progress counts target layers and
blocker damage; score is the real first-wave score delta. The line matcher
checks only lines through the swapped cells, in the full matcher's order,
and restores the live tile references before returning. It neither refills
nor reads future RNG or changes the live game's wallet or move count. Connected-group
boards and moves that can award or fire a special use a copied simulation to
preserve placement and chained activations. The balancing bot caches immutable
geometry and rejects locked, empty, inactive and ordinary same-kind endpoints before
previewing candidates. Differential tests compare previews and simulation
settlement with real swaps across both campaigns and all blocker types.

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
its resource directory. It supplies neutral pieces, controls, HUD, effects
and a backdrop. Both portrait games use their own square floor, perimeter and
blocker atlases, including in the neutral preview. The [registration manifest](../engine/art/match3/manifest.json)
records source hashes and transforms; the retired original-art
[prompt](../engine/art/match3/prompt.txt) remains historical provenance.

A skin definition lists typed atlases under `sheets`, each
`{path="board/pieces.png", frames={name={x,y,w,h}, ...}}`, standalone
`images` such as backgrounds, and `aliases`; a plain `{path=, frames=}` is a
one-sheet definition, and `engine=true` reads paths with `texture.load_engine`.
A sheet can also specify `grid=128` and use slot numbers such as
`frames={["kind-0"]=27}`. Slots start at zero and run left to right, then
top to bottom. The engine derives the column count from the PNG's width.
The generated pieces sheets use this format. Rectangular frames are still
available for effects and other unevenly sized art.
`match3.atlas(definition)` flattens all of it into one table of named images,
loading each sheet once. `match3.skin(override)` loads the board: pieces,
blockers, cells, effects and boosters, with the backgrounds. `match3.hud(override)`
loads the HUD and boosters atlases: score, completion, the five states of Pause
and the game's booster buttons. A board without booster slots falls back to the
default skin's pickaxe, dynamite and sunburst buttons.
The loaders check frame bounds and required names. [Asset layout](ASSET_LAYOUT.md) lists which
frames go in which atlas.

`texture.region(atlas, rectangle)` returns a borrowed ordinary texture view.
Every sprite retains its own dimensions while sharing the atlas's GPU
storage, so `gfx.image`, `gfx.image_part`, forms and particles draw the authored
regions directly. Nested views compose. Invalid bounds return an empty
texture. Keep the owner alive; freeing a view leaves the owner intact.
Linear filtering stays inside the first and last texel centers of each view.
This keeps neighboring artwork out of transparent frame margins, including
on rotated rails, while adjacent draws still batch on the same atlas.
[Before and after captures](review/frame-atlas-seams/README.md).
`image.additive=true` affects just that view, permitting additive glows and
alpha-blended pieces in one atlas. Font glyphs, engine shape primitives and
transient beam/particle geometry remain normal renderer facilities.

Relic Rush and Christmas Market each ship `data/board/pieces.png`,
`blockers.png`, `cells.png`, `hud.png` and `fx.png`, with
backgrounds as separate JPEGs in `data/board/backs/`. Goal displays can reuse
the board's chip and objective frames. The generated `lua/match3_atlases.lua`
gives each atlas's frames; `lua/match3_skin.lua` and `lua/match3_hud.lua` pick
the atlases, images and aliases for the board and its HUD. `match3.screen`
owns the board screen for both campaigns. The `board` table in `game_config.lua`
sets the piece art mapping and presentation. A skin supplies art under the
same keys for floor, perimeter and blocker states.

The square perimeter occupies empty cells on the same grid as the playable
cells, including holes and a ring one cell beyond the level grid. The eight
neighbours determine the `square-frame-*` sprite and its quarter turn. Each
skin supplies those sprites in `cells.png`.

The renderer in `match3.elements_view` insets each square face by
`R.GROUND.seam_width` so the backing shows between cells. It uses the same
geometry for selected cells, tool targets, chain and ice overlays, and stone.

Floors can set `tablet_hint=true` to help players spot the last one to three
tablets. The reminder shares the move suggestion's five-second idle delay
and resets with it on board interaction. A blue wash lights the floor while
the original particle sprites sweep clockwise along the four bevel edges. A
double tablet uses green. The 3.6-second pulse repeats every nine seconds of
continued inactivity. Reduce Motion hides it. See the
[Cradle of Rome 2 glow reference](cradle-of-rome-reference/README.md#last-puzzle-tile-glow).
`--level N --cell-states` shows them all at once. Selection and hints animate piece scale.
When a hit removes a floor layer (ice, a double tablet's green face or a
tablet), `engine/lua/match3/shatter.lua` breaks that cell's own artwork apart.
At bind it makes eight Voronoi fractures of the cell shape. A break picks a pattern and rotates or mirrors it within the cell. The pieces are cut from the layer's
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
cells. The board screen draws the entrance sheen over the cells.

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

## User events and upgrades

`engine/lua/match3/user_events.lua` (`require("match3.user_events")`) is Cradle of Rome's
If/Then user-event system for the square campaigns. A game keeps its data in `lua/user_events.lua`
(`{events=, trophies=}`) and one wiring file, `lua/user_events_runtime.lua`, required last in `main.lua`:

```lua
local R = require("state")
return require("match3.user_events").install(R, {
    data = require("user_events"), rules = require("rules"),
    island = require("island"), economy = require("economy"),
    target = "plaque",   -- what a feat's "clear" counts: plaques, panes ...
})
```

Each event is checked only while it is available and not done; when its `If` is met it runs its `Then`s
and is done for good. Done and available flags and a few counters are saved with the campaign
(`R.serialize_campaign`); lasting effects are never stored but derived from the done events
(`U.win_income()`, `U.tool_charges()`, `U.upgrades(key)`, `U.trophies()`), so retuning the data
applies to old saves. The file's header lists every condition and effect.

**Upgrades.** `M.upgrade_events(rows)` builds the sixteen building upgrades (Rome's citizens, kept by the
cast we know; [design](CAMPAIGN_DESIGN.md#upgrades-romes-citizens-kept-by-the-cast-we-know)) from compact rows
(`{id="man_03", building=, title="a second oven", keeper="agnes", If=, perk=}`): placing the building
(`city_<building>`) arms the upgrade, and the feat earns it. The perks are two effects:

- `THEN_PLAYER_ADD_RESOURCE_PER_LEVEL id amount` adds income to every won level's reward from then
  on. The game's `reward_breakdown` adds `rules.perk_income()` (set by the runtime) to its `income`,
  as Christmas Market's carousel already does.
- `THEN_GAME_CHARGE_TOOL id amount` makes the pieces of that bonus's tool slot (Hammer and Bomb share
  one) charge `amount` points more per match: a bonus piece is worth 3 (`bonuses.slots`), so one
  upgrade makes it 4 of the slot's 90. Upgrades of one slot stack. The runtime wraps `rules.game_start`
  and `rules.game_apply` so the board's `g.yield_amounts` reaches the engine's clearing code
  while the economy's own piece tables stay untouched.

**Scene.** An upgrade's scene is a journey beat `{key="upgrade-man_03", phase="upgrade", event="man_03"}`
compiled by each game's `tools/prepare_story.py` from the `## Upgrades` section of `docs/story.md`
(headings `**Upgrade man_NN · <title> · <Building name>**`; the keeper must speak). `match3.game`'s journey keeps
these in `journey.upgrades`, apart from the level beats, and `R.story_tick` plays the first unseen one whose
event is done (`R.upgrade_done`) on a return to town, once no level beat is due; it is saved with the
other beats and never blocks progress. Without a scene the runtime shows a toast ("Gingerbread bakery: a second oven").
`R.upgrade_card(kind)` feeds the building card (and `R.building_words` the tap line): "Upgraded: <title>" with the
perk, or the feat while armed, as `resource_indicator` entries under a FEAT, EVERY WIN or TOOL caption; a game's
`screens.lua` provides `R.currency_icon(slot)`. No new speakers are added for upgrades: the keeper is an existing
cast member. A speaker without a portrait (`narrative.lua`, no `portrait_path`) is shown with a name plate.
`story.setup` takes up to 64 cast members.

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

### Optional match specials

An engine caller can pass `special_rules = {"striped", "color_bomb", "plane", "t_bomb"}`
to `match3.new` with straight match-3 rules, on hex or square cells. Each name
is independent. An omitted or empty list enables none. A square campaign sets
`special_rules` in its `lua/campaign.lua`: Relic Rush and Christmas Market
both enable `striped` and `color_bomb`.

| Rule | Shape | Matches as its color | On activation |
| --- | --- | --- | --- |
| `striped` | Exactly four on an axis | Yes | Clear the axis, including across gaps |
| `color_bomb` | At least five on an axis | No | Clear the color of the swap partner, or the original match color on tap |
| `t_bomb` | The end of a straight run meets the interior of another | No | Hit the neighboring cells |
| `plane` | Four in a hex rhombus (a 2 × 2 block on square cells) | No | Fly to a target, preferring plaques and blockers |

Overlapping rewards use the order color bomb, T bomb, striped, plane. The
swapped cell that made the match takes precedence for placement, and a
cascade's line leaves its special too.

A **colored** special (`colored = true` in its rule; the line gem) stays a
piece of its kind, as a Candy Crush striped candy does. It matches with its
color, counts for its resource and goal, and fires when it is cleared: by a
match it belongs to, another special or a tool. A plain swap that makes no
match is rejected. A **colorless** special never matches; tap or swap it to
activate for one move. A locked special waits: the hit breaks its chain or ice
first. A hit can chain into another special in that wave, once each.

Swapping two specials always fires:

| Pair | Effect |
| --- | --- |
| Two colored specials | Every axis through the moved piece: a row and a column on square cells |
| Color bomb and a colored special | Every plain piece of that color becomes that special, on alternating axes, and all of them fire |
| Two color bombs | Every active cell is hit |
| Any other pair | Both fire where they stand |

A special's hits are direct, like a tool's, and marked `swept`. Under
`match_only_resources` a tool clears without paying, but matched and swept
pieces both bank their resource (`match_banks`); only matched bonus pieces
charge a tool. `game_probe_swap` keeps its fast path for ordinary three-piece
matches on these boards and follows the full rules for awards and activations.

Colored specials draw their own piece through `gfx.image_striped`: cream
ribbons along the axis they clear, each outlined in the piece's own color and
masked to the painted alpha (`pieces.stripes` in the board art overrides
`repeats`, `width` and `ink`). Colorless ones use the game's
`board/match-specials.png`; the color bomb is drawn at the pieces' size with
their shadow. On the board a colored special and the color bomb carry a rim
of light (`elements.piece_glow`) and a glint (`R.draw_gem_glint`); Reduce
Motion holds the rim still and hides the glint. A special swells in where its line was
made. `--level N --special-states` shows both axes of every kind on a square
board. Sources, creation and activation are declared together in
`engine/lua/match3/specials.lua`.

### Finale: leftover moves

With `finale_batch = N` (`match3.square_campaign` sets 5), a won board spends
its leftover moves before the result, as Candy Crush does. The board runs the
finale as a coroutine (`finale_script` in `engine/lua/match3.lua`) while it is in
`PH_FINALE`. Each round arms up to N random plain, unlocked pieces as bombs:
every move flies from the moves medallion as a comet (`R.vfx_finale_launch`),
the medallion counting down one launch at a time, and the game's Bomb tool piece
pops in where it lands. After a short fuse the round's bombs go off in one wave,
each hitting the 3×3 square around it. The script yields while that wave and its
cascades clear and fall, and resumes when the board settles to arm the next
round. Once no moves are left the settled board rests 0.7 s, then the result
opens; a board won on its last move rests too. Matches stay the board's income, so the finale pays a small,
diminishing share of what it blasts: the k-th leftover move is worth
ln(1 + 1/k) of `finale_share`, and n moves together pay in proportion to
ln(1 + n). Going from 2 to 4 moves left pays about 1.5 times as much, and from
2 to 6 about 1.8 times. Each round pays its moves' average share, and fractions
carry from piece to piece. Square campaigns set 1.25, which the balance sample
measures at about a tenth on top of the matches. The rules are `game_finale_arm` and
`game_finale_fire`; `game_finale` plays every round with its cascades at once
for bots and the balance simulations, so measured income
includes the finale. Finale waves are not player moves: user events skip them.
Each round saves the completed board, so quitting mid-finale keeps the win.
`--level 1 --special-states --special-fire match` wins on its swap and plays the
finale (`reel match-finale`).
