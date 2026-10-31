# Building catalogue

Christmas Market has **37 objects**, all modelled and rendered in Blender as
[docs/BUILDING_ART.md](../../../docs/BUILDING_ART.md) describes:

- **10 market wishes**: the campaign buildings, one per completed puzzle, in story order.
- **15 decorations**: Lantern firs and Snowman bench, plus 13 more.
- **4 snowy trees.**
- **6 cottages.**

The first twelve follow the building direction sheet
(`art/building-reference-sheet.png`). They keep their identities, names and
footprints, and keep their row order, which is save data. The 25 rows after them
are new shop objects. The Blender renders are the runtime art. The
ImageGen repaint that [#34](https://github.com/corepunch/nile-archive/issues/34)
plans is still to come.

![All 37 objects (art/building-catalogue/geometry-atlas.png)](../art/building-catalogue/geometry-atlas.png)

## Source and pipeline

| Step | File |
| --- | --- |
| Catalogue: key, name, category, footprint, cost, Star unlock, description | `art/building-catalogue/catalogue.json` |
| Models, one builder per key | `art/building-catalogue/build_scene.py` |
| Master scene, one collection `cm_<key>` per object | `art/building-catalogue/christmas_market_buildings.blend` |
| Render, one sprite per object at 128 px a tile | `tools/render_buildings.py` |
| Projected pivot and base width | `art/building-catalogue/registration.json` |
| Crop, `lua/buildings.lua`, manifest, contact sheet | `tools/prepare_catalogue.py` |

- **Modelling.** One Blender unit is one tile side and the pivot is the
  footprint's ground centre. The orthographic camera at Euler (60°, 0, 45°)
  projects ground slopes to exactly ±½ (`grid_max_error_px` in
  `scene_layout.json`).
- **Bases.** The ten wishes and the two original decorations stand on a
  snow-covered brick slab that is exactly the footprint. Cottages stand on a
  cobble slab. The other decorations and the trees stand on the snow, and
  their footprint is a virtual base.
- **Style.** Every vertex is clamped to the footprint. The shared kit adds
  evergreen garlands with warm bulbs, red bows, iron lanterns and snow-capped
  firs.
- **Lighting.** Warm sun, blue fill and Cycles on the CPU at 64 samples, with
  transparent film. There is no shadow catcher.
- **Registration.** Each sprite's pivot and `base_width = (w + h) × 64` are
  projected, not measured. `tools/footprint.py` agrees to within one pixel
  on the slab buildings, for example bakery `vec2(192, 248)` / 383 measured
  against `vec2(193, 249)` / 384 projected.

The city tile stays `size2(40, 20)` with `clearance = size2(1, 1)`.
Every sprite is drawn at 40/64 = 0.625 scale.

The old ImageGen atlas (`art/buildings.png`) and its crops are retired. The
atlas stays in `art/` as the direction source, and `tools/prepare_assets.py`
no longer extracts buildings.

## Presentation and interaction states

Every object has one finished normal sprite. There are no construction,
damaged, upgrade, hover, pressed or disabled sprites. Placement, lift and the
valid/invalid footprint grid stay the engine's transient effects. Shop rows and
the building card show the normal sprite untinted, and the button captions
carry locked or unaffordable states. Lights, glowing windows and the tree's star
are baked into the sprites. Nothing is animated yet.

The shop has five categories: all, Market wishes, Decorations, Snowy trees and
Cottages. Decorations, trees and cottages cost Gold, paid once on confirmation,
and some need Christmas Stars. Stars unlock them and are never spent.

## Reproduce and verify

```sh
cd games/christmas-market/art/building-catalogue && blender -b --python build_scene.py && cd -
blender -b games/christmas-market/art/building-catalogue/christmas_market_buildings.blend \
    --python games/christmas-market/tools/render_buildings.py            # -- key ... renders a few
python3 games/christmas-market/tools/prepare_catalogue.py --inventory
python3 tools/footprint.py games/christmas-market/data/buildings/bakery.png --overlay /tmp/fp.png
make && make test     # runs prepare_catalogue.py --check and check_assets.py
xvfb-run -a ./build/christmas-market --headless --fresh --smoke --mute
xvfb-run -a python3 games/christmas-market/tools/capture_screenshots.py building-review-1 shop market
```

Without a Blender binary, use the `bpy` module from PyPI (see BUILDING_ART.md).
To inspect or tweak the scene in a running Blender, send `build_scene.py` through
the MCP socket bridge:
`python3 games/volcano/source/tools/blender_mcp.py games/christmas-market/art/building-catalogue/build_scene.py`.
It builds the collections there and does not overwrite the open file.
A full render of all 37 objects takes about two minutes on four CPU cores.

## Runtime inventory

| ID / key | Name | Category | Tiles | Pivot px | Base px | Cost (gold / holly / baubles) | Stars | Reviewed capture |
| --- | --- | --- | --- | --- | ---: | --- | ---: | --- |
| 0 / `arch` | Welcome arch | wonder | 3 x 3 | 193, 262 | 384 | 60 / 10 / 5 | 0 | [Page 1](screenshots/building-review-1.jpg) |
| 1 / `lumber` | Lumber workshop | wonder | 3 x 3 | 193, 251 | 384 | 80 / 15 / 15 | 0 | [Page 1](screenshots/building-review-1.jpg) |
| 2 / `bakery` | Gingerbread bakery | wonder | 3 x 3 | 193, 249 | 384 | 100 / 25 / 15 | 0 | [Page 1](screenshots/building-review-1.jpg) |
| 3 / `cocoa` | Hot cocoa kiosk | wonder | 3 x 3 | 193, 228 | 384 | 120 / 25 / 25 | 0 | [Page 1](screenshots/building-review-1.jpg) |
| 4 / `toys` | Toymaker’s workshop | wonder | 3 x 3 | 193, 262 | 384 | 140 / 30 / 30 | 0 | [Page 2](screenshots/building-review-2.jpg) |
| 5 / `gifts` | Gift wrapping pavilion | wonder | 3 x 3 | 193, 193 | 384 | 160 / 35 / 35 | 0 | [Page 2](screenshots/building-review-2.jpg) |
| 6 / `candles` | Candlelight shop | wonder | 3 x 3 | 193, 248 | 384 | 180 / 35 / 45 | 0 | [Page 2](screenshots/building-review-2.jpg) |
| 7 / `carousel` | Reindeer carousel | wonder | 3 x 3 | 193, 207 | 384 | 200 / 40 / 50 | 0 | [Page 2](screenshots/building-review-2.jpg) |
| 8 / `rink` | Winter skating rink | wonder | 3 x 3 | 193, 164 | 384 | 220 / 45 / 55 | 0 | [Page 3](screenshots/building-review-3.jpg) |
| 9 / `tree` | Christmas tree | wonder | 3 x 3 | 193, 280 | 384 | 250 / 50 / 60 | 0 | [Page 3](screenshots/building-review-3.jpg) |
| 10 / `firs` | Lantern firs | building | 2 x 2 | 129, 159 | 256 | 45 | 0 | [Page 3](screenshots/building-review-3.jpg) |
| 11 / `bench` | Snowman bench | building | 2 x 2 | 129, 125 | 256 | 60 | 0 | [Page 3](screenshots/building-review-3.jpg) |
| 12 / `snowman` | Snowman | building | 1 x 1 | 36, 92 | 128 | 35 | 0 | [Page 4](screenshots/building-review-4.jpg) |
| 13 / `presents` | Pile of presents | building | 1 x 1 | 43, 50 | 128 | 40 | 0 | [Page 4](screenshots/building-review-4.jpg) |
| 14 / `candy_canes` | Candy canes | building | 1 x 1 | 27, 80 | 128 | 30 | 0 | [Page 4](screenshots/building-review-4.jpg) |
| 15 / `lamp_post` | Lamp post | building | 1 x 1 | 11, 119 | 128 | 35 | 0 | [Page 4](screenshots/building-review-4.jpg) |
| 16 / `snowy_bench` | Snowy bench | building | 1 x 1 | 35, 63 | 128 | 30 | 0 | [Page 5](screenshots/building-review-5.jpg) |
| 17 / `mailbox` | Letters to Santa | building | 1 x 1 | 24, 95 | 128 | 40 | 3 | [Page 5](screenshots/building-review-5.jpg) |
| 18 / `snow_rocks` | Snowy rocks | building | 1 x 1 | 49, 48 | 128 | 20 | 0 | [Page 5](screenshots/building-review-5.jpg) |
| 19 / `giant_ornament` | Giant bauble | building | 1 x 1 | 36, 89 | 128 | 60 | 3 | [Page 5](screenshots/building-review-5.jpg) |
| 20 / `ice_star` | Ice star sculpture | building | 1 x 1 | 37, 95 | 128 | 70 | 6 | [Page 6](screenshots/building-review-6.jpg) |
| 21 / `nutcracker` | Nutcracker guard | building | 1 x 1 | 22, 90 | 128 | 80 | 6 | [Page 6](screenshots/building-review-6.jpg) |
| 22 / `reindeer` | Reindeer | building | 1 x 1 | 31, 93 | 128 | 90 | 9 | [Page 6](screenshots/building-review-6.jpg) |
| 23 / `penguins` | Penguin pair | building | 1 x 1 | 20, 68 | 128 | 80 | 9 | [Page 6](screenshots/building-review-6.jpg) |
| 24 / `wreath_arch` | Wreath arch | building | 2 x 1 | 66, 139 | 192 | 90 | 6 | [Page 7](screenshots/building-review-7.jpg) |
| 25 / `sleigh` | Santa's sleigh | building | 2 x 1 | 65, 85 | 192 | 150 | 12 | [Page 7](screenshots/building-review-7.jpg) |
| 26 / `igloo` | Igloo | building | 2 x 2 | 84, 83 | 256 | 120 | 9 | [Page 7](screenshots/building-review-7.jpg) |
| 27 / `fir_snowy` | Snowy fir | tree | 1 x 1 | 35, 104 | 128 | 25 | 0 | [Page 7](screenshots/building-review-7.jpg) |
| 28 / `birch` | Frosted birch | tree | 1 x 1 | 27, 96 | 128 | 30 | 0 | [Page 8](screenshots/building-review-8.jpg) |
| 29 / `fir_decorated` | Decorated fir | tree | 1 x 1 | 37, 120 | 128 | 50 | 3 | [Page 8](screenshots/building-review-8.jpg) |
| 30 / `pine_grove` | Pine grove | tree | 2 x 2 | 86, 162 | 256 | 80 | 6 | [Page 8](screenshots/building-review-8.jpg) |
| 31 / `log_cabin` | Log cabin | cottage | 2 x 2 | 129, 197 | 256 | 180 | 6 | [Page 8](screenshots/building-review-8.jpg) |
| 32 / `gingerbread_house` | Gingerbread house | cottage | 2 x 2 | 129, 172 | 256 | 200 | 9 | [Page 9](screenshots/building-review-9.jpg) |
| 33 / `post_office` | North Pole post office | cottage | 2 x 2 | 129, 177 | 256 | 220 | 12 | [Page 9](screenshots/building-review-9.jpg) |
| 34 / `chapel` | Snowy chapel | cottage | 2 x 2 | 129, 210 | 256 | 260 | 15 | [Page 9](screenshots/building-review-9.jpg) |
| 35 / `reindeer_stable` | Reindeer stable | cottage | 3 x 2 | 161, 205 | 320 | 280 | 18 | [Page 9](screenshots/building-review-9.jpg) |
| 36 / `santa_workshop` | Santa's workshop | cottage | 3 x 3 | 193, 279 | 384 | 320 | 21 | [Page 10](screenshots/building-review-10.jpg) |
