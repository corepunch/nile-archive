# Square match-3

Match relics to clear the turquoise plaques. The first epoch opens the Spring well, Trapper’s cabin, Carpenter’s workshop and Expedition camp. The camp upgrades the Hammer to a Bomb that clears a 3 × 3 area. The replacement carries across the existing charge.

A legal swap across a shared edge makes a row or column of three or more
identical pieces. A board spawns five kinds. Bonus pieces replace a kind
once its building is confirmed. Each matched Hammer piece gives 3 charge
points and the meter fills at 90. Long matches count each Hammer once.

In the Debug iOS Simulator build, a two-finger tap over the board runs the
reference bot through legal swaps at two moves per frame. It can keep playing
after the move counter reaches zero. The normal win dialogue and reward follow.

## Line gems and rainbow gems

Four in a row or column leave a **line gem** where the swap landed (or at the
line's first cell in a cascade). It is still its piece: the same relic under
four cream bands that run the way it clears. Match it with two of its kind and
it sweeps its whole row or column. Five or more in a line leave a **rainbow
gem**, which matches nothing. Swap it with a neighbor to clear every piece of
that kind, or tap it to clear the kind it was made from.

| Swap | Result |
| --- | --- |
| Line gem with line gem | A row and a column through the moved gem |
| Rainbow gem with line gem | Every piece of the gem's kind becomes a line gem and fires |
| Rainbow gem with rainbow gem | The whole board is hit |

Swept pieces pay their Coins, Food and Supplies like matched ones; a tool
still clears without paying, and only matched bonus pieces charge a slot. A
gem under a chain waits until the chain breaks. The first line gem and the
first rainbow gem each show a one-line hint, and the Explorer's guide lists
both. This is the one place the board leaves Cradle of Rome, whose matches
only clear. The rules are the engine's `striped` and `color_bomb`
([optional match specials](../../../docs/MATCH3_ENGINE.md#optional-match-specials)),
switched on in [`lua/campaign.lua`](../lua/campaign.lua).

Both target layers occupy the same cell. Green becomes teal on the first
hit. A chain absorbs its own hit before a target underneath clears. Clear
all the targets within the move budget and collect the matched Coins, Food and Supplies.

When one to three plaques remain, a trail follows their four edges after a
short pause. It glows blue on a single plaque and green on a double plaque.
Reduce Motion hides the trail.

## Build

Only gold and silver coins pay into the wallet on the first expedition.
The Spring well introduces water buckets from expedition 2. The
Carpenter’s workshop adds timber. The Trapper’s cabin
introduces the Hammer. Each purchase adds one item, including stone for timber
and shrimp for water. The Harbour lodge unlocks the Hourglass and the
Cartographer’s house unlocks Lightning. The Keeper’s archive replaces helmets
with rings.
Amphoras are playable score pieces from the opening. See the
[twenty prices and unlocks](../README.md#buildings).

The lower-left house opens the next purchase. Its readout shows the
remaining amount for each required resource. If the wallet covers the price
early, the readout shows the expedition to clear. A particle trail circles
the house when both the level requirement and price are met. Open placement
from the card, choose a site, then confirm to pay once. The card links to the
decoration shop. After level 100, a pending purchase can offer a replay for
resources.

## Levels and art

The [100 ASCII layouts](../lua/campaign.lua) use a maximum field of nine
columns by twelve rows. Dots are ordinary cells, asterisks single targets,
plus signs double targets, `c` and `C` single and double chains over
targets, and hyphens holes. Each board has a `tier` (levels 1–4 tutorial,
then per ten levels easy, easy, normal, normal, hard, easy, normal, normal,
hard, boss). `python3 tools/square_boards.py relic-rush` validates them,
`tools/square_trim.py` trims long ones to the tier (easy 30, normal 45, hard
60, boss 70 targets at the bot's median) and `tools/tune_moves.py` fits each
board's `moves`. The [move budget](level-moves.md) is the bot's median clear
times 1.25, rounded up, plus three moves.

The existing first-clear and construction scenes tell Ines’s story.
Plaques are still the goal and the five slots carry the regular resource,
score and bonus pieces.

The [shared floor study](../../../art/match3-square/README.md) records the
Cradle of Rome references for papyrus and plaques. Ordinary cells have
fine mottled papyrus grain, with light falling from the upper left into a
warm lower-right shadow. The single plaque shades from petrol blue to navy
along the same diagonal. The double plaque has a soft olive highlight from
lower left to upper right.

Built-in ImageGen painted the [current floor faces](../art/papyrus-board/contact.png)
using the [board layout](../art/papyrus-board/contact-layout.png), the
`cell_normal.png` and `cell_puzzle_one.png` studies, and the
[paint-over prompt](../art/papyrus-board/contact-prompt.txt).

The frame occupies whole 128 px cells in the empty ring and in board holes.
Each cell selects one sprite and a quarter turn from its eight neighbours.
The [square frame generator](../../../tools/square_board_frame.py) rounds
exposed corner caps and joins the arms of recessed corners at right angles.
It bakes the board's contact shadow along the inner edge and a soft
backdrop shadow beyond the brighter outer bevel, within the frame tile.
The [cracked stone texture](../art/papyrus-board/stone-cracks.png) multiplies
over the sandstone face. The generator keeps the fissures fine and adds
slight contrast in the Multiply map so they read at phone size.
ImageGen first painted the
[stone grain](../art/papyrus-board/stone-grain.png) from its
[material prompt](../art/papyrus-board/stone-grain-prompt.txt), then added
angular fractures using [the crack prompt](../art/papyrus-board/stone-cracks-prompt.txt)
and the supplied `gmf_corner_10.png` study. The generator bakes the angled
joints and [painted foliage](../../../engine/art/board-frame/decorations-source.png)
into each variant. The leaf stem sits at the bend and the fan points into
the empty cell. Bare and leafy variants alternate at recessed corners.
Stone, shadow and leaves fit inside the same empty square.
[Atlas registration](../art/match3-atlas.json) records the source crops,
texture blend, pivots and runtime atlas regions.
Rebuild from the repository root with `python3 tools/match3_atlas.py`.

## Construction balance

`python3 tools/balance.py relic-rush` fits the twenty purchase prices to the
bot's measured income: the balance sample tries 40 deals per board and
applies the average income per win to the purchase order. With the fitted
prices the expected campaign needs no replays, and each purchase is
affordable on its first eligible clear. Earnings vary with the deals and
matches. The seeded campaign check funds and places every ladder purchase
in order from the first win of each board.

```sh
BALANCE_RUNS=40 build/test/relic-rush --extended 'rules campaign_play' 'rules relic_balance'
```

## Captures

- [Harbour lodge before and after, 480 × 900](screenshots/review/building-rewards/lodge-480.jpg)
- [Harbour lodge before and after, 390 × 844](screenshots/review/building-rewards/lodge-390.jpg)

- [Jade Steps, 480 × 900](screenshots/square-jade-steps.jpg)
- [Tide Chamber, 390 × 844](screenshots/square-tide-chamber.jpg)
- [Fallen Colonnade, 480 × 900](screenshots/square-fallen-colonnade.jpg)
- [Heart of the Temple, 390 × 844](screenshots/square-heart-of-the-temple.jpg)
- [Build ready](screenshots/square-build-ready.jpg)
- [Still needed](screenshots/square-build-cost.jpg)

Capture from the game using `build/test/all --suite=relic-rush "shot square-"`.

The square Moves counter uses the board's rim colors and turns red for the
last five moves.

### Blockers and target hints

The stone blocker fills a square cell and clears after one adjacent match
or direct tool hit. The [painted strip](../../../art/match3-square/stones.png)
and [prompt](../../../art/match3-square/stones-prompt.txt) record both themes.
Repack with `python3 tools/match3_atlas.py`.
[480 × 900](screenshots/review/square-blockers/stones-480.jpg) ·
[390 × 844](screenshots/review/square-blockers/stones-390.jpg) ·
[Square states catalogue](screenshots/review/square-blockers/square-catalogue-480.jpg).

The [shared blocker sheet](../../../art/match3-square/README.md#blockers)
supplies a single silver chain and a crossed pair. Two ice states use
borderless, translucent frost, with a chipped upper edge after the first hit.
The board artwork review shows all four states together.

| Size | Board, before and after | Guide, before and after |
| --- | --- | --- |
| 480 × 900 | [Blockers](screenshots/review/square-blockers/board-480.jpg) | [Chain example](screenshots/review/square-blockers/guide-480.jpg) |
| 390 × 844 | [Blockers](screenshots/review/square-blockers/board-390.jpg) | [Chain example](screenshots/review/square-blockers/guide-390.jpg) |

[Motion on the final two plaques](screenshots/review/square-blockers/target-hints.webp).

```sh
build/test/all --suite=relic-rush 'shot art-pieces' 'shot phone-art-pieces' 'shot guide' 'shot phone-guide' 'reel relic-rush-tablet-hints-phone'
```

### Build progress captures

- [480 × 900](screenshots/square-build-progress.jpg)
- [390 × 844 with safe areas](screenshots/square-build-progress-phone.jpg)
- [Waiting for an expedition clear](screenshots/square-build-gate.jpg)

Capture these states with `build/test/relic-rush "shot square-build-progress" "shot square-build-gate"`.
