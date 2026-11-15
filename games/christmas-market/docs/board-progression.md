# Winter wish board progression

The market's courts move from tinsel and ice to delivering parcels between
working areas, with lanternlight or powder snow on about a third of them. The first two wishes teach matches and rockets. Wishes 18
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
| 2 | Lumber Lane | Tapered bowl | Match four to make a rocket. | bows | 28 |
| 3 | Gingerbread Swirl | Tapered bowl | Match in the lanternlight to light more tiles. (lanternlight) | lanternlight | 32 |
| 4 | Cocoa Corner | Twin lanes | Match through tinsel to free treats. | blockers, bows | 34 |
| 5 | Toymaker Lane | Two chambers | Match beside a stone to break it. (stone) | blockers, bows | 36 |
| 6 | Ribbon Wishes | Compact court | Match on ice to crack it. (lanternlight) | lanternlight, blockers | 38 |
| 7 | Candlelight Circle | Two chambers | Break the carved stone. (stone) | blockers, bows | 40 |
| 8 | Carousel Stars | Tapered bowl | Clear the tinsel and the ice. | blockers, bows | 42 |
| 9 | Skating Evening | Twin lanes | Rockets clear a whole line. (lanternlight) | lanternlight, blockers | 46 |
| 10 | Under the Big Fir | Tapered bowl | Clear the tinsel and the ice. | blockers, bows | 46 |
| 11 | Carols and Crumbs | Two chambers | Share the lanternlight around the square. (lanternlight) | lanternlight, bows | 32 |
| 12 | Word from Fenwick | Tapered bowl | Match five in a line for a rainbow ball. | bows, blockers | 35 |
| 13 | Sawdust Row | Twin lanes | Clear the powder snow before it spreads. (powder snow) | powder snow, blockers | 36 |
| 14 | The Bench by the Fir | Tapered bowl | Clear the stone to open the board. (stone) | blockers, bows | 37 |
| 15 | Tangled Tinsel | Tapered bowl | Untangle tinsel and light the square. (lanternlight) | lanternlight, blockers | 38 |
| 16 | Paper and String | Twin lanes | Thick ice takes two hits. | blockers, bows | 40 |
| 17 | Twelve Horses | Tapered bowl | Clear below the parcel to deliver it. (delivery) | delivery, blockers | 41 |
| 18 | Fairy Lights | Tapered bowl | Light the court for the evening. (lanternlight) | lanternlight | 42 |
| 19 | A Hundred Flames | Two chambers | Remember: thick ice takes two hits. (stone) | blockers, bows | 44 |
| 20 | A Letter Forty Years Late | Tapered bowl | Open both sides of the court. | blockers, bows | 46 |
| 21 | Carolers Court | Tapered bowl | Light the way for the carolers. (lanternlight) | lanternlight, bows | 34 |
| 22 | Many Hands | Tapered bowl | Free tinsel along the passage. | blockers, bows | 38 |
| 23 | Painted Horses | Twin lanes | Untangle the tinsel and thaw the ice. | blockers, bows | 39 |
| 24 | Frozen Fountain | Tapered bowl | Spread lanternlight across the frozen fountain. | lanternlight, blockers | 40 |
| 25 | Snow on the Line | Tapered bowl | Clear the powder snow before it spreads. (powder snow) | powder snow, blockers | 42 |
| 26 | Lantern Ice | Tapered bowl | Thaw the ice around the lanterns. | blockers, bows | 44 |
| 27 | Every Light in Bellmere | Two chambers | Clear the locks across the court. (stone) | blockers, bows | 38 |
| 28 | The Last Train | Tapered bowl | Spread lanternlight along the tracks. | lanternlight | 44 |
| 29 | The Big Fir | Twin lanes | Untangle and thaw the court. | blockers, bows | 47 |
| 30 | Light the Christmas Tree | Tapered bowl | Bring the parcel down to the tree. (delivery) | delivery, blockers | 48 |

Stones are solid cells. An adjacent match or direct power-up hit breaks one stone. Lanternlight spreads to every cell a
match touching it clears. Powder snow clears under a match and spreads after a move
that clears none. Delivery parcels fall to a marked exit and cannot be matched or
destroyed. Holes interrupt ordinary matches; rockets can cross them.

