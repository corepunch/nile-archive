# Relic Rush and Christmas at Bellmere: one game, two skins

Relic Rush and Christmas at Bellmere share the portrait puzzle and city engine.
Both match three in a line and spawn five kinds on each board. Board
presentation comes from Lua settings, level data and the skin's PNGs.

| Engine module | Owns |
|---|---|
| `engine/lua/match3.lua` (`match3`) | Rules, the board layout, HUD, tools, swaps, waves, the guide and pause forms |
| `engine/lua/match3/screen.lua` (`match3.screen`) | Draws the board screen, resolves piece art, and binds the shared board input and entrance |
| `engine/lua/match3/elements_view.lua` (`match3.elements_view`) | Draws the floor, perimeter, cell highlights, blockers and piece shadows |
| `engine/lua/board_intro.lua` | The board's entrance, its haptics and the mission banner timing |
| `engine/lua/town/screen.lua` (`town`) | The town screen (`lua/town_config.lua`) |
| `engine/lua/menu/screen.lua` (`menu.screen`) | The illustrated title screen, safe-area layout and form controls |
| `engine/lua/match3/journey.lua` (`match3.journey`) | Campaign scheduling, resident visits, story conditions and saved conversation history |
| `engine/lua/match3/game.lua` (`match3.game`) | The game around the board: shared state, progress and saving, selection of the current screen, dialogs, the shop, town hooks and story delivery |
| `engine/lua/screen_transition.lua` (`screen_transition`) | Screen changes, configured by `transitions` in each game's `lua/game_config.lua` |
| `engine/lua/match3/vfx.lua` (`match3.vfx`) | Effects: impacts, waves, halos, score pop-ups and particles |
| `engine/lua/match3/debug.lua` (`match3.debug`) | The screenshot and review entry points (`--level`, `--city`, `--epoch`, `--dialog`, ...) |

Each game's `lua/` supplies:

- **Content:** `campaign.lua`, `story_content.lua`, `buildings.lua`,
  `building_sprites.lua`, `match3_skin.lua`, `match3_hud.lua` (generated or
  authored data), `narrative.lua` (the cast), `journey.lua` (save version,
  recap, region and building lines as tables), `island.lua` (zone names,
  centres, lawn), `rules.lua` (piece names, economy slots and rewards, the `CLEARED` slot),
  `state.lua` (one line: the engine's state table).
- **Skin:** `skin.lua` (the ui.skin), `art.lua` (art contract and review
  sheets) and the
  parts of `screens.lua` that are art: the results card, guide rows and icons,
  wallet capsule icons.
- **Tests:** `smoke.lua` and Christmas at Bellmere's `campaign_smoke.lua`, keyed
  to each game's content.

Words live in `lua/game_config.lua`, a module returning one table, merged over
`match3.game`'s defaults the way `town_config.lua` is (tables merge field by
field, lists replace).
A game wires itself up in three lines:

```lua
local R = require("match3.game").bind(require("state"))   -- first line of screens.lua
R.dialogs[R.OV_RESULT], R.dialogs[R.OV_GUIDE] = result_screen, guide_screen
return require("match3.game").app(R)                       -- last line of main.lua
```

plus the art hooks `R.wallet_icons()`, `R.town_middle_icon(at)` and `R.cast`.

Games with several currencies supply `R.currency_capsules(balance)` and
`R.currency_prices(cost)`. A capsule's `id` is the name `capsules.show` in
`game_config.lua` uses to place it in the wallet row. Relic Rush and Christmas at Bellmere supply price entries
with a stable ID, name, icon and amount. The shared town and board wallet
targets the appropriate capsule when a match earns a resource.
`R.board_context(preview)` selects a match palette variant from the game state.
Games that bank winnings at Collect call `bind_completed_rewards` and include
its serializer in their campaign save hook. An unclaimed win then resumes
with its matched resources.

`engine/lua/match3/game.lua` selects the engine's default portrait-game dialogue
layout, drawn by `engine/src/story.c`. On phones the engine puts the portraits at
the screen edges, centers the text vertically in a full-width bar, and centers
the speaker's name tag on its top border. Games supply the skin, cast and
dialogue. Cast art faces right and the engine mirrors the right slot.

## Campaign progression and archived dialogue previews

Relic Rush and Christmas at Bellmere advance through board clears and confirmed construction.
Christmas at Bellmere plays tap-through scenes. Noelle introduces the resource loop on the first board, after
the entrance animation and before the first move. Relic Rush uses board hints for its tutorial.

