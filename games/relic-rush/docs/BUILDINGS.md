# Building art, footprints and ground shadows

The game uses a fixed 2:1 ground projection, `city.tile = (40,20)` half extents:
one tile is 80×40 world units. A tile offset `(u,v)` projects to
`((u-v)*40,(u+v)*20)`. Straight ground-axis edges have slopes ±0.5.

All ten painted buildings were authored together in one ImageGen paint-over of
the original Blender grid render. A second full-atlas ImageGen edit authored
the transparent cutouts and removed baked ground shadows. The original render,
painted master, transparent master, prompts and Blender master are committed.
See [provenance and reproduction](../art/isometric-paintover/README.md).

| Building | Occupied tiles |
| --- | --- |
| Expedition camp | 2×2 |
| Spring well | 2×2 |
| Artisan workshop | 3×2 |
| Jungle market | 3×2 |
| Sunstone gateway | 4×2 |
| Explorer's lodge | 3×3 |
| Lost-world archive | 3×3 |
| Star observatory | 2×2 |
| Jade fountain | 3×3 |
| Temple of the sun | 4×4 |

`tools/building_assets.py` locates the ten separated authored components and
copies spatial crops without changing RGB or alpha. The original camera report
provides each footprint centre and base width, registered to the generated atlas.
`art/isometric-paintover/registration.json` records source/crop coordinates and
each pixel pivot; `lua/building_art.lua` is the generated runtime table.

The engine derives one uniform world scale from the painted base width and tile
count. Sprite height never independently caps or distorts that scale. Pivots
remain the ground-centre point through cropping, zoom, placement and hit testing.
Placement reserves an extra half tile on every side (`city.clearance = (1,1)`).
In `--footprints` captures green shows that clearance, gold traces the actual
occupied base and magenta marks the ground pivot.

## Independent shadows

`render_shadows.py` renders isolated source buildings onto a transparent Cycles
shadow catcher with the original camera/light. Source meshes are invisible to
the camera but cast shadows. No Blender model/material refinements are used for
the painted artwork. Each shadow is rendered separately to exclude neighbours.

The exporter resizes the shadow pass to the atlas pixel density, then crops it
and records its own `shadow_pivot`. Shadow and sprite may have different canvas
sizes but share the same world units per pixel. `city:shadow_rect()` exposes the
registered shadow bounds. Shadow pixels never enlarge the building hit rectangle.

The engine draws all shadows after land/fog and before all painted buildings.
The old shadow is omitted while moving; the preview shadow sits at the snapped
landing point. Building lift/pop animations affect the sprite, keeping its
shadow grounded. Blocked placement retains the existing red sprite ghost and a
neutral shadow. Building cards and reward thumbnails use the sprite alone.
These states and runtime files are catalogued in [the asset catalogue](asset-catalogue.md).

## Existing saves and verification

The save records `building-art = 1`. Older layouts are re-snapped for new size
parities and use the engine's nearest legal open spot when necessary. This does
not charge resources or lose building types/stamps. If no full legal layout is
possible, the migration restores the original layout atomically and retains the
old version for a later retry. Migration and independent shadow scaling have
regression coverage.

```sh
python3 games/relic-rush/tools/building_assets.py
python3 games/relic-rush/tools/building_assets.py --check
make CFLAGS="-O2 -g -Werror"
make test
python3 games/relic-rush/tools/capture_buildings.py after
```

`--check` compares every exported RGBA pixel and registration record with the
committed sources. Real-game review covers all ten buildings, base/pivot guides,
valid/blocked/held placement, cards and rewards at both phone sizes. See the
[before/after capture matrix](review/painted-buildings/README.md).
