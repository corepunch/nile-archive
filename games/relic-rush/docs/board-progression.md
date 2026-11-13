# Relic Rush board progression

The expedition uses relic, blocker, moss, lamp oil and delivery goals. After
each first clear, the characters find the quest object in the story. Boards 18
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
| 1 | First Light | Tapered bowl | Match 3 in a row. | relics | 24 |
| 2 | The Lamp Lens | Tapered bowl | Match 4 for a sun ray. | relics | 29 |
| 3 | The Buried Cable | Two chambers | Match beside the stone to break it. | blockers, relics | 32 |
| 4 | Under the Pump | Twin lanes | Match to break chains. | blockers, relics | 35 |
| 5 | The Quay Marker | Tapered bowl | Match on the moss to spread it. (carpet) | moss | 35 |
| 6 | The Shore Marker | Two chambers | Match to break ice. | blockers, relics | 37 |
| 7 | The Tool Roll | Two chambers | Some stones need two hits. | blockers, relics | 40 |
| 8 | The Broken Cable | Compact court | Match 5 for a prism. (carpet) | moss, relics | 40 |
| 9 | The Supply Crate | Two chambers | Match the seal's colour beside it. | blockers, relics | 43 |
| 10 | The Shutter Crank | Twin lanes | Spread the moss over the centre. (carpet) | moss, blockers | 46 |
| 11 | The Long Terrace | Tapered bowl | Pieces travel between paired conduits. (conduit) | relics | 33 |
| 12 | Twelve Crates | Twin lanes | Free chained relics. (colour seal) | blockers, relics | 36 |
| 13 | Names in the Stone | Twin lanes | Aim rays along the stone. (carpet) | moss, blockers | 37 |
| 14 | Static | Two chambers | Work around the broken seam. (colour seal) | blockers, relics | 38 |
| 15 | The Frost Line | Tapered bowl | Break the three-layer stone. (stone) | blockers, relics | 39 |
| 16 | Supper for Twelve | Twin lanes | Stop the vines before they spread. (vines) | blockers, relics | 40 |
| 17 | The Torn Log | Tapered bowl | Some coloured seals take two hits. (colour seal) | blockers, relics | 42 |
| 18 | Lantern Steps | Tapered bowl | Spread the moss across the terrace. (carpet) | moss | 40 |
| 19 | Under the Vines | Twin lanes | Work beneath the locks. (vines) | blockers, relics | 45 |
| 20 | The Archivist's Key | Twin lanes | Mop up the lamp oil before it spreads. (oil) | lamp oil, blockers | 46 |
| 21 | Tomas's Trail | Tapered bowl | Clear below the tablet to deliver it. (delivery) | delivery | 35 |
| 22 | The Frozen Stair | Twin lanes | Thaw the frozen approach. (carpet) | moss, blockers | 40 |
| 23 | The Star Road | Twin lanes | Choose a colour for the prism. (colour seal) | relics, blockers | 40 |
| 24 | Noon Shadow | Tapered bowl | Spread the moss across the shadow. (carpet) | moss, relics | 41 |
| 25 | Smoke on the Water | Tapered bowl | Work through the locks. (vines) | blockers, relics | 38 |
| 26 | The Jade Deep | Twin lanes | Clear the oil and its cans. (oil) | lamp oil, blockers | 43 |
| 27 | Six Sun Gates | Twin lanes | Clear the scattered locks. (colour seal) | blockers, relics | 45 |
| 28 | The Last Terrace | Tapered bowl | Spread the moss across the terrace. (carpet) | moss | 42 |
| 29 | The Silent Temple | Twin lanes | Break through the temple floor. (stone) | blockers, relics | 47 |
| 30 | The Warning Returns | Tapered bowl | Send the tablet through the conduit. (conduit, delivery) | delivery, blockers | 49 |

Stones and seals are solid cells: matches beside them or direct special hits
remove one layer per wave. Seals require their own colour from adjacent matches;
a direct special bypasses the colour. Vines spread after a settled move that did not
damage any vine; clearing all of them is required. Conduits move pieces from the
marked entrance to their paired exit. A tablet falls into its marked exit and
cannot be matched or destroyed. Ordinary match lines stop at board holes, but
rays pass over them.

Starting positions and targets are authored in `lua/campaign.lua`. Locks are
ranked by the terrain priorities; solid cells and other reserved positions are
excluded from ranked placement. As in Homescapes' story levels, a board has at
most one floor, moss or lamp oil; dig sites are not used. A level is won by its
own goals only. As in Homescapes, each level
names one to three (at most two up to level 12) and score is never one: points
only rank a clear. "Blockers" counts chains, ice, stones, seals and vines
together. Pieces refill at
exposed tops and blocked-parent pockets, so a gap does not imply a sealed supply.
One paired conduit at most is used on each board. The first-clear rewards, story
and building milestones are unchanged. Seeded bot wins are not human balance;
playtesting should inspect openings, late cleanup and delivery paths.

Starting coverings are determined by the terrain priorities in `lua/campaign.lua`.
