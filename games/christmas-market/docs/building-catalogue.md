# Building catalogue

Christmas Market has **41 objects**, all modelled in Blender as
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
  [the second market row](#second-market-row).
- **Gran’s old stall** is already standing in Welcome Square at the start.
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

![All 41 objects](screenshots/buildings.jpg)

The build shop scrolls through the selected category. Its rows show each object's
sprite, footprint, ownership and price, with a disabled action for unavailable
stock. The category arrows stay above the list.

Prices show the Tokens, Treats and Materials deducted at confirmed placement.
Each stall's price is in the [construction sequence](market-pieces.md#construction-sequence).
The shop reserves the cost of
earned stalls when checking decoration purchases. Older saves retain their
wallet and buildings and can afford any previously earned stall.
[First 20 wishes and price sources](resource-prototype.md)

Gran’s old stall is the shuttered timber booth Rosa ran before retiring.
It is present when Noelle arrives to reopen the market for Advent. Players
can tap it for its description or hold it to move it, and the Welcome arch
is still the first campaign purchase. [Opening market](screenshots/opening-market.jpg)

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
A full render of the catalogue takes about two minutes on four CPU cores.

## Runtime inventory

| ID / key | Name | Category | Tiles | Cost (Tokens / Treats / Materials) | Stars | Reviewed city capture |
| --- | --- | --- | --- | --- | ---: | --- |
| 0 / `arch` | Welcome arch | wonder | 3 x 3 | 35 / 0 / 0 | 0 | [Page 1](review/painted-buildings/current-camera/after-building-review-1.jpg) |
| 1 / `lumber` | Lumber workshop | wonder | 3 x 3 | 915 / 330 / 0 | 0 | [Page 1](review/painted-buildings/current-camera/after-building-review-1.jpg) |
| 2 / `bakery` | Gingerbread bakery | wonder | 3 x 3 | 830 / 300 / 435 | 0 | [Page 1](review/painted-buildings/current-camera/after-building-review-1.jpg) |
| 3 / `cocoa` | Hot cocoa kiosk | wonder | 3 x 3 | 955 / 460 / 760 | 0 | [Page 1](review/painted-buildings/current-camera/after-building-review-1.jpg) |
| 4 / `toys` | Toymaker’s workshop | wonder | 3 x 3 | 1095 / 795 / 940 | 0 | [Page 2](review/painted-buildings/current-camera/after-building-review-2.jpg) |
| 5 / `gifts` | Gift wrapping pavilion | wonder | 3 x 3 | 1220 / 775 / 945 | 0 | [Page 2](review/painted-buildings/current-camera/after-building-review-2.jpg) |
| 6 / `candles` | Candlelight shop | wonder | 3 x 3 | 1155 / 775 / 910 | 0 | [Page 2](review/painted-buildings/current-camera/after-building-review-2.jpg) |
| 7 / `carousel` | Reindeer carousel | wonder | 3 x 3 | 1350 / 745 / 865 | 0 | [Page 2](review/painted-buildings/current-camera/after-building-review-2.jpg) |
| 8 / `rink` | Winter skating rink | wonder | 3 x 3 | 1365 / 750 / 855 | 0 | [Page 3](review/painted-buildings/current-camera/after-building-review-3.jpg) |
| 9 / `tree` | Christmas tree | wonder | 3 x 3 | 1610 / 755 / 890 | 0 | [Page 3](review/painted-buildings/current-camera/after-building-review-3.jpg) |
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
| 25 / `sleigh` | Santa's sleigh | wonder | 2 x 1 | 1625 / 770 / 870 | 0 | [Page 7](review/painted-buildings/current-camera/after-building-review-7.jpg) |
| 26 / `igloo` | Ice house | wonder | 2 x 2 | 945 / 545 / 790 | 0 | [Page 7](review/painted-buildings/current-camera/after-building-review-7.jpg) |
| 27 / `fir_snowy` | Snowy fir | tree | 1 x 1 | 20 | 0 | [Page 7](review/painted-buildings/current-camera/after-building-review-7.jpg) |
| 28 / `birch` | Frosted birch | tree | 1 x 1 | 25 | 0 | [Page 8](review/painted-buildings/current-camera/after-building-review-8.jpg) |
| 29 / `fir_decorated` | Decorated fir | tree | 1 x 1 | 70 / 0 / 12 | 3 | [Page 8](review/painted-buildings/current-camera/after-building-review-8.jpg) |
| 30 / `pine_grove` | Pine grove | tree | 2 x 2 | 105 / 0 / 10 | 6 | [Page 8](review/painted-buildings/current-camera/after-building-review-8.jpg) |
| 31 / `log_cabin` | Lakeside smokehouse | wonder | 2 x 2 | 1020 / 620 / 880 | 0 | [Page 8](review/painted-buildings/current-camera/after-building-review-8.jpg) |
| 32 / `gingerbread_house` | Gingerbread house | wonder | 2 x 2 | 150 / 40 / 80 | 0 | [Page 9](review/painted-buildings/current-camera/after-building-review-9.jpg) |
| 33 / `post_office` | North Pole post office | wonder | 2 x 2 | 1275 / 785 / 885 | 0 | [Page 9](review/painted-buildings/current-camera/after-building-review-9.jpg) |
| 34 / `chapel` | Snowy chapel | wonder | 2 x 2 | 780 / 345 / 450 | 0 | [Page 9](review/painted-buildings/current-camera/after-building-review-9.jpg) |
| 35 / `reindeer_stable` | Reindeer stable | wonder | 3 x 2 | 460 / 170 / 0 | 0 | [Page 9](review/painted-buildings/current-camera/after-building-review-9.jpg) |
| 36 / `santa_workshop` | Woodcarvers' hall | wonder | 3 x 3 | 1420 / 720 / 840 | 0 | [Page 10](review/painted-buildings/current-camera/after-building-review-10.jpg) |
| 37 / `firework_stall` | Firework stall | wonder | 2 x 2 | 790 / 280 / 290 | 0 | [Painted footprints](review/second-market-row/README.md) |
| 38 / `station_kiosk` | Station kiosk | wonder | 2 x 2 | 995 / 680 / 855 | 0 | [Painted footprints](review/second-market-row/README.md) |
| 39 / `glassblower` | Glassblower's stall | wonder | 2 x 2 | 1290 / 785 / 875 | 0 | [Painted footprints](review/second-market-row/README.md) |
| 40 / `rosa_stall` | Gran’s old stall | starter | 2 x 2 | Starting building | 0 | [Opening footprint](screenshots/starter-stall-footprint.jpg) |

### Gran’s old stall

The model is the `rosa_stall` collection in the Blender master. The ImageGen
paint-over adds visible pine grain, worn red shutters, green trim and snow
to the registered geometry. The sprite has one normal state. Placement and
pickup use the engine’s existing lift and footprint effects. See the [render guide](../art/building-catalogue/painted-v1/rosa-stall-input.png), [prompt](../art/building-catalogue/painted-v1/rosa-stall-prompt.txt) and [accepted painting](../art/building-catalogue/painted-v1/rosa-stall-output.png).

```sh
make buildings GAME=christmas-market BLENDER=1 REBUILD=1 KEYS=rosa_stall
python3 tools/import_painted_buildings.py christmas-market rosa-stall
build/test/christmas-market "shot opening-market" "shot phone-opening-market" "shot starter-stall-footprint"
```

## Second market row

The Firework stall, Station kiosk and Glassblower's stall appear at wishes 16, 46 and 71. Each sits on a 2 × 2 brick-and-snow slab with its main façade towards -Y. Their ImageGen paint-overs use the registered Scener geometry strip and the painted cocoa kiosk as the style reference. Snow caps, timber grain, garland bulbs and amber light carry over to all three. [Construction sequence](market-pieces.md#construction-sequence) · [Issue #109](https://github.com/corepunch/nile-archive/issues/109)

Each sprite retains the original ground registration. The same painted sprite draws in town, on cards and in the placement preview. The latest chimney pass opens the Station kiosk's flue and replaces the Glassblower's painted plume with live smoke. [Footprint captures at both phone sizes](review/second-market-row/README.md) · [Chimney review](review/chimneys/README.md)

Reimport the saved painted sprites with `python3 tools/import_painted_buildings.py christmas-market second-row`, reapply the [open chimney edits](#open-chimneys-and-live-smoke), then run `python3 games/christmas-market/tools/check_assets.py --update`. The layout records the source cells and foundation measurements. [Geometry guide](../art/building-catalogue/painted-v1/second-row-input.png) · [Painted source](../art/building-catalogue/painted-v1/second-row-output.png) · [Exact prompt](../art/building-catalogue/painted-v1/second-row-prompt.txt)

| Key | Paint | Materials and colours |
| --- | --- | --- |
| `firework_stall` | Open timber stall whose counter holds crates of indigo/midnight-blue paper cracker bundles (tied in threes with gold string) and rockets on sticks; pale back wall with gold sparks, a wooden sign board with a gold star on the front gable, indigo-and-cream striped awning over the right of the counter, a small lantern, a window on the +X wall. | Midnight and indigo (#1C2162, #3A3C9E) paper and stall front, cream awning stripes and trim, honey timber counter, gold string and star, snow roof over a midnight gable. No red or green fireworks: keep the New Year palette indigo and gold. |
| `station_kiosk` | Small railway kiosk with a round clock on the front gable (cream face, gold rim, iron hands, 12 ticks), a serving hatch with a striped awning and an iron pole of salted pretzels, a short snowy platform edge with a yellow safety line and a bench, a lamp post with wreath and a suitcase. | Railway green walls (#1F6E3A) with cream trim and a dark red roof under snow, red-and-cream awning, baked amber pretzels with white salt, grey stone platform, gold safety line, iron lamp. |
| `glassblower` | Dark timber stall with a lit amber shop window holding two shelves of round glass baubles, more baubles hanging on strings under the eave and on the counter, and a red-brick furnace on the +X side with a glowing mouth and an open flue. | Dark brown planks with cream trim, green roof under snow, brick red (#A8503A) furnace, glass in amber and gold (#E48A1E, #F8C45A, #F0B83A) with bright highlights, warm firelight on the snow below the mouth. |

## Open chimneys and live smoke

The Gingerbread bakery, Hot cocoa kiosk, Toymaker's workshop, Candlelight shop, Lakeside smokehouse, Gingerbread house, Woodcarvers' hall, Station kiosk and Glassblower's stall have open flues. The models use raised rim stones and a recessed soot floor. The accepted ImageGen edit replaces the chimney region on each sprite and clears the baked-in puffs from the cocoa kiosk and Glassblower's stall. Ground pivots and tile footprints are preserved.

The cocoa kiosk and Glassblower's stall ground shadows also come from the open-flue models. Rebuild those two shadow layers with `python3 tools/buildings.py christmas-market cocoa glassblower --blender --shadows`.

The layout records the painted crop and opening in each sprite's pixel coordinates. Run the following after importing the original building paintings.

```sh
python3 games/christmas-market/tools/prepare_chimneys.py
python3 tools/buildings.py christmas-market --finish
python3 games/christmas-market/tools/check_assets.py --update
```

Placed buildings emit smoke from their flues as the player pans, zooms and confirms placement. Cards and placement previews show the open chimney artwork. Reduce Motion suppresses the particles. [Edit guide](../art/building-catalogue/chimneys/guide.png) · [Painted source](../art/building-catalogue/chimneys/output.png) · [Exact prompt](../art/building-catalogue/chimneys/prompt.txt) · [Layout](../art/building-catalogue/chimneys/layout.json) · [In-game review](review/chimneys/README.md)

## Style and prompt provenance

See the [shared building style guide](../../../docs/BUILDING_STYLE.md) for the
accepted palette, materials, polish and review criteria, and the
[reference index](../art/building-catalogue/painted-v1/references.json) for exact
prompts, ordered input images, hashes and accepted versions.

## Enlarged painted sprites

The enlarged objects `snowy_bench`, `fir_snowy`, `birch`, `fir_decorated`, `pine_grove` use the `z-enlarged` painted atlas, based on the registered Blender renders at `ef26de3`. Normal world state only; interaction feedback remains an engine effect. Sources, exact ImageGen prompt, layout, import transforms and reproduction command are recorded in [painted-v1](../art/building-catalogue/painted-v1/README.md); [in-game footprint review](review/painted-buildings/enlarged/README.md).
