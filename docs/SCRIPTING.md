# Games in Lua

The engine is C11; the games are Lua 5.4. This page is the contract between
them: what a game is, what it can reach, how the glue between the two is
produced, and how to extend the engine's Lua API. The reference the games are
written against is [LUA_API.md](LUA_API.md), generated from
[`engine/api.xml`](../engine/api.xml). Where the ideas come from is in
[LINEAGE.md](LINEAGE.md).

## The split

**The engine knows mechanics, the games know content and rules.** That was
already the principle in C; moving the games to Lua makes it a hard boundary:

| Engine (C, `engine/`) | Game (Lua, `games/<name>/lua/`) |
| --- | --- |
| Window, logical screen, main loop, input gestures, screenshots | Which screen is showing and what is on it |
| Textures, shapes, camera, particles, styled text, fonts | Every drawing call and layout |
| Immediate-mode widgets, themes, toasts, modal backdrops | Which widgets, where, what they do |
| Save files (key=value, native and web) | What is saved and how it is migrated |
| The city meta-game: placement, zones, fog, income, moving, drawing | The map, the buildings, the regions, what resources mean |
| Characters and dialogue staging, speech bubbles | The cast, the lines, when a beat plays |
| The tone synthesiser | When to play what |

Relic Rush's match-4 rules, its island map, its effects and its dialogs are
all Lua; the engine has no idea what a hex is. Nile Archive's hidden-object
rules and chapters are Lua. Nothing game-specific remains in C: the two
binaries differ only in the folder the launcher points at.

## A game

```
games/<name>/
  lua/main.lua      returns the app descriptor; require()s the other files
  lua/*.lua         the game's modules
  data/             art, fonts, backgrounds
  docs/             screenshots and design notes
```

`main.lua` runs once at start and **returns a table** describing the app —
the same fields as `app_desc` in `engine.h`:

```lua
local function init() ... end          -- once the window exists: load, set up
local function frame(dt) ... end       -- every frame: update, draw, react

return {
    title = "Архив Нила", id = "nile-archive",        -- id names the save files
    design = size2(1200, 900), max_aspect = 16 / 9, landscape = true,
    rotate_text = "...", clear = color(14, 43, 46),
    init = init, frame = frame, quit = nil,
}
```

The engine owns the loop and calls `init`, then `frame(dt)` until the game
ends, then `quit` — LÖVE's `love.load`/`love.draw`, PICO-8's `_init`/`_draw`,
Defold's `init`/`update`/`final`, with update and draw as one pass because the
UI is immediate-mode. A frame typically reads the input, lays the screen out
with RectCut, draws, reacts to widgets, and ends with `story.frame(dt)`:

```lua
local function frame(dt)
    local inp, world = input.get(), input.world()
    local screen = app.screen()
    local header = screen:cut_top(66)
    gfx.rect_grad(screen, color.hex(0x12393B), color.hex(0x0E2B2E))
    if ui.button(header:right(150), "Персонажи") then G.modal = MODAL_CAST end
    G.island.cam = G.island.cam:input(world):clamp()
    local ev = G.island:update(world, G.wallet, app.clock(), dt)
    if ev.result == city.BUILT then save_progress() end
    G.island:draw(world, app.clock())
    story.frame(dt)
end
```

Every game accepts `--size WxH`, `--fresh`, `--data DIR`, `--lua DIR`,
`--shot out.png [--frames N]`; on the web the page's query string supplies
them (`?tiles=jewels`). `app.arg("name")` reads any other option, which is how
the games implement their screenshot entry points (`--screen`, `--level`,
`--dialog`, `--smoke`) in Lua.

## What Lua sees

Every module is a **global table** (`app`, `input`, `gfx`, `texture`,
`camera`, `fx`, `font`, `style`, `text`, `sfx`, `ui`, `save`, `story`, `city`,
`vec2`, `size2`, `rect`, `color`, `purse`, `num`, `ease`). There is nothing to
`require` from the engine; `require("island")` loads the game's own files.

**Value types are tables with a metatable.** `vec2(3, 4)`, `rect(0, 0, 100, 50)`,
`color.hex(0xF4E8CA)`, `purse(60, 10, 5)`, `camera{center = ..., zoom = .8}`,
`style{font = f, size = 17}`, `input{pos = p, pinch = 1}`. As in C, every field
left out is zero, so `{x = 1, y = 2}` is a valid vec2 and `style{font = f,
size = 17}` a valid style. Functions whose first argument is the type are also
methods, and vec2/size2/purse have operators:

