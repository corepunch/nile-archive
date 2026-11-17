# Relic Rush board progression

Every expedition asks the player to clear its blue plaques. Chains hold
pieces in place. A match or tool hit removes a chain (crossed double chains
take two), and a later hit
clears the plaque beneath it. A chain on plain stone can be left in place if
it is out of the way. Board 13 shows a story piece in one colour slot. Chapter 1 story scenes follow confirmed island work.

The 100 boards are authored, one file each, in [../levels](../levels), on Cradle
of Rome's feature schedule: chains from 5, ice from 7, two areas from 9,
double tablets from 10, carved stones from 15 and double chains from 51.
[docs/LEVEL_DESIGN.md](../../../docs/LEVEL_DESIGN.md) is the guide;
`make level-sheets` draws every board on
[one sheet](../../../docs/review/level-sheets/relic-rush.png). Move budgets are
fitted by `python3 tools/tune_moves.py relic-rush` and listed with each
board's tier in [level-moves.md](level-moves.md).

Every board spawns five kinds, as Cradle of Rome does on all 100 of its
levels. With six, lines of three were so rare on the 108-cell boards that the
reference bot needed about 200 moves a board. Refills are damped from the
second cascade wave (`refill_damping=2`), so one move rarely clears a board.

The green apple's slot (kind 2, 1 Food, never upgraded) is the special slot:
the bonus gem, a story item or a score piece takes it, and the bonus moves to
the red slot when a story item holds it (`SPECIAL_KIND` in
[economy.lua](../lua/economy.lua)).

| Boards | Palette |
| --- | --- |
| 1–12, 14–100 | Five kinds, the apple slot often a bonus or score piece |
| 13 | Four resource or score kinds and one story piece |

Set `story_piece` and `goal_kind` in [the campaign data](../lua/campaign.lua)
to choose a story sprite and the colour slot it replaces. `omit_kind` is
rejected: no board drops a colour.
The [campaign atlas](asset-catalogue.md#campaign-piece-atlas) supplies the art
for these slots and for the pieces introduced by restorations.

Green apples earn 1 Food each.
Confirming the Spring Well replaces blue timber with a water
bucket worth 3 Food from board 5. The Artisan Workshop replaces dressed
stone with cut blocks worth 5 Supplies from board 8. The optional Jungle Market replaces red berries with ration jars worth 4 Food from board 11.
From board 14 the Courtyard improves Coins, from board 17 the Lodge replaces
ration jars with grain, and from board 20 the Archive improves Supplies.
The Fountain upgrades the blue water slot from board 27 and the Temple
upgrades the Coins slot on board 30. These resources persist wherever their slot
is available. A confirmed restoration can also add a bonus piece family.

Leaves appear on boards 3, 9, 12, 18 and 24. Flowers appear on boards 4, 6,
7, 15, 21 and 27. They award score only and use the apple slot when a bonus leaves it available. Board 6 authors flowers in the red slot.

### Bonus pieces

| Slot | Level I | Level II |
| --- | --- | --- |
| Blast | **Hammer** from the Expedition camp on board 2 hits one chosen cell. | **Dynamite** from the Trapper's cabin on board 8 also hits the six neighbors. |
| Sweep | **Shield** from the Stone amphitheatre on board 14 hits a chosen row. | **Lightning** from the Valley lighthouse on board 20 hits that row and adds strikes elsewhere, up to twenty cells total. |
| Star | **Star** from the Clock tower on board 12 hits every piece of the chosen kind. | **Star II** from the Star observatory on board 24 hits through one layer of chain or ice and clears the piece if exposed. |
| Recharge | **Plus** from the Cartographer's house on board 23 gives a quarter charge to each other unlocked bonus. | **Plus II** from the Relic museum on board 28 gives half. |

Four large sockets stay in the same positions in one row throughout the
campaign. An upgrade takes over its slot and uses the charge already stored
there, including when a parked expedition resumes. A II badge identifies the
upgraded bonus. Hammer, Dynamite, Shield, Lightning and both Stars start by
choosing a cell. Lightning previews its full strike pattern before applying it.
Plus activates from its socket and keeps its use when the other unlocked
meters are already full.

The debut board features its newly unlocked or upgraded gem. Later boards
draw one eligible slot by seed and use its current gem. The bonus takes an
existing slot so the expedition keeps five kinds. Dynamite uses the apple slot on board 8.

Six matched gems fill one use. Each gem flies into its own socket and adds
a sixth of a meter. Reduce Motion fills it immediately. Using a bonus costs
no moves. Old saves combine each pair of separate meters into one slot at
their original charge fractions, capped at one use.

The Workshop cuts the replacement blocks, and the Quay Steps repair after expedition 10 opens the tide-room approach.
