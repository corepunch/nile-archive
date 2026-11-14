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

## Rocket, bomb and plane briefs

| Sprite | Homescapes shape and color placement | Christmas Market | Relic Rush |
| --- | --- | --- | --- |
| Rocket | A short, symmetric cylinder with a narrow waist, two thick rounded collars and two blunt cone tips. Wind contrasting diagonal bands round the waist so two show from any side. The tips use the band color. Keep the whole set consistent across +30°, vertical and −30°. Target 65% primary and 35% secondary. | Cranberry red `#B9243D` on the body and collars. Vanilla ivory `#F5D89A` on the tips and band. | Terracotta red `#A8362D` on the body and collars. Old gold `#E6AE47` on the tips and band. |
| Bomb | A round sphere seen from near its pole, with a narrow belt just above the equator. At the pole a raised ring of the body color surrounds an inset disc, where a short rope fuse with a lit tip stands. The belt and disc share one secondary hue. Keep the body about 70% of the visible area. | Evergreen `#177449` body, warm gold `#E8A940` fittings. | Petrol teal `#126D70` body, ochre gold `#E8AC43` fittings. |
| Plane | A plain folded paper plane angled up-right, with a center crease and one wing panel folded under. One hue, shaded by the folds alone. Both games use the same painting. | Icy blue. | The same painting in parchment: `#EAC985` midtones, `#96622C` shadows. |

The hex colors specify midtones. Model the surfaces with light and dark values
within those two hue families. Read the rocket axis from the line joining its
two tips. Distinguish the bomb by its spherical outline and short fuse, and
the plane by its broad folded wing.

## Model the power-ups

The rockets, bomb and rainbow ball are solids of revolution and tiles on a
sphere, so `tools/match3_specials.py` models them for
[Scener](https://github.com/corepunch/orion-ui) and renders them. This keeps
their geometry exact where painted versions drifted. The plane stays
painted. Relic Rush registers Christmas Market's plane with its blues
remapped by luminance to parchment (`PLANE_SHADES` in
`tools/match3_theme_art.py`), at the user's request. The drawing and alpha
are unchanged.

- **Rocket.** One lathe with cone tips, collars and a banded waist. Each board
  axis is the same model turned about the view direction, so the three
  sprites are identical apart from the rotation. The upper tip leans 8°
  towards the viewer.
- **Bomb.** A sphere whose pole points up and to the left, 36° off the view
  direction. The belt is a band of latitude standing proud of the sphere. The
  ring, inset disc, rope fuse and lit tip sit on the pole.
- **Rainbow ball.** Each tile is a rounded square in the sphere's own
  latitude and longitude, raised along a bevel profile. A tile narrows towards
  the pole and foreshortens at the edge as the sphere does.

A game supplies its palette, gloss and tile bevel in `THEMES`. Christmas
Market's tiles are pillows and Relic Rush's have a flat face and a chamfer.
The lighting is a bright ambient with a key from the upper left, so midtones
match the briefs above. No light casts shadows. The rocket waist is cut into
rings that darken under each collar, since a Scener shape takes one gradient.

```sh
python3 tools/match3_specials.py                 # both games; needs scener on PATH
python3 tools/match3_specials.py relic-rush --sheet /tmp/specials.png
python3 tools/match3_specials.py --check         # the committed scenes are current
python3 tools/match3_atlas.py                    # register the renders
```

Each game keeps the generated scene and its five 512 px transparent renders in
`art/board-theme/specials/`. Commit them with the tool. `--check` compares the
scene text only, so `make test` needs no Scener. Change the tool to change a
model, and review the sheet against the
[Homescapes sprites](../engine/art/homescapes/sprites/) before the board.

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

1. Crop and scale uniformly. The atlas importer measures visible pixels at
   half opacity or greater in the native Homescapes alpha masks. It uses the
   median of the six chip masks as a common chip target and the median of
   the two rocket masks for all three axes. Bomb, rainbow, plane and delivery
   each have their own reference. Target areas account for the smaller chip
   and delivery draw quads. Fit each silhouette inside the inset hex and
   favor centered placement. Narrow or asymmetric shapes can land below the
   area target to preserve their shape and clearance. The manifest records
   the target, fitted area and placement for review.
   The rendered rockets already lie on the exact +30°, 90° and −30° axes.
   Preserve authored alpha on objects. Apply
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
