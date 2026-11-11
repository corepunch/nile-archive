# Tropicats mechanics: evidence and limits

This is a static reference for Relic Rush and Christmas Market, based on the supplied Tropicats 2.5.11 assets, not a playthrough. The encrypted native executable was not run to recover gameplay. “Tutorial” below means the English strings in `reference/tropicats-analysis/bundled/english.json`; identifiers are included so they can be found there. “Serialized” means the tier JSON and enum defaults; “art” means the native assets and shader reconstruction documented in [the viewer artwork audit](../../tools/tropicats-viewer/ART.md). Neither a renderer nor a field name proves the complete runtime rule. Source files in `reference/` are ignored local inputs; [the atlas](../../tools/tropicats-viewer/README.md) requires that extraction and runs locally. See [board design](BOARD_DESIGN.md) for examples and corpus statistics.

## Pieces and matches

The tutorial `match3AndGoal.0` says to match at least three fruits. The table is a lookup of serialized enum values, not a promise that every value is reachable in every mode. The localized tutorial namespace includes retained variants, including `_170623` and old progression copy; it documents intended behavior but does not establish which tutorial is currently reachable. Where variants differ, both are identified.

### Piece colors (`gemColors`)

| ID | Name | Role or appearance |
| ---: | --- | --- |
| 0 | Undefined | No defined color. |
| 1 | Red | Strawberry. |
| 2 | Green | Starfruit. |
| 3 | Blue | Blueberry. |
| 4 | Yellow | Banana. |
| 5 | Purple | Grapes. |
| 6 | Orange | Apple. |
| 7 | Droppable | Goal piece; tutorial identifies turtles. |
| 8 | Random | Unspecified initial color; original striped marker. |
| 9 | Coins | Match color; `coins.0` says collected coins buy village buildings and decorations. |
| 10 | Cannonball | Obstacle that blocks line bursters. |
| 11 | Rainbow | Color Paw representation. |
| 12 | Climber | Climber character representation. |
| 13 | Treasure | Treasure representation. |
| 14 | Dirt | Dirt representation, distinct from dirt modifiers. |
| 15 | Colorless | `colorlessgems.0–1` calls these Mimic Flowers: adjacent matches transform them; three or more transformed flowers automatically match. |

Fruit appearances are grounded in native art. A Random marker does not specify its realized fruit. Coin scoring and payout details remain unverified.

### Piece types (`gemTypes`)

| ID | Name | Role / qualification |
| ---: | --- | --- |
| 0 | Undefined | No defined special type. |
| 1 / 2 | LineHorizontal / LineVertical | Two authored line axes. |
| 3 / 4 / 5 | Bomb / ActivatedBomb / ActivatedSuperBomb | Bomb and activated states; transitions are unknown. |
| 6 | ClimberGem | Feather / climber-associated gem. |
| 7 / 8 / 9 | StackedGemSmall / Medium / Big | Three fruit-stone sizes. |
| 10 | Cannon | Colored cannon. |
| 11 / 12 | Chameleon / ChameleonReduced | Standard / reduced variants; reduced palette is inferred. |
| 13 / 14 / 15 / 16 | DiagonalDownRight / DownLeft / UpLeft / UpRight | Four directed native sprites; runtime effect unverified. |
| 17 | DiagonalRandom | Enum exists; runtime selection unverified. |

### Modifiers and direction

| Modifier ID | Name | Meaning evidenced by assets / metadata |
| ---: | --- | --- |
| 0 | Undefined | No modifier. |
| 1 / 2 / 3 | IceHp1 / IceHp2 / IceHp3 | Three ice strengths. |
| 4 / 5 / 6 | DirtHp1 / DirtHp2 / DirtHp3 | Three dirt strengths. |
| 7 / 8 / 9 | PreChargedMuch / Medium / Little | Cannon initial charge 30 / 15 / 0, maximum 45. |

`gemDirection` IDs are 0 Undefined, 1 Left, 2 Up, 3 Right, 4 Down. The applicable piece and effect depend on context. All serialized campaign cannon placements have direction 0; the native cannon art has no confirmed facing setter.

| Element | Evidence for behavior | Open details |
| --- | --- | --- |
| Line burster | `linegem.0–1`: four fruits make one; it collects fruits in a line. Horizontal and vertical types and original meshes establish two axes. | Axis selection, propagation order, and interactions beyond cannonballs. |
| Bomb | `bombgem.0`: T/L shapes make bomb fruit. Bomb and two activated types exist. | Exact blast footprint and activation/chain timing. |
| Color Paw | `rainbowgem.0–1`: five fruits make one; it collects all fruits of the same color. | Selection and special-to-special behavior. |
| Stacked fruit stones | `stackedGems.0`: matching them releases many fruits; three size types are serialized. | Metadata constants `STACKED_GEM_SMALL/MEDIUM/BIG` are 3/5/10; their precise use and actual yield are unverified. |
| Feathers / climber | `climber_170623.0–1`: swap and match feathers with same-color fruit; enough matches make the bird fly to the top. Climber goal and route layer are separately serialized. | Exact movement per match and route semantics. |
| Diagonals | Four directed native sprites and enum types. | Creation, range and effect are not established by these assets alone. |
| Butterfly | `fish.0–1` says squares create butterflies and they remove obstacles; `fish_170623.0–1` also identifies squares and says they help beat the level. The event booster text specifies 2×2 matches and an increased number. | Target selection and precise removal rules. |
| Kitty Crackers | `kittycrackers.0–1`: match them to light them; they shoot through fruit and obstacles. | Mapping to a specific diagonal enum and exact path are unverified. |

