# Match-3 board art

Use the Homescapes board as the readability reference. A player should be able to
scan six chip colors, spot a power-up and see which cells have a floor objective
on a phone. Use the local [chip and power-up references](../engine/art/homescapes/sprites/)
and [hex rules](HOMESCAPES_HEX.md). Keep the game's own silhouettes and materials.

## Color and visual hierarchy

- Give each chip one primary hue and at most one secondary hue. The body should
  read as the primary at a glance. Use the secondary for one recognizable
  feature, such as a cream spiral on the red candy cane. Keep the rest of the
  modeling in shades of the primary. Keep the six chip colors distinct at
  phone size. Use Relic Rush's first row as a reference for how much detail a
  one-hue chip can carry.
- Use the same chip frame on the board and in color-specific goals and previews.
  Keep chips more saturated than floor materials. Check the jade leaf on
  mosaic, the blue scarab on silt, and the holly and blue ornament on
  lanternlight and powder snow.
- Relic Rush uses a slate-blue and limestone mosaic for restored cells and
  matte rose-brown silt for the advancing hazard. Christmas Market uses a
  warm apricot glow with a soft inside edge for lit cells and matte
  winter-white powder for snow. Carved stones face the viewer and use
  the board's flat-top hex outline, with sandstone in Relic Rush and cool slate
  in Christmas Market. Each stone has one hit and shares its sprite with the
  goal display and guide.
- Keep the Homescapes power-up silhouettes and color placement. Use broad,
  distinct color areas that survive phone-size rendering. The rainbow ball
  uses multiple hues. Its enamel tiles are discrete rounded squares in three
  rows of six around a dark violet sphere, with bare poles. Tiles foreshorten
  toward the edges, with a dark gap around each tile. Keep the round
  silhouette.

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
`booster-firework-icon`, sized to the extracted Homescapes rocket and bomb
silhouettes, which stay unregistered in
[the Homescapes sprites](../engine/art/homescapes/sprites/).
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
   local Homescapes shapes as reference and the palette above. Request true
   RGBA, generous transparent gutters, no text and no baked object shadows.
   Give the generator separate slots for the opaque square material swatches,
   and their freestanding goal icons. The terrain source sheet includes both
   games' materials and icons.
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

1. Crop and scale uniformly. The atlas importer measures visible pixels at
   half opacity or greater in the native Homescapes alpha masks. It uses the
   median of the six chip masks as a common chip target and the median of
   the two rocket masks for all three axes. Both games scale the painted
   rockets to 80% of their original width and height during registration.
   Bomb, rainbow, plane and delivery
   each have their own reference. Target areas account for the smaller chip
   and delivery draw quads. Fit each silhouette inside the inset hex and
   favor centered placement. Narrow or asymmetric shapes can land below the
   area target to preserve their shape and clearance. The plane is capped at
   84 px on its longest side, well under its area target, so the thin shape
   stays inside the cell like the chips. The manifest records
   the target, fitted area and placement for review.
   The Scener target places the rockets on the +30°, 90° and −30° axes.
   Preserve authored alpha on objects. Apply
   the [canonical flat-top mask](../engine/art/hex-tile/README.md) to full-cell
   sprites. The carved stone face uses the exact canonical mask. Mosaic and
   lanternlight use board-anchored swatches under connected surface masks.
   The river silt and powder snow swatches are cropped to the flat-top face
   of each affected cell at draw time.
2. Run `python3 tools/match3_atlas.py` to pack `data/match3.png` for the board
   and its effects, and `data/match3-hud.png` for the controls and HUD. Run
   `python3 tools/match3_atlas.py --check`. Record the packed frames in the
   [Christmas Market catalogue](../games/christmas-market/docs/asset-catalogue.md)
   or [Relic Rush catalogue](../games/relic-rush/docs/asset-catalogue.md).
3. Run `python3 tools/hex_tile_art.py` in strict `object`, `frame`, or
   `fill` mode as appropriate. Check the actual board at 480×900 and 390×844
   with all six kinds, chips on patches, all six power-up frames, carved stones
   and any changed restraints. Use the existing capture suite.
   Inspect each board at actual size, including the goal icons. Reject any
   swatch that is readable as a pattern before the chips are readable as colors.

Optional chip packs and reference-only source levels have their own inventories.
Reuse this palette and review process when generating replacements for them.
