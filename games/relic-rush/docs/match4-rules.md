# Hex match-4 rules and varied boards

This supersedes the prototype's earlier straight-line match-3 rules.

## Matching

- Exchange two side-adjacent movable relics, by swiping or tapping both.
- A connected component of **four or more identical relics** matches. Connections use the six shared hex edges; a line, bend, branch or diamond counts. Merely touching at a corner does not.
- Three identical relics do not clear. A move that creates no match returns without spending a move.
- Four clears normally; five leaves a directional ray; six or more leaves a bomb, with a prism for a straight run of six. A ray follows the longest straight axis of the matched component.
- Existing specials, combos, fire thawing, ice layers, chains, excavation and tools retain their respective effects.
- A ready group is checked on the idle board before hints/input and after every completed fall. All cascade waves finish before victory/failure is checked. Automatic waves do not spend additional moves.

The old detector considered only straight runs. Visually connected bent/compact groups were therefore ignored. Detection now walks the entire six-neighbor component. In addition, the idle animation state actively checks ready groups rather than relying solely on the previous swap/collapse transition.

## Ten board masks

| Level | Shape | Active cells |
| --- | --- | ---: |
| 1 | Hexagon | 61 |
| 2 | Crescent | 54 |
| 3 | Diamond | 43 |
| 4 | Butterfly | 45 |
| 5 | Hourglass | 49 |
| 6 | Lotus | 43 |
| 7 | Ring | 54 |
| 8 | Twin courts | 55 |
| 9 | Crossroads | 55 |
| 10 | Sun crown | 53 |

![All ten actual SDL boards](screenshots/level-shapes-overview.jpg)

Each mask is a distinct connected graph within the common axial-coordinate envelope. Missing cells are excluded from rendering, matching, tile selection, swapping, booster targeting, obstacle placement and refill. Matching never crosses a gap. Gravity refills each contiguous column segment independently; it does not pull tiles across a hole or an immovable blocker. Directional special attacks may travel across gaps but only affect actual cells. The silhouette follows the active cells rather than a permanently painted large hexagonal frame.

## Idol

`art/idol-hex.png` is a new original transparent six-sided gold idol, generated with the built-in imagegen tool. `tools/prepare_assets.py` exports it as `data/relics/0.png`, overriding only the former square idol. The other five sprite types are unchanged.

## Validation

- 1,000 seeded startup boards across all ten masks: no pre-existing four-plus component and at least one legal opening move.
- Hand-authored triples, bent fours in all six rotations, compact diamonds, five/six specials and hole-separated groups.
- Mask connectivity/uniqueness, absence of tiles/blockers in holes, gravity segmented at holes and locks, and invalid targeting of missing cells.
- Actual SDL update-loop regression: a three-cell group remains; adding its fourth cell triggers automatically without spending a move; after refill no ready group remains. A ready cascade discovered after falling also resolves automatically.
- Scaled mouse/touch regressions and hole-selection checks.
- 298/300 deterministic greedy campaign trials win without tools. This is a diagnostic, not a human difficulty rating or guarantee for every play strategy.

## Reference research

- [King's GDC Europe 2016 presentation: Level Design Saga, Jeremy Kang](https://media.gdcvault.com/gdceurope2016/presentations/KANG_Jeremy_LevelDesignSaga.pdf): level concept, layout, balancing and testing as separate design steps; board layouts support different gameplay situations.
- [Red Blob Games: Hexagonal Grids](https://www.redblobgames.com/grids/hexagons/): axial/cube coordinates, six edge neighbors, connected traversal and shaped grid regions. Used as a geometry/reference explanation, not copied game implementation.
- [Match 4 – Hex, developer page](https://dimcairion.itch.io/match-4-hex): an independent hex swap/match-4 prototype demonstrating the genre. No code or assets were imported.
- [Candy Crush official modes guide](https://candycrush.zendesk.com/hc/en-us/articles/360000754897-Which-game-modes-will-I-find): varying objectives and mixed modes complement level-layout variety.

The four-connected minimum is Relic Rush's design choice requested for this prototype; a hexagonal grid does not inherently mandate one universal matching threshold. Candy Crush is a reference for level variation and presentation, not the source of these custom matching rules.
