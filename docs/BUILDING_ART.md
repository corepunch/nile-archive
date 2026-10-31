# Creating and rendering building art in Blender

This guide covers how city buildings and decorations are modelled in Blender,
rendered to sprites, registered on the tile grid, added to the game, checked and
documented. Nile Archive's 96-object catalogue and Christmas Market's 37 objects
were made this way, and so were the geometry guides for Relic Rush's catalogue. [BUILDINGS.md](BUILDINGS.md)
is the spec for footprints, pivots and base widths. This guide is how to
produce art that meets it.

| | Nile Archive | Relic Rush | Christmas Market |
|---|---|---|---|
| Master scene script | `games/nile-archive/art/building-catalogue/build_scene.py` | `games/relic-rush/art/building-catalogue/build_scene.py` | `games/christmas-market/art/building-catalogue/build_scene.py` |
| Catalogue | `…/art/building-catalogue/catalogue.json` | same path in Relic Rush | same path; cost is `[gold]` or `[gold, holly, baubles]` |
| Render | `games/nile-archive/tools/render_buildings.py` (one sprite per object) | `games/relic-rush/tools/render_building_atlas.py` (a paint-over guide atlas) | `games/christmas-market/tools/render_buildings.py` (one sprite per object) |
| Import | `games/nile-archive/tools/prepare_catalogue.py` | `games/relic-rush/tools/prepare_buildings.py` | `games/christmas-market/tools/prepare_catalogue.py` (writes `lua/buildings.lua`) |
| Runtime sprites | the Blender renders themselves | ImageGen paint-overs of the renders | the Blender renders themselves |
| Inventory doc | [games/nile-archive/docs/building-catalogue.md](../games/nile-archive/docs/building-catalogue.md) | [games/relic-rush/docs/building-catalogue.md](../games/relic-rush/docs/building-catalogue.md) | [games/christmas-market/docs/building-catalogue.md](../games/christmas-market/docs/building-catalogue.md) |

The steps below use Nile Archive's paths. Relic Rush has the same
layout under `games/relic-rush/`.

## 1. Set up

- **Blender 5.2**, run headless with `blender -b`. Where there is no Blender
  binary, as in a cloud container, the `bpy` module from PyPI is the same
  Blender:

  ```sh
  python3.13 -m venv /tmp/bvenv && /tmp/bvenv/bin/pip install bpy   # ~400 MB, Python 3.13
  ```

  `blender -b master.blend --python script.py -- args` then becomes:

  ```sh
  /tmp/bvenv/bin/python -c "import bpy,sys,runpy; bpy.ops.wm.open_mainfile(filepath=sys.argv[1]); \
      s=sys.argv[2]; sys.argv=['blender','--']+sys.argv[3:]; runpy.run_path(s,run_name='__main__')" \
      master.blend script.py args...
  ```

- **Pillow** for the import step (`pip install pillow`).
- **The game build** for the checks: `make` builds it. On Linux, install the CI
  packages (`libx11-dev libegl1-mesa-dev libgl-dev libasound2-dev xvfb`) and
  capture under Xvfb with `LIBGL_ALWAYS_SOFTWARE=1`. Check out the submodules
  first: `git submodule update --init`.

## 2. Add the object to the catalogue

`art/building-catalogue/catalogue.json` is the list of what exists. Each row is:

```json
["key", "Name shown in the game", "category", w, h, coins, stars, "note"]
```

| Field | Requirement |
|---|---|
| `key` | Lower-case snake_case and unique. It names the builder function, the Blender collection (`na_<key>`), the sprite (`data/buildings/<key>.png`) and the save-independent identity. |
| Name | In the game's language. Nile Archive is Russian. |
| `category` | One of the tray's categories: `wonder`, `building`, `tree`, `bush`, `flower`, `statue`, `water`, `garden`, `camp`, `animal`, `rock`. A new category also needs an entry in `TRAY_CATEGORIES` in `lua/archive_island.lua`. |
| `w`, `h` | The footprint in whole tiles. `w` runs along the front-left side (world X), `h` along the front-right side (world Y). Choose it from what the art should cover, not to space objects apart: spacing comes from `city.clearance`. |
| `coins`, `stars` | The price, paid once on confirmation, and the Star unlock (Nile Archive: 0–9, the sum of best chapter Stars). Decorations grant no Influence. |
| `note` | Free text: what it depicts, its Relic Rush slot, the reference it follows. |

