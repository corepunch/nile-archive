# Relic Rush and Christmas Market: one game, two skins

Relic Rush and Christmas Market share the portrait puzzle and city engine.
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
- **Tests:** `smoke.lua` and Christmas Market's `campaign_smoke.lua`, keyed
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
`game_config.lua` uses to place it in the wallet row. Relic Rush and Christmas Market supply price entries
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

## Story progression and previews

Relic Rush and Christmas Market advance through board clears, story beats and
confirmed placement of required buildings.

A journey can show first-clear dialogue before Results with `clear_before_result`
and schedule a separate `restore` scene after placement. A beat with choices
uses the shared form and modal stack. The selection is saved before the reply
plays, and the scene is acknowledged after the reply finishes. Use
`--story-choice restore-16` to preview the Relic Rush prompt.

A game can play a short board-specific scene before dialogue and
Results. `R.clear_scene()` returns the active scene and `R.draw_clear_scene(scene, inp)`
draws it. The game owns first-clear eligibility, timing, and any skip input.
Relic Rush uses this for the light on board 3 and Ines's reply on board 30.

Results keep the board HUD in the blurred background so the card title and
actions have a clear foreground.

### Resident visits and conditional dialogue

Each game's authoring source is the **Town dialogue** section in its `docs/story.md`.
Run its `tools/prepare_story.py` to compile the script into `lua/story_content.lua`.
The following headers come from Lio and Nera's visits, callbacks and meeting.

| Header | What it controls |
| --- | --- |
| `**Placed aviary introduces Lio after-81**` | The invitation and the owned building unlock the introduction. Finishing the introduction unlocks visits. |
| `**Visit aviary after-85**` | A tap offers the latest visit whose checkpoint the player has witnessed. The first visit uses `placed-aviary`. |
| `**Ask personal \| Does he copy you too?**` | The following lines answer that question. Each visit has a personal and a story question. |
| `**With aviary after-91 2**` | The following line replaces line 2 when the aviary stands. If a resident speaks, the compiler also requires their introduction. |
| `**If asked after-85 personal**` | Within that replacement, use the following reply if the player heard this particular answer at this building. |
| `**If seen after-85**` | Within a replacement, use the following reply if the player witnessed this earlier campaign scene. |
| `**Meeting map_room aviary**` | A one-time town conversation between the residents of these two buildings. Both must have finished their introductions. |
| `**If asked map_room after-67 personal 2**` | Replace line 2 of the meeting if the player heard Nera's personal answer at this checkpoint. Either resident can deliver the changed line. |
| `**Ask at aviary \| Did your sister like the portrait?**` | After the meeting, add this question to Lio's visits. Put the answer below it, and give the other resident their own `Ask at` block. |

Several lines in a scene can each have a `With` block. Within one block, write the ordinary
building reply first, then the conditional replies in priority order. The first satisfied
condition wins. If none match, the resident gives the ordinary reply. If the building or
introduction is missing, the original campaign line plays. The compiler checks line numbers,
speakers, duplicate conditions and references to earlier scenes and questions.

The journey reads the town's ownership and the player's saved story history when a scene
starts. Resolving lines never changes either. Finishing a visit answer or pressing Skip
records its stable key. The roof bubble and future dialogue both consult that record.
Question wording and display order can change independently of the key. Building, checkpoint
and topic identifiers are part of the save format. The original one-answer visit key still
credits the story question in older saves.

Write the meeting as a complete exchange that works when the player has visited neither
resident. Choose an earlier visit for a memory the player can discover before the second
resident arrives. The listed order of the two building keys identifies the meeting in saves.
Older towns with both residents can see it on their next return. Finishing or skipping the
scene records it. Leaving midway makes the whole exchange available again.

Put the follow-up questions at the end of the meeting. Each building can have one per
meeting. The answer stays on that resident's menu as the ordinary questions change.
Each roof marks its own unheard answers, including follow-ups in existing towns.

