# nile-archive: painted current-camera buildings

All **101 registered objects** repainted using category ImageGen atlases of
the current Blender renders. Baseline: `aefd544` (raw renders). Source references,
prompts, original/output atlases and exact import transforms are committed under
`art/building-catalogue/painted-v1/`; see the [catalogue](../../../building-catalogue.md).

| Before | After |
| --- | --- |
| ![Before](before-island.jpg) | ![After](after-island.jpg) |
| ![Alternate size before](before-widescreen.jpg) | ![Alternate size after](after-widescreen.jpg) |
| ![Footprints before](before-footprints.jpg) | ![Footprints after](after-footprints.jpg) |
| ![Catalogue before](before-buildings.jpg) | ![Catalogue after](after-buildings.jpg) |

Registration retains the current camera, tile sizes, whole-tile reservations and
separate grounded shadows. Painted slab edges are aligned against their source
render; props retain their original visual scale and anchor. Catalogue order,
keys, prices, unlocks, saves and engine interaction states keep their contracts.
No engine or gameplay code changed.

Reproduce art: `python3 tools/import_painted_buildings.py nile-archive`.
Capture in one process under Xvfb: `build/test/nile-archive 'shot building-review-'`;
add the named island, shop, placement and footprint shots from `tests/games/nile-archive.lua`.

All review pages were inspected for missing sprites, clipping, perspective,
footprint placement and unwanted generation flecks. Crop-only component bounds
exclude distant flecks; RGB and alpha inside each crop are preserved. Normal
sprites are authored; the engine still supplies lift/placement/validity effects.

Additional iPad capture: ![1368×1026](after-ipad-island.jpg)

## Every catalogue page

![after-building-review-1](after-building-review-1.jpg)

![after-building-review-2](after-building-review-2.jpg)

![after-building-review-3](after-building-review-3.jpg)

![after-building-review-4](after-building-review-4.jpg)

![after-building-review-5](after-building-review-5.jpg)

![after-building-review-6](after-building-review-6.jpg)

![after-building-review-7](after-building-review-7.jpg)

![after-building-review-8](after-building-review-8.jpg)

![after-building-review-9](after-building-review-9.jpg)

![after-building-review-10](after-building-review-10.jpg)

![after-building-review-11](after-building-review-11.jpg)

![after-building-review-12](after-building-review-12.jpg)
