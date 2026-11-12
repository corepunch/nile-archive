# Relic Rush board progression

The expedition moves from excavation to opening a route for recovered objects.
The first two boards teach matches and rays. Boards 18 and 28 provide lighter
intervals. The following are intended decisions, not measured human difficulty.

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
| 1 | First Light | Tapered bowl | Match 3 in a row. (line matching) | 24 |
| 2 | The Jade Crescent | Tapered bowl | Match 4 for a sun ray. (familiar coverings) | 29 |
| 3 | Sunstone Spiral | Two chambers | Match beside the stone to break it. (stone) | 32 |
| 4 | The Vine Constellation | Twin lanes | Match to break chains. (familiar coverings) | 35 |
| 5 | Three Paths Meet | Tapered bowl | Excavate both cells to reveal the find. (hidden find) | 35 |
| 6 | Winter Lotus | Two chambers | Match to break ice. (familiar coverings) | 37 |
| 7 | The Ember Ring | Two chambers | Some stones need two hits. (stone) | 40 |
| 8 | Prism Hollow | Compact court | Match 5 for a prism. (familiar coverings) | 40 |
| 9 | The Sixfold Seal | Two chambers | Match the seal's colour beside it. (colour seal) | 43 |
| 10 | Heart of the Hexagon | Twin lanes | Uncover the buried centre. (familiar coverings) | 46 |
| 11 | The Long Terrace | Tapered bowl | Pieces travel between paired conduits. (conduit) | 33 |
| 12 | Twelve Crates | Twin lanes | Free chained relics. (colour seal) | 36 |
| 13 | Names in the Stone | Twin lanes | Aim rays along the stone. (hidden find) | 37 |
| 14 | Static | Two chambers | Work around the broken seam. (colour seal) | 38 |
| 15 | The Frost Line | Tapered bowl | Break the three-layer stone. (stone) | 39 |
| 16 | Supper for Twelve | Twin lanes | Stop the vines before they spread. (vines) | 40 |
| 17 | The Torn Log | Tapered bowl | Some coloured seals take two hits. (colour seal) | 42 |
| 18 | Lantern Steps | Tapered bowl | Clear the open terrace. (familiar coverings) | 40 |
| 19 | Under the Vines | Twin lanes | Dig beneath the locks. (vines) | 45 |
| 20 | The Archivist's Key | Twin lanes | Open the central approach. (hidden find) | 46 |
| 21 | Tomas's Trail | Tapered bowl | Clear below the tablet to deliver it. (delivery) | 35 |
| 22 | The Frozen Stair | Twin lanes | Thaw the frozen approach. (stone) | 40 |
| 23 | The Star Road | Twin lanes | Choose a colour for the prism. (colour seal) | 40 |
| 24 | Noon Shadow | Tapered bowl | Excavate across the shadow. (conduit) | 41 |
| 25 | Smoke on the Water | Tapered bowl | Work through the locks. (vines) | 38 |
| 26 | The Jade Deep | Twin lanes | Thaw the buried ground. (hidden find) | 43 |
| 27 | Six Sun Gates | Twin lanes | Clear the scattered locks. (colour seal) | 45 |
| 28 | The Last Terrace | Tapered bowl | Clear the open terrace. (familiar coverings) | 42 |
| 29 | The Silent Temple | Twin lanes | Dig through the temple floor. (stone) | 47 |
| 30 | The Song Returns | Tapered bowl | Send the tablet through the conduit. (conduit, delivery) | 49 |

Stones and seals are solid cells: matches beside them or direct special hits
remove one layer per wave. Seals require their own colour from adjacent matches;
a direct special bypasses the colour. A find is credited when all cells in its
footprint have been excavated. Vines spread after a settled move that did not
damage any vine; clearing all of them is required. Conduits move pieces from the
marked entrance to their paired exit. A tablet falls into its marked exit and
cannot be matched or destroyed. Ordinary match lines stop at board holes, but
rays pass over them.

Starting positions and targets are authored in `lua/campaign.lua`. Soil is
ranked by the terrain priorities, then find cells receive soil if necessary;
solid cells and other reserved positions are excluded from ranked placement.
All locks, solids and vines, the full soil count, every find and every delivery
must be completed along with the score and collection goals. Pieces refill at
exposed tops and blocked-parent pockets, so a gap does not imply a sealed supply.
One paired conduit at most is used on each board. The first-clear rewards, story
and building milestones are unchanged. Seeded bot wins are not human balance;
playtesting should inspect openings, late cleanup and delivery paths.

## Starting coverings

Coordinates are axial `(q,r)`. Ice marked ² starts with two layers; all other
ice and chain cells start with one. Footprint cells already appear among the
soil cells. Solid, hazard, conduit and delivery positions are specified
explicitly in the campaign data.

