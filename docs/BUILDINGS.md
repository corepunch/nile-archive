# Building specs

City buildings stand on a grid of whole tiles, seen by one camera. Every building
type says how many tiles it covers, which pixel of its sprite is the ground
centre it stands on, and how wide its base is in that sprite. The engine
derives the drawing scale, the snapping, the collision and the green/red
footprint from those three numbers, so they must match the art.

## The camera

The ground is seen by an orthographic camera turned **30° from the tile axes**
(yaw) and looking down at **40°** (elevation). This is a trimetric projection,
measured from June's Journey. It is not 2:1 isometric, and a tile is a skewed
parallelogram rather than a symmetric diamond.

| Per world unit of | Screen x | Screen y |
|---|---|---|
| tile u, the front-left side (`size.w`) | +0.866 | +0.321 |
| tile v, the front-right side (`size.h`) | −0.500 | +0.557 |
| height | 0 | −0.766 |

So the front-left edge is shallow (slope 0.371) and the front-right edge steep
(slope 1.114). `CITY_CAMERA_YAW` and `CITY_CAMERA_ELEVATION` in `engine/engine.h`
are the only definition: the engine projects with them, and `tools/city_camera.py`
reads them for the art tools. `make test` fails when a game's rendered art doesn't
match. Changing them means re-rendering every game.

## The tile

`city.tile` is a tile's side on the ground in world units (default 45). Set it
before `c:init`: drawn sizes are derived from it. Each game picks one tile for all
its buildings:

| Game | `city.tile` | `city.clearance` |
|---|---|---|
| Nile Archive | `34` | `size2(0, 0)` |
| Relic Rush | `56` | `size2(1, 1)` |
| Christmas Market | `56` | `size2(1, 1)` |

`city.clearance` adds tiles to every footprint around its base, so buildings
keep apart: with `size2(1, 1)` a 2 × 2 base takes a 3 × 3 footprint, half a
tile of open ground on each side. It changes the footprint (snapping,
collision, the green/red tiles), never the sprite's size: `size` is always
the base the art shows. Relic Rush and Christmas Market leave one tile
between bases. In Nile Archive, neighbouring bases may share an edge.

## A building

```lua
{name = "Artisan workshop", sprite_path = "buildings/workshop.png",
 size = size2(3, 2),        -- tiles: 3 along the front-left side, 2 along the front-right
 pivot = vec2(144, 246),    -- sprite pixel of the footprint's ground centre
 base_width = 278,          -- sprite pixels from the footprint's left corner to its right one
 cost = purse(100, 25, 15)}
```

- **`size`**, whole tiles. `w` runs along the front-left side (from the left
  corner down to the front corner), `h` along the front-right side (from the
  front corner up to the right corner). 2 × 2, 3 × 2 and 3 × 3 are typical.
  Pick the sides from the art: the ratio of the base's front-left to
  front-right edge, rounded to whole tiles.
- **`pivot`**, sprite pixels: the centre of the base on the ground, halfway
  between its left and right corners. It is the building's zero: `building.pos`
  is this point in the world, and the sprite is drawn so the pivot lands on
  it. It is not the bottom of the image: the front corner and anything in
  front of the base (steps, plants, a rug) hang below it.
- **`base_width`**, sprite pixels between the base's left and right corners.
  The engine scales the sprite so that width covers
  `city_base_span(c, size)`, `(w·cos yaw + h·sin yaw)·tile`, so the drawn base
  matches the footprint exactly. `height` follows from it; don't set it by hand.

A building with no `size` falls back to a circle of `city.spacing` and a
sprite drawn `height` tall, standing on its bottom centre.

## How the grid uses it

- **Snapping.** `c:snap(p, type)` puts the footprint on whole tiles: a side
  with an odd number of tiles centres on a tile, an even one on a tile edge.
  Drops and confirmations snap; a dragged ghost follows the finger
  and snaps when let go.
- **Collision.** Footprints (`size` plus `city.clearance`) are rectangles in
  tile space: they may share an edge but not overlap. Every covered tile's centre and the footprint's
  corners must be open, buildable land.
- **Drawing.** The ghost's footprint is the parallelogram of its tiles with
  the tile lines inside, green when it fits and red when it doesn't. During
  placement or relocation, all other buildings show cream perimeter guides
  around their collision footprints, including clearance. A dark edge keeps
  them readable over the terrain. Christmas Market enables
  `city.placement_guides_on_ground` so opaque building pixels cover the
  lines behind them. The mover's old footprint is omitted. Confirm or Cancel
  hides the guides. Debug `--footprints` overlays all four edges and the pivot
  on the sprites. See the
  [placement-guide review](review/city-placement-guides/README.md).
