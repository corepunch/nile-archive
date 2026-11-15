# Relic Rush resource expedition

Clear the marked ground or complete the crew's task. The matches made along the
way bring back Gold, Provisions and Supplies to restore the valley. The launch
campaign uses the existing 30 expeditions, ten restorations, nine quests and
the signal finale. Each restoration should feel like spending what the crew
just brought home.

## What the reference games do

The [extracted Cradle of Rome reference](../../../docs/cradle-of-rome-reference/README.md)
covers the original game's Android beta, with board counts, city prices and
[proposals for this campaign](../../../docs/cradle-of-rome-reference/ADAPTATION.md).

| Question | Cradle of Rome | Cradle of Egypt, GameTop Windows edition |
| --- | --- | --- |
| What clears a board? | Match on every blue plaque before time runs out. Chains limit access to the pieces above the plaques. | The atlas has beige ordinary, blue single-hit and orange two-hit cells. All 115 numbered board files use marked cells. 102 only use single-hit targets, and 13 also have two-hit targets. |
| How do matches pay? | Pieces produce Gold, Food or Supplies according to their type. Lines of four or five pay more per piece than a line of three. The time left can also pay out. | The piece table gives a resource and yield to each earning piece. The four opening types include two filler pieces and two coins. Tomato and brick enter the pool through city construction. |
| Do the piece types change? | Buying a building can introduce a resource piece or a bonus on later boards. Sawmill lumber and quarry stone both feed Supplies. | Level 1 permits four types and 114 subsequent numbered level files permit five. Some levels pin specific opening pieces. The construction table unlocks different spawnable pieces or bonuses over the campaign. |
| How many currencies does a building cost? | The city uses three purses, and prices depend on the building. | Of 20 buildings, two cost Gold alone, one costs Gold and Food, and 17 use all three. The Clay Pit raises the Food requirement before it introduces bricks. |

