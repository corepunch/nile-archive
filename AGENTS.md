# Instructions for coding agents

## Pull requests: always show screenshots

Every pull request that can change what a player sees must include screenshots in its description. That covers UI, layout, art, text, dialogue, effects and engine drawing code. Add them whenever it is possible at all. When it isn't, for example a pure build or test change, say so in one line.

- **Show the changed screens.** Include every screen the change touches, with before and after shots side by side when something existing changed.
- **Cover the sizes the change affects.** Nile Archive and Volcano are iPad landscape (1200×900, 1368×1026). Relic Rush and Christmas Market are 480×900 phone portraits. Add a 16:9 or a 390×844 shot when the layout adapts to it.
- **Capture the game itself.** Every game renders headlessly with the software renderer:

  ```sh
  make
  Xvfb :99 -screen 0 2000x1400x24 &            # or prefix each command with xvfb-run -a
  export DISPLAY=:99 LIBGL_ALWAYS_SOFTWARE=1
  ./build/nile-archive --headless --mute --fresh --size 1200x900 --screen island --shot out.png
  make shots                                   # re-renders every documentation screenshot
  make smoke                                   # every game's smoke run
  ```

  Each game has entry points for its screens: Nile Archive takes `--screen …`, Relic Rush `--level`, `--city`, `--dialog …` and others, and Volcano `--level`, `--pause` and `--preview`. Pass `--frames N` for a later frame, for example once dialogue has finished typing.
- **Embed images, don't just link them.** Commit the screenshots under `games/<game>/docs/screenshots/`, or another tracked path when they are only for review. Reference them in the description with URLs pinned to the pushed commit, so they keep showing what was reviewed:

  ```markdown
  ![Island](https://github.com/corepunch/nile-archive/blob/<commit-sha>/games/nile-archive/docs/screenshots/island.jpg?raw=true)
  ```

  A table puts before and after next to each other.
- **Check them first.** Look at every screenshot before posting it. A half-typed line, an empty frame or a missing texture is a bug to fix, not a picture to post.

## Tests: one start per game

`make test` compiles a test build (`-DENGINE_TEST`) and runs each suite once: `build/test/engine`, `build/test/relic-rush`, `build/test/nile-archive`, `build/test/christmas-market` and `build/test/volcano`. One start runs that suite's C tests, Lua rules, smoke runs, screens and gestures. [docs/TESTING.md](docs/TESTING.md) is the guide.

- **Never start a game per test or per screen.** Don't loop over `subprocess.run` or a shell `for`. Add a line to `tests/games/<game>.lua`, and run only part of a suite by name: `build/test/relic-rush smoke`.
- **Tests stay small.** C tests use `TEST`, `CHECK` and `NEAR`. Lua tests use the global `check` and `near`. Anything else a test needs belongs in the test build, as `#ifdef ENGINE_TEST` in the engine or in `engine/test_runner.c`, not as boilerplate in each test.
- **A failure ends its test, never the run.** Every test reports PASS or FAIL with its file and line, and the summary lists what failed.
- **New engine state must reset.** Every test shares the process, so a static that outlives a run leaks into the next. Clear it from `app_run` under `ENGINE_TEST`, as `ui_restart` does.

## The city camera: never 2:1

Every city game sees its ground through one camera. **It is orthographic, turned 30° from the tile axes (yaw) and looking down at 40° (elevation).** It is not 2:1 isometric and tiles are not symmetric diamonds: one tile side runs 73.5 right and 27.3 down for every 42.4 left and 47.2 down of the other, at 85 px per tile side (slopes of 0.371 and 1.114). World Z shrinks by 0.766. Getting this wrong puts every building beside its footprint.

- **There is one definition.** `CITY_CAMERA_YAW` and `CITY_CAMERA_ELEVATION` in `engine/engine.h` set the engine's projection, and `tools/city_camera.py` reads those two lines for all art tools. Never write the angles or slopes anywhere else in code. `make test` fails when a game's rendered art doesn't match them.
- **Model for it.** In Blender, X is tile u (the front-left side, `size.w`) and Y is -v (the front-right side, `size.h`). The camera sees faces towards **-Y** best and towards **+X** second, so a building's main facade, door and steps go on -Y.
- **Sprites come from Blender, not paint.** A painting or paint-over is locked to the angle it was drawn from and can't be turned, so a building needs a model before it has art.
- **Re-render by name.** A building's Blender collection name is its key and its file name.

  ```sh
  make buildings GAME=relic-rush                 # every building in the game
  make buildings GAME=relic-rush KEYS="lodge well"
  make buildings GAME=relic-rush REBUILD=1       # after editing build_scene.py
  ```

  Look at the review sheet it writes, `games/<game>/docs/screenshots/buildings.jpg`, then at the game.
- **Changing the camera means re-rendering every game.** Change the two defines, run `make buildings` for each game, and reshoot.

## City buildings: tiles, size and pivot

Buildings stand on a grid of whole tiles. [docs/BUILDINGS.md](docs/BUILDINGS.md) is the spec. Read it before you add or change a building, its sprite, `city.tile` or the placement code.

