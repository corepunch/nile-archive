# Buried finds: art prompts

These are the original excavation prompts and registration notes. The
excavation commands refer to commit `78fbe020`. The
[current catalogue](../../docs/asset-catalogue.md#collectible-story-pieces)
records the collection sprites.

The [board dressing atlas](../../docs/asset-catalogue.md#story-materials) now supplies the dig
surfaces from section 1. The laid-out timber and cable use their own footprints in section 2.
[Issue #102](https://github.com/corepunch/nile-archive/issues/102) tracks the broader long-find work.
The [selected crank](../../docs/asset-catalogue.md#chapter-1-quest-objects) has its
own four-option source sheet and uses its existing excavation footprint.

Style references for the original production requests: [source.png](source.png) (the eight existing props)
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

| Find | Board | Cells | Footprint |
| --- | ---: | ---: | --- |
| Camp timber | 1 | 7 | Thick stack of irregular boards across two staggered rows, rising to the right |
| Relay cable | 3 | 6 | Zigzag down two neighbouring columns, alternating left and right |

See the [footprint guide](laid-finds-guide.png) and [exact production prompt](laid-finds-states.prompt.txt).
One master sheet contains the painted and charcoal states for both finds. Registration places
each state on a separate transparent board canvas. Run `python3 tools/relic_quest_art.py --overlay-dir /tmp/relic-finds`
from the repository root and compare the overlays with the game. The goal and recovered-item
cards keep the compact original props.

The selected shutter crank remains on its compact excavation footprint.
