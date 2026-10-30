# Buildings and decorations

Relic Rush has **96 registered sprites**: ten unique story restorations and 86
repeatable buildings and decorations. Open **BUILD SHOP** on the island. Browse
categories with the arrows and pages with Prev/Next. Each measured row shows its
sprite, tile footprint, owned count, price and unlock requirement. Choose a
location, move the preview to open grass and confirm. Gold is paid once on
confirmation; cancellation is free. Stars unlock stock and are never spent.
Purchased objects use the same hold-to-move, Confirm/Cancel and save system as
story wonders. There is a 160-object island limit.

Story wonders remain in expedition order, one per completed level. Optional
purchases do not count as restorations, trigger story scenes, or advance the
campaign. Gold needed for earned but unbuilt story wonders is reserved; the shop
explains when it cannot be spent. This is the existing finite offline economy:
no production timers, premium purchases, flower score or upgrade stages are added.

## Source, import and registration

The complete master is `art/building-catalogue/relic_rush_buildings.blend`, copied
from the supplied local Blender study. Its procedural source, catalogue and
layout report are preserved beside it. The six supplied `tile_*.jpg` files are
reference previews with grid/text, not runtime crops.

`tools/render_building_atlas.py` exports a transparent 12 x 8 guide containing
all 96 objects with the original orthographic 30-degree elevation, 45-degree
azimuth and exact 2:1 ground projection. It records a separate projected ground
centre and pixels per tile for every object in `registration.json`.

All 96 objects were initially painted together using the **built-in ImageGen tool**
with `geometry-atlas.png` as edit target, `detail-reference.png` (the supplied
`buildings-paintover`) for detail, and original `art/buildings.png` for style.
The initial prompts are `prompt.txt`, `correction-prompt.txt`, `jaguar-prompt.txt`
and `alpha-prompt.txt`. Each edit retained the entire set in one atlas. Versions
v1 through v4 preserve the generated outputs. `paintover-atlas.png` selects v2,
with only cell 55 (jaguar) copied directly from v4 at [896,512,1024,640]. Its
1536 x 1024 / 128-pixel cells supply the seventy smaller decorations.

The production resolution pass uses two complete category sets: **all ten story
wonders together** in `paintover-wonders.png` (1870 x 841), and **all sixteen
additional buildings together** in `paintover-buildings.png` (1254 x 1254). The
wonder prompts are `wonders-prompt.txt`, `wonders-spacing-prompt.txt` and
`wonders-gutters-prompt.txt`; source versions v1/v2 record the spacing corrections.
The sixteen-building edit uses `geometry-atlas-buildings.png` (1536 x 1536), the
same style references, and `buildings-prompt.txt`. These larger sprites preserve
masonry, carving, foliage and wares when the map zooms in. No icon was generated
separately. Every group has one authored normal/restored presentation.

`tools/prepare_buildings.py` uses explicit authored boxes in `sheets.json` for
the larger atlases, with the existing largest-component isolation to remove a
neighboring roof or leaf fragment when bounding boxes overlap. Its threshold
identifies the component; retained pixels keep their original RGB and alpha,
including the soft edge. It does not quantize or recolour retained artwork.
The small-decoration atlas uses fixed 128-pixel cells with transparent-margin
cropping. Outputs are `data/buildings/0.png` through `9.png` for stable story IDs,
plus named PNGs for the 86 purchasable items. The importer emits
`lua/buildings.lua` and `art/building-catalogue/manifest.json`, with per-object
source, selection/crop boxes, prices, unlocks and measurements. No script draws
details, manufactures interaction states or recolours artwork.

For the 26 slab-based buildings, `measurements.json` records the actual painted
front/left/right corners measured with `tools/footprint.py`; these override the
Blender guide's pivots/base widths after painting. Unbased decorations use the
projected virtual tile footprint and ground origin from Blender: trees, benches
and small props occupy whole tiles even when their visible ground contact is
smaller than one tile. A virtual base width can exceed the sprite width. The
tile stays `size2(40,20)` and clearance stays `size2(1,1)`.

## Supported presentation and interactions

