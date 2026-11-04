# Shared UI states

## Chapter 1

The browser, journal and cache result use measured `ui.form` layouts with the Nile skin. The browser and journal use stable search and clue IDs.

| Control | Meaning and states |
| --- | --- |
| Search row | Painting thumbnail, clue count and best Stars. Play, search for clue B or replay. Locked rows show the missing clue, Influence or fountain. |
| Journal | Earned notes in clue order, with an empty state before the first find. Back returns to the browser. |
| Cache row | Locked until all nine clues, ready when the chain can start, completed after the reward. |
| Cache target | Shows one named item and its position in the four-item chain. Correct taps advance, and the existing hint highlights the current target. |
| Cache result | Shows the final journal note, 150 Coins and the title of the next chapter. The button returns to the island. |

### Chapter 1 captures

| Screen | 1200×900 | 1368×1026 |
| --- | --- | --- |
| Search browser | [Chapter 1](screenshots/chapter-one/browser.jpg) | [Larger iPad](screenshots/chapter-one/ipad-browser.jpg) |
| Courtyard revisit | [Search](screenshots/chapter-one/courtyard.jpg) | [Larger iPad](screenshots/chapter-one/ipad-courtyard.jpg) |
| Library revisit | [Search](screenshots/chapter-one/library.jpg) | [Larger iPad](screenshots/chapter-one/ipad-library.jpg) |
| Temple cache | [First target](screenshots/chapter-one/cache.jpg) | [Larger iPad](screenshots/chapter-one/ipad-cache.jpg) |
| Search reward | [New clue](screenshots/chapter-one/reward.jpg) | [Larger iPad](screenshots/chapter-one/ipad-reward.jpg) |
| Completed cache | [Chapter result](screenshots/chapter-one/cache-result.jpg) | [Larger iPad](screenshots/chapter-one/ipad-cache-result.jpg) |
| Journal | [All ten entries](screenshots/chapter-one/journal.jpg) | [Larger iPad](screenshots/chapter-one/ipad-journal.jpg) |
| Opening dialogue | [Longest line](screenshots/chapter-one/dialogue.jpg) | [Larger iPad](screenshots/chapter-one/ipad-dialogue.jpg) |
| Decorations | [Influence and footprint](screenshots/chapter-one/build.jpg) | [Larger iPad](screenshots/chapter-one/ipad-build.jpg) |

```sh
make CFLAGS="-O2 -g -Werror" nile-archive build/test/nile-archive
./build/test/nile-archive "shot chapter-one-" "shot ipad-chapter-one-"
```

On Linux, run the test command under `xvfb-run -a`. The prototype [browser](screenshots/chapters.jpg) and [search reward](screenshots/reward.jpg) show the prior layout.

## Rewards, chapter gates and building purchases

The [prototype economy review](review/economy/README.md) covers the result, chapters,
building list, initial estate, purchase preview and minimum-reward restoration
route at 1200 x 900, 1368 x 1026 and 1600 x 900. Source: `lua/archive_island.lua`,
`lua/archive_dialogs.lua` and `lua/archive_economy.lua`; shared controls/layout: `engine/ui_forms.lua`. The
existing five building sprites, Coin and Influence icons, fonts, theme and
button rendering are reused. No runtime bitmap, icon set or ImageGen prompt is
added. The repeatable building list uses `form:set_items` with stable IDs 1–5,
one price/payoff/requirement data source and measured rows. Both the build tray
and chapter browser use the shared scrolling list.

| Presentation/control | Meaning and supported states |
| --- | --- |
| Coin result | Actual base + first-clear + newly improved Star + clean-search payout; informational |
| Scene Stars | Best time rating or guaranteed clear count up to three, whichever is higher. Improvements award Coins once. |
| Influence | Existing estate icon; building-only cumulative progress, never a scene payout or spendable balance |
| Chapter button | Opens the search browser, including the cache and journal. The notification dot signals a ready goal. |
| Building row | Sprite, price and Influence. Decorations also show footprint size. Restorations become unavailable after purchase. |
| Category arrows | Engine buttons in the tray header wrap through «Восстановление», «Все постройки» and 11 catalogue categories. The selected category scrolls below the header. |
| Buy/close | Engine buttons with normal/hover/pressed/focus; Buy disabled for locked or unaffordable stock |
| Purchase preview | Existing city ghost/valid-invalid footprint; shows cost and Influence return; charges only on confirmation |
| Goal | Shows missing Influence and opens the building list, or opens chapters when ready |

The 96 decorations are documented in [building-catalogue.md](building-catalogue.md); the tray
lists any category with `--screen build --catalogue <category> --catalogue-page N`.
Reproduce with `--screen win`, `first-win`, `chapters`, `build`, `first-build`, `purchase`,
`opening` and `island`. `--smoke` covers all five searches, the replay gates, purchases, the ordered cache and the journal using actual control input.
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

## Island roads

`archive_island.lua` explicitly disables automatic building connectors with
a transparent `city.path` (matching the previous default). Paths painted into
`data/island.png` remain part of the terrain. Reviewed iPad and 16:9 captures
are in [the road removal comparison](review/no-auto-roads/README.md).

## Placement alignment guides

`placement-guides` uses the shared `engine/city.c` renderer. While moving or
placing a building, other buildings show neutral cream outlines with dark
contrast edges around their occupied ground, including placement clearance.
The building in hand retains its green/red footprint; its original location
is omitted. Guides stay visible after release until Confirm/Cancel, then hide.
The guides use the existing camera and tile measurements; artwork, alpha,
footprints and collision rules are unchanged. No bitmap or ImageGen source is
added. Reproduce with the existing native-input hold/placement captures in the
[review](../../../docs/review/city-placement-guides/README.md).
