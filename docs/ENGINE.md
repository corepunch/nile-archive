# Engine architecture

The engine is about 2,300 lines of C11 in six modules behind one header,
[`engine/engine.h`](../engine/engine.h). It targets 2D sprite games with menus,
dialogs and a build-your-place meta-game: hidden objects, match-3, merge,
solitaire, word games and the like.

```
            game (games/<name>/main.c)
   ┌────────────┬────────┬──────────┬──────────┐
   │   city     │   ui   │   save   │   fx     │   meta-game, widgets, persistence, juice
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

Games are designed against a resolution (both games use 1200×900). The
logical screen keeps the design's **short side** and grows along the long side
with the device, up to `max_aspect`:

| Device | Logical screen |
| --- | --- |
| iPad landscape 4:3 | 1200 × 900 |
| 16:9 monitor | 1600 × 900 |
| phone landscape 19.5:9 | 1950 × 900 (Relic Rush; Nile caps at 16:9 and letterboxes) |
| phone portrait | 900 × 1950 (the design rotates) |

Layouts are cut from `app_screen()`, so they adapt instead of stretching;
Relic Rush switches to a stacked layout when `screen.size.h > screen.size.w`.
Landscape-only games set `.landscape = true` and the engine shows a rotate
prompt in portrait. `app_pixel_scale()` reports device pixels per logical unit;
text uses it to rasterise at native resolution (crisp on Retina) while all game
code stays in logical units.

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
- Kerning, letter spacing (`tracking`), font fallback chains, word wrapping
  (`text_box`) and shrink-to-fit (`text_fit`) are built in.

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
                 float height, sink; purse cost, reward, needs, income;
                 float income_period; } building_def;
```

- `cost` is paid on placement, `reward` granted once, `needs` must be owned
  (stars in Relic Rush), `income` is collected by tapping once
  `income_period` seconds of wall-clock time have passed (offline progress
  included; time comes from `app_clock()`).
- Zones are world rects that unlock in order for a `purse` each; locked zones
  are tinted. Placement checks the world bounds, unlocked zones, a game-supplied
  `buildable(vec2)` terrain test and the minimum spacing between buildings.
- Buildings are depth-sorted by their anchor's y. Desktop users get a
  green/red placement ghost under the mouse; touch users tap to place.
- `city_update` returns a `city_event` (`CITY_BUILT`, `CITY_COLLECTED`,
  `CITY_CANT_AFFORD`, …) and the game decides how to celebrate or explain it.

## Platform notes

- **Native**: vsync'd SDL renderer, software fallback. Headless runs use
  `SDL_VIDEODRIVER=offscreen` plus `--shot`, which is how the documentation
  screenshots and the CI smoke test are produced.
- **Web**: Emscripten with the SDL2 port. The canvas is sized by CSS
  (`100vw × 100dvh`); SDL resizes the drawing buffer with `devicePixelRatio`.
  Assets are preloaded from `games/<name>/data` to `/data`.

## Testing

`make test` runs `tests/test_main.c` headless: vector and rect maths, RectCut,
the camera round trip and clamping, purses, save round trips and defaults, city
placement/income/zones, and the match-3 rules (specials, chain reactions,
gravity, plus 600 random moves checking that the board never holds a match or
a hole when it settles). Relic Rush's `--autoplay N` bot plays whole levels
through the real animation state machine, which catches stuck states.

## Possible next steps

- Audio (SDL audio with a small mixer for effects and music).
- Texture atlases / sprite sheets and frame animation for characters.
- A tween helper for UI transitions (games currently use `ease_*` directly).
- Moving or removing placed buildings, and building upgrades.
- Localisation tables instead of string literals.
