# Building catalogue

Christmas Market has **40 objects**, all modelled and rendered in Blender as
[docs/BUILDING_ART.md](../../../docs/BUILDING_ART.md) describes:

- **20 market stalls on the campaign ladder**, one every five levels: the 10 story stalls and
  10 between them (stable, Firework stall, chapel, ice house (key `igloo`), lakeside smokehouse
  (key `log_cabin`), Station kiosk, post office, Glassblower's stall, Woodcarvers' hall
  (key `santa_workshop`) and sleigh), each placed once. The Gingerbread house, Giant bauble and
  Pile of presents left the ladder and stay in the shop. The keys stay; only the names changed:
  `igloo` is the Ice house, `log_cabin` the Lakeside smokehouse and `santa_workshop`
  the Woodcarvers' hall.
  See the [ladder](market-pieces.md#construction-sequence).
- **The Firework stall, Station kiosk and Glassblower's stall** are the three new ladder stalls, see
  [the second market row](#second-market-row-geometry-renders-awaiting-paint-over).
- **15 decorations**: Lantern firs and Snowman bench, plus 13 more.
- **4 snowy trees.**
- **6 cottages.**

The first twelve follow the building direction sheet
(`art/building-reference-sheet.png`). They keep their identities, names and
footprints, and keep their row order, which is save data. The 25 rows after them
are new shop objects; the three stalls after those are the second market row. The first 37 runtime sprites have a category ImageGen
paint-over on the current Blender renders, matching the direction sheet's timber,
snow, garlands, ribbons and warm amber lighting. This addresses the building paint
portion of [#34](https://github.com/corepunch/nile-archive/issues/34).

![All 37 objects](screenshots/buildings.jpg)

The build shop scrolls through the selected category. Its rows show each object's
sprite, footprint, ownership and price, with a disabled action for unavailable
stock. The category arrows stay above the list.

Prices show the Tokens, Treats and Materials deducted at confirmed placement.
Each stall's price is in the [construction sequence](market-pieces.md#construction-sequence).
The shop reserves the cost of
earned stalls when checking decoration purchases. Older saves retain their
wallet and buildings and can afford any previously earned stall.
[First 20 wishes and price sources](resource-prototype.md)

## Source and pipeline

| Step | File |
| --- | --- |
| Catalogue: key, name, category, footprint, cost, Star unlock, description | `art/building-catalogue/catalogue.json` |
| Models, one builder per key | `art/building-catalogue/market_wishes.py` for the first twelve, `build_scene.py` for the rest |
| Master scene, one collection per object, named after its key | `art/building-catalogue/christmas_market_buildings.blend` |
| Render, one sprite and shadow per object at 100 px a tile side | `make buildings GAME=christmas-market` |
| Pivot and base width | `art/building-catalogue/registration.json` |
| `lua/buildings.lua`, manifest | `tools/prepare_catalogue.py` |

- **Modelling.** One Blender unit is one tile side and the pivot is the
  footprint's ground centre. The [city camera](../../../docs/BUILDINGS.md#the-camera)
  is the same as every other game's.
- **Bases.** The ten story stalls and the two original decorations stand on a
  snow-covered brick slab that is exactly the footprint. Cottages stand on a
  cobble slab. The other decorations and the trees stand on the snow, and
  their footprint is a virtual base.
- **Style.** Every vertex is clamped to the footprint. The shared kit adds
  evergreen garlands with warm bulbs, red bows, iron lanterns and snow-capped
  firs.
- **Lighting.** Warm sun, blue fill and Cycles on the CPU at 64 samples, with
  transparent film. Ground shadows are a separate pass with their own sun, direction, blue tint and strength (see
  [Ground shadows](../../../docs/BUILDING_ART.md#ground-shadows)).
- **Painted registration.** The current camera projects a footprint's width as
  `(w * cos(yaw) + h * sin(yaw)) * ppt`. The importer projects the model's slab
  corners at ground level and resamples the painted stone and snow onto the
  visible contact edges. It rejects gaps in the projected slab and edge errors
  greater than one source pixel. `city.tile` is 56 with
  `clearance = size2(1, 1)`, reserving half a tile around each base.

`art/building-catalogue/painted-v1/` retains every input/output atlas, prompt, cell
layout, original render registration and per-key crop/scale/translation in
`imports.json`. The import record also identifies which sprites use projected
foundation edges. Decorations with a virtual base use the authored RGBA crop.
Reproduce with `python3 tools/import_painted_buildings.py christmas-market`.
See the [painted catalogue review](review/painted-buildings/current-camera/README.md)
and the [adjacent foundation review](review/foundations/README.md).

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
Cottages. The listed resources are paid once on confirmation. Some items
also need Christmas Stars. Stars unlock them and are never spent.

## Reproduce and verify

```sh
make buildings GAME=christmas-market REBUILD=1     # add KEYS="a b" to render a few
python3 games/christmas-market/tools/prepare_catalogue.py --inventory
make && make test     # runs prepare_catalogue.py --check and check_assets.py
xvfb-run -a make test ONLY="building-review shop market"
```

Without a Blender binary, use the `bpy` module from PyPI (see BUILDING_ART.md).
To inspect or tweak the scene in a running Blender, send `build_scene.py` through
the MCP socket bridge:
`python3 games/emergency/source/tools/blender_mcp.py games/christmas-market/art/building-catalogue/build_scene.py`.
It builds the collections there and does not overwrite the open file.
A full render of all 40 objects takes about two minutes on four CPU cores.

## Runtime inventory

| ID / key | Name | Category | Tiles | Cost (Tokens / Treats / Materials) | Stars | Reviewed city capture |
| --- | --- | --- | --- | --- | ---: | --- |
| 0 / `arch` | Welcome arch | wonder | 3 x 3 | 70 / 0 / 0 | 0 | [Page 1](review/painted-buildings/current-camera/after-building-review-1.jpg) |
| 1 / `lumber` | Lumber workshop | wonder | 3 x 3 | 1115 / 410 / 0 | 0 | [Page 1](review/painted-buildings/current-camera/after-building-review-1.jpg) |
| 2 / `bakery` | Gingerbread bakery | wonder | 3 x 3 | 1065 / 0 / 640 | 0 | [Page 1](review/painted-buildings/current-camera/after-building-review-1.jpg) |
| 3 / `cocoa` | Hot cocoa kiosk | wonder | 3 x 3 | 1355 / 1390 / 1165 | 0 | [Page 1](review/painted-buildings/current-camera/after-building-review-1.jpg) |
| 4 / `toys` | Toymaker’s workshop | wonder | 3 x 3 | 1455 / 1110 / 1170 | 0 | [Page 2](review/painted-buildings/current-camera/after-building-review-2.jpg) |
| 5 / `gifts` | Gift wrapping pavilion | wonder | 3 x 3 | 1545 / 1080 / 1090 | 0 | [Page 2](review/painted-buildings/current-camera/after-building-review-2.jpg) |
| 6 / `candles` | Candlelight shop | wonder | 3 x 3 | 1960 / 1235 / 1255 | 0 | [Page 2](review/painted-buildings/current-camera/after-building-review-2.jpg) |
| 7 / `carousel` | Reindeer carousel | wonder | 3 x 3 | 1990 / 1190 / 1185 | 0 | [Page 2](review/painted-buildings/current-camera/after-building-review-2.jpg) |
| 8 / `rink` | Winter skating rink | wonder | 3 x 3 | 1880 / 1210 / 1070 | 0 | [Page 3](review/painted-buildings/current-camera/after-building-review-3.jpg) |
| 9 / `tree` | Christmas tree | wonder | 3 x 3 | 2520 / 1440 / 1240 | 0 | [Page 3](review/painted-buildings/current-camera/after-building-review-3.jpg) |
| 10 / `firs` | Lantern firs | building | 2 x 2 | 55 / 0 / 8 | 0 | [Page 3](review/painted-buildings/current-camera/after-building-review-3.jpg) |
| 11 / `bench` | Snowman bench | building | 2 x 2 | 65 / 0 / 10 | 0 | [Page 3](review/painted-buildings/current-camera/after-building-review-3.jpg) |
| 12 / `snowman` | Snowman | building | 1 x 1 | 0 / 3 / 3 | 0 | [Page 4](review/painted-buildings/current-camera/after-building-review-4.jpg) |
| 13 / `presents` | Pile of presents | wonder | 1 x 1 | 200 / 500 / 60 | 0 | [Page 4](review/painted-buildings/current-camera/after-building-review-4.jpg) |
| 14 / `candy_canes` | Candy canes | building | 1 x 1 | 25 / 4 | 0 | [Page 4](review/painted-buildings/current-camera/after-building-review-4.jpg) |
| 15 / `lamp_post` | Lamp post | building | 1 x 1 | 20 / 0 / 4 | 0 | [Page 4](review/painted-buildings/current-camera/after-building-review-4.jpg) |
| 16 / `snowy_bench` | Snowy bench | building | 1 x 1 | 25 / 0 / 4 | 0 | [Page 5](review/painted-buildings/current-camera/after-building-review-5.jpg) |
| 17 / `mailbox` | Letters to Santa | building | 1 x 1 | 55 / 0 / 6 | 3 | [Page 5](review/painted-buildings/current-camera/after-building-review-5.jpg) |
| 18 / `snow_rocks` | Snowy rocks | building | 1 x 1 | 15 | 0 | [Page 5](review/painted-buildings/current-camera/after-building-review-5.jpg) |
| 19 / `giant_ornament` | Giant bauble | wonder | 1 x 1 | 160 / 400 / 50 | 0 | [Page 5](review/painted-buildings/current-camera/after-building-review-5.jpg) |
| 20 / `ice_star` | Ice star sculpture | building | 1 x 1 | 85 / 0 / 8 | 6 | [Page 6](review/painted-buildings/current-camera/after-building-review-6.jpg) |
| 21 / `nutcracker` | Nutcracker guard | building | 1 x 1 | 95 / 0 / 15 | 6 | [Page 6](review/painted-buildings/current-camera/after-building-review-6.jpg) |
| 22 / `reindeer` | Reindeer | building | 1 x 1 | 110 / 12 | 9 | [Page 6](review/painted-buildings/current-camera/after-building-review-6.jpg) |
| 23 / `penguins` | Penguin pair | building | 1 x 1 | 100 / 8 | 9 | [Page 6](review/painted-buildings/current-camera/after-building-review-6.jpg) |
| 24 / `wreath_arch` | Wreath arch | building | 2 x 1 | 125 / 0 / 20 | 6 | [Page 7](review/painted-buildings/current-camera/after-building-review-7.jpg) |
| 25 / `sleigh` | Santa's sleigh | wonder | 2 x 1 | 2445 / 1360 / 1215 | 0 | [Page 7](review/painted-buildings/current-camera/after-building-review-7.jpg) |
| 26 / `igloo` | Ice house | wonder | 2 x 2 | 1155 / 835 / 1000 | 0 | [Page 7](review/painted-buildings/current-camera/after-building-review-7.jpg) |
| 27 / `fir_snowy` | Snowy fir | tree | 1 x 1 | 20 | 0 | [Page 7](review/painted-buildings/current-camera/after-building-review-7.jpg) |
| 28 / `birch` | Frosted birch | tree | 1 x 1 | 25 | 0 | [Page 8](review/painted-buildings/current-camera/after-building-review-8.jpg) |
| 29 / `fir_decorated` | Decorated fir | tree | 1 x 1 | 70 / 0 / 12 | 3 | [Page 8](review/painted-buildings/current-camera/after-building-review-8.jpg) |
| 30 / `pine_grove` | Pine grove | tree | 2 x 2 | 105 / 0 / 10 | 6 | [Page 8](review/painted-buildings/current-camera/after-building-review-8.jpg) |
| 31 / `log_cabin` | Lakeside smokehouse | wonder | 2 x 2 | 1660 / 930 / 1265 | 0 | [Page 8](review/painted-buildings/current-camera/after-building-review-8.jpg) |
| 32 / `gingerbread_house` | Gingerbread house | wonder | 2 x 2 | 150 / 40 / 80 | 0 | [Page 9](review/painted-buildings/current-camera/after-building-review-9.jpg) |
| 33 / `post_office` | North Pole post office | wonder | 2 x 2 | 2315 / 1485 / 1455 | 0 | [Page 9](review/painted-buildings/current-camera/after-building-review-9.jpg) |
| 34 / `chapel` | Snowy chapel | wonder | 2 x 2 | 1010 / 0 / 630 | 0 | [Page 9](review/painted-buildings/current-camera/after-building-review-9.jpg) |
| 35 / `reindeer_stable` | Reindeer stable | wonder | 3 x 2 | 685 / 245 / 0 | 0 | [Page 9](review/painted-buildings/current-camera/after-building-review-9.jpg) |
| 36 / `santa_workshop` | Woodcarvers' hall | wonder | 3 x 3 | 1870 / 1175 / 990 | 0 | [Page 10](review/painted-buildings/current-camera/after-building-review-10.jpg) |
| 37 / `firework_stall` | Firework stall | wonder | 2 x 2 | 905 / 340 / 430 | 0 | [Footprints](review/second-market-row/footprints.jpg), geometry render only |
| 38 / `station_kiosk` | Station kiosk | wonder | 2 x 2 | 1275 / 840 / 1040 | 0 | [Footprints](review/second-market-row/footprints.jpg), geometry render only |
| 39 / `glassblower` | Glassblower's stall | wonder | 2 x 2 | 1920 / 1190 / 1210 | 0 | [Footprints](review/second-market-row/footprints.jpg), geometry render only |

## Second market row: geometry renders, awaiting paint-over

Tracked in [issue #109](https://github.com/corepunch/nile-archive/issues/109): each needs a hand-painted pass that keeps its geometry, camera and registration.

`firework_stall`, `station_kiosk` and `glassblower` (rows 37 to 39) are registered Blender/Scener
renders of the shared city camera with no painted-v1 pass yet, so they currently look
simpler and flatter than the 37 painted sprites beside them. Each is a 2 x 2 `wonder` on the
brick-and-snow market slab, main facade towards -Y. They are on the campaign ladder after levels 16, 46 and 71 at the fitted prices in the
[construction sequence](market-pieces.md#construction-sequence).
Review captures: [renders](review/second-market-row/renders.jpg) and
[footprints](review/second-market-row/footprints.jpg) (`--building-review 10 --footprints`, 480x900).

Reproduce: `make buildings GAME=christmas-market KEYS="firework_stall station_kiosk glassblower"`
(Scener; needs an orion-ui checkout via `ORION_UI=...`), then
`python3 games/christmas-market/tools/check_assets.py --update`.

Paint-over brief for all three: keep the render's geometry, lighting, camera and registration,
and add the same hand-painted surface as the existing Christmas stalls (see
[BUILDING_STYLE.md](../../../docs/BUILDING_STYLE.md) and the painted cocoa kiosk, candlelight
shop and log cabin as style references): thick soft snow caps and drip edges, garlands with
warm bulbs and red bows, carved timber grain, glowing amber windows. Use the render as the edit
target and run the importer for the three keys.

| Key | Paint | Materials and colours |
| --- | --- | --- |
| `firework_stall` | Open timber stall whose counter holds crates of indigo/midnight-blue paper cracker bundles (tied in threes with gold string) and rockets on sticks; pale back wall with gold sparks, a wooden sign board with a gold star on the front gable, indigo-and-cream striped awning over the right of the counter, a small lantern, a window on the +X wall. | Midnight and indigo (#1C2162, #3A3C9E) paper and stall front, cream awning stripes and trim, honey timber counter, gold string and star, snow roof over a midnight gable. No red or green fireworks: keep the New Year palette indigo and gold. |
| `station_kiosk` | Small railway kiosk with a round clock on the front gable (cream face, gold rim, iron hands, 12 ticks), a serving hatch with a striped awning and an iron pole of salted pretzels, a short snowy platform edge with a yellow safety line and a bench, a lamp post with wreath and a suitcase. | Railway green walls (#1F6E3A) with cream trim and a dark red roof under snow, red-and-cream awning, baked amber pretzels with white salt, grey stone platform, gold safety line, iron lamp. |
| `glassblower` | Dark timber stall with a lit amber shop window holding two shelves of round glass baubles, more baubles hanging on strings under the eave and on the counter, a red-brick furnace on the +X side with a glowing mouth and a tall chimney with a snow cap and smoke, a blowpipe leaning out, a crate of baubles and a dressed fir. | Dark brown planks with cream trim, green roof under snow, brick red (#A8503A) furnace, glass in amber and gold (#E48A1E, #F8C45A, #F0B83A) with bright highlights, warm firelight on the snow below the mouth. |

## Style and prompt provenance

See the [shared building style guide](../../../docs/BUILDING_STYLE.md) for the
accepted palette, materials, polish and review criteria, and the
[reference index](../art/building-catalogue/painted-v1/references.json) for exact
prompts, ordered input images, hashes and accepted versions.

## Enlarged painted sprites

The enlarged objects `snowy_bench`, `fir_snowy`, `birch`, `fir_decorated`, `pine_grove` use the `z-enlarged` painted atlas, based on the registered Blender renders at `ef26de3`. Normal world state only; interaction feedback remains an engine effect. Sources, exact ImageGen prompt, layout, import transforms and reproduction command are recorded in [painted-v1](../art/building-catalogue/painted-v1/README.md); [in-game footprint review](review/painted-buildings/enlarged/README.md).
