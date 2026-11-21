# Bellmere's first four board backdrops

The first wish shows the village square. The next three scenes appear on the
first eligible wish after the matching building is confirmed. Later wishes
retain the workshop scene until another backdrop is added.

The first visit to the arch, stable or workshop painting gives the scene a
brief full-screen moment before the cells and HUD arrive. Tapping skips it.
The game remembers that the painting was shown. [Welcome Arch entrance reel](arch-reveal.gif)

| Wish | 480 × 900 | 390 × 844 with phone safe area |
| --- | --- | --- |
| 1 · Opening square | ![Opening square](opening-480x900.jpg) | ![Opening square on a compact phone](opening-390x844.jpg) |
| 2 · Welcome Arch | ![Welcome Arch](arch-480x900.jpg) | ![Welcome Arch on a compact phone](arch-390x844.jpg) |
| 7 · Reindeer Stable | ![Reindeer Stable](stable-480x900.jpg) | ![Reindeer Stable on a compact phone](stable-390x844.jpg) |
| 12 · Lumber Workshop | ![Lumber Workshop](workshop-480x900.jpg) | ![Lumber Workshop on a compact phone](workshop-390x844.jpg) |

```sh
make christmas-market build/test/christmas-market
build/test/christmas-market 'rules christmas' 'smoke walkthrough-pointer' \
  'shot lantern-opening' 'shot purchase-stable-board' 'shot construction-backdrop' \
  'reel construction-backdrop-reveal'
```
