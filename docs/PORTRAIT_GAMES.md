# Relic Rush and Christmas Market: one game, two skins

Relic Rush and Christmas Market are the same portrait match-3 city game. Both
should differ only in data: Lua settings, levels, campaign and story content, skin and art
tables, and PNGs. Behaviour belongs to the engine:

| Engine module | Owns |
|---|---|
| `engine/match3.lua` (`match3`) | Rules, the board layout, HUD, tools, swaps, waves, the guide and pause forms |
| `engine/board_intro.lua` | The board's entrance, its haptics and the mission banner timing |
| `engine/town.lua` (`town`) | The town screen (`lua/town_config.lua`) |
| `engine/match3_game.lua` (`match3.game`) | The game around the board: the shared state table, progress and saving, level flow, the frame, the town <-> board dive, paint helpers, dialogs (pause, restart, failed, region, building card, finale), the shop, the level list, the town hooks, story delivery and the journey's bookkeeping (`lua/game_config.lua`) |
| `engine/match3_vfx.lua` (`match3.vfx`) | Effects: impacts, waves, halos, score pop-ups and particles |
| `engine/match3_debug.lua` (`match3.debug`) | The screenshot and review entry points (`--level`, `--city`, `--dialog`, ...) |

Each game's `lua/` keeps only:

- **Content:** `campaign.lua`, `story_content.lua`, `buildings.lua`,
  `building_sprites.lua`, `match3_skin.lua`, `match3_hud.lua` (generated or
  authored data), `narrative.lua` (the cast), `journey.lua` (save version,
  recap, region and building lines as tables), `island.lua` (zone names,
  centres, lawn), `rules.lua` (piece names, economy slots and rewards, the `CLEARED` slot),
  `state.lua` (one line: the engine's state table).
- **Skin:** `skin.lua` (the ui.skin), `art.lua` (art contract and review
  sheets), `board.lua` (how cells, pieces and blockers are painted) and the
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

`engine/match3_game.lua` selects the engine's default portrait-game dialogue
layout, drawn by `engine/story.c`. On phones the engine puts the portraits at
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
`--story-choice after-10` to preview the Relic Rush prompt.

A game can play a short board-specific scene before dialogue and
Results. `R.clear_scene()` returns the active scene and `R.draw_clear_scene(scene, inp)`
draws it. The game owns first-clear eligibility, timing, and any skip input.
Relic Rush uses this for the light on board 3 and Ines's reply on board 30.

Results keep the board HUD in the blurred background so the card title and
actions have a clear foreground.

Both games support `--debug-walkthrough`. Skip level opens the normal results.
Advance confirms an earned restoration or opens the next board. The
walkthrough uses its own save and does not report scores to Game Center.

## Inventory (November 2026)

Every difference between the two games' copies, sorted into content, skin,
or accidental drift. Line counts are `diff` lines before this work.

### Accidental drift (behaviour one game lacked)

Fixed in the engine, so both games now behave the same way:

| Behaviour | Was in | Missing from | Now |
|---|---|---|---|
| Popups open and close at once, with no entrance or exit tween (a stalled clock on device left Pause's dim with no panel, commit 7122d63); modal backdrops snap in (`snap_backdrop`), so the shop and level list are dimmed on their first frame | Relic Rush | Christmas Market (tweened every dialog; its lists showed an undimmed first frame) | Both, `match3.game` dialogs and lists |
| Pause shows Restart (asks first) and Quit, which keeps the unfinished board for the level list | Relic Rush | Christmas Market (the smoke test even asserted they were absent) | Both; Christmas Market's skin gains an evergreen `secondary` button |
| The level list opens scrolled to the current board | Christmas Market | Relic Rush (always opened at level one) | Both |
| Choosing a level clears the overlay before `play_level`, so a refused start does not leave a dead overlay state | Christmas Market | Relic Rush | Both |
| The building card shows the story's current line for the building (`journey.building_about`), as the tap bubble does | Christmas Market | Relic Rush (showed the static catalogue line) | Both |
| Per-level backdrop scene (`level.background`) | Relic Rush | Christmas Market (hard-coded "level 5 and on") | Both read `level.background` with the same fallback |
| `--talk-through`, `--scroll-review`, `--placing focused`, `--dialog confirm` debug entry points | Relic Rush | Christmas Market | Both |
| `--present`, `--goals-met`, `--dialog bubble` with the story's words, `--victory clue`, debug wallets without legacy slots | Christmas Market | Relic Rush | Both |
| `R.expand()` (open the next region from code) | Relic Rush | Christmas Market | Both |
| Board entrance haptics (`R.intro_haptics`) | Relic Rush | Christmas Market | Both (fixed earlier in `engine/board_intro.lua`) |

### Intentional skin

Kept per game, as data or painting code:

- `skin.lua`: jade vs festive red buttons, authored navigation images vs drawn
  badges, wallet pill opacity and em, moves colours.
- `board.lua`: Relic Rush draws ice as a floor tile with full ice over the
  piece; Christmas Market draws snow and tinsel edge art below the
  treats (blockers before pieces), rotated selection/hint frames, per-kind
  piece lift (`art.piece_lift`) and drifting snow instead of sun motes.
- `screens.lua`: the results card (Relic Rush's breakdown vs Christmas
  Market's chips), guide rows and icons, wallet icons.
- Speech style: Relic Rush's dialogue is 1.5× (`speech.scale` in game_config.lua)
  with a 22.5 name plate; Christmas Market uses 1× and 15.
- `art.lua`: review sheets, packs (`relics`/`jewels`/`resources` vs
  `festive`), the hud catalogue, `piece_lift`, `snow_source`.
- `island.lua`: Relic Rush's lawn is a polygon and its fog has clouds;
  Christmas Market's is a rectangle with paths and blue fog.
- The town's middle button icon.

### Content and data

- Words: every notice, dialog title, button label, catalogue and level-list
  line, pause title, failed, region and finale text (now `lua/game_config.lua`).
- `campaign.lua`, `story_content.lua`, `narrative.lua` cast, `journey.lua`
  recap/regions/building lines, `buildings.lua`, `building_sprites.lua`,
  `match3_skin.lua`, `match3_hud.lua`, zone names and positions.
- Shop categories, save version, kudos words, tool notes, the locked
  notice, title and id.
- Christmas Market opens on the market (`start_on_town`) and plays the
  opening scene there.
- The results card's words stay in `screens.lua` with its painting.

## Not yet shared

Follow-ups, tracked here until done:

- `board.lua` still has two painting paths; a data-driven cell/blocker style
  (edge art, badge, layering) would make it one.
- The results card and guide icons are two hand-painted layouts.
- The smoke tests are separate scripts keyed to each game's content
  (`lua/smoke.lua` in both; Christmas Market's moved out of `main.lua`).
- `island.lua`'s region map logic is copied; only its data differs.