- **Give every building three measurements.** These are `size`, its footprint in whole tiles (`size2(2, 2)`, `size2(3, 2)`, …), `pivot`, the sprite pixel of the footprint's ground centre, and `base_width`, the base's width in sprite pixels from its left corner to its right one. Don't size a building with `height`, and don't sink or nudge the sprite to fit. Wrong numbers put the building beside its footprint, which is the bug this spec exists to prevent.
- **Let the pipeline measure.** `tools/buildings.py` writes exact registration for every render into `lua/building_sprites.lua`; never edit that file. Only art not rendered from the master needs `python3 tools/footprint.py <sprite> --overlay out.png`, which knows the camera's slopes.
- **Make Blender building art by the guide.** [docs/BUILDING_ART.md](docs/BUILDING_ART.md) covers catalogue rows (append only: the row order is save data), modelling on the grid, rendering by name, checks and the review gallery.
- **Check in the game.** Render the island with `--footprints` (Relic Rush and Christmas Market `--showcase --footprints`, Nile Archive `--screen island --footprints`) and look at it. Every parallelogram must sit on its building's base, with the pivot dot at the base's centre. Post that shot in the pull request whenever building specs change.
- **Keep one tile per game.** `city.tile`, a tile's side in world units, is set before `c:init`, and changing it changes every building's drawn size. When you change it, re-check all the game's buildings.
- **Space buildings with `city.clearance`, not `size`.** `size` is the base the art shows. To keep buildings further apart, raise `city.clearance`, which adds tiles around every base. Don't inflate `size` for that: it scales the sprite up.
- **Snap with the type.** Pass the building type to `city_snap` / `c:snap(p, type)` so the footprint lands on whole tiles. Points you hand-place on the island (seed buildings, showcase spots) should go through it too.

## Repository conventions

- **Catalogue every visual addition in the same PR.** For Relic Rush, update `games/relic-rush/docs/asset-catalogue.md`, the runtime inventory and state mapping in `games/relic-rush/art/board-states/manifest.json`, and the runtime contract in `lua/art.lua` when applicable. Other games must maintain an equivalent catalogue in their `docs/`. Record rule meaning, every supported visual/interaction state, source/prompt, runtime path, reproduction command and reviewed in-game capture. New kinds, powerups, blockers, skins, effects and temporary visual fallbacks all count.
- **Audit artwork before handing it over.** Compare rule/state definitions with the catalogue; inspect all packs, blocker strengths, special axes and normal/selected/pressed/hover/disabled controls in actual game captures. Run `make test` and the game's asset checks. A screenshot of only an ordinary opening board does not cover specials or exhausted tools.
- **Track gaps immediately.** If the audit finds placeholder art, a missing state, an uncatalogued asset or a visual defect that will remain, create or link a GitHub issue before handoff. Record the issue in the catalogue with concrete missing states and acceptance criteria; do not silently ship geometry, tinting, or reused artwork as a finished state. When fixed, close the issue through the PR.
- **Author state artwork together.** Generate an icon set and all required interaction states in one ImageGen atlas. Preserve authored alpha; do not manufacture states with recolouring, tint filters or procedural glyph overlays. Spatial crop/rotation/resize registration may align existing artwork to slots; preserve its design and record the transform. Hex states must match the board slot's size, centre and flat-top orientation. Animation transforms and transient beams/particles may remain procedural when explicitly catalogued.

- **Build and test before pushing.** Run `make CFLAGS="-O2 -g -Werror"`, `make test` (under Xvfb on Linux) and `make lint` (luacheck; `.luacheckrc` declares the engine's globals, so an undefined global is a typo and an unused local is dead code). CI runs the same checks.
- **Regenerate generated code.** After editing `engine/api.xml`, run `make gen`, and commit the generated files.
- **Keep reusable UI in the engine.** Use `ui.form` templates, bindings and `ui.modals` for new reusable dialogs. Games provide skins, data and command handling; a game's look belongs in its skin file (`ui.skin`, see `docs/UI_ENGINE.md#skins`): add a state, variant or text style there instead of new paint code; layout, hit testing, keyboard focus, data exchange and modal layering belong in `engine/ui_forms.lua` / `engine/ui.c`. Extend the engine for missing behaviour instead of cloning it into a game. Skin callbacks paint controls and do not implement their input logic. Document new controls/states in `docs/UI_ENGINE.md`, and cover them in form and renderer/input tests.
- **Use measured rows for repeated UI.** Populate engine `list` nodes with `form:set_items` and stable keys; keep titles, descriptions and icons in one data source. Icon-and-copy rows left-align both labels; iconless copy may centre. Measure wrapped text after allocating icon width. Check source refresh/reorder/removal and actual input at every affected size. Dialogue badges anchor to `story.bubble_bounds`, and bubble padding includes the decorative outline rather than adding it twice. Centre framed phone portraits and bubbles together using their visible bounds within the safe screen; include any listener and keep Skip attached to the group.
- **Regenerate embedded UI code.** Changes to `engine/ui_forms.lua` or `engine/city_smoke.lua` also require `make gen`; commit `engine/ui_forms_lua.h`. Never edit that generated header directly. Verify Gaussian blur on fine text and high-frequency detail, including resize, nested layers, clips and safe areas; retain the GPU target cache and measure performance.
- **Keep building pickup deliberate.** Use the shared city mover: a stationary 0.5-second hold picks up a placed building; an ordinary drag pans even when it starts over a building. Movement, pinch, UI capture and pointer/focus cancellation must discard the pending hold. Release only snaps a preview: expose Confirm/Cancel, preserve the original position and wallet until confirmation, and consume a pickup's release so it cannot also open/collect the building or activate newly shown controls. Continue city updates with idle input while a modal blocks it. Cover real press/move/release input in every movable city game: drive `city.move_test` (engine/city_smoke.lua) from the game's `--smoke` run, which checks the pan, the hold, the uncommitted preview, Cancel and Confirm once for every game.
- **Keep the docs in step.** Update a game's README and `docs/` when its interface or rules change.
