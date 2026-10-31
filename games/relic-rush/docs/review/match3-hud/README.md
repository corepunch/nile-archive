# Match-3 HUD

The expedition screen was built from cream cards floating over the painting:
a Goal card and a Moves card with Elena's portrait wedged between them, a hint
line above the tools, captions under every tool and a guide book beside them.
It now uses the layout that portrait match-3 games (Royal Match, Toon Blast,
Homescapes, Candy Crush) share. See [references](../../references.md#match-3-level-hud).

- **One top band.** A jade band with a gold trim hangs from the top edge and runs
  under the status bar. It holds:
  - a hexagonal **Moves** medallion, echoing the board cells, that overhangs the band;
  - a recessed plate of **goal icons** with the remaining count beneath each;
  - the authored **pause** medallion.
- **Goals.** A met goal dims and shows the check seal instead of "DONE".
  Collection flights land on their goal icon, which bounces.
- **Last moves.** Over the last five moves the medallion turns red and glows.
- **No portrait.** Elena's investigation cutout is gone from the board. She still
  speaks in dialogue. The source art is kept but no longer exported to `data/`.
- **Bottom tray.** The three tools stand in sockets in a matching tray along the
  bottom edge, evenly spaced and without captions. Choosing one names it and its
  effect in the toast, for example "Dynamite: tap a relic to blast around it."
- **Less clutter.** The standing "CONNECT 4+ MATCHING NEIGHBORS." line and the
  guide book are gone from the board. The Explorer's Guide opens from Pause, and
  Elena still explains each level's twist the first time.
- **Bigger stage.** The board moves up 52 units into the freed space, centred
  between the band and the tray. Tall phones still add their extra height around it.

Before: commit `6a56346`. Every image is captured from the actual game.

| Screen / size | Before | After |
| --- | --- | --- |
| first / 480×900 | ![Before first](before-first-480x900.jpg) | ![After first](after-first-480x900.jpg) |
| first / 390×844 | ![Before first](before-first-390x844.jpg) | ![After first](after-first-390x844.jpg) |
| late / 480×900 | ![Before late](before-late-480x900.jpg) | ![After late](after-late-480x900.jpg) |
| late / 390×844 | ![Before late](before-late-390x844.jpg) | ![After late](after-late-390x844.jpg) |
| temple / 480×900 | ![Before temple](before-temple-480x900.jpg) | ![After temple](after-temple-480x900.jpg) |
| temple / 390×844 | ![Before temple](before-temple-390x844.jpg) | ![After temple](after-temple-390x844.jpg) |
| goals complete / 480×900 | ![Before complete](before-complete-480x900.jpg) | ![After complete](after-complete-480x900.jpg) |
| goals complete / 390×844 | ![Before complete](before-complete-390x844.jpg) | ![After complete](after-complete-390x844.jpg) |
| last moves / 480×900 | ![Before last moves](before-last-moves-480x900.jpg) | ![After last moves](after-last-moves-480x900.jpg) |
| last moves / 390×844 | ![Before last moves](before-last-moves-390x844.jpg) | ![After last moves](after-last-moves-390x844.jpg) |
| tool tapped / 480×900 | ![Before tool](before-tool-480x900.jpg) | ![After tool](after-tool-480x900.jpg) |
| tool tapped / 390×844 | ![Before tool](before-tool-390x844.jpg) | ![After tool](after-tool-390x844.jpg) |
| pause / 480×900 | ![Before pause](before-pause-480x900.jpg) | ![After pause](after-pause-480x900.jpg) |
| pause / 390×844 | ![Before pause](before-pause-390x844.jpg) | ![After pause](after-pause-390x844.jpg) |
| guide / 480×900 | ![Before guide](before-guide-480x900.jpg) | ![After guide](after-guide-480x900.jpg) |
| guide / 390×844 | ![Before guide](before-guide-390x844.jpg) | ![After guide](after-guide-390x844.jpg) |
| island (unchanged) / 480×900 | ![Before island](before-island-480x900.jpg) | ![After island](after-island-480x900.jpg) |
| island (unchanged) / 390×844 | ![Before island](before-island-390x844.jpg) | ![After island](after-island-390x844.jpg) |

390×844 captures use 47px top / 34px bottom safe-area insets. The "tool tapped"
row injects a real press and release on Dynamite.

Reproduce from the repository root (on Linux, under Xvfb):

```sh
make CFLAGS="-O2 -g -Werror"
python3 tests/fixtures/match3-hud/capture.py --before-ref 6a56346
make test
./build/relic-rush --headless --mute --fresh --smoke
./build/relic-rush --headless --mute --fresh --smoke --size 390x844 --safe-area 0,47,0,34
```

The capture script also runs the expedition-header input fixture against the
new layout: pause opens from the band, taps inside popups don't dismiss them,
background taps do, and the unfinished board survives. The game's `--smoke` run
now opens the Explorer's Guide through Pause.
