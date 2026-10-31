# Creating and rendering building art in Blender

This guide covers how city buildings and decorations are modelled in Blender,
rendered to sprites, registered on the tile grid, added to the game, checked and
documented. [BUILDINGS.md](BUILDINGS.md) is the spec for the camera, footprints, pivots
and base widths. This guide is how to produce art that meets it.

Every city game works the same way, from one command:

```sh
make buildings GAME=nile-archive                     # every building
make buildings GAME=nile-archive KEYS="sphinx"       # just this one, in seconds
make buildings GAME=nile-archive REBUILD=1           # after editing build_scene.py
```

| | Nile Archive | Relic Rush | Christmas Market |
|---|---|---|---|
| Models | `art/building-catalogue/build_scene.py`, `restorations.py` | `art/building-catalogue/build_scene.py` | `art/building-catalogue/build_scene.py` |
| Catalogue | `art/building-catalogue/catalogue.json` | same path, plus `story.json` | same path; cost is `[gold]` or `[gold, holly, baubles]` |
| After the render | `tools/prepare_catalogue.py` writes `lua/archive_catalogue.lua` | `tools/prepare_buildings.py` writes `lua/buildings.lua` | `tools/prepare_catalogue.py` writes `lua/buildings.lua` |
| Inventory doc | [building-catalogue.md](../games/nile-archive/docs/building-catalogue.md) | [building-catalogue.md](../games/relic-rush/docs/building-catalogue.md) | [building-catalogue.md](../games/christmas-market/docs/building-catalogue.md) |

Paths are under `games/<game>/`. `art/buildings.json` connects them to the shared
tools. The steps below use Nile Archive.

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
| `key` | Lower-case snake_case and unique. It names the builder function, the Blender collection, the sprite (`data/buildings/<key>.png`), its shadow and its entry in `lua/building_sprites.lua`. |
| Name | In the game's language. Nile Archive is Russian. |
| `category` | One of the tray's categories: `wonder`, `building`, `tree`, `bush`, `flower`, `statue`, `water`, `garden`, `camp`, `animal`, `rock`. A new category also needs an entry in `TRAY_CATEGORIES` in `lua/archive_island.lua`. |
| `w`, `h` | The footprint in whole tiles. `w` runs along the front-left side (world X), `h` along the front-right side (world Y). Choose it from what the art should cover, not to space objects apart: spacing comes from `city.clearance`. |
| `coins`, `stars` | The price, paid once on confirmation, and the Star unlock (Nile Archive: 0–9, the sum of best chapter Stars). Decorations grant no Influence. |
| `note` | Free text: what it depicts, its Relic Rush slot, the reference it follows. |

**Order is save data.** A catalogue object's city type is `5 + row index`, and
saves store types. Append new rows at the end. Never reorder, remove or reuse
a row once it has shipped; a retired object keeps its row. The importer
asserts 96 rows. Raise that when the catalogue grows.

## 3. Model it

Write one builder function per object in `build_scene.py`, named after the key.
If the key clashes with a helper, register it in `BUILDERS`. The builder
receives a `Kit` and adds geometry to it in **pivot-local coordinates**:

- **Units.** One Blender unit is one tile side. The pivot, the footprint's
  ground centre, is the origin. Z is up.
