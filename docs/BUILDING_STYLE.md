# Painted building style, references and prompts

Relic Rush, Nile Archive and Christmas Market use detailed hand-painted surfaces
over registered Blender geometry. The current `painted-v1` pass covers **234
normal sprites**: 96 Relic Rush objects, 101 Nile Archive objects and 37 Christmas
Market objects, including decorations. The raw renders establish perspective,
silhouette, scale and foundations; the paint pass supplies the finished materials
and detail. Returning to smooth, unpainted renders loses the accepted finish.

[BUILDINGS.md](BUILDINGS.md) defines placement and the camera;
[BUILDING_ART.md](BUILDING_ART.md) defines modelling and importing. This guide
defines what the finished artwork should look like and where its sources live.

## Shared finish

- **Readable form, rich surfaces.** Keep the model's large forms and clear
  silhouette. Add hand-cut masonry joints, carving, roof tiles, wood grain,
  cloth folds and stitching, believable wares, individual foliage and water
  highlights. Detail should remain legible at the game's actual display size.
- **Painted materials.** Use deliberate highlights, warm/cool shading and small
  surface variations. Avoid flat toy-like plastic, featureless low-poly surfaces
  and uniform noise applied over every material.
- **Controlled lighting.** Preserve the render's lighting direction. Warm lamps,
  windows and flames are painted into the object. The engine's separately
  registered ground shadow stays grounded during pickup; do not paint another
  external cast shadow into the normal sprite.
- **A complete set.** Paint related objects together in category atlases so their
  palette, detail density and finish agree. Keep small decorations at their
  registered world scale; enlarging an atlas guide for painting does not enlarge
  the runtime object.
- **Authored transparency.** Request a transparent output with clear gutters.
  Preserve complete foundations and all legitimate parts. Import by spatial
  crop, uniform resize and translation, preserving the authored RGBA inside the
  crop. Do not reconstruct masks or manufacture states with recolouring.

## Each game's direction

| Game | Palette and materials | Detail and atmosphere | Actual generation style reference |
| --- | --- | --- | --- |
| Relic Rush | Warm sandstone, teal/jade and gold ornament, terracotta roofs, timber and canvas | Weathered masonry, carved motifs, rope lashings, stitched tents, lush tropical leaves, lively turquoise water and amber lanterns | [Earlier painted detail reference](../games/relic-rush/art/building-catalogue/detail-reference.png) |
| Nile Archive | Ivory limestone and mudbrick, lapis/turquoise, gold, pottery, woven reeds and fabric | Ptolemaic Egyptian carving and hieroglyphic reliefs, weathered stone, date-palm fronds, flowering vines and reflective water | [Earlier gardener's-house painting](../games/nile-archive/art/building-0.png) |
| Christmas Market | Timber, stone, evergreen, red ribbons and gold, warm amber light against cool blue snow | Wood grain, thick pillowy snow, individual fir needles, dense garlands and berries, bows, carefully painted gifts and stall wares | [Building direction sheet](../games/christmas-market/art/building-reference-sheet.png) |

These references guide **surface style**, not the geometry or camera. In
particular, Relic's earlier paintings use the retired 2:1 view. Never copy that
perspective back into a current sprite. The live camera comes from
`engine/engine.h` through `tools/city_camera.py`.

Additional historical context remains in Relic's `paintover-*.png` and their
prompts, Nile's `art/building-0.png` through `building-4.png` (also used as model
design references), and Christmas's retired `art/buildings.png` atlas. These are
not additional image inputs to the current generation calls unless the reference
index explicitly lists them.

## Exact prompt and reference indexes

Each index records the ordered image inputs, prompt, raw output, layout, SHA-256
of the reference files and accepted runtime keys for every generation. Paths in
an index are relative to that game's root. `imports.json` records the accepted
per-key atlas cell, crop, scale, pivot and output dimensions.

| Game | Reference and prompt index | Accepted sources | In-game review |
| --- | --- | --- | --- |
| Relic Rush | [references.json](../games/relic-rush/art/building-catalogue/painted-v1/references.json) | [Atlas directory](../games/relic-rush/art/building-catalogue/painted-v1/README.md) | [Before/after and 24 footprint pages](../games/relic-rush/docs/review/painted-buildings/current-camera/README.md) |
| Nile Archive | [references.json](../games/nile-archive/art/building-catalogue/painted-v1/references.json) | [Atlas directory](../games/nile-archive/art/building-catalogue/painted-v1/README.md) | [Before/after and 12 footprint pages](../games/nile-archive/docs/review/painted-buildings/current-camera/README.md) |
| Christmas Market | [references.json](../games/christmas-market/art/building-catalogue/painted-v1/references.json) | [Atlas directory](../games/christmas-market/art/building-catalogue/painted-v1/README.md) | [Before/after and 10 footprint pages](../games/christmas-market/docs/review/painted-buildings/current-camera/README.md) |

