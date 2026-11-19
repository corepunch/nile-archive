# Lines of three, six kinds and the crew's requests

Relic Rush now matches straight lines of three among six kinds. The sixth slot
shows quartz, or the piece of an open crew request. Open requests stand as
round markers down the island's left edge, under the next building.
[Rules](../../../match4-rules.md#crew-requests) · [Story](../../../story.md#crew-requests)

## Board

| View | Before: lines of four, five kinds | After: lines of three, six kinds |
| --- | --- | --- |
| Expedition 1 · 480×900 | ![Five kinds on The Landing](board1-before.jpg) | ![Quartz joins as the sixth kind](board1-after.jpg) |
| Expedition 3 · 480×900 | ![Expedition 3 with five kinds](board3-before.jpg) | ![Chart pages and berries on expedition 3](board3-after.jpg) |
| Expedition 3 · 390×844 | ![Expedition 3 on the phone](phone-board3-before.jpg) | ![Chart pages and berries on the phone](phone-board3-after.jpg) |

| Expedition 6: arrows and tool rolls | Expedition 9: relay cable | Results with request pieces |
| --- | --- | --- |
| ![Trail arrows and tool rolls](board6.jpg) | ![Relay cable beside timber](board9.jpg) | ![Results list chart pages and berries](result.jpg) |

## Island

| View | Before | After |
| --- | --- | --- |
| Island · 480×900 | ![Island without markers](island-before.jpg) | ![Next building and two requests on the left](island-after.jpg) |
| Island · 390×844 | ![Phone island without markers](phone-island-before.jpg) | ![Phone island with request markers](phone-island-after.jpg) |

| Ready to hand in | One board slot: the second request waits |
| --- | --- |
| ![Filled requests glow on the selected face](island-ready.jpg) | ![The waiting request uses the disabled face](island-waiting.jpg) |

## Request card

| Short · 480×900 | Short · 390×844 | Filled · 480×900 |
| --- | --- | --- |
| ![Card with the amount still needed](card.jpg) | ![Phone card](phone-card.jpg) | ![Card offering to hand the request in](card-ready.jpg) |

`build/test/relic-rush "shot quest-"` renders the after views. The before views
come from the previous commit with `--level 1`, `--level 3` and `--city 2`.
