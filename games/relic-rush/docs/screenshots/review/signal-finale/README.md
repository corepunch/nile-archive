# Sand, shutter and signal finale

The former board is on the left of each comparison. The revised board is on
the right. The shutter-crank captures document the original excavation.
Board 10 now collects the [bronze shutter gear](../story-collection/README.md).

| Screen | 480×900 | 390×844 |
| --- | --- | --- |
| Sweeping sand, halfway through board 8 | [Before and after](sand-480.jpg) | [Before and after](sand-390.jpg) |
| Board 10, partially uncovered shutter crank | [Before and after](crank-480.jpg) | [Before and after](crank-390.jpg) |
| Board 10, fully recovered shutter crank | [480×900](crank-found-480.jpg) | [390×844](crank-found-390.jpg) |
| Board 30, the signal plate and its goal | [Before and after](plate-480.jpg) | [Before and after](plate-390.jpg) |
| Ines answers from the landing | [Lantern lit](signal-landing.jpg) | [Lantern lit](phone-signal-landing.jpg) |

[Board 3’s three flashes](signal-cliff.webp) set up [Ines’s reply](signal-finale.webp).
The finale shows [the seated plate](signal-in-exit.jpg), then the lantern, followed
by [Ines’s confirmation](phone-story-finale.jpg). The [broken cable](sand-cable.jpg)
and the [archived shutter crank](crank-award.jpg) have separate item cards.

Reproduce the review in one run from the repository root.

```sh
build/test/relic-rush "shot sand-" "shot delivery-finale" \
    "shot phone-story-level-30" "shot signal-" "shot phone-signal-landing" \
    "shot phone-story-finale" "reel signal-"
```

The short WebP previews use every seventh rendered frame at 117 ms per sample.
See the [asset catalogue](../../../asset-catalogue.md#the-signal-finale) for
the source artwork, prompts, and registration.
