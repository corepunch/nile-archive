# Relic Rush board progression

The expedition uses score, collection, sand, blocker and delivery goals. After
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

| Level | Board | Family | Lesson and focus | Moves |
| ---: | --- | --- | --- | ---: |
| 1 | First Light | Tapered bowl | Match 3 in a row. | 24 |
| 2 | The Lamp Lens | Tapered bowl | Match 4 for a sun ray. | 29 |
| 3 | The Buried Cable | Two chambers | Match beside the stone to break it. | 32 |
| 4 | Under the Pump | Twin lanes | Match to break chains. | 35 |
| 5 | The Quay Marker | Tapered bowl | Rays cross gaps. | 35 |
| 6 | The Shore Marker | Two chambers | Match to break ice. | 37 |
| 7 | The Tool Roll | Two chambers | Some stones need two hits. | 40 |
| 8 | The Broken Cable | Compact court | Match 5 for a prism. | 40 |
| 9 | The Supply Crate | Two chambers | Match the seal’s colour beside it. | 43 |
| 10 | The Shutter Crank | Twin lanes | Uncover the buried centre. | 46 |
| 11 | The Long Terrace | Tapered bowl | Pieces travel between paired conduits. (conduit) | 33 |
| 12 | Twelve Crates | Twin lanes | Free chained relics. (colour seal) | 36 |
| 13 | Names in the Stone | Twin lanes | Aim rays along the stone. | 37 |
| 14 | Static | Two chambers | Work around the broken seam. (colour seal) | 38 |
| 15 | The Frost Line | Tapered bowl | Break the three-layer stone. (stone) | 39 |
| 16 | Supper for Twelve | Twin lanes | Stop the vines before they spread. (vines) | 40 |
| 17 | The Torn Log | Tapered bowl | Some coloured seals take two hits. (colour seal) | 42 |
| 18 | Lantern Steps | Tapered bowl | Clear the open terrace. (familiar coverings) | 40 |
| 19 | Under the Vines | Twin lanes | Dig beneath the locks. (vines) | 45 |
| 20 | The Archivist's Key | Twin lanes | Open the central approach. | 46 |
| 21 | Tomas's Trail | Tapered bowl | Clear below the tablet to deliver it. (delivery) | 35 |
| 22 | The Frozen Stair | Twin lanes | Thaw the frozen approach. (stone) | 40 |
| 23 | The Star Road | Twin lanes | Choose a colour for the prism. (colour seal) | 40 |
| 24 | Noon Shadow | Tapered bowl | Excavate across the shadow. (conduit) | 41 |
| 25 | Smoke on the Water | Tapered bowl | Work through the locks. (vines) | 38 |
| 26 | The Jade Deep | Twin lanes | Thaw the buried ground. | 43 |
| 27 | Six Sun Gates | Twin lanes | Clear the scattered locks. (colour seal) | 45 |
| 28 | The Last Terrace | Tapered bowl | Clear the open terrace. (familiar coverings) | 42 |
| 29 | The Silent Temple | Twin lanes | Dig through the temple floor. (stone) | 47 |
| 30 | The Warning Returns | Tapered bowl | Send the tablet through the conduit. (conduit, delivery) | 49 |

Stones and seals are solid cells: matches beside them or direct special hits
remove one layer per wave. Seals require their own colour from adjacent matches;
a direct special bypasses the colour. Vines spread after a settled move that did not
damage any vine; clearing all of them is required. Conduits move pieces from the
marked entrance to their paired exit. A tablet falls into its marked exit and
cannot be matched or destroyed. Ordinary match lines stop at board holes, but
rays pass over them.

Starting positions and targets are authored in `lua/campaign.lua`. Soil is
ranked by the terrain priorities; solid cells and other reserved positions are
excluded from ranked placement.
All locks, solids and vines, the full soil count, and every delivery
must be completed along with the score and collection goals. Pieces refill at
exposed tops and blocked-parent pockets, so a gap does not imply a sealed supply.
One paired conduit at most is used on each board. The first-clear rewards, story
and building milestones are unchanged. Seeded bot wins are not human balance;
playtesting should inspect openings, late cleanup and delivery paths.

Starting coverings are determined by the terrain priorities in `lua/campaign.lua`.
