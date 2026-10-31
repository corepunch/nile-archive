# Automatic roads disabled

Relic Rush no longer draws the engine’s generated building connectors.

Before: main `3628324`. After: this branch. All captures use the native game renderer.

| Logical size | Before | After |
| --- | --- | --- |
| 480x900 | ![Before](before-480x900.jpg) | ![After](after-480x900.jpg) |
| 390x844 | ![Before](before-390x844.jpg) | ![After](after-390x844.jpg) |

Reproduce each logical size with:

```sh
./build/relic-rush --headless --mute --fresh --size 480x900 --showcase --shot /tmp/island.png
```

For the 390×844 Relic Rush capture, add `--safe-area 0,47,0,34`. Nile also covers 1368×1026 and 1600×900. PNG captures are converted to RGB JPEG at quality 90, fitted within 600×1100 (phone) or 1200×1000 (iPad).