The journey can play first-clear dialogue before Results with `clear_before_result` and
schedule a separate scene after a purchase. Archived Relic Rush scenes can be previewed
with `--story-beat KEY`, optionally with `--story-line N`. Use `--level 1 --story-beat before-01`
to preview the Christmas at Bellmere opening on its board.

The **Town dialogue** section in the Relic Rush script uses `**Placed building_key**`
for a purchase scene. `**With building_key beat-key 2**` replaces line 2 if the building
stands. If the replacement features a resident, it also waits for their introduction.
Run the game's `tools/prepare_story.py` to update `lua/story_content.lua`.

## First launch and main menu

Both games open on the illustrated title screen on every launch. The Main
Menu link in in-game Settings also returns there. Continue in Relic Rush and
Play in Christmas at Bellmere open the phase medals. Back returns to the title.
Play on the medals screen starts level 1 for a fresh profile, resumes the
current board or restores an unclaimed result. Collecting the first reward
takes the player to the island or market to build. Visit
Island or Visit Market gives direct access to construction. Settings shares
the guide, leaderboard and saved Sound and Reduce Motion preferences with
in-game Settings.

The GameTop Windows [Cradle of Rome 2 reference](cradle-of-rome-reference/README.md)
puts a large adventure control in the center of the bottom menu and makes
Options secondary (`settings/scenes/menu/menu.xml` and `menu_controls.xml`).
Its adventure is configured to start at level 1 (`game_settings.xml`).
[Homescapes' official tutorial](https://www.youtube.com/watch?v=GkYNAU6iE6c)
teaches matches on the board, and the [GameTop description](https://www.gametop.com/download-free-games/cradle-of-rome-2/)
ties construction to resources earned through play. The title screens use
that action hierarchy with original portraits of the destinations. The first
puzzle gives the player something to spend before introducing the town.

Use `--main-menu` to preview either title screen and `--opening-town` to see
the seeded town. The direct board and town preview options still open their
requested screen.

## App Store rating

Both campaigns ask for a rating with the App Store's own sheet
(`app.request_review`, iOS only): the game's icon, five stars and Not Now over
the game, in the player's language. Apple shows it at most three times a year
per player, never in TestFlight builds, and does not say whether it showed. A
custom look-alike is not allowed, so the game's part is picking the moment
([match3/rating.lua](../engine/lua/match3/rating.lua)):

- Only a first clear asks, never a replay.
- The first ask comes at the tenth board cleared, or from the sixth when the
  player lost that board and then won it.
- Later asks are at least 25 boards and 30 days apart, three in all.
- The sheet waits until the results are claimed and the player is back in
  town with every card and story line closed and no finger on the screen for
  1.2 seconds. Starting the next board first drops the ask unspent.

The counters live in the settings save, so a new campaign does not ask again.
A game tunes the numbers under `rating` in `game_config.lua`.

Settings also has a permanent **Rate the game** link (iOS), which opens the
review form on the game's App Store page. It needs `app.app_store_id` in
`game_config.lua`.

`--rate` shows the link in a capture, and on a development build on a device
it raises the sheet as soon as the town is idle:

```sh
make ios-relic-rush ARGS='--rate'
```

## Guided board lessons

The first four levels each teach one move on the real board. Level 1
highlights a swap that clears a target with a match of three. Levels 2 and
3 lead the player through making and firing a Line Gem and a Rainbow Gem.
Level 4 highlights the first match through a chain or tie. The player
can swipe or tap both pieces and can skip the lesson at any point.

The opening deal is selected using the ordinary swap and cascade rules so
the special survives and can be used in the next guided move. The board
then continues normally. Replays of cleared levels omit the opening lesson.
The existing guide remains available in Settings.

Construction tools introduce themselves when their pieces appear on the board
and again when their charge first becomes usable. Each rank remembers when
the player has seen these instructions. They use the actual toolbar, board
pieces and stored charge.

The short, highlighted move follows the early hint pattern described in
the [Candy Crush starter guide](https://play.google.com/store/apps/editorial?id=mc_editorialevergreen_post_install_candy_crush_saga_starter_tips_fcp).
Spacing the introductions across boards follows
[Royal Match's opening levels](https://www.youtube.com/watch?v=CA34zG-NWSw).

## Inventory (November 2026)

The two square campaigns use the same board constructor, modular border
renderer and one-use bonus slots. The rules, rank effects and saved charge
live in `match3`, `match3.bonuses` and `match3.game`. The skins supply
tool art and names. Their campaigns place the shared ranks on different
buildings and boards.

Every difference between the two games' copies, sorted into content, skin,
or accidental drift. Line counts are `diff` lines before this work.

### Accidental drift (behaviour one game lacked)

Fixed in the engine, so both games now behave the same way:

| Behaviour | Was in | Missing from | Now |
|---|---|---|---|
| Popups open and close at once, with no entrance or exit tween (a stalled clock on device left Pause's dim with no panel, commit 7122d63); modal backdrops snap in (`snap_backdrop`), so the shop is dimmed on its first frame | Relic Rush | Christmas at Bellmere (tweened every dialog; its lists showed an undimmed first frame) | Both, `match3.game` dialogs and lists |
| Pause shows Restart (asks first) and Quit, which keeps the unfinished board for Play to resume | Relic Rush | Christmas at Bellmere (the smoke test even asserted they were absent) | Both; Christmas at Bellmere's skin gains an evergreen `secondary` button |
| Play shows the number of the level it starts; there is no level list, so a cleared level is not replayed, and once every level is cleared the "You won" card opens after the last win and from Play | New | Both had a Levels button and list | Both |
| Choosing a level clears the overlay before `play_level`, so a refused start does not leave a dead overlay state | Christmas at Bellmere | Relic Rush | Both |
| The building card shows the story's current line for the building (`journey.building_about`), as the tap bubble does | Christmas at Bellmere | Relic Rush (showed the static catalogue line) | Both |
| Per-level backdrop scene (`level.background`) | Relic Rush | Christmas at Bellmere (hard-coded "level 5 and on") | Both read `level.background` with the same fallback |
| `--talk-through`, `--scroll-review`, `--placing focused`, `--dialog confirm` debug entry points | Relic Rush | Christmas at Bellmere | Both |
| `--present`, `--goals-met`, `--dialog bubble` with the story's words, `--victory clue`, debug wallets without legacy slots | Christmas at Bellmere | Relic Rush | Both |
| `R.expand()` (open the next region from code) | Relic Rush | Christmas at Bellmere | Both |
| Board entrance haptics (`R.intro_haptics`) | Relic Rush | Christmas at Bellmere | Both (fixed earlier in `engine/lua/board_intro.lua`) |

### Intentional skin

Kept per game, as data or painting code:

- `skin.lua`: jade vs festive red buttons, authored navigation images vs drawn
  badges, wallet pill opacity and em, moves colours.
- `game_config.lua` and the skin atlases supply the piece mappings, piece
  size, background and motes. Both boards use the same cell coordinates,
  blocker layering and perimeter masks. The cells atlas supplies sandstone
  and leaves in Relic Rush, and aged oak and holly in Christmas at Bellmere.
- `screens.lua`: the results card (Relic Rush's breakdown vs Christmas
  Market's chips), guide rows and icons, wallet icons.
- Speech style: Relic Rush's dialogue is 1.5× (`speech.scale` in game_config.lua)
  with a 22.5 name plate; Christmas at Bellmere uses 1× and 15.
- `art.lua`: review sheets, packs (`relics`/`jewels`/`resources` vs
  `festive`) and the HUD catalogue.
- `island.lua`: Relic Rush's lawn is a polygon and its fog has clouds;
  Christmas at Bellmere's is a rectangle with paths and blue fog.
- The town's middle button icon.

### Content and data

- Words: every notice, dialog title, button label and catalogue
  line, pause title, failed, region and finale text (now `lua/game_config.lua`).
- `campaign.lua`, `story_content.lua`, `narrative.lua` cast, `journey.lua`
  recap/regions/building lines, `buildings.lua`, `building_sprites.lua`,
  `match3_skin.lua`, `match3_hud.lua`, zone names and positions.
- Shop categories, save version, kudos words, tool notes, the locked
  notice, title and id.
- The results card's words stay in `screens.lua` with its painting.

## Not yet shared

Follow-ups, tracked here until done:

- The results card and guide icons are two hand-painted layouts.
- The smoke tests are separate scripts keyed to each game's content
  (`lua/smoke.lua` in both; Christmas at Bellmere's moved out of `main.lua`).
- `island.lua`'s region map logic is copied; only its data differs.
