# Buildings and decorations

Relic Rush has **96 registered sprites**: twenty campaign restorations (ten
story wonders and ten ladder buildings, each placed once) and 76 repeatable
buildings and decorations. Open **SHOP** on the island. Browse
categories with the arrows and pages with Prev/Next. Each measured row shows its
sprite, tile footprint, owned count, price and unlock requirement. Choose a
location, move the preview to open grass and confirm. Confirmation spends the listed resources once. Cancellation is free. Stars
unlock stock and remain in the wallet.
Purchased objects use the same hold-to-move, Confirm/Cancel and save system as
story wonders. There is a 160-object island limit.

The twenty restorations follow the [campaign ladder](resource-expedition.md#restoration-prices-and-earnings):
the ten wonders unlock at the story milestones and the other ten between them.
The Trapper's cabin, Cartographer's house, Trading post, Water mill, Clock
tower, Valley lighthouse, Great aviary, Beached schooner, Stone amphitheatre
and Relic museum were shop buildings; they are now campaign rows with no star
requirement. Optional purchases can use
the Coins, Food and Supplies left after reserving the cost of unlocked
restorations. The shop shows prices and marks an item unavailable when buying
it would spend reserved funds. Replays bank resources from matches and the
move bonus. See the [expedition economy](resource-expedition.md).


## Source and rendering

The master is `art/building-catalogue/relic_rush_buildings.blend`, built from
`art/building-catalogue/build_scene.py` and the shared `tools/building_kit.py`. Every
object is one Blender collection named after its key. All sprites are rendered from
it by the shared pipeline with the [city camera](../../../docs/BUILDINGS.md#the-camera):

```sh
make buildings GAME=relic-rush                  # all 96
make buildings GAME=relic-rush KEYS="lodge"     # one
make buildings GAME=relic-rush REBUILD=1        # after editing build_scene.py
```

Outputs are `data/buildings/<key>.png` and `data/building-shadows/<key>.png` at 100
pixels per tile side, the registry `art/building-catalogue/registration.json`,
`lua/building_sprites.lua`, and the [review sheet](screenshots/buildings.jpg).
`tools/prepare_buildings.py` then writes `lua/buildings.lua`, merging prices and
stories from `catalogue.json` and `story.json` by key, plus `manifest.json` and the
runtime inventory.

Story ID 4 is the **Sunstone courtyard**, modelled in `build_scene.py` after the
accepted design in `landmark-alternatives/source.png`: a dry plaza with a mosaic sun,
two lantern steles, curved benches and planters. The legacy key `gateway` and numeric
ID 4 stay stable for saves and story order. Restoration costs 22 Food and 26 Supplies.

### Painted current-camera sprites

All 96 sprites now have a category ImageGen paint-over on the current Blender
renders. The earlier `paintover-*.png` and `detail-reference.png` supplied the
painted masonry, carved teal/gold ornament, roof tiles, cloth, foliage and warm
lighting direction. The Sunstone courtyard keeps its current sun-mosaic design.

`art/building-catalogue/painted-v1/` retains every input atlas, generated output,
prompt, cell layout, original render registration and `imports.json` mapping each
runtime key to its source and crop/scale/translation. `hedge` overrides the final
`bush` cell: the first pass mistakenly painted it as a stone block. The first
wonder pass is retained in `versions/first/`; the accepted atlas gives the temple
more gutter space. No colour filters, procedural detail or replacement alpha masks
are used. Sources remain locked to the current camera.

Reproduce with `python3 tools/import_painted_buildings.py relic-rush`. See the
[before/after and complete footprint review](review/painted-buildings/current-camera/README.md).
This completes the building paint pass tracked in [#41](https://github.com/corepunch/nile-archive/issues/41).

## Separate ground shadows

All 96 entries have a registered low-resolution shadow PNG under
`data/building-shadows/`, rendered per building with the sprites from the same
geometry, sun and fill: camera-invisible casters on a transparent Cycles catcher,
direct light only. Crops use alpha >= 24 support plus a three-pixel feather margin
to exclude ray-sampling speckles; retained RGB/alpha stays unchanged. Generated Lua
fields `shadow_path`, `shadow_pivot` and `shadow_base_width` register to the same
world ground centre independently of the sprite's resolution. All shadows are drawn
below all building sprites. Held previews keep the shadow grounded.

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
make buildings GAME=relic-rush
make CFLAGS="-O2 -g -Werror"
make test
./build/relic-rush --headless --mute --fresh --catalogue --shot /tmp/shop.png
./build/relic-rush --headless --mute --fresh --catalogue all --catalogue-page 32 --shot /tmp/shop-last.png
./build/relic-rush --headless --mute --fresh --building-review 24 --footprints --shot /tmp/footprints-last.png
./build/relic-rush --headless --mute --fresh --smoke
```

On Linux, run renderer captures and smoke under Xvfb with
`LIBGL_ALWAYS_SOFTWARE=1`; the reviewed captures here use the installed native
macOS renderer. The shop fits all 96 sprites in 32 rows of three. The footprint
review fits them in 24 pages of four. The [review gallery](review/building-catalogue/README.md)
also includes normal/blocked placement, details and 480 x 900 / 390 x 844 layouts.
Generated masters and editable sources are preserved in the repository; rendering
needs only Blender.

## Runtime inventory

All entries support the presentation/interaction contract above. `manifest.json`
records sources, costs, requirements and registration; `art/building-catalogue/registration.json`
holds each sprite's pivot and base width. Category and Star unlocks come from the
supplied study catalogue; its June's Journey names are design references only. The
sprite file is always `data/buildings/<key>.png`.

| ID / key | Name | Category | Tiles | Price | Stars | Reviewed city capture |
| --- | --- | --- | --- | --- | ---: | --- |
| 0 / `camp` | Expedition camp | wonder | 2 x 2 | 3 Food + 8 Supplies | 0 | [Page 1](review/painted-buildings/current-camera/after-building-review-1.jpg) |
| 1 / `well` | Spring well | wonder | 2 x 2 | 100 Coins | 0 | [Page 1](review/painted-buildings/current-camera/after-building-review-1.jpg) |
| 2 / `workshop` | Artisan workshop | wonder | 3 x 2 | 70 Coins + 20 Food + 24 Supplies | 0 | [Page 1](review/painted-buildings/current-camera/after-building-review-1.jpg) |
| 3 / `market` | Jungle market | wonder | 3 x 2 | 85 Coins + 24 Food + 30 Supplies | 0 | [Page 1](review/painted-buildings/current-camera/after-building-review-1.jpg) |
| 4 / `gateway` | Sunstone courtyard | wonder | 3 x 2 | 85 Coins + 34 Food + 36 Supplies | 0 | [Page 2](review/painted-buildings/current-camera/after-building-review-2.jpg) |
| 5 / `lodge` | Explorer's lodge | wonder | 3 x 3 | 130 Coins + 35 Food | 0 | [Page 2](review/painted-buildings/current-camera/after-building-review-2.jpg) |
| 6 / `archive` | Lost-world archive | wonder | 3 x 3 | 145 Coins + 85 Food + 40 Supplies | 0 | [Page 2](review/painted-buildings/current-camera/after-building-review-2.jpg) |
| 7 / `observatory` | Star observatory | wonder | 2 x 2 | 155 Coins + 70 Supplies | 0 | [Page 2](review/painted-buildings/current-camera/after-building-review-2.jpg) |
| 8 / `fountain` | Jade fountain | wonder | 3 x 3 | 160 Coins + 65 Supplies | 0 | [Page 3](review/painted-buildings/current-camera/after-building-review-3.jpg) |
| 9 / `temple` | Temple of the sun | wonder | 4 x 4 | 185 Coins + 110 Food + 75 Supplies | 0 | [Page 3](review/painted-buildings/current-camera/after-building-review-3.jpg) |
| 10 / `log_cabin` | Trapper's cabin | wonder | 2 x 2 | 40 Coins + 12 Supplies + 10 Food | 0 | [Page 3](review/painted-buildings/current-camera/after-building-review-3.jpg) |
| 11 / `apothecary` | Herbalist's hut | building | 2 x 2 | 220 Coins + 15 Food | 6 | [Page 3](review/painted-buildings/current-camera/after-building-review-3.jpg) |
| 12 / `mess_hall` | Mess hall | building | 3 x 2 | 240 Coins + 16 Supplies | 9 | [Page 4](review/painted-buildings/current-camera/after-building-review-4.jpg) |
| 13 / `stilt_house` | Stilt house | building | 3 x 2 | 260 Coins + 17 Supplies | 9 | [Page 4](review/painted-buildings/current-camera/after-building-review-4.jpg) |
| 14 / `map_room` | Cartographer's house | wonder | 3 x 2 | 140 Coins + 40 Supplies + 50 Food | 0 | [Page 4](review/painted-buildings/current-camera/after-building-review-4.jpg) |
| 15 / `greenhouse` | Glass greenhouse | building | 3 x 2 | 300 Coins + 20 Food | 12 | [Page 4](review/painted-buildings/current-camera/after-building-review-4.jpg) |
| 16 / `trading_post` | Trading post | wonder | 3 x 3 | 90 Coins + 20 Supplies + 45 Food | 0 | [Page 5](review/painted-buildings/current-camera/after-building-review-5.jpg) |
| 17 / `water_mill` | Water mill | wonder | 3 x 3 | 45 Coins + 15 Supplies + 12 Food | 0 | [Page 5](review/painted-buildings/current-camera/after-building-review-5.jpg) |
| 18 / `clock_tower` | Clock tower | wonder | 2 x 2 | 80 Coins + 25 Supplies + 30 Food | 0 | [Page 5](review/painted-buildings/current-camera/after-building-review-5.jpg) |
| 19 / `lighthouse` | Valley lighthouse | wonder | 2 x 2 | 75 Coins + 20 Supplies + 40 Food | 0 | [Page 5](review/painted-buildings/current-camera/after-building-review-5.jpg) |
| 20 / `treehouse` | Canopy treehouse | building | 3 x 3 | 400 Coins + 27 Supplies | 21 | [Page 6](review/painted-buildings/current-camera/after-building-review-6.jpg) |
| 21 / `aviary` | Great aviary | wonder | 3 x 3 | 160 Coins + 60 Supplies + 40 Food | 0 | [Page 6](review/painted-buildings/current-camera/after-building-review-6.jpg) |
| 22 / `beached_ship` | Beached schooner | wonder | 4 x 2 | 120 Coins + 70 Supplies + 30 Food | 0 | [Page 6](review/painted-buildings/current-camera/after-building-review-6.jpg) |
| 23 / `amphitheater` | Stone amphitheatre | wonder | 4 x 3 | 50 Coins + 18 Supplies + 18 Food | 0 | [Page 6](review/painted-buildings/current-camera/after-building-review-6.jpg) |
| 24 / `museum` | Relic museum | wonder | 4 x 3 | 170 Coins + 50 Supplies + 90 Food | 0 | [Page 7](review/painted-buildings/current-camera/after-building-review-7.jpg) |
| 25 / `hanging_gardens` | Hanging gardens | building | 4 x 4 | 550 Coins + 37 Food | 30 | [Page 7](review/painted-buildings/current-camera/after-building-review-7.jpg) |
| 26 / `palm_young` | Young palm | tree | 1 x 1 | 30 Coins | 0 | [Page 7](review/painted-buildings/current-camera/after-building-review-7.jpg) |
| 27 / `jungle_tree` | Round jungle tree | tree | 1 x 1 | 30 Coins | 0 | [Page 7](review/painted-buildings/current-camera/after-building-review-7.jpg) |
| 28 / `cypress` | Temple cypress | tree | 1 x 1 | 45 Coins | 3 | [Page 8](review/painted-buildings/current-camera/after-building-review-8.jpg) |
| 29 / `banana` | Banana plant | tree | 1 x 1 | 45 Coins | 3 | [Page 8](review/painted-buildings/current-camera/after-building-review-8.jpg) |
| 30 / `fan_palm` | Fan palm | tree | 1 x 1 | 45 Coins | 6 | [Page 8](review/painted-buildings/current-camera/after-building-review-8.jpg) |
| 31 / `papaya` | Papaya tree | tree | 1 x 1 | 60 Coins | 9 | [Page 8](review/painted-buildings/current-camera/after-building-review-8.jpg) |
| 32 / `frangipani` | Frangipani | tree | 1 x 1 | 75 Coins | 12 | [Page 9](review/painted-buildings/current-camera/after-building-review-9.jpg) |
| 33 / `bamboo` | Bamboo grove | tree | 2 x 2 | 120 Coins | 6 | [Page 9](review/painted-buildings/current-camera/after-building-review-9.jpg) |
| 34 / `twin_palms` | Twin palms | tree | 2 x 2 | 150 Coins | 6 | [Page 9](review/painted-buildings/current-camera/after-building-review-9.jpg) |
| 35 / `mango` | Mango tree | tree | 2 x 2 | 180 Coins | 9 | [Page 9](review/painted-buildings/current-camera/after-building-review-9.jpg) |
| 36 / `kapok` | Giant kapok | tree | 2 x 2 | 300 Coins | 18 | [Page 10](review/painted-buildings/current-camera/after-building-review-10.jpg) |
| 37 / `shrub` | Round shrub | bush | 1 x 1 | 15 Coins | 0 | [Page 10](review/painted-buildings/current-camera/after-building-review-10.jpg) |
| 38 / `fern` | Forest fern | bush | 1 x 1 | 15 Coins | 0 | [Page 10](review/painted-buildings/current-camera/after-building-review-10.jpg) |
| 39 / `monstera` | Big-leaf monstera | bush | 1 x 1 | 30 Coins | 3 | [Page 10](review/painted-buildings/current-camera/after-building-review-10.jpg) |
| 40 / `flower_shrub` | Flowering shrub | bush | 1 x 1 | 30 Coins | 3 | [Page 11](review/painted-buildings/current-camera/after-building-review-11.jpg) |
| 41 / `berry` | Berry bush | bush | 1 x 1 | 30 Coins | 6 | [Page 11](review/painted-buildings/current-camera/after-building-review-11.jpg) |
| 42 / `reeds` | Riverside reeds | bush | 1 x 1 | 30 Coins | 6 | [Page 11](review/painted-buildings/current-camera/after-building-review-11.jpg) |
| 43 / `topiary` | Topiary ball | bush | 1 x 1 | 45 Coins | 9 | [Page 11](review/painted-buildings/current-camera/after-building-review-11.jpg) |
| 44 / `hedge` | Clipped hedge block | bush | 1 x 1 | 30 Coins | 9 | [Page 12](review/painted-buildings/current-camera/after-building-review-12.jpg) |
| 45 / `orchid` | Wild orchids | flower | 1 x 1 | 15 Coins | 0 | [Page 12](review/painted-buildings/current-camera/after-building-review-12.jpg) |
| 46 / `hibiscus` | Red hibiscus | flower | 1 x 1 | 15 Coins | 0 | [Page 12](review/painted-buildings/current-camera/after-building-review-12.jpg) |
| 47 / `daisies` | Sunny daisies | flower | 1 x 1 | 15 Coins | 3 | [Page 12](review/painted-buildings/current-camera/after-building-review-12.jpg) |
| 48 / `blue_lily` | Blue lilies | flower | 1 x 1 | 30 Coins | 6 | [Page 13](review/painted-buildings/current-camera/after-building-review-13.jpg) |
| 49 / `flower_box` | Flower planter | flower | 1 x 1 | 30 Coins | 6 | [Page 13](review/painted-buildings/current-camera/after-building-review-13.jpg) |
| 50 / `bromeliad` | Blooming bromeliad | flower | 1 x 1 | 30 Coins | 9 | [Page 13](review/painted-buildings/current-camera/after-building-review-13.jpg) |
| 51 / `flower_bed` | Flower bed | flower | 2 x 2 | 90 Coins | 6 | [Page 13](review/painted-buildings/current-camera/after-building-review-13.jpg) |
| 52 / `rainbow_bed` | Rainbow garden | flower | 2 x 2 | 180 Coins | 15 | [Page 14](review/painted-buildings/current-camera/after-building-review-14.jpg) |
| 53 / `broken_column` | Broken column | statue | 1 x 1 | 30 Coins | 3 | [Page 14](review/painted-buildings/current-camera/after-building-review-14.jpg) |
| 54 / `idol_head` | Stone idol | statue | 1 x 1 | 45 Coins | 3 | [Page 14](review/painted-buildings/current-camera/after-building-review-14.jpg) |
| 55 / `jaguar` | Jaguar guardian | statue | 1 x 1 | 60 Coins | 6 | [Page 14](review/painted-buildings/current-camera/after-building-review-14.jpg) |
| 56 / `obelisk` | Sun obelisk | statue | 1 x 1 | 60 Coins | 9 | [Page 15](review/painted-buildings/current-camera/after-building-review-15.jpg) |
| 57 / `sundial` | Sundial | statue | 1 x 1 | 60 Coins | 9 | [Page 15](review/painted-buildings/current-camera/after-building-review-15.jpg) |
| 58 / `explorer` | Explorer statue | statue | 1 x 1 | 90 Coins | 12 | [Page 15](review/painted-buildings/current-camera/after-building-review-15.jpg) |
| 59 / `gold_idol` | Golden idol | statue | 1 x 1 | 150 Coins | 18 | [Page 15](review/painted-buildings/current-camera/after-building-review-15.jpg) |
| 60 / `stone_arch` | Ruined arch | statue | 2 x 2 | 180 Coins | 12 | [Page 16](review/painted-buildings/current-camera/after-building-review-16.jpg) |
| 61 / `giant_head` | Giant stone head | statue | 2 x 2 | 240 Coins | 15 | [Page 16](review/painted-buildings/current-camera/after-building-review-16.jpg) |
| 62 / `birdbath` | Birdbath | water | 1 x 1 | 45 Coins | 3 | [Page 16](review/painted-buildings/current-camera/after-building-review-16.jpg) |
| 63 / `small_fountain` | Little fountain | water | 1 x 1 | 90 Coins | 9 | [Page 16](review/painted-buildings/current-camera/after-building-review-16.jpg) |
| 64 / `lily_pond` | Lily pond | water | 2 x 2 | 120 Coins | 6 | [Page 17](review/painted-buildings/current-camera/after-building-review-17.jpg) |
| 65 / `duck_pond` | Duck pond | water | 2 x 2 | 150 Coins | 9 | [Page 17](review/painted-buildings/current-camera/after-building-review-17.jpg) |
| 66 / `spring_rocks` | Rock spring | water | 2 x 2 | 240 Coins | 15 | [Page 17](review/painted-buildings/current-camera/after-building-review-17.jpg) |
| 67 / `bench` | Garden bench | garden | 1 x 1 | 30 Coins | 0 | [Page 17](review/painted-buildings/current-camera/after-building-review-17.jpg) |
| 68 / `lantern` | Lantern post | garden | 1 x 1 | 30 Coins | 0 | [Page 18](review/painted-buildings/current-camera/after-building-review-18.jpg) |
| 69 / `tiki` | Tiki torch | garden | 1 x 1 | 30 Coins | 3 | [Page 18](review/painted-buildings/current-camera/after-building-review-18.jpg) |
| 70 / `signpost` | Signpost | garden | 1 x 1 | 30 Coins | 3 | [Page 18](review/painted-buildings/current-camera/after-building-review-18.jpg) |
| 71 / `flagpole` | Expedition flag | garden | 1 x 1 | 45 Coins | 6 | [Page 18](review/painted-buildings/current-camera/after-building-review-18.jpg) |
| 72 / `pump` | Water pump | garden | 1 x 1 | 45 Coins | 9 | [Page 19](review/painted-buildings/current-camera/after-building-review-19.jpg) |
| 73 / `picnic` | Picnic rug | garden | 2 x 2 | 120 Coins | 6 | [Page 19](review/painted-buildings/current-camera/after-building-review-19.jpg) |
| 74 / `hammock` | Palm hammock | garden | 2 x 2 | 150 Coins | 6 | [Page 19](review/painted-buildings/current-camera/after-building-review-19.jpg) |
| 75 / `pergola` | Vine pergola | garden | 2 x 2 | 180 Coins | 9 | [Page 19](review/painted-buildings/current-camera/after-building-review-19.jpg) |
| 76 / `swing` | Garden swing | garden | 2 x 2 | 240 Coins | 12 | [Page 20](review/painted-buildings/current-camera/after-building-review-20.jpg) |
| 77 / `gazebo` | Jade gazebo | garden | 2 x 2 | 300 Coins | 12 | [Page 20](review/painted-buildings/current-camera/after-building-review-20.jpg) |
| 78 / `crates` | Supply crates | camp | 1 x 1 | 15 Coins | 0 | [Page 20](review/painted-buildings/current-camera/after-building-review-20.jpg) |
| 79 / `barrels` | Barrels | camp | 1 x 1 | 15 Coins | 0 | [Page 20](review/painted-buildings/current-camera/after-building-review-20.jpg) |
| 80 / `campfire` | Campfire | camp | 1 x 1 | 30 Coins | 0 | [Page 21](review/painted-buildings/current-camera/after-building-review-21.jpg) |
| 81 / `field_scope` | Field telescope | camp | 1 x 1 | 60 Coins | 9 | [Page 21](review/painted-buildings/current-camera/after-building-review-21.jpg) |
| 82 / `globe` | Explorer's globe | camp | 1 x 1 | 90 Coins | 15 | [Page 21](review/painted-buildings/current-camera/after-building-review-21.jpg) |
| 83 / `chest` | Treasure chest | camp | 1 x 1 | 120 Coins | 15 | [Page 21](review/painted-buildings/current-camera/after-building-review-21.jpg) |
| 84 / `supply_tent` | Supply tent | camp | 2 x 2 | 120 Coins | 3 | [Page 22](review/painted-buildings/current-camera/after-building-review-22.jpg) |
| 85 / `dig_site` | Dig site | camp | 2 x 2 | 120 Coins | 6 | [Page 22](review/painted-buildings/current-camera/after-building-review-22.jpg) |
| 86 / `rowboat` | Rowboat | camp | 2 x 2 | 150 Coins | 9 | [Page 22](review/painted-buildings/current-camera/after-building-review-22.jpg) |
| 87 / `cart` | Market cart | camp | 2 x 2 | 180 Coins | 9 | [Page 22](review/painted-buildings/current-camera/after-building-review-22.jpg) |
| 88 / `turtle` | Sunning turtle | animal | 1 x 1 | 60 Coins | 6 | [Page 23](review/painted-buildings/current-camera/after-building-review-23.jpg) |
| 89 / `toucan` | Toucan perch | animal | 1 x 1 | 60 Coins | 6 | [Page 23](review/painted-buildings/current-camera/after-building-review-23.jpg) |
| 90 / `parrot` | Parrot perch | animal | 1 x 1 | 60 Coins | 9 | [Page 23](review/painted-buildings/current-camera/after-building-review-23.jpg) |
| 91 / `monkey` | Curious monkey | animal | 1 x 1 | 90 Coins | 12 | [Page 23](review/painted-buildings/current-camera/after-building-review-23.jpg) |
| 92 / `capybara` | Capybara | animal | 1 x 1 | 90 Coins | 12 | [Page 24](review/painted-buildings/current-camera/after-building-review-24.jpg) |
| 93 / `boulder` | Boulder | rock | 1 x 1 | 15 Coins | 0 | [Page 24](review/painted-buildings/current-camera/after-building-review-24.jpg) |
| 94 / `crystal` | Crystal cluster | rock | 1 x 1 | 120 Coins | 18 | [Page 24](review/painted-buildings/current-camera/after-building-review-24.jpg) |
| 95 / `mossy_rocks` | Mossy boulders | rock | 2 x 2 | 60 Coins | 3 | [Page 24](review/painted-buildings/current-camera/after-building-review-24.jpg) |

## Style and prompt provenance

See the [shared building style guide](../../../docs/BUILDING_STYLE.md) for the
accepted palette, materials, polish and review criteria, and the
[reference index](../art/building-catalogue/painted-v1/references.json) for exact
prompts, ordered input images, hashes and accepted versions.

## Enlarged painted sprites

The enlarged objects `bamboo`, `banana`, `cypress`, `fan_palm`, `frangipani`, `jungle_tree`, `kapok`, `mango`, `palm_young`, `papaya`, `twin_palms` use the `z-enlarged` painted atlas, based on the registered Blender renders at `ef26de3`. Normal world state only; interaction feedback remains an engine effect. Sources, exact ImageGen prompt, layout, import transforms and reproduction command are recorded in [painted-v1](../art/building-catalogue/painted-v1/README.md); [in-game footprint review](review/painted-buildings/enlarged/README.md).
