# Buried finds: art prompts

The [board dressing atlas](../../docs/asset-catalogue.md#story-materials) now supplies the dig
surfaces from section 1. The laid-out finds in section 2 remain tracked in
[issue #102](https://github.com/corepunch/nile-archive/issues/102).

Style reference to attach to both requests: [source.png](source.png) (the eight existing props)
and a current board capture, [find-half.jpg](../../docs/screenshots/find-half.jpg).

## 1. Dig-site surfaces

Replaces the river-silt tint over a buried find, and gives uncovered cells a floor that keeps the
find's footprint readable after the silt is gone. Both are material swatches sampled into the hex
face, like `oil-material`, so they need no hex outline.

```text
Use case: stylized-concept. Production material swatches for the painted mobile archaeology match-3 game Relic Rush. One image, landscape 2:1, exactly TWO equal SQUARE swatches side by side with no gap, no border and no gutter between them. Each swatch is completely OPAQUE and painted edge to edge, corners included: full bleed, zero rims, zero outlines, zero vignette, no hex shape drawn. Straight-on top view, flat ground seen from directly above, no perspective, no horizon.

LEFT swatch, "packed dig sand": warm pale ochre beach sand packed over something buried. Fine even grain across the WHOLE square, a few small half-sunk pebbles and two or three tiny shell fragments scattered evenly, faint shallow trowel scrapes running lower-left to upper-right. Bright and clearly lighter and warmer than a dark jade-green board, so a patch of it reads at a glance as "dig here". Low contrast inside the swatch: no large stones, no dark holes, no objects, no footprints.

RIGHT swatch, "excavated trench floor": the same sand dug out to a shallow pit floor. Darker damp umber-brown earth, compacted, with fine crumbs and a few tiny pale sand grains fallen in. Clearly darker and cooler than the LEFT swatch and clearly browner than jade green, so a brass, timber or leather object lying on it stands out. Even texture across the WHOLE square, no rim of sand around it, no shadow at the edges.

Both swatches: hand-painted casual-game finish matching the attached props, soft light from upper left with NO overall gradient across a swatch, texture features no larger than one tenth of the swatch so it can be mirrored and tiled without visible repeats. No text, letters, digits, labels, UI, watermark, grid lines, tools, relics or figures.
```

Acceptance:

- Each swatch crops to a square and resizes to 128×128 with no rim; mirrored tiling shows no seam.
- On the board at 480×900 and 390×844, a covered seven-cell cluster is obvious on first sight of
  board 1, and the six relic colours stay readable on both surfaces.
- The cover is the covered state and the trench floor is the uncovered state; neither is derived
  from the other by recolouring.

## 2. Finds laid out along the board

Three objects whose story shape is long. Each is painted in the pose and direction it will lie in,
because the board does not rotate art. Proportions are of the prop's own bounding box; R is one
cell's radius on the flat-top hex board.

| Find | Board | Cells | Footprint | Prop bounding box |
| --- | ---: | ---: | --- | --- |
| Camp timber | 1 | 4 | Straight diagonal run rising to the right, 30° above horizontal | 3:2 landscape (6.5R × 4.3R) |
| Relay cable | 3 | 6 | Zigzag down two neighbouring columns, alternating left and right | 4:7 portrait (3.5R × 6.1R) |
| Shutter crank | 10 | 4 | Three cells straight down, plus one cell lower-right of the bottom cell | 4:7 portrait (3.5R × 6.1R) |

```text
Use case: stylized-concept. One transparent PNG sprite sheet for the painted mobile archaeology match-3 game Relic Rush. Exactly 3 isolated props seen from DIRECTLY ABOVE, lying flat on the ground, top-down orthographic view with no perspective. Landscape 16:9 sheet. Generous empty transparent margin around every prop; the props must not touch or overlap. Match the attached reference props exactly in materials, palette and paint finish: these are the same three objects, laid out flat.

Prop 1, left third of the sheet, "camp timber": the same bundle of three cut cedar construction beams bound with rope, now as three LONG straight beams lying side by side. The bundle runs in a straight line from lower-left to upper-right at 30 degrees above horizontal. Its bounding box is 3:2 landscape and the beams span almost the full diagonal of that box. Two rope lashings, one near each end. Beam bundle is thick: its width is about one quarter of its length.

Prop 2, middle third, "relay cable": the same worn copper relay cable with dark cloth insulation, now UNCOILED and laid out as one continuous loose S-curve running from top to bottom. Its bounding box is 4:7 portrait. The cable swings left, right, left, right, left, right in six shallow evenly spaced bends, each bend reaching the side of the box, with one brass collar near the top and a frayed bare-copper end at the bottom. The cable is fat and bold: its thickness is about one quarter of the box width. No coils, no knots, no crossing over itself.

Prop 3, right third, "shutter crank": the same antique brass L-shaped shutter crank with a wooden grip, laid flat. Its bounding box is 4:7 portrait. A long straight brass shaft runs vertically down the LEFT side of the box for the full height, with the obvious square fitting at the top. At the bottom the arm turns and extends down and to the right at 30 degrees below horizontal, ending in the wooden grip at the lower-right corner of the box. Shaft thickness about one quarter of the box width.

All three: crisp bold silhouettes that stay recognisable when two thirds of the object is hidden, hand-painted dimensional adventure-game props, warm light from upper left, comparable paint weight. Real transparency around each prop. No ground, sand, dirt patch, cell plates, hex shapes, frames, borders, scene, figures, UI, letters, digits, labels, glow, watermark, or shadows outside the prop.
```

Acceptance:

- Laid over its footprint, each object's centre line passes through every listed cell and no cell
  is empty of paint.
- With every cell but one still covered, the visible slice already suggests the object.
- The goal icon and the **Item recovered!** card keep the existing compact props, so check that
  the laid-out and compact versions read as the same object side by side.

## Using them

- Surfaces: register both swatches beside `oil-material`, then draw the cover for levels with
  `oil_still` and the trench floor under uncovered find cells (`engine/match3_elements_view.lua`).
- Long finds: extend `tools/relic_quest_art.py` to write `data/finds/timber.png`, `cable.png` and
  `crank.png` from the new sheet at each footprint's proportions, and replace `cluster(...)` with
  the listed cells for boards 1, 3 and 10 in `lua/campaign.lua`. Board 8 also uses the `cable`
  slot, but only for its goal and card, so it is unaffected.
- Re-run the bot sample after changing footprints: a four-cell find is easier than a seven-cell
  one, and the six-cell cable spans most of a chamber.
- Record sources, prompts, transforms and reviewed captures in the manifest and the catalogue.
