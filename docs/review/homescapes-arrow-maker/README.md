# Homescapes donut exit and maker

The captures use the shared board renderer in Relic Rush and Christmas
Market. The 390 × 844 captures include phone safe-area insets.

## Donut exit arrow

The exit is directly below the blue portal, above the donut. The source
arrow is reproduced three times with the original stagger and fade.

| Game and logical size | Before | After |
| --- | --- | --- |
| Relic Rush 480 × 900 | ![Before](../homescapes-jelly-portals/relic-rush-element-states.jpg) | ![After](relic-rush-element-states.jpg) |
| Relic Rush 390 × 844 | ![Before](../homescapes-jelly-portals/relic-rush-phone-element-states.jpg) | ![After](relic-rush-phone-element-states.jpg) |
| Christmas Market 480 × 900 | ![Before](../homescapes-jelly-portals/christmas-market-element-states.jpg) | ![After](christmas-market-element-states.jpg) |
| Christmas Market 390 × 844 | ![Before](../homescapes-jelly-portals/christmas-market-phone-element-states.jpg) | ![After](christmas-market-phone-element-states.jpg) |

## Maker shell

The base, rear glass and front glass are registered on the same 460 × 420
source frame. The four examples show the runtime dough previews. Exact
resting poses and output indicator placement remain open.

| Game and logical size | Before | After |
| --- | --- | --- |
| Relic Rush 480 × 900 | ![Before](../homescapes-jelly-portals/relic-rush-homescapes-art-generators.jpg) | ![After](relic-rush-homescapes-art-generators.jpg) |
| Relic Rush 390 × 844 | ![Before](../homescapes-jelly-portals/relic-rush-phone-homescapes-art-generators.jpg) | ![After](relic-rush-phone-homescapes-art-generators.jpg) |
| Christmas Market 480 × 900 | ![Before](../homescapes-jelly-portals/christmas-market-homescapes-art-generators.jpg) | ![After](christmas-market-homescapes-art-generators.jpg) |
| Christmas Market 390 × 844 | ![Before](../homescapes-jelly-portals/christmas-market-phone-homescapes-art-generators.jpg) | ![After](christmas-market-phone-homescapes-art-generators.jpg) |

## Verification

- Warning-as-error build targets were current (0.07 s wall time).
- Shared checks passed 22 groups in 4.86 s within the default 5 s budget
  (5.04 s including Make). The board test checks that the exit draws three
  copies of the recovered sprite.
- Lua lint passed with 0 warnings or errors (1.41 s wall time).
- Four named captures passed in each game, with one test process per game
  (5.52 s Relic Rush, 5.14 s Christmas Market).
- The original arrow and all 13 named maker components matched the
  extraction checks. All three generated atlas manifests passed provenance
  verification. The arrow passed strict object registration in both game
  atlases, with zero pixels outside the canonical hex.

[Source rectangles, hashes and reproduction commands](../../HOMESCAPES_ART.md)
