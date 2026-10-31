# Dialog motion on the tween module

The dialogs' entrance, exit and the result screen's parts moved from a hand-kept
clock (`R.modal_clock`, `R.modal_exit`) onto the engine's motion module
([docs/MOTION.md](../../../../../docs/MOTION.md)). The look is unchanged: the
settled stills (`guide`, `pause`, `victory`) are pixel-identical to
the previous build, and the entrance below differs only by the one frame a
tween takes to start on the next engine tick.

| Before | After |
| --- | --- |
| ![before](before.gif) | ![after](after.gif) |

`--victory --reel`, 480×900, 36 pictures 3 frames apart (the `result` reel).
