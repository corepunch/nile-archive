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

Every board from 1 to 100 uses five piece kinds. Swapping neighbours must
form a straight line of four or more. The same minimum applies after a fall.
Each new deal checks every opening exchange through its entire cascade and
redeals if any exchange clears all the plaques. Refill damping begins on the second wave (`refill_damping=2`).

## Match-four difficulty

Each blue tablet sits on two axes with space for four pieces. A gate must have a
four-piece line on its fed side so the player can open it before filling the
chamber below. Use stepped edges, deep cutouts or interior gaps to give each
expedition a recognizable silhouette at phone size. Temple Steps has deep cuts
on opposite sides of its diagonal stairway, with seven tablets on the middle
landing. Sunken Courtyard has a seven-cell opening, with seven tablets along
the lower rim. Board 5 introduces a chain that holds back a tablet, and board 7
places ice above an empty tablet. Later boards combine split chambers, layered
tablets and double locks.

Keep more refillable cells than waiting cells in the opening position so
players can rearrange pieces while a gate holds. The match-four audit checked
every board and found two openings where most cells waited for a chain.
Vault Door now feeds its outer lanes from the start. Twin Terraces now feeds
both lower paths from the start, and each mandatory chain sits at the
intersection of all three match axes. Each Twin Terraces chain has ten
possible four-cell runs with room to swap in a piece, up from two.

| Board | Refillable cells at the start | Cells waiting for chains |
| --- | ---: | ---: |
| 5 · Vault Door | 35 → 73 | 38 → 1 |
| 9 · Twin Terraces | 29 → 80 | 46 → 0 |

Each board was played on 40 deals without tools to set its move limit. Levels
1–4 have median clears of 6, 7, 9 and 6 moves respectively. Across boards in
each later tier, the median of those board medians was 12 for easy, 16 for
normal, 23 for hard and 26.5 for bosses. All deals cleared within the 250-move
calibration ceiling. The fitted limits range from 11 to 56.

Before the early-board revisions to levels 2, 3, 5 and 9, a separate check used
ten other deals per board (runs 301–310 of the same seed sequence), with the
scheduled restoration pieces, no tools and the live move limits. The bot won
766 of 1,000 games, up from 131 on the same deals with the pre-rebalance
layouts and budgets. It won at least once on each board. Trying every legal
first exchange on the first of those ten deals per board found zero one-move wins.

Each comparison shows the previous layout on the left and the current one on the right.

| Board | 480 × 900 | 390 × 844 |
| --- | --- | --- |
| 2 · Temple Steps | [Opening deal](screenshots/review/tutorial-shapes/temple-steps-480.jpg) | [Opening deal](screenshots/review/tutorial-shapes/temple-steps-390.jpg) |
| 3 · Sunken Courtyard | [Opening deal](screenshots/review/tutorial-shapes/sunken-courtyard-480.jpg) | [Opening deal](screenshots/review/tutorial-shapes/sunken-courtyard-390.jpg) |
| 5 · Vault Door | [Opening deal](screenshots/review/match-four-gates/vault-door-480.jpg) | [Opening deal](screenshots/review/match-four-gates/vault-door-390.jpg) |
| 9 · Twin Terraces | [Opening deal](screenshots/review/match-four-gates/twin-terraces-480.jpg) | [Opening deal](screenshots/review/match-four-gates/twin-terraces-390.jpg) |

## Piece progression

Each expedition has five kinds. The starting pieces are two coins, a leaf, a flower and an amphora. Buying a campaign building introduces one resource or bonus piece. Board 13 reserves one slot for the story note. The [building table](../README.md#buildings) lists all twenty purchases, their prices and the piece each introduces.

### Bonus pieces

Four sockets hold one charge each. A new tool takes over its socket and replaces the old collectible on the board, including when returning to a parked expedition. Matching six ordinary bonus pieces fills one charge. The painted piece appears from the bottom as the charge arrives. After using the tool its recessed silhouette is visible again. Each board can feature one active bonus family.

- Hunter's Hut — Unlocks Hammer. Hit one cell.
- Village — Unlocks Bomb. Hit a cell and its six neighbors.
- Thermae — Unlocks Shield. Hit the row through a chosen cell.
- Curia Octavia — Unlocks Hourglass. Add five moves.
- House of the Vestals — Unlocks Lightning. Strike up to fifteen random cells.
- Lighthouse — Unlocks Plus. Choose a resource piece for 100 resources or another bonus to add a quarter charge.
- Mausoleum of Augustus — Unlocks Mixer. Shuffle the pieces.
- Forum — Unlocks Star. Clear all pieces of a chosen kind.
