# Engine architecture

The engine uses small C11 modules behind one public header,
[`engine/engine.h`](../engine/engine.h), plus Lua 5.4 and the glue generated
from [`engine/api.xml`](../engine/api.xml). It targets 2D sprite games with
menus, dialogs and a build-your-place meta-game: hidden objects, match-3,
merge, solitaire, word games and the like. Games are written in Lua; see
[SCRIPTING.md](SCRIPTING.md) for that side and [LINEAGE.md](LINEAGE.md) for
where the ideas come from.

```
            game (games/<name>/lua/main.lua + modules)      Lua 5.4
   ┌────────────────────────────────────────────┐
   │ script: sandboxed state, require, callbacks │   generated glue (api.xml → api_lua.c)
   ├────────────┬────────┬──────────┬──────────┤
   │ city │ story │ ui │ save │ fx/audio │   meta-game, dialogue, widgets, persistence, juice
   ├────────────┴────────┴──────────┴──────────┤
   │   gfx: textures, shapes, camera │ font     │   drawing
   ├─────────────────────────────────┴──────────┤
   │   core: window, logical screen, input, loop │   corepunch/platform (native, Emscripten)
   └────────────────────────────────────────────┘
        math: header-only value types (vec2, rect, …)
```

## Principles

1. **Values, not handles.** Small structs (`vec2`, `rect`, `camera`, `purse`,
   `text_style`, `texture`) are passed and returned by value. Functions return
   a new value instead of mutating, so they compose:
   `camera_clamp(camera_zoom_at(cam, 1.25f, rect_center(cam.view)))`.
   The exceptions are deliberate: RectCut's `rect_cut_*(&r, n)` mutates the rect
   it cuts from, and stateful objects (`city`, `font`) are pointers.
2. **One public header.** Every module's internals are `static`. The Lua API
   is that header seen from Lua, generated from `api.xml`, so the two cannot
   drift; games see nothing else.
3. **Zero means default.** Descriptors (`app_desc`, `text_style`, `camera`,
   `building_def`, `ui_theme`) work with designated initialisers that only name
   what differs, in the spirit of the sokol headers.
4. **Immediate mode.** Screens are functions that lay out, react and draw in
   one pass every frame. There is no retained widget tree to keep in sync.
5. **Engine knows mechanics, games know content and rules.** The city module
   knows how to place, sort, draw, pay for and collect from buildings; it does
   not know what "coins" or "influence" are. Resources are just slots in a
   `purse`. Since the games moved to Lua this is a hard boundary: no game
   logic is compiled into the engine, and the engine reaches a game only
   through the descriptor `main.lua` returns and the callbacks it registers.

## The screen model

Games are designed against a resolution. By default the logical screen keeps
the design's **short side** and grows along the long side with the device, up
to `max_aspect` — Nile Archive (1200 × 900) works this way:

| Device | Logical screen |
| --- | --- |
| iPad landscape 4:3 | 1200 × 900 |
| 16:9 monitor | 1600 × 900 |
| wider than 16:9 | 1600 × 900, letterboxed |
| portrait | the design rotates (900 × 1200 and taller) |

Layouts are cut from `app_screen()`, so they adapt instead of stretching.
Landscape-only games set `.landscape = true` and the engine shows a rotate
prompt in portrait and holds input until the device turns.

Games whose art is composed for one frame set `.fixed = true`: the logical
screen is exactly the design and the renderer letterboxes the rest. A fixed
game that also sets `max_aspect` keeps its width but grows along its long side
up to that ratio, so a tall phone gets a taller screen instead of bars. Relic
Rush is a 480 × 900 portrait game laid out in absolute coordinates with
`max_aspect = 2.2`: on an iPad it is a centred column, on a 390 × 844 iPhone it
is 480 × 939, and it pins its bottom controls to `app_screen()`'s bottom edge.

**Full bleed.** The logical screen sits inside the device's safe area, so
controls never meet the notch, the status bar or the home indicator. The
renderer still covers the whole display: `app_bleed()` is that display in
logical units (the screen plus letterbox bars and safe-area margins, so its
origin is usually negative), and between `gfx_bleed(true)` and
`gfx_bleed(false)` drawing may reach it. Drawing is otherwise clipped to the
logical screen, so nothing spills into the margins by accident. This follows
Apple's game guidance: safe areas are guides for controls, not the margins of
the game, and the environment should use every pixel. Relic Rush draws its
jungle backdrop, its island and the top of its header band this way; the
engine's dialogue and modal dimming cover the whole display too.

`app_pixel_scale()` reports device pixels per logical unit; text uses it to
rasterise at native resolution (crisp on Retina) while all game code stays in
logical units.

## Input

