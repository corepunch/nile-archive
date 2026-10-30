# Burning-log particles

The runtime uses `log-fire.png` (two 40-frame layers, eight columns) and
`soot-smoke.png` (four volumetric charcoal billows in a 2×2 atlas). The soot
atlas was authored in one built-in ImageGen call using the supplied building
fire photo as a material reference; its original transparent pixels are used
directly. The exact prompt and generation details are in `soot-smoke.prompt.txt`.
Smoke uses roughly three broad billows at a time, emitted at 0.75 per second
with 3.2–4.2 second lifetimes. Larger individual sprites preserve the authored
lobe detail at game scale, while a short rise keeps the small fire compact.
Two wider flame tongues burn below it, with sparse drifting embers.
The solid object or its optional `fire-foreground` plate hides the main flame
roots, with smaller near-side licks and embers over it. See
[`docs/creating-missions.md`](../../docs/creating-missions.md) for facade art,
emitter alignment and scale. `make test-fire` checks occlusion, animation,
pause, clearing and restart using the original log art.

Repack the original CC0 assets with
`python3 tools/pack_fire_particles.py`. Packing preserves the fire's authored
colors and straight alpha; smoke images are proportionally reduced to 128 px.
`log-smoke.png` is the older CC0 smoke sheet, retained with its source files.
Repacking does not overwrite the authored soot atlas. No runtime network access is needed.

- Fire: **Mikodrak**, [Fire FX – Burning Fire Animation](https://opengameart.org/content/fire-fx-burning-fire-animation),
  CC0. Original download: https://opengameart.org/sites/default/files/FIRE.zip
  (retained in `source/FIRE.zip`). Both the back (`b`) and front (`f`) layers
  are retained with their original 81×123 frames and two-pixel atlas gutters;
  drawing skips the empty top 30 pixels so the tongues fill their emission area.
- Smoke: **Kenney Vleugels**, [Smoke particle assets](https://opengameart.org/content/smoke-particle-assets),
  CC0. Original download: https://opengameart.org/sites/default/files/smokeParticleAssets.zip
  Selected originals `whitePuff00`, `04`, `08`, `12` and the original license
  are retained in `source/`. The remaining unused pack is not required.

Both packs were downloaded on 2026-10-19. CC0:
https://creativecommons.org/publicdomain/zero/1.0/

The normal and HD application bundles include these textures under
`Resources/assets/particles/texture/particles`, with this credit file and the Kenney license.
Development executables find `assets/particles` relative to the executable.