- **Depth.** Tiles skew, so a footprint's y says little about a long neighbour's.
  A building draws in front of another when it lies past it along one tile axis
  and not before it along the other; pairs that don't relate keep y order.

## Moving a placed building

Both city games use the engine's `movable` gesture: hold a building still for
**0.5 seconds**, then drag the lifted preview. A quick drag pans the map even
when it begins on a building. Moving before the threshold permanently cancels
that press's pickup; stopping the pan does not re-arm it. UI presses, two-finger
gestures, wheel zoom, release and pointer/focus cancellation cannot trigger it.

Release snaps the preview to the grid. Tapping land never repositions the preview;
drag the building to move it again. Pickup and drop request haptic feedback;
Confirm/Cancel stay silent. Confirm commits a valid move at no cost;
Cancel keeps the original position. No layout or wallet change is saved while
previewing. Existing explicit `begin_move` commands still enter a preview;
programmatic placement and short-tap income/details retain their own behavior.
Nile Archive uses an engine form for Confirm/Cancel; Relic Rush anchors round ×/✓ controls below the preview sprite’s left/right edges. Emergency has no city-building relocation mode.

Reviewed native-input comparisons are in [the gesture review](review/city-long-press/README.md).

## Rendering buildings

Sprites are rendered from each game's `build_scene.py`. A painting can't be turned
to another camera, so a building needs a model before it has art.

```sh
make buildings GAME=relic-rush                     # every building, with Scener
make buildings GAME=relic-rush KEYS="lodge well"   # just these
make buildings GAME=relic-rush BLENDER=1           # with Blender/Cycles from the .blend instead
make buildings GAME=relic-rush BLENDER=1 REBUILD=1 # rebuild the .blend from build_scene.py first
python3 tools/buildings.py --list relic-rush       # every key
```

**Scener renders by default.** [Scener](https://github.com/corepunch/orion-ui/tree/main/apps/scener)
is a small OpenGL scene renderer. `tools/scener_buildings.py` runs the game's
`build_scene.py` unchanged, with stand-in `bpy` and `mathutils`, against a kit
(`tools/scener_kit.py`) that writes every kit call as a Scener primitive with its
modifiers: a box is a soft-box rounded by its material's bevel, a lathe a `<lathe>`, a
wall block, voussoir or roof tile a `<shape>` extruded (and tapered), a frame a
`<group>`. A piece has one colour; a `Gradient` is its gizmo, never per-vertex colour.
It writes two scenes: the lit buildings, and the same groups hidden
(`renderable="0"`), casting shadows on a white catcher. Every building gets
an orthographic camera named after its key, framed on whole pixels exactly as the
Blender script frames it, so registration is identical. Point `SCENER` at the binary,
or build `make scener` in an `orion-ui` checkout beside this one; without a display
the renders run under `xvfb-run`; `ORION_UI` names the checkout if it isn't beside this
one (the scenes use its writer kit and `utilities.xml`). All 234 buildings and shadows of the three games
take about three minutes on four CPU cores with Mesa's software renderer.

Colour that varies over a piece is a `building_kit.Gradient`: `uv` over a surface's or
lathe's parameters, or `Gradient.box(a, b, axis="z")` over the piece's own bounds, with
`repeat`, `mirror`, `edge` and `power`, as a 3ds Max map on its gizmo. Blender evaluates
the same gizmo per vertex. A builder that passes a function as a colour stops the
Scener render with the piece's name. A material Blender textures with noise (`mottle`, `bump` in `make_material`) becomes a Scener
`<material>` carrying a noise `<map>` on the same scale; its pieces name it and keep their own colours.
Scener has no global illumination: a calibrated
gain stands in for bounced light. Use `BLENDER=1` when that matters.

**A full render replaces the painted sprites.** `data/buildings/` holds the accepted
paint-over ([BUILDING_STYLE.md](BUILDING_STYLE.md)); a full `make buildings` writes raw
renders there. Use `--shadows` to re-render shadows alone, or restore the painted
sprites afterwards.

**The name is the file.** A building's Blender collection name is its key:
collection `lodge` becomes `data/buildings/lodge.png` and
`data/building-shadows/lodge.png`, and `lua/building_sprites.lua` holds its
registration under `lodge`. Games merge that table into their city defs by key;
never edit it. Numeric types stay in save files only, as positions in the game's
own list: append new rows, never reorder.

| File | Role |
|---|---|
| `games/<game>/art/buildings.json` | Where the game's master is, sprite resolution, samples, post-render step |
| `games/<game>/art/building-catalogue/build_scene.py` | The models; saves the `.blend`, and is read directly for Scener |
| `tools/building_kit.py` | The shared toolbox: palette, materials, `Kit`, `assemble()` |
| `tools/buildings.py` | The command; crops, registers, writes Lua and the review sheet |
| `tools/scener_buildings.py` | Runs the models without Blender and writes the Scener scenes |
| `tools/render_buildings_blender.py` | Runs inside Blender (`BLENDER=1`): one sprite and one shadow per building |
| `tools/city_camera.py` | The camera for all of them, read from `engine/engine.h` |

To add a building: add a function to the game's `build_scene.py`, add it to the
game's list, and run `make buildings GAME=<game> REBUILD=1 KEYS=<key>`. Footprints
are whole tiles and `assemble()` clamps geometry to them. The camera sees faces
towards -Y best and +X second, so the main facade goes on -Y. Look at the review
sheet `games/<game>/docs/screenshots/buildings.jpg`, which shows every building on
the tile grid with its footprint, pivot and name.

`python3 tools/buildings.py --check` needs no Blender and runs in `make test`. It
fails on art rendered with another camera, a sprite not named after its key, a
missing or stray file, and stale Lua.
For registered painted slabs in Christmas Market, it also checks opaque
coverage inside the projected ground polygon and compares the visible front
edges against it with a one-source-pixel rasterization tolerance.

## Measuring a hand-made sprite

Rendered sprites carry exact registration. For anything else:

```sh
python3 tools/footprint.py path/to/sprite.png --overlay /tmp/base.png
```

The script fits the base's lower V (the camera's two slopes) to the sprite's
silhouette and prints `pivot`, `base_width` and the w : h ratio. Plants or props
below the base can fool the fit; then read the corners off the image and pass them:
`--bottom X,Y` (the front corner), `--left X`, `--right X`. Open the overlay and
check that the drawn parallelogram sits on the base.

