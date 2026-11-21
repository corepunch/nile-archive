# Square match-3

Match Christmas pieces to light the teal panes. The 100-level campaign opens twenty stalls, one after every fifth level (see the [construction sequence](market-pieces.md#construction-sequence)). Each stall unlocks one item. The first Advent brings mulled wine, the Farrier's hammer, bundled pine and the Firework Bomb. The hammer charges a single-cell blow. The Firework Bomb inherits that slot and its charge. Bundled pine replaces the mitten, and dressed stone later replaces the pine.

A legal swap across a shared edge makes a row or column of three or more
identical pieces. A board spawns five kinds. Bonus pieces replace a kind
once its building is confirmed. Thirty matched bonus pieces fill their
permanent slot exactly once. Spending the tool empties the slot. The
[shared ranks and charge rules](../../../docs/MATCH3_ENGINE.md) apply to both
Christmas Market and Relic Rush.

## Line gems and rainbow gems

Four in a row or column leave a **line gem** where the swap landed (or at the
line's first cell in a cascade). It is still its piece: the same treat or
token under cream ribbons that run the way it clears, with a rim of light and
a glint that crosses it in that direction. Match it with two of
its kind and it sweeps its whole row or column. Five or more in a line leave a
**rainbow gem**, which matches nothing. Swap it with a neighbor to clear every
piece of that kind, or tap it to clear the kind it was made from.

| Swap | Result |
| --- | --- |
| Line gem with line gem | A row and a column through the moved gem |
| Rainbow gem with line gem | Every piece of the gem's kind becomes a line gem and fires |
| Rainbow gem with rainbow gem | The whole board is hit |

Swept pieces pay their Tokens, Treats and Materials like matched ones; a tool
still clears without paying, and only matched bonus pieces charge a slot. A
gem under a chain waits until the chain breaks. The first line gem and the
first rainbow gem each show a one-line hint, and the Market keeper's guide
lists both. The rules are the engine's
`striped` and `color_bomb` ([optional match specials](../../../docs/MATCH3_ENGINE.md#optional-match-specials)),
switched on in [`lua/campaign.lua`](../lua/campaign.lua).

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
After level 100, a pending purchase can offer a replay for resources.

## Levels and art

The [color map](market-pieces.md) pairs Cradle of Rome 2 pieces and purchase
rewards with the Christmas Market artwork, yields and prices.

The [100 ASCII layouts](../lua/campaign.lua) use a maximum field of nine
columns by twelve rows. Each carries a `tier` (levels 1–4 tutorial, then per ten levels easy, easy, normal, normal, hard, easy, normal, normal, hard, boss), checked by `python3 tools/square_boards.py christmas-market`, covered with panes by `tools/square_trim.py --fill` (plain only where the bot reaches last, so the median clear fits 24 moves on easy boards, 28 on normal, 30 on hard and 32 on bosses) and given its `moves` by `tools/tune_moves.py`. Panes cover 95% of the cells on average, and no budget passes 40 moves. Dots are ordinary cells, asterisks single targets,
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

Pieces fit the square cell. Most use their opacity-weighted center. The snowy
fir uses its visible bounds so the tip and trunk have equal breathing room,
and the frost shield does the same so its point and rim sit evenly.
The square corners leave room for the diagonal hammer and cracker bundle. The
same hammer and station clock illustrations appear on the board and in all
five toolbar states.

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

- [Level 14 before and after the panes covered it, 480 × 900](screenshots/review/covered-boards/level-14-480.jpg)
- [The same at 390 × 844](screenshots/review/covered-boards/level-14-390.jpg)
- [Winter Wreath](screenshots/square-winter-wreath.jpg)
- [Christmas Star](screenshots/square-christmas-star.jpg)

Capture from the game using `build/test/all --suite=christmas-market "shot square-"`.

The square Moves counter uses the board's rim colors and turns red for the
last five moves.

### Blockers and target hints

The stone blocker fills a square cell and clears after one adjacent match
or direct tool hit. The [painted strip](../../../art/match3-square/stones.png)
and [prompt](../../../art/match3-square/stones-prompt.txt) record both themes.
Repack with `python3 tools/match3_atlas.py`.
[480 × 900](screenshots/review/square-blockers/stones-480.jpg) ·
[390 × 844](screenshots/review/square-blockers/stones-390.jpg).

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

## Upgrades

Sixteen stalls earn an upgrade, after Cradle of Rome 2's citizens `man_01` to `man_16`
([the table](../../../docs/CAMPAIGN_DESIGN.md#upgrades-romes-citizens-kept-by-the-cast-we-know)): a second oven at
the Gingerbread bakery (Agnes), a second furnace at the Glassblower's stall (Theo), a star for the Christmas tree
(Theo) and so on, each kept by a character who already runs it. The Station kiosk, Gift wrapping pavilion, Winter
skating rink and Santa's sleigh have none. [`lua/user_events.lua`](../lua/user_events.lua) holds the feats and perks
(Tokens, Treats and Materials in every win, or a tool that charges one point more per match); the runtime is the
engine's ([`match3/user_events.lua`](../../../engine/lua/match3/user_events.lua)), wired in by
`lua/user_events_runtime.lua`. Placing the stall arms the feat; meeting it upgrades the stall and adds the perk.
The income shows in the results card's totals like the carousel's. The stall's card shows the feat, then
"Upgraded: ..." with the perk. The keeper's scene is the upgrade's entry in `docs/story.md` under `## Upgrades`,
played on the next return to market (a toast if it is missing).