- **Axes.** World X is the footprint's `w` side and runs down-right on screen.
  World Y is the `h` side and runs up-right. The [city camera](BUILDINGS.md#the-camera)
  sees faces whose normals point to **−Y** best (the long, shallow, front-left
  side) and **+X** second. Put doors, windows, reliefs and other detail on −Y first. `face(a, b)` and `doorway(k, a, b, …)`
  mount detail on the outside of a wall walked from `a` to `b`.
- **The base.** Objects in the categories `wonder` and `building` stand on a
  paved slab that `assemble()` adds automatically. It is exactly the footprint and
  `G = .1` high, so build from `z = G`. Decorations stand on the grass at
  `z = 0` with no slab; their footprint is a virtual base.
- **Nile Archive's one-tile decorations fill their tile.** Model them at true scale.
  Its `model_scale`, which `assemble()` calls with each model's reach, scales every 1 × 1
  decoration about its pivot, with its bevels and lights, to just inside the tile's edge,
  at most ×2. The object always fits its footprint, and `base_width` and price stay one
  tile's. The vertex clamp works at model scale: a one-tile builder still keeps its
  geometry within ±0.5.
- **Stay inside the footprint.** `assemble()` clamps every vertex to the footprint
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

The master is generated from the script, so never edit the `.blend` by hand.

## 4. Render it

```sh
make buildings GAME=nile-archive REBUILD=1 KEYS="sphinx date_palm"   # omit KEYS to render all
```

`tools/buildings.py` starts Blender, and `tools/render_buildings_blender.py` renders
inside it. These are fixed, which is what makes all sprites one registered set:

- **Camera.** `tools/city_camera.py`, read from `engine/engine.h`.
- **Fixed scale.** `ppt` pixels per tile side from `art/buildings.json`, never fitted to a
  cell. Each sprite's `base_width` follows exactly from it and from the camera.
- **Framing.** Each object renders alone, on whole pixels, so its pivot is exact.
- **Lighting.** The master's sun, fill and world, unchanged. Each object's ground shadow
  renders separately on a catcher, at low resolution.
- **Cycles on the CPU.** 64 samples, adaptive threshold 0.02, denoising on, transparent
  film, RGBA PNG and the Standard view transform.

It then crops each sprite to its visible pixels, moving the pivot with the crop, and
gives fully transparent edge pixels their neighbours' RGB so filtering can't darken the
outline. It writes:

- `data/buildings/<key>.png` and `data/building-shadows/<key>.png`.
- `art/building-catalogue/registration.json`, the registry of every sprite.
- `lua/building_sprites.lua`, generated, which the game's Lua merges by key.
- `docs/screenshots/buildings.jpg`, the review sheet: every object on the tile grid
  with its footprint, pivot and name.
- Whatever the game's `after` step writes: its catalogue Lua and `manifest.json`.
  `--inventory` on that script prints the rows of the runtime inventory table in
  `docs/building-catalogue.md`. Paste them over the old rows.

## 5. Check it

Look at every picture yourself before handing anything over. A missing face, a
black sail or a footprint beside its object is a bug to fix, not a picture to post.

1. **Review sheet.** Open `docs/screenshots/buildings.jpg` and look for z-fighting,
   covered water, clipped or squashed parts, unreadable silhouettes and colours
   outside the palette. Every slab must sit exactly on its footprint.
2. **In the game.** Run `--building-review N` with `--footprints`. Page N places
   objects 8(N−1)+1 to 8N on the island, zoomed to the page's largest footprint.
   Each parallelogram (the footprint plus its clearance ring) must sit under its
   object, with the pivot dot at the centre of the base:

   ```sh
   ./build/nile-archive --headless --mute --fresh --size 1200x900 --building-review 12 --footprints --shot /tmp/fp.png
   ```

3. **The tray.** Capture `--screen build --catalogue <category> --catalogue-page N`
   at 1200×900, 1368×1026 (iPad) and 1600×900 (16:9). This shortcut sets 7
   Stars, so the 8- and 9-Star objects also show their locked state.
4. **Build and tests:**

   ```sh
   make CFLAGS="-O2 -g -Werror"
   make test
   xvfb-run -a ./build/nile-archive --headless --fresh --smoke --mute
   ```

   The smoke test browses the tray's categories and pages and buys a
   decoration through real input. Extend it when tray behaviour changes.

## 6. Document and hand over

Everything below belongs in the same pull request as the art:

- **Catalogue doc.** Update `games/<game>/docs/building-catalogue.md`: the
  category counts, the inventory rows (`--inventory`), and the links from each
  row to its reviewed capture.
- **Review gallery.** Re-capture the affected `--building-review` pages with
  footprints, the tray shots and the contact sheet into
  `games/<game>/docs/review/building-catalogue/`. Re-render the documentation
  shots with `make shots`, and commit only the screenshots your change affects.
- **Commit the sources** together with the sprites: `catalogue.json`,
  `build_scene.py`, the rebuilt `.blend`, `registration.json`, `manifest.json` and the
  review sheet. Nothing may depend on files outside the repository.
- **Gaps get issues.** A placeholder, a missing state or a known visual defect
  that will remain gets a GitHub issue before handoff, with the concrete states
  and acceptance criteria, linked from the catalogue doc. Close it from the
  pull request that fixes it. The open gaps are the paint-over passes:
  [#32](https://github.com/corepunch/nile-archive/issues/32) for Nile Archive, with whether its
  2×2 decorations should grow, and [#41](https://github.com/corepunch/nile-archive/issues/41) for Relic Rush.
- **Pull request.** Embed before/after tray shots, the contact sheet and
  footprint pages, with image URLs pinned to the pushed commit (see
  [AGENTS.md](../AGENTS.md)).

## Optional: painting over the renders

A paint-over keeps a render's geometry, lighting and registration and adds a painted
surface on top. It is locked to the camera it was painted from, so it must be redone
if the camera changes. No game ships one now; the old 2:1 Relic Rush paint-overs stay
in its `art/` as references (issue #32 tracks Nile Archive's pass):

- **Edit the whole set together.** Use one ImageGen atlas per category, with
  an atlas of the current renders as the edit target and the
  game's painted art (the five restorations and `island.png`) as the style
  reference.
- **Keep the sources.** Save every prompt and every generated version beside
  the master, and record which version each object comes from.
- **Preserve authored alpha and the object's placement.** Crops and the
  registration transforms may only align, never redesign.
  Re-measure slab buildings with `tools/footprint.py` when their bases move.
- **Interaction states belong to the engine.** Don't create states by tinting
  or recolouring. Placement, lift and valid/invalid feedback stay engine
  effects, as documented in each catalogue doc.
