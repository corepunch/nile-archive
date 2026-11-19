# Square match-3

Match Christmas pieces to light the teal panes. The campaign opens the Welcome arch, Reindeer stable, Lumber workshop, Gingerbread house, Gingerbread bakery, Snowy chapel and Hot cocoa kiosk. The workshop introduces pine and the chapel replaces it with dressed stone. The stable introduces the farrier's hammer. The Gingerbread house upgrades its slot to Firework Bomb and keeps its charge.

A legal swap across a shared edge makes a row or column of three or more
identical pieces. A board spawns five kinds. Bonus pieces replace a kind
once its building is confirmed. Thirty matched bonus pieces fill their
permanent slot exactly once. Spending the tool empties the slot. The
[shared ranks and charge rules](../../../docs/MATCH3_ENGINE.md) apply to both
Christmas Market and Relic Rush.

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

Honey maple and lightly frosted teal panes sit inside a narrow aged-oak frame.
The [source and lighting measurements](../../../art/match3-square/README.md)
describe the Cradle of Rome 2 palette study and original tile paintings.

### Modular perimeter

The engine checks the eight neighbors of each empty cell around the playfield,
including the ring just outside the level grid. It selects one baked
128 × 128 module and rotates it in quarter turns. Touching one playable side
produces a rail, touching only a diagonal produces a rounded outer cap, and
touching two playable sides produces an inside join. Eligible inside joins
alternate between bare oak and the same oak with holly baked into the module.
Both square games use the same placement rules. Each game packs its own
materials in `data/board/cells.png`. Frame pixels stay in the empty cells.

[Eight finishes compared on an identical stepped board](screenshots/review/square-frame/variants.jpg).
The live finish is **Aged oak**. Its dark rim, narrow warm shoulder and small
diagonal cuts follow the Cradle of Rome 2 frame's visual hierarchy. The other
seven materials remain in the [source atlas](../art/square-frame/variants.png).
The [paint prompt](../art/square-frame/prompt.txt), [style order](../art/square-frame/styles.json)
and [registration](../art/match3-atlas.json) record the source and fitted rail.

| Native capture | Before | After |
| --- | --- | --- |
| 480 × 900 | [Previous frame](screenshots/review/winter-boosters/toolbar-480.jpg) | [Aged oak](screenshots/review/square-frame/board-480.jpg) |
| 390 × 844 | [Previous frame](screenshots/review/winter-boosters/toolbar-390.jpg) | [Aged oak](screenshots/review/square-frame/board-390.jpg) |

[Winter Wreath's stepped edges](screenshots/review/square-frame/wreath.jpg) ·
[Deep notch with chains and ice](screenshots/review/square-frame/notch.jpg)

```sh
python3 tools/match3_atlas.py
python3 tools/square_board_frame.py --review games/christmas-market/docs/screenshots/review/square-frame/variants.jpg
build/test/christmas-market "shot booster-toolbar" "shot square-winter-wreath" "shot phone-pieces-board"
```

### Piece size

All pieces are sized to the square cell and centered by their opacity-weighted
mass. The square corners leave space for the diagonal hammer and cracker.
The farrier's hammer uses the same painted head and wooden handle on the board
and in all five toolbar states.

| Size | Before | After |
| --- | --- | --- |
| 480 × 900 | [Board](screenshots/review/winter-stalls/board-480-before.jpg) | [Board](screenshots/review/winter-stalls/board-480.jpg) |
| 390 × 844 | [Board](screenshots/review/winter-stalls/board-390-before.jpg) | [Board](screenshots/review/winter-stalls/board-390.jpg) |

[Dense board with chains and ice](screenshots/review/winter-stalls/final-480.jpg) ·
[Five bonus button states](screenshots/review/winter-stalls/bonus-states.jpg)

### Shared bonus slots

| Size | Earlier toolbar | Shared slots |
| --- | --- | --- |
| 480 × 900 | [Board](screenshots/review/large-pieces/board-480.jpg) | [Board](screenshots/review/shared-bonuses/toolbar-480.jpg) |
| 390 × 844 | [Board](screenshots/review/large-pieces/board-390.jpg) | [Board](screenshots/review/shared-bonuses/toolbar-390.jpg) |

[One use spent](screenshots/review/shared-bonuses/spent.jpg) ·
[Eight bonus pieces and five interaction states](screenshots/review/shared-bonuses/art-states.jpg)

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
