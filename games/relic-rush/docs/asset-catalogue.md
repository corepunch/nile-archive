# Relic Rush artwork and state catalogue

This is the review inventory for the current game, audited 31 October 2026.
The original gap and acceptance criteria are tracked in [issue #11](https://github.com/corepunch/nile-archive/issues/11).
There are **18 base pieces, 5 special modifiers, 27 authored board/control sprites,
7 expedition-header icons and one investigating Elena cutout**.
The complete filename inventory, crop rectangles, rule names and state matrix live in
[`manifest.json`](../art/board-states/manifest.json). Paths below are relative to this game.

![All packs and authored states rendered by the game](screenshots/art-catalogue.jpg)

## Buildings and decorations

The [building catalogue](building-catalogue.md) covers **96** registered sprites,
including ten story wonders and 86 repeatable shop items. It records the full
source/prompt history, runtime paths, whole-tile measurements, supported states,
import commands and reviewed in-game captures. The board manifest links the
building manifest and inventories every new runtime file.

The fifth restoration is now the **Sunstone courtyard**, a dry mosaic gathering
plaza replacing the bridge-shaped gateway. Its 3 x 2 footprint is measured from
the new artwork. The complete three-option ImageGen atlas, selection, source,
prompt and reviewed game captures are recorded in the
[replacement review](review/sunstone-courtyard/README.md).

## Reward and replay presentation

The [economy review](review/economy/README.md) records first-clear/replay rewards,
the measured expedition list, available/locked/resume rows and the shop's spendable /
reserved Gold. Sources are `lua/expeditions.lua`, `lua/screens.lua`,
`lua/catalogue.lua` and `lua/rules.lua`. The shared form skin supplies existing
normal/hover/pressed/disabled/focus controls. No new bitmap or icon set is added;
the existing normal Idol/Leaf/Crystal artwork identifies Gold/Wood/Stone. Board
matches contribute to score/objectives; wallet payouts use the separate fixed
grant contract. Discovery Stars/Compasses are one-time progress rewards, and
replays pay Gold only. All piece packs and authored board/tool states retain
their existing artwork and state mapping. Reproduce with `--victory`,
`--replay-victory`, `--expeditions --expedition-page N` and `--catalogue`.

## Pause menu actions

`lua/screens.lua` lays Pause out in groups, with the look in `lua/skin.lua`: a
settings well holding the Sound and Reduce motion checkboxes, then Resume, then
Restart and Quit to Island as secondary wooden buttons, and the guide as a link.
Restart asks for confirmation and resets the current puzzle; Quit to Island
suspends it without paying rewards. Island Pause hides Restart and Quit. (The
motion toggle was removed once and returned as the Reduce motion checkbox.)
Both menus measure their content before centring, including the taller
safe-area phone layout. States are listed below with the checkbox and button
variants; no artwork, source prompt, runtime file or sprite transform is added.
The menu contract is recorded in `art/board-states/manifest.json` under `pause_menu`.

Reproduce and inspect both contexts at both phone sizes with
`python3 tests/fixtures/pause-actions/capture.py`; reviewed captures and exact
commands are in the [pause menu review](review/pause-actions/README.md).
The game's `--smoke` run exercises Restart, Quit to Island, hidden island actions,
resuming through the expedition browser, and unchanged banked rewards.

## Piece kinds and optional packs

All packs use the same kind IDs and rules. Colours and silhouettes are authored;
the game does not recolour one gem into other kinds.

| ID / rule name | Relics (default) | Jewels | Resources | Rule meaning |
| --- | --- | --- | --- | --- |
| 0 / IDOL | Gold sun idol | Yellow hex gem | Coins | Idol objective and score; reused Gold purse icon |
| 1 / FLAME | Coral flame | Red heart | Terracotta amphora | A matched, unlocked flame thaws adjacent ice |
| 2 / LEAF | Jade leaf | Green square gem | Timber | Ordinary matching kind; reused Wood purse icon |
| 3 / SCARAB | Turquoise scarab | Blue teardrop | Water | Ordinary matching kind |
| 4 / CRYSTAL | Purple crystal cluster | Purple diamond | Stone | Ordinary matching kind; reused Stone purse icon |
| 5 / AMPHORA | Amber amphora | Orange star | Wheat | Ordinary matching kind |

Source: `art/tile-sets/source.png`, six columns × three packs. Runtime:
`data/tile-sets/{relics,jewels,resources}/{0..5}.png`. Import:
`python3 games/relic-rush/tools/prepare_assets.py` from the repository root.
Largest-component isolation removes neighbouring sprite fragments before centring
and resizing; it does not create new colours or states.

## Specials and powerups

Source for every new sprite below: `art/board-states/source.png`, generated together
in one built-in ImageGen call. The exact prompt is
[`board-states.prompt.txt`](../art/board-states.prompt.txt). The manifest records the
actual generated dimensions and explicit crop boxes; the importer does not assume
the generator produced a mathematically uniform grid.

Runtime pattern: `data/board-states/<name>.png`, RGBA 128 × 128.
Filled terrain and ice use the slot's **flat-top** silhouette, registered to the
renderer-authored cell mask. Special gems use no hexagonal outline frames.
The replacement set is authored together in
`art/board-states/clear-indicators.png` (ImageGen, 2026-11-01), with its prompt
in `clear-indicators-prompt.txt`. The manifest records measured crop boxes,
spatial axis registration and runtime paths. The importer preserves authored
RGBA and clips filled ice to the actual tile; it does not synthesize states.
Selection and hints use soft filled glows, with no hard border.
`lua/art.lua` names these textures; `lua/board.lua` uses the same artwork for
live pieces, collection flights, clearing animations and the guide.

| Rule state | Authored name | Creation / behaviour |
| --- | --- | --- |
| NORMAL (0) | Base kind image | Four connected equal kinds clear normally |
| ROW (1) | `ray-row` | Group of five; full-gem stripes along the 30° board axis |
| COLUMN (2) | `ray-column` | Group of five; full-gem vertical stripes |
| DIAGONAL (3) | `ray-diagonal` | Group of five; full-gem stripes along the 150° axis |
| BOMB (4) | `bomb` | Six or more in a non-line group; radius-one hex blast (cell plus six neighbours) |
| PRISM (5) | `prism` | Six in a straight line; clears the swapped kind |

Rays use `gfx.image_striped` on the matching gem at full size. Broad cream bands
follow the 30°, 90° or 150° clear axis, masked to the gem's authored alpha and
modulated by its surface shading. Bomb and prism sprites replace the gem at full
piece size. The old `ray-row`, `ray-column`, `ray-diagonal` images remain canonical
skin compatibility regions and no longer appear as tiny board/guide badges.

The user explicitly requested engine-drawn masked stripes on 2026-11-01; this
supersedes the usual authored-state requirement for this pattern. No generated
stripe atlas is used, and existing textures/alpha remain unchanged. Relics,
Jewels, Resources and the guide share the same renderer. The
[striped-special review](../../../docs/review/striped-specials/README.md) covers
all six kinds, all axes, the full bomb, both phone sizes and blockers.
See [match rules](match4-rules.md) for special-combination resolution.

## Terrain, blockers and board interaction

| Authored name | State and meaning |
| --- | --- |
| `sand` | One excavation layer under a piece; cleared by a match above it |
| `chain` | Crossed linked chains and padlock; one hit unlocks the piece |
| `ice-2` | Filled faceted frost sheet across the whole gem; counter **2** means two hits remain |
| `ice-1` | Filled cracked frost sheet across the whole gem; counter **1** means one hit remains |
| `selected` | Soft filled mint glow under the tapped piece; no outline |
| `hint` | Soft filled gold glow and sparkles under both idle-hint pieces; no outline |
| `guide` | Jade book medallion for the explorer guide; not drawn on the board since the [match-3 HUD](review/match3-hud/README.md) (the guide opens from Pause), kept for the art catalogue screen |

Ice uses a uniform 0.52 material opacity so the matching gem is visible through the whole frozen face. The two separately authored ice states also show a dynamic 1/2 remaining-hit count, shared with the guide. Ice and chain are independent layers; if both exist, both are shown. A blocker hit
removes a layer before collecting its piece. Selected/hint frames are under pieces,
blockers over them; sand is beneath both. Board cells and outer edge lines remain
simple intentional layout geometry. Empty/inactive cells have no piece artwork.
Hint opacity pulses; reduced motion uses a steady frame. There are no hover/pressed
states for individual pieces: a touch selects a piece or initiates a swap.
If idle hint search finds no legal swap, the existing reshuffle now also recovers
idle boards and shows the text-only notice “No moves. Board reshuffled.” No new
sprites or derived artwork are used. The existing hint artwork still marks only
legal swaps; [review captures and reproduction](review/dead-board/README.md)
cover a zero-charge ring at both phone sizes.

## Tools: complete interaction matrix

Each tool starts with two charges per level, costs no move, and is used by selecting
it then tapping an active cell. Pickaxe hits one cell; dynamite hits its cell and
six neighbours; sunburst attacks all three axes through its target.

All fifteen buttons are separately painted in the same atlas, including their
backgrounds. The renderer never desaturates, tints or synthesizes a disabled state.
Their updated source is `art/tool-buttons/source.png`, generated together in one
built-in ImageGen call; the exact prompt is [`tool-buttons/prompt.txt`](../art/tool-buttons/prompt.txt).
The original 27-sprite atlas remains the source for hex layers and the guide.
Tool crop boxes and the separate atlas's dimensions are recorded in the manifest.
The importer spatially registers each measured button body (plus eight source
pixels of padding) into a 120×120 area on the existing 128×128 runtime canvas,
preserving authored alpha and all five painted states. This corrects the source's
roughly 4% width excess; no visual state is generated by processing.
Runtime paths remain `data/board-states/{pickaxe,dynamite,sunburst}-{state}.png`.
`lua/art.lua` specifies 76×76 touch targets, and `lua/board.lua` draws each texture
into a square with equal padding. The row begins at y=784 plus tall-phone offset;
labels sit below the buttons and counters stay at their upper-right corners.
Reproduce with `python3 games/relic-rush/tools/board_assets.py`; validate with
`--check`. [Actual-game captures and native-input checks](review/square-tools/README.md)
cover every tool/state plus normal and exhausted rows at both phone sizes.

| Tool | Normal | Selected | Pressed | Mouse hover | Disabled |
| --- | --- | --- | --- | --- | --- |
| Pickaxe | `pickaxe-normal` | `pickaxe-selected` | `pickaxe-pressed` | `pickaxe-hover` | `pickaxe-disabled` |
| Dynamite | `dynamite-normal` | `dynamite-selected` | `dynamite-pressed` | `dynamite-hover` | `dynamite-disabled` |
| Sunburst | `sunburst-normal` | `sunburst-selected` | `sunburst-pressed` | `sunburst-hover` | `sunburst-disabled` |

Priority: depleted or board busy → disabled; held pointer that began inside →
pressed; selected tool → selected; real mouse inside → hover; otherwise normal.
Touch never receives hover art. Charge counts are dynamic text on a counter.
The tools stand up out of a low jade tray along the bottom edge, three evenly
spaced sockets without captions; choosing one names it and its effect in the toast.

## Expedition header

The header follows the portrait match-3 convention (Royal Match, Toon Blast,
Homescapes): one jade band with a gold trim hangs from the top edge, under the
status bar. It holds a hexagonal Moves medallion that overhangs the band, a
recessed goal plate and the authored pause medallion. Goals are icons with their
remaining count beside them; both bars stay slim to leave the painting visible. Score remains a win condition, represented by the star
seal; idols, sand and lock counts use their existing artwork. A met goal dims its
icon and replaces the count with the completed seal. Collections landing on a
goal make its icon bounce. Over the last five moves the medallion face turns
red and glows. The band, trim, plate and medallion are drawn with engine shapes
(gradients, polygons); they are frames, not interaction states of an authored
control, and the medallion has no pressed/hover states because it is read-only. No score total, level title,
progress bar or island shortcut is displayed during an expedition. Level details
are in Pause; results retain score/reward details. Pause's Restart (confirmed)
and Quit to island (keeps the board) are the in-round exits; win/failure screens
provide theirs.

`art/expedition-hud/controls.png` contains **all seven new icons together in one
built-in ImageGen call**. The exact prompt is
[`controls-prompt.txt`](../art/expedition-hud/controls-prompt.txt). `pause-normal`,
`pause-selected`, `pause-pressed`, `pause-hover`, `pause-disabled` are individually
painted jade/gold medallions. `score` denotes the remaining score objective;
`complete` denotes any fulfilled objective. The runtime button uses normal,
pressed and real-mouse hover states; selected/disabled artwork is supplied for
the complete control contract. No tint or procedural bars create states.

The shared board/city Pause medallion uses a 64×64 logical-unit canvas and touch
area, enlarged from 44×44. The existing authored states scale directly. Board
goals reserve 64 units beside the button; city currency pills use 76-unit spacing
and 72-unit widths to stay clear of it. The smoke run opens board Pause at the
new left edge and city Pause at the new lower edge, outside the old touch area.
[Reviewed headers at both phone sizes](review/larger-pause/README.md).
Runtime: `data/expedition-hud/<name>.png`, 128×128 RGBA.

`art/expedition-hud/elena-investigating.png` is a separate ImageGen identity edit
of the existing Elena portrait: she examines a sun fragment through a magnifying
glass. [Exact portrait prompt](../art/expedition-hud/elena-prompt.txt). It was
shown between the old goal and moves cards; the match-3 HUD retires it, so it has
no runtime export and the manifest lists it as `retired_portrait`. Dialogue
continues using the original Elena portrait.

Measured crops, source dimensions, prompts and runtime paths are recorded in
[`expedition-hud/manifest.json`](../art/expedition-hud/manifest.json), referenced
by the primary runtime manifest. Import is aspect-preserving spatial registration
with authored alpha retained, never derived state artwork:
`python3 games/relic-rush/tools/prepare_hud.py` (`--check` verifies exact exports).
`lua/art.lua` loads the contract; the measured horizontal engine list in
`lua/board.lua` owns the goal cells. Collection flights land on the new goal positions.
[Reviewed game captures and native input checks](review/expedition-header/README.md)
cover both backgrounds, both phone sizes, completed goals, every pause state,
and dismissible/required popup behavior.

[Match-3 HUD before/after captures](review/match3-hud/README.md) cover both
paintings, both phone sizes, completed goals, the last moves, a tapped tool,
pause, guide and the island.

![The match-3 HUD on a late level](review/match3-hud/after-late-480x900.jpg)

## Animation and effect states

| State | Presentation / assets |
| --- | --- |
| PRESENT | The board's entrance after any dialogue: existing HUD, tool, cell, piece and blocker artwork move on the shared timeline in `engine/board_intro.lua`, with transient glows, sparks and a sheen. No new art. Tap skips it. Capture: `build/test/relic-rush board-intro` (`--level 5 --present --reel`), frames in `build/shots/frames/` |
| Idle | Base or special frame, optional sand/selection/hint/blocker layers |
| SWAP | Existing piece artwork moves to neighbour |
| REJECT | Same artwork returns; no move spent |
| CLEAR | Existing artwork expands briefly, then shrinks and fades; a blocked hit keeps the piece |
| FALL | Engine one-edge gravity steps prefer straight down; diagonals require a blocked or missing cell below the donor, then land with a short squash; all exposed column tops spawn vertically; interior cells spawn only with blocked donors |
| Special birth | Existing authored special plus transient halo/sparks |
| Attack | Procedural travelling rays, bomb rings, prism links and combo effects |
| Collection | Existing base-kind image flies to resource HUD with a trail |
| Reduced motion | Suppresses trails, shake, squash and effect spawns; the board's entrance becomes a short fade; rule resolution stays active |

Transient light, beams, rings, particles, score text and sunlight motes
are intentional animation primitives, not missing static artwork. Result-card
torch sconces and their flame renderer have been removed; reviewed standard
and safe-area phone captures are in `docs/review/result-without-torches/`.
`lua/vfx.lua` creates an additive light texture in memory; see
[effects and capture modes](effects.md). There are no additional hidden gem skins
for burning, charging, cracked gems or tool upgrades.

## Remaining runtime asset families

`cloud-fog` covers locked land with rolling cloud banks (`city.fog_clouds`, `engine/city.c`).
Two world-space density fields of three spatial frequencies each drift on the smooth frame
clock. Density modulates soft cloud edges, blue-grey hollows and pale sunlit lobes. The cached
closed-land mask stays fixed, and unlocking clears it immediately. Open land stays clear. This
is a continuous procedural effect, with no icon or interaction-state atlas. See the
[review](review/cloud-fog/README.md).

`building-shadows` is a separate Blender-rendered RGBA layer for all 96 objects, drawn below the
fog and every sprite; see [registration](BUILDINGS.md).

The current [96-entry catalogue](building-catalogue.md), including the dry Sunstone
courtyard, is rendered directly from its Blender master with the shared
[city camera](../../../docs/BUILDINGS.md#the-camera). The earlier
[ImageGen paint-over](../art/isometric-paintover/README.md), the
[2:1 building-art trial](../art/isometric-trial/README.md) and the
[Blender projection study](../art/isometric-blender/README.md) are preserved as source
history; all of them use the old 2:1 view, and none is runtime artwork. Painted detail is
the known gap recorded in the [building catalogue](building-catalogue.md#known-gap-no-paint-over) and [tracked here](https://github.com/corepunch/nile-archive/issues/41).

These families plus the board assets above cover every file in `data/`;
`runtime_inventory` is checked against disk by `make test`.

| Runtime files | Source / ownership | Supported states |
| --- | --- | --- |
| `data/buildings/<key>.png` | Blender master; `make buildings GAME=relic-rush` | Authored restored sprite; valid placement reuses it, blocked placement uses the existing engine red ghost, held placement lifts it; cards/rewards use it alone |
| `data/building-shadows/<key>.png` | Blender master; `make buildings GAME=relic-rush` | Separate grounded shadow for restored/valid/blocked/held states; own crop/pivot and shared pixel scale; all shadows below all buildings; omitted in cards/rewards |
| `data/characters/{elena,mara,tomas,adrian}.png` | `art/art-direction/expedition-cast.png`; prepare_assets.py | One authored bust each; engine supplies speech/thought/shout bubbles |
| `data/{island,jungle,scene-lagoon,scene-temple}.jpg` | Corresponding paintings in `art/` | Island, fallback jungle, levels 1–5 lagoon, levels 6–10 temple |
| `data/board-states/cell-mask.png` | Actual `gfx.ngon` capture in `art/board-states/cell-mask.png` | Shared flat-top slot silhouette; clip mask, not an icon/state |
| `data/title.png` | `art/title.png` | Retained title asset; the current minimal HUD does not draw it |
| `data/fonts/LilitaOne-Regular.ttf`, `lilitaone-OFL.txt` | Bundled licensed font | Dynamic labels, counters, outlined/gradient typography |

The reusable engine UI now owns form layout, input, focus, data exchange and modal
Gaussian blur; the game supplies its skin and templates for pause, building and
guide dialogs. The guide uses one stable-key data source, a measured list and
left-aligned icon/copy rows. Speech, thought-cloud and shout-burst badges centre
on the visible outline; their puffs/spikes contribute to text padding. Framed
phone dialogue centres the portrait, visible bubble and any listener as one
measured unit within the safe screen; Skip travels with that unit. Reviewed
480×900 and safe-area 390×844 comparisons are in `docs/review/centered-dialogue/`.
The badge/padding audit is tracked in [issue #16](https://github.com/corepunch/nile-archive/issues/16).
Reviewed comparisons live in `docs/review/dialogue-stack/` (all three shapes,
one/two-line speech, 480×900 and safe-area 390×844, plus the guide). See [the UI engine](../../../docs/UI_ENGINE.md).

Board presentation restores the original 26.5-unit cell radius, fitting the
maximum nine-column grid into 371/480 logical screen units. The previous fixed
32-unit radius made the settled board about 21% too large. Base pieces, the
cell mask, specials, blockers and selection/hints share the restored geometry;
authored alpha and orientation are preserved. Cell positions, input and refill
clips use the same radius. Guide icons retain their original size. Sources:
`lua/state.lua`, `lua/board.lua`; no bitmap or interaction state is added.
The entrance settles to a 1× pose after natural completion, skipping or reduced
motion. Representative before/after captures at both phone sizes, plus
reproduction, are in
[the size correction review](review/board-size-fix/README.md).

Superseded twice (by the Goal/Moves cards and then the match-3 HUD above):
the board HUD used three small, separate jade cards with gold rims: score,
level/name and moves. Each label stays grouped with its value; objective pills
share the same near-opaque backing. The painting remains visible in the gaps.
The read-only `hud_form` in `lua/board.lua` uses engine row/column layout,
computed values and a paint-only skin. Text keeps its outlined/shadowed palettes;
score pulses and progress remain animated. No authored sprite or interaction
state is added. The earlier unbacked HUD lost contrast and is superseded by
[the grouped-card review](review/readable-hud/README.md), including both paintings,
phone safe areas, modal underlays and effects. Historical captures are in
`docs/review/floating-hud/`.

The island's redundant minus/plus/MAP button cluster has been removed from
`lua/island_view.lua`. Navigation uses the shared city camera: pinch or mouse
wheel to zoom and drag to pan. Placement, confirmation and long-press pickup
are unchanged. No bitmap or state mapping changed. Normal, overview and
placement captures at both phone sizes are in
[the map-control review](review/gesture-only-map/README.md).

Building pickup now uses the engine's stationary 0.5-second hold; ordinary drags
pan the map. The existing ghost/footprint, held/released, valid/blocked and
confirm/cancel states are retained. [Issue #21](https://github.com/corepunch/nile-archive/issues/21)
tracks gesture arbitration and the two-game input audit. Sources are
`engine/city.c`, `engine/core.c` and `lua/island_view.lua`; reviewed native-input
captures and reproduction commands are in
[the shared gesture review](../../../docs/review/city-long-press/README.md).
No bitmap or atlas mapping is added.

The island HUD has no sheet or panel over the map: one row of slim resource
pills, the shared pause medallion, and a bottom row of a large Play/Build button
between icon-only round Expeditions and Shop buttons. The side-button centres
share the Play/Build button’s centre line; captions beneath them are removed.
The round buttons are engine geometry
(gold rim, jade face) around existing artwork: the procedural compass icon and the
Jungle market sprite (`data/buildings/3.png`). Their pressed state shifts the face
2 units, as menu buttons do; there is no hover, selected or disabled state because
they are always available. The EXPAND pill is gone: a region that can open now
shows "+" and a glow on its fog marker, and its name is outlined text without a
plate. [Island HUD captures](review/island-hud/README.md).

The Pause menu's Sound and Reduce motion settings are engine `checkbox`
controls drawn by `lua/skin.lua` (`controls.checkbox`): a 40-unit well in the
panel's wooden rim on a jade shadow, filled with a jade face, gloss and a cream
tick with a dark rim when checked. States: unchecked, checked, pressed (box and
tick sink 2 units) and disabled (rim and fill turn grey; not used by the game).
Hover looks like normal, as for every Relic Rush control, because touch has no
hover. All of it is engine geometry, like the menu buttons, with no bitmap.
Checked = sound on / motion reduced; the binding writes the setting at once.
[Reviewed captures of every state](../../../docs/review/ui-skin-files/README.md#relic-rush-pause-checkboxes).
`--smoke` clicks Sound off and on again through real input.

Pause groups its controls, as pause menus in other match-3 games do. The two
checkboxes sit in a recessed well (`controls.panel.variants.group`: a sand
gradient with a darker rim). Below it come the jade RESUME and two secondary
actions in carved wood (`controls.button.variants.secondary`, same layers and
states as the jade button: pressed sinks 2 units, disabled drains it). EXPLORER'S
GUIDE is a gold text link (`variants.link`: no layers; pressed moves the text).
From the island Pause shows only Resume. RESTART opens a confirmation
(`OV_CONFIRM`): RESTART in jade and KEEP PLAYING as a link, which returns to
Pause. QUIT TO ISLAND keeps the unfinished board. All are engine geometry
with no bitmap. Captures at both sizes, in the board and on the island, are in
[the skin review](../../../docs/review/ui-skin-files/README.md#relic-rush-pause-grouped-with-restart-and-quit).

Resource capsules, island HUD buttons, progress bars, menu buttons, result stars, placement outlines, land
fog and dialogue chrome are intentional engine geometry/text; they are not gem
or tool artwork states. Existing island, dialogue and result captures are linked
from the [README](../README.md). App icons live in `Assets.xcassets/`, outside the
runtime data inventory; their source and selection records are in `art/app-icon/`.

## Reproduce and keep current

From the repository root:

```sh
python3 games/relic-rush/tools/capture_cell_mask.py  # when cell geometry changes
python3 games/relic-rush/tools/board_assets.py
python3 games/relic-rush/tools/board_assets.py --check
python3 games/relic-rush/tools/check_art_catalogue.py
make test
./build/relic-rush --headless --mute --fresh --art-states --shot catalogue.png
./build/relic-rush --headless --mute --fresh --art-board --shot specials.png
./build/relic-rush --headless --mute --fresh --tiles jewels --art-board --shot jewels.png
```

Use Xvfb on Linux. `tools/screenshots.py` regenerates the catalogue and special
board as well as ordinary levels, guide, effect and phone captures. Review at
480 × 900 and 390 × 844 with phone safe areas. `--art-board` freezes a deterministic
level-nine board with all five specials, selection/hints and selected/depleted
tools; `--art-states` displays every base piece and all 27 authored sprites through
the real renderer. These capture modes do not save progress.

For every addition, update this document, the manifest inventory and state mapping,
and the runtime contract together; add capture coverage. A new file without an
inventory entry, an absent authored state, or a stale atlas crop fails CI. When
changing existing definitions, audit their actual rule meaning as well as names.
If any visual gap remains, open/link a GitHub issue here before handoff. No known
placeholder board/control states remain from issue #11.

## Island connector removal

`lua/island.lua` disables the engine's procedural roads between buildings
with a transparent `city.path`. Building sprites, shadows and terrain assets
keep their existing registrations. Reviewed 480×900 and 390×844 captures are
in [the road removal comparison](review/no-auto-roads/README.md).

## Engine match-3 atlas and trickling

`data/match3.png`, registered by `lua/match3_skin.lua` and
`art/match3-atlas.json`, contains all match-board backgrounds, pieces, special
axes, blockers, selection/hint/guide frames, HUD icons and all five authored
states of each tool and Pause. Relic Rush includes all three piece packs and
both scenes. Existing source artwork and alpha are copied without modifying
states. The 64px cubic radial light is the existing procedural transient
effect, packed in the same atlas and drawn with a per-view additive flag.

The engine's default resource skin is independent and embedded; both games
normally override it. `python3 tools/match3_atlas.py` reproduces the atlases and
registrations, and `make gen` embeds the default. FALL uses engine-owned
simultaneous one-edge movement steps, straight-down priority with blocked-down diagonal fallback, vertical spawning at every exposed column top and
a short landing squash; static states continue to use the existing artwork.
Input and animation timing are shared.

See [checked in-game captures and commands](review/trickling/README.md) and the
[engine contract](../../../docs/MATCH3_ENGINE.md). The default atlas's source,
prompt, all supported states and crop/rotation registration are catalogued in
`engine/art/match3/manifest.json` at repository root.

### Flat-top hex pieces; original gem set retained

Relic Rush retains its original flame and the other original piece identities.
Only the sun idol and yellow hex gem contours were reauthored to match the
board's six-sided flat-top orientation; the sun face remains upright.
`art/tile-sets/source-flat-hex.png` and `flat-hex.prompt.txt` preserve the whole
set edit. `piece_replacements` in the state manifest records both crops and
their spatial fit to the renderer-authored cell aspect. The other sixteen
pieces, including the flame, match the original runtime pixels exactly.

The clay brick belongs to the independent engine default atlas and is not used
by this game's overrides. Reproduce with `python3 tools/match3_atlas.py` and
`make gen`. Review [actual boards and guide](../../../docs/review/resource-icons/README.md).


### Cell registration and dialogue motion

The board retains its enlarged 32-unit radius and 16-unit side margins. Pieces
and state panels scale together by `32 / 26.5` from the authored registration:
the 43.7-unit piece canvas becomes about 52.77 units, while the inset 51.4-unit
cell/state canvas becomes about 62.07 units. This preserves piece padding and
keeps neighbouring cell faces, selection/hint frames and special panels apart.
Filling the entire cell diameter had removed that inset; reducing the board
radius then lost the deliberate wide layout without repairing the proportions.
The guide and HUD retain their own sizes. Artwork and alpha are unchanged. See
the [wide-board and cell-fit review](review/gem-cell-fit/README.md) for both phone
sizes, the selected/special cell view and existing capture commands.

Portraits retain finite entrance/exit slides and fades. An independent colour
tween brightens/dims active/listener states without replaying the slide. Size is
constant for speaker/listener, with no scale/rotation animation or idle wobble. See [motion, captures and timing review](../../../docs/review/motion/README.md).

### Placement confirmation controls

`lua/island_view.lua` uses an engine form with `placement_cancel` and
`placement_confirm` variants from `lua/skin.lua`. These are procedural UI skin
controls like the existing checkbox: red round × (cancel) and jade round ✓
(commit build/move), normal/hover/pressed states with a keyboard-only focus ring; confirmation fades when
invalid. No texture substitution or gem-art tint is used. Their screen positions
follow the preview sprite with safe-screen clamping, at 480×900 and 390×844.
Reproduce with `--city 6 --placing` or `--placing blocked`; reviewed captures are
in `docs/review/relic-polish/` at the repository root. Existing native-input smoke
covers both cancel and confirm, including uncommitted moves and wallet changes.

## Current-camera building paint pass

All registered buildings and decorations use the painted-v1 sources, normal sprite
and unchanged engine placement/lift/validity states documented in the
[building catalogue](building-catalogue.md) and
[review gallery](review/painted-buildings/current-camera/README.md).

## Centred board indicators and placement input

The former centred lightning/bomb overlay was replaced by the engine-masked
stripes and full-size bomb described above. Ice **1**/**2** counters are centred on
their cell and drawn last, above every board layer. The guide shares the current piece rendering. Authored PNGs and alpha are unchanged;
the former corner offsets remain removed. No new bitmap assets.

Touch/mouse use removes the placement button's keyboard focus outline; Tab
restores keyboard focus. Preview movement requires dragging the building.
Pickup and release/drop emit feedback; Confirm and Cancel add none. See the
[review and reproduction commands](../../../docs/review/relic-input-feedback/README.md)
for both phone sizes and the dense special/blocker state board.

## Placement alignment guides

`placement-guides` uses the shared `engine/city.c` renderer. While moving or
placing a building, other buildings show neutral cream outlines with dark
contrast edges around their occupied ground, including placement clearance.
The building in hand retains its green/red footprint; its original location
is omitted. Guides stay visible after release until Confirm/Cancel, then hide.
The guides use the existing camera and tile measurements; artwork, alpha,
footprints and collision rules are unchanged. No bitmap or ImageGen source is
added. Reproduce with the existing native-input hold/placement captures in the
[review](../../../docs/review/city-placement-guides/README.md).

## Settings gear and three-resource wallet

The legacy `pause-normal`, `pause-hover`, `pause-pressed`, `pause-selected` and `pause-disabled` keys now draw the authored settings gear from `art/expedition-hud/settings-lives.png`. `life` is the red heart from the same atlas; it is a wallet readout, not an interactive control. The hex amulet uses the existing archaeological sun idol, and discovery stars retain their documented procedural glyph. Wood, stone and compasses are retired from wallet UI, costs and rewards; their old slots remain reserved for save compatibility.

All five gear states were generated together by ImageGen; `settings-lives-prompt.txt` records the prompt and alpha cutout edit. `python3 games/relic-rush/tools/prepare_hud.py` performs only grid crops and thumbnail registration to 128px RGBA canvases, preserving authored alpha and paint. `tools/match3_atlas.py` then packs the five gear states. No tint-generated interaction state is used. Captures: `docs/screenshots/hud-states.jpg`, `hex-first.jpg`, `phone-board.jpg`, `island-village.jpg` and `phone-island.jpg`. Normal, selected, pressed, hover and disabled use the same authored outer medallion, with distinct painted state feedback.

The larger Buildings and Play actions reuse the existing jade button skin in all its states. Expeditions remains the smaller compass action. Building name/subtitle bubbles use the existing story bubble renderer and persist until the next press.
