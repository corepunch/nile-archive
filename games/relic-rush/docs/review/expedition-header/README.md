# Goal, moves and pause

The expedition header replaces score/level/name/progress plus objective capsules
with one Goal panel of remaining objectives, a Moves card and an authored pause
medallion. Elena examines a sun fragment through a magnifying glass in a separate
static portrait, with an independent anchor for later animation. Score is still
required by the rules; its remaining count uses the star seal. No win condition
was removed. Level details moved into Pause and reward totals remain in Results.

An unfinished round has no island shortcut. Win/loss screens retain explicit
exit actions. Closable pause, guide, building, region, shop and expedition-browser
popups dismiss on a captured tap that begins and ends on their background.
Opening releases, taps inside, drags and multi-touch cannot dismiss or leak
through. Shared `ui.modal_dismiss` and `ui.modals` own this input behavior.

Before: commit `a47431a`. Every image below is captured from the actual game.

| Screen / size | Before | After |
| --- | --- | --- |
| first / 480x900 | ![Before first](before-first-480x900.jpg) | ![After first](after-first-480x900.jpg) |
| first / 390x844 | ![Before first](before-first-390x844.jpg) | ![After first](after-first-390x844.jpg) |
| late / 480x900 | ![Before late](before-late-480x900.jpg) | ![After late](after-late-480x900.jpg) |
| late / 390x844 | ![Before late](before-late-390x844.jpg) | ![After late](after-late-390x844.jpg) |
| pause / 480x900 | ![Before pause](before-pause-480x900.jpg) | ![After pause](after-pause-480x900.jpg) |
| pause / 390x844 | ![Before pause](before-pause-390x844.jpg) | ![After pause](after-pause-390x844.jpg) |
| guide / 480x900 | ![Before guide](before-guide-480x900.jpg) | ![After guide](after-guide-480x900.jpg) |
| guide / 390x844 | ![Before guide](before-guide-390x844.jpg) | ![After guide](after-guide-390x844.jpg) |
| island / 480x900 | ![Before island](before-island-480x900.jpg) | ![After island](after-island-480x900.jpg) |
| island / 390x844 | ![Before island](before-island-390x844.jpg) | ![After island](after-island-390x844.jpg) |
| shop / 480x900 | ![Before shop](before-shop-480x900.jpg) | ![After shop](after-shop-480x900.jpg) |
| shop / 390x844 | ![Before shop](before-shop-390x844.jpg) | ![After shop](after-shop-390x844.jpg) |
| browser / 480x900 | ![Before browser](before-browser-480x900.jpg) | ![After browser](after-browser-480x900.jpg) |
| browser / 390x844 | ![Before browser](before-browser-390x844.jpg) | ![After browser](after-browser-390x844.jpg) |
| details / 480x900 | ![Before details](before-details-480x900.jpg) | ![After details](after-details-480x900.jpg) |
| details / 390x844 | ![Before details](before-details-390x844.jpg) | ![After details](after-details-390x844.jpg) |
| zone / 480x900 | ![Before zone](before-zone-480x900.jpg) | ![After zone](after-zone-480x900.jpg) |
| zone / 390x844 | ![Before zone](before-zone-390x844.jpg) | ![After zone](after-zone-390x844.jpg) |

| Additional state | 480×900 | 390×844 |
| --- | --- | --- |
| complete | ![complete](after-complete-480x900.jpg) | ![Phone complete](after-complete-390x844.jpg) |
| states | ![states](after-states-480x900.jpg) | ![Phone states](after-states-390x844.jpg) |

390×844 captures use 47px top / 34px bottom safe-area insets. The source atlas,
portrait, exact ImageGen prompts and spatial registration are catalogued in
[the source directory](../../../art/expedition-hud/README.md).

Reproduce from the repository root:

```sh
make gen
make CFLAGS="-O2 -g -Werror"
python3 games/relic-rush/tools/prepare_hud.py --check
python3 tests/fixtures/expedition-header/capture.py --before-ref a47431a
make test
./build/relic-rush --headless --mute --fresh --smoke
./build/relic-rush --headless --mute --fresh --smoke --size 390x844 --safe-area 0,47,0,34
```

On Linux run rendering/input commands under Xvfb; macOS uses the native
headless renderer. Temporary Lua links avoid copying large asset directories.
The capture fixture exercises real press/move/release for pause and background
dismissal, preserving the unfinished board and protecting win/failure results.
Headless form tests cover fresh/inside/drag/multi-touch, nested top-layer cancel
and opt-out cases. Goal tests cover every required objective and zero clamping.

Validation passed in a separate checkout containing only this change: strict
`-Werror` build, full `make test` (67 form checks, 911 board checks, zero failures),
exact asset reproduction, native popup checks, and complete game smoke runs at
both phone sizes. All forty final review captures were inspected.