`input_get()` returns a snapshot of one pointer (mouse or first finger):
`pressed`, `released`, `tap` (released without dragging), `dragging` and
per-frame `drag`, `wheel`, two-finger `pinch` and `pinch_center`, plus `key`
and `back`.

UI and world share the pointer without callbacks: every widget registers its
rect; when a press starts on a rect registered in the previous frame, the press
is `captured`. `input_world()` is the same snapshot with captured presses
removed, which is what cameras, boards and cities consume. While a modal is
open, games pass an empty input to the world and call `ui_set_enabled(false)`
while drawing what sits under the dialog.

## Drawing

- **Textures** load through `stb_image` (PNG/JPG/BMP) and are drawn with a tint.
- **Shapes** (`draw_round_rect_grad`, `draw_ring`, `draw_line`, `draw_glow`,
  `draw_shadow`, `draw_poly`) are triangle meshes sent to the shared triangle renderer.
  Each outline gets a one-device-pixel ring fading to transparent, which gives
  anti-aliased edges without MSAA; `draw_shadow` widens that ring into a blur.
- **Camera**: a view rect on screen looking at a world. `camera_input` applies
  drag, wheel and pinch (zooming around the finger), `camera_clamp` keeps the
  view inside the world (`cover`) or centres small worlds, and
  `camera_draw_texture` blits only the visible part of a world-sized image.
- **fx**: a pooled particle system (`fx_burst`, `fx_sparkle`) drawn additively,
  and floating text (`fx_text`) for score pop-ups.

## Text

`font.c` renders TrueType fonts through `stb_truetype`:

- Glyphs are rasterised on demand at the device pixel size and packed into
  1024² atlas pages (shelf packing, up to 8 pages, reset when full). Any
  Unicode text works — Nile Archive is in Russian.
- The atlas stores white coverage only. Colour comes from vertex colours, so
  a vertical **gradient** costs nothing extra and every colour shares the cache.
- **Outlines** and **soft shadows** come from `stb_truetype`'s signed distance
  fields: the SDF is thresholded at `-outline` with a soft edge of `blur`
  pixels, cached per (outline, blur) pair. A styled string is drawn as up to
  three batched layers: shadow, outline, fill.
- Kerning, letter spacing (`tracking`) and font fallback chains are built in.
- `text_box` wraps words into **balanced** lines (the narrowest width that
  keeps the line count), so paragraphs have no lonely last word.
- `text_ink` measures the visible ink of a line and `text_in` places a line by
  its ink, shrinking it to fit: optical centring for buttons and counters,
  independent of a font's ascent and descent.

## UI

`ui_theme` holds colours and text styles; widgets read the current theme.
`ui_button`, `ui_button_frame` (background only, for custom content such as
shop cards), `ui_panel`, `ui_label`, `ui_toast` and `ui_modal_backdrop` cover
both games. Layout is plain rect arithmetic with RectCut plus `rect_col`,
`rect_row` and `rect_align`.

## Saves

A game writes one `serialize(save *s, void *user)` function; `save_read` and
`save_write` call it in read or write mode. Files are `key=value` text, so they
are diffable and forward compatible: missing keys keep their defaults.
Native builds retain the original `corepunch/<id>` save namespace under Application Support (Apple) or the XDG data directory (Linux); the web
build in `localStorage["<id>/<slot>"]`. `save_inject` feeds text from elsewhere
into the next read — Nile Archive uses it to import progress from the old
HTML version's `localStorage["nile-v1"]` JSON.

## City (the meta-game)

```c
typedef struct { const char *name, *about, *sprite_path; texture sprite;
                 float height, width, max_height, sink; size2 footprint;
                 purse cost, reward, needs, income; float income_period; } building_def;
```

- `cost` is paid on placement, `reward` granted once, `needs` must be owned
  (Nile's influence, Relic Rush's stars are never spent), `income` is
  collected by tapping once `income_period` seconds of wall-clock time have
  passed (offline progress included; time comes from `app_clock()`).
