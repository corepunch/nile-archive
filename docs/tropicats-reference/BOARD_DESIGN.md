# Tropicats board design: patterns in authored levels

These observations describe the extracted 2.5.11 campaign, not verified play outcomes. A variant is a numbered level plus a/b/c tier; these are 8,190 authored configurations of 2,730 numbered levels, plus 500 unsuffixed assets excluded from the statistics. Every tier has a 9×9 array envelope, with field value 0 making holes. Nonzero fields include windows, so “field cells” below is a serialized mask count, not guaranteed ordinary matchable space. Layer counts count occupied cells, not HP, independent obstacles, or moves to clear. [Mechanics and evidence limits](MECHANICS.md) explains each layer.

Run `python3 tools/tropicats-viewer/serve.py` from the repository root to open the level links. The atlas is a static inspector; it does not simulate gravity, randomness or play. Raw examples are `reference/tropicats-analysis/levels/0001a`, `0001b`, `0001c`, etc. Those extracted inputs are ignored local files.

## What changes a board's problem

- **Shape and routes:** [1](http://127.0.0.1:8765/#level=1) uses a 54-cell tapered shape with a climber target; [11](http://127.0.0.1:8765/#level=11) has a 45-cell mask and turtle route markers. Holes and narrow sections change where pieces can be arranged, while separately authored routes and spawn points make objective movement a distinct constraint. A 0 in `spawning` does not prove the game cannot refill there; level 11 b/c have no nonzero entries in that layer.
- **Separated spaces connected by routes:** [51](http://127.0.0.1:8765/#level=51) has 72 field cells, eight portal endpoints in four pairs, and eight drop-route markers in all three tiers. Entrances lie on lower boundaries and paired exits on upper boundaries; inspect the portal layer to follow the linkage. This gives the turtle goal a spatial itinerary without proving the exact falling algorithm.
- **Layered discovery and access:** [8](http://127.0.0.1:8765/#level=8) combines a full 81-cell mask with stones, tiles and hidden-item footprints. Its a/b/c tiers contain respectively 20/48/67 tile cells and 16/35/35 hidden-item cells. They also contain 47/43/43 stone cells. The combined view shows a change in what covers the board, not simply an increase in one number. Hidden IDs can span cells; occupied-cell counts are not statue counts.
- **Gates with a color constraint:** [606](http://127.0.0.1:8765/#level=606) combines 63 field cells, 20 crate cells, 45 tile cells, 40 hidden-item cells and 12 portal endpoints in each tier. Crate colors and strengths, special placements and palette can change despite identical layer occupancy. This reuses one spatial plan while changing how its layers are approached.
- **Interaction of scarce colors and blockers:** [2422](http://127.0.0.1:8765/#level=2422) keeps a 69-cell mask and 36 stone cells but grows crates 16→28→35; green's authored amount is 8/8/6 while other listed colors have 25. Cannons and reduced wheels appear here. Treat `amount` as an authored weight parameter rather than a proven percentage: the exact sampling and reduced-palette predicate are unverified.
- **Combined goals:** [2726](http://127.0.0.1:8765/#level=2726) specifies four climbers and four chameleons in each tier. Its 62-cell mask, eight climber markers and eight stone cells stay fixed; crate cells rise 19→23→31 while moves are 32/34/30. Two goal systems compete for board space and attention; a static board alone cannot establish how difficult the interaction is in play.

## Tiers are authored alternatives, not a single difficulty slider

| Level | Tier a | Tier b | Tier c | What changes |
| --- | --- | --- | --- | --- |
| [1](http://127.0.0.1:8765/#level=1) | 30 moves, 1 climber, 0 stone cells | 25 moves, 1 climber, 9 stones | 25 moves, 2 climbers, 14 stones | Same 54-cell mask; targets, blockers and palette change. |
| [8](http://127.0.0.1:8765/#level=8) | 35 moves, 20 tile cells | 38 moves, 48 tile cells | 41 moves, 67 tile cells | More moves accompany more covering, not a universal move reduction. |
| [11](http://127.0.0.1:8765/#level=11) | 25 moves, 2 turtles, 0 stones | 26 moves, 3 turtles, 9 stones | 28 moves, 4 turtles, 14 stones | Same 45 field cells, increasing target and obstruction alongside budget. |
| [411](http://127.0.0.1:8765/#level=411) | 37 moves, 49 fields, 0 stones | 25 moves, 63 fields, 12 stones | 25 moves, 77 fields, 14 stones | Even the field mask can change considerably between tiers. |
| [606](http://127.0.0.1:8765/#level=606) | 30 moves | 36 moves | 28 moves | Equal occupied counts of major layers hide different values and palettes. |

Across all 2,730 paired numbers, c has fewer moves than a in **1,906**, equal moves in **261**, and more in **563**. Mean budgets a/b/c are **34.07 / 32.84 / 31.10**; ranges are 20–46 / 19–46 / 18–45. These summarize authored budgets, not actual difficulty, win rate, or number of player attempts. Even an apparently increased obstacle count does not prove a harder puzzle without runtime testing.

## A practical authoring pass

Treat a tier as three independently adjustable decisions, then set a move budget and test their interaction:

| Decision | Authoring question | Source comparison |
| --- | --- | --- |
| Goal and demand | What must be collected, and how much? | Level 1 changes one climber to two in c; level 11 asks for 2/3/4 turtles. Level 2726 keeps both targets at four across tiers. |
| Shape and movement | Which field cells, route markers, portals and spawn constraints expose the goal? | Level 411 changes the mask 49→63→77 cells; level 51 keeps the 72-cell mask and four portal pairs while changing other properties. Inspect routes independently of the mask. |
| Local layers and palette | What covers, blocks or colors the playable space? | Level 8 increases tile cells 20→48→67; level 606 holds major layer occupancy constant but changes source values and palette. Compare the atlas's cell inspector rather than extrapolating from counts. |

For a new board, first pick the goal and sketch a readable route or region for it. Choose a field mask and connection points that make that route consequential, then place coverings, blockers, initial specials and palette weights around it. Create tier variants deliberately along those three axes: specify which feature stays recognizable, which constraints change, and why. Give each tier an initial move allowance, then playtest openings, cascades, reachability and the actual objective flow; revise budgets and constraints from observed outcomes. Inspect combined layers and each numeric layer so a hidden obstruction or spawn restriction does not accidentally undermine the intended route. These steps are a design method inferred from the serialized examples, not a claim about Tropicats' internal authoring process.

## Measured vocabulary and presentation sequence

The generator [tools/tropicats_board_analysis.py](../../tools/tropicats_board_analysis.py) reads all tier files and reports counts and first serialized appearances, with no external dependency:

```sh
python3 tools/tropicats_board_analysis.py > /tmp/tropicats-board-analysis.json
```

It requires exactly 8,190 filenames matching four digits plus a/b/c and checks every field mask has 81 entries. Counts are variants containing at least one nonzero value, not counts of levels, objects or hits. It does not include unsuffixed assets, interpret goals, or execute the game.

| Layer | Variants with nonzero entries | Earliest relevant campaign source value |
| --- | ---: | --- |
| Stones | 3,768 | `0001b` stone 1; `0001c` stone 2; `0010a` stone 3; `0041a` stone 4; `0041c` stone 5 |
| Chains | 2,329 | `0013a` strength 1; `0013b` strength 2; `0028c` strength 3 |
| Crates | 2,859 | `0067a` strength 1; `0067b` strength 2; `0068c` strength 3; colored crate `0571a` |
| Tiles | 3,554 | Inspect exact values and first tier in generator output |
| Hidden items | 2,021 | Inspect IDs in generator output; one object can cover multiple cells |
| Portals | 1,767 | `0051a`, pair 1/2 |
| Climber routes | 1,734 | `0001a` |
| Drop routes | 1,865 | `0011a` |
| Modifiers | 3,862 | Ice `0021a`, dirt `0091a`, precharge `0251a` |
| Special types | 6,369 | Climber gem `0001a`, bomb `0007a`, lines `0008a`, cannon `0251a`, chameleon `1611a`, diagonals `2251a` |
| Fields 2 / 3 | 1,861 / 576 | Window `0005a`, growing window `1291a` |

Some serialized first appearances precede the foreshadowing schedule. The bundled `125_levelforeshadowingconfig` schedules stones at 3, statues 6, turtles 11, chains 13, recipe 15, ice 21, cannonballs 35, portals 51, crates 67, cannons 251, water 411 and colored crates 571. This is a presentation schedule, not proof of first exposure, reachable tutorial sequence, or chronological design. For example, stone values are already in 1b/c. Later authored variation combines previously introduced systems rather than requiring a new objective every level.

## Design lessons to test in our games

1. Give each goal a spatial problem: a route, covered region or restricted access point, not only an aggregate counter. Compare the turtle route in 11 and paired portal route in 51.
2. Preserve recognizable structure across tiers while changing target, cover and palette together; inspect all cell values, not just occupancy. Levels 1 and 606 show two different degrees of reuse.
3. Use a layered reveal or gate to make the same space serve successive purposes. Level 8's hidden footprints and coverings are an inspectable example; design and test the actual reveal rules in the target game.
4. Change a budget in response to the whole authored situation. Levels 8 and 11 increase both moves and workload; 411 changes mask size and budget. Playtest rather than assuming monotonic metrics imply difficulty.
5. Make a color constraint legible and ensure the relevant color can plausibly reach it. Level 2422 illustrates colored obstacles plus a low configured weight, but the static corpus does not prove spawn probability, fairness or solvability.

The reference corpus is a source of hypotheses and concrete layouts, not a substitute for playable prototypes, move-budget telemetry, accessibility checks or a verified simulator.
