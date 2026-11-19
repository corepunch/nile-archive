# Square match-3

Match Christmas pieces to light the teal panes. The campaign opens the Welcome arch, Reindeer stable, Lumber workshop, Gingerbread house, Gingerbread bakery and Hot cocoa kiosk. The stable introduces the farrier's hammer. The Gingerbread house supplies one Firework Bomb per wish.

A legal swap across a shared edge makes a row or column of three or more
identical pieces. A board spawns five kinds. Bonus pieces replace a kind
once its building is confirmed. Each matched Hammer piece gives 3 charge
points and the meter fills at 90. Long matches count each Hammer once.

Both target layers occupy the same cell. Green becomes teal on the first
hit. A chain absorbs its own hit before a target underneath clears. Clear
all the targets within the move budget and collect the matched Tokens, Treats and Materials.

When one to three panes remain, a trail follows their four edges after a
short pause. It glows blue on a single pane and green on a double pane.
Reduce Motion hides the trail.

## Build

The lower-left Build button opens the next purchase. The card shows the
price or the amounts still needed. The particle trail runs when the level
gate and resource price are met. Open placement from the card, choose a
site, then confirm to pay once. The card links to the decoration shop.
After level ten, a pending purchase can offer a replay for resources.

## Levels and art

The [color map](market-pieces.md) pairs Cradle of Rome 2 pieces and purchase
rewards with the Christmas Market artwork, yields and prices.

The [ten ASCII layouts](../lua/campaign.lua) use a maximum field of nine
columns by twelve rows. Dots are ordinary cells, asterisks single targets,
plus signs double targets, `c` and `C` single and double chains over
targets, and hyphens holes.

Honey maple, lightly frosted teal panes, holly-engraved gilded oak, and spruce, berry and brass corner ornaments. The [source and lighting measurements](../../../art/match3-square/README.md)
describe the Cradle of Rome 2 palette study and original painted frames.
See [atlas registration](../art/match3-atlas.json) for the source crop and
runtime region of each tile and ornament. Rebuild from the repository root
with `python3 tools/match3_atlas.py`.

## Captures

- [Winter Wreath](screenshots/square-winter-wreath.jpg)
- [Christmas Star](screenshots/square-christmas-star.jpg)

Capture from the game using `build/test/all --suite=christmas-market "shot square-"`.

### Blockers and target hints

The [shared blocker sheet](../../../art/match3-square/README.md#blockers)
supplies a single silver tie and a crossed pair. The board artwork review
also shows full and chipped borderless ice over the treats.

| Size | Board, before and after | Guide, before and after |
| --- | --- | --- |
| 480 × 900 | [Blockers](screenshots/review/square-blockers/board-480.jpg) | [Tied treat](screenshots/review/square-blockers/guide-480.jpg) |
| 390 × 844 | [Blockers](screenshots/review/square-blockers/board-390.jpg) | [Tied treat](screenshots/review/square-blockers/guide-390.jpg) |

[Three remaining panes with their edge trails](screenshots/review/square-blockers/target-hints.jpg).

```sh
build/test/all --suite=christmas-market 'shot pieces-board' 'shot phone-pieces-board' 'shot guide' 'shot phone-guide' 'frame christmas-market-tablet-hints'
```
