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

The city camera is defined once in `engine/src/engine.h`; `city_camera.py` reads it
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
| `city_camera.py` | The camera's yaw, elevation and tile slopes, read from `engine/src/engine.h` | imported |
| `roads.py` | Renders a game's road tiles for the city camera | `python3 tools/roads.py <game>` |

## Match-3 art

[docs/MATCH3_ART_GENERATION.md](../docs/MATCH3_ART_GENERATION.md) and the
hex registration in [engine/art/hex-tile](../engine/art/hex-tile/README.md)
are the guides.

| Script | What it does | Run |
| --- | --- | --- |
| `match3_atlas.py` | Packs the engine's and each game's registered sprites into one atlas per kind (`data/board/<kind>.png`, see [Asset layout](../docs/ASSET_LAYOUT.md)) | `python3 tools/match3_atlas.py` (`--check` in `make test-assets`) |
| `match3_elements_art.py` | Registers the authored 48-state blocker and tablet atlas | `--check` in `make test-assets` |
| `match3_theme_art.py` | Registers each portrait game's board-theme sheet | imported by `match3_atlas.py` |
| `pack_particles.py` | Registers particle frames for the `fx` atlas | imported by `match3_atlas.py` |
| `pack_match_specials.py` | Repack the authored optional match specials for both games | `python3 tools/pack_match_specials.py` |
| `match3_buttons.py` | Centers each campaign action icon in its 128 px button cell using the silhouette's pixel opacity | `python3 tools/match3_buttons.py`, then `python3 tools/match3_atlas.py` to repack |
| `board_tiles.py` | Bakes the shared board tiles into hex sprites for every game | `--render-check` in `make test-assets` |
| `board_grain.py` | Tileable grain texture for the board tiles | imported by `board_tiles.py` |
| `board_frame.py` | Bakes the hex border atlas and its registration guide | `python3 tools/board_frame.py --output build/board-frame` |
| `square_board_frame.py` | Bakes painted oak and textured sandstone into square perimeter modules and compares the eight winter materials | imported by `match3_atlas.py` or `python3 tools/square_board_frame.py --review build/square-frames.jpg` |
| `board_frame_decor.py` | Registers separately painted board decorations | imported by `board_frame.py` |
| `hex_tile_art.py` | Checks sprites against the engine's flat-top tile face | `python3 tools/hex_tile_art.py <art.png> --mode fill --strict` |
| `artkit.py` | Shared Pillow and NumPy helpers for the art scripts | imported |

## Levels and balance

[docs/LEVEL_DESIGN.md](../docs/LEVEL_DESIGN.md) is the guide.