Rome's blue plaques and income are an especially good fit. A player can
decide whether to take the match that clears a remote plaque, take a colour
needed at home, or satisfy both with one move. The extracted Android beta
and the Egypt desktop edition both make that loop inspectable. The exact
ratios belong to each build. For example, the official Egypt tile guide gives
silver/gold coins yields of 3/5, while the Windows files set them to 2/4.
[GameHouse's Rome walkthrough](https://www.gamehouse.com/blog/2016/04/cradle-of-rome-walkthrough/),
[Awem's Egypt tile guide](https://support.awem.com/hc/en-gb/articles/201076871-Tiles),
[GameTop's Egypt edition](https://www.gametop.com/download-free-games/cradle-of-egypt/).

### The water bucket in Cradle of Rome 2

Big Fish publishes the exact level 4 screenshot from the discussion. Its
board has green leaves, blue flowers, silver coins, gold coins and buckets
of water. The bucket produces **3 Food per piece**, so a match of three
produces 9 Food at base value. The blue marble is the level objective and the
large water vessel on the right is the timer. Awem credits later Food pieces
such as meat, bread and shrimp at 4, 5 and 6 per piece. Buying buildings adds
more valuable pieces and bonuses to the pool. In the recorded opening, the
player builds the well after the first board and reaches the bucket board
after that. The level 4 screenshot establishes the five active pieces at that
moment. The previous slot is unverified.
[Big Fish level 4 screenshot](https://cdn-content.bigfishgames.com/prodstatic/games/es_cradle-of-rome-2/screen1.jpg),
[Well construction in the recorded run](https://www.youtube.com/watch?v=AOBES8G3LGU&t=150s),
[Awem on resources and construction](https://support.awem.com/hc/en-gb/articles/200686242-Building-the-City),
[Awem on level completion](https://support.awem.com/hc/en-gb/articles/200721201).

### Extracted evidence

The GameTop Windows installer was unpacked with innoextract. Its installer
manifest lists two PAKs and separate Theora tutorials for matching, puzzle cells,
collecting resources, and rope. The `AWEM` archive contains 826 indexed entries.
These files were extracted and read for the comparison above.

| Archive entry | What it establishes |
| --- | --- |
| `settings/scenes/game/levels/level_*.xml` | Per-board palette cap, cell targets, target hit count and preplaced pieces. Sample boards 1, 5 and 20 have 12, 64 and 143 target cells. |
| `settings/scenes/game/game_balls.xml` | Piece availability, resource mapping and per-piece payout. |
| `settings/scenes/shop/epochs.xml` | Five epochs with four constructions each, three price fields, and tile or bonus unlocks. |
| `settings/scenes/game/field_tiles.xml` and `textures/scenes/game/game_field_atlas_01.png` | Distinct ordinary, one-hit and two-hit floor art. |
| `app/Video/2_puzzle_cell.ogg` and `app/Video/3_recieve_resources.ogg` | Separate tutorials shipped with the installer. |

The installer and selected files are in the local temporary reference folder
`/tmp/rr-cradle-reference`. The installer SHA-256 is
`6e2cc4353f3d0a118503f0a338ea646140b842d91ef076fb9e63d64dcf23d086`.
The archived Awem trials for Rome and Rome 2 use Gentee installers. The
Shockwave Rome 2 trial has a readable 1,136-entry AWEM directory inside its
wrapper. The referenced level and price files remained packed in both
installers. The screenshot, playthrough and Awem's guide supply the Rome 2
observations above. Apktool expects an Android APK. The paired iPhone can
serve as a visual reference, and the Egypt desktop edition supplied the
extracted files.
[Awem trial archive](https://web.archive.org/web/20070222161945/http://www.awem.com:80/download/CradleOfRomeSetup.exe),
[Awem Rome 2 trial archive](https://web.archive.org/web/20110329182607/http://www.awem.com/download/CradleOfRome2Setup.exe),
[Shockwave Rome 2 trial](https://www.shockwave.com/gamelanding/cradle-of-rome-2),
[innoextract](https://constexpr.org/innoextract/),
[QuickBMS AWEM format](https://mirror.aluigi.org/bms/awem.bms),
[Apktool CLI](https://apktool.org/docs/cli-parameters/).

## Board rules and palette

A beige cell is open ground. Clear the piece on a blue cell once to expose
the sandstone. A lock or cover takes the hit while it protects a piece on
that cell. Locks, salt, rubble and ice are routes through the board. Their
counts stay off the goal bar. A cell changes only when the move reaches it.

A regular expedition marks the work site with blue plaques. Recovery
expeditions match the item in an ordinary colour slot, with a plaque patch
only when the location adds to the task. Delivery boards guide the tablet
or signal plate to its marked exit. Board 30 keeps the three flashes and
Ines's reply. Move limits fit short portrait play and give deliberate resource
matches a visible cost. The soundtrack and effects can show time pressure
without imposing a real-time deadline.

| Regular piece | Family | Yield per removed piece |
| --- | --- | ---: |
| Gold sun coin | Gold | 4 |
| Red berries | Provisions | 1 |
| Green plantains | Provisions | 1 |
| Blue-wrapped timber | Supplies | 1 |
| Purple dressed stone | Supplies | 1 |

Buy or restore a building using the family totals. Timber and stone are
separate match kinds within Supplies, just as berries and plantains are
separate kinds within Provisions. Each piece needs a recognizable shape at phone
size. Resource counters use the coin, a food basket and a supply crate, so
the player can see immediately where the pieces went.

Five types is the normal palette. A 4+1 recovery has four regular kinds and a
story kind in the fifth slot. A 5+1 recovery has six total kinds and should
earn that complexity through layout and enough legal opening swaps. Keep board
1 4+1 and boards 4 and 9 5+1. Board 8 uses a purple snapped cable in 4+1. The
orange slot can hold an authored recovery item or a rarer orange food jar on a
six-kind board. Gold story chapters can temporarily suspend coin income.
Board 4's next restoration uses Provisions and Supplies, and boards 11 and 12 earn
Gold before the note on board 13 takes the yellow slot again. Keep the palette
explicit for each board. A missing family is allowed only when the next story
gate can be funded without that board earning it.

A restoration can also introduce a recurring resource sprite. The Spring Well
is the first such opportunity. After placement, show a turquoise water bucket
in place of the blue timber on the next two water-site boards, 5 and 6.
It pays into **Provisions**, the same family as the fruit. Those boards already
use their green slot for the quay marker, and purple stone still supplies
construction. Clearing the blue plaques and finding the marker are the win
conditions. The bucket remains available on designated water boards and adds
no fourth currency. Later, a restored workshop can introduce cut blocks in
place of rough purple stone. Keep each intro tied to an actual change in the
valley and display the new piece and its yield on the restoration card.

## Restoration prices and earnings

Regular restorations have two price entries. All three apply for the
market, archive and temple, where workers, materials and trade are all involved.
The first restoration spends Provisions and Supplies gathered in the timber tutorial.
These are initial tuning values in Relic Rush units.

| Clear | Restore | Gold | Provisions | Supplies |
| ---: | --- | ---: | ---: | ---: |
| 1 | Expedition camp | — | 6 | 8 |
| 4 | Spring well | — | 10 | 22 |
| 7 | Artisan workshop | 70 | — | 24 |
| 9 | Jungle market | 60 | 18 | 12 |
| 13 | Sunstone courtyard | — | 22 | 26 |
| 16 | Explorer's lodge | 70 | 25 | — |
| 19 | Lost-world archive | 100 | 20 | 25 |
| 23 | Star observatory | 105 | — | 30 |
| 26 | Jade fountain | 110 | — | 33 |
| 29 | Temple of the sun | 120 | 30 | 36 |

A piece earns its base amount each time it actually leaves its cell, including
during cascades and when collected by a special. A hit that removes a lock or
cover with the piece intact pays on the later removal. Specials earn from the
pieces they clear. A piece converted into a special can earn once at
conversion. Story pieces count toward their recovery. Their assembled item has
a separate card. Keep the existing move bonus as a capped Gold reward and use
the existing discovery-star gates for land. Show the three resource totals on
the result card next to any story award and the next building's price.

Record attempt earnings until a successful clear. Claim persists the first
clear, resources, story progress and discovery stars together. A resumed result
can be claimed once. Restart and loss discard unbanked matches. Quitting to the island keeps the active board available for the current session.
Optional replays bank the matches from each won attempt and advance no story.
Suggested play for a missing resource can point to a prior board with two
kinds in its family, with replay entirely optional to the story route.

On first clears that unlock a mandatory restoration, provide a crew delivery
for the exact unreserved shortfall. The results itemizes this delivery apart
from matches. The first board's opening should make this unnecessary in
ordinary play. The crew delivery eliminates progression stalls from random
palettes, early wins or tool-heavy play. Its frequency is a balance measure.
Reserve the price of the next unlocked wonder in all three currencies while
any is owed. Gold-only scenery gives surplus Gold a place to go. Optional
buildings use Gold and one practical resource. Confirmed placement debits the price once and Cancel returns the
preview. Stars remain access requirements.

A save version identifies the Provisions and Supplies slots. Existing Gold,
stars, placements, lives, unlocks, claimed levels and story checkpoints are
preserved. Legacy Wood and Stone are combined into Supplies. If the player
already earned a building at its old single-currency price, migration funds
any shortfall once. The wallet, catalogue and result
screen should all use the same ordering and amount formatting. Use resource
shapes and readable labels alongside color in the guide and price rows.

## Release status and checks

The campaign uses sandstone on all 30 boards, with blue plaque targets on
20. Story recovery, targeted floor clearing and delivery are the win
conditions. The runtime uses the five base resources, the scripted story
pieces and well variants, three balances, and the restoration prices above.
The [art review](screenshots/review/expedition-economy/README.md) shows the
board, wallet, shop and results.

For release balancing, play the first restoration through a fresh save on
both supported phone sizes and sample a migrated save midway through chapter two.
Verify that matching every resource kind, including through a cascade or
special, agrees with the result and the wallet after a restart. Confirm the
shop's price and reserve through Confirm, Cancel, exhausted tool counts, replay
and claim interruption. Record resource yields at all ten restoration gates for
at least 30 deterministic campaign runs, then play through all 30 boards on a
phone with human players. Tune prices so most ordinary clears fund the current
restoration with what the crew matched and keep every story gate available
without mandatory replay. Review plaque recognition and story piece
recognition with Reduce Motion enabled at 390 × 844 and 480 × 900.
