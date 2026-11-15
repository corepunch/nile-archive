# Relic Rush board progression

The expedition uses collection, blocker, sand sweeping, spreading ground and
delivery goals. On boards 1–10 and 13 the story piece occupies one colour
slot and advances the collection counter. The first clear shows the quest
object on the **Item recovered!** card. Boards 18 and 28 provide lighter intervals in the
later chapters.

| Boards | Palette |
| --- | --- |
| 1, 2, 5, 8, 10, 13 | Four regular kinds and one story piece |
| 3, 4, 6, 7, 9 | Five regular kinds and one story piece |

Set `story_piece` and `goal_kind` in [the campaign data](../lua/campaign.lua)
to choose a story sprite and the colour slot it replaces. An optional
`omit_kind` removes one other colour from that board's starting pieces and
refills. Leave it unset for five regular kinds plus the story piece. The
existing relic target sets the collection count.

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
| 1 | First Light | Tapered bowl | Match 3 to collect timber. | 10 timber pieces | 24 |
| 2 | The Lamp Lens | Tapered bowl | Match 4 for a rocket. Collect lenses. | 10 lenses | 29 |
| 3 | The Relay Cable | Two chambers | Match beside stone to break it. Collect cable coils. | blockers, 12 cable coils | 32 |
| 4 | Under the Pump | Twin lanes | Collect map pieces and break the chains. | blockers, 15 map pieces | 35 |
| 5 | The Quay Marker | Tapered bowl | Match on cleared stone to sweep sand. Collect marker pieces. | sand, 14 marker pieces | 35 |
| 6 | The Shore Marker | Two chambers | Match the piece under the salt crust. Collect marker pieces. | blockers, 14 marker pieces | 37 |
| 7 | The Tool Roll | Two chambers | Clear the stone and salt crust. Collect tool rolls. | blockers, 16 tool rolls | 40 |
| 8 | The Broken Cable | Compact court | Collect snapped cable. Match 5 for a rainbow ball. | 16 snapped cable pieces | 40 |
| 9 | The Supply Crate | Two chambers | Collect supply packs. Clear the ropes and salt crust. | blockers, 18 supply packs | 43 |
| 10 | The Shutter Gear | Twin lanes | Sweep the sand, clear blockers, and collect gears. | sand, blockers, 20 gears | 46 |
| 11 | The Long Terrace | Tapered bowl | Collect the relics. | relics | 33 |
| 12 | Twelve Crates | Twin lanes | Free relics caught in the vines. | blockers, relics | 36 |
| 13 | Names in the Stone | Twin lanes | Sweep the sand, clear vines, and collect folded notes. | sand, blockers, 14 folded notes | 37 |
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
