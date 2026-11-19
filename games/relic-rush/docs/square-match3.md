# Square match-3

Match relics to clear the turquoise plaques. The first campaign opens the Well, Hunter’s Hut, Sawmill and Village. The Village upgrades the Hammer to a Bomb that clears a 3 × 3 area. The replacement carries across the existing charge.

A legal swap across a shared edge makes a row or column of three or more
identical pieces. A board spawns five kinds. Bonus pieces replace a kind
once its building is confirmed. Each matched Hammer piece gives 3 charge
points and the meter fills at 90. Long matches count each Hammer once.

Both target layers occupy the same cell. Green becomes teal on the first
hit. A chain absorbs its own hit before a target underneath clears. Clear
all the targets within the move budget and collect the matched Coins, Food and Supplies.

## Build

The lower-left Build button opens the next purchase. The card shows the
price or the amounts still needed. The particle trail runs when the level
gate and resource price are met. Open placement from the card, choose a
site, then confirm to pay once. The card links to the decoration shop.
After level ten, a pending purchase can offer a replay for resources.

## Levels and art

The [ten ASCII layouts](../lua/campaign.lua) use a maximum field of nine
columns by twelve rows. Dots are ordinary cells, asterisks single targets,
plus signs double targets, `c` and `C` single and double chains over
targets, and hyphens holes.

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
the floor. The flat sandstone face has a narrow outer bevel, seeded grain,
and dark angled joints with light shoulders along the cuts. The corner studies were
`gmf_corner_2.png`, `gmf_corner_9.png`, `gmf_corner_11.png` and
`gmf_corner_17.png`, plus the rounded silhouette in the supplied game capture.
The generator joins sections halfway along each exposed cell edge. It bakes
the [painted foliage](../../../engine/art/board-frame/decorations-source.png)
under the stone in a single 224 px corner sprite, on the same grid pivot
as the 128 px bare corner. The two inset corners alternate.
[Atlas registration](../art/match3-atlas.json) records the source crops,
pivots and runtime atlas regions.
Rebuild from the repository root with `python3 tools/match3_atlas.py`.

## Captures

- [Jade Steps, 480 × 900](screenshots/square-jade-steps.jpg)
- [Tide Chamber, 390 × 844](screenshots/square-tide-chamber.jpg)
- [Build ready](screenshots/square-build-ready.jpg)
- [Still needed](screenshots/square-build-cost.jpg)

Capture from the game using `build/test/all --suite=relic-rush "shot square-"`.
