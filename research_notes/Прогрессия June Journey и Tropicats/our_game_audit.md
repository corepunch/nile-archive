# Audit of our own repository: what exists today for a full game loop

Audited on 2026-11-02 at checkout `resource-panels` @ `c3b507b`. An earlier transcript says this tree was merged to `main` as `d791fe8` ("its tree is identical"); the local `main` ref is still behind, at `f31d782`. Read-only code and doc audit: no builds, tests or game runs. Links are relative to this file and point at line numbers in that commit. Calculations of mine are labelled.

## Which game is the target?

### Takeaway
The evidence points to Relic Rush as the main target: it is the only game with both match-3 levels and active recent work, and it is the genre match for Tropicats. Nile Archive is the genre match for June's Journey (hidden-object scenes plus an island), but it has no puzzle levels in the match-3 sense. So the two references map to two different games, which the report should state plainly.

### Cited Findings
- Relic Rush is "a portrait mobile-first hex match-3 / island-restoration prototype" — [relic-rush/README.md:7](../../games/relic-rush/README.md#L7).
- Its references call Tropicats the "direct match-3 plus island restoration reference" and June's Journey / Pearl's Peril "the primary references for the island and buildings" — [references.md:13](../../games/relic-rush/docs/references.md#L13), [references.md:7](../../games/relic-rush/docs/references.md#L7).
- Nile Archive's core is hidden-object chapters feeding an island; its loop references are June's Journey and Pearl's Peril, and Tropicats is not mentioned anywhere in that game's docs — [nile main.lua:1](../../games/nile-archive/lua/main.lua#L1), [PROJECT.md:9](../../games/nile-archive/docs/PROJECT.md#L9); a repo-wide grep finds "Tropicats" only in `games/relic-rush/README.md`, `docs/references.md`, `docs/art-direction-v2.md` and `docs/art-direction-v2-prompts.json`.
- Both share the engine `city` module and the same June's Journey-derived camera ("measured from June's Journey") — [docs/BUILDINGS.md](../../docs/BUILDINGS.md), [PROJECT.md:172](../../games/nile-archive/docs/PROJECT.md#L172).
- Siblings: Christmas Market is "an in-progress" reskin "based on Relic Rush's" systems, with 10 level rows and 37 buildings — [christmas-market/README.md:8](../../games/christmas-market/README.md#L8), [christmas campaign.lua:5](../../games/christmas-market/lua/campaign.lua#L5). Emergency is a separate level-based game with dispatch briefings, not examined further — [emergency main.lua:39](../../games/emergency/lua/main.lua#L39).
- Recent activity: of the last 60 commit subjects, 9 name Relic and 3 name Nile. The newest game-specific work is Relic Rush: `5abc3c7` straight-line rules (2026-11-02), `6827012` catalogues and wallet (2026-11-01) (`git log`). Commits touching each folder: Nile 48, Christmas Market 24, Emergency 2, Relic at least 60 (my query capped at 60).

### Inferences
- The owner's "puzzle levels work, we have many houses" fits Relic Rush best (10 match-3 levels, 96 buildings). Nile also has "many houses" (101 types), but its "levels" are three hidden-object scenes.
- A June's Journey *progression structure* (chapters gated by decoration score) can be mapped onto Relic Rush's match-3 levels; a June's Journey *core mechanic* clone already sits in Nile. The owner should confirm which one is meant, or whether Relic is the product and Nile a sibling.

### Gaps
- No doc names a single clone target. The owner's own statement is the only source of the "cloning" intent; existing docs deliberately say otherwise (see the docs section below).

## Relic Rush: levels, pay, lives, currencies, post-level flow, buildings

### Takeaway
A complete loop exists for exactly 10 hand-authored levels and 10 story buildings, ending in a finale panel. First clears pay the next building's exact price, so amulets never create tension. The 86 decorations cost 11,595 amulets in total but have no effect on progression.

### Cited Findings

**Levels**
- 10 levels, flat list, authored as data: name, lesson, moves, score, idols, sand, chains, ice — [campaign.lua:5-16](../../games/relic-rush/lua/campaign.lua#L5). Each has a hand-written 61-character mask and terrain row — [campaign.lua:19-42](../../games/relic-rush/lua/campaign.lua#L19).
- No level generator exists. `generate_board` only fills gems into a fixed layout from a seed, so a retry gets a new gem layout on the same level — [engine/match3.lua:514](../../engine/match3.lua#L514), [engine/match3.lua:550-569](../../engine/match3.lua#L550), [main.lua:84](../../games/relic-rush/lua/main.lua#L84). `tools/` contains no level tool (only `economy_audit.*`, `capture_economy_review.py`, `luagen.py` matched a search for level/gen/econ).
- The engine accepts any level count (`M.LEVELS = #M.levels`) — [engine/match3.lua:104](../../engine/match3.lua#L104).
- Win: score, idols and sand goals met and no obstacles left. Loss: out of moves — [engine/match3.lua:602-603](../../engine/match3.lua#L602). Tools: 2 charges each of 3 per level — [engine/match3.lua:558](../../engine/match3.lua#L558).

| # | Name | Moves | Score | Idols | Sand | Chains | Ice | Active cells | Goal items per move (my calc) | Grant + spare amulets | Cumulative stars |
|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|---|---:|
| 1 | First Light | 24 | 1100 | 8 | 0 | 0 | 0 | 61 | 0.33 | 60 + 80..120 | 3 |
| 2 | The Jade Crescent | 28 | 1800 | 10 | 7 | 0 | 0 | 54 | 0.61 | 80 + 80..120 | 6 |
| 3 | Sunstone Spiral | 32 | 2300 | 12 | 12 | 0 | 0 | 43 | 0.75 | 100 + 80..120 | 9 |
| 4 | The Vine Constellation | 34 | 2700 | 12 | 10 | 4 | 0 | 45 | 0.76 | 120 + 80..120 | 12 |
| 5 | Three Paths Meet | 36 | 3100 | 14 | 13 | 4 | 0 | 49 | 0.86 | 140 + 80..120 | 15 |
| 6 | Winter Lotus | 38 | 3400 | 14 | 13 | 0 | 5 | 43 | 0.84 | 160 + 80..120 | 18 |
| 7 | The Ember Ring | 40 | 3800 | 16 | 15 | 4 | 5 | 54 | 1.00 | 180 + 80..120 | 21 |
| 8 | Prism Observatory | 42 | 4200 | 16 | 17 | 4 | 6 | 55 | 1.02 | 200 + 80..120 | 24 |
| 9 | The Sixfold Seal | 44 | 4600 | 18 | 19 | 5 | 6 | 55 | 1.09 | 220 + 80..120 | 27 |
| 10 | Heart of the Hexagon | 46 | 5000 | 20 | 22 | 6 | 6 | 53 | 1.17 | 250 + 80..120 | 30 |

Sources: [campaign.lua:6-15](../../games/relic-rush/lua/campaign.lua#L6), [buildings.lua:4-13](../../games/relic-rush/lua/buildings.lua#L4), [rules.lua:36-44](../../games/relic-rush/lua/rules.lua#L36). Levels 7+ use double ice — [campaign.lua:45](../../games/relic-rush/lua/campaign.lua#L45). Level 9's lesson repeats level 5's idea — [campaign.lua:10](../../games/relic-rush/lua/campaign.lua#L10), [campaign.lua:14](../../games/relic-rush/lua/campaign.lua#L14).

**What a level pays**
- `FIRST_GOLD, REPLAY_GOLD, MOVE_GOLD, MAX_MOVE_GOLD = 80, 60, 2, 40` — [rules.lua:16](../../games/relic-rush/lua/rules.lua#L16).
- First clear: next wonder's price + 80 + `min(40, 2 × moves left)` amulets + 3 stars. Replay: 60 + the same bonus, no stars — [rules.lua:36-44](../../games/relic-rush/lua/rules.lua#L36).
- Stars are a flat +3 on first clear, always shown as 3 icons; no 1–3 performance rating exists — [screens.lua:245](../../games/relic-rush/lua/screens.lua#L245), [screens.lua:281](../../games/relic-rush/lua/screens.lua#L281). Result header says "WELL EXPLORED" for every win — [screens.lua:244](../../games/relic-rush/lua/screens.lua#L244).

**Lives**
- 5 lives, one back per 1800 s, including offline — [rules.lua:18-28](../../games/relic-rush/lua/rules.lua#L18). A life goes only when a board is actually lost — [rules.lua:29-34](../../games/relic-rush/lua/rules.lua#L29), [main.lua:120](../../games/relic-rush/lua/main.lua#L120).
- Zero lives blocks every level start, replays included, and sends the player to the island with a toast — [main.lua:83](../../games/relic-rush/lua/main.lua#L83).
- Pause > Restart costs no life — [screens.lua:441](../../games/relic-rush/lua/screens.lua#L441), [screens.lua:452](../../games/relic-rush/lua/screens.lua#L452). Tools and moves carry no paid continuation; there are no extra-move, booster-purchase or premium paths.

**Currencies**
- Live: amulets (purse slot 1), stars (slot 4, never spent), lives. Slots 2, 3, 5 (wood, stone, compass) are reserved for save compatibility — [rules.lua:12](../../games/relic-rush/lua/rules.lua#L12), [rules.lua:17](../../games/relic-rush/lua/rules.lua#L17), [relic README:24](../../games/relic-rush/README.md#L24). The match engine still counts wood and stone (`g.wood`, `g.stone`), but neither is paid — [engine/match3.lua:555](../../engine/match3.lua#L555), [rules.lua:43](../../games/relic-rush/lua/rules.lua#L43).
- HUD shows lives, amulets, stars — [screens.lua:119-126](../../games/relic-rush/lua/screens.lua#L119).

**After a level**
- Win → result dialog → "COLLECT & RETURN" → island with a toast — [engine/match3.lua:786](../../engine/match3.lua#L786), [screens.lua:292](../../games/relic-rush/lua/screens.lua#L292), [main.lua:108-115](../../games/relic-rush/lua/main.lua#L108).
- The next level is blocked until the earned wonder is placed — [island_view.lua:150](../../games/relic-rush/lua/island_view.lua#L150), [main.lua:79](../../games/relic-rush/lua/main.lua#L79). Placing it plays one Tomas line — [island_view.lua:52-55](../../games/relic-rush/lua/island_view.lua#L52).
- Loss → "TRY AGAIN" or "VISIT ISLAND" — [screens.lua:457-464](../../games/relic-rush/lua/screens.lua#L457).
- After level 10 the Play button opens the expedition list, for replays only — [island_view.lua:151](../../games/relic-rush/lua/island_view.lua#L151).

**Buildings and costs**
- 96 entries: 10 wonders, 86 decorations; prices in amulets only — [buildings.lua:3-100](../../games/relic-rush/lua/buildings.lua#L3). Tabulated from that file:

| Category | Count | Total amulets | Min–max price |
|---|---:|---:|---|
| wonder | 10 | 1,510 | 60–250 |
| building | 16 | 5,670 | 200–550 |
| tree | 11 | 1,080 | 30–300 |
| bush | 8 | 225 | 15–45 |
| flower | 8 | 405 | 15–180 |
| statue | 9 | 915 | 30–240 |
| water | 5 | 645 | 45–240 |
| garden | 11 | 1,200 | 30–300 |
| camp | 10 | 900 | 15–180 |
| animal | 5 | 360 | 60–90 |
| rock | 3 | 195 | 15–120 |
| **Total** | **96** | **13,105** (11,595 without wonders) | |

- Star gates for stock run 0–30: 22 items at 0, 12 at 3, 18 at 6, 17 at 9, 9 at 12, 7 at 15, 5 at 18, 2 at 21, 2 at 24, 1 at 27, 1 at 30 (from the same file).
- Decorations carry no `reward` and no story or progression hook; catalogue doc: they "do not count as restorations, trigger story scenes, or advance the campaign" — [buildings.lua:14](../../games/relic-rush/lua/buildings.lua#L14), [building-catalogue.md:12-13](../../games/relic-rush/docs/building-catalogue.md#L12).
- Amulets for earned, unbuilt wonders are reserved from decoration spending — [island.lua:40](../../games/relic-rush/lua/island.lua#L40), [island.lua:46-52](../../games/relic-rush/lua/island.lua#L46).
- Island cap: 160 objects — [island.lua:37](../../games/relic-rush/lua/island.lua#L37), [engine.h:569](../../engine/engine.h#L569). No upgrades, production timers or citizens — [relic README:182](../../games/relic-rush/README.md#L182).
- Land: 6 regions, star gates 0/6/9/15/21/27, zero cost, stars never spent — [island.lua:75-76](../../games/relic-rush/lua/island.lua#L75), [island.lua:184](../../games/relic-rush/lua/island.lua#L184).

### Inferences
- Campaign first-clear total: 1,510 grant + 800–1,200 spare = 2,310–2,710 amulets (my sum). Buying one of every decoration needs 11,595, so about 104–180 replays after a full campaign (my calc: remaining 10,395–10,795 at 60–100 per replay). That is a large unmotivated grind with no progression reason.
- Land opens by first clear of levels 2, 3, 5, 7 and 9 (my calc from stars), which matches the earlier session's result.
- Stars from the last 3 levels unlock little: only 4 stock items sit at 24–30, plus the last land region at 27.
- Because Pause > Restart is free and a life is taken only on a true loss, a player can restart a doomed board before the last move to avoid losing a life. I read this from code and did not run it.

### Gaps
- No measured session length, win rate or time-to-finish exists for human players. The only win data is the bot audit, which is out of date (see the docs section).
- Whether all 10 wonders fit without opening land at each stage: not analysed (placement relies on `find_spot`).

## Nile Archive: levels, pay, currencies, post-level flow, buildings

### Takeaway
Three hidden-object scenes of 8 items each, a clue per scene, no lives. Coins buy buildings, restorations give Influence, Influence plus the previous clue opens the next chapter. This is the closest code to June's Journey's loop, at a scale of 3 chapters, all in Russian.

### Cited Findings
- Scenes: exactly 3, with 8 targets each drawn from a nearly identical item list — [archive_content.lua:10-32](../../games/nile-archive/lua/archive_content.lua#L10), [archive_state.lua:9](../../games/nile-archive/lua/archive_state.lua#L9). Three-chapter logic is hard-coded in `for i=1,3` and `{0,0,0}` — [archive_economy.lua:14-25](../../games/nile-archive/lua/archive_economy.lua#L14), [archive_state.lua:24](../../games/nile-archive/lua/archive_state.lua#L24). No generator; hit ellipses are measured per painting.
- Scoring: 300 per find, -60 per miss, combo up to ×5 within 5 s, hint recharge 20 s, 3 names on show, 3/2 stars at ≤75/≤150 s, always at least 1 star — [archive_state.lua:16-20](../../games/nile-archive/lua/archive_state.lua#L16). There is no loss state. Lives or energy: none (grep for lives/life/energy across `games/nile-archive/lua` returns nothing).
- Pay per completed scene: 80 coins; +40 first clear; +20 per newly improved best star; +20 with no misses or hints — [archive_economy.lua:3](../../games/nile-archive/lua/archive_economy.lua#L3), [archive_economy.lua:33-40](../../games/nile-archive/lua/archive_economy.lua#L33). Scenes pay no Influence.
- Start: 0 coins, 10 Influence, one free house — [archive_economy.lua:3](../../games/nile-archive/lua/archive_economy.lua#L3), [archive_progress.lua:11-18](../../games/nile-archive/lua/archive_progress.lua#L11).
- Chapter gates: Influence 0/20/50 and previous chapter won — [archive_economy.lua:4](../../games/nile-archive/lua/archive_economy.lua#L4), [archive_economy.lua:27-31](../../games/nile-archive/lua/archive_economy.lua#L27).
- Currencies and records: coins (spent), Influence (grows only), chapters and best stars (derived, unspent); a player level is derived from Influence — [archive_state.lua:5-8](../../games/nile-archive/lua/archive_state.lua#L5), [archive_progress.lua:76-80](../../games/nile-archive/lua/archive_progress.lua#L76).
- Five restorations: gardener's house 70/+10, Isis temple 160/+30, archive 130/+25, fountain 60/+10, workshop 100/+15, unlocked by 1 or 2 chapters and repeatable — [archive_economy.lua:5-11](../../games/nile-archive/lua/archive_economy.lua#L5), [archive_content.lua:45-51](../../games/nile-archive/lua/archive_content.lua#L45), [PROJECT.md:95-96](../../games/nile-archive/docs/PROJECT.md#L95).
- 96 catalogue decorations: 15,555 coins in total, gated by best stars 0–9, no Influence — [archive_catalogue.lua](../../games/nile-archive/lua/archive_catalogue.lua), [archive_content.lua:53-65](../../games/nile-archive/lua/archive_content.lua#L53). Non-monument categories cost the same as Relic's slot for slot (11,595); monuments cost 3,960 versus Relic's 1,510 wonders (tabulated from both files).
- Land: 4 zones; shores cost 120/180/240 coins and need 1/2/3 chapters; optional for clues — [archive_economy.lua:12](../../games/nile-archive/lua/archive_economy.lua#L12), [archive_island.lua:36-40](../../games/nile-archive/lua/archive_island.lua#L36).
- After a scene: clue dialogue (first time) → win dialog with payout breakdown and clue → "Строить за монеты" if Influence is short, otherwise "На остров" — [archive_scene.lua:142-149](../../games/nile-archive/lua/archive_scene.lua#L142), [archive_dialogs.lua:33-70](../../games/nile-archive/lua/archive_dialogs.lua#L33).
- After chapter 3 the island goal reads "АРХИВ СОБРАН / Переиграйте главы на три звезды"; there is no ending screen — [archive_island.lua:88](../../games/nile-archive/lua/archive_island.lua#L88).
- Audit's minimum story path: 3 clears, 2 builds, 220 coins, 50 Influence — [economy-audit.json:8-13](../../docs/economy-audit.json#L8).

### Inferences
- Decorations in Nile are also purely cosmetic, so neither game currently has "decorate to unlock story". June's Journey's flowers map onto Influence, but only the five restorations grant it.
- One of everything costs about 15,555 coins, so about 156–195 replays at 80–100 coins (my calc, ignoring first-clear pay).

### Gaps
- Human session length unmeasured. PROJECT.md says a full iPad/Safari run is unconfirmed — [PROJECT.md:193](../../games/nile-archive/docs/PROJECT.md#L193).

## Story, dialogue, cutscenes, chapters

### Takeaway
The engine has a good dialogue primitive (cast, portraits, typed lines, once-per-save beats) but no chapter, journal, branching or cutscene system. Content is tiny: Relic Rush has 26 unique lines and Nile Archive 7, of which Relic's are mostly tutorial text or building descriptions.

### Cited Findings
- Engine API: `story.setup`, `play` (a beat "once per save"), `say`, `add`, `active`, `next`, `seen`, `frame`, `serialize`, `forget`, plus `bubble`; bubble kinds SPEECH/THOUGHT/SHOUT — [engine/api.xml:468-480](../../engine/api.xml#L468), [docs/LUA_API.md:2094](../../docs/LUA_API.md#L2094). Beats are saved by string key — [main.lua:65](../../games/relic-rush/lua/main.lua#L65), so new beats add naturally.
- No match for "cutscene", "cinematic" or "journal" in `engine`, Relic or Nile Lua (grep). README: "Journal entries, branching choices and cinematics are not implemented" — [relic README:123](../../games/relic-rush/README.md#L123).
- Relic cast: Elena, Mara, Tomas, Adrian — [main.lua:21-30](../../games/relic-rush/lua/main.lua#L21). All `story.*` sites in normal play:
  - Intro, 3 lines (Elena, Mara, Elena) — [main.lua:32-36](../../games/relic-rush/lua/main.lua#L32), [main.lua:195](../../games/relic-rush/lua/main.lua#L195).
  - Level lesson, Elena, 1 line per level (10), tutorial text, 81 words in all — [main.lua:90-92](../../games/relic-rush/lua/main.lua#L90).
  - Wonder, Tomas, 1 line per wonder (10), which is just the building's `about`, 78 words in all — [island_view.lua:55](../../games/relic-rush/lua/island_view.lua#L55).
  - Region opened, Mara, the same line each time — [screens.lua:480](../../games/relic-rush/lua/screens.lua#L480).
  - Finale, 2 lines (Adrian, Elena), then a panel: "The valley lives again / YOU RESTORED ALL TEN WONDERS. / THANK YOU FOR EXPLORING." — [main.lua:38-41](../../games/relic-rush/lua/main.lua#L38), [island_view.lua:56-58](../../games/relic-rush/lua/island_view.lua#L56), [screens.lua:490-496](../../games/relic-rush/lua/screens.lua#L490).
- Adrian's designed role ("may conflict with Elena's" interest) exists only in the cast notes and never appears before the finale — [art-direction-v2.md:41](../../games/relic-rush/docs/art-direction-v2.md#L41).
- `--dialog guide|pause|failed|finale|intro|mara|tomas|adrian|bubble` are debug captures of those same screens, not extra content — [debug_screens.lua:215-225](../../games/relic-rush/lua/debug_screens.lua#L215), [relic README:251](../../games/relic-rush/README.md#L251).
- Relic scenery: two board backgrounds, lagoon for levels 1–5 and temple for 6–10 — [relic README:99](../../games/relic-rush/README.md#L99).
- Nile cast: Nefra, Horem, Merit — [archive_content.lua:67-74](../../games/nile-archive/lua/archive_content.lua#L67). Lines: intro 2, clues 1+1+2, shore 1 = 7 — [archive_content.lua:12-25](../../games/nile-archive/lua/archive_content.lua#L12), [archive_content.lua:77-82](../../games/nile-archive/lua/archive_content.lua#L77). There is a real three-step mystery chain ending open: the father's fate is unresolved and the books "under the temple" are not playable — [PROJECT.md:28-34](../../games/nile-archive/docs/PROJECT.md#L28).
- Chapters or episodes: Relic has none; levels are a flat list, and only a README note says Prev/Next pages "are reserved for future episodes" — [relic README:22](../../games/relic-rush/README.md#L22). Nile's 3 scenes are called chapters; there are no volumes or larger grouping.
- Audio: Relic uses `sfx.tone` synth tones; no `sfx.music/play/load` calls in Relic or Nile Lua (grep). PROJECT.md: no sound or music in Nile — [main.lua:51-53](../../games/relic-rush/lua/main.lua#L51), [PROJECT.md:195](../../games/nile-archive/docs/PROJECT.md#L195).

### Inferences
- Relic: 26 unique authored lines over 10 levels (3 + 10 + 10 + 1 + 2, my count), and only the 5 intro and finale lines (58 words) plus Mara's one are narrative rather than instructions or descriptions. There is no question being answered across the campaign.
- Nile has the better story skeleton per line, since each chapter ends in a clue, while Relic has the better puzzle content.
- The earlier session's figure of about 3.7 June's Journey dialogues per scene (6,050 / 1,650, second-hand) compares with about 2.6 lines per Relic level in total. Relic's are single lines, so if a June's Journey "dialogue" is a multi-line exchange the real gap is wider.

### Gaps
- I did not evaluate how well `story.frame` handles long multi-speaker scenes or backgrounds. No current content tests it beyond 3 lines in a row.

## What's missing to play from start to a "to be continued" ending?

### Takeaway
Both games already run start to end with no dead end, but neither ends on a hook. Relic Rush's main gaps are a chapter layer, a story arc, a purpose for decoration and any content past level 10. No text or screen for "to be continued" exists.

### Cited Findings
- No "to be continued", episode or continuation text in Relic, Nile or engine Lua (grep; the hits were unrelated "Продолжить" buttons).
- Adding Relic levels is not data-only: `reward_breakdown` indexes `wonders[g.level + 1]` and reads `w.cost`, so a level without a matching wonder would hit a nil — [rules.lua:39-40](../../games/relic-rush/lua/rules.lua#L39). `WONDERS = 10` is fixed and bound to level progress — [island.lua:10](../../games/relic-rush/lua/island.lua#L10), [island.lua:39](../../games/relic-rush/lua/island.lua#L39). The finale fires when the wonder count reaches 10 — [island_view.lua:56](../../games/relic-rush/lua/island_view.lua#L56). Result screen also reads a next wonder — [screens.lua:287](../../games/relic-rush/lua/screens.lua#L287).
- Land and stock gates stop at 27 and 30 stars, i.e. level 10 — [island.lua:76](../../games/relic-rush/lua/island.lua#L76), [buildings.lua:29](../../games/relic-rush/lua/buildings.lua#L29).
- Nile needs code changes for more chapters: hard-coded 3 in economy and save records — [archive_economy.lua:14-25](../../games/nile-archive/lua/archive_economy.lua#L14), [archive_economy.lua:4](../../games/nile-archive/lua/archive_economy.lua#L4).
- Docs' own gap statement: "ten puzzle stages and three hidden-object scenes... do not yet have the content breadth of their references, building upgrades, a player-tested mastery curve or live telemetry" — [ECONOMY_RESEARCH.md:211-213](../../docs/ECONOMY_RESEARCH.md#L211). Outstanding QA on devices — [relic README:265](../../games/relic-rush/README.md#L265).
- No store, ads, purchases, backend, events or cloud saves — [relic README:315](../../games/relic-rush/README.md#L315), [PROJECT.md:195](../../games/nile-archive/docs/PROJECT.md#L195).

### Inferences
Missing for a Relic Rush vertical slice, in rough dependency order (my reading, not a plan on file):
1. **Chapter layer:** a data structure grouping levels, a chapter-start and chapter-end beat, and a chapter-aware expedition list.
2. **Decoupling levels from wonders:** so that levels can outnumber story buildings, or new wonders can be added per chapter.
3. **Decoration purpose:** a rank/flower-type value on the 86 existing items and a gate that reads it. Existing assets can serve this with no new art.
4. **Tension in the economy:** first clears currently pay the next build in full, so the "should I replay or decorate?" decision never arises.
5. **Story arc:** a central question, recurring suspects (Adrian exists but is unused), multi-line scenes at chapter ends, and a "to be continued" screen replacing "THANK YOU FOR EXPLORING".
6. **Level content:** more levels and either hand-authoring tools or a generator. Mask and terrain rows are currently hand-typed 61-value tables.
7. **Measurement:** human playtests and refreshed bot audit before tuning.
8. **Optional clone features if wanted:** level difficulty variants (Tropicats), 1–3 performance stars, building timers, boosters, a premium currency. None exist.
9. **Audio:** only synth tones today.

For Nile Archive, the shortest path to a "to be continued" ending is smaller: an ending beat after chapter 3 could close on the open father mystery that already exists. A longer run needs new paintings and hit data per scene.

### Gaps
- Effort per item is not estimated. Art needs (backgrounds per chapter, new cast portraits) are not costed.

## What the repo already knows about June's Journey and Tropicats

### Takeaway
June's Journey is well studied in the docs, using official Wooga support pages. Tropicats is barely covered: four brief mentions, none on economy or story. Standing decisions in the docs explicitly reject timers, energy and extra currencies, which conflicts with a full clone and needs an owner decision.

### Cited Findings
**June's Journey** (all from [ECONOMY_RESEARCH.md:30-35](../../docs/ECONOMY_RESEARCH.md#L30), checked 30–31 October 2026 against official support pages):
- Repeated scenes accumulate mastery toward 5 stars; decoration earns Flowers that open chapters; some buildings generate coins.
- Coins or diamonds buy items; some stock needs an earned star count; construction usually takes time.
- Clouded land usually needs Stars and Compasses — also [references.md:52-53](../../games/relic-rush/docs/references.md#L52).
- A chapter's final Adventure Scene is untimed and needs the chapter's clues plus a star threshold; the next chapter also depends on Flowers.
- Island Errands offer one task at a time as onboarding; Help Wanted cases give replays an economic purpose.
- HUD and visual studies: minimal scene HUD, three item slots, combo scoring — [archive_state.lua:14-19](../../games/nile-archive/lua/archive_state.lua#L14), [REFERENCES.md:7-20](../../games/nile-archive/docs/REFERENCES.md#L7), [references.md:100](../../games/relic-rush/docs/references.md#L100).
- The camera (30° yaw, 40° elevation) was "measured from June's Journey" — [docs/BUILDINGS.md](../../docs/BUILDINGS.md).

**Tropicats** (everything in the repo):
- "direct match-3 plus island restoration reference" — [references.md:13](../../games/relic-rush/docs/references.md#L13).
- One of the games whose level-screen HUD layout was followed — [references.md:67-77](../../games/relic-rush/docs/references.md#L67).
- Art reference: "Welcoming tropical framing, saturated foreground pieces against a quieter background, compact objectives and boosters" — [art-direction-v2.md:11](../../games/relic-rush/docs/art-direction-v2.md#L11), [relic README:99](../../games/relic-rush/README.md#L99).
- ECONOMY_RESEARCH.md does not mention Tropicats at all (grep).

**Standing decisions that a clone would overturn**
- "Use two complementary loops, with unlimited play and instant construction" — [ECONOMY_RESEARCH.md:11](../../docs/ECONOMY_RESEARCH.md#L11).
- "Do not add timers, energy or extra currencies merely because a reference game has them" — [ECONOMY_RESEARCH.md:227](../../docs/ECONOMY_RESEARCH.md#L227); no energy, premium currency, chests, daily login, production timer or purchase backend — [ECONOMY_RESEARCH.md:62-64](../../docs/ECONOMY_RESEARCH.md#L62).
- Nile keeps 3 performance stars rather than 5 mastery stars "without pretending it has the content volume" — [ECONOMY_RESEARCH.md:55-58](../../docs/ECONOMY_RESEARCH.md#L55).
- Relic keeps its own currency identity and does not use spendable restoration Stars — [ECONOMY_RESEARCH.md:49-53](../../docs/ECONOMY_RESEARCH.md#L49).
- IP stance: no Wooga assets, original cast, "Копирование полного коммерческого набора механик, моделей монетизации, интерфейсов и контента не является частью прототипа" — [REFERENCES.md:24-28](../../games/nile-archive/docs/REFERENCES.md#L24).
- Recommended future order: playtest first 15–20 minutes, and "more scenes/levels before larger grind targets" — [ECONOMY_RESEARCH.md:215-225](../../docs/ECONOMY_RESEARCH.md#L215).

### Inferences
- The clone-spec report should present its proposals as reversing or amending these decisions, not as filling blanks.
- "Clone" should mean structure and pacing. The docs and earlier session both recommend not copying story, characters, levels or art.
- The Relic Rush lives system (added after this doc) already departed from "unlimited play", so that rule is not currently enforced by code for Relic.

### Gaps
- The repo holds no June's Journey or Tropicats numbers for level counts, prices or pacing; the docs state public documentation "does not reveal complete difficulty curves" — [ECONOMY_RESEARCH.md:41-44](../../docs/ECONOMY_RESEARCH.md#L41).

## Where docs and code disagree

### Takeaway
ECONOMY_RESEARCH.md, economy-audit.json, references.md and PROJECT.md were all last changed on 2026-10-31, before lives (2026-11-01) and straight-line matching (2026-11-02). Trust code over them. The Relic README is largely current, with a few stale lines; Nile's economy numbers still match code.

### Cited Findings

| Doc says | Code does | Status |
|---|---|---|
| Relic wonders cost Gold, Wood and Stone and pay compasses, with a table of those values — [ECONOMY_RESEARCH.md:87-109](../../docs/ECONOMY_RESEARCH.md#L87) | Amulets only: `cost=purse(60,0,0)`; reward `purse(g,0,0,stars)` — [buildings.lua:4](../../games/relic-rush/lua/buildings.lua#L4), [rules.lua:43](../../games/relic-rush/lua/rules.lua#L43). The Gold column values still match. | Stale |
| Compasses spent on land; 20 compasses cover 5 expansions; gates at costs 2/3/4/5/6 — [ECONOMY_RESEARCH.md:108](../../docs/ECONOMY_RESEARCH.md#L108), [references.md:63](../../games/relic-rush/docs/references.md#L63) | Land is star-gated at zero cost — [island.lua:184](../../games/relic-rush/lua/island.lua#L184) | Stale |
| "unlimited play"; failed attempts have "no financial penalty"; "No lives" — [ECONOMY_RESEARCH.md:11](../../docs/ECONOMY_RESEARCH.md#L11), [ECONOMY_RESEARCH.md:91-92](../../docs/ECONOMY_RESEARCH.md#L91), [references.md:23](../../games/relic-rush/docs/references.md#L23) | 5 lives, 30-minute refill, zero lives blocks play — [rules.lua:18](../../games/relic-rush/lua/rules.lua#L18), [main.lua:83](../../games/relic-rush/lua/main.lua#L83) | Stale |
| T/L intersections make a bomb — [references.md:23](../../games/relic-rush/docs/references.md#L23) | Straight lines only (`LINE_MATCHES`); "Crossing lines do not create bombs" — [rules.lua:4](../../games/relic-rush/lua/rules.lua#L4), [relic README:213](../../games/relic-rush/README.md#L213) | Stale |
| Bot won 199 of 200 — [ECONOMY_RESEARCH.md:204](../../docs/ECONOMY_RESEARCH.md#L204), [economy-audit.json](../../docs/economy-audit.json) | Audit file predates the rule change `5abc3c7` (2026-11-02). Its compass and spare-wood/stone fields are retired too. | Results not valid for current rules |
| UI: "Retrying is always free" — [screens.lua:441](../../games/relic-rush/lua/screens.lua#L441) | True for Pause > Restart; a lost board costs a life first — [rules.lua:29-34](../../games/relic-rush/lua/rules.lua#L29). | Misleading in-game text |
| "Tap a building for its card" — [relic README:256](../../games/relic-rush/README.md#L256) | Taps/picks show a bubble, not a card — [relic README:26](../../games/relic-rush/README.md#L26), [island_view.lua:175-177](../../games/relic-rush/lua/island_view.lua#L175) | README contradicts itself |
| "SHOP", pages, Gold — [building-catalogue.md:3-8](../../games/relic-rush/docs/building-catalogue.md#L3), [relic README:184-187](../../games/relic-rush/README.md#L184) | Image-only Build button and scrolling list; currency is amulets — [island_view.lua:114-118](../../games/relic-rush/lua/island_view.lua#L114), [catalogue.lua:21](../../games/relic-rush/lua/catalogue.lua#L21) | Stale wording |
| Nile has 5 building types — [PROJECT.md:85-91](../../games/nile-archive/docs/PROJECT.md#L85) | 101 types — [archive_content.lua:53-65](../../games/nile-archive/lua/archive_content.lua#L53), [nile building-catalogue.md:3](../../games/nile-archive/docs/building-catalogue.md#L3) | Stale |
| Nile placement is free, without a grid — [PROJECT.md:121](../../games/nile-archive/docs/PROJECT.md#L121) | Snaps to tiles of 34 world units — [archive_content.lua:36](../../games/nile-archive/lua/archive_content.lua#L36), [archive_progress.lua:17](../../games/nile-archive/lua/archive_progress.lua#L17) | Stale |
| Next step: link chapters to preceding clues — [PROJECT.md:203](../../games/nile-archive/docs/PROJECT.md#L203) | Already implemented — [archive_economy.lua:30](../../games/nile-archive/lua/archive_economy.lua#L30) | Stale |
| Nile game "написана на C11" — [PROJECT.md:11](../../games/nile-archive/docs/PROJECT.md#L11) | Game is Lua on the C engine — [PROJECT.md:168](../../games/nile-archive/docs/PROJECT.md#L168) | Stale |

Nile's economy numbers (start values, gates, restoration prices, shore costs, scene pay) do match code — compare [ECONOMY_RESEARCH.md:140-176](../../docs/ECONOMY_RESEARCH.md#L140) with [archive_economy.lua:3-12](../../games/nile-archive/lua/archive_economy.lua#L3).

### Inferences
- Any report citing "199/200 wins" or Relic "Wood/Stone/Compass" budgets as current would be wrong. Rerunning `tools/economy_audit.py` is the fix; out of scope here since builds and tests were excluded.

### Gaps
- I did not audit whether `tools/economy_audit.lua` still runs against the current rules, or read `tests/games/*.lua` in depth.

## Did earlier sessions already do this analysis?

### Takeaway
Yes. The request and a full answer are both in the transcripts, delivered in chat at 13:20 UTC on 2026-11-02 but never saved to any file. It was likely "lost" because it was interleaved with PR-merge work, and the forked merge session said it had not done the research.

### Cited Findings
- The owner's request, sent mid-turn during a PR merge: "find walkthrough of tropicats and junes journey - we want to create good story and levels/buildings/resources balance" — `39657972-fb90-4afb-87f6-ad95933652d2.jsonl`, 2026-11-02T13:17:40Z (the same text is in `73299f0b-...jsonl`, which forks from it).
- Session `39657972` moved the merge to a separate session, ran 4 web searches and 2 fetch subagents, and answered at 13:20:09Z (line 249). It used no Write tool, so nothing persisted. At 13:31:48Z session `73299f0b` ended with: "this session only handled the merge, so it did not do the Tropicats and June's Journey walkthrough research."
- Its opening finding: "I couldn't find a complete written walkthrough for either game, only tips guides, reviews and design breakdowns."
- Its gaps for Relic Rush: "Decoration has no purpose: this is the biggest gap"; "Amulets create no tension"; "There's no central mystery"; "Difficulty only goes up". I re-checked its code numbers against the current code and they hold: 1,510 wonder total, 800–1,200 spare, goal density 0.33/0.86/1.17, land after levels 2/3/5/7/9.
- Its recommendations (labelled "not tested results"): a central question ("who silenced the temple?"), Adrian early as suspect, a reveal every ~5 levels, 3–4 short dialogues per level; a rank value on decorations gating chapters; a harder replay version of each level with an easier one after each spike; keep amulets, stars and lives and add only rank.

**Second-hand web facts from those subagent reports** (not re-fetched by me; other researchers should verify):
- Tropicats — [Wooga blog, 7 Aug 2018](https://www.wooga.com/blog/tropicats-behind-the-scenes-how-a-match-3-level-is-made-977a77ca9b4b): two new chapters with 80 new levels, "240 levels in total"; levels start from a puzzle idea, layout or chain reaction; tested in-house; win/loss data softens or tightens after release.
- Tropicats — [Mog Anarchy review, Jan 2018](http://moganarchy.blogspot.com/2018/01/review-tropicats.html): totem chopped down by an unknown vandal, earthquake, player as chief finds the culprit and rebuilds; each level has easy, medium and hard variants; hard levels replay for coins, diamonds and tournament points; decorations raise village rank.
- Tropicats — [App Store](https://apps.apple.com/app/id1215220850): Olivia, Elsie, Kip; Great Totem mystery. [Gamezebo](https://www.gamezebo.com/walkthroughs/tropicats-tips-cheats-and-strategies/): coins, blue diamonds, Village Rank; diamonds continue after running out of moves.
- June's Journey — [Naavik, Nov 2023](https://naavik.co/deep-dives/junes-journey-hidden-object-game/): weekly chapter since 2018; volumes 1–5 have 100/50/25/35/35 chapters; 275 chapters, ~1,375 scenes, 275 puzzles, 6,050 dialogues; no loss condition; free hint every 30 s; Lighthouse landmark 20 levels at ~2 weeks each.
- June's Journey — [Game Developer, Apr 2020](https://www.gamedeveloper.com/design/june-s-journey-breakdown): coins, diamonds, energy, stars, daffodils; clues at about stars 2 and 4; 5 stars = Mastery; star boxes. [Level Winner, Feb 2024](https://www.levelwinner.com/junes-journey-guide-tips-cheats-solve-puzzles/): ~110 energy, 15 per round, 1 per 2 minutes; decor waits 2–12 hours; area unlocks need compasses plus stars.
- Reported source problems: energy-ad duration conflicts (10 vs 30 minutes); flowers vs daffodils; June's Journey fan wiki returned HTTP 402; the [ChapterCheats playlist](https://www.chaptercheats.com/cheat/android/376813/tropicats-puzzle-paradise/video-walkthrough/184037) names a different publisher (Mantis Shrimp GmbH, 2016), though its titles such as "Level 40 (EASY)" fit the difficulty variants; no Tropicats building costs, life-refill times or obstacle order found.

### Inferences
- The new report should build on that answer, not redo it. Its largest additions would be level-by-level progression data, which the earlier run could not get from text sources.
- "240 levels in total" alongside "80 new levels" and three difficulties may mean 80 × 3 counted as 240. That is my reading of the second-hand summary, not something the source was reported to say.

### Gaps
- No level-by-level walkthrough data for either game; the earlier session reports that this "would mean playing the games or watching footage".
- The two transcripts are the only ones I was asked to search. A grep shows no other session besides the current one mentions Tropicats.