Representative complete prompts:

- Relic: [story wonders](../games/relic-rush/art/building-catalogue/painted-v1/wonder-prompt.txt),
  [shop buildings](../games/relic-rush/art/building-catalogue/painted-v1/building-prompt.txt),
  [hedge correction](../games/relic-rush/art/building-catalogue/painted-v1/hedge-prompt.txt).
- Nile: [five restorations](../games/nile-archive/art/building-catalogue/painted-v1/restoration-prompt.txt),
  [catalogue buildings](../games/nile-archive/art/building-catalogue/painted-v1/building-prompt.txt).
- Christmas: [market wishes](../games/christmas-market/art/building-catalogue/painted-v1/wonder-prompt.txt),
  [cottages](../games/christmas-market/art/building-catalogue/painted-v1/cottage-prompt.txt).

### Prompt structure for the next pass

Use the saved category prompt as the starting point, keeping these instructions:

1. **Image 1 is the edit target:** an atlas assembled from the current registered
   renders. **Image 2 is style only:** the game's reference listed above. The
   isolated hedge correction uses only its geometry guide.
2. Name the game and category, then state its palette, material details, lighting
   and expected hand-painted polish. Specify the complete object count and grid
   where needed.
3. Preserve the target's camera, perspective, identities, silhouettes, sizes,
   positions, foundation corners, row order, empty cells and aspect ratio. Do not
   copy the style reference's camera or substitute another object design.
4. Require complete sprites inside their cells, generous transparent gutters,
   zero-alpha background, no labels/grid/backdrop and no external cast shadows.
5. Save the literal prompt, ordered references and untouched output before
   importing. Image generation is not deterministic: a fresh generation needs
   visual review even when the prompt and references are unchanged.

## Accepted corrections and rejected versions

Relic's first wonder pass had insufficient gutter space for the temple. Its
input, output, layout and prompt remain under
[`versions/first/`](../games/relic-rush/art/building-catalogue/painted-v1/versions/first/).
The active `wonder-*` files are the replacement with enlarged painting guides and
complete foundations. The Sunstone courtyard keeps its mosaic plaza design; the
old bridge/gateway painting is not its replacement.

The first Relic bush atlas interpreted the hedge as a carved stone block. Keep
the raw atlas as history, but use the separate `hedge-*` correction for runtime
key `hedge`. The reference index excludes that key from the bush atlas's accepted
keys and records the correction as the accepted source. Never import a rejected
output merely because it is newer or appears in the same directory.

## Reimport, regenerate and review

To reproduce the runtime sprites from the **saved accepted outputs**, install
`tools/requirements-assets.txt` and run:

```sh
python3 tools/import_painted_buildings.py relic-rush
python3 tools/import_painted_buildings.py nile-archive
python3 tools/import_painted_buildings.py christmas-market
python3 tools/buildings.py --check
```

The importer writes runtime PNGs, registration, generated Lua, manifests and the
review sheet. Do not edit generated `lua/building_sprites.lua` by hand.

To **create new art**, render matching geometry with `make buildings GAME=<game>`,
assemble category guides with recorded layouts/display scales, and regenerate
with the saved prompts and ordered references. A camera or model change requires
new matching guides and new paint-overs. `make buildings` produces raw renders;
it does not itself reproduce the painted finish. Retain prior versions and record
which output supplies each accepted key.

Review the full sheet and actual game captures for missing or repeated objects,
unwanted design substitutions, clipped bases, floating generation fragments,
noisy edges, covered water and inconsistent materials. Inspect every affected
`--building-review` page with `--footprints`: foundations and pivot dots must align
with the reserved ground. Also check the shop, card, placement and island views
at the supported sizes in [AGENTS.md](../AGENTS.md). Keep before/after captures in
the PR, pinned to the reviewed commit. Existing normal sprites remain the only
authored world state; lift, placement and validity feedback stay engine effects.
