# Applying Cradle of Rome to Relic Rush

Relic Rush uses the purchase-to-tile loop from the [Cradle of Rome 2 Windows economy](rome-2-economy.json).
Matches finance restorations, and every confirmed placement introduces
a higher-yield piece or a tool on subsequent expeditions. Tropicats remains the
companion reference for quest structure and story pacing.
[Tropicats adaptation](../tropicats-reference/ADAPTATION.md)

## What Relic Rush already does

| Rome pattern | Relic Rush implementation | Design consequence |
| --- | --- | --- |
| Progress on the board and gather city currency at the same time | Plaques, story-piece recovery and deliveries determine victory. Ordinary coin clears earn 4 Gold, fruit earns 1 Provisions, timber earns 2 Supplies and dressed stone earns 3. Story pieces earn recovery credit. On a winning claim, cascades and clears from specials can contribute resources. A hit absorbed by a cover or chain does not pay for the protected piece. | Give the player a choice of earning matches while the win condition is still open. |
| Quick finish pays | Each remaining move is worth 2 Gold, capped at 40. A first clear also awards 3 discovery stars. A replay can bank earnings and the move bonus without advancing the campaign or granting more stars. | With 1–20 moves left, one extra ordinary Supplies triple can trade 2 Gold for 3 Supplies before cascades. With more than 20 left, the next move costs no bonus Gold. Check which purse is scarce before changing the bonus. |
| Spend several resources to build visibly | Twenty restorations follow Rome's one-purchase, one-change ladder. The ten story restorations unlock at clears 1, 4, 7, 9, 13, 16, 19, 23, 26 and 29; they no longer block the next expedition; the other ten open between them and must be placed before the next story one. Players pay with banked earnings. Replays can cover a shortfall, and optional purchases respect the reserve. Discovery stars separately open land and shop stock. Placement is player-chosen. | Let good play leave more resources for optional spending. Keep the authored campaign progress independent of exceptional boards or discretionary purchases. |
| A construction changes the board | Eight restorations add a higher-yield chip and six introduce matchable bonus pieces. One bonus family appears on any given expedition, while all unlocked sockets keep their charge across boards. The Market's Shutter Gear is also the story piece on its debut board. | A new chip pays a currency the next building uses. Bonuses can collect resources from the pieces they clear and save moves. The Temple's emeralds earn 11 Coins each for island purchases after the finale. |

[Relic Rush economy design](../../games/relic-rush/docs/resource-expedition.md) · [Piece yields](../../games/relic-rush/lua/economy.lua) · [Claims and move bonus](../../games/relic-rush/lua/rules.lua) · [Construction reserve](../../games/relic-rush/lua/island.lua) · [Campaign palettes and milestones](../../games/relic-rush/lua/campaign.lua)

## Priorities

1. **Check that players recognize the payoff.** Watch for the first water,
   block and ration matches. Ask what each pays and whether the player
   can see how that helps with the next construction.
2. **Measure the cost of a shortfall.** At each unlock, compare the
   wallet before claim, matched income and move Gold with the price.
   Record which resource players need to replay for and how many wins
   it takes to continue.
3. **Compare the balance after the Workshop and Market.** Check whether
   higher Provisions and Supplies yields create useful surplus for
   optional buildings while Gold still rewards efficient play.
4. **Try a building-linked skill challenge only after that link reads.**
   Rome's Sawmill asks for a five-piece match and gives the building a visible
   upgrade. An optional workshop challenge could ask for a line of four on
   one of several eligible expeditions, with a one-time visible upgrade or
   reward. Let the task remain available across wins and retries. Check award
   persistence and duplicate claims if it is prototyped.

The Rome timer, escalating multipliers and recurring citizen income are
poor starting points for the current 30-board economy. Putting a timer on
board completion would change the campaign's pace. Larger line payouts
would amplify the same moves
that already create rockets and rainbow balls. The stronger experiment
changes which matches are appealing before changing the reward scale.
[Rome yield and progression evidence](ECONOMY_AND_CITY.md)

## Board briefs

| Relic Rush target | Rome lesson | Prototype and check |
| --- | --- | --- |
| **5–6, Quay and Shore Markers** | 5 teaches one chain away from the goal. 6 layers chains over the objectives with fixed resource pieces. | Use the pair to test a readable escalation from an exposed plaque cluster to a route that goes past a lock or crust. Give players a choice between an attainable water match and the direct objective route. Purple Supplies must still be accessible. Keep the marker objective and verify how protected cells pay out. |
| **9, The Supply Crate** | The Sawmill makes the new material relevant immediately after construction. | Try workshop blocks where purple is a free slot. The blue supply-pack story matches count toward recovery. Purple block matches count toward the wallet. Compare first-screen recognition and typical income before changing yield. |
| **14, Static** | 35 splits work and supply across two fields, each with its own targets. | Use the existing seam and the hex engine's actual refill to give each side a usable match area. Place a concentrated plaque patch per side, with one meaningful access decision. Check each side still has a straight three on a hex axis after clearing its blockers. Inspect multiple seeded openings and the last few plaques. |
| **A later plaque board with stacked access layers** | 10 isolates double plaques, 40 combines them with chains, and 51 introduces double chains. | Prototype the work using existing one-hit plaques under thicker covers or locks. Reserve a true two-hit plaque for a separate rules and art proposal if a board still needs that decision. A thicker cover delays access to the piece, whereas a durable floor target asks for repeat work at the same site. |

Use Rome's counts as examples of emphasis. Its beta averages about 100
active cells on square boards, while Relic Rush has at most 61 hex cells,
defined by its radius-four envelope. Draft the productive areas and escape
routes in hex coordinates. Set move budgets after testing access, refill, and
the finish-versus-earn choice. Read board structure and story objectives
together before picking a specific campaign edit.
[Rome layouts](BOARD_DESIGN.md) · [Relic Rush board progression](../../games/relic-rush/docs/board-progression.md) · [Hex match rules](../../games/relic-rush/docs/match4-rules.md)

## How to judge the first prototype

Use the existing well captures and wallet tests as baselines. When tuning
prices, follow the existing economy plan for at least 30 seeded campaign runs.
At the restoration milestones, record wallet before claim, earning clears
by family, unused moves and outstanding cost. Compare full runs
including players who finish quickly, make an optional purchase, or replay for
resources. The measure is the frequency and size of each shortfall and
whether the featured match is worth taking during normal objective play.

Observe people playing the featured boards at 480×900 and 390×844. Ask them
to identify what the new piece pays, what move clears the objective and what
they can afford on return. Use real clears and compare approaches across
seeds. The existing campaign smoke exercises the claim, placement and
story route with pre-met puzzle goals and cannot answer whether a board
presents a meaningful resource choice.
[Economy tuning plan](../../games/relic-rush/docs/resource-expedition.md#release-status-and-checks) · [Wallet tests](../../tests/lua/relic_wallet.lua) · [Capture and campaign test notes](../../games/relic-rush/README.md#verification)