Every object has one authored, finished normal/restored sprite. It has no damaged,
construction or upgrade state. Map tap opens details; a stationary 0.5-second
hold lifts it. Ordinary drag pans. The engine's existing **transient** placement
preview uses alpha, lift animation, a valid/invalid grid and its invalid-location
red overlay; these remain placement feedback, not additional authored sprite
states. Catalogue item images always use the normal sprite without tinting;
locked/unaffordable status is expressed by labels and the existing form button
skin. Buildings have no separate hover, pressed or disabled world artwork.

## Reproduce and verify

```sh
/Applications/Blender.app/Contents/MacOS/Blender -b games/relic-rush/art/building-catalogue/relic_rush_buildings.blend --python games/relic-rush/tools/render_building_atlas.py
/Applications/Blender.app/Contents/MacOS/Blender -b games/relic-rush/art/building-catalogue/relic_rush_buildings.blend --python games/relic-rush/tools/render_building_atlas.py -- buildings
python3 games/relic-rush/tools/prepare_buildings.py
python3 tools/footprint.py games/relic-rush/data/buildings/0.png --overlay /tmp/camp.png
make CFLAGS="-O2 -g -Werror"
make test
./build/relic-rush --headless --mute --fresh --catalogue --shot /tmp/shop.png
./build/relic-rush --headless --mute --fresh --catalogue all --catalogue-page 24 --shot /tmp/shop-last.png
./build/relic-rush --headless --mute --fresh --building-review 24 --footprints --shot /tmp/footprints-last.png
./build/relic-rush --headless --mute --fresh --smoke
```

On Linux, run renderer captures and smoke under Xvfb with
`LIBGL_ALWAYS_SOFTWARE=1`; the reviewed captures here use the installed native
macOS renderer. Review pages 1 through 24 cover all 96 sprites in both catalogue
rows and actual city footprints. The [review gallery](review/building-catalogue/README.md)
also includes normal/blocked placement, details and 480 x 900 / 390 x 844 layouts.
Generated masters and editable sources are preserved in the repository; no new
models, dependency environments or cloud-only intermediates are required.

## Runtime inventory

All entries support the presentation/interaction contract above. `manifest.json`
records exact crops, source, costs, requirements and registration. Category and
Star unlocks come from the supplied study catalogue; its June's Journey names
are design references only. The runtime art is original generated artwork.

