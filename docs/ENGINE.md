# Engine architecture

The engine is about 3,000 lines of C11 in eight modules behind one header,
[`engine/engine.h`](../engine/engine.h). It targets 2D sprite games with menus,
dialogs and a build-your-place meta-game: hidden objects, match-3, merge,
solitaire, word games and the like.

```
            game (games/<name>/main.c)
   ┌────────────┬────────┬──────────┬──────────┐
   │ city │ story │ ui │ save │ fx/audio │   meta-game, dialogue, widgets, persistence, juice
   ├────────────┴────────┴──────────┴──────────┤
   │   gfx: textures, shapes, camera │ font     │   drawing
   ├─────────────────────────────────┴──────────┤
   │   core: window, logical screen, input, loop │   platform (SDL2, Emscripten)
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
2. **One public header.** Every module's internals are `static`. Games include
   `engine.h` and nothing else; a game needing more than one source file adds
   at most one header of its own (Relic Rush has `relic.h` so the tests can
   share its rules).
3. **Zero means default.** Descriptors (`app_desc`, `text_style`, `camera`,
   `building_def`, `ui_theme`) work with designated initialisers that only name
   what differs, in the spirit of the sokol headers.
4. **Immediate mode.** Screens are functions that lay out, react and draw in
   one pass every frame. There is no retained widget tree to keep in sync.
5. **Engine knows mechanics, games know content.** The city module knows how
   to place, sort, draw, pay for and collect from buildings; it does not know
   what "coins" or "influence" are. Resources are just slots in a `purse`.

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
screen is exactly the design and SDL letterboxes the rest. Relic Rush is a
480 × 900 portrait game laid out in absolute coordinates; on an iPad it is a
centred column.

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
  `draw_shadow`, `draw_poly`) are triangle meshes sent to `SDL_RenderGeometry`.
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
Native builds store them under `SDL_GetPrefPath("corepunch", id)`, the web
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
- **Terrain and regions come from the game.** `buildable(vec2)` says where
  land is; zones are rects by default (Nile's shore strips) or come from a
  `zone_at(vec2)` callback (Relic Rush's six flood-filled hex regions). A zone
  opens with `city_unlock` when it touches open land (rect contact or the
  game's `zone_touches`), the wallet covers its `needs` and pays its `cost`.
  Closed zones are covered by fog: a vertex grid sampled over the world, so
  region borders of any shape fade softly.
- **Placement.** A building without a footprint keeps `spacing` from others.
  With a `footprint` (half extents of its ground diamond) five probe points
  must be open land and diamonds may touch but not overlap. Placement is
  either instant (`selected`: tap the land) or a session with a ghost
  (`city_begin_place` / `city_begin_move`, drag or tap to move the ghost,
  `city_confirm` or `city_cancel`). With `movable`, dragging a building
  starts moving it. `city_find_spot` searches outwards from a hint.
- **Drawing.** Ground, optional curved paths linking each building to its
  nearest older neighbour, buildings depth-sorted by their anchor's y (the
  newest one bounces in), income bubbles, fog, a `draw_over` hook for the
  game's labels, then the ghost with its green or red footprint.
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
  Comics' rule applies: tails aim at the head or mouth and never cross a face.
  On narrow screens the bubble runs along the bottom with the speaker's
  medallion standing on it and a short tail aimed at their mouth.
  Text types itself out without ever re-wrapping (`text_box_reveal`); a tap
  finishes the line, the next tap moves on; Space works too, and an optional
  skip pill sits in the corner away from the speaker.
- Bubble kinds: **speech** (rounded body, tapered tail), **thought** (a cloud
  of puffs with shrinking puffs as the tail) and **shout** (fixed-length
  spikes around a superellipse, one long spike to the speaker). Body and tail
  are drawn as one shape — an outline pass of both, then a fill pass of both
  with the tail's root reaching into the body — so no seam shows where they
  meet.
- `story_next()` moves on as a tap would (for timed sequences and captures).
- `speech_bubble(tip, text, style, …, kind)` is the bubble on its own: placed above
  a point (below when there is no room), kept on screen, tail on the point —
  for words over the world, like Relic Rush's restored wonders.

## Audio

`sfx_tone(hz, seconds)` plays a soft bell-like note on a one-voice synthesiser
(Relic Rush chimes rising notes as cascades grow). The audio device opens on
the first note; `--mute` and `sfx_enable(false)` silence it.

## Platform notes

- **Native**: vsync'd SDL renderer, software fallback. Headless runs use
  `SDL_VIDEODRIVER=offscreen` plus `--shot`, which is how the documentation
  screenshots and the CI smoke test are produced.
- **Web**: a preview target only. Emscripten with the SDL2 port; `web/shell.html` is
  nothing but a fullscreen canvas. The canvas is sized by CSS
  (`100vw × 100dvh`); SDL resizes the drawing buffer with `devicePixelRatio`.
  Assets are preloaded from `games/<name>/data` to `/data`.

## Testing

`make test` runs the engine tests (`tests/test_main.c`: vector and rect maths,
RectCut, the camera round trip and clamping, purses, save round trips and
defaults, city placement, footprints, sessions, moving, income and zones) and
Relic Rush's rule tests (`tests/test_relic.c`, ported from the original
prototype, including 300 greedy campaign runs). Relic Rush's `--smoke` drives
the real game loop through injected mouse clicks from the first swap to the
second level, which catches stuck states and broken input routing.

## Possible next steps

- A mixer for music and sampled sounds next to the tone synthesiser.
- Texture atlases / sprite sheets and frame animation for characters.
- A tween helper for UI transitions (games currently use `ease_*` directly).
- Removing placed buildings, and building upgrades.
- iOS and Android packaging for the engine (both games target the iPad).
- Localisation tables instead of string literals.
