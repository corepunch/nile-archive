# Island HUD

The island screen covered much of its painting: two rows of resource capsules
plus an EXPAND pill at the top, and EXPEDITIONS / BUILD SHOP buttons over a cream
sheet at the bottom. The sheet held a status line ("6 WONDERS - NEW LAND AWAITS"),
a gesture hint and the Play button. Fog markers sat on dark name plates.

It now follows the home screens of Royal Match, Homescapes and June's Journey.
See [references](../../references.md#island-home-screen-hud).

- **One row of currency pills.** Gold, Wood, Stone, Stars and Compasses sit in
  slim pills beside the pause medallion, which now matches the one on the board.
  Tapping a pill still explains it.
- **No sheet.** The bottom holds one big button labelled with what it does:
  - **LEVEL N** plays the next expedition;
  - **BUILD** opens the restored wonder, whose name is shown above the button;
  - **PLAY FOR GOLD** appears once the campaign is complete.

  Round **Expeditions** (compass) and **Shop** (market) buttons with captions flank it.
- **No EXPAND button.** A region that can open now shows "+" and a breathing
  glow on its fog marker; tapping a marker opens its card, as before. Marker
  names are outlined text, without plates.
- **Placement** keeps only the building's name and CANCEL / PLACE & BUILD; the
  toast already explains the gestures.
- **Toast** sits just above the bottom controls.

Before: commit `6410ad8` (the slim match-3 board HUD, same island). Every image
is captured from the actual game.

| Screen / size | Before | After |
| --- | --- | --- |
| island / 480×900 | ![Before](before-island-480x900.jpg) | ![After](after-island-480x900.jpg) |
| island / 390×844 | ![Before](before-island-390x844.jpg) | ![After](after-island-390x844.jpg) |
| wonder to build / 480×900 | ![Before](before-wonder-480x900.jpg) | ![After](after-wonder-480x900.jpg) |
| wonder to build / 390×844 | ![Before](before-wonder-390x844.jpg) | ![After](after-wonder-390x844.jpg) |
| placing / 480×900 | ![Before](before-placing-480x900.jpg) | ![After](after-placing-480x900.jpg) |
| placing / 390×844 | ![Before](before-placing-390x844.jpg) | ![After](after-placing-390x844.jpg) |
| blocked spot / 480×900 | ![Before](before-blocked-480x900.jpg) | ![After](after-blocked-480x900.jpg) |
| blocked spot / 390×844 | ![Before](before-blocked-390x844.jpg) | ![After](after-blocked-390x844.jpg) |
| land ready / 480×900 | ![Before](before-fog-480x900.jpg) | ![After](after-fog-480x900.jpg) |
| land ready / 390×844 | ![Before](before-fog-390x844.jpg) | ![After](after-fog-390x844.jpg) |
| overview, land ready / 480×900 | ![Before](before-overview-480x900.jpg) | ![After](after-overview-480x900.jpg) |
| overview, land ready / 390×844 | ![Before](before-overview-390x844.jpg) | ![After](after-overview-390x844.jpg) |
| campaign complete / 480×900 | ![Before](before-showcase-480x900.jpg) | ![After](after-showcase-480x900.jpg) |
| campaign complete / 390×844 | ![Before](before-showcase-390x844.jpg) | ![After](after-showcase-390x844.jpg) |
| region card / 480×900 | ![Before](before-unlock-480x900.jpg) | ![After](after-unlock-480x900.jpg) |
| region card / 390×844 | ![Before](before-unlock-390x844.jpg) | ![After](after-unlock-390x844.jpg) |
| shop / 480×900 | ![Before](before-shop-480x900.jpg) | ![After](after-shop-480x900.jpg) |
| shop / 390×844 | ![Before](before-shop-390x844.jpg) | ![After](after-shop-390x844.jpg) |
| expeditions / 480×900 | ![Before](before-expeditions-480x900.jpg) | ![After](after-expeditions-480x900.jpg) |
| expeditions / 390×844 | ![Before](before-expeditions-390x844.jpg) | ![After](after-expeditions-390x844.jpg) |

390×844 captures use 47px top / 34px bottom safe-area insets.

Reproduce from the repository root (on Linux, under Xvfb):

```sh
make CFLAGS="-O2 -g -Werror"
python3 tests/fixtures/match3-hud/capture.py --suite island --before-ref 6410ad8
make test
./build/relic-rush --headless --mute --fresh --smoke
./build/relic-rush --headless --mute --fresh --smoke --size 390x844 --safe-area 0,47,0,34
```

The `--smoke` run presses the new Expeditions button, the Play/Build button and
the placement buttons with real injected clicks. The capture script also runs the
expedition-header input fixture, which opens the shop and expedition browser and
dismisses them from the background.
