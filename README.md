# Sprite engine + games

One repository, one small **C11 + platform** engine, games driven by **Lua** on it:

| | Game | Core loop | Meta-game |
| --- | --- | --- | --- |
| ![](games/nile-archive/docs/screenshots/island.jpg) | **[Архив Нила / Nile Archive](games/nile-archive/README.md)** (Russian) | Hidden-object scenes painted in Ptolemaic Egypt | Restore an island estate: buildings, influence, new shores |
| ![](games/relic-rush/docs/screenshots/hex-first.jpg) | **[Relic Rush · The Lost Valley](games/relic-rush/README.md)** (English) | Hex match-4 on ten shaped boards with sand, chains, ice, rays, bombs and prisms | Restore an island: ten wonders placed freely, six regions opened with stars and compasses |
| ![](games/christmas-market/docs/screenshots/market.jpg) | **[Christmas Market](games/christmas-market/README.md)** (English, prototype) | Ten festive hex match-4 puzzles | Build a snowy Christmas market with ten stalls and attractions, two repeatable decorations and Noelle as the market keeper |
| ![](games/volcano/docs/screenshots/outskirts.jpg) | **[Volcano · After the Eruption](games/volcano/README.md)** (English) | Dispatch workers, clear routes, repair supply stations and evacuate five districts | A linked rescue campaign with recruits, pet escorts and saved chapter progress |

[Clayfight](games/clayfight/README.md) runs its complete original C fighting game on the shared engine, with Lua frame scheduling, custom clay fighters, conquest, training, tug-of-war, endurance, and native iOS photo/video capture. Its original PC reference data is supplied locally and ignored by Git.

Volcano is a five-map resource-and-route rescue campaign; see [its port assessment and asset catalog](games/volcano/docs/PORT.md).

The games target the iPad; the web build is only a fullscreen preview (a bare canvas, no HTML UI). Nile Archive and Relic Rush are a "puzzle → reward → build" loop, so the shared parts are big: the city-building meta-game (economy, building catalogue, placement, zones, timed income), characters and dialogue (portraits, speech bubbles, typed text, story beats that play once), the camera, styled text, UI widgets, save files, effects, sound, and the platform layer for desktop, iPad and phones (native and WebAssembly). Nile Archive lays itself out for any landscape screen; Relic Rush keeps a fixed 480 × 900 portrait design inside the safe area that only grows taller on tall phones, with its backgrounds running on to the screen edges — the engine supports both.

**The engine knows mechanics, the games know content and rules.** The engine is C; the original three games use Lua 5.4 for game logic (Clayfight retains its tested C simulation), and the glue between them is generated from one XML description of the API, together with its reference. See [docs/SCRIPTING.md](docs/SCRIPTING.md) for the contract, [docs/LUA_API.md](docs/LUA_API.md) for the reference and [docs/LINEAGE.md](docs/LINEAGE.md) for where every idea comes from.

## Layout