| ID / key | Name | Category | Tiles | Pivot px | Base px | Gold | Stars | Reviewed city capture |
| --- | --- | --- | --- | --- | ---: | ---: | ---: | --- |
| 0 / `camp` | Expedition camp | wonder | 2 x 2 | 120, 146.5 | 234 | 60 | 0 | [Page 1](review/building-catalogue/footprints-01.jpg) |
| 1 / `well` | Spring well | wonder | 2 x 2 | 119.5, 166.75 | 233 | 80 | 0 | [Page 1](review/building-catalogue/footprints-01.jpg) |
| 2 / `workshop` | Artisan workshop | wonder | 3 x 2 | 145, 192.5 | 278 | 100 | 0 | [Page 1](review/building-catalogue/footprints-01.jpg) |
| 3 / `market` | Jungle market | wonder | 3 x 2 | 133, 174.5 | 258 | 120 | 0 | [Page 1](review/building-catalogue/footprints-01.jpg) |
| 4 / `gateway` | Sunstone gateway | wonder | 4 x 2 | 168, 169 | 328 | 140 | 0 | [Page 2](review/building-catalogue/footprints-02.jpg) |
| 5 / `lodge` | Explorer's lodge | wonder | 3 x 3 | 149, 211.5 | 290 | 160 | 0 | [Page 2](review/building-catalogue/footprints-02.jpg) |
| 6 / `archive` | Lost-world archive | wonder | 3 x 3 | 152, 189 | 296 | 180 | 0 | [Page 2](review/building-catalogue/footprints-02.jpg) |
| 7 / `observatory` | Star observatory | wonder | 2 x 2 | 101.5, 201.75 | 197 | 200 | 0 | [Page 2](review/building-catalogue/footprints-02.jpg) |
| 8 / `fountain` | Jade fountain | wonder | 3 x 3 | 136.5, 176.25 | 267 | 220 | 0 | [Page 3](review/building-catalogue/footprints-03.jpg) |
| 9 / `temple` | Temple of the sun | wonder | 4 x 4 | 170.5, 187.75 | 333 | 250 | 0 | [Page 3](review/building-catalogue/footprints-03.jpg) |
| 10 / `log_cabin` | Trapper's cabin | building | 2 x 2 | 147, 217 | 288 | 200 | 6 | [Page 3](review/building-catalogue/footprints-03.jpg) |
| 11 / `apothecary` | Herbalist's hut | building | 2 x 2 | 146.5, 207.75 | 285 | 220 | 6 | [Page 3](review/building-catalogue/footprints-03.jpg) |
| 12 / `mess_hall` | Mess hall | building | 3 x 2 | 158, 219 | 308 | 240 | 9 | [Page 4](review/building-catalogue/footprints-04.jpg) |
| 13 / `stilt_house` | Stilt house | building | 3 x 2 | 152.5, 221.75 | 297 | 260 | 9 | [Page 4](review/building-catalogue/footprints-04.jpg) |
| 14 / `map_room` | Cartographer's house | building | 3 x 2 | 150, 225 | 292 | 280 | 12 | [Page 4](review/building-catalogue/footprints-04.jpg) |
| 15 / `greenhouse` | Glass greenhouse | building | 3 x 2 | 157, 195.5 | 306 | 300 | 12 | [Page 4](review/building-catalogue/footprints-04.jpg) |
| 16 / `trading_post` | Trading post | building | 3 x 3 | 156, 214.5 | 306 | 320 | 15 | [Page 5](review/building-catalogue/footprints-05.jpg) |
| 17 / `water_mill` | Water mill | building | 3 x 3 | 152.5, 207.75 | 297 | 340 | 15 | [Page 5](review/building-catalogue/footprints-05.jpg) |
| 18 / `clock_tower` | Clock tower | building | 2 x 2 | 115, 285 | 224 | 360 | 18 | [Page 5](review/building-catalogue/footprints-05.jpg) |
| 19 / `lighthouse` | Valley lighthouse | building | 2 x 2 | 119.5, 279.75 | 233 | 380 | 18 | [Page 5](review/building-catalogue/footprints-05.jpg) |
| 20 / `treehouse` | Canopy treehouse | building | 3 x 3 | 161.5, 268.75 | 285 | 400 | 21 | [Page 6](review/building-catalogue/footprints-06.jpg) |
| 21 / `aviary` | Great aviary | building | 3 x 3 | 151.5, 229.25 | 295 | 420 | 21 | [Page 6](review/building-catalogue/footprints-06.jpg) |
| 22 / `beached_ship` | Beached schooner | building | 4 x 2 | 151.5, 200.25 | 295 | 440 | 24 | [Page 6](review/building-catalogue/footprints-06.jpg) |
| 23 / `amphitheater` | Stone amphitheatre | building | 4 x 3 | 153, 130 | 300 | 460 | 24 | [Page 6](review/building-catalogue/footprints-06.jpg) |
| 24 / `museum` | Relic museum | building | 4 x 3 | 154, 183 | 300 | 500 | 27 | [Page 7](review/building-catalogue/footprints-07.jpg) |
| 25 / `hanging_gardens` | Hanging gardens | building | 4 x 4 | 162, 202.5 | 290 | 550 | 30 | [Page 7](review/building-catalogue/footprints-07.jpg) |
| 26 / `palm_young` | Young palm | tree | 1 x 1 | 64.234, 113.733 | 194.92 | 30 | 0 | [Page 7](review/building-catalogue/footprints-07.jpg) |
| 27 / `jungle_tree` | Round jungle tree | tree | 1 x 1 | 50.067, 114.752 | 150.278 | 30 | 0 | [Page 7](review/building-catalogue/footprints-07.jpg) |
| 28 / `cypress` | Temple cypress | tree | 1 x 1 | 51, 116.367 | 130.064 | 45 | 3 | [Page 8](review/building-catalogue/footprints-08.jpg) |
| 29 / `banana` | Banana plant | tree | 1 x 1 | 58.631, 86.582 | 178.977 | 45 | 3 | [Page 8](review/building-catalogue/footprints-08.jpg) |
| 30 / `fan_palm` | Fan palm | tree | 1 x 1 | 63.136, 81.93 | 175.489 | 45 | 6 | [Page 8](review/building-catalogue/footprints-08.jpg) |
| 31 / `papaya` | Papaya tree | tree | 1 x 1 | 63.379, 115.668 | 177.218 | 60 | 9 | [Page 8](review/building-catalogue/footprints-08.jpg) |
| 32 / `frangipani` | Frangipani | tree | 1 x 1 | 56.395, 115.502 | 161.012 | 75 | 12 | [Page 9](review/building-catalogue/footprints-09.jpg) |
| 33 / `bamboo` | Bamboo grove | tree | 2 x 2 | 66.818, 101.685 | 163.101 | 120 | 6 | [Page 9](review/building-catalogue/footprints-09.jpg) |
| 34 / `twin_palms` | Twin palms | tree | 2 x 2 | 51.254, 103.363 | 185.966 | 150 | 6 | [Page 9](review/building-catalogue/footprints-09.jpg) |
| 35 / `mango` | Mango tree | tree | 2 x 2 | 65.839, 113.221 | 192.966 | 180 | 9 | [Page 9](review/building-catalogue/footprints-09.jpg) |
| 36 / `kapok` | Giant kapok | tree | 2 x 2 | 63.632, 107.163 | 117.121 | 300 | 18 | [Page 10](review/building-catalogue/footprints-10.jpg) |
| 37 / `shrub` | Round shrub | bush | 1 x 1 | 59.735, 97.123 | 217.299 | 15 | 0 | [Page 10](review/building-catalogue/footprints-10.jpg) |
| 38 / `fern` | Forest fern | bush | 1 x 1 | 63.136, 64.348 | 192.202 | 15 | 0 | [Page 10](review/building-catalogue/footprints-10.jpg) |
| 39 / `monstera` | Big-leaf monstera | bush | 1 x 1 | 62.56, 74.826 | 194.635 | 30 | 3 | [Page 10](review/building-catalogue/footprints-10.jpg) |
| 40 / `flower_shrub` | Flowering shrub | bush | 1 x 1 | 63.975, 98.781 | 196.062 | 30 | 3 | [Page 11](review/building-catalogue/footprints-11.jpg) |
| 41 / `berry` | Berry bush | bush | 1 x 1 | 61.129, 95.979 | 208.783 | 30 | 6 | [Page 11](review/building-catalogue/footprints-11.jpg) |
| 42 / `reeds` | Riverside reeds | bush | 1 x 1 | 63.941, 106.646 | 137.146 | 30 | 6 | [Page 11](review/building-catalogue/footprints-11.jpg) |
| 43 / `topiary` | Topiary ball | bush | 1 x 1 | 64, 112.114 | 171.579 | 45 | 9 | [Page 11](review/building-catalogue/footprints-11.jpg) |
| 44 / `hedge` | Clipped hedge block | bush | 1 x 1 | 63, 86.33 | 130.232 | 30 | 9 | [Page 12](review/building-catalogue/footprints-12.jpg) |
| 45 / `orchid` | Wild orchids | flower | 1 x 1 | 64.566, 90.648 | 215.795 | 15 | 0 | [Page 12](review/building-catalogue/footprints-12.jpg) |
| 46 / `hibiscus` | Red hibiscus | flower | 1 x 1 | 74.249, 89.709 | 225.913 | 15 | 0 | [Page 12](review/building-catalogue/footprints-12.jpg) |
| 47 / `daisies` | Sunny daisies | flower | 1 x 1 | 65.546, 84.599 | 227.333 | 15 | 3 | [Page 12](review/building-catalogue/footprints-12.jpg) |
| 48 / `blue_lily` | Blue lilies | flower | 1 x 1 | 62.122, 98.491 | 187.833 | 30 | 6 | [Page 13](review/building-catalogue/footprints-13.jpg) |
| 49 / `flower_box` | Flower planter | flower | 1 x 1 | 64, 79.111 | 186.668 | 30 | 6 | [Page 13](review/building-catalogue/footprints-13.jpg) |
| 50 / `bromeliad` | Blooming bromeliad | flower | 1 x 1 | 64, 71.91 | 222.733 | 30 | 9 | [Page 13](review/building-catalogue/footprints-13.jpg) |
| 51 / `flower_bed` | Flower bed | flower | 2 x 2 | 64, 41.771 | 113.131 | 90 | 6 | [Page 13](review/building-catalogue/footprints-13.jpg) |
| 52 / `rainbow_bed` | Rainbow garden | flower | 2 x 2 | 64, 68.575 | 164.992 | 180 | 15 | [Page 14](review/building-catalogue/footprints-14.jpg) |
| 53 / `broken_column` | Broken column | statue | 1 x 1 | 64, 94.952 | 159.63 | 30 | 3 | [Page 14](review/building-catalogue/footprints-14.jpg) |
| 54 / `idol_head` | Stone idol | statue | 1 x 1 | 55, 97.34 | 137.336 | 45 | 3 | [Page 14](review/building-catalogue/footprints-14.jpg) |
| 55 / `jaguar` | Jaguar guardian | statue | 1 x 1 | 64, 84.099 | 151.352 | 60 | 6 | [Page 14](review/building-catalogue/footprints-14.jpg) |
| 56 / `obelisk` | Sun obelisk | statue | 1 x 1 | 64, 103.913 | 107.247 | 60 | 9 | [Page 15](review/building-catalogue/footprints-15.jpg) |
| 57 / `sundial` | Sundial | statue | 1 x 1 | 51, 104.243 | 188.014 | 60 | 9 | [Page 15](review/building-catalogue/footprints-15.jpg) |
| 58 / `explorer` | Explorer statue | statue | 1 x 1 | 49, 99.863 | 125.853 | 90 | 12 | [Page 15](review/building-catalogue/footprints-15.jpg) |
| 59 / `gold_idol` | Golden idol | statue | 1 x 1 | 51, 97.31 | 137.515 | 150 | 18 | [Page 15](review/building-catalogue/footprints-15.jpg) |
| 60 / `stone_arch` | Ruined arch | statue | 2 x 2 | 62.757, 90.452 | 131.062 | 180 | 12 | [Page 16](review/building-catalogue/footprints-16.jpg) |
| 61 / `giant_head` | Giant stone head | statue | 2 x 2 | 78.134, 86.91 | 155.404 | 240 | 15 | [Page 16](review/building-catalogue/footprints-16.jpg) |
| 62 / `birdbath` | Birdbath | water | 1 x 1 | 64, 104.393 | 186.22 | 45 | 3 | [Page 16](review/building-catalogue/footprints-16.jpg) |
| 63 / `small_fountain` | Little fountain | water | 1 x 1 | 64, 94.686 | 170.471 | 90 | 9 | [Page 16](review/building-catalogue/footprints-16.jpg) |
| 64 / `lily_pond` | Lily pond | water | 2 x 2 | 58.769, 41.971 | 144.086 | 120 | 6 | [Page 17](review/building-catalogue/footprints-17.jpg) |
| 65 / `duck_pond` | Duck pond | water | 2 x 2 | 64, 76.963 | 172.165 | 150 | 9 | [Page 17](review/building-catalogue/footprints-17.jpg) |
| 66 / `spring_rocks` | Rock spring | water | 2 x 2 | 54.96, 80.218 | 154.625 | 240 | 15 | [Page 17](review/building-catalogue/footprints-17.jpg) |
| 67 / `bench` | Garden bench | garden | 1 x 1 | 62.296, 97.849 | 170.395 | 30 | 0 | [Page 17](review/building-catalogue/footprints-17.jpg) |
| 68 / `lantern` | Lantern post | garden | 1 x 1 | 64, 113.018 | 157.274 | 30 | 0 | [Page 18](review/building-catalogue/footprints-18.jpg) |
| 69 / `tiki` | Tiki torch | garden | 1 x 1 | 33, 117.013 | 171.079 | 30 | 3 | [Page 18](review/building-catalogue/footprints-18.jpg) |
| 70 / `signpost` | Signpost | garden | 1 x 1 | 42.161, 115.804 | 167.836 | 30 | 3 | [Page 18](review/building-catalogue/footprints-18.jpg) |
| 71 / `flagpole` | Expedition flag | garden | 1 x 1 | 35.069, 110.835 | 107.825 | 45 | 6 | [Page 18](review/building-catalogue/footprints-18.jpg) |
| 72 / `pump` | Water pump | garden | 1 x 1 | 63.426, 98.704 | 185.179 | 45 | 9 | [Page 19](review/building-catalogue/footprints-19.jpg) |
| 73 / `picnic` | Picnic rug | garden | 2 x 2 | 57.403, 64.42 | 137.229 | 120 | 6 | [Page 19](review/building-catalogue/footprints-19.jpg) |
| 74 / `hammock` | Palm hammock | garden | 2 x 2 | 61.917, 99.388 | 186.75 | 150 | 6 | [Page 19](review/building-catalogue/footprints-19.jpg) |
| 75 / `pergola` | Vine pergola | garden | 2 x 2 | 64, 91.747 | 129.48 | 180 | 9 | [Page 19](review/building-catalogue/footprints-19.jpg) |
| 76 / `swing` | Garden swing | garden | 2 x 2 | 64, 88.156 | 152.07 | 240 | 12 | [Page 20](review/building-catalogue/footprints-20.jpg) |
| 77 / `gazebo` | Jade gazebo | garden | 2 x 2 | 64, 97.734 | 136.911 | 300 | 12 | [Page 20](review/building-catalogue/footprints-20.jpg) |
| 78 / `crates` | Supply crates | camp | 1 x 1 | 61.44, 96.973 | 146.904 | 15 | 0 | [Page 20](review/building-catalogue/footprints-20.jpg) |
| 79 / `barrels` | Barrels | camp | 1 x 1 | 69.017, 87.524 | 200.684 | 15 | 0 | [Page 20](review/building-catalogue/footprints-20.jpg) |
| 80 / `campfire` | Campfire | camp | 1 x 1 | 64.278, 76.607 | 181.937 | 30 | 0 | [Page 21](review/building-catalogue/footprints-21.jpg) |
| 81 / `field_scope` | Field telescope | camp | 1 x 1 | 59.645, 106.804 | 160.355 | 60 | 9 | [Page 21](review/building-catalogue/footprints-21.jpg) |
| 82 / `globe` | Explorer's globe | camp | 1 x 1 | 53, 104.088 | 173.099 | 90 | 15 | [Page 21](review/building-catalogue/footprints-21.jpg) |
| 83 / `chest` | Treasure chest | camp | 1 x 1 | 75.164, 80.224 | 151.987 | 120 | 15 | [Page 21](review/building-catalogue/footprints-21.jpg) |
| 84 / `supply_tent` | Supply tent | camp | 2 x 2 | 70.499, 77.507 | 141.433 | 120 | 3 | [Page 22](review/building-catalogue/footprints-22.jpg) |
| 85 / `dig_site` | Dig site | camp | 2 x 2 | 64, 57.914 | 143.59 | 120 | 6 | [Page 22](review/building-catalogue/footprints-22.jpg) |
| 86 / `rowboat` | Rowboat | camp | 2 x 2 | 47.563, 60.143 | 164.506 | 150 | 9 | [Page 22](review/building-catalogue/footprints-22.jpg) |
| 87 / `cart` | Market cart | camp | 2 x 2 | 64, 89.13 | 200 | 180 | 9 | [Page 22](review/building-catalogue/footprints-22.jpg) |
| 88 / `turtle` | Sunning turtle | animal | 1 x 1 | 55.6, 82.992 | 221.94 | 60 | 6 | [Page 23](review/building-catalogue/footprints-23.jpg) |
| 89 / `toucan` | Toucan perch | animal | 1 x 1 | 65.598, 108.307 | 155.909 | 60 | 6 | [Page 23](review/building-catalogue/footprints-23.jpg) |
| 90 / `parrot` | Parrot perch | animal | 1 x 1 | 35, 108.503 | 153.295 | 60 | 9 | [Page 23](review/building-catalogue/footprints-23.jpg) |
| 91 / `monkey` | Curious monkey | animal | 1 x 1 | 58.448, 108.987 | 196.697 | 90 | 12 | [Page 23](review/building-catalogue/footprints-23.jpg) |
| 92 / `capybara` | Capybara | animal | 1 x 1 | 66.45, 82.073 | 248.928 | 90 | 12 | [Page 24](review/building-catalogue/footprints-24.jpg) |
| 93 / `boulder` | Boulder | rock | 1 x 1 | 60.825, 89.135 | 213.945 | 15 | 0 | [Page 24](review/building-catalogue/footprints-24.jpg) |
| 94 / `crystal` | Crystal cluster | rock | 1 x 1 | 59.39, 110.386 | 194.288 | 120 | 18 | [Page 24](review/building-catalogue/footprints-24.jpg) |
| 95 / `mossy_rocks` | Mossy boulders | rock | 2 x 2 | 66.564, 77.312 | 183.684 | 60 | 3 | [Page 24](review/building-catalogue/footprints-24.jpg) |
