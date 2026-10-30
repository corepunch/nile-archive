# Shared UI engine

The engine owns form resources, layout, controls, interaction/focus, model exchange
and modal composition. A game supplies its skin, model and action handlers. This
work is tracked in [issue #12](https://github.com/corepunch/nile-archive/issues/12).

![One resource with two skins, captured from the engine](screenshots/ui-skins.jpg)

## Resource and model exchange

The approach follows Orion's [declarative dialogs and DDX](https://github.com/corepunch/orion-ui/blob/1cf7e7272ab68665615c7c8b307b612e0b62c26a/docs/dialogs.md): a resource defines controls and a static binding table maps control IDs to model fields.
The [identity dialog](https://github.com/corepunch/orion-ui/blob/1cf7e7272ab68665615c7c8b307b612e0b62c26a/apps/gitclient/dialogs/dlg_identity.c) demonstrates push on opening, pull on acceptance, and game/application-owned actions. Here, Lua field paths replace C struct offsets; the renderer and input primitives remain native C.

```lua
local settings = {audio = {sound = true}}
local form = ui.form{
    root = {kind="column", panel=true, padding=24, gap=16, children={
        {kind="label", text="Settings", height=44, role="title"},
        {kind="toggle", id="sound", height=48,
         on_text="Sound on", off_text="Sound off"},
        {kind="button", id="accept", text="Apply", height=48, accent=true},
    }},
    bindings = {{id="sound", field="audio.sound", type="boolean"}},
}
assert(form:push(settings))
-- In the frame, after drawing the game:
ui.modal_layer(7, color(5,22,22,185))
local action = form:draw(rect(40,200,400,260), skin)
if action and action.id == "accept" then
    local ok, message = form:pull(settings)
    if ok then close_settings() else show_validation(message) end
end
```

`push(model)` validates and populates the controls. Editing changes the form's
values; the model changes only on `pull(model, validator?)`. Pull first validates
**all** fields and the optional validator, then commits them together. Cancelling
can discard the form without touching the model. Both return `ok, message?`.

Bindings have `id`, `field`, `type` (default `string`), optional `min`, `max` and
`readonly`. Types are `string`, `boolean`, `integer`, `number`, `texture`.
Paths such as `audio.sound` and `cost.1` support tables and numeric array keys.
Readonly bindings populate display controls but do not write back. False booleans
are preserved. Missing paths, wrong types and invalid ranges reject transfer.
Use `form:set(id,value)` / `form:get(id)` for computed display data; `form.values`
also holds visibility/enabled predicates.

## Layout and controls

| Node | Responsibility |
| --- | --- |
| `column`, `row` | Automatic flow with padding, gaps, fixed lengths and weighted `grow` |
| `list` | Data-backed row/column stack, populated with `form:set_items(id,records)` |
| `overlay` | Children share the same content bounds |
| `label` | Text/formatting, optional wrap, style or semantic role |
| `image` | Bound/authored texture, fitted to its allocated bounds |
| `button` | Command ID; pointer, disabled, focus and keyboard activation |
| `toggle` | Bound boolean with on/off captions; same interaction as a button |
| `progress` | Bound fraction through the engine meter |
| `spacer` | Fixed or flexible space |
| `custom` | Game-specific painting inside engine-assigned bounds |

Every node may have `width`, `height`, `min_width`, `min_height`, `grow`, `padding`,
`gap`, `visible=false`, or `visible_field`. Containers support cross-axis
`align="start|center|end|stretch"`. Buttons support `enabled=false`,
`enabled_field`, `accent` and `flat`. Interactive controls require unique string
IDs. Templates reject duplicate IDs, unknown kinds, invalid sizes/bindings and
excessive nesting. Construction copies the node tree so instances have independent
layout, values and focus.

Labels support `text_align="start|center|end"` (default `center`). Icon-and-copy
rows use `start` for both title and wrapped description. A row measures fixed
icon/control widths first, then wraps flexible copy in the remaining width;
its measured height grows with the text.

### Data-backed stacks

```lua
local help = ui.form{kind="list", id="topics", gap=12, item=function(record)
    return {kind="row", gap=14, align="center", children={
        {kind="image", image=record.icon, width=64, height=64, visible=record.icon~=nil},
        {kind="column", grow=1, gap=4, children={
            {kind="label", text=record.title, wrap=true,
             text_align=record.icon and "start" or "center"},
            {kind="label", text=record.description, wrap=true,
             text_align=record.icon and "start" or "center"},
        }},
    }}
end}
assert(help:set_items("topics", records))
```

The source is a dense array of records with stable string/integer `id` keys
(override the field with the list's `key`). The builder returns an ordinary node
resource; the engine instantiates, measures and stacks it. `direction="row"`
selects a horizontal list; the default is `column`. Rows are cached between
frames. Call `set_items` again to refresh/reorder the source or pass `{}` to clear
it. The engine validates the complete replacement before committing it, so bad
keys, malformed rows or builder errors preserve the current list.

Control IDs and visibility/enabled references are scoped to each record. Stable
keys preserve keyboard focus across reordering; removal releases it. Row actions
include `{id,kind,value,source,key}`: the action/control ID, list ID and record
key let the game update its model and refresh the source. Source records remain
game-owned. `node.value` supplies an initial control value on refresh. Generated
control IDs are available through `form.nodes`/`form.boxes` for inspection.

`form:measure(width,skin)` gives intrinsic width/height.
`form:layout(bounds,skin)` exposes ID-to-rectangle results for inspection/tests.
`form:draw(bounds,skin,options?)` lays out, paints and returns one action
`{id,kind="click|change",value}` or nil. `options.interactive=false` disables input
for a lower modal; `options.input` can supply a test input snapshot; `options.hit_offset` aligns hit
regions with a skin’s translated/animated painting. Tab moves
focus in resource order; Return/Space activate the focused control. Disabled
controls are excluded. Pointer activation uses the engine's press-origin and drag
rules. Touch has no artificial hover state.

## Skins

A skin can provide a native `ui_theme` and `styles` keyed by node role/kind.
The same resource then gets different colours, corner radii and typography.
A skin may provide `style(node)` for dynamic logical-unit typography: measurement
uses the same font/size as paint, before the game animation transform. Custom
`label` callbacks honour the resource's `text_align`.
For authored artwork, `button_states` accepts `normal`, `selected`, `pressed`,
`hover`, `disabled` textures. The engine selects the state and uses its authored
pixels; it does not synthesize a disabled or selected texture.

Custom paint callbacks are `panel(bounds,node)`, `button(bounds,state,node)`,
`button_text(bounds,caption,node,state)`, `label(bounds,caption,node,style)` and
`focus(bounds,node)`. They own paint only; the engine still owns hit testing,
focus, activation and layout. `state` includes `hot`, `held`, `clicked`, `disabled`,
`selected`, `focused`. Theme changes are scoped to the form draw and restored.

Relic Rush supplies one skin through its existing painting helpers. Its pause
resource binds sound and reduced motion; its building resource binds the name,
art, description, cost row and action caption. Games retain gameplay actions such
as claiming rewards or entering placement mode. Its Explorer's guide uses a
stable-key source and one icon/copy row resource. The game paints authored icon
layers inside assigned bounds; the engine owns placement, wrapping, spacing and
the footer button.

## Modal layers and input ownership

![Nested layers: game and first dialog blurred, top dialog sharp](screenshots/ui-layers.jpg)

```lua
local modals = ui.modals(skin)
assert(modals:open("settings", form, settings, {width=400, blur=7}))
-- frame:
if modals:begin() then update_game() end -- disable underlying UI/world input
render_game()
local action = modals:draw(dt, {reduced_motion=reduced_motion})
if action and action.id == "accept" then
    if form:pull(settings) then modals:close(action.modal) end
elseif action and action.kind == "cancel" then modals:close(action.modal) end
```

`open(id,form,model,options)` pushes model values and a layer. Options include
`bounds`, `width`, `height`, `blur`, `dim`, and a `cancel` command ID (default
`cancel`). Automatic bounds centre the measured form within the logical screen.
Each layer blurs/dims all earlier drawing; the next layer can blur the previous
dialog too. Only the top form receives input. Escape emits its cancel action.
`close(id?)` closes only the top layer; duplicate open IDs are rejected.
`active()` reports whether any modal is open. Call `begin()` before underlying
widgets/update, then `draw()` after the game. Screen-wide blocking includes safe
areas. Reduced motion makes the backdrop transition immediate.

Existing screens can use `ui.modal_layer(radius,dim)` directly before their
custom dialog. `gfx.backdrop(radius,dim)` is the drawing-only equivalent. Drawing
order defines the layers; no per-game framebuffer management or duplicated world
rendering is required. `ui.modal_backdrop(t)` uses `ui_theme.backdrop_blur` and
`dim`; `story_style.backdrop_blur` enables the same engine effect for dialogue.
Zero blur preserves existing games' sharp backdrops.

## Gaussian renderer, verification and boundaries

The GPU resolves the current framebuffer, prefilters it in **two successive
half-size steps**, and runs a separable Gaussian at quarter resolution. It
computes contiguous Gaussian weights; adjacent taps share bilinear samples.
This avoids the grid/comb artifacts caused by spacing a tiny kernel apart. The
kernel is capped at 33 taps (at most 17 filtered samples per direction). Targets
are cached, reallocated on resize and released on renderer shutdown. Production
blur has no CPU pixel readback. Native GL, ES 3 and WebGL 2 use the same path.
The actual platform framebuffer, viewport, scissor and drawing state are restored.
On target/shader allocation failure it reports the problem and retains dimming.

A local Mac sample at 960×1800 measured **2.92 ms** for Gaussian blur **plus
synchronized RGBA readback**, averaged over 12 warm frames. The readback is in the
test only. This is a desktop measurement; mobile hardware performance is not yet
measured. `tests/test_backdrop.c` checks clip restoration, full-screen coverage,
sharp later drawing, nested blur, dim-only composition and resize/reallocation.
`tests/lua/forms.lua` checks binding transactions, layout/reflow, focus and
validation. The real-window fixture checks bound toggles, deferred commit and
nested modal input.

```sh
make gen                         # after API or engine/ui_forms.lua changes
make CFLAGS="-O2 -g -Werror"
make test
make test-platform               # prefix with xvfb-run -a on Linux
./build/relic-rush --headless --mute --fresh --lua tests/fixtures/ui \
  --data games/relic-rush/data --size 900x700 --smoke
```

The fixture accepts `--nested --shot file.png`; without `--nested` it shows two
skins using the same template. `make shots` captures both. The runtime embeds
`engine/ui_forms.lua` through the generated `engine/ui_forms_lua.h`; native,
iOS and web games use the same implementation without extra game resources.

This core supports display, action and boolean controls. Text-entry/IME, combo
boxes, scrolling containers, screen-reader integration and a visual resource
editor are not implemented here. Add those behaviours to the engine and extend
its tests/skin contract when needed. This is an adoption path for the existing
immediate-mode games, rather than a port of Orion's native window/message system.
