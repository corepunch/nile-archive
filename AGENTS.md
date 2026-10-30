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

## Repository conventions

- **Catalogue every visual addition in the same PR.** For Relic Rush, update `games/relic-rush/docs/asset-catalogue.md`, the runtime inventory and state mapping in `games/relic-rush/art/board-states/manifest.json`, and the runtime contract in `lua/art.lua` when applicable. Other games must maintain an equivalent catalogue in their `docs/`. Record rule meaning, every supported visual/interaction state, source/prompt, runtime path, reproduction command and reviewed in-game capture. New kinds, powerups, blockers, skins, effects and temporary visual fallbacks all count.
- **Audit artwork before handing it over.** Compare rule/state definitions with the catalogue; inspect all packs, blocker strengths, special axes and normal/selected/pressed/hover/disabled controls in actual game captures. Run `make test` and the game's asset checks. A screenshot of only an ordinary opening board does not cover specials or exhausted tools.
- **Track gaps immediately.** If the audit finds placeholder art, a missing state, an uncatalogued asset or a visual defect that will remain, create or link a GitHub issue before handoff. Record the issue in the catalogue with concrete missing states and acceptance criteria; do not silently ship geometry, tinting, or reused artwork as a finished state. When fixed, close the issue through the PR.
- **Author state artwork together.** Generate an icon set and all required interaction states in one ImageGen atlas. Preserve authored alpha; do not manufacture states with recolouring, tint filters or procedural glyph overlays. Spatial crop/rotation/resize registration may align existing artwork to slots; preserve its design and record the transform. Hex states must match the board slot's size, centre and flat-top orientation. Animation transforms and transient beams/particles may remain procedural when explicitly catalogued.

- **Build and test before pushing.** Run `make CFLAGS="-O2 -g -Werror"`, `make test`, and each affected game's `--smoke` run under Xvfb. CI runs the same checks.
- **Regenerate generated code.** After editing `engine/api.xml`, run `make gen`, and commit the generated files.
- **Keep reusable UI in the engine.** Use `ui.form` templates, bindings and `ui.modals` for new reusable dialogs. Games provide skins, data and command handling; layout, hit testing, keyboard focus, data exchange and modal layering belong in `engine/ui_forms.lua` / `engine/ui.c`. Extend the engine for missing behaviour instead of cloning it into a game. Skin callbacks paint controls and do not implement their input logic. Document new controls/states in `docs/UI_ENGINE.md`, and cover them in form and renderer/input tests.
- **Regenerate embedded UI code.** Changes to `engine/ui_forms.lua` also require `make gen`; commit `engine/ui_forms_lua.h`. Never edit that generated header directly. Verify Gaussian blur on fine text and high-frequency detail, including resize, nested layers, clips and safe areas; retain the GPU target cache and measure performance.
- **Keep the docs in step.** Update a game's README and `docs/` when its interface or rules change.
