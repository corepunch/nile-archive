# Building catalogue review

Reviewed 30 October 2026 using the game itself on macOS. Main captures are
480 x 900; phone captures are 390 x 844 with 47 top / 34 bottom safe-area insets.
The source atlas and import history are documented in the
[building catalogue](../../building-catalogue.md).

## Existing screens, before and after

| Screen | Before | After |
| --- | --- | --- |
| Island | ![Before island](before-island.jpg) | ![After island](after-island.jpg) |
| Footprints | ![Before footprints](before-footprints.jpg) | ![After footprints](after-footprints.jpg) |
| Story placement | ![Before placement](before-placement.jpg) | ![After placement](after-placement.jpg) |
| Blocked placement | ![Before blocked](before-blocked.jpg) | ![After blocked](blocked.jpg) |
| Story details | ![Before card](before-card.jpg) | ![After card](card.jpg) |
| Tall phone island | ![Before phone](before-island-390x844.jpg) | ![After phone](after-island-390x844.jpg) |

## New buy-and-place catalogue

| Design size | Tall phone |
| --- | --- |
| ![Catalogue 480 x 900](catalogue-480x900.jpg) | ![Catalogue 390 x 844](catalogue-390x844.jpg) |

| Purchase preview | Purchased object details |
| --- | --- |
| ![Purchase placement](placement.jpg) | ![Purchased shrub details](purchased-card.jpg) |

## Every sprite in catalogue and city

All 24 pages below were inspected. Each page covers four stable catalogue IDs.
City overlays include the unchanged half-tile clearance and mark the ground
pivot in magenta. Small props intentionally occupy less than a tile visually;
their full tile reservation still prevents crowding. Trees use their projected
root pivots; a platform decoration's ground origin can be hidden by its volume.
The review-only city fixtures use the next story milestone in the bottom panel;
that text is independent of the four catalogue types being inspected.

![Catalogue overview 1](catalogue-all-overview-1.jpg)

![Footprint overview 1](footprints-overview-1.jpg)

![Catalogue overview 2](catalogue-all-overview-2.jpg)

![Footprint overview 2](footprints-overview-2.jpg)

![Catalogue overview 3](catalogue-all-overview-3.jpg)

![Footprint overview 3](footprints-overview-3.jpg)

| IDs | Catalogue rows | City footprints |
| --- | --- | --- |
| 0–3 | [Catalogue 1](catalogue-all-01.jpg) | [Footprints 1](footprints-01.jpg) |
| 4–7 | [Catalogue 2](catalogue-all-02.jpg) | [Footprints 2](footprints-02.jpg) |
| 8–11 | [Catalogue 3](catalogue-all-03.jpg) | [Footprints 3](footprints-03.jpg) |
| 12–15 | [Catalogue 4](catalogue-all-04.jpg) | [Footprints 4](footprints-04.jpg) |
| 16–19 | [Catalogue 5](catalogue-all-05.jpg) | [Footprints 5](footprints-05.jpg) |
| 20–23 | [Catalogue 6](catalogue-all-06.jpg) | [Footprints 6](footprints-06.jpg) |
| 24–27 | [Catalogue 7](catalogue-all-07.jpg) | [Footprints 7](footprints-07.jpg) |
| 28–31 | [Catalogue 8](catalogue-all-08.jpg) | [Footprints 8](footprints-08.jpg) |
| 32–35 | [Catalogue 9](catalogue-all-09.jpg) | [Footprints 9](footprints-09.jpg) |
| 36–39 | [Catalogue 10](catalogue-all-10.jpg) | [Footprints 10](footprints-10.jpg) |
| 40–43 | [Catalogue 11](catalogue-all-11.jpg) | [Footprints 11](footprints-11.jpg) |
| 44–47 | [Catalogue 12](catalogue-all-12.jpg) | [Footprints 12](footprints-12.jpg) |
| 48–51 | [Catalogue 13](catalogue-all-13.jpg) | [Footprints 13](footprints-13.jpg) |
| 52–55 | [Catalogue 14](catalogue-all-14.jpg) | [Footprints 14](footprints-14.jpg) |
| 56–59 | [Catalogue 15](catalogue-all-15.jpg) | [Footprints 15](footprints-15.jpg) |
| 60–63 | [Catalogue 16](catalogue-all-16.jpg) | [Footprints 16](footprints-16.jpg) |
| 64–67 | [Catalogue 17](catalogue-all-17.jpg) | [Footprints 17](footprints-17.jpg) |
| 68–71 | [Catalogue 18](catalogue-all-18.jpg) | [Footprints 18](footprints-18.jpg) |
| 72–75 | [Catalogue 19](catalogue-all-19.jpg) | [Footprints 19](footprints-19.jpg) |
| 76–79 | [Catalogue 20](catalogue-all-20.jpg) | [Footprints 20](footprints-20.jpg) |
| 80–83 | [Catalogue 21](catalogue-all-21.jpg) | [Footprints 21](footprints-21.jpg) |
| 84–87 | [Catalogue 22](catalogue-all-22.jpg) | [Footprints 22](footprints-22.jpg) |
| 88–91 | [Catalogue 23](catalogue-all-23.jpg) | [Footprints 23](footprints-23.jpg) |
| 92–95 | [Catalogue 24](catalogue-all-24.jpg) | [Footprints 24](footprints-24.jpg) |

## Validation

- `make CFLAGS="-O2 -g -Werror"`: passed.
- `make test`: passed; includes 5,514 Relic Rush checks, 53 form checks, asset
  coverage, engine tests and the other game rule checks.
- Native `--smoke` at 480 x 900 and 390 x 844 with safe areas: passed. Actual
  press/release input covers guide, puzzle win, claim, first restoration, pan,
  hold/move/cancel/confirm, category refresh, purchase cancellation, confirmed
  decoration purchase, purchased-instance details/movement, and level two.
- Catalogue tests cover Star requirements, repeated ownership, reserved story
  gold, cancelled/invalid placement, save round trips with more placed items than
  completed levels, and preserving ownership if no relocation plot exists.
- `git diff --check`: passed.

## Capture commands

```sh
./build/relic-rush --headless --mute --fresh --size 480x900 --catalogue --shot shop.png
./build/relic-rush --headless --mute --fresh --size 390x844 --safe-area 0,47,0,34 --catalogue --shot phone.png
./build/relic-rush --headless --mute --fresh --catalogue all --catalogue-page 1 --shot catalogue-01.png
./build/relic-rush --headless --mute --fresh --building-review 1 --footprints --shot footprints-01.png
./build/relic-rush --headless --mute --fresh --catalogue-item 10 --shot placement.png
./build/relic-rush --headless --mute --fresh --catalogue-card 37 --shot purchased-card.png
```

Repeat catalogue/review pages 1–24. The original comparison launcher used HEAD's
`lua/` and `data/` exported to a temporary folder, with the same native renderer.
Tracked JPGs are proportionally downscaled captures; no game artwork was edited
in review images. Native PNG intermediates are reproducible and are not retained.
