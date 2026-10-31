# Building registration and independent shadows

The [96-entry catalogue](building-catalogue.md) owns all runtime sprites,
whole-tile sizes, measured ground-centre pivots, prices and unlocks. It includes
the Sunstone courtyard at stable ID 4; the former bridge remains historical art.
`city.tile = size2(40,20)` gives one fixed 80×40 tile for the entire catalogue.
See the shared [building spec](../../../docs/BUILDINGS.md).

`tools/prepare_buildings.py` exports the current painted sprites unchanged.
`tools/building_assets.py` then registers nine independent Blender shadows
(camp, well, workshop, market, lodge, archive, observatory, fountain, temple).
Each source pass is resized to the corresponding current sprite's measured
base width and spatially cropped, preserving shadow alpha. Exact resize,
crop, pixel density and ground pivot are recorded in
`art/isometric-paintover/registration.json`; `lua/building_art.lua` contains only
shadow paths/pivots and a base-width consistency check. No sprite definition,
footprint or economic value is overridden.

The bridge's source pass is incompatible with the new courtyard and is excluded.
The courtyard and 86 repeatable decorations retain their current authored art
without a separate shadow layer. No replacement shadow is manufactured.

The engine draws all independent shadows below all sprites. A held sprite lifts
while its shadow remains at the snapped landing point. Blocked placement keeps
the existing neutral shadow/red preview. Cards and reward thumbnails use only
the painted sprite. `city:shadow_rect()` reports the separate registered bounds;
shadow pixels do not enlarge the sprite hit rectangle.

Existing saves continue through `island.restore_saved`: catalogue ownership,
resources, income stamps and story progress are preserved. This integration
changes no footprints and requires no additional save-version migration.
`--footprints` adds gold occupied-base outlines beside the existing green
clearance outlines and magenta ground pivots.

```sh
python3 games/relic-rush/tools/prepare_buildings.py
python3 games/relic-rush/tools/building_assets.py
python3 games/relic-rush/tools/building_assets.py --check
make CFLAGS="-O2 -g -Werror"
make test
python3 games/relic-rush/tools/capture_buildings.py after
```

[Reviewed captures](review/painted-buildings/README.md) cover both phone sizes and
shared Nile debug outlines at both iPad sizes and 16:9. The wider projection
acceptance work remains [issue #15](https://github.com/corepunch/nile-archive/issues/15).
