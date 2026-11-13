# Winter wish board progression

The market's courts move from uncovering displays to delivering parcels between
working areas. The first two wishes teach matches and striped treats. Wishes 18
and 28 are lighter intervals. Roles below are design intentions rather than
measured human difficulty.

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
| 1 | Welcome Lights | Tapered bowl | Match three treats in a line. (line matching) | bows | 24 |
| 2 | Lumber Lane | Tapered bowl | Match four to make a striped treat. (familiar coverings) | bows, snow | 28 |
| 3 | Gingerbread Swirl | Tapered bowl | Clear both snow cells to reveal a display. (hidden display) | display | 32 |
| 4 | Cocoa Corner | Twin lanes | Match through tinsel to free treats. (familiar coverings) | blockers, snow | 34 |
| 5 | Toymaker Lane | Two chambers | Match beside the snowdrift to clear it. (snowdrift) | blockers, bows | 36 |
| 6 | Ribbon Wishes | Compact court | Match on ice to crack it. (familiar coverings) | blockers, snow | 38 |
| 7 | Candlelight Circle | Two chambers | Some snowdrifts need two hits. (snowdrift) | blockers, bows | 40 |
| 8 | Carousel Stars | Tapered bowl | Match the ribbon colour beside its parcel. (ribbon parcel) | blockers, snow | 42 |
| 9 | Skating Evening | Twin lanes | Match on the green carpet to spread it. (familiar coverings) | carpet | 44 |
| 10 | Under the Big Fir | Tapered bowl | Clear snow, tinsel and ice. (ribbon parcel) | snow, blockers | 46 |
| 11 | Carols and Crumbs | Two chambers | Clear the snow around the square. (hidden display) | display, bows | 32 |
| 12 | Word from Fenwick | Tapered bowl | Treats travel between paired chutes. (chute) | bows, snow | 35 |
| 13 | Sawdust Row | Twin lanes | Clear the spilled caramel before it spreads. (ribbon parcel) | caramel, blockers | 36 |
| 14 | The Bench by the Fir | Tapered bowl | Clear the three-layer snowdrift. (snowdrift) | blockers, snow | 37 |
| 15 | Tangled Tinsel | Tapered bowl | Untangle tinsel through the snow. (hidden display) | display, blockers | 38 |
| 16 | Paper and String | Twin lanes | Some ribbon parcels take two hits. (ribbon parcel) | blockers, bows | 40 |
| 17 | Twelve Horses | Tapered bowl | Clear below the parcel to deliver it. (delivery) | delivery, snow | 41 |
| 18 | Fairy Lights | Tapered bowl | Take a breath and clear the snow. (familiar coverings) | snow | 42 |
| 19 | A Hundred Flames | Two chambers | Remember: thick ice takes two hits. (snowdrift) | blockers, snow, bows | 44 |
| 20 | A Letter Forty Years Late | Tapered bowl | Open both sides of the court. (chute) | snow, blockers | 46 |
| 21 | Carolers Court | Tapered bowl | Clear the snow for the carolers. (familiar coverings) | carpet, snow | 34 |
| 22 | Many Hands | Tapered bowl | Free tinsel along the passage. (ribbon parcel) | blockers, snow | 38 |
| 23 | Painted Horses | Twin lanes | Untangle the ribbon before it spreads. (spreading ribbon) | blockers, bows | 39 |
| 24 | Frozen Fountain | Tapered bowl | Thaw the ice around the fountain. (hidden display) | display, blockers | 40 |
| 25 | Snow on the Line | Tapered bowl | Clear the snow and free the treats. (spreading ribbon) | caramel, snow, blockers | 42 |
| 26 | Lantern Ice | Tapered bowl | Thaw the ice around the lanterns. (ribbon parcel) | blockers, bows | 44 |
| 27 | Every Light in Bellmere | Two chambers | Clear the snow across the court. (snowdrift) | snow, blockers, bows | 38 |
| 28 | The Last Train | Tapered bowl | Roll out the carpet before the finale. (familiar coverings) | carpet | 44 |
| 29 | The Big Fir | Twin lanes | Untangle and thaw the snowy court. (spreading ribbon) | blockers, snow, bows | 47 |
| 30 | Light the Christmas Tree | Tapered bowl | Send the parcel through the chute. (chute, delivery) | delivery, snow, blockers | 48 |

