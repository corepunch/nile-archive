# Instructions for coding agents

## Pull requests: always show screenshots

Every pull request that can change what a player sees must include screenshots in its description. That covers UI, layout, art, text, dialogue, effects and engine drawing code. Add them whenever it is possible at all. When it isn't, for example a pure build or test change, say so in one line.

- **Show the changed screens.** Include every screen the change touches, with before and after shots side by side when something existing changed.
- **Cover the sizes the change affects.** Nile Archive and Volcano are iPad landscape (1200×900, 1368×1026). Relic Rush is a 480×900 phone portrait. Add a 16:9 or a 390×844 shot when the layout adapts to it.
- **Capture the game itself.** Every game renders headlessly with the software renderer:

  ```sh
  make
  Xvfb :99 -screen 0 2000x1400x24 &            # or prefix each command with xvfb-run -a
  export DISPLAY=:99 LIBGL_ALWAYS_SOFTWARE=1
  ./build/nile-archive --headless --mute --fresh --size 1200x900 --screen island --shot out.png
  make shots                                   # re-renders every documentation screenshot
  ```

  Each game has entry points for its screens: Nile Archive takes `--screen …`, Relic Rush `--level`, `--city`, `--dialog …` and others, and Volcano `--level`, `--pause` and `--preview`. Pass `--frames N` for a later frame, for example once dialogue has finished typing.
- **Embed images, don't just link them.** Commit the screenshots under `games/<game>/docs/screenshots/`, or another tracked path when they are only for review. Reference them in the description with URLs pinned to the pushed commit, so they keep showing what was reviewed:

  ```markdown
  ![Island](https://github.com/corepunch/nile-archive/blob/<commit-sha>/games/nile-archive/docs/screenshots/island.jpg?raw=true)
  ```

  A table puts before and after next to each other.
- **Check them first.** Look at every screenshot before posting it. A half-typed line, an empty frame or a missing texture is a bug to fix, not a picture to post.

## City buildings: tiles, size and pivot

Buildings stand on an isometric grid of whole tiles. [docs/BUILDINGS.md](docs/BUILDINGS.md) is the spec. Read it before you add or change a building, its sprite, `city.tile` or the placement code.

- **Give every building three measurements.** These are `size`, its footprint in whole tiles (`size2(2, 2)`, `size2(3, 2)`, …), `pivot`, the sprite pixel of the footprint's ground centre, and `base_width`, the base's width in sprite pixels from its left corner to its right one. Don't size a building with `height`, and don't sink or nudge the sprite to fit. Wrong numbers put the building beside its footprint, which is the bug this spec exists to prevent.
- **Measure, don't guess.** Run `python3 tools/footprint.py <sprite> --overlay out.png` and look at the overlay. Pass `--bottom`, `--left` and `--right` when plants or props fool the automatic fit. Round the side ratio it prints to whole tiles.
- **Check in the game.** Render the island with `--footprints` (Relic Rush `--showcase --footprints`, Nile Archive `--screen island --footprints`) and look at it. Every diamond must sit on its building's base, with the pivot dot at the base's centre. Post that shot in the pull request whenever building specs change.
- **Keep one tile per game.** `city.tile` is set before `c:init`, and changing it changes every building's drawn size. When you change it, re-check all the game's buildings.
- **Space buildings with `city.clearance`, not `size`.** `size` is the base the art shows. To keep buildings further apart, raise `city.clearance`, which adds tiles around every base. Don't inflate `size` for that: it scales the sprite up.
- **Snap with the type.** Pass the building type to `city_snap` / `c:snap(p, type)` so the footprint lands on whole tiles. Points you hand-place on the island (seed buildings, showcase spots) should go through it too.

## Repository conventions

- **Catalogue every visual addition in the same PR.** For Relic Rush, update `games/relic-rush/docs/asset-catalogue.md`, the runtime inventory and state mapping in `games/relic-rush/art/board-states/manifest.json`, and the runtime contract in `lua/art.lua` when applicable. Other games must maintain an equivalent catalogue in their `docs/`. Record rule meaning, every supported visual/interaction state, source/prompt, runtime path, reproduction command and reviewed in-game capture. New kinds, powerups, blockers, skins, effects and temporary visual fallbacks all count.
- **Audit artwork before handing it over.** Compare rule/state definitions with the catalogue; inspect all packs, blocker strengths, special axes and normal/selected/pressed/hover/disabled controls in actual game captures. Run `make test` and the game's asset checks. A screenshot of only an ordinary opening board does not cover specials or exhausted tools.
- **Track gaps immediately.** If the audit finds placeholder art, a missing state, an uncatalogued asset or a visual defect that will remain, create or link a GitHub issue before handoff. Record the issue in the catalogue with concrete missing states and acceptance criteria; do not silently ship geometry, tinting, or reused artwork as a finished state. When fixed, close the issue through the PR.
- **Author state artwork together.** Generate an icon set and all required interaction states in one ImageGen atlas. Preserve authored alpha; do not manufacture states with recolouring, tint filters or procedural glyph overlays. Spatial crop/rotation/resize registration may align existing artwork to slots; preserve its design and record the transform. Hex states must match the board slot's size, centre and flat-top orientation. Animation transforms and transient beams/particles may remain procedural when explicitly catalogued.

- **Build and test before pushing.** Run `make CFLAGS="-O2 -g -Werror"`, `make test`, `make lint` (luacheck; `.luacheckrc` declares the engine's globals, so an undefined global is a typo and an unused local is dead code) and each affected game's `--smoke` run under Xvfb. CI runs the same checks.
- **Regenerate generated code.** After editing `engine/api.xml`, run `make gen`, and commit the generated files.
- **Keep reusable UI in the engine.** Use `ui.form` templates, bindings and `ui.modals` for new reusable dialogs. Games provide skins, data and command handling; layout, hit testing, keyboard focus, data exchange and modal layering belong in `engine/ui_forms.lua` / `engine/ui.c`. Extend the engine for missing behaviour instead of cloning it into a game. Skin callbacks paint controls and do not implement their input logic. Document new controls/states in `docs/UI_ENGINE.md`, and cover them in form and renderer/input tests.
- **Use measured rows for repeated UI.** Populate engine `list` nodes with `form:set_items` and stable keys; keep titles, descriptions and icons in one data source. Icon-and-copy rows left-align both labels; iconless copy may centre. Measure wrapped text after allocating icon width. Check source refresh/reorder/removal and actual input at every affected size. Dialogue badges anchor to `story.bubble_bounds`, and bubble padding includes the decorative outline rather than adding it twice. Centre framed phone portraits and bubbles together using their visible bounds within the safe screen; include any listener and keep Skip attached to the group.
- **Regenerate embedded UI code.** Changes to `engine/ui_forms.lua` also require `make gen`; commit `engine/ui_forms_lua.h`. Never edit that generated header directly. Verify Gaussian blur on fine text and high-frequency detail, including resize, nested layers, clips and safe areas; retain the GPU target cache and measure performance.
- **Keep building pickup deliberate.** Use the shared city mover: a stationary 0.5-second hold picks up a placed building; an ordinary drag pans even when it starts over a building. Movement, pinch, UI capture and pointer/focus cancellation must discard the pending hold. Release only snaps a preview: expose Confirm/Cancel, preserve the original position and wallet until confirmation, and consume a pickup's release so it cannot also open/collect the building or activate newly shown controls. Continue city updates with idle input while a modal blocks it. Cover real press/move/release input in every movable city game.
- **Keep the docs in step.** Update a game's README and `docs/` when its interface or rules change.
