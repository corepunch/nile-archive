# Christmas Market

From the repository root, `make -C games/christmas-market ios` builds, signs,
installs and launches on a connected iPhone. The native iOS target is iPhone
only. Set `DEVICE="name or UDID"` to choose one. See the
[device deployment guide](../../tools/xcode/README.md#deploy-to-a-connected-iphone-or-ipad).

An in-progress Christmas market game based on Relic Rush's square match-3 and free-placement city systems. The market has 41 buildings and decorations. Smoke rises from nine working chimneys in town. See the [building catalogue](docs/building-catalogue.md).

The first launch opens level 1, where Noelle's opening scene plays over the
puzzle. Collect the first reward to visit the market. Later launches show
the illustrated title screen with Continue and Settings. **Main Menu** in
Settings takes you back to the title. See the
[title screen](docs/screenshots/main-menu.jpg) and [opening board](docs/screenshots/first-launch.jpg).
Both also have [compact title](docs/screenshots/main-menu-phone.jpg) and
[compact board](docs/screenshots/first-launch-phone.jpg) captures.

![The 41 market buildings and decorations](docs/screenshots/buildings.jpg)

The [reference sheet](art/building-reference-sheet.png) covers ten of the twenty campaign stalls: Welcome arch, Lumber workshop, Gingerbread bakery, Hot cocoa kiosk, Toymaker's workshop, Gift wrapping pavilion, Candlelight shop, Reindeer carousel, Winter skating rink and Christmas tree. Lantern firs and Snowman bench are repeatable decorations. The build shop adds 25 more objects in four tabs (Decorations, Snowy trees, Cottages): snowmen, presents, a sleigh, reindeer, a gingerbread house, a giant bauble and more.

Direction: snow-covered timber and cream plaster, evergreen garlands, red ribbons, warm amber windows and lights, cool blue snow, readable isometric silhouettes. The Blender models resolve perspective and footprints exactly. The renders can still guide an ImageGen repaint ([#34](https://github.com/corepunch/nile-archive/issues/34)).

The original transparent building atlas and the labeled reference sheet are preserved in `art/`. Built-in ImageGen produced the artwork. Exact generation prompts are in `art/prompts.json` and `art/reference-sheet-prompt.txt`.

The supplied portrait is now the identity reference for Noelle, the main character (`art/noelle-reference.jpg`). Her transparent cutout is used in dialogue. Her [portrait app icon](art/app-icon-1024.png) is installed in the iOS/macOS `AppIcon` catalogue; its opaque square master leaves corner masking to the OS. `python3 games/christmas-market/tools/prepare_character.py` reproduces the portrait resize and all icon sizes. Built-in ImageGen prompts are in `art/character-and-icon-prompts.json`.

Building cards and their contents lift and fade in together. After a win or
loss, the board fades away before the result card arrives. Cards fade out
before moving on, with instant transitions under Reduce Motion.

Haptics accompany matches, tools, cascades, trickling landings,
results, income collection and confirmed building placement/relocation. Dragging
and previews stay silent. See the [shared haptics contract](../../docs/HAPTICS.md).

The 100 winter wishes use square boards up to 9 × 12. Swap two neighboring treats to match three in a row or column. Every blue pane must light. Single and crossed chains mark treats that need one or two hits before the pane can clear. The last few panes get a trail around their square edges during idle play. The five Advents run levels 1–20, 21–40, 41–60, 61–80 and 81–100, and each board has a tier (levels 1–4 teach, then easy, easy, normal, normal, hard, easy, normal, normal, hard, boss per ten). `python3 tools/square_boards.py christmas-market` validates them, `tools/square_trim.py` trims long ones and `tools/tune_moves.py` fits their move budgets. Every tier uses the median clear × 1.25, rounded up; slow bot samples do not add moves. The [square campaign guide](docs/square-match3.md) lists the levels and artwork.

## Shared match engine and atlas

Each board spawns five piece kinds. Building the Reindeer stable adds the Farrier's hammer. Match 30 to charge a blow on a chosen cell. The Firework stall upgrades that slot to Firework Bomb and carries over its charge. Each campaign purchase adds one piece or tool. [Compare all 20 rewards with Cradle of Rome 2](../../docs/cradle-of-rome-reference/building-rewards.html).

The puzzle and town use the same wallet and blue Settings gear. Each green resource
capsule has the brass rim and drop shadow of the round buttons. The remaining moves
are shown below the wallet on the puzzle. The deep blue tablets mark the objectives on parchment cells, which meet at
hairline seams; cleared tablets return to parchment. Pause opens
the Market Keeper's Guide alongside Sound and Reduce Motion.
[Board palette and guide screenshots](docs/screenshots/review/spruce-palette/README.md).

The board starts in Bellmere's village square. Each of the twenty campaign
buildings changes the backdrop on subsequent wishes after its placement is
confirmed.
The first visit shows the full painting briefly before the board appears.
Tap to skip the entrance. Reduce Motion goes straight to the board fade.
Earlier replays show the setting of their own stage, and later wishes keep
the latest available painting. [Backdrop captures](docs/screenshots/review/construction-backdrops/README.md)

The board's art is one atlas per kind in `data/board/`: `pieces.png` (the
market goods and the earlier festive pieces), `blockers.png`, `cells.png`,
`hud.png` and `fx.png`. Backdrops are separate JPEGs in `data/board/backs/`.
Run `python3 tools/match3_atlas.py` to
rebuild the atlases from the registered sprites in `art/registered/`;
[Asset layout](../../docs/ASSET_LAYOUT.md) describes the folders. The three lantern
panes use the board tiles shared with Relic Rush, which `tools/board_tiles.py`
bakes from `engine/art/board-tiles/tiles.json`.
[Asset catalogue](docs/asset-catalogue.md#lantern-panes).

The market keeps Relic Rush's bottom controls in its own skin: Build (the
shop) on the left, a large Play in the middle showing the number of the next
wish, and Settings on the right. A placement shows Cancel and Confirm beside the building. Snow
falls over the village and moves with it when you pan. Dialogue stands the
speaker (and listener) on a full-width bubble in the middle of the screen.

Building bases need one tile of open ground between them. During placement,
cream guides include that clearance and disappear behind buildings that cover
them. Debug `--footprints` shows the full outline over
each sprite. See the [placement captures](docs/review/placement-guides/README.md).

## Market economy

Silver snowflake coins pay 3 Tokens and gold Sun coins pay 5. Snowy firs, knitted mittens and candy canes earn score on the opening board.
The Welcome arch serves mulled wine for Treats. The Lumber workshop introduces brown pine bundles tied with blue ribbon for Materials.
The bakery and cocoa kiosk upgrade the red Treats piece. Each matched piece pays its own value. Each win
banks the goods cleared on the board. Regions and decorations open by
wishes cleared (the purse's fourth slot, `CLEARED`).

When Noelle arrives, Rosa’s old stall is already standing in Welcome Square.
It’s the last stall her gran ran before retiring, and the market Noelle has
come to reopen starts there. The stall can be moved for free. [Opening market](docs/screenshots/opening-market.jpg)

Confirmed placement spends Tokens, Treats and Materials from that wallet.
The Welcome arch is the first campaign purchase.
The lower-left Build button opens the next stall and shows its price or shortfall. A circling trail signals when you can choose a location. Play another wish to earn the missing resources. The [color map and construction ladder](docs/market-pieces.md) show where the pieces come from and how each purchase follows the Windows edition of Cradle of Rome 2.

There are no lives: a failed wish can be retried at once.
Snow drifts over the village behind the controls. Reduce Motion keeps the
flakes still.

`make run-christmas-market` launches the native draft. `--showcase` previews the
campaign buildings, `--level 4` previews a Christmas puzzle, and `--opening-town`
shows Rosa's stall. The game has an independent `christmas-market` save namespace.
Native macOS and iOS project files are included.

The build shop and Winter Wishes scroll continuously. Swipe inside either list or
use the mouse wheel. Both are full-screen sheets under the wallet row. The shop
lists one building per row with its whole price, an amount you cannot yet cover
in red, and a BUILD button or the reason it waits; it keeps its category
arrows. Winter Wishes opens near the current puzzle. Both screens share row
templates with Relic Rush.

Pause offers Resume, Restart (it asks first) and Quit to the market, which
keeps the unfinished board for LEVEL or Winter Wishes. Popups open and close
at once.

The game is the same as Relic Rush with other data and art
([docs/PORTRAIT_GAMES.md](../../docs/PORTRAIT_GAMES.md)): every word of the
shared screens is in [`lua/game_config.lua`](lua/game_config.lua), and the flow, dialogs,
shop, effects and debug entry points are the engine's
(`engine/lua/match3/game.lua`). The engine draws the board from the market's
skin atlas and `board` settings. `lua/screens.lua` provides the results card
and guide icons.

The interface look (text palettes, panels, the red buttons and their states, focus) is data in [`lua/skin.lua`](lua/skin.lua), compiled by the engine's `ui.skin`; see [skin files](../../docs/UI_ENGINE.md#skins).

Board, HUD and character art is spatially extracted by `python3 games/christmas-market/tools/prepare_assets.py`. Buildings are rendered by `tools/render_buildings.py` and imported by `tools/prepare_catalogue.py`. See the [asset catalogue](docs/asset-catalogue.md) and the [building catalogue](docs/building-catalogue.md).


## Story

The 100 playable wishes run through five Advents. Ten stalls carry the story (Welcome arch, Lumber workshop, Gingerbread bakery, Hot cocoa kiosk, Toymaker's workshop, Gift wrapping pavilion, Candlelight shop, Reindeer carousel, Winter skating rink and Christmas tree) and ten more fill the ladder between them: one purchase every five levels. The [script](docs/story.md) runs five Advents of twenty wishes to Christmas Eve: Noelle arrives to help for Advent, lights the market's lane, and by the last Advent a late passenger and a light to come home to bring everyone together. There is no villain.

Otis Bell brings his clock to the Station Kiosk after wish 46. Ask how he passes the time and he’ll remember whose buttons Pip chose when they wait outside Henrik’s door at wish 63.

Ada Pike arrives from across the lake when the Glassblower’s stall opens. She returns at wishes 74, 84, 89 and 90. Tap the stall to visit Ada after the introduction. Tap the roof bubble or the building to choose what to ask Ada. Each of six story milestones offers a personal question and a question about recent events, including a final pair after the finale. New questions come first, with previously heard answers under “Ask again” when both are available. The bubble stays while any available answer is new. You can return and ask either question again. At wish 90 Ada remembers the cue she and Noelle agreed on at the stall.

Once Otis and Ada have both moved in, a lost draughts button gives them an excuse for a game. Ask Otis why he keeps the dent in his tin and he tells Ada what it means to him.

At the Station Kiosk, ask Otis how the first game went. At the Glassblower’s Stall, ask Ada about her blue button and the winning move.

Pip can ask Ada whether Otis left the double jump on purpose, or ask Otis what Ada’s two pings sounded like from his end of the board. Either answer gives Pip a reason to walk back.

All twenty campaign purchases now have a character response. The ten purchases between story gates trigger a conversation on confirmation. Later dialogue checks whether the building actually stands. Compare `--story-beat after-98 --story-line 2` with the same preview plus `--story-built`, or preview the purchase with `--story-beat placed-sleigh`.

`lua/story_content.lua` is compiled from the script by `python3 games/christmas-market/tools/prepare_story.py`; `--check` catches drift in `make test`. `lua/journey.lua` holds the stall schedule, recap and changing tap lines as data; `lua/narrative.lua` holds the cast. The engine (`engine/lua/match3/game.lua`) keeps the checkpoints and plays the scenes. Preview any scene with `--story-beat before-11`, or `--story-beat after-30 --story-line 15`, and `--frames 240` for fully typed text. All eleven speakers use painted busts. Sources and export commands are in the [asset catalogue](docs/asset-catalogue.md#story-cast). Review captures are in [docs/review/story](docs/review/story/README.md).

## Review and validation

| Snowy market | Festive puzzle | Noelle |
| --- | --- | --- |
| ![Market](docs/screenshots/market.jpg) | ![Puzzle](docs/screenshots/review/spruce-palette/letter.jpg) | ![Dialogue](docs/screenshots/review/market-wishes/opening-390.jpg) |

Build with `make CFLAGS="-O2 -g -Werror" christmas-market build/test/christmas-market`.
Run `build/test/christmas-market --extended "rules campaign_play" "rules christmas" "smoke game" "smoke campaign"`
under Xvfb on Linux. The extended campaign earns its wallet from real
matches and checks the 100 wishes and twenty purchases. The standard
smoke uses real input for a win, construction, building pickup and movement,
decoration shopping, replay and the next level. The campaign smoke prepares
each board and the wallet for one real winning move, then drives Collect,
region opening, construction, dialogue and Play through the end screen.
`rules christmas_story` covers the story scheduler and saved progress.

## Leaderboard

The LEADERBOARD link in Settings opens the overall rankings by winter wishes cleared. The game
updates the total when the player claims a first-clear reward. Use `com.corepunch.christmasmarket.stars`
in [Game Center](../../docs/GAMECENTER.md) and capture the dialog with `--gamecenter-demo --dialog leaderboard`.

| Settings | Merriest markets |
| --- | --- |
| ![Settings with a Leaderboard link](docs/screenshots/pause.jpg) | ![The overall leaderboard](docs/screenshots/leaderboard.jpg) |

![The stars board on a 390x844 phone](docs/screenshots/phone-leaderboard.jpg)

`python3 games/christmas-market/tools/check_assets.py` verifies the 125-file runtime inventory (five of them temporary name-card busts), 37 buildings, all forty authored atlas crops and eleven native icon slots. `python3 games/christmas-market/tools/capture_screenshots.py` reproduces the review captures; pass names such as `market phone-market` to capture a subset. Use `xvfb-run -a` on Linux. CI also builds the iOS Simulator target and the WebAssembly game.

## Fast rule tests

Run `make test-christmas-market` from the repository root for this game's tests in one command. The Lua suites use deterministic state injections and need no window or artwork. See [the testing guide](../../docs/TESTING.md) for coverage, test-only `ENGINE_TEST` hooks, extended samples and renderer smoke checks.

Board artwork fills its registered square slots. In dialogue, portraits face each other and slide into place at the edges of the screen. The same engine layout used by Relic Rush centers the text vertically in the full-width bar. The name tag sits just above the bar, and Skip sits the same distance below it. [Dialogue bar captures](docs/review/dialogue-bar/README.md)

The 0.7-second wipe from town reveals the board as it assembles. If dialogue is playing, the entrance waits for it to end. Cells ripple in, treats fall, blockers land and a light sweeps across the board. Tap to skip the entrance. Reduced motion uses a short fade. See [the engine timeline](../../docs/ENGINE.md#board-entrance).
During refills, each treat gives a small bounce when it comes to rest in its slot. Reduce Motion suppresses the bounce.

Popups use measured vertical forms. Every popup uses the shared title panel. Settings shows the current board as its subtitle during play. Results display Tokens, Treats and Materials in three equal columns, with each icon above a plain number. Above Collect, the card shows the amounts the next stall still needs, its picture once the wallet covers it, or a first clear's story find. In reels the result sections still settle on one timeline, which the first tap skips. See [docs/MOTION.md](../../docs/MOTION.md) and the [dialog motion review](docs/review/dialog-motion/README.md).

![The result dialog arriving](docs/screenshots/reward-entrance-reel.gif)

Placement and move previews show cream ground-footprint guides around the other
buildings, including clearance. Dark contrast edges remain readable on snow.
Guides hide after Confirm/Cancel; the mover's old spot is omitted. See the
[shared review](../../docs/review/city-placement-guides/README.md).

## Town screen

The market is the engine's [shared town screen](../../docs/TOWN.md), laid out by
`lua/town_config.lua`. Tapping a building shows its name in a word bubble; holding
it for half a second lifts it to move.

The town row draws Build, Play, Levels and Pause as enamel buttons sized to their
slots. A single [painted strip](../../art/match3-buttons/README.md) supplies the
128×128 action icons. The board draws its own bonus pieces on the same buttons.

For a local story walkthrough, launch `./build/christmas-market --debug-walkthrough`.
Tap **Skip level** at the top right of the board, read any scene, then claim the usual reward.
On the island, **Advance** places an earned story building or starts the next board.
The walkthrough has its own save. Add `--fresh` to start at the opening without saving.

The Reindeer stable introduces the Farrier's hammer and the Candlelight shop introduces
the lantern. Match them to charge their tools. Stored uses and partial
charge carry between wishes.

### Board

Honey maple, teal panes and brass trim with snowy fir sprigs frame the winter wishes.