```
engine/            the shared engine: ONE public header + one .c per module
  engine.h         math, app, input, gfx, camera, fx, text, ui, audio, save, story, city, script
  core.c           window, logical screen, main loop, pointer/touch gestures, screenshots
  gfx.c            textures, anti-aliased shapes, camera, particles
  font.c           TrueType text: outline, soft shadow, gradient; Retina-crisp glyph atlas
  ui.c             immediate-mode widgets, input blocking, toasts, modals
  save.c           key=value saves (files natively, localStorage on the web)
  city.c           the city-building meta-game
  sprite.c         authored atlas animation and pivot-aware drawing
  nav.c            geometric graph routes with live blockers
  audio.c          shared stereo PCM mixer and feedback-tone synthesiser
  raster.c         caller-owned CPU surfaces and indexed sprite drawing
  photo.c          background removal, common scale and shared photo palettes
  story.c          characters, dialogue with portraits, speech bubbles
  script.c         the Lua runtime: sandboxed state, require, the main-loop callbacks
  launcher.c       main() for a Lua game, built once per game
  api.xml          the Lua API, described once          ─┐ tools/luagen.py
  api_lua.c/.h     the generated glue                   ─┤ (committed; make gen,
  engine.d.lua     generated editor annotations         ─┘  checked by make test)
  lua_lib.c        Lua 5.4 as one translation unit, sandbox libraries only
  third_party/     lua/ and platform/ (pinned submodules), stb_*
games/
  nile-archive/    lua/ (main, state, content, economy, progress, kit, island, scene, dialogs, smoke)
                   + data/ (art, fonts) + docs/ + tools/ + nile-archive.xcodeproj
  relic-rush/      lua/ (main, rules, island, board, screens, vfx, island_view, state)
                   + art/ (sources) + data/ (runtime) + docs/ + tools/ + relic-rush.xcodeproj
  volcano/        lua/ (campaign, simulation, atlas metadata, UI) + data/ + docs/ + volcano.xcodeproj
  clayfight/      native game rules/resources + Lua scheduling + data/ + capture tools
tests/             engine tests in C; tests/lua/: the generated API and the games' rules
tools/             luagen.py (XML → glue + docs), xcode/generate.py (Xcode projects), screenshots.py, make_reels.py, artkit.py
docs/              ENGINE.md, SCRIPTING.md, LUA_API.md (generated), LINEAGE.md
web/               shell.html: a bare fullscreen canvas for the web preview
```

Each game is one folder with its own content; the engine never includes game code. Adding another game means adding `games/<name>/lua/main.lua` and a `data/` folder — the Makefile picks it up once its name is added to `GAMES`.

## Build and run

