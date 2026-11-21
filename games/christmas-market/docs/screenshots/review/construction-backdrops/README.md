# Bellmere's board backdrops

The first wish shows the village square. Every purchase introduces its own
painting on the first eligible wish after the building is confirmed.

The first visit to each construction painting gives the scene a
brief full-screen moment before the cells and HUD arrive. Tapping skips it.
The game remembers that the painting was shown. [Welcome Arch entrance reel](arch-reveal.gif)

| Wish | 480 × 900 | 390 × 844 with phone safe area |
| --- | --- | --- |
| 1 · Opening square | ![Opening square](opening-480x900.jpg) | ![Opening square on a compact phone](opening-390x844.jpg) |
| 2 · Welcome Arch | ![Welcome Arch](arch-480x900.jpg) | ![Welcome Arch on a compact phone](arch-390x844.jpg) |
| 7 · Reindeer Stable | ![Reindeer Stable](stable-480x900.jpg) | ![Reindeer Stable on a compact phone](stable-390x844.jpg) |
| 12 · Lumber Workshop | ![Lumber Workshop](workshop-480x900.jpg) | ![Lumber Workshop on a compact phone](workshop-390x844.jpg) |

| First eligible wish | 390 × 844 phone capture | 480 × 900 crop check |
| --- | --- | --- |
| 17 · Firework Stall | [View](wish-17.jpg) | |
| 22 · Gingerbread Bakery | [View](wish-22.jpg) | |
| 27 · Snowy Chapel | [View](wish-27.jpg) | [View](wide-27.jpg) |
| 32 · Hot Cocoa Kiosk | [View](wish-32.jpg) | |
| 37 · Ice House | [View](wish-37.jpg) | |
| 42 · Lakeside Smokehouse | [View](wish-42.jpg) | |
| 47 · Station Kiosk | [View](wish-47.jpg) | [View](wide-47.jpg) |
| 52 · Toymaker’s Workshop | [View](wish-52.jpg) | |
| 57 · Candlelight Shop | [View](wish-57.jpg) | |
| 62 · Gift Wrapping Pavilion | [View](wish-62.jpg) | |
| 67 · North Pole Post Office | [View](wish-67.jpg) | |
| 72 · Glassblower’s Stall | [View](wish-72.jpg) | |
| 77 · Reindeer Carousel | [View](wish-77.jpg) | [View](wide-77.jpg) |
| 82 · Winter Skating Rink | [View](wish-82.jpg) | |
| 87 · Woodcarvers’ Hall | [View](wish-87.jpg) | |
| 92 · Christmas Tree | [View](wish-92.jpg) | |
| 97 · Santa’s Sleigh | [View](wish-97.jpg) | [View](wide-97.jpg) |

```sh
make christmas-market build/test/christmas-market
build/test/christmas-market 'rules christmas' 'smoke walkthrough-pointer' \
  'shot lantern-opening' 'shot purchase-stable-board' 'shot construction-backdrop' \
  'reel construction-backdrop-reveal'
```
