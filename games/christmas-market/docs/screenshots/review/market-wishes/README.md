# Christmas Market goods, prices and story

| Screen | Before | After |
| --- | --- | --- |
| Cocoa Corner, 480×900 | ![Earlier pieces](board-before-480.jpg) | ![Six new market goods](board-480.jpg) |
| Cocoa Corner, 390×844 | ![Earlier pieces on the narrow phone](board-before-390.jpg) | ![New goods and blue panes on the narrow phone](board-390.jpg) |
| Build shop, 480×900 | ![Previous decoration prices](shop-before-480.jpg) | ![Revised decoration prices](shop-480.jpg) |
| Build shop, 390×844 | ![Previous shop on the narrow phone](shop-before-390.jpg) | ![Revised pricing on the narrow phone](shop-390.jpg) |
| First-clear reward | ![Prior funded price](reward-before.jpg) | ![Revised funding and bell icon](reward.jpg) |

| Opening | The neighbors' lamps | Noelle's decision |
| --- | --- | --- |
| ![Agnes asks for the first light](opening-480.jpg) | ![Agnes and the Fenwick choir](borrowed-lamps.jpg) | ![Noelle tells Wren she's staying](staying.jpg) |

[Opening on the narrow phone](opening-390.jpg), [the updated Market Guide](guide.jpg),
[art and control states](art-states.jpg), and [the end screen](finale.jpg).

Capture with the software renderer in one test run.

```sh
make christmas-market build/test/christmas-market
build/test/christmas-market "shot main-character-board" "shot phone-board" "shot shop" "shot phone-shop" \
  "shot reward" "shot guide" "shot art-states" "shot story-agnes" "shot phone-story-agnes" \
  "shot story-borrowed-lamps" "shot story-staying" "shot finale"
```
