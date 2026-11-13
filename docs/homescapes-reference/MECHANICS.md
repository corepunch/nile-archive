# Homescapes match-3 mechanics and comparison

This comparison uses the Homescapes 9.2.601 bundle (build 10100292), Playrix's
player guides, the [Tropicats 2.5.11 reference](../tropicats-reference/MECHANICS.md),
and King's current guides for **Candy Crush Saga**. Soda Saga is identified
separately where it differs. Published rules can change independently of the
bundled files. No claim here depends on decoding the board artwork.

## Matching, specials and tools

| Player action | Homescapes | Tropicats | Candy Crush Saga |
| --- | --- | --- | --- |
| Three of a kind in a line | Regular clear. | Regular fruit clear. | Regular candy clear. |
| Four in a line | Rocket clears a row or column; tap to fire. | Line burster; authored horizontal and vertical variants. | Striped Candy; match it to clear its line. |
| L or T | Five or six pieces form a Bomb; tap for an area blast. | Bomb fruit; tutorial confirms the shape, not the precise blast. | Five pieces form a Wrapped Candy, which blasts its local area. |
| Five in a line | Rainbow Ball; swap with a piece to clear that type. | Color Paw clears fruit of one color. | Color Bomb; swap with a candy to clear that color. |
| Four in a square | Paper Plane; clears nearby tiles on takeoff and strikes a remote target, favoring goals or locks. | Butterfly removes an obstacle; target selection is unverified. | King now documents the 2×2 Fish; it can reach obstacles elsewhere on the board. |
| Combining specials | Rocket × Rocket crosses one row and column; Rocket × Bomb clears three of each; two Bombs widen the blast. Plane × Plane sends three planes; Plane × Rocket/Bomb carries the payload to a tile. Rainbow Ball × special converts the most common piece type to that special; two Balls clear the board and one obstacle layer. | Swapping specials combines their powers; the full pair table is unverified. | Striped × Wrapped clears several lines; two Color Bombs clear the board. Other pairs are documented selectively. |
| Player tools | Starting Rainbow Ball, Bomb + Rocket or Double Planes. In-level Hammer, Glove, Broom, Kettlebell and Fan cover single hits, free swaps, horizontal and vertical clears, and a reshuffle. | Starting Color Paw, Bomb + Line or Double Butterfly; tutorial describes single, cross and color hammers. | Color Bomb and Striped + Wrapped can start on the board; Lollipop Hammer and Free Switch act in-level. King also lists Lucky Candy, Coconut Wheel, Striped Brush, UFO and Party Booster. |

