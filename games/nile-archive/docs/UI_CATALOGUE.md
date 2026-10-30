# Shared UI states

## City move strip

Source: the `move_form` resource in `lua/main.lua`, using `engine/ui_forms.lua`,
`ui_theme` from `setup_theme`, and the shared city gesture in `engine/city.c`.
No bitmap, generated icon or runtime asset file is added.

| Control/content | Meaning and states |
| --- | --- |
| `name` | Moving building's name, informational title |
| Instruction | Drag the preview or tap a free location; informational label |
| `cancel` | Cancel preview and retain the original location; normal, hover (mouse), pressed, keyboard focus |
| `confirm` | Commit a valid move at no cost; normal, hover, pressed, keyboard focus; disabled when terrain/zone/collision validation fails |
| Ghost | Existing building sprite lifted while held, snapped on release, green valid footprint / red blocked preview; original layout remains unchanged until confirmation |

The engine measures and places the strip and handles hit testing/focus. The
native accent button uses the theme's dark `accent_text` over its gold fill.
Both labels use 21-point PT Sans Bold and the existing engine text effects:
Cancel has a cream-to-gold gradient, dark one-pixel outline and soft shadow;
Confirm has a dark teal-to-ink gradient and a one-pixel pale embossed shadow.
These styles are shared by normal, hover, pressed, focus and disabled controls;
the button surface and focus ring communicate interaction state while the labels
retain their contrast. No icon atlas or generated state artwork is involved.
The panel blocks world input, and its buttons cannot inherit the release of
the world press that opened it. Esc cancels the move. A short drag remains map
navigation; a stationary half-second hold picks up a building. Pinch/capture or
pointer cancellation cannot promote a pending hold.

[Issue #21](https://github.com/corepunch/nile-archive/issues/21) tracks this audit.
See [native-input before/after captures and reproduction](../../../docs/review/city-long-press/README.md).
Canonical captures are `screenshots/nile-long-press.jpg`, `nile-ipad-long-press.jpg`
and `nile-wide-long-press.jpg`; `make shots` reproduces them.

See [button typography review](../../../docs/review/button-text/README.md) for
reviewed captures at 1200×900, 1368×1026 and 1600×900, button states and
reproduction commands. Source: `setup_theme` in `lua/main.lua`; rendering:
`engine/ui_forms.lua` and `engine/font.c`. This is authored text styling, with
no ImageGen prompt or added runtime texture.