**Order is save data.** A catalogue object's city type is `5 + row index`, and
saves store types. Append new rows at the end. Never reorder, remove or reuse
a row once it has shipped; a retired object keeps its row. The importer
asserts 96 rows and a 12 × 8 contact sheet. Raise both (`len(...) == 96`,
`CELL, COLS, ROWS`) when the catalogue grows.

## 3. Model it

Write one builder function per object in `build_scene.py`, named after the key.
If the key clashes with a helper, register it in `BUILDERS`. The builder
receives a `Kit` and adds geometry to it in **pivot-local coordinates**:

- **Units.** One Blender unit is one tile side. The pivot, the footprint's
  ground centre, is the origin. Z is up.
- **Axes.** World X is the footprint's `w` side and runs down-right on screen.
  World Y is the `h` side and runs up-right. The camera sees faces whose normals
  point to **+X (front right)** and **−Y (front left)**. Put doors, windows,
  reliefs and other detail on those faces. `face(a, b)` and `doorway(k, a, b, …)`
  mount detail on the outside of a wall walked from `a` to `b`.
- **The base.** Objects in the categories `wonder` and `building` stand on a
  paved slab that `build()` adds automatically. It is exactly the footprint and
  `G = .1` high, so build from `z = G`. Decorations stand on the grass at
  `z = 0` with no slab; their footprint is a virtual base.
- **One-tile decorations are scaled ×2.** Model them at true scale. `build()`
  scales every 1 × 1 decoration about its pivot by `DECOR_SCALE` (2.0), with
  the bevels and lights. The scaled object fills the tile plus the half tile
  that `city.clearance` reserves around it, so `DECOR_SCALE` must not exceed
  `1 + clearance` (in tiles). The footprint, `base_width` and price stay one
  tile's. The vertex clamp works at model scale: a one-tile builder still
  keeps its geometry within ±0.5.
- **Stay inside the footprint.** `build()` clamps every vertex to the footprint
  rectangle, so anything that overhangs is squashed flat. Use `k.fit(x, y,
  reach)` (as `k.palm` and `k.puff` do) to move plants inward. Keep props on the
  base, because footprints may touch their neighbours'.
- **Style.** Few, big, soft shapes. The object should read at a glance from
  its silhouette and two or three colours, with nothing smaller than about a
  tenth of a tile. Use the palette constants (`LIME`, `WASH`, `LAPIS`, `TEAL`,
  `GOLD`, `OCHRE`, …) rather than new colours. `J(col)` and `lime()` add slight
  per-block variation. Materials come from the kit: `stone`, `slab`, `wood`,
  `clay`, `glaze`, `gold`, `cloth`, `leaf`, `hedge`, `glass`, `matte`, `water`,
  `flame` and `glow`. The bevel widths in `BEVELS` give the soft, toy-like edges.
- **Primitives.** `box`, `beam`, `tube`, `path`, `lathe`, `ball`, `surface`,
  `poly`, `prism`, `wall`, `ring`, `arch`, `window`, `pane` and `hip_roof` come
  from the shared kit. Nile Archive adds `frustum` (battered walls), `pyramid`,
  `cornice`, `column` (papyrus), `head` (nemes), `obelisk`, `jar`, `date_palm`,
  `seated_cat`, `lotus`, `pad`, `pool`, `stair`, `wheel`, `sail_boat`, `flag`
  and `band_plinth`. `k.flame` and `k.lights` add point lights for fire and glow.

