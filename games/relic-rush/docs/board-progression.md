# Relic Rush board progression

Every expedition asks the player to clear its blue plaques. Chains hold
pieces in place. A match or tool hit removes a chain (crossed double chains
take two), and a later hit
clears the plaque beneath it. A chain on plain stone can be left in place if
it is out of the way. Boards 2–10 and 13 show a story piece in one colour slot.
**Item recovered!** follows the first clear.

Plaque placement, chains, double chains, green double tablets and move
budgets are not authored per board. They are fitted to the difficulty curve
in [lua/difficulty.lua](../lua/difficulty.lua) by
`python3 games/relic-rush/tools/tune_levels.py`, which writes
`lua/level_tuning.lua` and the review table in [level-tuning.md](level-tuning.md).
To change difficulty, edit the curve's tiers or rhythm and rerun the tuner.
The layout, the plaque count and story slots stay authored here.

Placement is the strongest lever on lane and chamber boards: the same twelve
plaques on The Jade Deep range from a 25% to a 100% bare bot win rate by
position. On tapered bowls it barely matters (83–100% anywhere on The Cracked
Wall), so bowls rely on blockers and a tighter budget. The tuner tries the
authored patch moved up to two cells and a compact patch grown around every
playable cell, and keeps the hardest whose bare win rate is at least ten
points above the target, leaving the blockers room to work. Boards with an
authored opening keep their authored plaques.

Every board spawns all six kinds. With five on a hex board, where each cell
sits on three lines, refills chained so often that one move could clear a board.
Refills are also damped from the second cascade wave (`refill_damping=2`).

| Boards | Palette |
| --- | --- |
| 1, 11, 12, 14–30 | Six resource kinds, some of them score pieces |
| 2–10, 13 | Five resource or score kinds and one story piece |

