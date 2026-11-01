# Buildings and decorations

Relic Rush has **96 registered sprites**: ten unique story restorations and 86
repeatable buildings and decorations. Open **SHOP** on the island. Browse
categories with the arrows and pages with Prev/Next. Each measured row shows its
sprite, tile footprint, owned count, price and unlock requirement. Choose a
location, move the preview to open grass and confirm. Gold is paid once on
confirmation; cancellation is free. Stars unlock stock and are never spent.
Purchased objects use the same hold-to-move, Confirm/Cancel and save system as
story wonders. There is a 160-object island limit.

Story wonders remain in expedition order, one per completed level. Optional
purchases do not count as restorations, trigger story scenes, or advance the
campaign. Gold needed for earned but unbuilt story wonders is reserved; the shop
shows spendable and reserved Gold separately. Completed expeditions can now be
replayed for 60–100 Gold, keeping every decorative saving goal reachable. First
discoveries leave 80–120 spare Gold after funding their restoration. See the
[economy study](../../../docs/ECONOMY_RESEARCH.md). No production timers, premium
purchases, flower score or upgrade stages are added.

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
ID 4 stay stable for saves and story order. Restoration costs remain 140 gold, 30 wood
and 30 stone.

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
./build/relic-rush --headless --mute --fresh --catalogue all --catalogue-page 24 --shot /tmp/shop-last.png
./build/relic-rush --headless --mute --fresh --building-review 24 --footprints --shot /tmp/footprints-last.png
./build/relic-rush --headless --mute --fresh --smoke
```

On Linux, run renderer captures and smoke under Xvfb with
`LIBGL_ALWAYS_SOFTWARE=1`; the reviewed captures here use the installed native
macOS renderer. Review pages 1 through 24 cover all 96 sprites in both catalogue
rows and actual city footprints. The [review gallery](review/building-catalogue/README.md)
also includes normal/blocked placement, details and 480 x 900 / 390 x 844 layouts.
Generated masters and editable sources are preserved in the repository; rendering
needs only Blender.

## Runtime inventory

All entries support the presentation/interaction contract above. `manifest.json`
records sources, costs, requirements and registration; `art/building-catalogue/registration.json`
holds each sprite's pivot and base width. Category and Star unlocks come from the
supplied study catalogue; its June's Journey names are design references only. The
sprite file is always `data/buildings/<key>.png`.

| ID / key | Name | Category | Tiles | Gold | Stars | Reviewed city capture |
| --- | --- | --- | --- | ---: | ---: | --- |
| 0 / `camp` | Expedition camp | wonder | 2 x 2 | 60 | 0 | [Page 1](review/painted-buildings/current-camera/after-building-review-1.jpg) |
| 1 / `well` | Spring well | wonder | 2 x 2 | 80 | 0 | [Page 1](review/painted-buildings/current-camera/after-building-review-1.jpg) |
| 2 / `workshop` | Artisan workshop | wonder | 3 x 2 | 100 | 0 | [Page 1](review/painted-buildings/current-camera/after-building-review-1.jpg) |
| 3 / `market` | Jungle market | wonder | 3 x 2 | 120 | 0 | [Page 1](review/painted-buildings/current-camera/after-building-review-1.jpg) |
| 4 / `gateway` | Sunstone courtyard | wonder | 3 x 2 | 140 | 0 | [Page 2](review/painted-buildings/current-camera/after-building-review-2.jpg) |
| 5 / `lodge` | Explorer's lodge | wonder | 3 x 3 | 160 | 0 | [Page 2](review/painted-buildings/current-camera/after-building-review-2.jpg) |
| 6 / `archive` | Lost-world archive | wonder | 3 x 3 | 180 | 0 | [Page 2](review/painted-buildings/current-camera/after-building-review-2.jpg) |
| 7 / `observatory` | Star observatory | wonder | 2 x 2 | 200 | 0 | [Page 2](review/painted-buildings/current-camera/after-building-review-2.jpg) |
| 8 / `fountain` | Jade fountain | wonder | 3 x 3 | 220 | 0 | [Page 3](review/painted-buildings/current-camera/after-building-review-3.jpg) |
| 9 / `temple` | Temple of the sun | wonder | 4 x 4 | 250 | 0 | [Page 3](review/painted-buildings/current-camera/after-building-review-3.jpg) |
| 10 / `log_cabin` | Trapper's cabin | building | 2 x 2 | 200 | 6 | [Page 3](review/painted-buildings/current-camera/after-building-review-3.jpg) |
| 11 / `apothecary` | Herbalist's hut | building | 2 x 2 | 220 | 6 | [Page 3](review/painted-buildings/current-camera/after-building-review-3.jpg) |
| 12 / `mess_hall` | Mess hall | building | 3 x 2 | 240 | 9 | [Page 4](review/painted-buildings/current-camera/after-building-review-4.jpg) |
| 13 / `stilt_house` | Stilt house | building | 3 x 2 | 260 | 9 | [Page 4](review/painted-buildings/current-camera/after-building-review-4.jpg) |
| 14 / `map_room` | Cartographer's house | building | 3 x 2 | 280 | 12 | [Page 4](review/painted-buildings/current-camera/after-building-review-4.jpg) |
| 15 / `greenhouse` | Glass greenhouse | building | 3 x 2 | 300 | 12 | [Page 4](review/painted-buildings/current-camera/after-building-review-4.jpg) |
| 16 / `trading_post` | Trading post | building | 3 x 3 | 320 | 15 | [Page 5](review/painted-buildings/current-camera/after-building-review-5.jpg) |
| 17 / `water_mill` | Water mill | building | 3 x 3 | 340 | 15 | [Page 5](review/painted-buildings/current-camera/after-building-review-5.jpg) |
| 18 / `clock_tower` | Clock tower | building | 2 x 2 | 360 | 18 | [Page 5](review/painted-buildings/current-camera/after-building-review-5.jpg) |
| 19 / `lighthouse` | Valley lighthouse | building | 2 x 2 | 380 | 18 | [Page 5](review/painted-buildings/current-camera/after-building-review-5.jpg) |
| 20 / `treehouse` | Canopy treehouse | building | 3 x 3 | 400 | 21 | [Page 6](review/painted-buildings/current-camera/after-building-review-6.jpg) |
| 21 / `aviary` | Great aviary | building | 3 x 3 | 420 | 21 | [Page 6](review/painted-buildings/current-camera/after-building-review-6.jpg) |
| 22 / `beached_ship` | Beached schooner | building | 4 x 2 | 440 | 24 | [Page 6](review/painted-buildings/current-camera/after-building-review-6.jpg) |
| 23 / `amphitheater` | Stone amphitheatre | building | 4 x 3 | 460 | 24 | [Page 6](review/painted-buildings/current-camera/after-building-review-6.jpg) |
| 24 / `museum` | Relic museum | building | 4 x 3 | 500 | 27 | [Page 7](review/painted-buildings/current-camera/after-building-review-7.jpg) |
| 25 / `hanging_gardens` | Hanging gardens | building | 4 x 4 | 550 | 30 | [Page 7](review/painted-buildings/current-camera/after-building-review-7.jpg) |
| 26 / `palm_young` | Young palm | tree | 1 x 1 | 30 | 0 | [Page 7](review/painted-buildings/current-camera/after-building-review-7.jpg) |
| 27 / `jungle_tree` | Round jungle tree | tree | 1 x 1 | 30 | 0 | [Page 7](review/painted-buildings/current-camera/after-building-review-7.jpg) |
| 28 / `cypress` | Temple cypress | tree | 1 x 1 | 45 | 3 | [Page 8](review/painted-buildings/current-camera/after-building-review-8.jpg) |
| 29 / `banana` | Banana plant | tree | 1 x 1 | 45 | 3 | [Page 8](review/painted-buildings/current-camera/after-building-review-8.jpg) |
| 30 / `fan_palm` | Fan palm | tree | 1 x 1 | 45 | 6 | [Page 8](review/painted-buildings/current-camera/after-building-review-8.jpg) |
| 31 / `papaya` | Papaya tree | tree | 1 x 1 | 60 | 9 | [Page 8](review/painted-buildings/current-camera/after-building-review-8.jpg) |
| 32 / `frangipani` | Frangipani | tree | 1 x 1 | 75 | 12 | [Page 9](review/painted-buildings/current-camera/after-building-review-9.jpg) |
| 33 / `bamboo` | Bamboo grove | tree | 2 x 2 | 120 | 6 | [Page 9](review/painted-buildings/current-camera/after-building-review-9.jpg) |
| 34 / `twin_palms` | Twin palms | tree | 2 x 2 | 150 | 6 | [Page 9](review/painted-buildings/current-camera/after-building-review-9.jpg) |
| 35 / `mango` | Mango tree | tree | 2 x 2 | 180 | 9 | [Page 9](review/painted-buildings/current-camera/after-building-review-9.jpg) |
| 36 / `kapok` | Giant kapok | tree | 2 x 2 | 300 | 18 | [Page 10](review/painted-buildings/current-camera/after-building-review-10.jpg) |
| 37 / `shrub` | Round shrub | bush | 1 x 1 | 15 | 0 | [Page 10](review/painted-buildings/current-camera/after-building-review-10.jpg) |
| 38 / `fern` | Forest fern | bush | 1 x 1 | 15 | 0 | [Page 10](review/painted-buildings/current-camera/after-building-review-10.jpg) |
| 39 / `monstera` | Big-leaf monstera | bush | 1 x 1 | 30 | 3 | [Page 10](review/painted-buildings/current-camera/after-building-review-10.jpg) |
| 40 / `flower_shrub` | Flowering shrub | bush | 1 x 1 | 30 | 3 | [Page 11](review/painted-buildings/current-camera/after-building-review-11.jpg) |
| 41 / `berry` | Berry bush | bush | 1 x 1 | 30 | 6 | [Page 11](review/painted-buildings/current-camera/after-building-review-11.jpg) |
| 42 / `reeds` | Riverside reeds | bush | 1 x 1 | 30 | 6 | [Page 11](review/painted-buildings/current-camera/after-building-review-11.jpg) |
| 43 / `topiary` | Topiary ball | bush | 1 x 1 | 45 | 9 | [Page 11](review/painted-buildings/current-camera/after-building-review-11.jpg) |
| 44 / `hedge` | Clipped hedge block | bush | 1 x 1 | 30 | 9 | [Page 12](review/painted-buildings/current-camera/after-building-review-12.jpg) |
| 45 / `orchid` | Wild orchids | flower | 1 x 1 | 15 | 0 | [Page 12](review/painted-buildings/current-camera/after-building-review-12.jpg) |
| 46 / `hibiscus` | Red hibiscus | flower | 1 x 1 | 15 | 0 | [Page 12](review/painted-buildings/current-camera/after-building-review-12.jpg) |
| 47 / `daisies` | Sunny daisies | flower | 1 x 1 | 15 | 3 | [Page 12](review/painted-buildings/current-camera/after-building-review-12.jpg) |
| 48 / `blue_lily` | Blue lilies | flower | 1 x 1 | 30 | 6 | [Page 13](review/painted-buildings/current-camera/after-building-review-13.jpg) |
| 49 / `flower_box` | Flower planter | flower | 1 x 1 | 30 | 6 | [Page 13](review/painted-buildings/current-camera/after-building-review-13.jpg) |
| 50 / `bromeliad` | Blooming bromeliad | flower | 1 x 1 | 30 | 9 | [Page 13](review/painted-buildings/current-camera/after-building-review-13.jpg) |
| 51 / `flower_bed` | Flower bed | flower | 2 x 2 | 90 | 6 | [Page 13](review/painted-buildings/current-camera/after-building-review-13.jpg) |
| 52 / `rainbow_bed` | Rainbow garden | flower | 2 x 2 | 180 | 15 | [Page 14](review/painted-buildings/current-camera/after-building-review-14.jpg) |
| 53 / `broken_column` | Broken column | statue | 1 x 1 | 30 | 3 | [Page 14](review/painted-buildings/current-camera/after-building-review-14.jpg) |
| 54 / `idol_head` | Stone idol | statue | 1 x 1 | 45 | 3 | [Page 14](review/painted-buildings/current-camera/after-building-review-14.jpg) |
| 55 / `jaguar` | Jaguar guardian | statue | 1 x 1 | 60 | 6 | [Page 14](review/painted-buildings/current-camera/after-building-review-14.jpg) |
| 56 / `obelisk` | Sun obelisk | statue | 1 x 1 | 60 | 9 | [Page 15](review/painted-buildings/current-camera/after-building-review-15.jpg) |
| 57 / `sundial` | Sundial | statue | 1 x 1 | 60 | 9 | [Page 15](review/painted-buildings/current-camera/after-building-review-15.jpg) |
| 58 / `explorer` | Explorer statue | statue | 1 x 1 | 90 | 12 | [Page 15](review/painted-buildings/current-camera/after-building-review-15.jpg) |
| 59 / `gold_idol` | Golden idol | statue | 1 x 1 | 150 | 18 | [Page 15](review/painted-buildings/current-camera/after-building-review-15.jpg) |
| 60 / `stone_arch` | Ruined arch | statue | 2 x 2 | 180 | 12 | [Page 16](review/painted-buildings/current-camera/after-building-review-16.jpg) |
| 61 / `giant_head` | Giant stone head | statue | 2 x 2 | 240 | 15 | [Page 16](review/painted-buildings/current-camera/after-building-review-16.jpg) |
| 62 / `birdbath` | Birdbath | water | 1 x 1 | 45 | 3 | [Page 16](review/painted-buildings/current-camera/after-building-review-16.jpg) |
| 63 / `small_fountain` | Little fountain | water | 1 x 1 | 90 | 9 | [Page 16](review/painted-buildings/current-camera/after-building-review-16.jpg) |
| 64 / `lily_pond` | Lily pond | water | 2 x 2 | 120 | 6 | [Page 17](review/painted-buildings/current-camera/after-building-review-17.jpg) |
| 65 / `duck_pond` | Duck pond | water | 2 x 2 | 150 | 9 | [Page 17](review/painted-buildings/current-camera/after-building-review-17.jpg) |
| 66 / `spring_rocks` | Rock spring | water | 2 x 2 | 240 | 15 | [Page 17](review/painted-buildings/current-camera/after-building-review-17.jpg) |
| 67 / `bench` | Garden bench | garden | 1 x 1 | 30 | 0 | [Page 17](review/painted-buildings/current-camera/after-building-review-17.jpg) |
| 68 / `lantern` | Lantern post | garden | 1 x 1 | 30 | 0 | [Page 18](review/painted-buildings/current-camera/after-building-review-18.jpg) |
| 69 / `tiki` | Tiki torch | garden | 1 x 1 | 30 | 3 | [Page 18](review/painted-buildings/current-camera/after-building-review-18.jpg) |
| 70 / `signpost` | Signpost | garden | 1 x 1 | 30 | 3 | [Page 18](review/painted-buildings/current-camera/after-building-review-18.jpg) |
| 71 / `flagpole` | Expedition flag | garden | 1 x 1 | 45 | 6 | [Page 18](review/painted-buildings/current-camera/after-building-review-18.jpg) |
| 72 / `pump` | Water pump | garden | 1 x 1 | 45 | 9 | [Page 19](review/painted-buildings/current-camera/after-building-review-19.jpg) |
| 73 / `picnic` | Picnic rug | garden | 2 x 2 | 120 | 6 | [Page 19](review/painted-buildings/current-camera/after-building-review-19.jpg) |
| 74 / `hammock` | Palm hammock | garden | 2 x 2 | 150 | 6 | [Page 19](review/painted-buildings/current-camera/after-building-review-19.jpg) |
| 75 / `pergola` | Vine pergola | garden | 2 x 2 | 180 | 9 | [Page 19](review/painted-buildings/current-camera/after-building-review-19.jpg) |
| 76 / `swing` | Garden swing | garden | 2 x 2 | 240 | 12 | [Page 20](review/painted-buildings/current-camera/after-building-review-20.jpg) |
| 77 / `gazebo` | Jade gazebo | garden | 2 x 2 | 300 | 12 | [Page 20](review/painted-buildings/current-camera/after-building-review-20.jpg) |
| 78 / `crates` | Supply crates | camp | 1 x 1 | 15 | 0 | [Page 20](review/painted-buildings/current-camera/after-building-review-20.jpg) |
| 79 / `barrels` | Barrels | camp | 1 x 1 | 15 | 0 | [Page 20](review/painted-buildings/current-camera/after-building-review-20.jpg) |
| 80 / `campfire` | Campfire | camp | 1 x 1 | 30 | 0 | [Page 21](review/painted-buildings/current-camera/after-building-review-21.jpg) |
| 81 / `field_scope` | Field telescope | camp | 1 x 1 | 60 | 9 | [Page 21](review/painted-buildings/current-camera/after-building-review-21.jpg) |
| 82 / `globe` | Explorer's globe | camp | 1 x 1 | 90 | 15 | [Page 21](review/painted-buildings/current-camera/after-building-review-21.jpg) |
| 83 / `chest` | Treasure chest | camp | 1 x 1 | 120 | 15 | [Page 21](review/painted-buildings/current-camera/after-building-review-21.jpg) |
| 84 / `supply_tent` | Supply tent | camp | 2 x 2 | 120 | 3 | [Page 22](review/painted-buildings/current-camera/after-building-review-22.jpg) |
| 85 / `dig_site` | Dig site | camp | 2 x 2 | 120 | 6 | [Page 22](review/painted-buildings/current-camera/after-building-review-22.jpg) |
| 86 / `rowboat` | Rowboat | camp | 2 x 2 | 150 | 9 | [Page 22](review/painted-buildings/current-camera/after-building-review-22.jpg) |
| 87 / `cart` | Market cart | camp | 2 x 2 | 180 | 9 | [Page 22](review/painted-buildings/current-camera/after-building-review-22.jpg) |
| 88 / `turtle` | Sunning turtle | animal | 1 x 1 | 60 | 6 | [Page 23](review/painted-buildings/current-camera/after-building-review-23.jpg) |
| 89 / `toucan` | Toucan perch | animal | 1 x 1 | 60 | 6 | [Page 23](review/painted-buildings/current-camera/after-building-review-23.jpg) |
| 90 / `parrot` | Parrot perch | animal | 1 x 1 | 60 | 9 | [Page 23](review/painted-buildings/current-camera/after-building-review-23.jpg) |
| 91 / `monkey` | Curious monkey | animal | 1 x 1 | 90 | 12 | [Page 23](review/painted-buildings/current-camera/after-building-review-23.jpg) |
| 92 / `capybara` | Capybara | animal | 1 x 1 | 90 | 12 | [Page 24](review/painted-buildings/current-camera/after-building-review-24.jpg) |
| 93 / `boulder` | Boulder | rock | 1 x 1 | 15 | 0 | [Page 24](review/painted-buildings/current-camera/after-building-review-24.jpg) |
| 94 / `crystal` | Crystal cluster | rock | 1 x 1 | 120 | 18 | [Page 24](review/painted-buildings/current-camera/after-building-review-24.jpg) |
| 95 / `mossy_rocks` | Mossy boulders | rock | 2 x 2 | 60 | 3 | [Page 24](review/painted-buildings/current-camera/after-building-review-24.jpg) |

## Style and prompt provenance

See the [shared building style guide](../../../docs/BUILDING_STYLE.md) for the
accepted palette, materials, polish and review criteria, and the
[reference index](../art/building-catalogue/painted-v1/references.json) for exact
prompts, ordered input images, hashes and accepted versions.
