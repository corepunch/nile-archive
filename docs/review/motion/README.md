# Cell registration and portrait motion review

The 112px artwork inside a 128px canvas was being scaled as if it filled the
canvas. Board hex pieces now reach the cell diameter and other silhouettes fit
the inscribed square; state panels span the whole cell. Sprite pixels and authored
interaction states are unchanged. Relic Rush still uses its original flame.

| Size | Previous registration | Corrected registration |
| --- | --- | --- |
| 480×900 | ![Before](before-board-480x900.png) | ![After](after-board-480x900.png) |
| 390×844, safe areas | ![Before](before-board-390x844.png) | ![After](after-board-390x844.png) |

The engine owns finite, monotonic 0.2-second portrait transitions. Enter/exit
slide and fade; active/inactive changes blend size, location and colour from the
currently visible pose. Returning speakers do not re-enter. There is no idle
motion, scale pulse, rotation, or overshoot. Layout, transition state, and drawing
are separate helpers, using the engine's value-type cubic tween.

![Real game entrance, idle, listener, returning speaker and exit](portraits.gif)

| Size | Active speaker | Speaker and inactive listener |
| --- | --- | --- |
| 480×900 | ![Speaker](after-speaker-480x900.png) | ![Listener](after-listener-480x900.png) |
| 390×844, safe areas | ![Speaker](after-speaker-390x844.png) | ![Listener](after-listener-390x844.png) |

Captured from the real game via `tests/fixtures/dialogue/main.lua`, with a fixed
50ms presentation clock. Run `build/test/relic-rush portrait-` once for all sizes
and the reel. The GIF uses its 42 frames at half resolution and 100ms per frame.
Every frame was inspected, including entrance, both speaker changes and exit.
The still captures show completed lines. Engine tests verify unchanged settled
portrait pixels and continuous retargeting through active/listener transitions.

See [test timing and CI changes](../../TESTING.md#fail-early-and-measure-slow-steps).
