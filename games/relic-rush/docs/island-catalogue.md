# Island catalogue

Proposed content for Relic Rush's first release: 96 assets. **Proposal, not runtime content.** Nothing here
is wired into the game yet. Prices, unlocks and charm are first-pass numbers to tune in play.

The models are procedural Blender geometry in `art/isometric-blender/build_scene.py`, in the casual block style, on
the 2:1 grid of `docs/BUILDINGS.md`. They are review blockouts, not finished runtime sprites. The original `art/buildings.png`
and runtime sprites are unchanged.

## What June's Journey does, and what we take from it

From the community [June's Journey Wiki](https://junes-journey.fandom.com/wiki/June%27s_Journey_Wiki) (CC-BY-SA;
player-maintained, so some numbers may be out of date). Its pages cover only part of the game's current content.

| June's Journey | Detail | Relic Rush |
|---|---|---|
| [Buildings](https://junes-journey.fandom.com/wiki/Buildings) | 28 3×3 income buildings and a 4×4 Estate, unlocked by stars, 7 to 1836 | 26: 10 wonders and 16 income buildings, 2×2 to 4×4 |
| [Landmarks](https://junes-journey.fandom.com/wiki/Landmarks) | Five fixed story restorations | The wonders fill this role, but the player places them |
| [Decorations](https://junes-journey.fandom.com/wiki/Decorations) | About 120 permanent items, almost all 1×1 or 2×2, unlocked in batches | 70, all 1×1 or 2×2 |
| Flowers | Every coin decoration gives the same flowers per coin (1 per 30) and flowers raise the level | Charm, one per 5 gold, the same for everything |
| [Shop](https://junes-journey.fandom.com/wiki/Shop) | Tiles, Permanent Decorations, Buildings, Seasonal Sets, Limited Edition | Tabs by the sections below |
| [Seasonal sets](https://junes-journey.fandom.com/wiki/Tropical_Paradise_Set_(2021)) | Monthly themed sets, such as Tropical Paradise | Later: not needed for the first release |
| [Gift bushes](https://junes-journey.fandom.com/wiki/Bushes) | Placed on friends' islands | Later: needs a social layer |

Left out on purpose: tiles, paths, roads, fences and walls that connect, because of their joining logic. Also train
items, which are tied to June's Journey's setting. Names here are our own; the "Closest in June's Journey" column
is only a reference for scale and role. **Don't copy their art or names into the game.**

## Rules

- **Footprints** are whole tiles. `w` runs along the front-left side, `h` along the front-right. The Blender pivot is the
  footprint's ground centre.
- **Wonders and buildings** stand on a slab exactly the size of their footprint. Decorations stand straight on the grass.
- **Stars** is the number of stars needed to unlock. The six regions open at 0, 6, 9, 15, 21 and 27 stars today, and these thresholds follow them.
- **Wonder sizes** are the ones in the Blender scene. Five differ from `lua/island.lua`: gateway 4×2 (game 3×2), lodge 3×3 (3×2),
  archive 3×3 (2×2), fountain 3×3 (2×2), temple 4×4 (3×3). Wonder prices are the gold part of today's costs.

## Engine work this list needs

- **Clearance per type.** `city.clearance` is one value for all types. At today's `size2(1, 1)` a 1×1 bush takes 2×2
  tiles, so decorations can't sit together. Decorations need 0.
- **More placed items.** `CITY_MAX` is 160. One of every asset uses 96, leaving little room to repeat
  decorations, which is most of what players do in this genre.
- **Not one of each, in order.** `island_place_next` treats `c.count` as the next wonder. Decorations need a shop that buys any unlocked
  type, any number of times.
- **Charm and shop.** Neither exists yet: a charm total, shop tabs, unlock filtering.
- **Space.** The lawn is about 1146 tiles. One of each covers 332 before clearance, so there's room to repeat.

## Wonders (the story campaign) (10)

| Asset | Size | Gold | Stars | Charm | Closest in June's Journey |
|---|---|---:|---:|---:|---|
| Expedition camp | 2×2 | 60 | story | 12 | story restoration, as a landmark |
| Spring well | 2×2 | 80 | story | 16 | story restoration, as a landmark |
| Artisan workshop | 3×2 | 100 | story | 20 | story restoration, as a landmark |
| Jungle market | 3×2 | 120 | story | 24 | Farmers Market |
| Sunstone gateway | 4×2 | 140 | story | 28 | Park Bridge |
| Explorer's lodge | 3×3 | 160 | story | 32 | Estate |
| Lost-world archive | 3×3 | 180 | story | 36 | Lavish Library |
| Star observatory | 2×2 | 200 | story | 40 | Observatory |
| Jade fountain | 3×3 | 220 | story | 44 | Fountain |
| Temple of the sun | 4×4 | 250 | story | 50 | story finale, as a landmark |

## Income buildings (16)

| Asset | Size | Gold | Stars | Charm | Closest in June's Journey |
|---|---|---:|---:|---:|---|
| Trapper's cabin | 2×2 | 200 | 6 | 40 | Summer House |
| Herbalist's hut | 2×2 | 220 | 6 | 44 | Flower Shop |
| Mess hall | 3×2 | 240 | 9 | 48 | Orchid Island Gourmet |
| Stilt house | 3×2 | 260 | 9 | 52 | Stately Stilt House |
| Cartographer's house | 3×2 | 280 | 12 | 56 | Schoolhouse |
| Glass greenhouse | 3×2 | 300 | 12 | 60 | Orangerie |
| Trading post | 3×3 | 320 | 15 | 64 | Central Station |
| Water mill | 3×3 | 340 | 15 | 68 | Windmill |
| Clock tower | 2×2 | 360 | 18 | 72 | Clock Tower |
| Valley lighthouse | 2×2 | 380 | 18 | 76 | Lighthouse |
| Canopy treehouse | 3×3 | 400 | 21 | 80 | Tree House |
| Great aviary | 3×3 | 420 | 21 | 84 | Aviary |
| Beached schooner | 4×2 | 440 | 24 | 88 | Pirate Ship |
| Stone amphitheatre | 4×3 | 460 | 24 | 92 | Amphitheater |
| Relic museum | 4×3 | 500 | 27 | 100 | Museum |
| Hanging gardens | 4×4 | 550 | 30 | 110 | Hanging Gardens |

## Trees (11)

| Asset | Size | Gold | Stars | Charm | Closest in June's Journey |
|---|---|---:|---:|---:|---|
| Young palm | 1×1 | 30 | 0 | 6 | Small Lush Tree |
| Round jungle tree | 1×1 | 30 | 0 | 6 | Large Lush Tree |
| Temple cypress | 1×1 | 45 | 3 | 9 | Conical Tree |
| Banana plant | 1×1 | 45 | 3 | 9 | Banana Plants |
| Fan palm | 1×1 | 45 | 6 | 9 | Fan Palm |
| Papaya tree | 1×1 | 60 | 9 | 12 | Papaya Tree |
| Frangipani | 1×1 | 75 | 12 | 15 | Plumeria Tree |
| Bamboo grove | 2×2 | 120 | 6 | 24 | Lush Reeds |
| Twin palms | 2×2 | 150 | 6 | 30 | Tropical Tree |
| Mango tree | 2×2 | 180 | 9 | 36 | Oak, Apple Orchard |
| Giant kapok | 2×2 | 300 | 18 | 60 | Oak |

## Bushes (8)

| Asset | Size | Gold | Stars | Charm | Closest in June's Journey |
|---|---|---:|---:|---:|---|
| Round shrub | 1×1 | 15 | 0 | 3 | Bush |
| Forest fern | 1×1 | 15 | 0 | 3 | Verdant Bush |
| Big-leaf monstera | 1×1 | 30 | 3 | 6 | Marvelous Mangroves |
| Flowering shrub | 1×1 | 30 | 3 | 6 | Bouganvillea |
| Berry bush | 1×1 | 30 | 6 | 6 | Berry Bush |
| Riverside reeds | 1×1 | 30 | 6 | 6 | Lush Reeds |
| Topiary ball | 1×1 | 45 | 9 | 9 | Marble Planter |
| Clipped hedge block | 1×1 | 30 | 9 | 6 | Spear Grass |

## Flowers (8)

| Asset | Size | Gold | Stars | Charm | Closest in June's Journey |
|---|---|---:|---:|---:|---|
| Wild orchids | 1×1 | 15 | 0 | 3 | Pink Flower |
| Red hibiscus | 1×1 | 15 | 0 | 3 | Poppy Patch |
| Sunny daisies | 1×1 | 15 | 3 | 3 | Springtime Blooms |
| Blue lilies | 1×1 | 30 | 6 | 6 | Lovely Lupines |
| Flower planter | 1×1 | 30 | 6 | 6 | Planter |
| Blooming bromeliad | 1×1 | 30 | 9 | 6 | Blooming Bromeliad |
| Flower bed | 2×2 | 90 | 6 | 18 | Blossoming Nook |
| Rainbow garden | 2×2 | 180 | 15 | 36 | Rainbow Grove |

## Statues and monuments (9)

| Asset | Size | Gold | Stars | Charm | Closest in June's Journey |
|---|---|---:|---:|---:|---|
| Broken column | 1×1 | 30 | 3 | 6 | Column Arch |
| Stone idol | 1×1 | 45 | 3 | 9 | Statue |
| Jaguar guardian | 1×1 | 60 | 6 | 12 | Statue |
| Sun obelisk | 1×1 | 60 | 9 | 12 | Marble Vase |
| Sundial | 1×1 | 60 | 9 | 12 | Shining Sundial |
| Explorer statue | 1×1 | 90 | 12 | 18 | Statue |
| Golden idol | 1×1 | 150 | 18 | 30 | Ebony Thoroughbred |
| Ruined arch | 2×2 | 180 | 12 | 36 | Flourishing Archway |
| Giant stone head | 2×2 | 240 | 15 | 48 | Garden Grotto |

## Water features (5)

| Asset | Size | Gold | Stars | Charm | Closest in June's Journey |
|---|---|---:|---:|---:|---|
| Birdbath | 1×1 | 45 | 3 | 9 | Watering Post |
| Little fountain | 1×1 | 90 | 9 | 18 | Flowing Fountain |
| Lily pond | 2×2 | 120 | 6 | 24 | Giant Water Lilies |
| Duck pond | 2×2 | 150 | 9 | 30 | Duck Pond |
| Rock spring | 2×2 | 240 | 15 | 48 | Sunny Spring |

## Garden furniture and structures (11)

| Asset | Size | Gold | Stars | Charm | Closest in June's Journey |
|---|---|---:|---:|---:|---|
| Garden bench | 1×1 | 30 | 0 | 6 | Garden Chairs |
| Lantern post | 1×1 | 30 | 0 | 6 | Gilded Lampost |
| Tiki torch | 1×1 | 30 | 3 | 6 | Tiki Torches |
| Signpost | 1×1 | 30 | 3 | 6 | Crossroads Signpost |
| Expedition flag | 1×1 | 45 | 6 | 9 | Feature Film Board |
| Water pump | 1×1 | 45 | 9 | 9 | Water Barrel Pump |
| Picnic rug | 2×2 | 120 | 6 | 24 | Picnic Perfection |
| Palm hammock | 2×2 | 150 | 6 | 30 | Summer Swing |
| Vine pergola | 2×2 | 180 | 9 | 36 | Shaded Respite |
| Garden swing | 2×2 | 240 | 12 | 48 | Summer Swing |
| Jade gazebo | 2×2 | 300 | 12 | 60 | Gilded Gazebo |

## Camp props (10)

| Asset | Size | Gold | Stars | Charm | Closest in June's Journey |
|---|---|---:|---:|---:|---|
| Supply crates | 1×1 | 15 | 0 | 3 | Barrel-Aged Bounty |
| Barrels | 1×1 | 15 | 0 | 3 | Barrel-Aged Bounty |
| Campfire | 1×1 | 30 | 0 | 6 | Summer Fire Pit |
| Field telescope | 1×1 | 60 | 9 | 12 | News Column |
| Explorer's globe | 1×1 | 90 | 15 | 18 | Classic Commissions |
| Treasure chest | 1×1 | 120 | 15 | 24 | Fruity Feast |
| Supply tent | 2×2 | 120 | 3 | 24 | Holiday Hut |
| Dig site | 2×2 | 120 | 6 | 24 | Herbal Harvest |
| Rowboat | 2×2 | 150 | 9 | 30 | Merrily Rowing |
| Market cart | 2×2 | 180 | 9 | 36 | Hotdog Stand |

## Animals (5)

| Asset | Size | Gold | Stars | Charm | Closest in June's Journey |
|---|---|---:|---:|---:|---|
| Sunning turtle | 1×1 | 60 | 6 | 12 | Foraging Foxes |
| Toucan perch | 1×1 | 60 | 6 | 12 | Hesitant Heron |
| Parrot perch | 1×1 | 60 | 9 | 12 | Hesitant Heron |
| Curious monkey | 1×1 | 90 | 12 | 18 | Curious Critters |
| Capybara | 1×1 | 90 | 12 | 18 | Mischievous Moles |

## Rocks (3)

| Asset | Size | Gold | Stars | Charm | Closest in June's Journey |
|---|---|---:|---:|---:|---|
| Boulder | 1×1 | 15 | 0 | 3 | Hyacinth Rockery |
| Crystal cluster | 1×1 | 120 | 18 | 24 | Lovely Lily Pads |
| Mossy boulders | 2×2 | 60 | 3 | 12 | Hyacinth Rockery |

## Reproduce

Open Blender with its MCP add-on, then run `build_scene.py` inside it with `runpy.run_path`, and save the scene. From `art/isometric-blender/`:

```sh
/Applications/Blender.app/Contents/MacOS/Blender -b relic_rush_buildings.blend -S RelicRushIso -f 1
python3 annotate.py                # overlays footprints from the grid formula and measures them
python3 make_catalogue_doc.py      # regenerates this page from catalogue.json
```
