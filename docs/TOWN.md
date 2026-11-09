# Shared town screen

Relic Rush, Christmas Market and Nile Archive draw their town (island, market,
estate) with one engine module, `require("town")` (`engine/town.lua`). The
layout, behaviour and controls are the same in every game. Each game supplies
only a JSON file, a skin and hooks.

```lua
local town = require("town")
R.town = town.new(R.island, town.load("town.json"), hooks)
R.town:frame(inp, dt, R.overlay == R.OV_NONE)   -- once per frame
```

## What the engine owns

- The map under the whole display (`app.bleed()`), its background colour and
  optional weather (`weather.snow`, anchored to the world so a pan carries the
  flakes).
- Region markers over closed zones: `+` with a breathing glow when the region
  can open now, `?` otherwise, the zone's name below. A tap calls `hooks.zone`.
- **Tapping a building opens a word bubble**, never a dialog: its name and
  words from `hooks.about(item)`. The next tap anywhere dismisses it. Holding a
  building for half a second still lifts it (the city mover).
- Placement: `view:begin(kind, focus, item)` lifts a new or placed building.
  Cancel and Confirm stand under it, and nothing is charged until Confirm
  (`hooks.can_buy`, `hooks.placed`).
- The header: wallet capsules (`hooks.capsules`, left- or right-aligned) and
  the menu button (`hooks.menu`) in the top-right corner.
- The bottom row: the Build badge (`navigation_build`), the Play badge
  (`navigation_play`) and a middle control between them. That is a round
  button (`middle_icon`, `middle`) or the game's own card (`kind: "custom"`,
  `draw_middle`). `hide_bottom` hides the row while a game panel replaces it.
- `view.buttons` (`build`, `play`, `middle`, `menu`) and `view.placement_form`
  give tests real control positions.

## data/town.json

Every field is optional; the engine defaults are in `engine/town.lua`, and
`null` clears a default.

| Key | Meaning |
|---|---|
| `background` | Colour behind the map (`#RRGGBB[AA]`). |
| `header` | `x`, `y`, `width`, `height`, `gap`, `overhang`, `align` (`left`/`right`), `role` (the skin's resource variant), `menu.size`/`inset`/`y`. |
| `bottom` | `margin`, `bottom`, `height`, `build` and `play` badge widths. `middle.kind` is `round` or `custom`; `diameter`, `gap`, `from_bottom` and `colors` style the round button. |
| `placement` | Cancel/Confirm `button` size, row `min_width`/`max_width`, and the `gap`, `margin`, `top` and `bottom` limits. |
| `markers` | `visible`, `label` size, `label_width`, `glow`, `text` (skin text style). |
| `bubble` | `width`, `seconds` (0: until the next tap), `fill`, `edge`. |
| `focus` | `lift` and `min_zoom` when a placement starts. |
| `weather.snow` | `height`, `fade_from` and `layers` (`count`, `radius`, `fall`, `drift`, `opacity`). |
| `texts` | The notices: `placing`, `unchanged`, `blocked`, `cant_afford`, `cant_buy`, `no_room`. |

`app.read_text(path)` reads the file from the data root, and `json.decode`
(`engine/json.lua`) parses it. `tests/lua/town.lua` covers the decoder, the
merge and every game's file.