Native builds need a C compiler and the pinned [platform](https://github.com/corepunch/platform) and [Lua](https://github.com/lua/lua) submodules: clone with `--recursive`, or run `git submodule update --init` once. macOS uses the system AppKit/OpenGL/AudioToolbox frameworks. Linux uses X11/EGL/OpenGL (`apt install libx11-dev libegl1-mesa-dev libgl-dev libasound2-dev`); `make WINDOW_SYSTEM=wayland` selects Wayland when its development libraries are installed. The engine, Lua, scripting and platform compile as separate unity units, with no SDL installation or embedded framework. Regenerating the Lua glue (`make gen`) needs Python 3.

```sh
git submodule update --init   # Lua, once
make              # builds Nile Archive, Relic Rush, Volcano and Clayfight
make run-nile     # or: make run-relic / make run-volcano
make test         # generated-code freshness, then every test, in one start per game (docs/TESTING.md)
make smoke        # only the games' smoke runs
make gen          # after editing engine/api.xml
make shots        # re-render the documentation screenshots (software renderer, no display needed)
```

Web (needs the [Emscripten SDK](https://emscripten.org/docs/getting_started/downloads.html) on `PATH`):

```sh
make web
python3 -m http.server 8080 --directory dist   # open http://localhost:8080/nile-archive/ or /relic-rush/ or /volcano/
```

**iOS and macOS** (Xcode 16+): each game has a committed project, `games/<game>/<game>.xcodeproj`, with a macOS scheme and an iOS one — `nile-archive-ipad`, `volcano-ipad` and `relic-rush-iphone`. The games target iOS 16+ / macOS 12+. Xcode generates temporary `u_*.c` units in its build directory, compiles them into each app, and links only Apple system frameworks. `make xcode` regenerates the projects with `tools/xcode/generate.py` (see [tools/xcode/README.md](tools/xcode/README.md)).

CI builds the native, web and Xcode (iOS Simulator) targets on every push; the `web` artifact of a run is a ready-to-host `dist/`. The **Deploy to GitHub Pages** workflow (run it from the Actions tab) publishes it once Pages is enabled with "GitHub Actions" as the source.

Every game accepts: `--size WxH`, `--fresh` (no save read/write), `--data DIR`, `--lua DIR`, `--shot out.png [--frames N]`. Games add their own entry points for screenshots (Nile: `--screen <name>`; Relic Rush: `--level`, `--city`, `--victory`, `--dialog`, … and `--smoke`, which plays level one through injected clicks, claims, builds and enters level two; Volcano: `--level`, `--preview repaired|complete` and a full five-district `--smoke`).

## The engine in five minutes

A game is `games/<name>/lua/main.lua`, which returns the app descriptor: a title, a save id, a design resolution, and `init` and `frame(dt)` functions. The engine runs the loop; the game draws everything, every frame. The API is [`engine/engine.h`](engine/engine.h) seen from Lua — same names minus the type prefix, documented in [docs/LUA_API.md](docs/LUA_API.md). Conventions:

- **Value types are tables with a metatable**: `vec2`, `size2`, `rect`, `color`, `purse`, `camera`, `style`, `input`. Functions return new values and chain as methods; `a + b` works on vectors and purses; every field left out is zero, so `style{font = f, size = 17}` is complete.
- **Stateful things are handles**: `city.new()`, the save handle inside a visitor. Fields read and write the engine's state; callbacks are plain functions.
- **Modules are globals**: `app`, `input`, `gfx`, `texture`, `camera`, `fx`, `font`, `style`, `text`, `sfx`, `ui`, `save`, `story`, `city`, `num`, `ease`.

Layout uses [RectCut](https://halt76.notion.site/RectCut-for-dead-simple-UI-layouts-d175c7ff15e74c92b235eb43702155c8): slice a rect off one side and keep going.

```lua
local screen = app.screen()
local header = screen:cut_top(66)
local side = screen:cut_right(270)
local shop = screen:cut_bottom(112)
-- what is left of `screen` is the island view
for i, b in ipairs(buildings) do
    if ui.button(shop:col(5, i - 1, 10), b.name) then select(i) end
end
```

The [shared UI engine](docs/UI_ENGINE.md) adds declarative forms, reusable skins, typed model bindings, keyboard focus and nested modal layers with GPU Gaussian blur. Relic Rush’s pause and building dialogs use these resources.

Styled text is a value you tweak per call:

```lua
local title = style{font = serif, size = 30}:grad(color.hex(0xFFF3D1), color.hex(0xE2B46A))
                  :outlined(1.4, ink):shadowed(vec2(0, 3), 4, color(0, 0, 0, 140))
text.draw(title:sized(40), box:center(), vec2(.5, .5), "Память возвращается")
```

The city meta-game is data plus one update/draw pair. Relic Rush's wonders, for example:

```lua
local wonders = {
    {name = "Expedition camp", sprite_path = "buildings/0.png", size = size2(2, 2),  -- tiles
     pivot = vec2(150, 248), base_width = 280, cost = purse(60, 10, 5)},  -- gold, wood, stone
    ...
}
local c = city.new()
c.defs = wonders
c.tile = size2(40, 20)                                     -- tile half extents, before init
c.buildable = function(c, p) return island.grass(p) end   -- the game knows its map ...
c.zone_at = function(c, p) return island.zone(p) end      -- ... and its regions; the engine the rest
c:init("island.jpg")
local ev = c:update(input.world(), R.prog.wallet, app.clock(), dt)
if ev.result == city.ZONE then open_region_card(ev.zone) end
c:draw(input.world(), app.clock())
```

Placement is either instant (Nile: pick a card, tap the land) or a confirmable ghost (Relic Rush: `c:begin_place`, drag, `c:confirm`); buildings can be dragged to move; zones open with a cost and requirements once they touch open land; fog, paths between buildings and timed income are options.

Characters are data too; a story beat is a list of lines that plays once per save:

```lua
local cast = {
    {id = "elena", name = "Elena Voss", portrait_path = "characters/elena.png", color = color(44, 108, 84)},
    {id = "mara", name = "Mara Bell", portrait_path = "characters/mara.png", color = color(150, 74, 40), right = true},
}
story.setup(cast, story_style{text = speech, name = tag, framed = true, skip = "SKIP"})
story.play("intro", {{"elena", "The Lost Valley at last."}, {"mara", "And now we do."}})
...
story.frame(dt)   -- last in the frame: portrait, bubble, typed text, tap to continue
story.bubble(above_building, "A new wonder!", speech, cream, brown, 220, story.SPEECH)   -- words over the world
```

Saves are one function per game that both reads and writes, so fields cannot drift:

```lua
local function serialize(s)
    R.prog.level = s:int("level", R.prog.level)
    R.prog.wallet = s:ints("wallet", R.prog.wallet)
    R.island:serialize(s)
end
save.read("progress", serialize)    -- at start
save.write("progress", serialize)   -- after something worth keeping
```

See [docs/ENGINE.md](docs/ENGINE.md) for the architecture, the screen model, text rendering and the decisions behind them, and [docs/SCRIPTING.md](docs/SCRIPTING.md) for the Lua side.

## C engine, Lua games

The engine stays C11 on purpose (see the earlier "C, not C++" argument: value types and prefixed free functions chain as well as methods, no ABI or exception questions, trivial Emscripten builds). The games moved to Lua for the reasons every engine from LÖVE to Don't Starve settled on it: content as tables, no compile step for game logic, the same scripts on desktop, iPad and the web, and a hard boundary that keeps engine and game from leaking into each other. The port was checked pixel for pixel — every documentation screenshot and reel frame rendered by the Lua games is identical to the C games' at the same commit — and the C rule tests were ported too.

The Lua glue is not written by hand: [`engine/api.xml`](engine/api.xml) describes the API once and [`tools/luagen.py`](tools/luagen.py) writes the C bindings, the Markdown reference and editor annotations from it, after wayland-scanner, GObject Introspection and the `.cgen` generator in [corepunch/orion-ui](https://github.com/corepunch/orion-ui). `make test` fails if the generated files are stale.

## Merging the repositories

This repository is the single home for the engine and all three games. Relic Rush was imported from `corepunch/relic-rush` (commit `4463559`) into `games/relic-rush/`: its rules and tests were kept, its island became the engine city, and its presentation was rebuilt on the engine. `corepunch/relic-rush` can now be archived, and this repository renamed (for example to `sprite-games`) — GitHub keeps redirects from the old name.

## References

- [docs/LINEAGE.md](docs/LINEAGE.md) — 2D engines from hardware sprites and Turbo Pascal's SPX to LÖVE, Defold and PICO-8; Lua in shipped games; XML-described APIs — and what was taken from each.
- [RectCut for dead simple UI layouts](https://halt76.notion.site/RectCut-for-dead-simple-UI-layouts-d175c7ff15e74c92b235eb43702155c8) — the layout technique used by every screen.
- [sokol headers](https://github.com/floooh/sokol) — C API style: descriptor structs, zero-init defaults, designated initialisers.
- [Lua 5.4](https://www.lua.org/manual/5.4/) — the games' language; the [lua/lua](https://github.com/lua/lua) mirror is a submodule under `engine/third_party/lua` (MIT).

### Safe areas and city placement

The engine fits each game inside the native iOS safe area, using the same
`axIOSGetSafeArea` platform API as Orca. Insets are refreshed every frame so
rotation and inset changes update both rendering and pointer mapping. Desktop
screens have zero insets; `--safe-area L,T,R,B` simulates them in window points.
For example: `./build/relic-rush --size 390x844 --safe-area 0,59,0,34`.

Controls stay in that safe screen, but backgrounds may fill the whole display:
`app.bleed()` is the display in logical units (status bar, home indicator and
letterbox bars included), and drawing between `gfx.bleed(true)` and
`gfx.bleed(false)` may reach it. Relic Rush's jungle, island and header band
run to the edges this way.

Cities place buildings on an isometric grid of whole tiles. `city.tile` sets
a tile's half extents (default `size2(32, 16)`). Each building type gives its
`size` in tiles (2 × 2, 3 × 2, …), its `pivot` (the sprite pixel of the
footprint's ground centre, where it stands) and its `base_width` (the base's
width in sprite pixels, which sets the drawing scale); see
[docs/BUILDINGS.md](docs/BUILDINGS.md) for the spec, the measuring tool and the
`--footprints` check. Taps, drops and confirmations snap the footprint to the
tiles (`c:snap(p, type)`); a dragged ghost follows the finger, lifted
(`c.held`) over the green or red footprint of the tiles it will land on.
Footprints may share an edge but not overlap; `city.clearance` adds tiles
around every base (both games use `size2(1, 1)`) without scaling the sprites. Existing saved positions remain
intact until the player moves a building.
