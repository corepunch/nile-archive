# Dialogue outlines and a data-backed guide

Before captures use main at `5ea3e971a51b5882d7ef7d5208d905e8d97e1998` (PR #14). After captures use this change. Tracked JPEGs are review evidence; canonical screenshots are also refreshed in each game’s `docs/screenshots/`.

The badge center follows the visible outline, including thought puffs and shout spikes. Those decorative outsets count toward text padding. One- and two-line rounded speech, thought and shout bubbles are covered, along with Nile Archive’s standing portraits and Emergency’s dispatcher.

The Explorer’s guide is an engine `list` populated through `set_items`, with stable record IDs. Each item builds a horizontal icon/content stack. The content column is measured in the space remaining beside its icon; labels start-align when an icon exists. Records without icons can center their copy. No per-row coordinates are authored.

## Reproduce

Build with `make CFLAGS="-O2 -g -Werror"`. On Linux prefix rendering commands with `xvfb-run -a` and set `LIBGL_ALWAYS_SOFTWARE=1`. All captures use `--headless --fresh --mute` and `--shot <path>.png`:

| Game | Review name | Arguments |
| --- | --- | --- |
| Relic Rush | speech-one | `--dialog tomas --frames 240` |
| Relic Rush | speech-two | `--dialog adrian --frames 240` |
| Relic Rush | cloud | `--dialog intro --frames 240` |
| Relic Rush | burst | `--dialog mara --frames 240` |
| Relic Rush | guide | `--dialog guide --frames 40` |
| Nile Archive | nile-story, nile-horem, nile-merit | `--screen story` / `horem` / `merit`, `--frames 240` |
| Emergency | emergency-dialog | `--level 1 --dialog --frames 240` |

Relic Rush is captured at `--size 480x900` and `--size 390x844 --safe-area 0,47,0,34`. Nile Archive has 1200×900 captures of all three speakers, plus story at 1368×1026 and merit at 1600×900. Emergency is 1368×1026. Review images are capped at 1200×1026; canonical screenshots retain native capture dimensions.

`make test` covers source refresh, scoped row actions, stable focus, invalid updates and wrapped row measurement/arrangement. `make test-platform` additionally reads real rendered bubble/badge/text pixels in eighteen combinations. Relic Rush’s `--smoke` opens and dismisses the real guide using its measured button bounds before exercising gameplay. `make shots` regenerates canonical screenshots.

Tracked by [issue #16](https://github.com/corepunch/nile-archive/issues/16).
