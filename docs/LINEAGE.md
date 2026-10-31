# Lineage: what the engine takes from where

The engine is small, but almost nothing in it is new. This page names the
2D engines, scripting conventions and API-description tools it borrows from,
era by era, and what exactly was taken. Every entry links to a primary source;
the few claims that could not be checked against a page are marked
*[unverified]*. The architecture itself is in [ENGINE.md](ENGINE.md) and the
Lua side in [SCRIPTING.md](SCRIPTING.md).

The one-line summary: **the engine knows mechanics, the games know content**,
which is the split every generation of 2D engine rediscovered — hardware
sprites and name tables, then sprite libraries, then scene graphs, then an
engine in C with the game in a scripting language.

## 1. Sprite engines through the eras

### Hardware sprites (1982–1990): the display list is the API

| Machine | Model | What we keep |
| --- | --- | --- |
| C64 VIC-II (1982) | 8 hardware sprites, repositioned in a raster interrupt to show more ([c64-wiki: Sprite](https://www.c64-wiki.com/wiki/Sprite), [Raster-IRQ](https://www.c64-wiki.com/wiki/Raster-IRQ)) | Nothing directly; the idea that a sprite is a *record* (position, image, flags) the hardware walks every frame is the ancestor of every display list below. |
| NES PPU (1983) | OAM: a 64-entry sprite list, 8 per scanline; backgrounds are name tables of tiles with attribute tables for palettes; scrolling by register ([nesdev: OAM](https://nesdev.org/wiki/OAM), [attribute tables](https://www.nesdev.org/wiki/PPU_attribute_tables)) | The separation of a **scrolling backdrop** (our `camera_draw_texture` over a world-sized image) from **sprites drawn over it** (the city's depth-sorted buildings). |
| Amiga OCS (1985) | Blitter "Bobs" — software sprites of any depth drawn by a coprocessor — next to 8 hardware sprites; the Copper rewrites registers at beam positions ([Amiga OCS](https://en.wikipedia.org/wiki/Amiga_Original_Chip_Set)) | Blitting as the universal primitive: every `draw_image*` is a blit with a tint, and shapes are triangle meshes, nothing special-cased. |
| SNES PPU (1990) | 128 sprites, Mode 7 affine backgrounds, HDMA tables that change registers per scanline — "a hardware per-scanline script" ([snes.nesdev: HDMA](https://snes.nesdev.org/wiki/DMA), [Mode 7](https://www.sneslab.net/wiki/Mode_7)) | The data-driven frame: a table the hardware reads is the earliest form of "the engine runs, the content is data", which is what `api.xml` and the Lua descriptors are. |

### DOS and Turbo Pascal (1987–1997): libraries, not engines

| Library | Model | What we keep |
| --- | --- | --- |
| Borland BGI `Graph` unit (1987) | `GetImage`/`PutImage` to save and restore rectangles, `SetActivePage`/`SetVisualPage` for flipping; no sprite objects ([BGI docs](https://home.cs.colorado.edu/~main/bgi/doc/index.html)) | The immediate-mode habit: nothing is retained between frames; you draw the whole screen every time (`frame(dt)` redraws everything, including the UI). |
| Fastgraph (1989–1995) | Commercial C/Pascal/BASIC library: physical, virtual and logical pages, masked bitmaps, palette operations ([READ.ME](https://discmaster.textfiles.com/view/10567/HPAVC%20CD-ROM.iso/pc/FGL402A.ZIP/READ.ME)) | The "logical screen" idea. Fastgraph's logical pages are where our *logical screen* comes from: the game draws in design units and the engine maps them to the device (`app_screen`, `app_pixel_scale`). |
| Mode X libraries (1991–1994) | Planar 320×240 with hardware page flipping, after Michael Abrash ([Mode X](https://en.wikipedia.org/wiki/Mode_X), [PCGPE MODEX.TXT](https://discmaster.textfiles.com/view/10567/HPAVC%20CD-ROM.iso/pc/PCGPEV10.ZIP/MODEX.TXT)) | Page flipping is SDL's `RenderPresent` now; what survives is the discipline of one `present` per frame and never drawing into the visible page. |
| **SPX Library, Scott D. Ramsay (1992–1994, Turbo Pascal 6/7)** | Shareware library "to EASILY write games in the native 320x200x256 VGA mode": primitives, joystick and mouse, paging, sprites (VSP files), PCX; SPX 2.0 shipped **tools** — a sprite maker, PCX2VSP, a tile map maker, a font editor, CEL2VSP ([retropc.se listing](https://files.retropc.se/software/PROGRAMM/PASCAL/index5851.html?C=S&O=D), [synchrondata](http://www.synchrondata.com/pheaven/www/area18.htm)). SPX 3.0 (1993–94) adds `SPX_ES`, which loads a whole VSP sprite file into expanded memory in one call, and `SPX_IMG` for PCX/BMP/PTR images ([SPX_ES.DOC](https://discmaster.textfiles.com/view/10567/HPAVC%20CD-ROM.iso/pc/SPX30.ZIP/SPX_DOC.ZIP/SPX_ES.DOC), [SPX_IMG.DOC](https://discmaster.textfiles.com/view/10567/HPAVC%20CD-ROM.iso/pc/SPX30.ZIP/SPX_DOC.ZIP/SPX_IMG.DOC)). *[unverified]*: the complete unit list of SPX 3.0; only these two documents were reachable. | Three things. (1) **One unit per concern** — SPX ships `SPX_VGA`, `SPX_IMG`, `SPX_ES`…; the engine ships `core`, `gfx`, `font`, `ui`, `save`, `city`, `story`, one `.c` per module behind one header. (2) **Tools beside the library**: SPX's sprite and tile-map makers are the ancestors of `tools/` (`artkit.py`, `screenshots.py`, and now `luagen.py`). (3) **The library owns the format and the loading, the game owns the data**: a VSP is loaded in one call and the game never parses it, the way `tex_load`, `font_load` and `city_init` take a path. SPX is also the reason this document exists: it is the point where "a Pascal programmer with a game idea" could write only the game. |
| Same era, same idea | Marius Kjeldahl's mode-13h sprite engine for TP 6.0 ([pascal.sources.ru](https://pascal.sources.ru/graph/sprites.htm)); Mike Wiering's Mario clone with page flipping in `VGA.PAS` ([MarioPascal](https://github.com/lhkastenson/MarioPascal/blob/master/README.TXT)); SWAG, a curated archive of thousands of Pascal snippets ([swag.bttr-software.de](https://swag.bttr-software.de/)) | SWAG is the counter-example: routines without an engine. The shared engine exists so that the second game does not copy the first game's routines. |

### C libraries and wrappers (1995–2005): the game is a C program

| Library | Model | What we keep |
| --- | --- | --- |
| **Allegro** 1–4, Shawn Hargreaves (1995–) | `BITMAP` as the universal surface, `blit`/`masked_blit`/`draw_sprite`, RLE and compiled sprites, timers, input, sound, a GUI, and **grabber datafiles**; no scripting language — games link the library ([readme](https://liballeg.org/readme.html), [RLE sprites](https://www.allegro.cc/manual/4/api/rle-sprites/)) | The *kitchen-sink single library* shape: input, timers, drawing, text, sound and a small GUI in one dependency, so a game needs nothing else. Allegro's grabber (assets as data the engine loads) is where the `data/` folder convention comes from. |
| SDL 1.2 + SDL_image (1998–2012) | `SDL_SetVideoMode`, `SDL_BlitSurface`, colour keys, `SDL_Flip`; `IMG_Load` returns a surface; no scene model, the game owns the loop ([SDL 1.2 video](https://libsdl.org/release/SDL-1.2.15/docs/html/video.html), [SDL_image](https://libsdl.org/projects/docs/old/SDL_image/SDL_image.html)) | The platform layer is SDL2 (window, renderer, input, touch, Emscripten). Like SDL 1.2, the engine has **no scene graph**: it is a drawing and input API plus a few mechanics. |
| CDX (1998–2002) | C++ wrappers over DirectDraw: `CDXScreen`, `CDXSurface`, `CDXSprite`, tiles, scrollable maps, sprite lists ([codeguru](https://codeguru.com/multimedia/cdx-game-development-kit)) | A cautionary tale rather than a source: the wrapper died with the API it wrapped. The engine wraps SDL2 only in `core.c`/`gfx.c`, so the rest never sees it. |
| ClanLib (1999–) | Classes for collision, GUI, XML, networking ([ClanLib](https://en.wikipedia.org/wiki/ClanLib)) | Nothing; listed as the other C++ road not taken (see "C, not C++" in the README). |
| pygame (2000–) | Python over SDL with a sprite module ([pygame](https://github.com/pygame/pygame)) | The first mainstream "engine in C, game in a scripting language" layering on top of SDL — the shape this repository now has, with Lua instead of Python. |

### Scene graphs and scripted engines (2005–2015)

| Engine | Model | What we keep |
| --- | --- | --- |
| Flash + Flixel (2008–2012) | `FlxSprite` with basic physics and animation, `FlxState` screens, tilemaps, cameras; pure code and sprite sheets, no authoring tool ([flixel](https://github.com/AdamAtomic/flixel)) | `FlxState` is the "screen as a function" idea; our screens (`island_frame`, `scene_frame`, `board_screen`) are functions, not classes, and a game switches by calling a different one. |
| cocos2d (2008–) | Director, scenes, layers, sprites running *actions* (move, rotate, scale), transitions ([cocos](https://github.com/los-cocos/cocos)) | Not the retained scene tree (deliberately — see ENGINE.md principle 4), but cocos2d's *actions* are the ancestors of our easing helpers (`ease.*`, `num.approach`) used inline, and of the Lua motion module's tweens and timelines, whose API follows GSAP, flux, DOTween and Godot's Tween ([MOTION.md](MOTION.md)). |
| Torque 2D (2000s) | C++ engine, game logic in TorqueScript ([Torque2D](https://github.com/TorqueGameEngines/Torque2D)) | The split engine-in-C++/game-in-script, with a language of its own. We chose a language that already exists. |
| XNA / MonoGame (2006–) | `Game` subclass with `Initialize`, `LoadContent`, `Update(gameTime)`, `Draw(gameTime)`; `SpriteBatch` ([XNA Game class](https://learn.microsoft.com/en-us/previous-versions/dotnet/netframework-4.0/ee248547(v=vs.100)), [MonoGame](https://github.com/MonoGame/MonoGame)) | The *named lifecycle callbacks*: the descriptor a game returns from `main.lua` has `init`, `frame(dt)` and `quit`, which is XNA's `LoadContent`/`Update`+`Draw`/`UnloadContent` with update and draw folded into one immediate-mode pass. |
| GameMaker (1999–) | Sprites, objects, rooms; instances get Create/Step/Draw events each tick; GML ([Objects and instances](https://manual.gamemaker.io/lts/en/Quick_Start_Guide/Objects_And_Instances.htm)) | The reminder that most 2D games are *events on data*; we keep the data in Lua tables and the events as plain function calls. |
| Godot 2D (2014–) | A scene tree of `Node2D`s, `_ready()`/`_process(delta)`, signals ([Godot](https://github.com/godotengine/godot), [signals](https://docs.godotengine.org/en/4.0/getting_started/step_by_step/signals.html)) | `city_update` returning a `city_event` instead of taking callbacks is the engine's small, synchronous version of signals: the mechanic reports, the game decides. |
| raylib (2013–) and the sokol headers (2017–) | C99, no dependencies, "write the game as a C program" ([raylib](https://github.com/raysan5/raylib)); sokol: STB-style single-file C libraries whose Zig/Odin/Nim/Rust bindings are **generated from the C headers** by `bindgen/gen_all.py` ([sokol bindgen](https://github.com/floooh/sokol/blob/master/bindgen/README.md)) | The C API style (descriptor structs, zero-initialised defaults, value types) is sokol's; and sokol's generated bindings are the nearest modern precedent for *generating the Lua glue instead of writing it*. |

### Engines whose games are written in Lua (2008–)

These are the direct models for the split made in this repository.

| Engine | How the engine and the game meet | What we keep |
| --- | --- | --- |
| **LÖVE** (2008–) | C++ wrapper over SDL/OpenAL/FreeType; the game is `main.lua` overriding `love.load`, `love.update(dt)`, `love.draw`; engine objects (Image, Canvas, Source) are GC-managed userdata subtypes of `Object` with `type`/`typeOf`/`release` ([callbacks](https://www.love2d.org/wiki/Category:Callbacks), [Object](https://www.love2d.org/wiki/Object), [love2d/love](https://github.com/love2d/love)) | The whole shape: a game is a folder with `main.lua`, the engine owns the loop and calls named functions, and stateful engine objects are userdata with methods (`city.new()`, `c:update(...)`). We merge `update` and `draw` into `frame(dt)` because the UI is immediate-mode. |
| **Corona SDK / Solar2D** (2009–) | `main.lua` is where the app starts; display objects from `display.newImage`; `Runtime:addEventListener("enterFrame", fn)` at the configured frame rate ([Solar2D guide](https://docs.coronalabs.com/guide/programming/01/index.html), [enterFrame](https://docs.coronalabs.com/api/event/enterFrame/index.html)) | The `--size`/`config` idea of a *design resolution* the engine letterboxes (Corona's `config.lua` content scaling) is our `design`, `max_aspect` and `fixed` descriptor keys. |
| **Moai** (2011–) | C++ classes exposed one-to-one as Lua classes (`MOAILayer`, `MOAIProp`, `MOAIAction`); the developer writes a *host* around the library ([moai-dev](https://github.com/moai/moai-dev)) | The one-to-one mapping: every `engine.h` function with a type prefix becomes a method of that type in Lua (`rect_inflate` → `r:inflate`), generated, so the two APIs cannot drift. |
| **Defold** (2014/2016–) | Scripts get `init`, `update(dt)`, `on_message`, `on_input`, `final`; engine state is addressed by URLs and hashed ids with message passing, not userdata ([script manual](https://defold.com/manuals/script), [lifecycle](https://defold.com/manuals/application-lifecycle)) | `final` → our `quit`; and Defold's insistence that scripts cannot hold raw engine pointers is why Lua never sees a `lua_State`, a texture pointer is opaque, and the city is reached only through its handle. |
| **PICO-8** (2015–) | A fantasy console on Lua 5.2: `_init`, `_update`/`_update60`, `_draw`; `spr`, `map`, `sfx`, `btn`; all state in fixed RAM, no handles ([API](https://people.zoy.org/~sam/pico8-api/)) | The *tiny flat API* feel: `gfx.circle(p, r, c)`, `sfx.tone(hz, s)`, `input.get()` are global tables with short functions, there to be typed from memory. |

## 2. Lua inside shipped games

Lua was born as a data-description language: *The Evolution of Lua*
(Ierusalimschy, de Figueiredo, Celes, HOPL III 2007) traces it to DEL, a
data-entry language for forms, and SOL, a "Simple Object Language" for
describing objects, merged in 1993 into Lua 1.0 with SOL's constructor syntax
kept ([hopl.pdf](https://www.lua.org/doc/hopl.pdf)). *Programming in Lua*
opens its C-API part with the configuration-file example and its data chapter
with `entry{...}` files ([PIL 25](https://lua.org/pil/25.html),
[PIL 10.1](https://www.lua.org/pil/10.1.html)); *Lua Programming Gems* has a
whole part on game programming ([lua.org/gems](https://www.lua.org/gems/)).
That is why the games here describe their content — scenes, buildings, cast,
levels, wonders — as Lua tables and the engine never parses a format of its own.

| Game | What lives in Lua / what stays in the engine | Taken here |
| --- | --- | --- |
| Grim Fandango, GrimE (1998) | "Everything that matters": dialogue, puzzles, menus, logic ([Mogilefsky, Lua Workshop 2005](https://www.lua.org/wshop05/Mogul.pdf)); the engine renders and plays sound. *[unverified]*: the exact Lua version. | The ambition: *all* game logic in the script, including the dialogue — hence `story.play` takes its lines from Lua tables. |
| Baldur's Gate (1998) | Lua "mainly as a debugging tool" ([lua-l 1999](https://lua-users.org/lists/lua-l/1999-05/msg00027.html)); the Enhanced Editions keep a Lua console. | Our debug entry points (`--screen`, `--level`, `--dialog`, `--smoke`) live in the game script, like a console that is part of the game. |
| Homeworld 2 (2003) | Ship definitions, build and research trees, maps are Lua files ([HWRM wiki](https://github.com/HWRM/KarosGraveyard/wiki/Tutorial%3B-Lua)). | Content as Lua tables (`levels`, `wonders`, `scenes`). |
| World of Warcraft UI (2004–) | Frames declared in **XML** (`<Frame>` … `<Scripts><OnLoad>`) or built in Lua, handlers in Lua, addons as a `.toc` manifest of XML and Lua files ([Handling events](https://warcraft.wiki.gg/wiki/Handling_events), [UI customization](https://warcraft.wiki.gg/wiki/WoW_UI_Customization_Guide)). | The XML/Lua pairing, inverted: WoW puts the *layout* in XML and the *behaviour* in Lua; we put the *API* in XML (`api.xml`) and both layout and behaviour in Lua. |
| Far Cry / CryEngine (2004–) | Script entities: an `.ent` XML points at a Lua file whose `Properties` table the editor shows; C++ exposes `ScriptBind_*` functions ([CryEngine docs](https://cryengine.com/docs/static/engines/cryengine-3/categories/1638401/pages/1933358)). | `ScriptBind_*` by hand is exactly the glue we chose not to write; the generator writes ours. |
| Garry's Mod (2006–) | Gamemodes and entities as tables of hooks (`GM`, `ENTITY`, `hook.Add`) over the Source engine ([GM hooks](https://wiki.facepunch.com/gmod/GM_Hooks)). | A game is a table of named functions — the descriptor `main.lua` returns. |
| Roblox / Luau (2006–) | All experience code in Luau; scripts reach the engine through services and a tree of Instances; `luaL_sandbox` isolates globals ([luau](https://github.com/luau-lang/luau)). | Sandboxing: each game gets its own state with `io`, `os`, `package` and `debug` left out of the build (`engine/lua_lib.c`). |
| Angry Birds (2009) | Shipped encrypted Lua scripts over SDL + Box2D ([AB360](https://github.com/AB360-org)). *[unverified]*: what the scripts controlled. | Evidence that SDL + Lua ships at scale on phones. |
| Natural Selection 2 (2012) | Gameplay entirely in Lua on the C++ Spark engine, three isolated VMs; the C++/Lua binding layer was the known bottleneck ([Cronin, Lua Workshop 2012](https://www.lua.org/wshop12/Cronin.pdf)). | A warning taken seriously: value types cross the boundary as plain tables with no per-call allocation on the C side, and the hot loops of the rules (`game_matches`, `game_collapse`) are *pure Lua*, never crossing. |
| Don't Starve (2013) | "Most of the actual game code is in Lua": prefabs, components, state graphs, brains ([Don't Starve wiki](https://dontstarve.wiki.gg/wiki/Lua)). | Confidence that a whole mid-sized game, not just its data, belongs in the script. |
| Factorio (2016) | Mods run in three stages; the prototype stage defines every entity as a Lua table before the game exists; the runtime stage registers event handlers ([Data lifecycle](https://lua-api.factorio.com/1.1.83/Data-Lifecycle.html)). | `main.lua` is Factorio's two stages in one file: the top defines data (tables), `init` builds the world from it, `frame` is the runtime. |
| Noita (2019) | Entities are XML files; Lua spawns and extends them ([Modding basics](https://noita.wiki.gg/wiki/Modding:_Basics)). | Another XML+Lua pairing; we keep XML for the one thing that must be machine-checked (the API). |
| Civilization V / VI | `GameEvents` hooks that may return values altering the outcome ([GameEvents](https://modiki.civfanatics.com/index.php/GameEvents_(Civ5_Type))). | The city's `buildable`/`zone_at` callbacks: the engine asks, Lua answers, the engine acts. |
| Project Zomboid | Lua (Kahlua on Java) with only exported classes visible and no disk I/O outside the game's folders ([modding guide](https://github.com/FWolfe/Zomboid-Modding-Guide/blob/master/api/README.md)). | `require` resolves only inside the game's `lua/` folder. |
| Stardew Valley (counter-example) | C# mods, no Lua ([SMAPI](https://stardewvalleywiki.com/Modding:Modder_Guide/Get_Started)). | Listed to show the alternative: compiled plugins. Not chosen; the games should run from source on the web build. |

## 3. Describing an API once: XML → glue + docs

The request was "don't write Lua glue code, generate it from XML along with
docs". The precedents, and what `tools/luagen.py` copies from each:

| System | What it does | Taken here |
| --- | --- | --- |
| **wayland-scanner** | Protocol XML (`<interface>`, `<request>`, `<event>`, `<enum>`, `<arg type summary>`, `<description summary>`) → client headers, server headers and marshalling code; the descriptions become doc comments ([scanner usage](https://gist.github.com/twaik/e9cf32cba07ccc8ff8dcc100f7440dd2), [Message XML](https://git.sudomsg.com/mirror/wayland/tree/doc/book/src/Message_XML.md)) | The overall contract: one XML with *documentation nodes next to the signatures*, and one tool that emits both code and reference. Our `doc` attributes and arg text are Wayland's `summary`. |
| **GObject Introspection** `.gir` + lgi | `g-ir-scanner` turns headers and GTK-Doc into GIR XML with `<class>`, `<method>`, `<parameter direction="in|out|inout" transfer-ownership>` and inline `<doc>`; `g-ir-doc-tool` writes docs from it; lgi binds Lua dynamically from the typelib ([gir-1.2.rnc](https://raw.githubusercontent.com/GNOME/gobject-introspection/main/docs/gir-1.2.rnc), [lgi](https://github.com/lgi-devs/lgi)) | `ref="inout"`/`ref="out"` on arguments (RectCut's `cut_*`, `city:find_spot`'s result, the save visitor's values) is GIR's `direction`. |
| **Khronos `vk.xml` / `gl.xml`** | The registry is "the source file for the API description"; Python + `etree` generators write the headers and the spec's include files; a RelaxNG schema validates; `make validate install test` is the workflow ([vk.xml README](https://raw.githubusercontent.com/KhronosGroup/Vulkan-Docs/main/xml/README.adoc)) | A Python generator over `xml.etree`, with a validation pass (`validate()` in luagen) before anything is written. |
| **D-Bus introspection + gdbus-codegen** | `<interface>`/`<method>`/`<arg direction>` XML → proxy and skeleton C types, and `--generate-docbook` reference pages from the same file ([gdbus-codegen](https://www.mankier.com/1/gdbus-codegen)) | Docs are an *output*, never written by hand — `docs/LUA_API.md` carries a "do not edit" header. |
| Mozilla XPIDL / WebIDL | `.idl`/`.webidl` → C++ bindings by `Codegen.py` ([WebIDL](https://firefox-source-docs.mozilla.org/dom/bindings/webidl/index.html)) | The scale at which this works; nothing specific. |
| tolua / tolua++ `.pkg`, SWIG `.i` | A "cleaned" header drives the binding generator ([tolua](https://web.tecgraf.puc-rio.br/~celes/tolua/tolua-3.2.html), [SWIG Lua](https://www.swig.org/Doc4.5/Lua.html)) | Rejected as the input: a cleaned header has no place for documentation or Lua-side naming, which is what the XML adds (`lua="inside"` for `text_in`, `sized` for `ts_size`). |
| sol2 / LuaBridge | C++ templates describe the API at compile time ([sol2](https://github.com/ThePhD/sol2), [LuaBridge](https://github.com/vinniefalco/LuaBridge)) | Not applicable to C, and the reference could not be generated from the same source. |
| **corepunch/orion-ui `.cgen`** ([PR #289](https://github.com/corepunch/orion-ui/pull/289), [PR #288](https://github.com/corepunch/orion-ui/pull/288)) | A `.cgen` XML per module (`<module name prefix>` / `<function name call lua>` / `<arg name type optional default>` / `<returns type>`) read by `tools/cgen.c`, which writes `<stem>_lua.h` (argument checks, `luaopen_`, prototypes so a disagreeing C signature fails to compile) and a Markdown reference; `make lua-docs` writes `docs/lua/`, `lua-docs-check` diffs it and **`make test` fails while the docs are stale**; add-ons run in a sandbox with base, `string`, `table`, `math`, `utf8`, `coroutine` and a `require` limited to known folders ([docs/scripting.md](https://github.com/corepunch/orion-ui/blob/main/docs/scripting.md)). Orion's Ledger goes further with `apps/ledger/ledger-api.xml` and `tools/generate_lua_api.py`, which emits the header, the docs, a `.d.lua` annotations file and a site page from one XML. | The closest ancestor, taken almost whole: the `<function>`/`<arg>`/`<returns>` vocabulary with `optional` and `default`; `impl=` for the hand-written few (orion's `lua="true"`); generated docs committed and checked by `make test` (`gen-check`); the `.d.lua` annotations for editors; the same sandbox library list and the same `require` policy. What is added for a game engine: `<struct>` value types marshalled as tables with metatables and operators, `<handle>` userdata with field access and callback trampolines, arrays with `count` arguments, and `inout`/`out` arguments. |

## 4. What is deliberately not taken

- **A retained scene graph** (cocos2d, Godot, Flash): the UI and screens are
  immediate-mode functions; nothing has to be kept in sync.
- **A custom scripting language** (TorqueScript, GML): Lua 5.4 as shipped,
  the official mirror as a submodule under `engine/third_party/lua`, unchanged.
- **Message passing to engine objects** (Defold): the games are small enough
  that direct calls on handles read better; callbacks are synchronous.
- **Bindings from C++ templates** (sol2): the engine is C, and the reference
  must come from the same description as the glue.
- **Scripts with file or OS access**: the sandbox opens neither `io` nor `os`;
  saves go through the engine's `save` module, assets through `texture.load`.
