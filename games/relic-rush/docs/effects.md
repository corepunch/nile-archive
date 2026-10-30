# Effects and motion

![Actual SDL effects reel](screenshots/effects-reel.gif)

This is a capture of the actual renderer using deterministic ray, bomb and prism test boards. The effects run in the game; this is not a generated animation or a claim of measured mobile performance.

## Implemented feedback

| Event | Presentation |
| --- | --- |
| Normal match | Brief piece expansion, shrink and fade, local light bloom, colored shards and four-point sparkles |
| Directional ray | Travelling head, colored light envelope, bright narrow core and a fading trail along its attack axis |
| Bomb | Expanding double shockwave, warm center flare and radial sparkles |
| Prism | Staggered branching light links from the prism to affected targets |
| Special combination | Broader bomb shockwaves or rays along all three board axes |
| Special creation | Delayed birth halo, an expanding ring and orbiting sparkles |
| Landing | Eased movement and a short squash/stretch at the end of the fall |
| Resource collection | Staggered curved flights, light trails and a small HUD landing pulse; locked pieces do not send unearned resource icons |
| Score | Smooth count-up, progress-bar interpolation, a small number pulse and one floating score per cascade wave |
| Cascade | Escalating chimes and animated BRILLIANT / MAGNIFICENT / SUNSTORM feedback |

Reduced-motion mode suppresses effect spawns, trails, shakes and squash/stretch while retaining normal rule resolution and immediate score readability.

## Reference study

- [King: creating and combining special candies](https://candycrush.zendesk.com/hc/en-us/articles/211939685-Creating-and-combining-Special-Candies): distinct line, area and color attacks rather than one generic explosion.
- [King's Crush & Tell: Super Color Bomb](https://community.king.com/en/candy-crush-saga/discussion/512579/crush-tell-go-behind-the-scenes-of-the-candy-kingdom): the official developer-series reference for satisfying booster feedback and its place in gameplay.
- [GDC: Juice It or Lose It, Martin Jonasson and Petri Purho](https://www.gdcvault.com/play/1016789/Juice-It-or-Lose): a game-feel reference for layered sensory feedback.

Our interpretation is anticipation → attack → tile response → collection → HUD response. All art, effects and timing are implemented for Relic Rush; no Candy Crush effects or proprietary assets are copied.

## Implementation and verification

`vfx.lua` isolates presentation from `rules.lua`. Effects use a separate random stream, a 256-event pool and the existing 650-particle pool. A small procedural additive light texture is created once; rings, beams and sparkles use SDL geometry. Presentation never consumes gameplay random numbers or changes rewards/objectives.

Static specials, blockers and tool controls use authored atlas artwork; their
states and the intentional procedural animation primitives are listed in the
[asset catalogue](asset-catalogue.md). Ray direction, bomb/prism identity and ice
strength are no longer supplied by procedural glyphs.

Effects only read the board; the ported rule tests (`make test`) and the `--smoke` run cover gameplay with effects active.

Capture single moments with `--fx ray|bomb|prism --frames N --shot file.png` (N frames after the special fires); `tools/screenshots.sh` renders the reel frames and assembles `screenshots/effects-reel.gif`. These modes do not write player progress.
