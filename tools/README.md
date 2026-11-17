# Tools

Every script that builds, checks or studies the games, in one list. Run them
from the repository root. `make test-assets` fails if a script under `tools/`
or `games/*/tools/` is missing from this page (`tests/test_tools_index.py`).

**Where things live**

| Folder | Holds |
| --- | --- |
| `tools/` | Shared by more than one game, or by the engine |
| `tools/reference/` | Studying other games (Cradle of Rome, June's Journey, Tropicats) from local, git-ignored extractions in `reference/` |
| `tools/xcode/` | Xcode projects and device runs |
| `games/<game>/tools/` | One game's art registration, story compilation and asset checks |
| `tests/lua/` | Lua tools that run inside a test build: the move tuner and the balance runner (see [Levels and balance](#levels-and-balance)) |

## Engine, build and tests

| Script | What it does | Run |
| --- | --- | --- |
| `luagen.py` | Writes the engine's Lua glue, reference and editor annotations from `engine/api.xml` | `make gen` (`make gen-check` in CI) |
| `unity.sh` | Emits a unity translation unit for the Xcode builds | used by `Makefile` and `tools/xcode/generate.py` |
| `run_tests.py` | Runs every assertion suite once beside the script checks, within a wall-clock budget | `make test` |
| `test_run_tests.py` | Failure, deadline and coverage contracts of `run_tests.py` | CI |
| `test_web.py` | Runs the WebGL builds in Chromium (Playwright) | CI |
| `screenshots.py` | Turns the pictures a test build rendered into documentation images; starts no game | `make shots` |
| `make_reels.py` | Assembles reels from the frames `screenshots.py` collected | `python3 tools/make_reels.py` |
| `requirements-assets.txt` | Python packages the art tools need (Pillow, NumPy, SciPy) | `pip install -r tools/requirements-assets.txt` |
| `xcode/generate.py` | Generates `games/<game>/<game>.xcodeproj` | `make xcode` |
| `xcode/deploy.py` | Builds, installs and launches a game on a connected iPhone or iPad | `make ios GAME=relic-rush` |
| `xcode/smoke.py` | Launches each built game in an iOS Simulator and requires a frame | `python3 tools/xcode/smoke.py` |
| `xcode/test_deploy.py` | Device selection, signing and deploy failure cases | `make test-ios-deploy` |

## City buildings and roads

The city camera is defined once in `engine/engine.h`; `city_camera.py` reads it
for every art tool. [docs/BUILDINGS.md](../docs/BUILDINGS.md) and
[docs/BUILDING_ART.md](../docs/BUILDING_ART.md) are the guides.

| Script | What it does | Run |
| --- | --- | --- |
| `buildings.py` | Renders a game's buildings by name with Scener (or Blender) and writes `lua/building_sprites.lua` | `make buildings GAME=relic-rush KEYS="lodge well"` |
| `building_kit.py` | The Blender modelling kit every game's `art/building-catalogue/build_scene.py` uses | imported |
| `scener_kit.py` | The same kit drawn with Scener primitives | imported |
| `scener_buildings.py` | Builds Scener scenes from a game's `build_scene.py` | imported by `buildings.py` |
| `render_buildings_blender.py` | Runs inside Blender for `buildings.py --blender` | `make buildings BLENDER=1` |
| `painted_foundations.py` | Registers painted slab textures to a model's ground polygon | imported |
| `import_painted_buildings.py` | Imports reviewed paint-overs and registers their foundations | `python3 tools/import_painted_buildings.py <game>` |
| `footprint.py` | Measures a sprite's ground footprint for art not rendered from the master | `python3 tools/footprint.py <sprite> --overlay out.png` |
| `city_camera.py` | The camera's yaw, elevation and tile slopes, read from `engine/engine.h` | imported |
| `roads.py` | Renders a game's road tiles for the city camera | `python3 tools/roads.py <game>` |

## Match-3 art

[docs/MATCH3_ART_GENERATION.md](../docs/MATCH3_ART_GENERATION.md) and the
hex registration in [engine/art/hex-tile](../engine/art/hex-tile/README.md)
are the guides.

| Script | What it does | Run |
| --- | --- | --- |
| `match3_atlas.py` | Builds and checks the engine skin and each game's single-texture override | `python3 tools/match3_atlas.py` (`--check` in `make test-assets`) |
| `match3_elements_art.py` | Registers the authored 48-state blocker and tablet atlas | `--check` in `make test-assets` |
| `match3_theme_art.py` | Registers each portrait game's board-theme sheet | imported by `match3_atlas.py` |
| `pack_particles.py` | Registers particle frames in the match-3 atlas | imported by `match3_atlas.py` |
| `match3_buttons.py` | Prepares the Pause plate and packs the shared campaign actions; uses `games/relic-rush/tools/prepare_bonus_gems.py` for the button recipe | `python3 tools/match3_buttons.py` |
| `board_tiles.py` | Bakes the shared board tiles into hex sprites for every game | `--render-check` in `make test-assets` |
| `board_grain.py` | Tileable grain texture for the board tiles | imported by `board_tiles.py` |
| `board_frame.py` | Bakes the hex border atlas and its registration guide | `python3 tools/board_frame.py --output build/board-frame` |
| `board_frame_decor.py` | Registers separately painted board decorations | imported by `board_frame.py` |
| `hex_tile_art.py` | Checks sprites against the engine's flat-top tile face | `python3 tools/hex_tile_art.py <art.png> --mode fill --strict` |
| `artkit.py` | Shared Pillow and NumPy helpers for the art scripts | imported |

## Levels and balance

[docs/LEVEL_DESIGN.md](../docs/LEVEL_DESIGN.md) is the guide.

| Script | What it does | Run |
| --- | --- | --- |
| `hex_levels.py` | Validates the hex level files, prints a board, writes `lua/boards.lua` and the overview sheets | `python3 tools/hex_levels.py relic-rush --lua`; `make level-sheets` |
| `tune_moves.py` | Fits each board's move budget to its tier with the reference bot; writes `lua/level_moves.lua` and `docs/level-moves.md` | `python3 tools/tune_moves.py relic-rush` |
| `tests/lua/tune_moves.lua` | The bot side of `tune_moves.py` | run by `tune_moves.py` |
| `tests/lua/greedy_bot.lua` | The reference bot shared by the tuner and the balance runner | required |
| `tests/lua/relic_balance.lua` | Plays every Relic Rush board, reports income and fits restoration prices | `BALANCE_RUNS=10 build/test/relic-rush --extended "rules relic_balance"` |

## Review captures and story

| Script | What it does | Run |
| --- | --- | --- |
| `capture_match3_default.py` | Captures match-3 atlas reviews, one start per game | `python3 tools/capture_match3_default.py` |
| `capture_resource_icons.py` | Captures resource and hex review cases | `python3 tools/capture_resource_icons.py` |
| `capture_trickling.py` | Captures vertical and diagonal refill reviews | `python3 tools/capture_trickling.py` |
| `capture_economy_review.py` | Captures economy before/after comparisons with the native renderer | `python3 tools/capture_economy_review.py --before-ref <sha>` |
| `scenario_overview.py` | One HTML page of every game's cast, boards and story beats | `python3 tools/scenario_overview.py --capture` |
| `scenario_dump.lua` | Prints a game's scenario data as JSON for `scenario_overview.py` | run by `scenario_overview.py` |

## Studying other games: `tools/reference/`

These read local extractions under `reference/` (git-ignored; each has a
`SOURCE.txt`) and write the docs in `docs/*-reference/`.

| Script | What it does | Run |
| --- | --- | --- |
| `cradle-of-rome/extract_pak.py` | Unpacks a Cradle of Rome `resources.pak` | `python3 tools/reference/cradle-of-rome/extract_pak.py <resources.pak> <new dir>` |
| `cradle-of-rome/analyze.py` | Inspects board, piece and construction tables | `python3 tools/reference/cradle-of-rome/analyze.py` |
| `cradle-of-rome/level_data.py` | Exports every level as design data: `docs/cradle-of-rome-reference/levels.json` and `LEVELS.md` | `python3 tools/reference/cradle-of-rome/level_data.py [--check]` |
| `cradle-of-rome/export_art.py` | Exports the XML-defined board artwork | `python3 tools/reference/cradle-of-rome/export_art.py` |
| `cradle-of-rome/export_economy.py` | Exports Cradle of Rome 2's economy tables | `python3 tools/reference/cradle-of-rome/export_economy.py` |
| `cradle-of-rome/export_cell_hint_particles.py` | Extracts the cell hint's two embedded PNGs | `python3 tools/reference/cradle-of-rome/export_cell_hint_particles.py` |
| `extract_junes_scenes.py` | Extracts June's Journey chapter 1 sprites and scene data (UnityPy) | see [docs/JUNES_JOURNEY_ANALYSIS.md](../docs/JUNES_JOURNEY_ANALYSIS.md) |
| `junes-viewer/` | Browser viewer for the extracted June's Journey scenes (`serve.py`, `scene_data.py`, `test_scene_data.py`) | `python3 tools/reference/junes-viewer/serve.py` |
| `inspect_tropicats.py` | Audits a locally owned Tropicats app and its level bundles | see [docs/TROPICATS_ANALYSIS.md](../docs/TROPICATS_ANALYSIS.md) |
| `tropicats_board_analysis.py` | Summarizes Tropicats campaign tiers | `python3 tools/reference/tropicats_board_analysis.py` |
| `tropicats_story_reference.py` | Generates the Tropicats campaign reference or looks up a level or scene | `python3 tools/reference/tropicats_story_reference.py --level 12` |
| `tropicats-viewer/` | Browser viewer for Tropicats art and boards (`serve.py`, `extract_art.py`, `materials.py`, `mechanics.py`, `skeleton.py`, tests) | `python3 tools/reference/tropicats-viewer/serve.py` |

## One game's tools: `games/<game>/tools/`

| Script | What it does |
| --- | --- |
| **relic-rush** | |
| `prepare_assets.py` | Builds `data/` from the source paintings in `art/` |
| `board_assets.py` | Registers authored board artwork (crop, rotate, resize); `--check` in `make test-assets` |
| `check_art_catalogue.py` | Fails on uncatalogued runtime files, rule kinds or states (`make test-assets`) |
| `prepare_buildings.py` | Builds the catalogue around the rendered building sprites (after `tools/buildings.py`) |
| `prepare_bonus_gems.py` | Bonus button states from a painted base and the icons; also the recipe `tools/match3_buttons.py` uses |
| `prepare_resource_pieces.py` | Registers match pieces and wallet icons |
| `prepare_result_icons.py` | Registers the two result icons |
| `prepare_hud.py` | Registers the expedition HUD atlas (`--check` in `make test-assets`) |
| `prepare_finale_art.py` | Registers the signal plate and the landing scene |
| `prepare_story.py` | Compiles the reviewed story's lines; `--check` detects drift |
| `relic_quest_art.py` | Registers quest icons, item cards and story pieces |
| `capture_buildings.py` | Real-game before/after captures for building art and shadows |
| `capture_cell_mask.py` | Captures the game's real hex geometry |
| **christmas-market** | |
| `prepare_assets.py` | Registers ImageGen artwork with crops, resizes and board masks |
| `fit_match3_edges.py` | Hex-edge remapping for the tinsel ring, used by `prepare_assets.py` |
| `check_assets.py` | Checks shipped inventory, state coverage and icon exports (`make test-assets`) |
| `prepare_catalogue.py` | Builds the catalogue around the rendered sprites (`--check` in `make test-assets`) |
| `prepare_bonus_buttons.py` | Circular boosters with the shared painted-button recipe |
| `prepare_market_goods.py` | Registers the market pieces in one 4x4 atlas |
| `prepare_character.py` | Resizes the character cutout and the app-icon master |
| `prepare_hud.py` | Exports the navigation cells |
| `prepare_story.py` | Compiles the reviewed story's lines; `--check` detects drift |
| `prepare_story_cast.py` | Registers the five story busts (`--check` in `make test-assets`) |
| `prepare_story_pieces.py` | Fits the six story objects on the chip canvas |
| **nile-archive** | |
| `prepare_catalogue.py` | Builds the catalogue around the rendered sprites (after `tools/buildings.py`) |
| `import_buildings.py` | Recreates the colour-key building atlas from the accepted cutouts |
| `make_icons.py` | Draws the coin and influence icons |
| **emergency** | |
| `check_assets.py` | Checks every shipped asset against the provenance catalogue (`make test-assets`) |
| `screenshots.py` | Renders the campaign and simulation stages with the shared launcher |
| `prepare_app_icon.py` | Exports atlas artwork to the iOS and macOS app icons |
| `import_episode.py` | One-time source migration |
| `preserve_source.py` | Preserves an Emergency checkout before retiring it |

## Adding a tool

1. **Pick the folder.** Used by one game: `games/<game>/tools/`. Used by more
   than one game or by the engine: `tools/`. Reads another game's data:
   `tools/reference/`. A Lua tool that needs the game's rules runs inside the
   test build, as `tests/lua/<name>.lua`, registered with `rules("<name>")` in
   `tests/games/<game>.lua` and guarded so a plain `make test` skips it (see
   `tests/lua/tune_moves.lua`). Never start a game per case from a script loop.
2. **Start with a docstring** whose first line says what the tool does, then
   how to run it. Find the repository from the file
   (`ROOT = Path(__file__).resolve().parents[N]`), never from the working
   directory.
3. **Generated files get a `--check`** that fails when they are stale. Add it
   to `make test-assets` if a stale file would ship.
4. **Add a row to this page** in the right section. `make test-assets` fails
   until you do. Put temporary output in `build/`, never in the tree.
5. **Name the module uniquely.** The test build puts every game's `lua/` and
   `tests/lua/` on one search path, so a Lua file in `tests/lua/` must not share
   a name with a game module.