| Level | Soil | Chains | Ice |
| ---: | --- | --- | --- |
| 1 | — | — | — |
| 2 | -2,0; -1,-1; 0,-1; 1,-1; 2,-1; 3,-1; 4,-1 | — | — |
| 3 | -4,3; -4,4; -3,2; -3,3; -3,4; -2,1; -2,2; -2,3; 2,-3; 2,-2; 3,-3; 4,-4 | — | — |
| 4 | -2,-2; -2,-1; -2,0; -2,1; -1,-3; -1,-2; -1,3; -1,4; 0,-4; 0,-3 | -1,-2; 0,-4; -2,-1; -2,2 | — |
| 5 | -4,1; -3,1; -2,0; -2,1; -1,-1; -1,0; -1,1; 0,-1; 0,0; 1,-1; 1,0; 2,0; 3,0; 4,0 | -1,0; 2,0; -4,1; -1,-1 | — |
| 6 | -3,4; -2,2; -2,3; -2,4; 2,-2; 2,-1; 2,0; 3,-3; 3,-2; 3,-1; 4,-4; 4,-3; 4,-2 | — | 3,-3; 3,-1; 2,-2; 2,0; -2,2 |
| 7 | -4,0; -4,1; -3,-1; -3,0; -3,1; -2,-1; -2,0; -2,1; 2,-1; 2,1; 3,0; 4,0 | -3,0; 4,0; -3,1 | -2,-1²; -2,1; 2,-1; 2,1² |
| 8 | -3,-1; -3,0; -2,-2; -2,-1; -2,0; -1,-2; -1,-1; -1,0; 0,-2; 0,-1; 0,0; 1,-2; 1,-1; 1,0; 2,-2; 2,-1; 2,0 | 1,-1; -2,-1; 2,0; 0,-2 | 2,-2²; 1,-2; 1,0; 0,0²; -1,-2; -1,0 |
| 9 | -4,2; -4,3; -4,4; -3,1; -3,2; -3,3; -3,4; -2,0; -2,1; -2,2; -2,3; 2,-3; 2,-2; 2,-1; 3,-4; 3,-3; 3,-2; 4,-4; 4,-3 | -3,3; 3,-3; -3,2; -2,3; 3,-4 | -2,1²; 2,-3; 2,-1; 3,-2²; -3,1; -2,0 |
| 10 | -2,-1; -2,0; -2,1; -2,2; -2,3; -2,4; -1,-3; -1,-2; -1,3; -1,4; 0,-4; 0,-3; 0,3; 0,4; 1,-4; 1,-3; 1,2; 1,3; 2,-1; 2,0; 2,1; 2,2 | 0,3; -1,4; 1,2; 1,-3; -2,3; -2,1 | -1,3²; -1,-2; -2,2; 2,1²; -2,0; 2,0 |
| 11 | -4,1; -4,2; -3,1; -3,2; -2,0; -2,1; -2,2; -1,0; -1,1; -1,2; 0,0; 0,1; 2,1; 3,1 | — | — |
| 12 | -4,2; -4,3; -3,1; -3,2; -3,3; -2,0; -2,1; -2,2; 1,-3; 2,-4; 2,-3; 2,-2; 3,-4; 3,-3; 4,-4 | 2,-3; -4,3; 2,-4; -2,0; -3,3 | — |
| 13 | -2,-2; -1,-3; -1,-2; -1,3; -1,4; 0,-4; 0,-3; 0,3; 0,4; 1,-4; 1,-3; 1,2; 1,3; 2,-4; 2,-3; 2,-2; 2,-1; 2,0 | 0,-3; 1,-4; -1,-2; 1,3; 2,-3; -2,-1 | — |
| 14 | -4,0; -4,1; -4,2; -3,0; -3,1; -3,2; -2,0; -2,1; -2,2; 2,-1; 2,1; 2,2; 3,-1; 3,0; 3,1; 4,-1; 4,0 | 2,1; -4,1; 2,2; -3,0; -4,2; 2,-1; -3,-1 | — |
| 15 | -4,3; -4,4; -3,2; -3,3; -3,4; -2,1; -2,2; -2,3; -1,0; -1,1; -1,2; 0,-1; 0,1; 1,-2; 1,-1; 1,0; 2,-2; 2,-1 | -3,3; 1,-1; -3,2; -2,3 | 2,-2; -2,1; -1,0; -1,2; 0,-1; 0,1 |
| 16 | -3,3; -3,4; -2,-2; -2,-1; -2,0; -2,1; -2,2; -2,3; -2,4; -1,-3; -1,-2; -1,3; -1,4; 0,-4; 0,-3; 0,3; 0,4; 1,3 | -1,3; -2,4; 0,3; -2,0 | -2,3²; -2,2; -2,1; -2,-1²; 0,-3; -3,3; -3,2² |
| 17 | -4,1; -2,0; -1,-2; -1,-1; -1,0; 0,-2; 0,-1; 0,0; 1,-2; 1,-1; 1,0; 2,-2; 2,-1; 3,-2; 3,-1; 3,0; 4,-2; 4,-1; 4,0 | 0,-1; 3,-1; -1,-2; 0,0; 2,-2 | -2,0²; -1,0; 0,-2; 1,-2²; 1,0; 3,-2; 3,0² |
| 18 | -3,4; -2,3; -1,2; 0,1; 1,0; 2,-2; 2,-1; 2,0; 3,-2; 3,-1; 4,-3; 4,-2 | 3,-2; 0,1 | -1,2; -2,3; 3,-1; 2,-2 |
| 19 | 0,-4; 0,-3; 0,3; 0,4; 1,-4; 1,-3; 1,2; 1,3; 2,-4; 2,-3; 2,-2; 2,-1; 2,1; 2,2; 3,-4 | 1,-3; 0,-4; 2,-3; 0,3 | 0,-3²; 2,-2; 2,-1; 2,1²; 3,-3; -1,-2 |
| 20 | -3,0; -2,-1; -2,0; -2,1; -1,-3; -1,-2; -1,3; 0,-4; 0,-3; 0,3; 0,4; 1,-3; 1,2; 1,3; 2,-1; 2,0; 2,1; 3,0 | 0,-3; -1,-2; -2,1; 2,-1; -1,-3 | 1,2²; -2,-1; 2,1; -3,0²; -1,3; 1,-3; 3,0² |
| 21 | -4,2; -4,3; -4,4; -3,1; -3,2; -3,3; -2,0; -2,1; -2,2; -1,-1; -1,0; -1,1; 0,-1; 0,0; 1,-2 | — | — |
| 22 | -2,-2; -2,-1; -2,0; -2,1; -2,2; -2,3; -2,4; -1,-3; -1,-2; -1,3; -1,4; 0,-4; 0,-3; 0,3; 0,4; 1,-4 | -1,-2; 0,-4 | 0,-3²; -2,-1; -2,0; -2,1²; -2,2; -2,3; 0,3²; 1,-3 |
| 23 | -4,0; -4,1; -4,2; -3,0; -3,1; -3,2; -2,0; -2,1; -2,2; 1,2; 2,1; 3,1 | -3,1; 3,1; -3,0 | -3,2; -2,0; -2,2; 1,2 |
| 24 | -2,0; -2,1; -2,2; -1,-1; -1,0; -1,1; -1,2; -1,3; 0,-3; 0,-1; 0,0; 0,1; 0,2; 0,3; 0,4; 1,-1; 1,0; 1,2; 1,3; 2,1 | 0,0; -1,0; 1,2; 0,4 | 0,-1²; 0,3; -1,2; 1,0²; -2,1 |
| 25 | -1,0; -1,1; -1,2; -1,3; -1,4; 0,-4; 0,-3; 0,-2; 0,-1; 0,0; 0,1; 0,2; 0,3; 0,4; 1,0; 1,1; 1,2; 1,3 | 0,3; 0,0; 0,-3; -1,3; 1,2; -1,0 | 0,-1²; 0,-2; -1,2; -1,1²; 1,1; 1,0 |
| 26 | -3,-1; -2,-2; -2,-1; -2,0; -2,1; -1,-3; -1,-2; 0,-4; 0,-3; 0,3; 1,-4; 1,-3; 1,2; 2,-2; 2,-1; 2,0; 3,-1 | -1,-2; 2,-1; -2,-2; 2,-2 | 1,-3²; -2,0; 0,3; 2,0²; 1,2; 3,-1; -2,1² |
| 27 | -4,2; -4,3; -4,4; -3,1; -3,2; -3,3; -3,4; -2,0; -2,1; -2,2; -2,3; -2,4; 2,-3; 2,-2; 2,-1; 3,-4; 3,-3; 3,-2; 4,-4; 4,-3 | -3,3; 3,-3; -3,2; -2,3; 3,-4; -4,2; -2,4 | -2,1²; 2,-3; 2,-1; 3,-2²; -3,1; -2,0; -1,3²; 1,-3 |
| 28 | 0,1; 0,2; 0,3; 0,4; 1,-4; 1,-3; 1,-2; 1,-1; 1,0; 1,1; 1,2; 1,3; 2,2 | 1,2; 1,-1 | 1,-2; 1,-3; 0,3; 0,2 |
| 29 | -4,0; -4,1; -4,2; -3,-1; -3,0; -3,1; -3,2; -2,-2; -2,-1; -2,0; -2,1; -2,2; -1,-2; 1,2; 2,-2; 2,-1; 2,1; 2,2; 3,-1; 3,0; 3,1; 4,-1; 4,0 | -3,0; 4,0; -3,1; 2,-1; 3,1; -3,2; -1,-2; 2,2 | -2,-1²; -2,1; 2,1; 3,-1²; -2,2; 1,2; 2,-2²; 3,-2; -3,3; -2,3² |
| 30 | -4,3; -4,4; -3,2; -3,3; -3,4; -2,1; -2,2; -2,3; -1,0; -1,1; -1,2; 0,-2; 0,-1; 0,0; 0,1; 1,-3; 1,0; 2,-2; 2,-1; 2,0; 3,-2; 3,-1; 4,-3; 4,-2 | -2,2; 4,-3; 0,1; -2,1; -3,4; 3,-1; -1,-1; -2,4 | -3,3²; 3,-2; 2,-1; 1,0²; 0,-1; -1,0; -1,2²; -2,3; -3,2; 2,0² |