Packed drifts and colour parcels are solid cells. An adjacent match or direct
special removes one layer per wave; adjacent parcel hits must match its colour,
while a direct special bypasses colour. A display is credited after every snow
cell in its footprint is uncovered. Ribbon spreads after a settled move that
has not damaged ribbon, and all ribbon must be cleared. Chutes carry pieces from
entrance to exit. Delivery parcels fall to a marked exit and cannot be matched or
destroyed. Holes interrupt ordinary matches; striped treats can cross them.

Starting positions and targets are authored in `lua/campaign.lua`. The terrain
ranks snow and locks; display cells gain snow if needed, and solid cells and other
reserved positions are excluded from ranked placement. All locks, solids and
ribbon, the full snow count, every display and every delivery are on the board,
but a level is won by its own goals only. As in Homescapes, each level names
one to three (at most two up to level 12) and score is never one: points only
rank a clear. "Blockers" counts tinsel, ice, snowdrifts, parcels and ribbon
together. Every exposed top refills and blocked
upstream pockets can spawn, so a narrow court does not guarantee a blocked
supply. A board has at most one chute pair. Story scenes and building milestones
are unchanged. Seeded bot wins are not human balance; playtesting should inspect
openings, late cleanup and delivery paths.

## Starting coverings

Coordinates are axial `(q,r)`. Ice marked ² starts with two layers; all other
ice and chain cells start with one. Footprint cells already appear among the
soil cells. Solid, hazard, conduit and delivery positions are specified
explicitly in the campaign data.

