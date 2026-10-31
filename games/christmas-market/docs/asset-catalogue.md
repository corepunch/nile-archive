# Christmas art direction catalogue

Status: the buildings are Blender renders with projected registration (see the [building catalogue](building-catalogue.md)); the board, HUD and character art are directional ImageGen artwork. The planned ImageGen repaint of the renders and special-colour readability remain in [#34](https://github.com/corepunch/nile-archive/issues/34).

| Asset | Source | Draft runtime | Meaning and supported states |
| --- | --- | --- | --- |
| 37 buildings and decorations | `art/building-catalogue/` (Blender scene, catalogue, registration) | `data/buildings/<key>.png` | Ten sequential construction milestones, 15 decorations, 4 trees and 6 cottages, one Blender render each; placed and placement-preview use the same sprite, with engine lift/footprint feedback. See the [building catalogue](building-catalogue.md) |
| Original building atlas | `art/buildings.png` | Retired | The first directional paintings of the twelve designs; no longer extracted |
| Labeled building sheet | `art/building-reference-sheet.png` | Reference only | All twelve designs, numbered and captioned: the Blender models follow it |
| Six festive puzzle kinds | `art/icons.png`, cells 0–5 | `data/tile-sets/festive/` | Bell, candy cane, holly, blue ornament, purple bauble, gingerbread; bell objective, candy canes thaw nearby ice |
| Specials and board layers | `art/icons.png`, cells 6–18 | `data/board-states/` | Three shooting-star axes, firework bomb, rainbow prism, snow, tinsel, two ice strengths, selection, hint, guide and cell mask |
| Tools | `art/icons.png`, cells 19–33 | `data/board-states/` | Hammer, firecracker and star wand: normal, selected, pressed, hover and disabled, authored together in one atlas |
| Pause and completion | `art/icons.png`, cells 34–39 | `data/expedition-hud/` | Five authored pause states and a completion medal; medal also represents cumulative Christmas Stars |
| Terrain | `art/terrain.png` | `data/island.jpg`, `data/winter.jpg` | Empty snowy market ground and puzzle backdrop |
| Main character | User-supplied `art/noelle-reference.jpg`; ImageGen transparent cutout `art/noelle.png` | `data/characters/noelle.png` | Noelle's static dialogue and board portrait; original direction retained as `art/noelle-direction-v1.png` |
| Portrait app icon | `art/app-icon-source.png` | `Assets.xcassets/AppIcon.appiconset/` | One authored portrait composition, spatially resized for all iOS/macOS slots; opaque RGB square, no baked corner mask, no interaction states |
| Interface controls | `lua/skin.lua` (engine `ui.skin`) | Engine geometry | Four outlined Lilita text palettes, the parchment panel, the festive red button (normal, pressed sinks 2 units, disabled drains the colour; flat text variant), toggle and focus ring. Hover and selected match normal because touch has no hover; no bitmap or derived state. Captures are pixel-identical to the paint code this replaced |
| Snowfall and feedback | Lua renderer | Procedural | Transient snow particles, collection particles, beams, lift and placement feedback; no authored control state is derived with a filter |

Built-in ImageGen generated all new paintings except the buildings, which are Blender renders. `art/prompts.json` records the exact source prompts; `art/reference-sheet-prompt.txt` records the labeled-sheet prompt. `art/registration.json` records the icon atlas crops and output sizing; building registration lives in `art/building-catalogue/`. Original source RGB and alpha are preserved inside extracted artwork. Control states are directly cropped from the authored atlas.

Reproduce draft runtime extraction with `python3 games/christmas-market/tools/prepare_assets.py`; launch previews with `make run-christmas-market ARGS="--showcase --fresh --mute"` or `ARGS="--level 4 --fresh --mute"`. The PR captures all screens at 480×900, plus the market, board and dialogue at 390×844 with safe areas. All twelve directional building footprints are included across three review pages. Every building footprint is now projected from the Blender scene and checked in the ten review pages.

The font and its license are inherited unmodified from Relic Rush in `data/fonts/`. Gameplay modules were adapted locally from Relic Rush; its original archaeological paintings are not used in this draft.

## Main character and app icon review

The user selected the supplied portrait as the main character. Built-in ImageGen used it as the identity reference for the app icon and for transparent background extraction. Exact prompts are preserved in `art/character-and-icon-prompts.json`. Reproduce the runtime exports with `python3 games/christmas-market/tools/prepare_character.py` (also called by the full asset preparation script). All eleven iOS/macOS catalogue entries were checked for the declared pixel dimensions and opaque RGB, and the 64px icon was visually inspected. Xcode project freshness checks pass.

Actual game captures cover both portrait uses: [480×900 puzzle header](screenshots/main-character-board.jpg) and [390×844 dialogue with safe areas](screenshots/main-character-dialogue.jpg).


## Reviewed state coverage

- [All six kinds, three special axes, bomb/prism, snow/tinsel, both ice strengths and all five tool states](screenshots/art-states.jpg).
- [All five pause states, completion medal and Noelle portrait](screenshots/hud-states.jpg).
- [Specials, selection/hint and exhausted tool on an actual board](screenshots/specials-board.jpg).
- All 37 buildings with footprints, four a page: [1](screenshots/building-review-1.jpg), [2](screenshots/building-review-2.jpg), [3](screenshots/building-review-3.jpg), [4](screenshots/building-review-4.jpg), [5](screenshots/building-review-5.jpg), [6](screenshots/building-review-6.jpg), [7](screenshots/building-review-7.jpg), [8](screenshots/building-review-8.jpg), [9](screenshots/building-review-9.jpg), [10](screenshots/building-review-10.jpg), and [market footprints](screenshots/footprints.jpg).
- [Valid placement](screenshots/placement.jpg), [blocked placement](screenshots/blocked-placement.jpg), [shop](screenshots/shop.jpg), [building card](screenshots/building-card.jpg), and [reward](screenshots/reward.jpg).

`art/manifest.json` records hashes for every runtime file. Update it with `python3 games/christmas-market/tools/check_assets.py --update` only alongside the corresponding catalogue/source changes. The full native build with `-Werror`, rule tests, Lua lint (59 files, zero warnings), inventory checks and real-input game smoke pass on macOS. Linux Xvfb, WebAssembly and iOS Simulator coverage run in CI.

## Engine match-3 atlas and trickling

`data/match3.png`, registered by `lua/match3_skin.lua` and
`art/match3-atlas.json`, contains all match-board backgrounds, pieces, special
axes, blockers, selection/hint/guide frames, HUD icons and all five authored
states of each tool and Pause. The Christmas override additionally contains
its board portrait; Relic Rush includes all three piece packs and both scenes.
Existing source artwork and alpha are copied without modifying states. The
64px cubic radial light is the existing procedural transient effect, packed
in the same atlas and drawn with a per-view additive flag.

The engine's default resource skin is independent and embedded; both games
normally override it. `python3 tools/match3_atlas.py` reproduces the atlases and
registrations, and `make gen` embeds the default. No new game icon designs were
generated. FALL uses engine-authored simultaneous one-edge movement steps,
diagonal priority, upstream inlets and a short landing squash; static states
continue to use the existing artwork. Input and animation timing are shared.

See [checked in-game captures and commands](review/trickling/README.md) and the
[engine contract](../../../docs/MATCH3_ENGINE.md). The default atlas's source,
prompt, all supported states and crop/rotation registration are catalogued in
`engine/art/match3/manifest.json` at repository root.


### Cell registration and dialogue motion

Board state canvases now span the complete hex diameter. The authored 112px
piece interior on a 128px canvas is registered explicitly: hex silhouettes fill
the hex, other objects fit its inscribed square. Guide and HUD sizes retain their
own registration. Artwork and its alpha remain unchanged. Reproduce the reviewed
boards with the test suite's `resource-icons`, `atlas-` and `trickling-` filters.

Portraits retain finite entrance/exit slides and fades. An independent colour
tween brightens/dims active/listener states without replaying the slide. Size is
constant for speaker/listener, with no scale/rotation animation or idle wobble. See [motion, captures and timing review](../../../docs/review/motion/README.md).
