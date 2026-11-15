# Relic Rush board progression

The expedition uses relic, blocker, sand sweeping, spreading ground and delivery goals. Boards
1–7, 9 and 10 bury their quest object under sand, well mud or tide-room silt.
Timber takes seven cells across two staggered rows and the cable takes six in a zigzag.
Each buried find shows a black silhouette over its covered cells until a match reveals the painted find.
Uncovering all buried cells is a goal (shown with the object's own icon), a crew member speaks at
the halfway point, and the first clear shows the whole object on the emptied
board before its **Item recovered!** card. Board 8 sweeps sand from the stonework and shows the broken cable on its recovered-item card. Boards 18
and 28 provide lighter intervals in the later chapters.

Four recurring silhouettes give the player readable working areas: parallel
channels frame a narrow centre spine with bridges at both ends; a tapered cap
opens into a broad bowl; two substantial chambers sit on opposite sides of a
wide empty channel and connect at one end; and a compact court limits setup
space. Relic's two chambers join at the top, the market's at the bottom. On
the parallel-channel boards, mandatory terrain avoids the isolated central
spine so its narrowness does not create inaccessible cleanup. Blockers and
objectives move the emphasis within each family.

| Level | Board | Family | Lesson and focus | Goals | Moves |
| ---: | --- | --- | --- | --- | ---: |
| 1 | First Light | Tapered bowl | Match on the sand to uncover the timber. | find | 24 |
| 2 | The Lamp Lens | Tapered bowl | Match 4 for a rocket. Uncover the lens. | find | 29 |
| 3 | The Buried Cable | Two chambers | Break the stone. Uncover the cable. (stone) | blockers, find | 32 |
| 4 | Under the Pump | Twin lanes | Break the chains. Uncover the chart. | blockers, find | 35 |
| 5 | The Quay Marker | Tapered bowl | Match on cleared stone to sweep more sand. (sand) | sand, find | 35 |
| 6 | The Shore Marker | Two chambers | Match the piece under the salt crust to break it. | blockers, find | 37 |
| 7 | The Tool Roll | Two chambers | Break the carved stone. Uncover the tools. (stone) | blockers, find | 40 |
| 8 | The Broken Cable | Compact court | Match 5 for a rainbow ball. (sand) | sand, relics | 40 |
| 9 | The Supply Crate | Two chambers | Clear the ropes and salt crust. Uncover the crate. | blockers, find | 43 |
| 10 | The Shutter Crank | Twin lanes | Sweep the sand. Uncover the crank. (sand) | sand, blockers, find | 46 |
| 11 | The Long Terrace | Tapered bowl | Collect the relics. | relics | 33 |
| 12 | Twelve Crates | Twin lanes | Free relics caught in the vines. | blockers, relics | 36 |
| 13 | Names in the Stone | Twin lanes | Match on the sand to uncover the note. | sand, blockers, buried note | 37 |
| 14 | Static | Two chambers | Work around the broken seam. | blockers, relics | 38 |
| 15 | The Frost Line | Tapered bowl | Clear the stone to open the board. (stone) | blockers, relics | 39 |
| 16 | Supper for Twelve | Twin lanes | Hit the salt crust with matches or power-ups. | blockers, relics | 40 |
| 17 | The Torn Log | Tapered bowl | Thick salt crust takes two hits. | blockers, relics | 42 |
| 18 | Lantern Steps | Tapered bowl | Sweep the sand across the terrace. (sand) | sand | 40 |
| 19 | Under the Vines | Twin lanes | Work beneath the locks. | blockers, relics | 45 |
| 20 | The Archivist's Key | Twin lanes | Clear the river silt before it spreads. (river silt) | river silt, blockers | 46 |
| 21 | Tomas's Trail | Tapered bowl | Clear below the tablet to deliver it. (delivery) | delivery | 35 |
| 22 | The Frozen Stair | Twin lanes | Thaw the frozen approach. (stone, sand) | sand, blockers | 40 |
| 23 | The Star Road | Twin lanes | Choose a colour for the rainbow ball. | relics, blockers | 40 |
| 24 | Noon Shadow | Tapered bowl | Sweep the sand across the shaded floor. (sand) | sand, relics | 41 |
| 25 | Smoke on the Water | Tapered bowl | Work through the locks. | blockers, relics | 38 |
| 26 | The Jade Deep | Twin lanes | Clear the mud before it spreads. | well mud, blockers | 43 |
| 27 | Six Sun Gates | Twin lanes | Clear the scattered locks. | blockers, relics | 45 |
| 28 | The Last Terrace | Tapered bowl | Sweep the sand across the terrace. (sand) | sand | 42 |
| 29 | The Silent Temple | Twin lanes | Break through the temple floor. (stone) | blockers, relics | 47 |
| 30 | The Warning Returns | Tapered bowl | Clear below the signal plate to deliver it. (delivery) | delivery, blockers | 49 |

Stones are solid cells. A neighbouring match or direct power-up hit breaks one stone.
A cover takes one hit when its own piece is matched or struck by a power-up.
Salt crust is the default cover, with barnacles at the quay, rubble at the wall
and ice on board 22. A match touching cleared stone sweeps sand from the other matched cells.
River silt on board 20 and well mud on 26 clear under a match and spread after
a move that clears none. A tablet falls into its marked exit and
cannot be matched or destroyed. Ordinary match lines stop at board holes, but
rays pass over them.

Starting positions and targets are authored in `lua/campaign.lua`. Locks are
ranked by the terrain priorities; solid cells and other reserved positions are
excluded from ranked placement. As in Homescapes' story levels, a board has at
most one spreading ground layer. A level is won by its
own goals only. As in Homescapes, each level
names one to three (at most two up to level 12) and score is never one: points
only rank a clear. "Blockers" counts locks, covers and stone together. Pieces refill at
exposed tops and blocked-parent pockets, so a gap does not imply a sealed supply.
The final first clear plays Ines’s three-flash reply before the dialogue and reward. Seeded bot wins are not human balance;
playtesting should inspect openings, late cleanup and delivery paths.

Starting coverings are determined by the terrain priorities in `lua/campaign.lua`.
