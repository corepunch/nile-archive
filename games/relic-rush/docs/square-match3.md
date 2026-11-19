# Square match-3

Match relics to clear the turquoise plaques. The first chapter opens the Well, Hunter’s Hut, Sawmill and Village. The Village upgrades the Hammer to a Bomb that clears a 3 × 3 area. The replacement carries across the existing charge.

A legal swap across a shared edge makes a row or column of three or more
identical pieces. A board spawns five kinds. Bonus pieces replace a kind
once its building is confirmed. Each matched Hammer piece gives 3 charge
points and the meter fills at 90. Long matches count each Hammer once.

Both target layers occupy the same cell. Green becomes teal on the first
hit. A chain absorbs its own hit before a target underneath clears. Clear
all the targets within the move budget and collect the matched Coins, Food and Supplies.

## Build

Only gold and silver coins pay into the wallet on the first expedition.
The Well introduces water buckets worth 3 Food from expedition 2. The
Sawmill adds timber worth 5 Supplies from expedition 8. The Hunter’s Hut
introduces the Hammer from expedition 5. Later purchases replace existing
pieces, including stone for timber and shrimp for water. See the
[fourteen prices and unlocks](../README.md#buildings).

The lower-left house opens the next purchase. Its readout shows the
remaining amount for each required resource. If the wallet covers the price
early, the readout shows the expedition to clear. A particle trail circles
the house when both the level requirement and price are met. Open placement
from the card, choose a site, then confirm to pay once. The card links to the
decoration shop. After level twenty, a pending purchase can offer a replay for
resources.

## Levels and art

The [twenty ASCII layouts](../lua/campaign.lua) use a maximum field of nine
columns by twelve rows. Dots are ordinary cells, asterisks single targets,
plus signs double targets, `c` and `C` single and double chains over
targets, and hyphens holes.

Expeditions 11–20 use new square layouts for the sites of the previous hex
chapter. The existing first-clear and construction scenes tell Ines’s story.
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

The [square frame generator](../../../tools/square_board_frame.py) rounds
outside corners and joins recessed corners at right angles. It uses the
distance to the board to place the dark contact shadow on the side facing
the floor. The sandstone has a dark warm outer edge and a flat tan face
with seeded grain and angled joints. The palette follows the stone and
shadow samples in `gmf_corner_1.png`, `gmf_corner_9.png` and
`gmf_corner_11.png`. The rounded outline follows the supplied game capture.
The generator joins sections halfway along each exposed cell edge. It bakes
the [painted foliage](../../../engine/art/board-frame/decorations-source.png)
over the stone in a single 224 px corner sprite, on the same grid pivot
as the 128 px bare corner. The two inset corners alternate. Leafy corners
draw after the other frame sections so the leaves stay visible across joins.
[Atlas registration](../art/match3-atlas.json) records the source crops,
pivots and runtime atlas regions.
Rebuild from the repository root with `python3 tools/match3_atlas.py`.

## Construction balance

The seeded campaign check funded and placed all fourteen buildings in order
using matches from the first win of each of the twenty boards. Two failed
attempts were retried and contributed no resources. The final wallet held
865 Coins, 1,053 Food and 657 Supplies. The separate balance sample tries
40 deals per board and applies the average income per win to the purchase
order. At the measured income, each purchase was affordable on its first
eligible clear. Earnings vary with the deals and matches.

```sh
BALANCE_RUNS=40 build/test/relic-rush --extended 'rules campaign_play' 'rules relic_balance'
```

## Captures

- [Jade Steps, 480 × 900](screenshots/square-jade-steps.jpg)
- [Tide Chamber, 390 × 844](screenshots/square-tide-chamber.jpg)
- [Fallen Colonnade, 480 × 900](screenshots/square-fallen-colonnade.jpg)
- [Heart of the Temple, 390 × 844](screenshots/square-heart-of-the-temple.jpg)
- [Build ready](screenshots/square-build-ready.jpg)
- [Still needed](screenshots/square-build-cost.jpg)

Capture from the game using `build/test/all --suite=relic-rush "shot square-"`.

### Build progress captures

- [480 × 900](screenshots/square-build-progress.jpg)
- [390 × 844 with safe areas](screenshots/square-build-progress-phone.jpg)
- [Waiting for an expedition clear](screenshots/square-build-gate.jpg)

Capture these states with `build/test/relic-rush "shot square-build-progress" "shot square-build-gate"`.