Three geometry traps show up as render defects:

| Defect | Cause | Fix |
|---|---|---|
| Black, flickering sails and flags | A face and its reversed copy at the same place, which z-fight | Add one face. Cycles shades both sides. |
| A pale disc where water should be | `lathe` caps both ends, so the rim's top cap covers the water | End the rim profile inside and below the water, e.g. `[(r,0),(r,h),(r2,h),(r2,.02)]`, and raise the water to just under the rim top. |
| Stripes blur into one colour | Vertex colours interpolate between few rings | Build striped parts from solid-colour bands, one closed `lathe`/`box` per band. |
| A painted band covers a whole plinth top | A full-size `glaze` box laid on top | Use `band_plinth`: a slightly wider band just under the top. |

Rebuild the master after every change. This rewrites
`nile_archive_buildings.blend` and `scene_layout.json`; the master is generated
from the script, so never edit the `.blend` by hand:

```sh
cd games/nile-archive/art/building-catalogue && blender -b --python build_scene.py && cd -
```

## 4. Render it

```sh
blender -b games/nile-archive/art/building-catalogue/nile_archive_buildings.blend \
    --python games/nile-archive/tools/render_buildings.py -- sphinx date_palm   # omit the keys to render all
```

The render script must keep these settings, which make all sprites one
consistent, registered set:

- **Camera.** The master's orthographic camera at Euler `(60°, 0, 45°)`: 30°
  above the ground with a 45° azimuth. This projects ground slopes to exactly
  ±½, the game's 2:1 grid, not 35.26° true isometric. `build_scene.py` checks
  the projection of grid corners against the analytic 2:1 formula
  (`grid_max_error_px` in `scene_layout.json` must be ~0).
- **Fixed scale.** `TILE_PX = 128` sprite pixels per tile width for every object
  (`PPU = 128 / √2` pixels per unit). Never fit objects to a cell: the scale
  is what makes the base width exact.
- **Framing.** Each object renders alone, with every other collection and
  `na_ground` hidden. The image is the projected bounds of its vertices and
  footprint corners on whole pixels, plus a 4 px margin, so the pivot falls on
  an exact pixel corner.
- **Lighting.** The master's warm sun, soft fill and blue-grey world, unchanged.
  Do not add a shadow catcher: it leaves a hard-edged diamond on transparent ground.
- **Cycles on the CPU.** 64 samples, adaptive threshold 0.02, denoising on,
  transparent film, RGBA PNG and the Standard view transform. Rendering all 96
  objects takes about 1.5 minutes on four cores.

For each object the script writes `data/buildings/<key>.png` and an entry in
`art/building-catalogue/registration.json`: the image size, the pivot in image
pixels and `base_width = (w + h) × 64`. The engine scales a sprite so that
`base_width` covers `(w + h)` tile half-widths. Every catalogue sprite is
therefore drawn at the same 24/64 = 0.375 scale on Nile Archive's
`size2(24, 12)` tile.

## 5. Import it

```sh
python3 games/nile-archive/tools/prepare_catalogue.py --inventory
```

- Crops each fresh render to its visible pixels (alpha > 2) and moves the pivot
  with the crop. Retained pixels keep their rendered RGBA: no recolouring,
  quantising or retouching. It is safe to run again, because already-cropped
  sprites take their crop from `manifest.json`.
- Generates `lua/archive_catalogue.lua`. Never edit it: `lua/archive_content.lua` appends each
  entry after the five restorations as `cost = purse(coins)`, no reward and
  `needs = purse(0, 0, 0, stars)`.
- Writes `manifest.json`, with each object's source collection, crop, pivot,
  base width, price and unlock, and `geometry-atlas.png`, the 12 × 8 contact sheet.
- `--inventory` prints the rows of the runtime inventory table in
  `docs/building-catalogue.md`. Paste them over the old rows.

## 6. Check it

