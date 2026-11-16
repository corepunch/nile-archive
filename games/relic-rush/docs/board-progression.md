# Relic Rush board progression

Every expedition asks the player to clear its blue plaques. Chains hold
pieces in place. A match or tool hit removes the chain, and a later hit
clears the plaque beneath it. A chain on plain stone can be left in place if
it is out of the way. Boards 2–10 and 13 show a story piece in one colour slot.
**Item recovered!** follows the first clear.

| Boards | Palette |
| --- | --- |
| 1 | Five regular kinds, including blue-tied timber |
| 2, 5, 8, 10, 13 | Four regular kinds and one story piece |
| 3, 4, 6, 7, 9 | Five regular kinds and one story piece |

Set `story_piece` and `goal_kind` in [the campaign data](../lua/campaign.lua)
to choose a story sprite and the colour slot it replaces. An optional
`omit_kind` removes one other colour from that board's starting pieces and
refills. Leave it unset for five regular kinds plus the story piece.

Ordinary boards use five resource pieces. The amber amphora on early six-kind
boards earns score. Confirming the Spring Well replaces blue timber with a water
bucket worth 3 Provisions from board 5. The Artisan Workshop replaces dressed
stone with cut blocks worth 5 Supplies from board 9. The Jungle Market
replaces red berries with ration jars worth 4 Provisions from board 10.
Each change persists wherever the board has that ordinary slot available.

Four recurring silhouettes give the player readable working areas: parallel
channels frame a narrow centre spine with bridges at both ends; a tapered cap
opens into a broad bowl; two substantial chambers sit on opposite sides of a
wide empty channel and connect at one end; and a compact court limits setup
space. Relic's two chambers join at the top, the market's at the bottom. On
the parallel-channel boards, mandatory terrain avoids the isolated central
spine so its narrowness does not create inaccessible cleanup. Blockers and
objectives move the emphasis within each family.

| Level | Board | Family | Blue plaques | Moves |
| ---: | --- | --- | ---: | ---: |
| 1 | First Light | Tapered bowl | 7 | 24 |
| 2 | The Lamp Lens | Tapered bowl | 9 | 29 |
| 3 | The Relay Cable | Two chambers | 10 | 32 |
| 4 | Under the Pump | Twin lanes | 11 | 35 |
| 5 | The Quay Marker | Tapered bowl | 10 | 35 |
| 6 | The Shore Marker | Two chambers | 11 | 37 |
| 7 | The Tool Roll | Two chambers | 12 | 40 |
| 8 | The Broken Cable | Compact court | 12 | 40 |
| 9 | The Supply Crate | Two chambers | 12 | 43 |
| 10 | The Shutter Gear | Twin lanes | 12 | 46 |
| 11 | The Long Terrace | Tapered bowl | 12 | 33 |
| 12 | Twelve Crates | Twin lanes | 12 | 36 |
| 13 | Names in the Stone | Twin lanes | 10 | 37 |
| 14 | Static | Two chambers | 13 | 38 |
| 15 | The Cracked Wall | Tapered bowl | 12 | 39 |
| 16 | Supper for Twelve | Twin lanes | 13 | 40 |
| 17 | The Torn Log | Tapered bowl | 13 | 42 |
| 18 | Lantern Steps | Tapered bowl | 14 | 40 |
| 19 | Under the Vines | Twin lanes | 12 | 45 |
| 20 | The Archivist's Key | Twin lanes | 9 | 46 |
| 21 | Tomas's Trail | Tapered bowl | 12 | 35 |
| 22 | The Alternate Landing | Twin lanes | 13 | 40 |
| 23 | The Star Road | Twin lanes | 12 | 40 |
| 24 | Noon Shadow | Tapered bowl | 12 | 41 |
| 25 | Smoke on the Water | Tapered bowl | 14 | 38 |
| 26 | The Jade Deep | Twin lanes | 10 | 43 |
| 27 | Six Sun Gates | Twin lanes | 12 | 45 |
| 28 | The Last Terrace | Tapered bowl | 13 | 42 |
| 29 | The Silent Temple | Twin lanes | 16 | 47 |
| 30 | The Warning Returns | Tapered bowl | 16 | 49 |

Straight matches of three or more clear all pieces in the run. Board holes
interrupt a match. Pickaxe hits a single cell, Dynamite hits a cell and its
immediate hex neighbors, and Sunburst hits all pieces of the chosen kind.
These are the campaign’s adaptations of Cradle of Rome’s Hammer, Bomb and
Star. Blue plaques stay in their authored positions until cleared.

Starting positions and targets are authored in `lua/campaign.lua`. Locks are
ranked by the terrain priorities; the ranks favor seams and bridge approaches. The board shows its targets in blue. Points
rank a clear. Pieces refill at
exposed tops and blocked-parent pockets, so a gap does not imply a sealed supply.
The final first clear plays Ines’s three-flash reply before the dialogue and reward. Seeded bot wins are not human balance;
playtesting should inspect openings and late cleanup.
