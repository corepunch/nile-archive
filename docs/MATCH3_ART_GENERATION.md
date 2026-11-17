# Match-3 board art

Use the recreated Cradle of Rome board as the readability reference. A player
should be able to scan six chip colors and see which cells hold a tablet on a
phone. Keep the game's own silhouettes and materials.

## Color and visual hierarchy

- Give each chip one primary hue and at most one secondary hue. The body should
  read as the primary at a glance. Use the secondary for one recognizable
  feature, such as a cream spiral on the red candy cane. Keep the rest of the
  modeling in shades of the primary. Keep the six chip colors distinct at
  phone size. Use Relic Rush's first row as a reference for how much detail a
  one-hue chip can carry.
- Use the same chip frame on the board and in color-specific goals and previews.
  Keep chips more saturated than the board tiles.
- Carved stones face the viewer and use the board's flat-top hex outline, with
  sandstone in Relic Rush and cool slate in Christmas Market. Each stone has
  one hit and shares its sprite with the goal display and guide.
- Tablets and every other cell state use the Cradle of Rome hex tiles in
  `engine/art/board-tiles`; there is no separate floor material.

| Chip color | Christmas Market | Relic Rush |
| --- | --- | --- |
| Yellow | Bell | Flat-top sun idol |
| Red | Candy cane | Flame |
| Green | Holly | Jade leaf |
| Cyan-blue | Ornament | Scarab |
| Violet | Bauble | Crystal cluster |
| Orange | Gingerbread person | Amphora |

## Booster icons from the retired power-ups

The engine has no special pieces, so no rocket, bomb, plane or rainbow ball is
drawn on a board. Two paintings survive as booster icons. Christmas Market's
Shooting Star and Firework Bomb buttons use the painted row rocket and bomb from
the bottom row of the [power-up paint sheet](../art/match3-power-up-paint/source.png).
`tools/match3_theme_art.py` registers them as `booster-star-icon` and
`booster-firework-icon`, sized to fixed target areas (`REFERENCE_AREAS`).
`games/christmas-market/tools/prepare_bonus_buttons.py` bakes them into the
booster buttons. The sheet's [prompt](../art/match3-power-up-paint/prompt.txt)
and [edit target](../art/match3-power-up-paint/scener-strip.png) are the
provenance. The Scener models that set its geometry have been deleted.

## Author the atlas

1. Inventory the names and states used by the rules, the board, the HUD and the
   guide. The game catalogues are the starting point. Keep all states of a
   family together, including
   one and two layers of restraints, and any mirrored layout the rules use.
2. Use one ImageGen call per game atlas. Give it a row-by-row slot list, the
   palette above. Request true RGBA, generous transparent gutters, no text and
   no baked object shadows.
3. For a separate set of controls, author normal, selected, pressed, hover and
   disabled in that set's single atlas. Use the existing authored interaction
   art when the controls are outside the change. A color filter or overlaid
   glyph is never a replacement for an authored state.
4. Preserve the source PNG and exact prompt under the game's `art/` tree.
   Record the source, crop, placement, rotation, state names, runtime path and
   reproduction command. The campaign source recipes live in
   [Christmas Market](../games/christmas-market/art/board-theme/) and
   [Relic Rush](../games/relic-rush/art/board-theme/).

## Register and review

1. Crop and scale uniformly. The atlas importer fits each chip to a common
   visible-area target (`REFERENCE_AREAS` in `tools/match3_theme_art.py`,
   pixels at half opacity or greater) inside the inset hex, favoring centered
   placement. The manifest records the target, fitted area and placement.
   Preserve authored alpha on objects. Apply
   the [canonical flat-top mask](../engine/art/hex-tile/README.md) to full-cell
   sprites. The carved stone face uses the exact canonical mask.
2. Run `python3 tools/match3_atlas.py` to pack each kind of art into its own
   atlas in `data/board/` ([Asset layout](ASSET_LAYOUT.md)). Run
   `python3 tools/match3_atlas.py --check`. Record the packed frames in the
   [Christmas Market catalogue](../games/christmas-market/docs/asset-catalogue.md)
   or [Relic Rush catalogue](../games/relic-rush/docs/asset-catalogue.md).
3. Run `python3 tools/hex_tile_art.py` in strict `object`, `frame`, or
   `fill` mode as appropriate. Check the actual board at 480×900 and 390×844
   with all six kinds, carved stones, tablets and any changed restraints. Use
   the existing capture suite. Inspect each board at actual size, including
   the goal icons.

Optional chip packs have their own inventories.
Reuse this palette and review process when generating replacements for them.
