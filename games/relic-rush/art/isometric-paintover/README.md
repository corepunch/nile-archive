# ImageGen paint-over of the Blender grid study

Generated with the built-in ImageGen tool on 2026-10-30, in one edit call for all
ten buildings together. This is the requested paint-over, not a Blender model
or material edit. The original Blender source and original game art are intact.

- **Edit target / geometry reference:**
  `../isometric-blender/preview/scene.png` (2520×870).
- **Style reference:** `../buildings.png`, the original Relic Rush building set.
- **Exact generation prompt:** `prompt.txt`.
- **Generated master:** `buildings-paintover.png` (2134×737 RGB, green grid retained).
- **Meaning/state:** the same ten restored buildings and source-study footprints,
  in the same order and arrangement; no authored interaction-state set added.
- **Runtime paths:** `data/buildings/0..9.png` and independent
  `data/building-shadows/0..9.png`, exported by `tools/building_assets.py`.

The prompt locks the source camera, footprints, ground pivots, scale and structural
edges, and requests the original game's painted sandstone, teal/gold ornament,
wood, fabric, terracotta, foliage and water. Visual inspection covers all ten
buildings and the complete grid composition. ImageGen returned a smaller image;
its scale relative to the source is approximately 0.8468 horizontally and 0.8471
vertically. The opaque paint-over master is retained unchanged. Transparency
comes from the separate ImageGen extraction edit described below.

The second whole-atlas ImageGen edit, `buildings-transparent.png`, removes the
grid and cast shadows. Its exact prompt is in `extraction-prompt.txt`. Painted
sprites are spatial crops of this authored RGBA master: no recolouring, warp,
procedural glyphs or alpha reconstruction. `registration.json` records crops,
source tile sizes, pixel pivots and base widths; `lua/building_art.lua` is generated.

`render_shadows.py` uses the unchanged Blender master and camera to render each
building in isolation onto a transparent Cycles shadow catcher. Persistent
source passes are in `shadows/0..9.png`. The importer registers their pixel
scale to the atlas using a documented Lanczos resize, crops meaningful alpha
with an 8px feather margin, and records independent shadow pivots. Shadow alpha
is retained. The engine draws all shadows below all buildings; lift/pop affect
only the painted sprite. Blocked placement retains the existing red ghost and
a neutral grounded shadow. Cards and rewards draw the sprite alone.

The game adopts the study footprints: camp/well/observatory 2×2, workshop/market
3×2, gateway 4×2, lodge/archive/fountain 3×3, temple 4×4. Older saves re-snap and
use the engine's nearest legal open spots without spending resources or losing
buildings/stamps; an impossible migration rolls back atomically.

All ten bases and pivots, valid/blocked/held placement, cards and rewards were
reviewed in [real-game captures](../../docs/review/painted-buildings/README.md)
at 480×900 and 390×844 with phone safe areas. This fixes
[issue #15](https://github.com/corepunch/nile-archive/issues/15).

Reproduce with the built-in ImageGen edit tool, supplying the geometry reference
first and the style reference second, using the saved prompt and an opaque
background. Retain the committed output as the master because regeneration is
nondeterministic. No dependencies were downloaded for this paint-over.

Export with `python3 games/relic-rush/tools/building_assets.py`; `--check`
verifies decoded RGBA pixels and all generated registration data. `make test`
runs that check. Re-render shadows with an existing Blender installation:
`Blender --background --python games/relic-rush/art/isometric-paintover/render_shadows.py`.

| Geometry reference | ImageGen paint-over |
| --- | --- |
| ![Original Blender render](../isometric-blender/preview/scene.png) | ![Relic Rush style paint-over](buildings-paintover.png) |