Preview the ordinary reply with `--story-beat after-91 --story-built --story-line 2`.
Add `--story-asked` for the first conditional reply at or after that line, or
`--story-when visit-aviary-after-85.personal` for a particular saved condition.
The scenario overview lists the alternatives in the same priority order.

## First launch and main menu

A fresh profile opens directly on level 1. Christmas Market plays Noelle's
opening scene there before the board is playable. Collecting a first-clear
reward takes the player to the island or market, where they can spend the
resources on construction.

Later launches and the Main Menu link in in-game Settings open the illustrated
title screen. Continue returns to the parked board or town in the current
session. After relaunch, Continue opens the campaign checkpoint and honors
unclaimed results and pending town scenes. Christmas Market returns to the
market after the first clear. Visit Island or Visit Market appears once the
player has a clear and Continue would go to a playable board. Settings shares
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

## Walkthrough

Both games support `--debug-walkthrough`. Skip level opens the normal results.
Advance confirms an earned restoration or opens the next board. The
walkthrough uses its own save and does not report scores to Game Center.

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
| Popups open and close at once, with no entrance or exit tween (a stalled clock on device left Pause's dim with no panel, commit 7122d63); modal backdrops snap in (`snap_backdrop`), so the shop is dimmed on its first frame | Relic Rush | Christmas Market (tweened every dialog; its lists showed an undimmed first frame) | Both, `match3.game` dialogs and lists |
| Pause shows Restart (asks first) and Quit, which keeps the unfinished board for Play to resume | Relic Rush | Christmas Market (the smoke test even asserted they were absent) | Both; Christmas Market's skin gains an evergreen `secondary` button |
| Play shows the number of the level it starts; there is no level list, so a cleared level is not replayed, and once every level is cleared the "You won" card opens after the last win and from Play | New | Both had a Levels button and list | Both |
| Choosing a level clears the overlay before `play_level`, so a refused start does not leave a dead overlay state | Christmas Market | Relic Rush | Both |
| The building card shows the story's current line for the building (`journey.building_about`), as the tap bubble does | Christmas Market | Relic Rush (showed the static catalogue line) | Both |
| Per-level backdrop scene (`level.background`) | Relic Rush | Christmas Market (hard-coded "level 5 and on") | Both read `level.background` with the same fallback |
| `--talk-through`, `--scroll-review`, `--placing focused`, `--dialog confirm` debug entry points | Relic Rush | Christmas Market | Both |
| `--present`, `--goals-met`, `--dialog bubble` with the story's words, `--victory clue`, debug wallets without legacy slots | Christmas Market | Relic Rush | Both |
| `R.expand()` (open the next region from code) | Relic Rush | Christmas Market | Both |
| Board entrance haptics (`R.intro_haptics`) | Relic Rush | Christmas Market | Both (fixed earlier in `engine/lua/board_intro.lua`) |

### Intentional skin

Kept per game, as data or painting code:

- `skin.lua`: jade vs festive red buttons, authored navigation images vs drawn
  badges, wallet pill opacity and em, moves colours.
- `game_config.lua` and the skin atlases supply the piece mappings, piece
  size, background and motes. Both boards use the same cell coordinates,
  blocker layering and perimeter masks. The cells atlas supplies sandstone
  and leaves in Relic Rush, and aged oak and holly in Christmas Market.
- `screens.lua`: the results card (Relic Rush's breakdown vs Christmas
  Market's chips), guide rows and icons, wallet icons.
- Speech style: Relic Rush's dialogue is 1.5× (`speech.scale` in game_config.lua)
  with a 22.5 name plate; Christmas Market uses 1× and 15.
- `art.lua`: review sheets, packs (`relics`/`jewels`/`resources` vs
  `festive`) and the HUD catalogue.
- `island.lua`: Relic Rush's lawn is a polygon and its fog has clouds;
  Christmas Market's is a rectangle with paths and blue fog.
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
  (`lua/smoke.lua` in both; Christmas Market's moved out of `main.lua`).
- `island.lua`'s region map logic is copied; only its data differs.
