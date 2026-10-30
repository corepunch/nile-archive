# Painted buildings and independent ground shadows

All 34 real-game captures were visually inspected. Captured with the native renderer at logical 480×900 and 390×844 (the latter with 0,47,0,34 phone safe areas). Retina image dimensions are twice the logical size.

The original art is retained in the before captures. After captures use ImageGen-painted transparent sprites, source-camera tile sizes and separately rendered Blender shadows. The held capture feeds an actual held-pointer gesture through the city update so lift and ground-shadow separation are visible.

Reproduce with `python3 games/relic-rush/tools/capture_buildings.py after`; capture the before set on the parent implementation before replacing the sprites.

| Screen / logical size | Before | After |
| --- | --- | --- |
| Restored village / all ten sprites and shadows, 480x900 | ![Before village](before-village-480x900.jpg) | ![After village](after-village-480x900.jpg) |
| Actual bases (gold), clearance (green), pivots (magenta), 480x900 | ![Before registration](before-registration-480x900.jpg) | ![After registration](after-registration-480x900.jpg) |
| Valid placement, 480x900 | ![Before placement](before-placement-480x900.jpg) | ![After placement](after-placement-480x900.jpg) |
| Held sprite / grounded shadow, 480x900 | ![Before dragging](before-dragging-480x900.jpg) | ![After dragging](after-dragging-480x900.jpg) |
| Blocked placement, 480x900 | ![Before blocked](before-blocked-480x900.jpg) | ![After blocked](after-blocked-480x900.jpg) |
| Building card, 480x900 | ![Before card](before-card-480x900.jpg) | ![After card](after-card-480x900.jpg) |
| Expedition reward thumbnail, 480x900 | ![Before reward](before-reward-480x900.jpg) | ![After reward](after-reward-480x900.jpg) |
| Restored village / all ten sprites and shadows, 390x844 | ![Before village](before-village-390x844.jpg) | ![After village](after-village-390x844.jpg) |
| Actual bases (gold), clearance (green), pivots (magenta), 390x844 | ![Before registration](before-registration-390x844.jpg) | ![After registration](after-registration-390x844.jpg) |
| Valid placement, 390x844 | ![Before placement](before-placement-390x844.jpg) | ![After placement](after-placement-390x844.jpg) |
| Held sprite / grounded shadow, 390x844 | ![Before dragging](before-dragging-390x844.jpg) | ![After dragging](after-dragging-390x844.jpg) |
| Blocked placement, 390x844 | ![Before blocked](before-blocked-390x844.jpg) | ![After blocked](after-blocked-390x844.jpg) |
| Building card, 390x844 | ![Before card](before-card-390x844.jpg) | ![After card](after-card-390x844.jpg) |
| Expedition reward thumbnail, 390x844 | ![Before reward](before-reward-390x844.jpg) | ![After reward](after-reward-390x844.jpg) |

The shared engine footprint-debug view also gains the gold occupied-base outline. Nile Archive has no new shadow assets; its three reviewed debug sizes are included below.

| Nile debug size | Before | After |
| --- | --- | --- |
| 1200x900 | ![Before](before-nile-registration-1200x900.jpg) | ![After](after-nile-registration-1200x900.jpg) |
| 1368x1026 | ![Before](before-nile-registration-1368x1026.jpg) | ![After](after-nile-registration-1368x1026.jpg) |
| 1600x900 | ![Before](before-nile-registration-1600x900.jpg) | ![After](after-nile-registration-1600x900.jpg) |
