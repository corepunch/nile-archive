# Relic Rush · The Lost Valley

From the repository root, `make -C games/relic-rush ios` builds, signs, installs
and launches on a connected iPhone. The native iOS target is iPhone only.
Set `DEVICE="name or UDID"` to select one.
See the [device deployment guide](../../tools/xcode/README.md#deploy-to-a-connected-iphone-or-ipad).

A portrait mobile-first square match-3 / island-restoration prototype, written in C11 on the repository's shared platform engine ([`engine/`](../../engine)), the same engine that runs [Nile Archive](../nile-archive). The island is the engine's `city`; text, shapes, input, camera, saves and sound come from the engine; this folder holds the rules, the content and the look. The WebAssembly preview runs the same C code; the browser page is only a fullscreen canvas.

The first launch goes straight to The Landing, the first of 100 expeditions.
Swap adjacent pieces, match horizontally or vertically, and clear the turquoise
plaques within the move budget. Claim the resources to visit the island, then
tap Build to see the next restoration. Each board uses five piece kinds and
fits inside a 9 × 12 square grid.

Later launches open the illustrated title screen. Continue returns to the
campaign, and Settings opens Sound, Reduce Motion, the guide and the leaderboard.
Use **Main Menu** in Settings to return to the title. See the [title screen](docs/screenshots/main-menu.jpg)
and [phone layout](docs/screenshots/main-menu-phone.jpg).

Building popup images and resource icons follow the panel’s entrance scale,
position and opacity through the shared form skin. See the
[popup and refill comparisons](docs/review/popup-refill/README.md).

Haptics accompany matches, cascades, trickling landings,
results, income collection, building pickup and release/drop. Moving a preview
requires dragging the building; tapping land does not move it. Confirm and Cancel
add no feedback. See the [shared haptics contract](../../docs/HAPTICS.md).

## Island navigation and resources

The cottage at the lower left opens the next restoration. The card shows the price or the remaining amount of each resource. A trail circles the button when the building is affordable and its level requirement is met. Choose a location and confirm to spend the resources. The card also opens the shop for decorations.

The top wallet shows Coins, Supplies and Food on both screens. Matches
preview in the wallet during an expedition and bank after a successful clear.
The completion dialog shows the expedition score.
The Spring well costs Coins alone. Later restorations add Food and Supplies, and from the Expedition camp on every purchase uses all three. Boards cleared unlock shop stock and land. There are no lives: a failed
board can be retried at once.

Tap a placed building for its name and subtitle above it. Only one stays open. The next press dismisses it. A stationary hold picks up a building through the shared mover, with Confirm/Cancel preserving saved state.

See the [building label comparisons at both phone sizes](docs/screenshots/review/town-labels/README.md).

Scrolling uses the engine animation clock: a scalar `CAAnimation` drives the iOS timeline, as in CorePunch/orca, while other platforms use the platform monotonic clock.

## Shared match engine and atlas

Match through every turquoise plaque to win. Single and crossed chains mark pieces that absorb one or two hits before a match clears the plaque beneath them. The last few plaques get a trail around their square edges during idle play. Papyrus fills the ordinary cells. The rounded sandstone rim has a dark lip along the board and alternates leafy and bare inset corners. The [square campaign guide](docs/square-match3.md) lists the boards and tiles.

The [engine match-3 module](../../docs/MATCH3_ENGINE.md) owns all matching,
swaps, blockers, trickling gravity, cascades, hints, tools and board
input/timing. This game provides campaign data, graphics and integer behavior
flags. Every exposed column top (no active cell directly above) spawns gems
vertically. Interior gems fall straight down whenever their cell below is
empty and movable, and slide diagonally only when that cell is occupied,
locked or missing. Locks still route gems around their sides.

The board's art is one atlas per kind in `data/board/`: `pieces.png`,
`blockers.png`, `cells.png`, `hud.png` and `fx.png`. Its backgrounds are separate JPEGs in
`data/board/backs/`. The small HUD icons share `pieces.png` with the board
pieces, and the jade signboard lives in `hud.png`.
`python3 tools/match3_atlas.py` rebuilds the atlases from
the registered sprites in `art/registered/`; [Asset layout](../../docs/ASSET_LAYOUT.md)
describes the folders.
`--default-match3` previews the engine's neutral skin.


## Screenshots

Captured from the engine build with `make shots` (headless, software renderer). Island images use demonstration progress to show the settlement and placement tools.

| Square expeditions | Restored island |
| --- | --- |
| ![Jade Steps on a square board](docs/screenshots/square-jade-steps.jpg) | ![Settlement with freely placed buildings](docs/screenshots/island-village.jpg) |
| ![Chains and blue tablets on board 22](docs/review/chains-only/board-after-480x900.jpg) | ![Choose and confirm a building location](docs/screenshots/island-placement.jpg) |
| ![Large island with locked regions](docs/screenshots/island-zones.jpg) | ![Boards required to open land](docs/screenshots/island-unlock.jpg) |
| ![Buildings stand clear of the soft fog at a region border](docs/screenshots/island-fog.jpg) | ![A building that can't go here turns red](docs/screenshots/island-blocked.jpg) |

## Leaderboard

The LEADERBOARD link in Settings opens the overall rankings by expeditions cleared. The game updates
the total when the player claims a first-clear reward. The dialog shows Everyone and Friends tabs,
player portraits and the player's own row. When offline, it shows the player's best total.

| Settings | Expeditions cleared |
| --- | --- |
| ![Settings with a Leaderboard link](docs/screenshots/pause.jpg) | ![The overall leaderboard](docs/screenshots/leaderboard.jpg) |

![The boards-cleared board on a 390x844 phone](docs/screenshots/phone-leaderboard.jpg)

Use `com.corepunch.relicrush.stars` in [Game Center](../../docs/GAMECENTER.md). Capture the dialog
with sample rivals using `--gamecenter-demo --dialog leaderboard`.

The Landing starts with gold coins, silver coins, leaves, flowers and amphoras. Water, timber and a bonus piece take existing slots once their buildings are confirmed.

Clear every turquoise plaque to finish the expedition. The opening chapter’s dialogue follows island construction.

## Shared UI and dialog layers

The island and the board share one wallet and Settings bar. The green resource
capsules have the same brass rim and drop shadow as the round buttons. The board shows
Moves at the left of the resource balances. The medallion turns red at five
moves. Blue tablets mark the board objective. Winning banks the resources
earned in the three slots.
Four large circular bonus sockets sit in one row below the centered board from the first
expedition. Settings opens the Explorer's Guide,
and Results shows the score and rewards. Popup cards lift and fade in over a
dimmed background, then drift down as they close. The board fades away before
the win or loss card arrives. Reduce Motion skips these transitions.
See the [top bar review](docs/screenshots/review/top-bar-moves/README.md)
and [shared UI API](../../docs/UI_ENGINE.md).


## Result screens and typography

The expedition result shows earned resources and Collect & Return. Above the Build house, each icon shows how much of that resource the next restoration still needs. When the price and level requirement are met, a particle trail circles the house. Tap it for the restoration card and its reward. Reduce Motion hides the trail. [Square build review](docs/square-match3.md#captures).

Text is aligned by its visible ink bounds (the engine's `text_in`), shared by buttons and counters, and paragraphs wrap into balanced lines (`text_box`).

![Result UI and building card animation](docs/screenshots/ui-result-reel.gif)

Dialogs arrive and leave on the engine's motion module ([docs/MOTION.md](../../docs/MOTION.md)): the card eases in and the parts of the result settle on one timeline, which the first tap skips.

See [UI architecture, Playrix/Candy Crush references and regression checks](docs/ui-results-and-type.md).

## Effects and motion

Coloured match fragments, resource trails and cascade chimes follow each clear. During refills, each gem gives a small bounce when it comes to rest in its slot. Reduce Motion suppresses the bounce. The result screen counts the score up. The 0.7-second wipe from the island reveals the board as it assembles. If dialogue is playing, the entrance waits for it to end. The HUD lands, cells ripple out from the centre, relics drop and bounce, blockers slam on and a sheen runs across the board. Tap to skip the entrance. Reduced motion uses a short fade. See [the board entrance](../../docs/ENGINE.md#board-entrance).

![Actual SDL effects demonstration](docs/screenshots/effects-reel.gif)

See [effect reference study](docs/effects.md). The reel uses deterministic test boards; actual iPhone/Android performance still needs device testing.

## Current match-3 rules and boards

The widest board uses nine 48-unit square cells across a 480-unit design. Match three or more in a row or column. A long or crossing match clears each participating piece once. The five matching kinds stay on the board through refills. The ten masks and move budgets live in [campaign.lua](lua/campaign.lua).

After five idle seconds, a legal swap is highlighted. If there is no legal swap, the board reshuffles for free and displays “No moves. Board reshuffled.” This recovery also runs after cascades. Movable pieces fly to their new cells during either a free shuffle or a Mixer use. Locked pieces and blue tablets stay put. Reduce Motion settles the pieces immediately. See the [dead-board regression and captures](docs/review/dead-board/README.md).

Power comes only from the bonus tools: matched bonus gems fly into their sockets and reveal the colored pieces from the bottom.
With Reduce Motion on, the charge appears immediately.
Empty buttons show the tool recessed into sandstone, with a soft shadow along the upper-left edge.
See the [bonus artwork and state review](docs/asset-catalogue.md#campaign-bonus-pieces-and-sockets).

See [matching rules, board shape and implementation notes](docs/square-match3.md). The [hex rules](docs/match4-rules.md) record the previous campaign.

## New art direction

The first match-3 board overlooks the expedition landing. Each of the 20 campaign
restorations introduces a portrait painting of that site on eligible boards once
the player confirms construction. Replays use the same expedition gates.
See the [backdrop catalogue](docs/asset-catalogue.md#construction-backdrops).

See the [reference study, original cast and asset gallery](docs/art-direction-v2.md) and [complete generation prompts](docs/art-direction-v2-prompts.json).

![Original expedition cast: Elena, Mara, Tomas and Adrian](art/art-direction/expedition-cast.png)

Elena Voss leads the archaeological expedition. Mara Bell pilots the Marigold, Tomas Reed keeps the harbor, and Adrian Vale finances the trip. Their busts (cut by `tools/prepare_assets.py` from that lineup) appear in the game's dialogue.

## Story and world

The [script](docs/story.md) runs 100 expeditions in five chapters of twenty. Every expedition has a scene on its first clear, and ten story restorations (after levels 1, 16, 21, 36, 41, 46, 61, 66, 91 and 96) play a scene when placed. The question is who is signalling back to Mara's lamp.

1. **A Light Below** (1–20): the crew restores the Spring well, finds the watch book at the Expedition camp and sees three flashes from under the cliff. The reply choice is at the camp (16).
2. **Tracks on the Terrace** (21–40): the Jungle market and Tide clock tower lead to a note, "Wall unsafe. I. R.", and a crack through the quay wall.
3. **The Keeper's Return** (41–60): the Harbour plaza register and the Harbour lodge name Ines, Tomas's sister, and point to cabinet seventeen.
4. **The Claim** (61–80): the Keeper's archive and the Lighthouse bring Ines's signed plan and second landing, and Adrian's claim on the island.
5. **Keep the Light** (81–100): the Temple of the Sun and Jade fountain end it. Adrian surrenders the claim, the bypass holds, and Ines answers with three flashes and comes home.

A first clear advances the expedition counter. Every won expedition banks its matched resources. Construction, currency and story progress persist across saves.

The speaker’s name tag and the Skip button sit equally far from the dialogue bar, with the name above and Skip below.

`lua/story_content.lua` is compiled directly from the script by `python3 games/relic-rush/tools/prepare_story.py`; `--check` catches drift and runs with the other asset checks in `make test-assets` and `make test`. `lua/journey.lua` holds the restoration schedule, recap and changing tap lines as data (the engine keeps the keyed checkpoints); `lua/narrative.lua` holds the cast; the engine (`engine/lua/match3/game.lua`) delivers the scenes. Preview any scene with `--story-beat before-11` or `--story-beat after-30 --story-line 3`. Restoration dialogue uses named speakers over the live island. The earlier request scenes and paintings remain in the story archive.

| Elena | Mara | Tomas | Adrian | Word bubble |
| --- | --- | --- | --- | --- |
| ![Elena](docs/screenshots/dialogue-elena.jpg) | ![Mara](docs/screenshots/dialogue-mara.jpg) | ![Tomas](docs/screenshots/dialogue-tomas.jpg) | ![Adrian](docs/screenshots/dialogue-adrian.jpg) | ![Bubble](docs/screenshots/island-bubble.jpg) |

On a 390 × 844 iPhone (safe-area insets 47 top, 34 bottom) the island and the jungle run to the screen edges while the controls stay inside the safe area. The screen grows taller there (480 × 939) rather than showing bars: the top HUD stays at the top, the tools and the island's bottom buttons move down to the bottom edge, and the board and dialogs stay centred:

| Island | Board |
| --- | --- |
| ![Island on an iPhone](docs/screenshots/phone-island.jpg) | ![Board on an iPhone](docs/screenshots/square-tide-chamber.jpg) |

## Expedition and restoration loop

1. Start directly in the first match-3 level; there is no title-screen or friend-road detour.
2. Clear all turquoise plaques within the move budget.
3. Claim the matched resources. A first clear counts as a cleared board.
4. Return to the island. At a restoration milestone, check the price and play the next expedition if you need more resources. Clearing the tablets and claiming the reward opens the next expedition. If you build later, the island story picks up where you left it.
5. Confirm construction, pan across the growing settlement and open neighboring land when eligible.
6. See how the crew uses what you built, then set out again. The 100 boards open twenty restorations, one after every fifth board.

A matched sun coin earns 5 Coins and a silver coin 3. Leaves, flowers and amphoras add score only.
The Spring well's water buckets earn Food from expedition 2. The Trapper's cabin introduces Hammer, and the Carpenter's workshop introduces timber worth Supplies. Buying the Expedition camp replaces Hammer with Bomb. The Build card shows the price or the amounts still needed alongside its one reward.

### Tutorials and upgrades (`lua/user_events.lua`)

[`lua/user_events.lua`](lua/user_events.lua) ports Cradle of Rome's
`settings/user_events.xml`. It uses the same event ids, `If` conditions,
`Then` effects and `available` chaining. The runtime is the engine's
([`match3/user_events.lua`](../../engine/lua/match3/user_events.lua), shared with
Christmas Market; see [the match-3 engine](../../docs/MATCH3_ENGINE.md#user-events-and-upgrades));
[`lua/user_events_runtime.lua`](lua/user_events_runtime.lua) only wires it to this
game. Each event fires once per profile, and the save keeps which events are done.

- **Tutorials.** The move hint repeats with the board's 1st, 2nd, 3rd and
  5th suggestion until the first line of three. Toasts introduce tablets,
  double tablets, chains, double chains, ice, the low-moves warning, each
  charged bonus and the catalogue.
- **Upgrades.** Sixteen, with Rome 2's ids `man_01` to `man_16` (Rome's citizens, kept by the
  cast we know; [the table](../../docs/CAMPAIGN_DESIGN.md#upgrades-romes-citizens-kept-by-the-cast-we-know)):
  a second rope and pulley at the Spring well (Tomas), a second saw bench at the Carpenter's workshop
  (Mara), a polished lens at the Lighthouse (Mara) and so on. Placing the building arms its feat (a resource
  earned in one level, a long match or a run of moves); meeting it upgrades the building, awards a trophy and gives
  a lasting perk: more Coins, Food or Supplies in every won expedition, or a tool whose pieces charge one point
  more per match. The building's card shows the feat while it is armed, then "Upgraded: ..." with the perk. The scene,
  spoken by the keeper, is the upgrade's entry in `docs/story.md` under `## Upgrades` and plays on the next return to
  town (a toast if it is missing).
- **Test flag.** `--user-events-test` fires the `test=true` events at once,
  like Rome's F5 cheat.

The building upgrade is recorded but has no art yet.

## Campaign

The 100 square boards are authored in `lua/campaign.lua`, five epochs of twenty levels: A Light Below (1–20), Tracks on the Terrace (21–40), The Keeper’s Return (41–60), The Claim (61–80) and Keep the Light (81–100). Each board has a tier: levels 1–4 teach, then every ten levels run easy, easy, normal, normal, hard, easy, normal, normal, hard, boss. Single chains arrive on level 4 and double chains on level 9. `python3 tools/square_boards.py relic-rush` validates the boards, `tools/square_trim.py` trims long ones and `tools/tune_moves.py` fits their move budgets. Every tier uses the median clear × 1.25, rounded up; slow bot samples do not add moves. The [previous hex campaign](docs/board-progression.md) records the earlier layouts.

## Buildings

[Compare all twenty rewards with Christmas Market and Cradle of Rome 2](../../docs/cradle-of-rome-reference/building-rewards.html).

The ladder has twenty purchases, one available after every fifth board (after levels 1, 6, 11 … 96), four per epoch. It follows the purchase order of the Windows edition of Cradle of Rome 2, with names that match the artwork (the Rome name is in brackets). The Spring well, Expedition camp, Jungle market, Tide clock tower, Harbour plaza, Harbour lodge, Keeper's archive, Lighthouse, Temple of the Sun and Jade fountain are story restorations with a placement scene and hold the next level; the others must be bought before the next story restoration. The [campaign balance check](docs/square-match3.md#construction-balance) fits the prices to the resources the bot earns by clearing boards in order, so the expected campaign needs no replays.

| After level | Restoration | Reward | Coins / Food / Supplies |
| ---: | --- | --- | --- |
| 1 | Spring well (Well) | Water buckets | 35 / 0 / 0 |
| 6 | Trapper's cabin (Hunter's Hut) | Hammer | 445 / 155 / 0 |
| 11 | Carpenter's workshop (Sawmill) | Timber | 985 / 365 / 0 |
| 16 | Expedition camp (Village) | Bomb | 965 / 355 / 390 |
| 21 | Jungle market (Farm) | Ration jars | 905 / 335 / 495 |
| 26 | Stone trading post (Quarry) | Dressed stones | 670 / 570 / 505 |
| 31 | Water mill (Mill) | Grain bundles | 560 / 695 / 680 |
| 36 | Tide clock tower (Thermae) | Shield | 510 / 745 / 690 |
| 41 | Harbour plaza (Port) | Shrimp | 555 / 850 / 780 |
| 46 | Harbour lodge (Curia Octavia) | Hourglass | 505 / 990 / 705 |
| 51 | Stone amphitheatre (Coliseum) | Helmets | 510 / 1025 / 670 |
| 56 | Cartographer's house (House of the Vestals) | Lightning | 545 / 1005 / 665 |
| 61 | Keeper's archive (Aqueduct) | Rings | 580 / 1060 / 685 |
| 66 | Lighthouse | Plus | 625 / 1045 / 665 |
| 71 | Beached schooner (Nero's Golden House) | Scarabs | 735 / 1180 / 750 |
| 76 | Star observatory (Mausoleum of Augustus) | Mixer | 790 / 1160 / 730 |
| 81 | Great aviary (Pantheon) | Sandals | 1065 / 1500 / 955 |
| 86 | Relic museum (Theatre) | Harps | 1135 / 1475 / 915 |
| 91 | Temple of the Sun (Forum) | Star | 1415 / 1625 / 1010 |
| 96 | Jade fountain (Fountain) | Emeralds | 1415 / 1620 / 1020 |

A new game opens with the crew's Supply tent already pitched on the lawn; it is free scenery and moves like any other building. Players may continue expeditions while saving for construction. The shop offers repeatable scenery alongside the campaign buildings. Browse categories and pages, check the
resource price and the number of boards cleared it needs, then choose a location and
confirm. Cancelling is free. The resources
needed for an earned restoration are reserved until placement. Purchases save
and move like wonders, with a 160-object island limit. See the complete
[building catalogue](docs/building-catalogue.md) and
[in-game review](docs/review/building-catalogue/README.md).


## Island regions

The 1920 × 2880 world scrolls beyond the phone screen. Hidden six-neighbor land tiles define connected regions, while placement itself uses continuous world coordinates. The puzzle grid and island territory graph are separate systems.

| Region | Boards cleared to open |
| --- | ---: |
| Harbor glade | 0 |
| Sunlit coast | 15 |
| Fern meadow | 30 |
| Sun garden | 50 |
| Ancient heights | 70 |
| Temple ridge | 85 |

A region must touch opened land and meet its boards-cleared gate. Expansion spends nothing. Regions do not open on a timer, and players do not need to build roads.

## Play

- Swap adjacent pieces to make a straight line of three or more identical pieces along rows or columns. Four in a line leave a line gem of that color, which sweeps its row or column when matched, and five leave a rainbow gem that clears one kind. Crossing lines make no bomb. The bonus tools, charged by matching bonus gems, follow Cradle of Rome.
- Match or land a tool hit on a chained piece to break the chain. A later hit clears a blue tablet on that cell. Ice and carved stones are other blockers; they gate the fall below them.
- Cascades increase score multipliers. Gathered resources animate toward their wallet slots. The result screen shows the matched resource totals and, as icon amounts, what the next restoration still needs.
- Restore buildings to unlock four bonus families. A later restoration
  upgrades each of the four slots and carries its charge forward. An expedition
  can feature one bonus gem family. Matching 30 fills one use, and activation
  costs zero moves. [Bonus effects and restorations](docs/board-progression.md#bonus-pieces)
- Idle hints, automatic dead-board recovery, restart on failure, pause with Restart (confirmed), Quit to Island, and Sound and Reduce motion checkboxes.
- Each won attempt banks what the crew brings back. First clears count toward boards cleared. Chapter 1 story progress follows island actions.
- Large scrollable island, six connected land regions defined by a hidden hex tile graph. Drag the map to pan, even when the gesture starts on a building; pinch to zoom (or use the mouse wheel on desktop).
- Adjacent clouded regions open by the number of boards cleared. There are no stars or compasses.
- The settings gear sits beside the three resource balances. Buildings, Play and Expeditions occupy the town's bottom row. Both catalogues scroll continuously. The building shop shows three cards per row.
- Choose any valid grassy position within opened land. Hold a placed building still for half a second to pick it up, then drag and confirm or cancel. The building shows no label; it turns semitransparent red where it can't go. Completed buildings can be moved without spending resources. Preview and cancellation never change the saved layout.
- Footprint collision and shoreline checks prevent overlap and water placement. Automatic connector roads are disabled.
- Progress saves after rewards, construction and region unlocks (a `key=value` file in the per-game preferences folder, or `localStorage["relic-rush/progress"]` in the browser). An unfinished board restarts if the application is closed.

## Selected tile art

The [artwork and state catalogue](docs/asset-catalogue.md) inventories every gem
pack, chain, tool and animation state, with source and runtime paths.
`--art-states` shows the collection and `--art-board` previews the shared
engine’s board pieces for development. Catalogue coverage runs in `make test`.

The campaign uses one [painted atlas](docs/asset-catalogue.md#campaign-piece-atlas)
for resources, upgrades and story pieces. The **Jewels** and **Resources**
art previews remain available through `--tiles jewels` and `--tiles resources`.
See the [tile-set comparison and construction research](docs/tile-sets.md).
The [Cradle of Rome gem sheet](../../docs/cradle-of-rome-reference/gem-correspondence.html)
shows both games’ pieces and payouts side by side.

Use `--rome-reference-art /absolute/path/to/game_graphics` to compare the
extracted Cradle of Rome 2 chips in a local run. Point it at the directory with
`gmbn_5.png`. The shipped resource art remains in the game data.

![The three packs on the same board](docs/screenshots/tile-sets.jpg)

## Run and build

From the repository root (system platform development files needed for native builds, the Emscripten SDK for the web):

```sh
make run-relic                                  # native desktop
make test                                       # rules, island and engine tests
make web && python3 -m http.server 8080 --directory dist   # http://localhost:8080/relic-rush/
```

The game is laid out for a 480 × 900 portrait screen inside the device's safe area. It is `fixed` with `max_aspect = 2.2`, so on taller phones the screen keeps its width and grows taller (`R.layout()` moves the bottom group down by the extra height, `R.drop`). Its jungle backdrop, the island and the HUD bands run on under the status bar and the home indicator to the screen edges (`app.bleed()` / `gfx.bleed`). Runtime art in `data/` is committed; `python3 games/relic-rush/tools/prepare_assets.py` rebuilds it from the sources in `art/` (needs Pillow).

Debug and capture options (no progress is written): `--level N`, `--city N` (an island after N expeditions; `--open MASK` limits it to those regions, bit per region), `--epoch N` (an island once N epochs of four ladder purchases are bought), `--look X,Y` (centre the island camera on a world point), `--showcase`, `--overview`, `--catalogue [category]`, `--catalogue-page N`, `--catalogue-item ID`, `--catalogue-card ID`, `--building-review N` (four catalogue objects per footprint review page), `--footprints` (every building's footprint and pivot over its sprite), `--placing [blocked|dragging]` (`blocked`: the red ghost over a built wonder; `dragging`: the ghost held up between tiles over the footprint of the tile it will land on), `--zone N`, `--card N`, `--victory`, `--dialog guide|pause|failed|finale|intro|mara|tomas|adrian|bubble|leaderboard`, `--tiles relics|jewels|resources`, `--art-states`, `--art-board`, `--fx shatter`, `--smoke` (plays level one through injected clicks, claims, builds, checks pan/long-press move/cancel/confirm and enters level two), plus the engine's `--shot file.png --frames N`, `--size WxH`, `--fresh` and `--mute`.

## Controls and saved progress

- **Board:** swipe to one of four neighbors, or tap two adjacent relics. Tap a charged socket and then its target. Plus activates as soon as you tap its socket. The top-right medallion pauses: level details, a Sound and Reduce motion group, Resume, Restart (asks first), Quit to island (keeps the board) and the guide; Escape does the same. Tap outside a closable popup to dismiss it; results require an explicit action.
- **Island:** drag the map to pan, including from buildings; pinch or use the mouse wheel to zoom. Tap a building for its card, or hold it still for half a second to pick it up and move it. Tap clouded land to see what opening it needs.
- **Placement:** choose a grassy spot, check the green/red footprint, then confirm or cancel. Leave a tile of open ground between building bases. Footprints cannot cross the shoreline or occupy closed land. Moving a completed building is free.
- **Save:** level progress, resources, opened regions and building positions persist; an unfinished puzzle restarts. Saves of the standalone prototype (`progress.txt`, `localStorage["relic-rush-v1"]`) are not imported.

## Verification

- `make test` runs the original rule regressions, ported: grid invariants, straight lines and rejection of bent, diamond and ring groups, holes and diagonal trickling, chains, tool targeting, playable opening boards, reward claims and construction. The extended campaign test runs with `make test-extended`. The greedy bot must win every board at least once in its seeds, without tools.
- `--smoke` opens and closes the data-backed guide, then drives the real game loop with injected mouse clicks through swaps, cascades, the win dialog, the claim, construction, pan/long-press pickup/cancel/confirm and the start of level two.
- `--smoke --campaign` plays the 100 expeditions through the real result, Claim, region, placement, dialogue and Play controls. Each board's goals are met before one real swap. Every story beat must play once, in script order, and be acknowledged, and the run must end on the finale with the ten story restorations placed and every region open. A stuck story or restoration gate fails it with the level and the beats played so far. It runs in `make test-full` (CI), or alone with `build/test/relic-rush "smoke campaign"`.
- Every screenshot above is rendered by the same code; they were compared side by side with captures of the standalone prototype.
- iPhone and Android device builds, touch feel, safe areas and performance still need device QA.

## Art and text pipeline

Nine matching landmarks have independently registered ground shadows below the
current painted sprites. The courtyard and all 86 repeatable catalogue entries
are preserved. See [building registration](docs/BUILDINGS.md) and the
[reviewed captures](docs/review/painted-buildings/README.md).

Original generated environment paintings, the legacy 10-building sprite sheet and the 6 × 3 tile sheet (`art/tile-sets/source.png`: the Relics, Jewels and Resources packs) are kept as editable sources in `art/`. The 97 current building sprites use the Blender-guided ImageGen atlas and `tools/prepare_buildings.py` (see the building catalogue). `tools/prepare_assets.py` cuts the other sprites out of their sheets (largest opaque component, so neighbouring paintings never leak in), scales backgrounds to what the screen needs and writes PNG/JPG files the engine loads directly. `docs/references.md` records reference research and provenance. Generated art is a prototype asset set and needs an art consistency / IP review before a commercial release.

Fonts: **Lilita One** for the game UI, rendered at runtime by the engine (TrueType with outline, gradient and drop shadow, any Unicode — Cyrillic localisation no longer needs a new atlas); **Lobster** made the gold `title.png` logo and stays in `art/fonts`. Both are unmodified SIL OFL 1.1 fonts with their license text.

## Source layout

Relic Rush and Christmas Market are one game with two skins
([docs/PORTRAIT_GAMES.md](../../docs/PORTRAIT_GAMES.md)). The flow around the
board, every dialog, the shop, the town hooks, story delivery,
effects and the debug entry points are the engine's (`engine/lua/match3/game.lua`,
`engine/lua/match3/vfx.lua`, `engine/lua/match3/debug.lua`); this folder is data and art.

- `lua/game_config.lua`: shared screen copy, board appearance and piece mappings, the piece packs and the dialogue scale.
- `lua/town_config.lua`: the town screen's layout and notices.
- `lua/state.lua`: the shared state table (`R`) from the engine.
- `lua/art.lua`: named authored states, control-state selection and the in-game catalogue.
- `lua/rules.lua`: piece identities, the economy slots and rewards over the engine's match-3 rules.
- `lua/campaign.lua`, `lua/story_content.lua`, `lua/buildings.lua`, `lua/building_sprites.lua`: levels, the script and the building catalogue.
- `lua/journey.lua`: the restoration schedule, recap and changing tap lines.
- `lua/narrative.lua`: the cast.
- `lua/island.lua`: shoreline, the hidden hex region map, region adjacency and the ten story restorations as engine building definitions.
- `engine/lua/match3/screen.lua`: the board screen shared with Christmas Market.
- `lua/screens.lua`: the results card, the guide's rows and icons, and the wallet and compass icons.
- `lua/skin.lua`: the look as data (`ui.skin`).
- `lua/main.lua`: loads the modules and returns the engine's app descriptor.
- `lua/smoke.lua`: the `--smoke` run through injected input, including the engine's `city.move_test`.
- `art/`, `data/`, `docs/`, `tools/`: sources, runtime assets, documentation and the asset pipeline.

## Design references and original assets

- **Cradle of Rome:** excavating puzzle terrain and spending collected resources on visible restoration.
- **Candy Crush:** an earlier reference for animated reward feedback.
- **June's Journey / Pearl's Peril (Wooga):** a large island, player-selected building locations and land expansion, replacing a linear friend-road progression map.
- **Supercell games:** readable building silhouettes, polished resource feedback and a cheerful settlement presentation.
- **Settlers II / Return to the Roots:** a reference for territory represented by small connected land cells. No road-management system or GPL implementation was copied into the game.
- **Canva-style text effects:** inspiration for layered, image-like lettering with gradient fill, a unified outline and shadow.

See [reference research and source links](docs/references.md) and [art prompts and screenshot provenance](docs/art-prompts.md). The island and buildings are original generated prototype artwork; no ripped commercial game assets are bundled. Font licenses are included alongside the font files. Bundled font licenses apply to the fonts. The repository’s existing top-level `LICENSE` is preserved.

## Roadmap and prototype boundaries

Ideas discussed for later development:

- More decorations, alternative buildings, upgrade choices and a richer restoration economy.
- An expedition journal, characters, narrative events and story scenes built around the Lost Valley premise.
- Visiting friends' settlements; optional asynchronous raids were discussed as an exploratory idea, not an implemented or committed feature.
- Backend accounts, cloud saves and social progression if those features are pursued.
- Human playtesting, campaign balancing, sound design, haptics and more responsive device-specific polish.
- Localization; app icons, safe-area validation, mobile performance checks and signed iOS/Android releases. The standalone prototype's Android/iOS host projects were not carried into this repository; mobile packaging is to be set up once for the shared engine.

The offline prototype has 100 square boards, twenty campaign purchases, repeatable scenery, six regions and local saves.

## Fast rule tests

Run `make test-relic-rush` from the repository root for this game's tests in one command. The Lua suites use deterministic state injections and need no window or artwork. See [the testing guide](../../docs/TESTING.md) for coverage, test-only `ENGINE_TEST` hooks, extended samples and renderer smoke checks.

Board artwork fills its registered square slots. Dialogue portraits slide/fade in and out, and only brighten/dim on speaker changes; no resizing, rotation or idle wobble; the engine owns those transitions. See [motion review](../../docs/review/motion/README.md).

Level entrances provide grouped haptic ticks as gems land and a stronger pulse for
blockers. The touch opening a level cannot skip its entrance; a new tap during
the entrance can. Reduced motion and skipped entrances omit these landing effects.
Building previews show a round × on the lower left and ✓ on the lower right of
the building. Dragging, panning and zooming keep these controls with the preview;
✓ is disabled on blocked land. Cancel preserves the original building and wallet.
Popups (Pause, results, guide, cards) and their backdrops appear and close
immediately, with no entrance or exit motion; only `--reel` captures still play
the results parts.

Frozen pieces retain a centred **1**/**2** counter above the board layers. Selection uses
a soft mint glow; hints use gold light and sparkles. See the updated Explorer’s
guide.

While moving or placing a building, cream outlines around other buildings show
their occupied ground and clearance for quick alignment. The mover's old spot is
free; guides remain until Confirm/Cancel. See the
[shared placement-guide review](../../docs/review/city-placement-guides/README.md).

## Town screen

The island is the engine's [shared town screen](../../docs/TOWN.md), laid out by
`lua/town_config.lua`. Tapping a building shows its name in a word bubble; holding
it for half a second lifts it to move.

The town row draws Build, Play, Levels and Pause as enamel buttons sized to their
slots. A single [painted strip](../../art/match3-buttons/README.md) supplies the
128×128 action icons. The board draws its own bonus pieces on the same buttons.

For a local story walkthrough, launch `./build/relic-rush --debug-walkthrough`.
Tap **Skip level** at the top right of the board, read any scene, then claim the usual reward.
On the island, **Advance** places an earned story building or starts the next board.
The walkthrough has its own save. Add `--fresh` to start at the opening without saving.

### Board

Two straight axes and five pieces form the square board. Papyrus cells and rounded sandstone trim define the playable outline.
