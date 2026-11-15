# Painted resource outlines

The everyday pieces use the warm dark contour of the Workshop cut blocks.
This includes the orange ration jar. The original dark cut blocks remain
the art reference. The wood match on First Light now uses the same blue-tied
timber as the rest of the expedition and earns Supplies as it advances the
camp goal. The green trail arrow replaces the stone marker on both marker
boards and their recovery cards.

| View | Before | After |
| --- | --- | --- |
| Shore Marker, 480 × 900 | ![Resource board and stone marker](shore-before.jpg) | ![Outlined resources and trail arrow](shore-after.jpg) |
| Shore Marker, 390 × 844 | ![Previous phone palette](shore-phone-before.jpg) | ![Outlined phone palette](shore-phone-after.jpg) |
| Supply Crate, 390 × 844 | ![Cut blocks alongside the previous palette](workshop-phone-before.jpg) | ![Cut blocks alongside the outlined palette](workshop-phone-after.jpg) |

| First Light | Camp timber reward | Quay marker reward | Guide |
| --- | --- | --- | --- |
| ![One blue timber kind](opening.jpg) | ![Blue-tied timber on the card](timber-award.jpg) | ![Green brass trail arrow](marker-award.jpg) | ![Outlined resource icons in the guide](guide.jpg) |

Capture the board and card views through the existing Relic Rush test runner.

```sh
build/test/relic-rush "shot dressing-shore" "shot phone-floating-hud" "shot hex-first" "shot timber-item-card" "shot marker-item-card" "shot phone-guide"
```

The [source atlas](../../../../art/resource-pieces/outlined-atlas.png) and
[prompts](../../../../art/resource-pieces/outlined-atlas.prompt.txt) record the
painted contours. The asset importers only crop, resize and center the sprites.
