# Christmas art direction catalogue

Status: directional artwork, accepted by the user as reference for a forthcoming Blender scene, render and repaint. Building perspective and registration are provisional. Remaining Blender-guided sprite registration, clean edges and special-colour readability are tracked in [#34](https://github.com/corepunch/nile-archive/issues/34).

| Asset | Source | Draft runtime | Meaning and supported states |
| --- | --- | --- | --- |
| Twelve buildings/decorations | `art/buildings.png` | `data/buildings/0.png`–`11.png` | Ten sequential construction milestones and two repeatable decorations; placed and placement-preview use the same directional painting, with engine lift/footprint feedback |
| Labeled building sheet | `art/building-reference-sheet.png` | Reference only | All twelve designs, numbered and captioned for Blender handoff |
| Six festive puzzle kinds | `art/icons.png`, cells 0–5 | `data/tile-sets/festive/` | Bell, candy cane, holly, blue ornament, purple bauble, gingerbread; bell objective, candy canes thaw nearby ice |
| Specials and board layers | `art/icons.png`, cells 6–18 | `data/board-states/` | Three shooting-star axes, firework bomb, rainbow prism, snow, tinsel, two ice strengths, selection, hint, guide and cell mask |
| Tools | `art/icons.png`, cells 19–33 | `data/board-states/` | Hammer, firecracker and star wand: normal, selected, pressed, hover and disabled, authored together in one atlas |
| Pause and completion | `art/icons.png`, cells 34–39 | `data/expedition-hud/` | Five authored pause states and a completion medal; medal also represents cumulative Christmas Stars |
| Terrain | `art/terrain.png` | `data/island.jpg`, `data/winter.jpg` | Empty snowy market ground and puzzle backdrop |
| Main character | User-supplied `art/noelle-reference.jpg`; ImageGen transparent cutout `art/noelle.png` | `data/characters/noelle.png` | Noelle's static dialogue and board portrait; original direction retained as `art/noelle-direction-v1.png` |
| Portrait app icon | `art/app-icon-source.png` | `Assets.xcassets/AppIcon.appiconset/` | One authored portrait composition, spatially resized for all iOS/macOS slots; opaque RGB square, no baked corner mask, no interaction states |
| Snowfall and feedback | Lua renderer | Procedural | Transient snow particles, collection particles, beams, lift and placement feedback; no authored control state is derived with a filter |

Built-in ImageGen generated all new paintings. `art/prompts.json` records the exact source prompts; `art/reference-sheet-prompt.txt` records the labeled-sheet prompt. `art/registration.json` records crop rectangles, spatial extraction polygons, output sizing and provisional building registration. Original source RGB and alpha are preserved inside extracted artwork. Control states are directly cropped from the authored atlas.

Reproduce draft runtime extraction with `python3 games/christmas-market/tools/prepare_assets.py`; launch previews with `make run-christmas-market ARGS="--showcase --fresh --mute"` or `ARGS="--level 4 --fresh --mute"`. The PR captures all screens at 480×900, plus the market, board and dialogue at 390×844 with safe areas. All twelve directional building footprints are included across three review pages. Final painted footprint accuracy remains for the Blender pass.

The font and its license are inherited unmodified from Relic Rush in `data/fonts/`. Gameplay modules were adapted locally from Relic Rush; its original archaeological paintings are not used in this draft.

## Main character and app icon review

The user selected the supplied portrait as the main character. Built-in ImageGen used it as the identity reference for the app icon and for transparent background extraction. Exact prompts are preserved in `art/character-and-icon-prompts.json`. Reproduce the runtime exports with `python3 games/christmas-market/tools/prepare_character.py` (also called by the full asset preparation script). All eleven iOS/macOS catalogue entries were checked for the declared pixel dimensions and opaque RGB, and the 64px icon was visually inspected. Xcode project freshness checks pass.

Actual game captures cover both portrait uses: [480×900 puzzle header](screenshots/main-character-board.jpg) and [390×844 dialogue with safe areas](screenshots/main-character-dialogue.jpg).


## Reviewed state coverage

- [All six kinds, three special axes, bomb/prism, snow/tinsel, both ice strengths and all five tool states](screenshots/art-states.jpg).
- [All five pause states, completion medal and Noelle portrait](screenshots/hud-states.jpg).
- [Specials, selection/hint and exhausted tool on an actual board](screenshots/specials-board.jpg).
- [Buildings 1–4](screenshots/building-review-1.jpg), [5–8](screenshots/building-review-2.jpg), [9–12](screenshots/building-review-3.jpg), and [market footprints](screenshots/footprints.jpg).
- [Valid placement](screenshots/placement.jpg), [blocked placement](screenshots/blocked-placement.jpg), [shop](screenshots/shop.jpg), [building card](screenshots/building-card.jpg), and [reward](screenshots/reward.jpg).

`art/manifest.json` records hashes for every runtime file. Update it with `python3 games/christmas-market/tools/check_assets.py --update` only alongside the corresponding catalogue/source changes. The full native build with `-Werror`, rule tests, Lua lint (59 files, zero warnings), inventory checks and real-input game smoke pass on macOS. Linux Xvfb, WebAssembly and iOS Simulator coverage run in CI.
