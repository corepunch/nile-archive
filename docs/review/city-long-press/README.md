# Deliberate building pickup

> The commands on this page used a capture tool that has since been replaced. A press and hold is now `hold()` in `tests/games/<game>.lua`; see [docs/TESTING.md](../../TESTING.md). The captures here are the historical record.

Before: main at `a59e8149e84cbf2254f6195aaa890f21eee7e0ec`. After: this PR.
Tracked by [issue #21](https://github.com/corepunch/nile-archive/issues/21).

`pan` starts on a building, moves 60 logical units left after six frames, then
continues holding. Before, that lifted the building. After, it pans the map and
never re-arms a pickup. `hold` remains still: before it did nothing, after half a
second it lifts the building and shows its placement controls. Release snaps a
preview; only Confirm saves a move, while Cancel preserves the original layout.

## Capture the actual games

`engine/launcher.c`, with `--gesture`, wraps the normal game's frame callback and queues
native pointer events, without changing game drawing or synthesizing placement
state. Build with `make CFLAGS="-O2 -g -Werror"`, then run:

```sh
./build/relic-rush --headless --fresh --mute \
  --city 3 --look 760,1980 --size 480x900 --gesture pan --press 240,440 \
  --frames 100 --shot out.png
./build/nile-archive --headless --fresh --mute \
  --screen island --size 1200x900 --gesture hold --press 435,345 \
  --frames 100 --shot out.png
```

Change `--gesture` between `pan` and `hold`. For the phone add
`--size 390x844 --safe-area 0,47,0,34`; the press remains `240,440`.
Nile Archive also has 1368×1026 captures with `--press 435,345` and 1600×900
captures with `--press 600,375`. Linux uses `xvfb-run -a` and software GL.
The helper also supports `--gesture drag`, which moves after a completed hold.

To reproduce before captures, build the helper against the named baseline
engine/game scripts and use the same arguments. For this review a small
`git archive` of engine/source files used symlinks to the unchanged game assets
and existing third-party sources; no dependencies or duplicate asset trees were
downloaded. Review JPEGs are capped at 480×900 (phone) or 1200×1026 (tablet).
Canonical long-press screenshots retain capture resolution; `make shots`
regenerates them using the same helper.

## Checks

Engine unit tests cover the threshold, pan arbitration, no re-arming after a
pan, short-tap income, UI-originated presses, movement disabled/quick-build
selection, pinch/wheel/capture/focus cancellation, preview release, cancellation
and free exactly-once confirmation. Platform tests verify that multi-touch is
latched through release and cannot click a UI button. A control appearing under
an existing world press cannot inherit its release; a new press on the visible
control still activates it. Generated Lua bindings
preserve that state. Both games' normal `--smoke` runs now perform real native
press/move/release sequences, cancel one move and confirm another through their
actual controls. Nile Archive's confirmation strip is an engine form.

No building geometry, art registration, runtime texture or authored icon/state
is added or changed. Volcano has no city relocation mode.
