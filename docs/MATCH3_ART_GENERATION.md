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
  Keep chips brighter and more saturated than carpet, oil and stone. Judge this
  with chips over the patches, including a green chip over green carpet.
- Keep carpet a single deep, muted green. Give it fine low-contrast texture.
  Avoid bands, stripes, motifs, contrasting threads and light trim. Oil is quiet
  amber-brown with soft glints. Stone is subdued gray with small same-hue cracks.
  Goal icons use the material's own hue.
- Keep the Homescapes power-up silhouettes. Rockets are short capped cylinders
  with clearly readable axes. The bomb is round with a short fuse. The plane has
  a broad triangular fold. In Homescapes the rocket reads purple first, with
  yellow on the stripe and ends. Use that hierarchy for a dark red rocket
  with a small gold accent. The rainbow ball is the deliberate exception to
  the two-hue limit, with a few large color panels.

| Chip color | Christmas Market | Relic Rush |
| --- | --- | --- |
| Yellow | Bell | Flat-top sun idol |
| Red | Candy cane | Flame |
| Green | Holly | Jade leaf |
| Cyan-blue | Ornament | Scarab |
| Violet | Bauble | Crystal cluster |
| Orange | Gingerbread person | Amphora |

## Author the atlas

1. Inventory the names and states used by the rules, the board, the HUD and the
   guide. The game catalogues are the starting point. Keep all states of a
   family together, including all three rocket axes, one to three stone hits,
   one and two layers of restraints, and any mirrored layout the rules use.
2. Use one ImageGen call per game atlas. Give it a row-by-row slot list, the
   local Homescapes shapes as reference and the palette above. Request true
   RGBA, generous transparent gutters, no text and no baked object shadows.
   Give the generator separate slots for the three quiet, edge-to-edge square
   material swatches and their freestanding goal icons. Request small authored
   oil glints on alpha and separate same-hue stone damage marks.
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

1. Crop and scale uniformly. Rotate the independently painted rockets to the
   exact +30°, 90° and −30° axes. Preserve authored alpha on objects. Apply
   the [canonical flat-top mask](../engine/art/hex-tile/README.md) to full-cell
   sprites. Keep carpet, oil and stone as swatches for the board's continuous
   surface mask. Keep carpet and stone's bevel and soft contact shadow in the
   renderer so they follow the outer edge as the patch changes.
2. Run `python3 tools/match3_atlas.py` to pack `data/match3.png`, then
   `python3 tools/match3_atlas.py --check`. Record the packed frames in the
   [Christmas Market catalogue](../games/christmas-market/docs/asset-catalogue.md)
   or [Relic Rush catalogue](../games/relic-rush/docs/asset-catalogue.md).
3. Run `python3 tools/hex_tile_art.py` in strict `object`, `frame`, or
   `fill` mode as appropriate. Check the actual board at 480×900 and 390×844
   with all six kinds, chips on patches, all six power-up frames, all stone
   strengths and any changed restraints. Use the existing capture suite.
   Inspect each board at actual size, including the goal icons. Reject any
   swatch that is readable as a pattern before the chips are readable as colors.

Optional chip packs and reference-only source levels have their own inventories.
Reuse this palette and review process when generating replacements for them.
