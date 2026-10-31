# Building registration and shadows

The [96-entry catalogue](building-catalogue.md) owns names, prices, unlocks and whole-tile
sizes. Every object has its own Blender-rendered sprite and ground shadow, registered by
`make buildings GAME=relic-rush` and merged by key from the generated
`lua/building_sprites.lua`. `city.tile = 56` is one tile side for the entire catalogue.
See the shared [building spec](../../../docs/BUILDINGS.md).

The engine draws all shadows below all sprites. A held sprite lifts while its shadow
remains at the snapped landing point. Blocked placement keeps the existing neutral
shadow/red preview. Cards and reward thumbnails use only the sprite.
`city:shadow_rect()` reports the separate registered bounds; shadow pixels do not enlarge
the sprite hit rectangle.

Existing saves continue through `island.restore_saved`: catalogue ownership, resources,
income stamps and story progress are preserved, and buildings saved under an earlier
projection re-snap to the current grid. `--footprints` adds gold occupied-base outlines
beside the existing green clearance outlines and magenta ground pivots.

```sh
make buildings GAME=relic-rush
make CFLAGS="-O2 -g -Werror"
make test
```

Earlier captures of the 2:1 paint-overs are in [review](review/painted-buildings/README.md).
