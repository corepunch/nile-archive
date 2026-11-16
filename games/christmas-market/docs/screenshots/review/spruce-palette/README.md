# Spruce board palette

ImageGen used the ordinary chips, the six story replacements and a screenshot
of the letter board to make the [palette concept](../../../../art/lantern-panes/concept.png).
The in-game backdrop and spruce, slate-blue and honey-amber tile artwork were
painted from that reference.

| Size | Before | In game |
| --- | --- | --- |
| 480×900 | ![Walnut and cobalt](before-480.jpg) | ![Spruce and slate blue](after-480.jpg) |
| 390×844 | ![Previous palette on the narrow phone](before-390.jpg) | ![New palette on the narrow phone](after-390.jpg) |

| With story pieces | Partway through The Last Train | Market Guide |
| --- | --- | --- |
| ![Letter pieces and chains](letter.jpg) | ![Lit and unlit panes side by side](lit-and-blue.jpg) | ![Slate-blue pane icon in the guide](guide.jpg) |

Capture with the native renderer in one test run.

```sh
make christmas-market build/test/christmas-market
build/test/christmas-market "shot main-character-board" "shot phone-board" \
  "shot find-letter-480" "shot story-floor-train-half" "shot guide"
```
