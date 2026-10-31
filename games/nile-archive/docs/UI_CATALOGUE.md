# Shared UI states

## Rewards, chapter gates and building purchases

The [economy review](review/economy/README.md) covers the result, chapters,
building list, initial estate, purchase preview and minimum-reward restoration
route at 1200 x 900, 1368 x 1026 and 1600 x 900. Source: `lua/archive_island.lua`,
`lua/archive_dialogs.lua` and `lua/archive_economy.lua`; shared controls/layout: `engine/ui_forms.lua`. The
existing five building sprites, Coin and Influence icons, fonts, theme and
button rendering are reused. No runtime bitmap, icon set or ImageGen prompt is
added. The repeatable building list uses `form:set_items` with stable IDs 1–5,
one price/payoff/requirement data source and measured horizontal item columns.

| Presentation/control | Meaning and supported states |
| --- | --- |
| Coin result | Actual base + first-clear + newly improved Star + clean-search payout; informational |
| Scene Stars | Existing 1–3 best-time rating; improvements award Coins once; no separate spending state |
| Influence | Existing estate icon; building-only cumulative progress, never a scene payout or spendable balance |
| Chapter button | Play/replay when preceding clue and Influence permit; disabled with the missing requirement otherwise; existing normal/hover/pressed/focus/disabled skin |
| Building row | Existing normal sprite; price, Influence return and chapter requirement; no persistent selected state |
| Buy/close | Engine buttons with normal/hover/pressed/focus; Buy disabled for locked or unaffordable stock |
| Purchase preview | Existing city ghost/valid-invalid footprint; shows cost and Influence return; charges only on confirmation |
| Goal | Shows missing Influence and opens the building list, or opens chapters when ready |

Reproduce with `--screen win`, `first-win`, `chapters`, `build`, `first-build`, `purchase`,
`opening` and `island`. `--smoke` plays two scenes, cancels/confirms purchases,
builds the fountain/temple and enters chapter three using actual control input.
Pure economy tests cover minimum/maximum rewards, repeated claims, best-Star
improvements, clue order and legacy scene access. The shared modal stack also
consumes opening-frame input before enabling its controls.

## City move strip

Source: the `move_form` resource in `lua/archive_island.lua`, using `engine/ui_forms.lua`,
`ui_theme` from `setup_theme` in `lua/archive_kit.lua`, and the shared city gesture in `engine/city.c`.
No bitmap, generated icon or runtime asset file is added.

| Control/content | Meaning and states |
| --- | --- |
| `name` | Moving or purchasing building's name, informational title |
| `payment` | Free move, or Coin cost and Influence return after purchase confirmation |
| Instruction | Drag the preview or tap a free location; informational label |
| `cancel` | Cancel preview and retain the original location; normal, hover (mouse), pressed, keyboard focus |
| `confirm` | Commit a valid move at no cost, or purchase at the displayed cost; normal, hover, pressed, keyboard focus; disabled when terrain/zone/collision validation fails |
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
reproduction commands. Source: `setup_theme` in `lua/archive_kit.lua`; rendering:
`engine/ui_forms.lua` and `engine/font.c`. This is authored text styling, with
no ImageGen prompt or added runtime texture.
