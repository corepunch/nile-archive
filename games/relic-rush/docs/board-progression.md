# Relic Rush board progression

Every expedition asks the player to clear all the blue plaques. Locks,
covers and stone can block access to a marked cell. Where a plaque lies
under a lock or cover, that blocker must come off first. A blocker on plain
stone is optional unless it is in the way. Boards 1–10 and 13 still have
a story piece in one colour slot; **Item recovered!** follows the first clear.
Boards 18 and 28 provide lighter intervals in the later chapters.

| Boards | Palette |
| --- | --- |
| 1 | Five regular kinds, including blue-tied timber |
| 2, 5, 8, 10, 13 | Four regular kinds and one story piece |
| 3, 4, 6, 7, 9 | Five regular kinds and one story piece |

Set `story_piece` and `goal_kind` in [the campaign data](../lua/campaign.lua)
to choose a story sprite and the colour slot it replaces. An optional
`omit_kind` removes one other colour from that board's starting pieces and
refills. Leave it unset for five regular kinds plus the story piece.

Ordinary boards use five resource pieces. The six-kind story palettes also
have room for the amber ration jar. Restoring the Spring Well changes the
blue slot from timber (Supplies) to a water bucket (Provisions) on boards 5
and 6. The marker stays in its green story slot. The scene overview shows the
palettes before and after the well. The Artisan Workshop brings purple cut blocks
to board 9. Each block earns 1 Supplies.

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
| 15 | The Frost Line | Tapered bowl | 12 | 39 |
| 16 | Supper for Twelve | Twin lanes | 13 | 40 |
| 17 | The Torn Log | Tapered bowl | 13 | 42 |
| 18 | Lantern Steps | Tapered bowl | 14 | 40 |
| 19 | Under the Vines | Twin lanes | 12 | 45 |
| 20 | The Archivist's Key | Twin lanes | 9 | 46 |
| 21 | Tomas's Trail | Tapered bowl | 12 | 35 |
| 22 | The Frozen Stair | Twin lanes | 13 | 40 |
| 23 | The Star Road | Twin lanes | 12 | 40 |
| 24 | Noon Shadow | Tapered bowl | 12 | 41 |
| 25 | Smoke on the Water | Tapered bowl | 14 | 38 |
| 26 | The Jade Deep | Twin lanes | 10 | 43 |
| 27 | Six Sun Gates | Twin lanes | 12 | 45 |
| 28 | The Last Terrace | Tapered bowl | 13 | 42 |
| 29 | The Silent Temple | Twin lanes | 16 | 47 |
| 30 | The Warning Returns | Tapered bowl | 16 | 49 |

Stones are solid cells. A neighbouring match or direct power-up hit breaks one stone.
A cover takes one hit when its own piece is matched or struck by a power-up.
Salt crust is the default cover, with barnacles at the quay, rubble at the wall
and ice on board 22. Match or land a power-up directly on a blue plaque to
expose the sandstone. An intact lock or cover absorbs the hit first. Blue
plaques stay in their authored positions. Ordinary match lines stop at board
holes, but rays pass over them.

Starting positions and targets are authored in `lua/campaign.lua`. Locks are
ranked by the terrain priorities; solid cells and other reserved positions are
excluded from ranked placement. The board shows its targets in blue. Points
rank a clear. Pieces refill at
exposed tops and blocked-parent pockets, so a gap does not imply a sealed supply.
The final first clear plays Ines’s three-flash reply before the dialogue and reward. Seeded bot wins are not human balance;
playtesting should inspect openings and late cleanup.

Starting coverings are determined by the terrain priorities in `lua/campaign.lua`.
