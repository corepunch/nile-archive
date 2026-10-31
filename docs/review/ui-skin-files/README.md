# Skin files

Each game's look becomes one data file compiled by the engine's `ui.skin`. See
[skin files](../../UI_ENGINE.md#skins).

## Shared UI fixture: two skin files, every control and state

The same template, now with a bound checkbox, a disabled checked checkbox, a
progress bar and a disabled/accent button pair, drawn by
`tests/fixtures/ui/sunstone_skin.lua` and `tests/fixtures/ui/nightfall_skin.lua`.
Before, both skins were native-theme colour tables with no checkbox.

| | Before | After |
| --- | --- | --- |
| Two skins | ![Before](before-ui-skins.jpg) | ![After](after-ui-skins.jpg) |
| Nested modals | ![Before](before-ui-layers.jpg) | ![After](after-ui-layers.jpg) |

## Relic Rush: same pixels, now from `lua/skin.lua`

Relic Rush's hand-written paint (`R.pal`, `R.panel`, `R.paint_button` and the form
skin callbacks) is replaced by `games/relic-rush/lua/skin.lua`. Captures at
480×900 and 390×844 (47/34 safe-area insets) of pause, guide, building card,
shop, expeditions, victory, failure, finale, region card, island, placement and
board are **pixel-identical** to `main` (24 captures). So are 6 more that exercise the
animated dialog transform and the pressed state: the pause and card pop-in
frames, the mid-animation victory card, and held presses on RESUME, the card's
action and the guide's button.

| | Before (`main`) | After |
| --- | --- | --- |
| Pause | ![Before](before-relic-pause.jpg) | ![After](after-relic-pause.jpg) |
| Building card | ![Before](before-relic-card.jpg) | ![After](after-relic-card.jpg) |
| Shop | ![Before](before-relic-shop.jpg) | ![After](after-relic-shop.jpg) |
| Victory | ![Before](before-relic-victory.jpg) | ![After](after-relic-victory.jpg) |

| Pressed RESUME (sinks 2 units) | Pause pop-in (transform) |
| --- | --- |
| ![Pressed](after-relic-pause-press.jpg) | ![Pop](after-relic-pause-pop.jpg) |
