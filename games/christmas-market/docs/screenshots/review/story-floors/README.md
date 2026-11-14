# Story floors

The first clear reveals the painting in the board's own silhouette, then leads
into the existing scene. The partial captures show four snow cells removed on
level 25 and half the lanternlight spread on levels 24 and 28.

## 480×900

| Board | Before | Partial | First clear |
| --- | --- | --- | --- |
| Frozen Fountain | ![Plain lanternlight](24-before-480x900.jpg) | ![The wish ribbons emerging](ribbon-half.jpg) | ![Noelle's wish ribbon in the fountain](24-win-480x900.jpg) |
| Snow on the Line | ![The original snow patch](25-before-480x900.jpg) | ![Paper showing in the cleared cells](telegram-half.jpg) | ![The uncovered telegram and knitted scarf](25-win-480x900.jpg) |
| The Last Train | ![Plain lanternlight](28-before-480x900.jpg) | ![Lanterns showing through the left side of the board](train-half.jpg) | ![The train guided by lanterns](28-win-480x900.jpg) |

## 390×844 with safe areas

| Board | Before | First clear |
| --- | --- | --- |
| Frozen Fountain | ![Plain lanternlight](24-before-390x844.jpg) | ![Noelle's wish ribbon in the fountain](24-win-390x844.jpg) |
| Snow on the Line | ![The original snow patch](25-before-390x844.jpg) | ![The uncovered telegram and knitted scarf](25-win-390x844.jpg) |
| The Last Train | ![Plain lanternlight](28-before-390x844.jpg) | ![The train guided by lanterns](28-win-390x844.jpg) |

| Win fade and hold | Pip's first line |
| --- | --- |
| ![Treats fade and the train stays in view](train-win.webp) | ![Pip hears the train](train-scene.jpg) |

Render the reveal states and reel from the repository root.

```sh
build/test/all --suite=christmas-market "shot story-floor-" "reel story-floor-train-win"
```