`combinedSupergems.0` explicitly says swapping special fruits combines their powers. The pregame “Combo” booster separately starts with a line burster and a bomb (`pregameBoostBombLine.0`); neither string specifies a combination matrix or a particular combined blast. Do not assume blast sizes, gravity, cascade order, or solvability from this static data.

### Player tools

`hammer.0` describes tapping a fruit to remove it; retained `hammer_170623.0` instead says a tile. `star.0` describes a Star Hammer removing objects in the same row and column; `rainbow.0` describes a Color Hammer removing all same-colored fruits. These strings describe tools rather than automatically spawned specials, and do not establish every affected obstacle or the currently reachable tutorial variant. Pregame Color Paw and Double Butterfly boosters are also named in the source; availability, costs and live settings are not established.

## Obstacles, coverings and board surfaces

The independent arrays can overlap: `fields`, `tiles`, `stones`, `chains`, `crates`, colors, types and modifiers are not interchangeable. Art sorting places hidden statues below tiles, pieces above tiles, stones above pieces, chains/crates above them and windows above those. That rendering order does not itself determine hit order.

| Layer / value | Confirmed evidence and player-facing rule | Unresolved |
| --- | --- | --- |
| Stones 1–5 | Five native strength sprites; the values correspond to authored 1–5 HP art. | Exact damage rules for every special. |
| Cannonball (color 10) | `cannonballs.0`: blocks line-burster effect; match beside it or hit it with special fruit. | Damage and all interactions. |
| Chains 1–3 | Three strength sprites; `chains.0`: match strapped fruit to break vines. | Overlapping damage sequence. |
| Crates 1–3 | Three strength sprites; `crates.0`: match adjacent to smash them. Colored encoding is `color × 4 + HP`; `colorcrates.0` requires an adjacent match of the same color. | Which specials bypass color conditions. |
| Ice modifiers 1–3 | Three HP overlays; `ice.0`: match iced fruit to break the ice. | Damage and other effects at each strength. |
| Dirt modifiers 4–6 | Three HP overlays; `dirtAndTreasures.0–1`: match next to sand to remove it and free crabs. Color 14 can also encode dirt. | Precise relation between color, modifier and treasure progression. |
| Resistant blocker, stone IDs 6–8 | Native constants identify HP range 6–8; tutorial `resistant_blocker.0–3` describes opening eggs with special fruit, then adjacent matches to free platypuses. | Exact HP transitions and damage table; the source IDs are not a count of ordinary adjacent hits. |
| Color wheel, stone IDs 9–12 | Four values encode a 2×2 wheel's corner and occupancy, standard/reduced palette; `colorwheel.0–2` says adjacent same-color matches remove colors until cleared. Native art has 3–6 segments. | Reduced palette as weights ≥25 is a metadata-supported inference, not executed native logic; order and rotation are unknown. |
| Fields 0–3 | 0 inactive, 1 field, 2 window, 3 growing window; `bamboo.0` says adjacent matching stops bamboo growth. | Growth schedule and precise window/bridge rules. |
| Tiles 1–3 | Original 1/2 HP tile and watered-field sprites; metadata has `TILE_AMOUNT_FOR_WATERED = 3`. `water.0–1` says match over honey to spread it across all fields. | Flood propagation details and all tile interactions. |
| Hidden IDs | IDs group cells into statue footprints, beneath covering tile/stone art. `hiddenItems.0`: cut grass to find every statue. | Exact uncover and credit rules. |
| Clams | `shells.0` says items inside a clam respawn after being matched. | Serialization mapping and timing are not established here. |

Cannons are type 10, often colored. `cannons.0` instructs matching their color to explode them. Metadata gives precharge modifier IDs 7/8/9 = 30/15/0, with maximum 45. This establishes stored initial charge, not how much each match adds or exactly what the explosion does. Gauge travel in the viewer is fitted, not recovered native geometry. A chameleon (types 11/12) must be matched with every color; when not matched it moves (`chameleon.0–2`). Native shader mixes current and next colors, but the viewer's next color and reduced palette are illustrative; native order, movement, and timing remain unknown.

## Goals, routes and budgets

The campaign index names eight primary families: climber, droppable, hiddenitem, recipe, treasure, water, resistant_blocker and chameleon. The English objective labels identify droppables as turtles, hidden items as statues; `dropitem_turtle.0` says bring turtles down to the sea. Treasure tutorial uses crabs in sand, water uses honey, resistant blockers use eggs/platypuses. Recipe specifies collecting ingredients; inspect per-tier objectives and palette for its particular quantities. Explicit `data.objectives` can contain multiple typed counts; an empty array is not proof of no goal because layout-derived counters are also present in metadata. `data.moves` is the authored move budget, not a prediction of required moves.

`spawning` uses 0 none, 1 normal, 2 defined gem, 3 chameleon spawn. `data.gems` has color `amount` plus optional `period`, `maxAmount`, `usage`; `spawnRatios` and `spawnRatioDroppable` have piece/type, minimum, maximum and probability parameters. Values are configuration weights or controls; their exact normalization, constraints and sampling are unverified. `dropItems` and `climbers` carry route markers; their individual marker meanings and movement algorithms are unverified. Portal pairs are odd entrance/even exit: 1→2, 3→4, etc. Source boundary topology and native portal sprites support that interpretation; [level 51](http://127.0.0.1:8765/#level=51) shows four pairs. Do not infer a complete gravity or routing simulation from paired markers.

For evidence paths and enumerated rendering approximations see [atlas README](../../tools/tropicats-viewer/README.md), [art audit](../../tools/tropicats-viewer/ART.md), `reference/tropicats-analysis/metadata-symbols.txt`, and raw `levels/0001a` through `levels/2730c`. English tutorial keys can be searched directly in the bundled JSON. Source references describe the inspected build and not possible server overrides.