```lua
local r = app.screen():inflate(-12)       -- rect_inflate(app_screen(), -12)
local side = r:cut_right(270)             -- rect_cut_right(&r, 270): r changes
local p = (a + b):scale(.5)               -- vec2_scale(vec2_add(a, b), .5)
wallet = wallet + reward - cost           -- purse_add, purse_sub
cam = cam:zoom_at(1.25, r:center()):clamp()
```

Because they are plain tables, they cost one allocation each and nothing on
the C side; the rules of Relic Rush never touch the engine at all, so its hot
loops are pure Lua.

**Handles** are userdata: `city.new()` returns one, `save.read(slot, fn)`
passes one to the visitor. Fields read and write the engine's state
(`c.selected = -1`, `c.open`, `c.count`, `c.cam`), arrays are assigned whole
(`c.defs = {...}`, `c.zones = {...}`), and callbacks are functions
(`c.buildable = function(c, p) ... end`). Struct-valued fields are copied in
and out, exactly like C struct assignment: `local cam = c.cam; cam.view = r;
c.cam = cam`. Unknown field names are errors, so typos surface at once.

**Textures and fonts** are opaque: a texture is `{tex = <pointer>, w, h}` and a
font a light userdata. The script cannot free them from the collector's side;
it can call `texture.free`.

**Arguments that C passes by pointer** become return values or in-place
updates: `local ok, spot = c:find_spot(type, hint)`;
`wallet = s:ints("wallet", wallet)` loads when reading, stores when writing,
and returns the value either way; `c:unlock(z, wallet)` pays from `wallet` in
place.

**The save visitor** keeps its one-function-reads-and-writes shape:

```lua
local function serialize(s)
    s:int("version", 2)
    G.wallet[COINS] = s:int("coins", G.wallet[COINS])
    G.wins = s:ints("wins", G.wins)
    G.island:serialize(s)
    story.serialize(s)
end
save.read("progress", serialize)   -- at start
save.write("progress", serialize)  -- after something worth keeping
```

Save files written by the C games are read unchanged: keys and slots are the
same.

## The sandbox

Each game gets its own Lua state with `base`, `table`, `string`, `math`,
`utf8` and `coroutine`. `io`, `os`, `package` and `debug` are not in the build
(`engine/lua_lib.c` amalgamates only the libraries the sandbox opens from the
`lua/lua` submodule, pinned to v5.4.8);
`dofile` and `loadfile` are removed. `require(name)` resolves `name` (dots as
slashes) against the game's `lua/` folder — or, for the test binary, the
list of folders it is given — and caches the module. Assets are reached
through the engine (`texture.load`, `font.load`), the file system never.

A Lua error prints a traceback to stderr and ends the process with status 3,
in `init`, `frame`, a callback or a save visitor alike. Headless runs (`make
test`, `make shots`, the CI smoke test) therefore fail loudly on any script
error.

## The glue is generated

Nothing in `engine/api_lua.c` was typed by hand. [`engine/api.xml`](../engine/api.xml)
describes the API once — modules, structs and their fields, handles and their
fields, enums, constants, functions with typed arguments, documentation on
every node — and [`tools/luagen.py`](../tools/luagen.py) writes four files from it:

| Output | What it is |
| --- | --- |
| `engine/api_lua.c` | The glue: `api_push_*`/`api_get_*`/`api_check_*`/`api_store_*` for every struct, metatables and constructors, handle `__index`/`__newindex`/`__gc`, one `lua_CFunction` per function with argument checks, module registration (`api_open`). |
| `engine/api_lua.h` | Its declarations, including the prototypes of the few hand-written functions, so a signature that disagrees with the XML does not compile. |
| `docs/LUA_API.md` | The reference: modules, types, fields, signatures, argument tables, returns. |
| `engine/engine.d.lua` | `---@class`/`---@param`/`---@return` annotations for Lua language servers (completion and type checks in an editor). |

The generated files are committed, so a checkout builds with a C compiler
alone; `make gen` regenerates them (Python 3, standard library only) and
`make test` runs `make gen-check`, which fails while they are stale — the
pattern of orion-ui's `lua-docs-check`.

The vocabulary, in brief:

