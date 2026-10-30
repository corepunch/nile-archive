# Floating board HUD

Before: merged main `961973730ab48099f6d4afd2635dd02f83677cda`. After: this PR.

The score/level/moves readouts float directly over the authored lagoon and temple paintings, following Nile Archive's approach. The large cream backing panel is removed. Existing outlined, shadowed typography provides local contrast, along with the move counter, objective pills and a slim translucent dark progress track. No artwork, visual state, gameplay rule or input target was added.

All review captures come from the real game, with `--headless --mute --fresh --shot <file>.png`. Before/after pairs cover:

| Name | Size | Extra arguments |
| --- | --- | --- |
| lagoon | 480×900 | `--frames 4` |
| temple | 480×900 | `--level 9 --frames 4` |
| phone-lagoon | 390×844 | `--safe-area 0,47,0,34 --frames 4` |
| phone-temple | 390×844 | `--level 9 --safe-area 0,47,0,34 --frames 4` |
| ray, bomb, prism | 480×900 | `--fx ray` / `bomb` / `prism`, `--frames 10` |
| pause, guide | 480×900 | `--dialog pause` / `guide`, `--frames 40` |

Review images are reduced to logical phone dimensions. Canonical captures and the effects reels are refreshed under `docs/screenshots/`; `make shots` reproduces them. Build/test and normal/tall-phone input smoke runs pass.