Look at every picture yourself before handing anything over. A missing face, a
black sail or a footprint beside its object is a bug to fix, not a picture to post.

1. **Contact sheet.** Open `geometry-atlas.png` on a solid background and look
   for z-fighting, covered water, clipped or squashed parts, unreadable
   silhouettes and colours outside the palette.
2. **Measurement.** For slab buildings, run
   `python3 tools/footprint.py games/nile-archive/data/buildings/<key>.png --overlay /tmp/fp.png`.
   Its pivot and base width must agree with `manifest.json` to within a few
   pixels (the bevels round the corners it measures), and its side ratio must
   match `w : h`.
3. **In the game.** Run `--building-review N` with `--footprints`. Page N places
   objects 8(N−1)+1 to 8N on the island, zoomed to the page's largest footprint.
   Each diamond (the footprint plus its clearance ring) must sit under its
   object, with the pivot dot at the centre of the base:

   ```sh
   ./build/nile-archive --headless --mute --fresh --size 1200x900 --building-review 12 --footprints --shot /tmp/fp.png
   ```

4. **The tray.** Capture `--screen build --catalogue <category> --catalogue-page N`
   at 1200×900, 1368×1026 (iPad) and 1600×900 (16:9). This shortcut sets 7
   Stars, so the 8- and 9-Star objects also show their locked state.
5. **Build and tests:**

   ```sh
   make CFLAGS="-O2 -g -Werror"
   make test
   xvfb-run -a ./build/nile-archive --headless --fresh --smoke --mute
   ```

   The smoke test browses the tray's categories and pages and buys a
   decoration through real input. Extend it when tray behaviour changes.

## 7. Document and hand over

Everything below belongs in the same pull request as the art:

- **Catalogue doc.** Update `games/<game>/docs/building-catalogue.md`: the
  category counts, the inventory rows (`--inventory`), and the links from each
  row to its reviewed capture.
- **Review gallery.** Re-capture the affected `--building-review` pages with
  footprints, the tray shots and the contact sheet into
  `games/<game>/docs/review/building-catalogue/`. Re-render the documentation
  shots with `make shots`, and commit only the screenshots your change affects.
- **Commit the sources** together with the sprites: `catalogue.json`,
  `build_scene.py`, the rebuilt `.blend` (with no `.blend1` backup),
  `scene_layout.json`, `registration.json`, `manifest.json` and
  `geometry-atlas.png`. Nothing may depend on files outside the repository.
- **Gaps get issues.** A placeholder, a missing state or a known visual defect
  that will remain gets a GitHub issue before handoff, with the concrete states
  and acceptance criteria, linked from the catalogue doc. Close it from the
  pull request that fixes it. The open Nile Archive gaps (the paint-over pass,
  and whether 2×2 decorations should grow like one-tile ones) are in
  [issue #32](https://github.com/corepunch/nile-archive/issues/32).
- **Pull request.** Embed before/after tray shots, the contact sheet and
  footprint pages, with image URLs pinned to the pushed commit (see
  [AGENTS.md](../AGENTS.md)).

## Optional: painting over the renders

Relic Rush's runtime sprites are ImageGen paint-overs of its renders. The
render's geometry, lighting and registration are kept, and a painted surface
is added on top. To do the same for Nile Archive (issue #32):

- **Edit the whole set together.** Use one ImageGen atlas per category, with
  `geometry-atlas.png` (or a per-category guide) as the edit target and the
  game's painted art (the five restorations and `island.png`) as the style
  reference.
- **Keep the sources.** Save every prompt and every generated version beside
  the master, and record which version each object comes from.
- **Preserve authored alpha and the object's placement.** Crops and the
  registration transforms may only align, never redesign.
  Re-measure slab buildings with `tools/footprint.py` and record the measured
  pivots and base widths when they move.
- **Interaction states belong to the engine.** Don't create states by tinting
  or recolouring. Placement, lift and valid/invalid feedback stay engine
  effects, as documented in each catalogue doc.