- **Terrain and regions come from the game.** `buildable(c, vec2)` says where
  land is; zones are rects by default (Nile's shore strips) or come from a
  `zone_at(c, vec2)` callback (Relic Rush's six flood-filled hex regions).
  Callbacks receive the city so a Lua trampoline can find its closure. A zone
  opens with `city_unlock` when it touches open land (rect contact or the
  game's `zone_touches`), the wallet covers its `needs` and pays its `cost`.
  Closed zones are covered by fog: closed land is sampled once on a fine world
  grid and blurred, so region borders of any shape (Relic Rush's are hex
  staircases) become soft cloud banks. The mask is rebuilt only when a zone
  opens; a frame draws only the visible, foggy cells.
- **Placement.** A building without a footprint keeps `spacing` from others.
  With a `footprint` (half extents of its ground diamond) five probe points
  must be open land and diamonds may touch but not overlap. Placement is
  either instant (`selected`: tap the land) or a session with a ghost
  (`city_begin_place` / `city_begin_move`, drag or tap to move the ghost,
  `city_confirm` or `city_cancel`). A dragged ghost is not snapped until it
  is let go; meanwhile it is `held`, drawn lifted over the green or red
  footprint of the tile it will land on (`city_snap`), where validity is
  checked. With `movable`, dragging a building
  starts moving it. `city_find_spot` searches outwards from a hint.
- **Drawing.** Ground, optional curved paths linking each building to its
  nearest older neighbour, fog over closed zones (under the buildings, which
  always stand on open land, so a tall sprite near the border is never
  veiled), buildings depth-sorted by their anchor's y (the newest one bounces
  in), income bubbles, a `draw_over` hook for the game's labels, then the
  ghost with its green or red footprint (red and see-through when blocked).
- `city_update` returns a `city_event` (`CITY_BUILT`, `CITY_MOVED`,
  `CITY_COLLECTED`, `CITY_PICKED`, `CITY_ZONE`, `CITY_BLOCKED`, …) and the
  game decides how to celebrate or explain it.

## Story

Characters, dialogue and speech bubbles, shared by both games:

```c
typedef struct { const char *id, *name, *role, *portrait_path; texture portrait;
                 color color; bool right; vec2 mouth; } character;
typedef struct { const char *who, *text; bubble_kind kind; } story_line;   /* speech, thought, shout */
```

- `story_setup(cast, n, &style)` registers the cast and how the dialogue looks:
  text and name-tag styles, bubble colours, a backdrop, portrait height, and
  `framed` for busts shown in a medallion (Relic Rush) rather than standing
  cut-outs (Nile Archive).
- `story_play(beat, lines, n)` queues a beat once per save (beats are hashed
  and saved by `story_serialize`); `story_say(who, text)` queues a line every
  time. `story_active()` tells the game to hold its own input and dialogs.
- `story_frame(dt)`, called last in the frame, stages the conversation the
  way Playrix and Wooga story screens do: the speaker stands in their bottom
  corner (sliding in when the speaker changes), the bubble sits at **face
  height** beside them and its tail ends just off their **mouth** (each
  character's `mouth` anchor, measured on the portrait); the previous speaker
  stays on the other side, dimmed and a little smaller, as the listener.
  Comic lettering rules apply (Blambot, Comicraft, Clip Studio lettering guides):
  - the balloon **hugs its words**: lines are balanced and the bubble shrinks
    to the widest one, no wider than a comfortable measure, so there is never
    an empty balloon;
  - the tail is a **short tapered comma** (20 units) on the bubble's bottom
    edge near the speaker, leaning toward their mouth: it says who speaks
    without reaching across to them, and never crosses a face;
  - narration (no speaker) is a centred caption with no tail, and a named
    speaker without a portrait (Volcano's dispatcher) gets a name tag on it.
  On phones (framed busts) the line sits in a **dialogue box**, the way the
  story screens of portrait match-3 games and visual novels do it: the box
  runs along the bottom from the speaker's side, sized to the phrase but never
  narrower than the medallion, which stands just above its end with the name
  plate on the box's edge. There is no tail: next to a framed portrait a tail
  only competes with the frame, and tails are kept for words placed in the
  world (`speech_bubble`) and for the standing figures of the iPad staging.
  The listener stands on the same baseline across the screen, dimmed and smaller.
  A new speaker's bubble springs out of its tail (`ease_out_back`), then the
  text types itself out at 40 characters a second without ever re-wrapping
  (`text_box_reveal`), with a beat after sentences and a shorter one after
  commas and dashes. A tap finishes the line, the next tap moves on; Space
  works too. The optional skip pill (with a fast-forward mark) sits in the
  bottom corner away from the speaker, or above the bubble's far end when a
  listener stands in that corner.
- Bubble kinds: **speech** (rounded body, curved tapered tail), **thought** (a
  cloud of puffs with detached, shrinking puffs as the tail) and **shout**
  (spikes evenly spaced along a rounded box, so long and short lines burst
  alike, and one long straight spike to the speaker). Body and tail are drawn
  as one shape — an outline pass of both, then a fill pass of both with the
  tail's root reaching into the body — so no seam shows where they meet. The
  tail is a single convex polygon (a straight leading edge and a bowed
  trailing one), so it has one smooth anti-aliased rim. Filled polygons
  feather outward whichever way their points wind. Layouts know how far each kind reaches past its box,
  so spikes and puffs stay on screen.
- `story_next()` moves on as a tap would (for timed sequences and captures).
- `speech_bubble(tip, text, style, …, kind)` is the bubble on its own: placed above
  a point (below when there is no room), kept on screen, tail on the point —
  for words over the world, like Relic Rush's restored wonders.

## Audio

`sfx_tone(hz, seconds)` plays a soft bell-like note (Relic Rush chimes rising
notes as cascades grow). The native C API `sfx_play(sample, volume, pan)` mixes
up to 16 unsigned 8-bit mono PCM samples into 44.1 kHz stereo, with source-rate
conversion, volume and panning. The sample descriptor is copied; its PCM storage
must remain valid until playback ends or `sfx_stop_samples()` returns. One audio
device serves samples and tones and opens on first playback. `--mute` and
`sfx_enable(false)` silence both; disabling clears queued voices and tones.

The native C APIs in `raster.c` draw indexed sprites into caller-owned ARGB
surfaces, including clipping, density, hotspots, flip, flash, shadow and fade.
`photo.c` loads images through `image_load_rgba`, removes backgrounds and builds
an indexed atlas with a shared 31-colour palette and configurable display
density. `photo_free` releases the set and atlas. These APIs contain no game
resource formats; Clayfight converts their results into its own frames and
alternate palettes. They are C APIs for native modules, not Lua bindings.

## Platform notes

- **Native**: corepunch/platform owns the window, GL context, events and audio.
  The engine streams colored and textured triangles through OpenGL 3.2 or ES 3.
  `--headless --shot file.png` hides the window for screenshot runs; Linux CI
  uses Xvfb and Mesa. `make test-platform` checks actual pixels and queued input.
- **iOS**: `axRunApplication` gives UIKit ownership of the frame loop. The
  launcher starts the game after its scene is laid out. Touch, pinch, focus
  cancellation and Retina scale come from platform.
- **Web**: Emscripten and platform's WebGL backend, requiring WebGL 2.
  `web/shell.html` is a fullscreen canvas (`100vw × 100dvh`); platform sizes
  its drawing buffer for `devicePixelRatio`. Assets preload at `/data`.
  `web_audio.c` supplies a WebAudio device for the platform mixer because its
  upstream hardware playback backend currently has no browser implementation.

Make and WebAssembly pipe unity include lists from `tools/unity.sh` directly
into the compiler. Xcode generates temporary `u_*.c` files in its build directory
from the same recipe. The individual engine modules are included by those units.
Lua is isolated in its own unit to avoid static-name collisions.

## Script

`script.c` is the Lua runtime: one state per game with a sandboxed standard
library (no `io`, `os`, `package`, `debug`), a `require` that resolves inside
the game's `lua/` folder, the main-loop trampolines (`init`, `frame`, `quit`
from the descriptor `main.lua` returns), and the few bindings a generator
cannot write: save visitors, the cast, the theme and the city's callbacks.
`launcher.c` is `main()` for every game, built once per game with the game's
folder compiled in. Everything else Lua can call lives in the generated
`api_lua.c`; the description it is generated from is `api.xml` and the
generator `tools/luagen.py`. The details are in [SCRIPTING.md](SCRIPTING.md).

## Testing

`make test` first checks that the generated glue, reference and annotations
match `api.xml` (`make gen-check`), then runs the engine tests
(`tests/test_main.c`: vector and rect maths, RectCut, the camera round trip
and clamping, purses, save round trips and defaults, city placement,
footprints, sessions, moving, income and zones, story beats) and, in the same
binary's Lua state without a window, every file in `tests/lua/`: `api.lua`
(the generated API: operators, in/out arguments, handles, callbacks) and
`relic.lua` (Relic Rush's rules, ported from the original prototype, including
the greedy bot's campaign runs). Relic Rush's `--smoke` drives the real game
loop through injected mouse clicks from the first swap to the second level,
which catches stuck states and broken input routing. The Lua port itself was
verified by rendering every documentation screenshot and reel frame with both
the C and the Lua games and comparing them pixel for pixel.

## Possible next steps

- Music streaming alongside the sampled-sound mixer.
- Texture atlases / sprite sheets and frame animation for characters.
- A tween helper for UI transitions (games currently use `ease_*` directly).
- Removing placed buildings, and building upgrades.
- iOS and Android packaging for the engine (both games target the iPad).
- Localisation tables instead of string literals.
- An error screen for script errors instead of exiting, for development builds.
- Hot reload of a game's Lua files while it runs.

## Atlas animation and route graphs

The third game, Volcano, adds `sprite.c` for authored atlas frames, animation
timing and shared draw/pick bounds, `nav.c` for blocked geometric graphs and
elliptical target approaches, and `ui.progress` for themed meters. These are
game-independent APIs, described in [LUA_API.md](LUA_API.md). Volcano's Lua code
owns its worker jobs and campaign rules. See [the port assessment](../games/volcano/docs/PORT.md).

Native verification can isolate save files with `SPRITE_SAVE_DIR`, an existing
writable directory. Normal play continues to use the existing per-game save directories.