Set `story_piece` and `goal_kind` in [the campaign data](../lua/campaign.lua)
to choose a story sprite and the colour slot it replaces. `omit_kind` is
rejected: no board drops a colour.
The [campaign atlas](asset-catalogue.md#campaign-piece-atlas) supplies the art
for these slots and for the pieces introduced by restorations.

Green apples earn 1 Food each.
Confirming the Spring Well replaces blue timber with a water
bucket worth 3 Food from board 5. The Artisan Workshop replaces dressed
stone with cut blocks worth 5 Supplies from board 8. The relay pliers occupy
the orange slot on that board. The Jungle Market
replaces red berries with ration jars worth 4 Food from board 10.
From board 14 the Courtyard improves Coins, from board 17 the Lodge replaces
ration jars with grain, and from board 20 the Archive improves Supplies.
The Fountain upgrades the blue water slot from board 27 and the Temple
upgrades the Coins slot on board 30. These resources persist wherever their slot
is available. A confirmed restoration can also add a bonus piece family.

Leaves appear on boards 3, 6, 9, 12, 18 and 24. Flowers appear on boards 4, 6,
7, 15, 21 and 27. They award score only. Earlier introductions use the score
slot. Board 6 also uses the berries' slot for the flower and gets Food from
the Well. Later appearances use the apple slot while rations or grain and
water still pay Food. A bonus may take the earlier score slot.

Boards 5 and 9 use authored openings with seeded refills. The first idle hint
matches three buckets on the quay approach or three cut blocks by the market
steps. Each match clears three plaques and earns 9 Food or 15 Supplies
after the relevant restoration. The bonus uses a different slot from these
featured resource matches.

### Bonus pieces

| Confirmed restoration | Debut | Bonus and effect |
| --- | ---: | --- |
| Expedition Camp | 2 | Dynamite hits the chosen cell and its six neighbors. |
| Trapper's cabin | 8 | Hammer hits one chosen cell. |
| Stone amphitheatre | 14 | Shield hits the row through the chosen cell, along the hex board's row axis. |
| Valley lighthouse | 20 | Lightning immediately strikes up to 20 distinct random cells. |
| Cartographer's house | 23 | Plus adds half a use to every other unlocked bonus. It keeps its use when they are all full. |
| Star Observatory | 24 | Star hits every piece of the chosen kind. |

These six tools cover a precision hit, a local blast, a row clear, a random
strike, a piece-type clear, and a charge refill. The sockets keep their
positions in restoration order from the first expedition, in one compact
row below the centered board.

The first expedition after a bonus restoration features its new piece.
Later boards draw a family from the eligible restorations using the board
seed. The bonus takes an existing slot so the expedition keeps six kinds.
The cabin's Hammer uses the red slot on board 8, where the relay pliers
occupy the orange slot. Expedition 10 introduces the market's ration jars
and gives the orange slot to the Shutter Gear quest piece.
Each matched bonus piece flies to its own socket and contributes three points.
The gold fill rises as the gems land, or immediately with Reduce Motion on.
The socket holds 18 points and one use. Matches beyond that cap cannot bank a
second use. Both partial and full meters are saved across expeditions, and using
a bonus empties its socket without spending a move. Confirming a restoration
unlocks its visible socket for charging.

The market hoist makes the tide-room approach possible. The Shutter Gear
counts toward the expedition 10 recovery objective, and the first clear
still awards the gear. The Tide Chart is recovered on expedition 4.

Four recurring silhouettes give the player readable working areas: parallel
channels frame a narrow centre spine with bridges at both ends; a tapered cap
opens into a broad bowl; two substantial chambers sit on opposite sides of a
wide empty channel and connect at one end; and a compact court limits setup
space. Relic's two chambers join at the top, the market's at the bottom. On
the parallel-channel boards, mandatory terrain avoids the isolated central
spine so its narrowness does not create inaccessible cleanup. Blockers and
objectives move the emphasis within each family. Chains and move budgets per
board are in [level-tuning.md](level-tuning.md).

| Level | Board | Family | Blue plaques |
| ---: | --- | --- | ---: |
| 1 | First Light | Tapered bowl | 7 |
| 2 | The Lamp Lens | Tapered bowl | 9 |
| 3 | The Relay Cable | Two chambers | 10 |
| 4 | Under the Pump | Twin lanes | 11 |
| 5 | The Quay Marker | Tapered bowl | 10 |
| 6 | The Shore Marker | Two chambers | 11 |
| 7 | The Tool Roll | Two chambers | 12 |
| 8 | The Relay Pliers | Compact court | 12 |
| 9 | The Supply Crate | Two chambers | 12 |
| 10 | The Shutter Gear | Twin lanes | 12 |
| 11 | The Long Terrace | Tapered bowl | 12 |
| 12 | Twelve Crates | Twin lanes | 12 |
| 13 | Names in the Stone | Twin lanes | 10 |
| 14 | Static | Two chambers | 13 |
| 15 | The Cracked Wall | Tapered bowl | 12 |
| 16 | Supper for Twelve | Twin lanes | 13 |
| 17 | The Torn Log | Tapered bowl | 13 |
| 18 | Lantern Steps | Tapered bowl | 14 |
| 19 | Under the Vines | Twin lanes | 12 |
| 20 | The Archivist's Key | Twin lanes | 9 |
| 21 | Tomas's Trail | Tapered bowl | 12 |
| 22 | The Alternate Landing | Twin lanes | 13 |
| 23 | The Star Road | Twin lanes | 12 |
| 24 | Noon Shadow | Tapered bowl | 12 |
| 25 | Smoke on the Water | Tapered bowl | 14 |
| 26 | The Jade Deep | Twin lanes | 10 |
| 27 | Six Sun Gates | Twin lanes | 12 |
| 28 | The Last Terrace | Tapered bowl | 13 |
| 29 | The Silent Temple | Twin lanes | 16 |
| 30 | The Warning Returns | Tapered bowl | 16 |

Straight matches of three or more clear all pieces in the run. Board holes
interrupt a match. Blue plaques stay in their authored positions until cleared.

Starting positions and targets are authored in `lua/campaign.lua`. Locks are
ranked by the terrain priorities; the ranks favor seams and bridge approaches. The board shows its targets in blue. Points
rank a clear. Pieces refill at
exposed tops and blocked-parent pockets, so a gap does not imply a sealed supply.
The final first clear plays Ines’s three-flash reply before the dialogue and reward. Seeded bot wins are not human balance;
playtesting should inspect openings and late cleanup.