Then check it in the game. `--footprints` draws every building's footprint
and pivot over its sprite:

```sh
./build/relic-rush --headless --mute --fresh --size 480x900 --showcase --footprints --shot fp.png
./build/nile-archive --headless --mute --fresh --size 1200x900 --screen island --footprints --shot fp.png
```

Each parallelogram should outline the building's base (plus the clearance around
it), with the pivot dot in the middle.

## Art for new buildings

Keep plants and props inside the footprint. Anything that hangs outside it
overlaps the neighbours, because footprints may touch. [BUILDING_ART.md](BUILDING_ART.md)
is the modelling guide.

Relic Rush's [96-entry catalogue](../games/relic-rush/docs/building-catalogue.md)
also includes decorations without a visible slab. Their Blender ground origin
and projected whole-tile reservation define the virtual base; a small prop's
`base_width` can exceed its visible sprite width. This keeps trees, flowers and
furniture at the model's intended scale while reserving at least one whole tile.
Slab-based buildings show that base as a slab of exactly the footprint.

Nile Archive's [96-object catalogue](../games/nile-archive/docs/building-catalogue.md)
mirrors Relic Rush's slots and footprints. It renders the Blender objects
directly at a fixed 128 pixels per tile, so its pivots and base widths are
projected analytically (`base_width = (w + h) × 64`). `tools/footprint.py`
confirms them to within a few pixels on slab buildings.

## Ground shadows

`building_def.shadow_path` loads a low-resolution ground PNG independently of the
sprite. `shadow_pivot` is the same ground centre in shadow pixels and
`shadow_base_width` the footprint's width in shadow pixels, so the engine scales it
by `city_base_span(c, size) / shadow_base_width` and transparent crop margins, sprite
resolution and lift animation cannot move its anchor. Without `shadow_base_width`
a layer uses the sprite's pixel scale. Shadows draw beneath all buildings and stay
grounded during a lift. Each layer comes from the building's own geometry:
invisible casters and the shadow sun alone on a catcher, in Scener (stencil shadows,
softened by 1.2 px for the sun's disc) or in Blender (a transparent Cycles catcher).
All placed shadows draw before the fog, so closed land covers them too.

## Cloud fog

`city.fog_clouds` opts into world-space animated density and cloud lighting over the cached
closed-land mask. Animation uses frame time; income timestamps keep using wall-clock time.
This leaves pan and zoom, unlocking and terrain rules unchanged. Relic Rush and Nile Archive
use it. `city.fog` sets the palette.
