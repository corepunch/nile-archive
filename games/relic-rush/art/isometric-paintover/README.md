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
- **Runtime path:** none. This is a review image, not replacement runtime sprites.

The prompt locks the source camera, footprints, ground pivots, scale and structural
edges, and requests the original game's painted sandstone, teal/gold ornament,
wood, fabric, terracotta, foliage and water. Visual inspection covers all ten
buildings and the complete grid composition. ImageGen returned a smaller image;
its scale relative to the source is approximately 0.8468 horizontally and 0.8471
vertically. No image warp, resize, recolouring, background removal or generated
interaction state was applied after generation.

This is an art-direction candidate, not a certification of pixel-exact sprite
registration. Before runtime adoption, measure the actual painted ground corners
and pivots against the source, extract alpha, reconcile the study/game footprint
sizes and review placement states in game. That remaining work is tracked in
[issue #15](https://github.com/corepunch/nile-archive/issues/15).

Reproduce with the built-in ImageGen edit tool, supplying the geometry reference
first and the style reference second, using the saved prompt and an opaque
background. Retain the committed output as the master because regeneration is
nondeterministic. No dependencies were downloaded for this paint-over.

| Geometry reference | ImageGen paint-over |
| --- | --- |
| ![Original Blender render](../isometric-blender/preview/scene.png) | ![Relic Rush style paint-over](buildings-paintover.png) |
