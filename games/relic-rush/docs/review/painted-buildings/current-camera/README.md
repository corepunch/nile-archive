# relic-rush: painted current-camera buildings

All **96 registered objects** repainted using category ImageGen atlases of
the current Blender renders. Baseline: `aefd544` (raw renders). Source references,
prompts, original/output atlases and exact import transforms are committed under
`art/building-catalogue/painted-v1/`; see the [catalogue](../../../building-catalogue.md).

| Before | After |
| --- | --- |
| ![Before](before-island-village.jpg) | ![After](after-island-village.jpg) |
| ![Alternate size before](before-phone-island.jpg) | ![Alternate size after](after-phone-island.jpg) |
| ![Footprints before](before-footprints.jpg) | ![Footprints after](after-footprints.jpg) |
| ![Catalogue before](before-buildings.jpg) | ![Catalogue after](after-buildings.jpg) |

Registration retains the current camera, tile sizes, whole-tile reservations and
separate grounded shadows. Painted slab edges are aligned against their source
render; props retain their original visual scale and anchor. Catalogue order,
keys, prices, unlocks, saves and engine interaction states keep their contracts.
No engine or gameplay code changed.

Reproduce art: `python3 tools/import_painted_buildings.py relic-rush`.
Capture in one process under Xvfb: `build/test/relic-rush 'shot building-review-'`;
add the named island, shop, placement and footprint shots from `tests/games/relic-rush.lua`.

All review pages were inspected for missing sprites, clipping, perspective,
footprint placement and unwanted generation flecks. Crop-only component bounds
exclude distant flecks; RGB and alpha inside each crop are preserved. Normal
sprites are authored; the engine still supplies lift/placement/validity effects.

## Placement after rebasing onto the updated controls

The current red cancel and jade confirm controls from `93c805b` are preserved.
These captures check the repainted sprites with those controls at both phone sizes.

| 480×900 | 390×844 | Blocked preview |
| --- | --- | --- |
| ![Placement](after-island-placement.jpg) | ![Phone placement](after-phone-island-placement.jpg) | ![Blocked placement](after-island-blocked.jpg) |

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

![after-building-review-13](after-building-review-13.jpg)

![after-building-review-14](after-building-review-14.jpg)

![after-building-review-15](after-building-review-15.jpg)

![after-building-review-16](after-building-review-16.jpg)

![after-building-review-17](after-building-review-17.jpg)

![after-building-review-18](after-building-review-18.jpg)

![after-building-review-19](after-building-review-19.jpg)

![after-building-review-20](after-building-review-20.jpg)

![after-building-review-21](after-building-review-21.jpg)

![after-building-review-22](after-building-review-22.jpg)

![after-building-review-23](after-building-review-23.jpg)

![after-building-review-24](after-building-review-24.jpg)