Sources: Playrix's [specials](https://playrix.helpshift.com/hc/en/14-homescapes/faq/16313-power-ups-and-how-to-use-them/),
[pairs](https://playrix.helpshift.com/hc/en/14-homescapes/faq/16363-what-power-up-combinations-are-available-in-the-game/)
and [boosters](https://playrix.helpshift.com/hc/en/14-homescapes/faq/16364-what-are-boosters-and-how-to-use-them/);
King's [Saga specials and pairs](https://candycrush.zendesk.com/hc/en-us/articles/211939685-Creating-and-combining-Special-Candies)
and [boosters](https://candycrush.zendesk.com/hc/en-us/articles/211320729-What-types-of-Boosters-are-available).
King [announced the Saga square match in 2025](https://community.king.com/en/candy-crush-saga/discussion/488193/let-s-dive-into-the-world-of-jelly-fish);
older Saga material describes fish as a booster. [Soda's special matches](https://candycrushsoda.zendesk.com/hc/en-us/articles/115000659009-What-are-special-matches)
also include the square Fish and a six-piece Coloring Candy that changes a
color rather than clearing it.

## What the board asks the player to do

| Decision | Homescapes | Tropicats | Candy Crush Saga |
| --- | --- | --- | --- |
| Free a captive piece | **Ice and Chains both exist.** The affected chip is held in place; match it in place or use a nearby power-up. A frozen or chained nonmatching object requires a power-up. Examples: `ICE`, `LOCK`. [Ice](https://playrix.helpshift.com/hc/en/14-homescapes/faq/1081-ice/), [Chains](https://playrix.helpshift.com/hc/en/14-homescapes/faq/1079-chains/) | Ice and vine chains; match the affected fruit. The files show three strengths for each. | Licorice Lock holds candy in place until matched. Honey can also hold candy; Sugar Coat travels with it and requires a direct match. |
| Open space from the edge | Boxes take adjacent matches or power-up hits. Blinds roll back; bricks, hazelnuts and filing cabinets have special-hit rules. [Boxes](https://playrix.helpshift.com/hc/en/14-homescapes/faq/1080-boxes/), [colored boxes](https://playrix.helpshift.com/hc/en/14-homescapes/faq/11953-colored-boxes/) | Stones, crates and colored crates gate space. Resistant eggs change the required hit as they open. | Frosting layers respond to neighboring matches or blasts; Licorice Shell needs specials. Licorice Swirls can move and stop blasts. |
| Work a floor or covering | Carpet spreads from a match touching existing carpet. Jelly around cherries has an adjacent-hit rule; clearing it serves a different goal from spreading carpet. `RUG`, `JELLY`, `CHERRY` occur in the bundle. [Carpet](https://playrix.helpshift.com/hc/en/14-homescapes/faq/1082-carpet/), [elements](https://playrix.helpshift.com/hc/en/14-homescapes/section/151-match-3-elements/) | Clear grass to reveal hidden statues; remove sand for crabs; spread honey by matching over it. | Clear jelly by matching directly over it. In Soda, frosting can conceal bears; its rules should not be attributed to Saga. |
| Contain a spreading threat | Oil can occupy more cells; clear pieces on it or hit it with power-ups. Suds and ivy also spread; soap and oil pitchers can create hazards. [Oil](https://playrix.helpshift.com/hc/en/14-homescapes/faq/1213-oil/), [elements](https://playrix.helpshift.com/hc/en/14-homescapes/section/151-match-3-elements/) | Match next to growing bamboo to stop it. Spreading honey is a positive objective, not the bamboo rule. | Chocolate spreads; Magic Mixer can place blockers near itself after turns. |
| Route an object or change how the board feeds | Donuts need marked bottom exits. Portals connect regions; some boards change gravity. Parrots rise under a condition; yarn rolls toward a basket when worked. Walls can stop movement while matches and blasts still pass. [Donuts](https://playrix.helpshift.com/hc/en/14-homescapes/faq/1085-donuts/), [walls](https://playrix.helpshift.com/hc/en/14-homescapes/faq/1083-walls-1774661309/), [elements](https://playrix.helpshift.com/hc/en/14-homescapes/section/151-match-3-elements/) | Turtles descend; birds climb with feather matches. Serialized portal pairs connect board regions. | Gummi Dragons drop to the bottom. A Licorice Fence blocks movement and special effects across an edge, unlike the Homescapes wall above. |
| Produce a goal, then collect it | Donut makers produce donuts; refrigerators release cans; suitcases yield hats; cameras produce photos. A generator may need a clear output lane. | Clams can replace matched contents; stacked fruit stones release fruit. | Magic Mixer can produce things the order needs. Destroying the source too early can prevent completion. |
| Manage color, timing or a staged gate | Jam jars fill, then require matching the jam color. Phones are vulnerable while ringing. Timers change color after matches. Keys open chests; Magic Hats gate collection behind a quota. | Chameleons need several colors and can move; cannons charge from matches; color wheels need neighboring matches of different colors. | Sugar Chests open with keys; Order Locks open when a separate order is filled. This is distinct from matching a candy inside Licorice. |

Candy Crush sources: [Saga blocker guide](https://candycrush.zendesk.com/hc/en-us/articles/360000754717-Which-Blockers-can-I-find-in-the-game),
[Magic Mixer](https://candycrush.zendesk.com/hc/en-us/articles/360002011778-What-does-the-Magic-Mixer-do),
[Licorice Fence](https://candycrush.zendesk.com/hc/en-us/articles/360010209738-What-is-the-Licorice-Fence),
[Order Locks](https://candycrush.zendesk.com/hc/en-us/articles/360013425077-What-are-the-Order-Locks),
[Saga goals](https://candycrush.zendesk.com/hc/en-us/articles/360000754897-Which-game-modes-will-I-find)
and [Soda blockers](https://candycrushsoda.zendesk.com/hc/en-us/articles/360001376929-How-do-the-different-blockers-work).

Other Homescapes examples in the [publisher's element index](https://playrix.helpshift.com/hc/en/14-homescapes/section/151-match-3-elements/)
add variations within these families: directional compasses and lanterns;
cat houses, ring boxes and puzzles that reveal objects; spreading or covering
foam, steam and paint; and staged devices such as plasma globes, gramophones,
tape measures, pool tables and arcade machines. These families describe what
changes the player's decision. Similar-looking props do not necessarily share
hit rules. The level guide also distinguishes regular progression from
[Challenge levels and events](https://playrix.helpshift.com/hc/en/14-homescapes/section/150-gameplay-guide/);
presence in a file does not place an element on the live campaign.

## Bundle inventory and limits

The extracted corpus has **6,184 XML definitions**: 514 under `base/`, including
500 `base/st/` files, and 5,670 under `packs/`. Counting distinct XML values
gives **130 model IDs** and **82 target types**. These totals include structural
markers, alternates, event/contest files and multiple IDs for one mechanic. For
example, `CARRY`, `CARRY_EXIT` and `CARRY_GEN` describe different parts of a
delivery setup, and `NORMAL`, `RANDOM_CHIP`, `NONE_CHIP`, and `BORN` do not
describe four obstacles. A target is also a separate field from a cell model.

The two lock rules are independently documented and common in the data:
`ICE` appears in **769 files**, `LOCK` in **994**, and `BOX` in **1,075**.
These are counts of files containing the ID, including variants. They are not
unlock levels, occurrence rates in player sessions, or measurements of
difficulty. See the [complete serialized ID index](BOARD_IDS.md) for an
example file and count for every model and target. The viewer can inspect
those paths without interpreting the rules. No mapping from every ID to a
published name has been verified; guide entries may also describe live
content absent from this bundle. Exact hit precedence, spawn probabilities,
timing, remote configurations and exhaustive per-element parity remain open.

## What to adapt in our hex games

Relic Rush and Christmas Market already have most of the useful decisions.
Start by tightening which hit each surface responds to and how the board
shows that rule. Use the [existing elements](../MATCH3_ELEMENTS.md) and
the [Relic Rush](../games/relic-rush/docs/board-progression.md) and
[Christmas Market](../games/christmas-market/docs/board-progression.md)
campaigns to pick representative boards before changing the engine.

| Player needs to… | Use what we already have | Adaptation to try |
| --- | --- | --- |
| Free a held piece | Chains and ice | Teach one lock first. Use a shared rule for matching the held piece or hitting it directly. Our thaw-enabled kinds can also clear adjacent ice; keep that difference only if it earns a distinct lesson. |
| Open a lane | Stone/snow and color crates/gifts | Teach the adjacent match with a plain blocker first. Introduce the colored version once the player has a reason to bring the right color to an edge. Show remaining layers on the tile. |
| Work the floor | Excavation and buried footprints | Pick a single floor task per lesson. Use the footprint to show where the player should spend moves. Try carpet-style spreading only if it creates a different layout problem. |
| Deliver something | Parcels, exits and tunnels | Make the destination visible before the first move. Add a tunnel once the player can already read a simple drop route. |
| Stop a threat | Growing vines/ribbon | Introduce later, after fixed blockers. One visible growth rule is enough to create pressure. |
| Reach a separated objective | Directional rays, bombs and the color clear | First check that board shape and special placement give players workable options. Try a targeted Plane-like effect only if a board still needs it; choose a match shape that reads on hexes. |

Keep generators, timers, staged color gates and additional blocker skins out
of the opening sequence until they earn their own player decision. Reuse the
rule patterns with our own silhouettes and state art. A useful art brief for
each element is to show where to hit it, how many hits remain, and what the
last hit will do.
