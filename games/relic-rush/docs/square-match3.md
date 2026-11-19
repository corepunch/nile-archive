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
Cradle of Rome palette references for the limestone and plaques. The
Relic Rush rim is carved sandstone with jade inlays, inspired by Maya jungle
temples. Each perimeter tile sits on a vertex of the square grid. It joins
its neighbours halfway along each exposed cell edge. The recessed corner
includes the tropical leaves and their shadows in the same painting.

Built-in ImageGen painted the [four-tile sheet](../art/square-frame/source.png)
from the [layout guide](../art/square-frame/layout.png) and
[initial prompt](../art/square-frame/prompt.txt). A
[second pass](../art/square-frame/foliage.png) retouched the plant with
the [foliage prompt](../art/square-frame/retouch-prompt.txt). The current
[corner painting](../art/square-frame/large-foliage.png) grows a larger fan
into the recess, using an [expanded layout](../art/square-frame/large-foliage-layout.png)
and [paint-over prompt](../art/square-frame/large-foliage-prompt.txt).
[Atlas registration](../art/match3-atlas.json) records the source coordinates and
runtime atlas regions. One grid step spans 128 px. The inset corner uses a
224 px canvas centred on the same vertex so the foliage can extend beyond
the stone joins.
Rebuild from the repository root with `python3 tools/match3_atlas.py`.

## Captures

- [Jade Steps, 480 × 900](screenshots/square-jade-steps.jpg)
- [Tide Chamber, 390 × 844](screenshots/square-tide-chamber.jpg)
- [Build ready](screenshots/square-build-ready.jpg)
- [Still needed](screenshots/square-build-cost.jpg)

Capture from the game using `build/test/all --suite=relic-rush "shot square-"`.
