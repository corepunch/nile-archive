# Relic Rush board progression

Expeditions ask players to clear blue plaques, recover a story object or
deliver it. Locks, covers and stone control access to the marked cells. On boards 1–10 and 13 the story piece occupies one colour
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
| 3 | The Relay Cable | Two chambers | Match beside a stone to break it. | 12 cable coils | 32 |
| 4 | Under the Pump | Twin lanes | Collect map pieces. Match a chained piece to free it. | 15 map pieces | 35 |
| 5 | The Quay Marker | Tapered bowl | Clear the blue plaques. Collect marker pieces. | 10 blue plaques, 14 marker pieces | 35 |
| 6 | The Shore Marker | Two chambers | Match the piece under the salt crust. Collect marker pieces. | 14 marker pieces | 37 |
| 7 | The Tool Roll | Two chambers | Collect tool rolls. Break stone to open more space. | 16 tool rolls | 40 |
| 8 | The Broken Cable | Compact court | Collect snapped cable. Match 5 for a rainbow ball. | 16 snapped cable pieces | 40 |
| 9 | The Supply Crate | Two chambers | Collect supply packs. | 18 supply packs | 43 |
| 10 | The Shutter Gear | Twin lanes | Clear blue plaques and collect gears. | 12 blue plaques, 20 gears | 46 |
| 11 | The Long Terrace | Tapered bowl | Clear the blue plaques along the terrace. | 12 blue plaques | 33 |
| 12 | Twelve Crates | Twin lanes | Match through the vines to reach the blue plaques. | 12 blue plaques | 36 |
| 13 | Names in the Stone | Twin lanes | Clear blue plaques and collect folded notes. | 10 blue plaques, 14 folded notes | 37 |
| 14 | Static | Two chambers | Clear blue plaques on both sides of the seam. | 13 blue plaques | 38 |
| 15 | The Frost Line | Tapered bowl | Clear the blue plaques around the fallen wall. | 12 blue plaques | 39 |
| 16 | Supper for Twelve | Twin lanes | Hit the salt crust with matches or power-ups. | 13 blue plaques | 40 |
| 17 | The Torn Log | Tapered bowl | Thick salt crust takes two hits. | 13 blue plaques | 42 |
| 18 | Lantern Steps | Tapered bowl | Clear the blue plaques on the terrace. | 14 blue plaques | 40 |
| 19 | Under the Vines | Twin lanes | Clear the blue plaques under the locks. | 12 blue plaques | 45 |
| 20 | The Archivist's Key | Twin lanes | Clear the blue plaques beside the records. | 9 blue plaques | 46 |
| 21 | Tomas's Trail | Tapered bowl | Clear below the tablet to deliver it. | deliver tablet | 35 |
| 22 | The Frozen Stair | Twin lanes | Break the ice to reach the blue plaques. | 13 blue plaques | 40 |
| 23 | The Star Road | Twin lanes | Choose a colour for the rainbow ball. | 12 blue plaques | 40 |
| 24 | Noon Shadow | Tapered bowl | Clear the blue plaques in the shade. | 12 blue plaques | 41 |
| 25 | Smoke on the Water | Tapered bowl | Clear the blue plaques along the quay. | 14 blue plaques | 38 |
| 26 | The Jade Deep | Twin lanes | Clear the blue plaques to open the water channel. | 10 blue plaques | 43 |
| 27 | Six Sun Gates | Twin lanes | Clear the six pairs of blue plaques. | 12 blue plaques | 45 |
| 28 | The Last Terrace | Tapered bowl | Clear the blue plaques on the terrace. | 13 blue plaques | 42 |
| 29 | The Silent Temple | Twin lanes | Clear the blue plaques at the temple entrance. | 16 blue plaques | 47 |
| 30 | The Warning Returns | Tapered bowl | Clear below the signal plate to deliver it. | deliver signal plate | 49 |

Stones are solid cells. A neighbouring match or direct power-up hit breaks one stone.
A cover takes one hit when its own piece is matched or struck by a power-up.
Salt crust is the default cover, with barnacles at the quay, rubble at the wall
and ice on board 22. Match or land a power-up directly on a blue plaque to
expose the sandstone. An intact lock or cover absorbs the hit first. Blue
plaques stay in their authored positions. A tablet falls into its marked exit and
cannot be matched or destroyed. Ordinary match lines stop at board holes, but
rays pass over them.

Starting positions and targets are authored in `lua/campaign.lua`. Locks are
ranked by the terrain priorities; solid cells and other reserved positions are
excluded from ranked placement. Plaque boards have one terrain goal. Boards
5, 10 and 13 also ask for their story piece. Each board lists its win conditions
in the goal bar. Points rank a clear. Pieces refill at
exposed tops and blocked-parent pockets, so a gap does not imply a sealed supply.
The final first clear plays Ines’s three-flash reply before the dialogue and reward. Seeded bot wins are not human balance;
playtesting should inspect openings, late cleanup and delivery paths.

Starting coverings are determined by the terrain priorities in `lua/campaign.lua`.