```xml
<struct name="rect" c="rect" ctor="x,y,w,h" doc="...">   value type → Lua table + metatable
  <field name="x" type="float" c="pos.x"/>               c= the C member expression
<handle name="city" c="city" owned="true">                stateful object → userdata
  <field name="selected" type="int" access="rw"/>
  <field name="defs" type="building_def[]" count="def_count" alloc="true" anchor="true" access="rw"/>
  <field name="buildable" type="callback" tramp="lcity_buildable" decl="..."/>
<module name="rect" type="rect">                          module table; type= makes it the method table
  <function name="cut_top" c="rect_cut_top" doc="...">
    <arg name="r" type="rect" ref="inout"/>              updated in place and returned
    <arg name="a" type="float"/>
    <returns type="rect"/>
<function name="find_spot" c="city_find_spot">
    <arg name="out" type="vec2" ref="out"/>              an extra return value
<function name="poly" c="draw_poly">
    <arg name="pts" type="vec2[]"/><arg name="n" type="count" of="pts"/>   a sequence and its length
<function name="read" impl="lsave_read">                 body in script.c; checks, registration and docs still generated
<enum name="flags" prefix="UI_"><value name="ACCENT"/>   ui.ACCENT
```

Types: `float double int uint u8 bool string bytes ptr count`, any struct or
handle name, `T[]`. Optional arguments take `optional="true"` or
`default="..."`; a struct returned by pointer takes `optional="true"` (nil
when NULL) or `ptr="true"`.

### Adding to the API

1. Add the C function to `engine.h` and its module.
2. Describe it in `engine/api.xml`: name, `c=`, a `doc`, each `<arg>` with a
   type and (optionally) text, the `<returns>`.
3. `make gen`, then `make test`.

That is the whole procedure; no C is written for the binding, and the
reference and the annotations update with it. The hand-written exceptions
live in `engine/script.c` and are declared with `impl=`: the save visitors
(`save.read`/`save.write` call a Lua function with a handle), `story.setup`
(the engine keeps the cast, so the binding copies it into static storage and
anchors the Lua table for its strings), `ui.set_theme` (the widgets read the
theme by pointer) and the four city callback trampolines, which find the
Lua function through the handle registry. Everything else — 190-odd
functions — is generated.

Two engine-side changes made the generation clean: the city's callbacks now
receive the city (`bool (*buildable)(const city *, vec2)`), so a trampoline
can find its closure, and a handful of helpers were added for things the C
games did directly with SDL (`draw_mesh` for coloured triangles,
`tex_additive`, `app_inject_click` for the smoke test, `app_web_storage` for
the old web save).

## Tests and verification

- `make test` → `gen-check`, the engine's C tests, then every file in
  `tests/lua/` run by the test binary in an engine Lua state without a window:
  `api.lua` exercises the generated glue (operators, RectCut mutation, in/out
  arguments, handles, callbacks, save round trips, story beats), `relic.lua`
  is the Relic Rush rule suite ported from C (5,800 checks, including the
  greedy bot playing the campaign).
- The port was verified **pixel for pixel**: every documentation screenshot
  and reel frame (129 images: both games' screens, dialogues, effects,
  level shapes, tile packs) rendered by the Lua games is identical to the one
  rendered by the C games at the same commit. The rules keep the C random
  stream, so boards, seeds and saves are the same too.
- `./build/relic-rush --smoke --mute` still plays level one through injected
  clicks to level two, driven by `smoke.lua`; Nile Archive's `archive_smoke.lua`
  plays chapter one. Both run the engine's `city.move_test`
  (`engine/city_smoke.lua`, embedded like `ui_forms.lua`), which drags the first
  building through real press/move/release events and asserts the deliberate
  pickup contract: a drag pans, a half-second hold lifts, release leaves an
  uncommitted preview, Cancel restores it and Confirm moves it for free.

## Performance notes

- Per-frame allocation is Lua tables for value types; the collector runs in
  generational mode with a small step per frame. Both games run their
  screenshots and smoke test well within the C version's timings.
- The Relic Rush rules copy a 61-cell board to evaluate a move (`game_copy`),
  which the greedy bot and the hint do; it is fast enough for play and for
  the test suite (the 40-expedition campaign test takes about ten seconds).
- Text styles and cameras are read field by field on each call; keep them in
  locals rather than rebuilding them per draw if a screen gets heavy.

## The web build

`make web` compiles the engine, the Lua interpreter and the launcher with
Emscripten and preloads `games/<name>/data` as `/data` and
`games/<name>/lua` as `/lua`; scripts load from the virtual file system
through `luaL_loadfile`. No JavaScript changed.
