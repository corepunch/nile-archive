# Lantern panes

Cocoa Corner shows blue panes both with and without one-hit tinsel. The board
surface has hairline seams. The town wallet and Pause control follow the same
layout on the board. The guide shows the blue pane, tinsel and the three tools.

| Screen | Before | After |
| --- | --- | --- |
| Cocoa Corner, 480×900 | ![Previous board](before-board-480x900.jpg) | ![Blue panes and shared wallet](board-480x900.jpg) |
| Cocoa Corner, 390×844 | ![Previous board on the narrow phone](before-board-390x844.jpg) | ![Blue panes on the narrow phone](board-390x844.jpg) |
| Guide, 480×900 | ![Previous guide](before-guide-480x900.jpg) | ![Pane and tinsel guide](guide-480x900.jpg) |
| Guide, 390×844 | ![Previous guide on the narrow phone](before-guide-390x844.jpg) | ![Pane and tinsel guide on the narrow phone](guide-390x844.jpg) |

| Welcome Lights | The Last Train, partway through | Finale |
| --- | --- | --- |
| ![Opening with no tinsel](opening.jpg) | ![Lit amber and pending blue panes](train-partway.jpg) | ![Tree-shaped patch and tinsel](finale.jpg) |

| A Ribbon for Home | Word from the Station | The Last Train |
| --- | --- | --- |
| ![The childhood ribbon](ribbon.jpg) | ![Pip's telegram](telegram.jpg) | ![The train arriving](train.jpg) |

[Pip spots his mum after the painting](train-scene.jpg).
[The same wallet in the market](market.jpg).
[Runtime art and authored tool states](art-states.jpg).

Capture with the software renderer in one test run.

```sh
make christmas-market build/test/christmas-market
build/test/christmas-market "shot main-character-board" "shot phone-board" "shot guide" "shot phone-guide" \
  "shot lantern-opening" "shot tree-finale" "shot story-floor-train-half" "shot story-floor-train-scene" \
  "shot story-floor-24-480x900" "shot story-floor-25-480x900" "shot story-floor-28-390x844" \
  "shot art-states" "shot market"
```