| Level | Soil | Chains | Ice |
| ---: | --- | --- | --- |
| 1 | — | — | — |
| 2 | 0,-1; 1,-2; 1,-1; 1,0; 1,1; 2,-1; 2,0 | — | — |
| 3 | -3,1; -3,2; -2,0; -2,1; -2,2; -1,0; -1,1; 0,-1; 0,0; 0,1; 1,-1; 1,0; 1,1 | — | — |
| 4 | -2,1; -2,2; 1,-4; 2,-4; 2,-3; 2,-2; 2,-1; 3,-4; 3,-3; 3,-2 | 2,-3; 3,-2; 2,-1; 0,-3 | — |
| 5 | -4,0; -4,1; -4,2; -3,-1; -3,0; -3,1; -2,-1; -2,0; -2,1; 2,-2; 2,-1; 3,-2; 3,-1 | 2,-1; -2,-1; 3,-2; -4,1 | — |
| 6 | -1,2; 0,-2; 0,-1; 0,0; 0,1; 0,2; 1,-3; 1,-2; 1,-1; 1,0; 1,1; 2,-3; 2,-2 | — | 1,1; 1,0; 1,-1; 0,2; 1,-3 |
| 7 | -3,1; -3,2; -3,3; -2,0; -2,1; -2,2; -2,3; -1,3; 2,-3; 2,-2; 2,-1; 2,1; 3,-3; 3,-2; 3,-1 | -2,1; 3,-2; -3,2; -2,3 | 3,-1²; -3,1; -3,3; -2,0²; -1,3 |
| 8 | -2,-1; -2,0; -2,1; -2,2; -2,3; -1,-1; -1,1; -1,2; 0,-2; 0,-1; 0,0; 0,1; 0,2; 1,-2; 1,-1; 1,0; 1,1 | 0,1; -1,2; 0,2; 1,0 | 0,-2²; 0,0; 1,-2; 1,-1²; 1,1; -2,-1 |
| 9 | -4,1; -4,2; -4,3; -3,0; -3,1; -3,2; -3,3; -2,-1; -2,0; -2,1; -2,2; -2,3; 2,-4; 2,-3; 2,-2; 2,-1; 2,0; 3,-3; 3,-2 | 2,-2; -2,0; 2,-1; -4,1; -3,0 | -2,2²; 2,-3; 3,-3; 3,-2²; -3,3; -2,-1 |
| 10 | -1,-2; -1,-1; -1,1; -1,2; 0,-3; 0,-2; 0,-1; 0,0; 0,1; 0,2; 0,3; 1,-3; 1,-2; 1,-1; 1,0; 1,1; 1,2; 2,-3; 2,-2; 2,-1; 2,0; 2,1 | 0,-2; 1,-2; 0,0; 0,-3; -1,-2; 2,-1 | 0,2²; 1,-3; 0,-1; -1,2²; -1,1; -1,-1 |
| 11 | -3,-1; -3,0; -3,1; -2,-2; -2,-1; -2,0; -2,1; -1,3; 0,3; 1,2; 1,3; 2,-1; 2,0; 2,1 | — | — |
| 12 | -3,1; -3,2; -2,0; -2,1; -2,2; -1,0; -1,1; 0,-1; 0,0; 1,-2; 1,-1; 1,0; 2,-2; 2,-1; 3,-1 | -2,1; 1,0; 0,-1; -2,2; -3,1 | — |
| 13 | -3,1; -3,2; -3,3; -2,0; -2,1; -2,2; -2,3; 0,-3; 1,-4; 2,-4; 2,-3; 2,-2; 2,-1; 3,-4; 3,-3; 3,-2 | -2,2; -3,1; -2,0; 1,-4; 3,-4; -4,1 | — |
| 14 | -3,0; -3,1; -2,-1; -2,0; -2,1; -1,-1; -1,0; 1,-1; 1,0; 2,-2; 2,-1; 3,-2; 3,-1; 3,0; 4,-3; 4,-2; 4,-1 | -2,0; 2,-2; -1,0; -2,-1; 4,-1; 3,0; 2,-3 | — |
| 15 | -2,-1; -2,0; -1,-2; -1,-1; 0,-3; 0,-2; 0,-1; 0,1; 0,2; 1,-3; 1,-2; 1,0; 1,1; 1,2; 2,0; 2,1 | 1,1; 0,-3; 0,2; 1,0; 2,1; -1,-3; 0,-4; 0,0; 1,-1 | — |
| 16 | -3,1; -3,2; -3,3; -2,0; -2,1; -2,2; -2,3; 2,-3; 2,-2; 2,-1; 3,-3; 3,-2; 3,-1; 3,0; 4,-4; 4,-3; 4,-2; 4,-1 | 2,-2; 3,-1; 2,-3; -3,3 | 3,-2; 3,-3; -2,3; -2,0; -3,2; -3,1; 3,0 |
| 17 | -4,1; -4,2; -4,3; -3,0; -3,1; -3,2; -3,3; -2,-1; -2,0; -2,1; -2,2; -1,0; -1,1; 1,-1; 1,0; 2,-1; 2,0; 3,-2; 3,-1 | 2,-1; -2,0; -1,1; 3,-1; -4,3 | -2,2; -1,0; 1,-1; 1,0; 2,0; 3,-2; -3,0 |
| 18 | -1,0; -1,1; 0,-2; 0,-1; 0,0; 0,1; 1,-3; 1,-2; 1,-1; 1,0; 2,-3; 2,-2 | 0,0; 1,0 | 1,-1; 1,-3; 0,1; 0,-1 |
| 19 | -4,0; -4,1; -3,-1; -3,0; -3,1; -2,-2; -2,-1; -2,0; -2,1; 2,-3; 2,-2; 2,-1; 2,0; 3,-3; 3,-2; 3,-1; 3,0; 4,-3; 4,-2; 4,-1 | -2,-1; 2,0; -3,-1; -2,-2; 3,-3; 4,-2 | 3,-2²; 3,-1; -3,0; -3,1²; -2,1; 2,-3; 3,0²; -3,2 |
| 20 | -3,1; -3,2; -2,0; -2,1; -2,2; -1,0; -1,1; 0,-1; 0,0; 0,1; 0,2; 1,-2; 1,-1; 1,0; 1,2; 2,-2; 2,-1; 2,0; 2,1; 3,-2; 3,-1; 3,0 | -2,1; 0,0; -2,2; -3,1; 3,-2; 1,2; 0,-1 | 1,-1²; 0,1; -1,1; -1,0²; -2,0; -3,2; 3,0²; 3,-1; 2,1 |
| 21 | -2,-1; -1,-1; -1,0; 0,-2; 0,-1; 0,0; 0,1; 0,2; 1,-2; 1,-1; 1,0; 1,1; 1,2; 2,0; 2,1 | — | — |
| 22 | -3,0; -3,1; -2,-1; -2,0; -2,1; -1,-1; 0,-1; 0,0; 1,-2; 1,-1; 1,0; 2,-2; 2,-1; 3,-3; 3,-2; 3,-1 | -2,0; 1,0; 0,-1; -2,-1; 3,-1; 2,0 | — |
| 23 | -3,1; -3,2; -3,3; -2,0; -2,1; -2,2; -2,3; 2,-4; 2,-3; 2,-2; 2,-1; 3,-4; 3,-3; 3,-2; 3,-1; 4,-4 | -2,1; 2,-1; -3,1; -2,0; 4,-4 | 3,-3; 3,-2; -3,2; -3,3; -2,3 |
| 24 | -2,-1; -2,0; -2,1; -1,-1; -1,0; -1,1; -1,2; 0,-2; 0,-1; 0,0; 0,1; 0,2; 1,-2; 1,-1; 1,0; 1,1 | 0,1; -1,1; 0,0; 1,-1 | -1,2²; 0,-2; 0,2; 1,-2²; 1,0 |
| 25 | -4,1; -4,2; -4,3; -3,0; -3,1; -3,2; -2,0; -2,1; -2,2; -1,0; -1,1; 0,-1; 0,0; 1,-2; 1,-1; 1,0; 2,-2; 2,-1 | 1,-1; -2,0; -1,1; 1,-2; 2,-1; -4,3 | -2,2²; -1,0; 0,-1; 0,0²; 1,0; 2,-2 |
| 26 | -2,0; -2,1; -1,-1; -1,0; -1,1; -1,2; 0,-2; 0,-1; 0,0; 0,1; 1,-4; 1,-3; 1,-2; 1,-1; 1,0; 2,-3; 2,-2; 2,-1; 3,-3; 3,-2 | -1,0; 1,-1; 0,-1; -1,-1 | 1,-3²; 0,0; 0,-2; -1,1²; -2,1; -2,0; 3,-2²; 3,-3; 2,-1 |
| 27 | -4,1; -4,2; -4,3; -3,0; -3,1; -3,2; -3,3; -2,-1; -2,0; -2,1; -2,2; -2,3; 2,-2; 2,-1; 3,-2; 3,-1 | 2,-1; -2,0; 3,-2; -4,2; -3,3 | -2,2²; 2,-2; 3,-1; -3,0²; -2,-1; -2,3 |
| 28 | -1,0; -1,1; 0,-1; 0,0; 0,1; 1,-2; 1,-1; 1,0; 2,-2; 2,-1; 3,-3; 3,-2; 3,-1 | 0,0; 1,0 | 1,-2; 0,1; 0,-1; -1,1 |
| 29 | -4,1; -4,2; -4,3; -4,4; -3,0; -3,1; -3,2; -3,3; -2,0; -2,1; -2,2; -2,3; 2,-3; 2,-2; 2,-1; 2,1; 3,-3; 3,-2; 3,-1; 3,0; 4,-3; 4,-2; 4,-1 | -2,1; -3,1; -2,0; 2,1; 4,-3; -4,1; -4,4; -2,-1 | 3,-2²; 3,-1; -3,2; -3,3²; -2,3; 2,-3; 3,-3²; 3,0; -3,0; 0,3² |
| 30 | -1,-2; -1,-1; -1,2; -1,3; 0,-3; 0,-2; 0,-1; 0,0; 0,1; 0,2; 0,3; 1,-4; 1,-3; 1,-2; 1,-1; 1,0; 1,1; 1,2; 1,3; 2,-3; 2,0; 3,-1; 3,0; 3,1 | 0,-2; 1,2; 0,2; 0,-1; -1,-2; 3,-1; 1,3; 1,-1 | 1,0²; 1,-2; 1,-3; 0,1²; 0,-3; -1,-1; 3,0²; 2,-3; 0,3; 0,0² |