| Script | What it does | Run |
| --- | --- | --- |
| `balance.py` | One run that sets every fitted value: compiles the boards, fits the move budgets, fits both games' twenty purchase prices to the bot's measured income (Relic Rush writes `art/building-catalogue/story.json`, Christmas Market `catalogue.json`) and writes them to lua and the docs, then runs the rule tests. The bots run the rules alone, one process per processor | `make balance GAME=relic-rush`; `BALANCE_ARGS=--trim` trims long boards first |
| `hex_levels.py` | Validates the hex level files, prints a board, writes `lua/boards.lua` and the overview sheets | `python3 tools/hex_levels.py relic-rush --lua`; `make levels-preview` |
| `square_boards.py` | Validates the 100 square boards per game (envelope, legend, connectivity, every target can receive pieces, at least six target layers); lists asymmetric boards as notes | `python3 tools/square_boards.py christmas-market`; add `--show N` to print a board |
| `square_trim.py` | Uses the reference bot to remove the last targets cleared until each board's median fits its tier (easy 30, normal 45, hard 60, boss 70) | `python3 tools/square_trim.py relic-rush --levels 21-30 --report` |
| `story_lines.py` | Lists story lines that may be narration rather than speech: no I/we/you, no name, no question or imperative ([why](../docs/STORY_WRITING.md#speech-only-no-narration)) | `python3 tools/story_lines.py christmas-market` |
| `tune_moves.py` | Fits each board's `moves` in the square campaign's `lua/campaign.lua` to the bot's median times the tier margin and writes `docs/level-moves.md` and `.json` (`lua/level_moves.lua` is the archived hex path) | `python3 tools/tune_moves.py relic-rush` |
| `balance_plaques.py` | Lists the plaques the bot clears last on each board and, with `--trim`, removes them until the bot's median game is at most twice the level's Homescapes move budget (`--high`); `--keep-blockers` trims plain plaques before chained and frozen ones | `python3 tools/balance_plaques.py relic-rush --levels 31-40`; add `--trim` to rewrite the level files |
| `tests/lua/tune_moves.lua` | The bot side of `tune_moves.py` and `balance_plaques.py`; reports the move each plaque was cleared on | run by `tune_moves.py` |
| `tests/lua/greedy_bot.lua` | The reference bot shared by the tuner and the balance runner | required |
| `tests/lua/relic_balance.lua` | Plays every board of both games, reports income and fits purchase prices; `balance.py` runs it one board per process and writes the prices | `make test-balance` (report only, same forty-game sample) |

## Review captures and story

| Script | What it does | Run |
| --- | --- | --- |
| `capture_match3_default.py` | Captures match-3 atlas reviews, one start per game | `python3 tools/capture_match3_default.py` |
| `capture_resource_icons.py` | Captures resource and hex review cases | `python3 tools/capture_resource_icons.py` |
| `capture_trickling.py` | Captures vertical and diagonal refill reviews | `python3 tools/capture_trickling.py` |
| `capture_economy_review.py` | Captures economy before/after comparisons with the native renderer | `python3 tools/capture_economy_review.py --before-ref <sha>` |
| `scenario_overview.py` | One HTML page of every game's cast, boards and story beats; with `--epoch N`, one epoch of the match-3 games: its four purchases, levels, scenes and town | `python3 tools/scenario_overview.py --capture`, `python3 tools/scenario_overview.py --epoch 1 --capture` |
| `scenario_dump.lua` | Prints a game's scenario data (cast, levels, purchase ladder, story beats) as JSON for `scenario_overview.py` | run by `scenario_overview.py` |

## Studying other games: `tools/reference/`

These read local extractions under `reference/` (git-ignored; each has a
`SOURCE.txt`) and write the docs in `docs/*-reference/`.

| Script | What it does | Run |
| --- | --- | --- |
| `cradle-of-rome/extract_pak.py` | Unpacks a Cradle of Rome `resources.pak` | `python3 tools/reference/cradle-of-rome/extract_pak.py <resources.pak> <new dir>` |
| `cradle-of-rome/analyze.py` | Inspects board, piece and construction tables | `python3 tools/reference/cradle-of-rome/analyze.py` |
| `cradle-of-rome/level_data.py` | Exports every level as design data: `docs/cradle-of-rome-reference/levels.json` and `LEVELS.md` | `python3 tools/reference/cradle-of-rome/level_data.py [--check]` |
| `cradle-of-rome/compare_levels.py` | Compares a hex campaign with Cradle of Rome 2 level by level: board fill, blue and green plaques, chains, ice and the cells a blocker holds back | `python3 tools/reference/cradle-of-rome/compare_levels.py relic-rush` |
| `cradle-of-rome/level_previews.py` | Draws 100 Adventure layouts from each of the two local Cradle of Rome editions as comparison sheets | `make reference-levels-preview` |
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
| `prepare_bonus_gems.py` | Registers the standalone bonus pieces used by the board and toolbar |
| `prepare_resource_pieces.py` | Registers match pieces and wallet icons |
| `prepare_result_icons.py` | Registers the two result icons |
| `prepare_hud.py` | Registers the expedition HUD atlas (`--check` in `make test-assets`) |
| `prepare_finale_art.py` | Registers the signal plate, landing scene and crew-request hand-in paintings |
| `prepare_story.py` | Compiles the reviewed story's lines; `--check` detects drift |
| `prepare_story_pieces.py` | Registers Relic Rush story pieces for alternate art packs |
| `capture_buildings.py` | Real-game before/after captures for building art and shadows |
| `capture_cell_mask.py` | Captures the game's real hex geometry |
| **christmas-market** | |
| `prepare_assets.py` | Registers ImageGen artwork with crops, resizes and board masks |
| `fit_match3_edges.py` | Hex-edge remapping for the tinsel ring, used by `prepare_assets.py` |
| `check_assets.py` | Checks shipped inventory, state coverage and icon exports (`make test-assets`) |
| `prepare_catalogue.py` | Builds the catalogue around the rendered sprites (`--check` in `make test-assets`) |
| `prepare_market_goods.py` | Centres the market pieces and boosters against square cells and packs one atlas. Run with `--check` to verify. |
| `prepare_character.py` | Resizes the character cutout and the app-icon master |
| `prepare_hud.py` | Exports the navigation cells |
| `prepare_story.py` | Compiles the reviewed story's lines; `--check` detects drift |
| `prepare_story_cast.py` | Registers the nine supporting story busts (`--check` in `make test-assets`) |
| `prepare_story_pieces.py` | Fits the six story objects on the chip canvas |
| **nile-archive** | |
| `prepare_catalogue.py` | Builds the catalogue around the rendered sprites (after `tools/buildings.py`) |
| `prepare_chimneys.py` | Imports the chimney paint-over and registers the smoke openings (`--check` verifies both) |
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