Starting positions and targets are authored in `lua/campaign.lua`. The terrain
ranks the locks; solid cells and other reserved positions are excluded from
ranked placement. As in Homescapes' story levels, a board has at most one floor,
lanternlight or powder snow. A level is won by its
own goals only. As in Homescapes, each level names
one to three (at most two up to level 12) and score is never one: points only
rank a clear. "Blockers" counts tinsel, ice and stone together. Every exposed top refills and blocked
upstream pockets can spawn, so a narrow court does not guarantee a blocked
supply. On first clears of 24, 25 and 28, the floor reveals a [story painting](asset-catalogue.md#story-floors)
and the associated scene plays over the board before the reward card. Seeded bot wins are not human balance; playtesting should inspect
openings, late cleanup and delivery paths.

## Starting coverings

Coordinates are axial `(q,r)`, read from each level's starting board. Ice
marked ² starts with two layers; all other ice and chain cells start with one.
Stone and delivery positions are specified explicitly in the campaign data.

| Level | Floor | Chains | Ice |
| ---: | --- | --- | --- |
| 1 | — | — | — |
| 2 | — | — | — |
| 3 | 0,-1 lanternlight; 0,0 lanternlight | — | — |
| 4 | — | 0,-3; 2,-3; 2,-1; 3,-2 | — |
| 5 | — | -4,1; -2,-1; 2,-1; 3,-2 | — |
| 6 | 1,-1 lanternlight; 1,0 lanternlight | — | 0,2; 1,-3; 1,-1; 1,0; 1,1 |
| 7 | — | -3,2; -2,1; -2,3; 3,-2 | -3,1; -3,3; -2,0²; -1,3; 3,-1² |
| 8 | — | -1,1; 0,0; 0,1; 1,-1 | -1,2²; 0,-2; 0,2; 1,-2²; 1,0; 1,1 |
| 9 | -3,-1 lanternlight; 3,0 lanternlight | -4,1; -3,0; -2,0; 2,-2; 2,-1 | -3,3; -2,-1; -2,2²; 2,-3; 3,-3; 3,-2² |
| 10 | — | -1,-2; 0,-3; 0,-2; 0,0; 1,-2; 2,-1 | -1,-1; -1,1; -1,2²; 0,-1; 0,2²; 1,-3 |
| 11 | 2,-1 lanternlight; 2,0 lanternlight | — | — |
| 12 | — | -3,1; -2,1; -2,2; 0,-1; 1,0 | — |
| 13 | 3,-1 powder snow; 3,0 powder snow; 4,-4 powder snow; 4,-3 powder snow; 4,-2 powder snow; 4,-1 powder snow; 4,0 powder snow | -4,1; -3,1; -2,0; -2,2; 1,-4; 3,-4 | — |
| 14 | — | -2,-1; -2,0; -1,0; 2,-3; 2,-2; 3,0; 4,-1 | — |
| 15 | 1,0 lanternlight; 1,1 lanternlight | -1,-3; 0,-4; 0,-3; 0,0; 0,2; 1,-1; 1,0; 1,1; 2,1 | — |
| 16 | — | -2,0; 2,-2; 2,0; 3,-1 | -3,1; -3,2; -3,3; -2,3; 2,-3; 3,-3; 3,-2 |
| 17 | — | -4,3; -2,0; -1,1; 2,-1; 3,-1 | -3,0; -2,2; -1,0; 1,-1; 1,0; 2,0; 3,-2 |
| 18 | -1,1 lanternlight; -1,2 lanternlight | 0,0; 1,0 | 0,-1; 0,1; 1,-3; 1,-1 |
| 19 | — | -3,-1; -2,-2; -2,-1; 2,0; 3,-3; 4,-2 | -3,0; -3,1²; -3,2; -2,1; 2,-3; 3,-2²; 3,-1; 3,0² |
| 20 | — | -3,1; -2,1; -2,2; 0,0; 1,1; 1,2; 3,-2 | -3,2; -2,0; -1,0²; -1,1; 0,1; 1,-1²; 2,1; 3,-1; 3,0² |
| 21 | -2,1 lanternlight; -2,2 lanternlight | — | — |
| 22 | — | -3,0; -2,0; -2,1; 0,-1; 1,0; 3,-3 | — |
| 23 | — | -3,1; -2,0; -2,1; 2,-1; 2,0 | -3,2; -3,3; -2,3; 3,-3; 3,-2 |
| 24 | -1,-1 lanternlight; 0,-1 lanternlight | -1,1; 0,0; 0,1; 1,-1 | -1,2²; 0,-2; 0,2; 1,-2²; 1,0 |
| 25 | 2,-3 powder snow; 3,-3 powder snow; 3,-2 powder snow; 3,-1 powder snow; 4,-3 powder snow; 4,-2 powder snow; 4,-1 powder snow | -4,3; -2,0; -1,1; 1,-2; 1,-1; 2,-1 | -2,2²; -1,0; 0,-1; 0,0²; 1,0; 2,-2 |
| 26 | — | -1,-1; -1,0; 0,-1; 1,-1 | -2,0; -2,1; -1,1²; 0,-2; 0,0; 1,-3²; 2,-1; 3,-3; 3,-2² |
| 27 | — | -4,2; -3,3; -2,0; 2,-1; 3,-2 | -3,0²; -2,-1; -2,2²; -2,3; 2,-2; 3,-1 |
| 28 | -1,-1 lanternlight; 0,-2 lanternlight | 0,0; 1,0 | -1,1; 0,-1; 0,1; 1,-2 |
| 29 | — | -4,1; -4,4; -3,1; -2,0; -2,1; 2,0; 2,1; 4,-3 | -3,0; -3,2; -3,3²; -2,-1²; -2,3; 2,-3; 3,-3²; 3,-2²; 3,-1; 3,0 |
| 30 | — | -1,-2; 0,-2; 0,-1; 0,2; 1,-1; 1,2; 1,3; 3,-1 | -1,-1; 0,-3; 0,1²; 0,3²; 1,-3; 1,-2; 1,0²; 2,-3; 2,-1; 3,0² |
