# Restore the original gem-to-cell proportions

The earlier board-size fix restored the cell radius but retained an independent
piece enlargement introduced in `27f63ed`. Normal piece canvases had grown from
43.7 to about 52.46 logical units; hex piece canvases grew to about 60.57. This
left almost no visible gutter, or filled the hex entirely, after the entrance
finished. An animation scale of 1 did not detect that rendering regression.

Restore the original `46 * .95` piece canvas, including authored transparent
padding. Cell geometry, state panels, artwork, alpha, animation timing and
interaction targets are unchanged. The regression now records actual draw
rectangles for all six kinds after natural entrance completion, in normal and
reduced-motion modes, and checks that the piece canvases leave space inside
their cells. Existing checks also cover skipped entrances and settled input.
The new rectangle assertion failed against the enlarged renderer before the fix.

Baseline: `1a95d11`. Both before/after pairs show level 5 at frame 180, after the
complete entrance; the alternate phone has safe areas. All four images were
visually reviewed. JPEGs are reduced to logical viewport size from game captures.

```sh
make CFLAGS="-O2 -g -Werror" relic-rush build/test/relic-rush
build/test/relic-rush "rules relic_board" "frame entrance-settled-relic-rush"
make lint
```

The existing frame jobs write
`build/shots/frames/entrance-settled-relic-rush-<size>.png`. No new capture jobs
or artwork pipeline runs are required for this geometry-only correction.

| Size | Before | After |
| --- | --- | --- |
| 480×900 | ![Before](before-480x900.jpg) | ![After](after-480x900.jpg) |
| 390×844 with safe areas | ![Before](before-390x844.jpg) | ![After](after-390x844.jpg) |
