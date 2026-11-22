rules("debug_walkthrough")
rules("town_story")
-- Relic Rush: every test, in one start of build/test/relic-rush. See docs/TESTING.md.
rules("relic_story")
rules("match_matrix")
rules("match3_tutorial")
rules("trickling")
rules("haptics_board")
rules("building_economy")
rules("relic")
rules("relic_board")
rules("portrait_game")
rules("campaign_play")
rules("relic_balance")
rules("balance_bot")
rules("tune_moves")
rules("campaign_layout", ".")
rules("match3_elements")
rules("relic_wallet")
rules("relic_user_events")
rules("upgrades")
rules("relic_leaderboard")
smoke()
smoke("--lua tests/fixtures/portrait-menu;games/relic-rush/lua;.", "portrait-menu")
smoke("--lua tests/fixtures/portrait-menu;games/relic-rush/lua;. --returning --size 390x844 --safe-area 0,47,0,34", "portrait-menu-returning")
smoke("--lua tests/fixtures/portrait-menu;games/relic-rush/lua;. --returning result", "portrait-menu-result")
local tutorial_review = "--lua tests/fixtures/match3-tutorial;games/relic-rush/lua;."
smoke(tutorial_review, "match3-tutorial")
shot("tutorial-match-three", "480x900", tutorial_review .. " --tutorial-lesson 1 --frames 8")
shot("tutorial-rainbow", "390x844", tutorial_review .. " --tutorial-lesson 3 --frames 8 --safe-area 0,47,0,34")
smoke("--debug-walkthrough --lua tests/fixtures/walkthrough;games/relic-rush/lua;. --review-game relic-rush", "walkthrough-pointer", "quick")
smoke("--debug-autoplay --lua tests/fixtures/board-autoplay;games/relic-rush/lua;. --size 240x450", "board-autoplay")
smoke("--campaign --size 240x450", "campaign")   -- same logical phone layout, fewer pixels per frame
smoke("--lua tests/fixtures/ui --data games/relic-rush/data --size 900x700", "ui")

shot("main-menu", "480x900", "--main-menu")
shot("main-menu-phone", "390x844", "--main-menu --safe-area 0,47,0,34")
shot("main-menu-settings", "390x844", "--main-menu --dialog pause --safe-area 0,47,0,34")
shot("debug-board", "480x900", "--debug-walkthrough --level 4 --frames 180")
shot("debug-town", "480x900", "--debug-walkthrough --city 2 --frames 180")
shot("debug-phone-board", "390x844", "--debug-walkthrough --level 4 --frames 180 --safe-area 0,47,0,34")
shot("debug-phone-town", "390x844", "--debug-walkthrough --city 2 --frames 180 --safe-area 0,47,0,34")
shot("story-handoff", "480x900", "--city 4 --look 925,2110 --story-beat after-10 --story-line 2 --frames 240")
shot("story-handoff-phone", "390x844", "--city 4 --look 925,2110 --story-beat after-10 --story-line 2 --frames 240 --safe-area 0,47,0,34")
shot("story-choice", "480x900", "--story-choice restore-16")
shot("story-choice-phone", "390x844", "--story-choice restore-16 --safe-area 0,47,0,34")
-- Line gems and the rainbow gem: both axes of every kind, then one real swap each.
local gems = "--level 30 --special-states "
shot("line-gem-states", "480x900", gems .. "--frames 60")
shot("line-gem-states-phone", "390x844", gems .. "--frames 60 --safe-area 0,47,0,34")
for _, fire in ipairs{"born", "sweep", "cross", "rainbow", "recolor"} do
    reel("line-gem-" .. fire, 12, 4, "480x900", gems .. "--special-fire " .. fire .. " --reel")
end
shot("goal-board", "480x900", "--level 2 --frames 180")
shot("goal-board-phone", "390x844", "--level 2 --frames 180 --safe-area 0,47,0,34")
shot("debug-skip-board", "480x900", "--debug-autoplay --level 2 --frames 180")
shot("debug-skip-board-phone", "390x844", "--debug-autoplay --level 2 --frames 180 --safe-area 0,47,0,34")
shot("construction-backdrop-landing", "390x844", "--level 1 --safe-area 0,47,0,34")
for level=2,97,5 do
    shot("construction-backdrop-" .. level, "390x844", "--level " .. level .. " --safe-area 0,47,0,34")
end
shot("construction-backdrop-fountain-wide", "480x900", "--level 97")
local bonus_review = "--lua tests/fixtures/bonus-toolbar;games/relic-rush/lua;. --level 28 "
shot("bonus-toolbar", "480x900", bonus_review .. "--frames 10")
shot("bonus-toolbar-phone", "390x844", bonus_review .. "--frames 10 --safe-area 0,47,0,34")
shot("bonus-spent", "390x844", bonus_review .. "--spend-bonus --frames 25 --safe-area 0,47,0,34")
shot("bonus-states", "480x900", "--level 28 --art-states bonuses")
local bonus_flight = "--lua tests/fixtures/bonus-toolbar;games/relic-rush/lua;. --level 5 --fly-bonus"
reel("bonus-gem-flight", 23, 4, "390x844", bonus_flight .. " --safe-area 0,47,0,34")
shot("bonus-reduced-motion", "480x900", bonus_flight .. " --flight-no-motion --frames 86")
shot("bonus-hammer-debut", "480x900", "--level 5")
shot("bonus-hammer-debut-phone", "390x844", "--level 5 --safe-area 0,47,0,34")
shot("bonus-mixer-debut", "480x900", "--level 24")
shot("bonus-gear", "480x900", "--level 10 --present --frames 140")
shot("bonus-building-result", "480x900", "--city 4 --victory 9 --debug-walkthrough")
shot("hex-first", "480x900")
shot("hex-late", "480x900", "--level 8")
shot("broken-cable-phone", "390x844", "--level 8")
shot("relay-clear-story", "480x900", "--level 8 --reveal 1 --goals-met --frames 270")
shot("relay-clear-story-phone", "390x844", "--level 8 --reveal 1 --goals-met --frames 270 --safe-area 0,47,0,34")
shot("first-water-phone", "390x844", "--story-beat restore-01 --frames 180 --safe-area 0,47,0,34")
shot("relay-pliers-alternate", "480x900", "--level 8 --tiles resources")
shot("campaign-access", "480x900", "--level 13")
shot("note-collection-phone", "390x844", "--level 13")
shot("note-read", "480x900", "--story-beat after-25 --story-line 1 --frames 120")
shot("note-courtyard", "480x900", "--story-beat restore-61 --story-line 1 --frames 220")
shot("dressing-pump", "480x900", "--level 4")
shot("dressing-quay", "480x900", "--level 5")
shot("dressing-shore", "480x900", "--level 6")
shot("dressing-shore-phone", "390x844", "--level 6 --safe-area 0,47,0,34")
shot("dressing-tools", "480x900", "--level 7")
shot("dressing-tide-room", "480x900", "--level 10")
shot("dressing-wall", "480x900", "--level 15")
shot("choked-gateway", "480x900", "--level 12")
shot("choked-gateway-phone", "390x844", "--level 12 --safe-area 0,47,0,34")
shot("chained-cloisters", "480x900", "--level 44")
shot("chained-cloisters-phone", "390x844", "--level 44 --safe-area 0,47,0,34")
shot("star-chamber", "480x900", "--level 65")
shot("star-chamber-phone", "390x844", "--level 65 --safe-area 0,47,0,34")
shot("valley-temple", "480x900", "--level 100")
shot("valley-temple-phone", "390x844", "--level 100 --safe-area 0,47,0,34")
shot("dressing-states", "480x900", "--art-states dressing")
shot("dressing-lesson", "480x900", "--level 6 --mission --frames 40")
shot("dressing-lesson-phone", "390x844", "--level 6 --mission --frames 40 --safe-area 0,47,0,34")
shot("workshop-lesson", "480x900", "--level 9 --mission --frames 40")
shot("workshop-lesson-phone", "390x844", "--level 9 --mission --frames 40 --safe-area 0,47,0,34")
shot("workshop-before", "480x900", "--level 9 --before-workshop")
shot("workshop-card-phone", "390x844", "--card 3 --safe-area 0,47,0,34")
shot("workshop-story", "480x900", "--story-beat after-10 --frames 240")
shot("workshop-story-phone", "390x844", "--story-beat after-10 --frames 240 --safe-area 0,47,0,34")
shot("dressing-jewels", "480x900", "--level 9 --tiles jewels")
shot("dressing-resources", "480x900", "--level 9 --tiles resources")
shot("supply-collection-phone", "390x844", "--level 9 --frames 3")
shot("landing-briefing", "390x844", "--story-beat before-01 --frames 180 --safe-area 0,47,0,34")
shot("dressing-tide-beat", "480x900", "--story-beat after-10 --story-line 2 --frames 180")
shot("alternate-landing", "480x900", "--level 22")
shot("phone-alternate-landing", "390x844", "--level 22 --safe-area 0,47,0,34")
shot("rome-helmet", "480x900", "--level 14")
shot("rome-ring", "480x900", "--level 18")
shot("rome-sandal", "480x900", "--level 25")
shot("rome-harp-and-shrimp", "480x900", "--level 28")
shot("rome-emerald-resources", "390x844", "--level 30 --tiles resources")
shot("rome-emerald-jewels", "390x844", "--level 30 --tiles jewels")
shot("designed-lanes", "480x900", "--level 4")
shot("designed-lanes-phone", "390x844", "--level 4 --safe-area 0,47,0,34")
shot("designed-chambers", "390x844", "--level 3 --safe-area 0,47,0,34")
shot("delivery-finale", "480x900", "--level 30")
shot("gear-story", "480x900", "--story-beat after-10 --frames 220")
shot("signal-in-exit", "480x900", "--level 30 --reveal 1 --frames 25")
shot("signal-landing", "480x900", "--level 30 --reveal 1 --frames 89")
shot("phone-signal-landing", "390x844", "--level 30 --reveal 1 --frames 89 --safe-area 0,47,0,34")
reel("signal-finale", 34, 7, "480x900", "--level 30 --reveal 1 --reel")
shot("element-states", "480x900", "--element-states")
shot("plaques-phone", "390x844", "--level 5 --safe-area 0,47,0,34")
local tablet_review = "--lua tests/fixtures/tablet-hints;games/relic-rush/lua;. --level 20 --reel"
reel("relic-rush-tablet-hints", 18, 15, "480x900", tablet_review)
reel("relic-rush-tablet-hints-phone", 18, 15, "390x844", tablet_review .. " --safe-area 0,47,0,34")
shot("water-after", "480x900", "--level 5")
shot("water-before", "480x900", "--level 5 --before-well")
shot("harbor-well", "480x900", "--level 5 --present --frames 115")
shot("harbor-well-phone", "390x844", "--level 5 --present --frames 115 --safe-area 0,47,0,34")
shot("harbor-workshop", "480x900", "--level 9 --present --frames 115")
shot("harbor-workshop-phone", "390x844", "--level 9 --present --frames 115 --safe-area 0,47,0,34")
shot("harbor-cable-phone", "390x844", "--level 8 --present --frames 115 --safe-area 0,47,0,34")
shot("harbor-story-opening", "480x900", "--story-beat restore-01 --story-line 3 --frames 180")
shot("harbor-story-plan-phone", "390x844", "--story-beat after-20 --frames 180 --safe-area 0,47,0,34")
shot("quest-board", "480x900", "--level 3")
shot("quest-board-phone", "390x844", "--level 3 --safe-area 0,47,0,34")
shot("quest-board-arrows", "480x900", "--level 6")
shot("quest-board-cable", "480x900", "--level 9")
shot("economy-wallet", "390x844", "--city 2 --safe-area 0,47,0,34")
shot("economy-price-phone", "390x844", "--card 3 --safe-area 0,47,0,34")
shot("economy-shop", "480x900", "--catalogue building")
shot("sawmill-shore", "480x900", "--city 3 --look 925,2195 --footprints")
shot("sawmill-shore-phone", "390x844", "--city 3 --look 925,2195 --footprints --safe-area 0,47,0,34")
shot("economy-result", "480x900", "--city 3 --victory 10")
shot("economy-result-phone", "390x844", "--city 3 --victory 10 --safe-area 0,47,0,34")
reel("relic-rush-plaques", 25, 15, "480x900", "--level 3 --floor-reel oil --reel")
shot("phone-element-states", "390x844", "--element-states --safe-area 0,47,0,34")
shot("floating-hud", "480x900", "--level 9")
shot("phone-floating-hud", "390x844", "--level 9 --safe-area 0,47,0,34")
shot("art-catalogue", "480x900", "--art-states")
shot("hud-states", "480x900", "--level 7 --hud-states")
shot("phone-art-pieces", "390x844", "--art-board --safe-area 0,47,0,34")
shot("art-pieces", "480x900", "--art-board")
shot("correspondence-fish", "480x900", "--level 17")
shot("correspondence-pearl", "390x844", "--level 19 --safe-area 0,47,0,34")
shot("art-jewels", "480x900", "--art-board --tiles jewels")
shot("art-resources", "480x900", "--art-board --tiles resources")
shot("art-phone", "390x844", "--level 8 --safe-area 0,47,0,34")
shot("guide", "480x900", "--dialog guide")
shot("phone-guide", "390x844", "--dialog guide --safe-area 0,47,0,34")
shot("pause", "480x900", "--dialog pause")
shot("phone-pause", "390x844", "--dialog pause --safe-area 0,47,0,34")
shot("leaderboard", "480x900", "--dialog leaderboard --gamecenter-demo")
shot("phone-leaderboard", "390x844", "--dialog leaderboard --gamecenter-demo --safe-area 0,47,0,34")
shot("result-leaderboard", "480x900", "--victory --gamecenter-demo")
shot("phone-card", "390x844", "--card 1 --safe-area 0,47,0,34")
shot("island-village", "480x900", "--showcase")
shot("starter-clearing", "480x900", "--opening-town --frames 8 --footprints")
shot("starter-clearing-phone", "390x844", "--opening-town --frames 8 --safe-area 0,47,0,34")
shot("footprints", "480x900", "--showcase --footprints")
shot("phone-island-placement", "390x844", "--city 6 --placing focused --safe-area 0,47,0,34")

for page = 1, 24 do shot("building-review-" .. page, "480x900", "--building-review " .. page .. " --footprints") end
shot("island-placement", "480x900", "--city 6 --placing focused")
shot("island-blocked", "480x900", "--city 6 --placing blocked")
shot("island-dragging", "480x900", "--city 6 --placing dragging --frames 30")
shot("island-zones", "480x900", "--city 3 --overview")
shot("island-fog", "480x900", "--city 3 --open 3 --look 700,1640")
shot("island-unlock", "480x900", "--city 3 --zone 1")
shot("victory", "480x900", "--victory")
shot("phone-victory", "390x844", "--victory --safe-area 0,47,0,34")
shot("replay-victory", "480x900", "--replay-victory")
shot("result-no-next", "480x900", "--city 1 --victory 2")
shot("stack-failed", "480x900", "--level 4 --dialog failed")
shot("stack-zone", "480x900", "--zone 1")
shot("stack-finale", "480x900", "--dialog finale")
shot("result-layer-480", "480x900", "--victory")
shot("result-layer-390", "390x844", "--victory --safe-area 0,47,0,34")
shot("sawmill-reward-phone", "390x844", "--card 2 --safe-area 0,47,0,34")
shot("build-ready-in-town", "480x900", "--card 0")
shot("building-card", "480x900", "--card 1")
shot("purchase-lodge-480x900", "480x900", "--purchase-card 10 --frames 35")
shot("purchase-lodge-390x844", "390x844", "--purchase-card 10 --frames 35 --safe-area 0,47,0,34")
shot("dialogue-intro", "480x900", "--dialog intro --frames 240")
shot("dialogue-sela", "480x900", "--story-beat before-01 --frames 240")
shot("dialogue-oren", "480x900", "--story-beat restore-01 --frames 240")
shot("dialogue-tavi", "480x900", "--story-beat restore-21 --story-line 2 --frames 240")
shot("island-bubble", "480x900", "--dialog bubble --frames 30")
shot("phone-island", "390x844", "--city 3 --safe-area 0,47,0,34")
shot("phone-board", "390x844", "--safe-area 0,47,0,34")
shot("effect-shatter", "480x900", "--fx shatter --frames 10")
shot("phone-dialogue-intro", "390x844", "--dialog intro --frames 240 --safe-area 0,47,0,34")
shot("phone-dialogue-sela", "390x844", "--story-beat before-01 --frames 240 --safe-area 0,47,0,34")
shot("phone-dialogue-oren", "390x844", "--story-beat restore-01 --frames 240 --safe-area 0,47,0,34")
shot("phone-dialogue-tavi", "390x844", "--story-beat restore-21 --story-line 2 --frames 240 --safe-area 0,47,0,34")

-- Pictures that documentation images are assembled from.
for _, pack in ipairs{"relics", "jewels", "resources"} do
    frame("tiles-" .. pack, "480x900", "--tiles " .. pack .. " --frames 3")
end
for level = 1, 10 do frame("shape-" .. level, "480x900", "--level " .. level .. " --frames 3") end
reel("fx-shatter", 24, 2, "480x900", "--fx shatter --reel")
reel("result", 36, 3, "480x900", "--victory --reel")
reel("relic-rush-level-end", 29, 3, "480x900", "--lua tests/fixtures/level-end;games/relic-rush/lua;. --victory 1 --reel")
frame("ui-skins", "900x700", "--lua tests/fixtures/ui --data games/relic-rush/data --frames 3")
frame("ui-layers", "900x700", "--lua tests/fixtures/ui --data games/relic-rush/data --nested --frames 3")
reel("ui-layer-motion", 9, 3, "900x700", "--lua tests/fixtures/ui --data games/relic-rush/data --nested --reel")
frame("ui-layout", "900x700", "--lua tests/fixtures/ui --data games/relic-rush/data --layout --frames 3")

hold("relic-long-press", "480x900", "240,440", "--city 3 --look 760,1980")
hold("relic-phone-long-press", "390x844", "240,440", "--city 3 --look 760,1980 --safe-area 0,47,0,34")

-- Shared-engine atlas and refill captures: all runs share this test process.
for _, size in ipairs{"480x900", "390x844"} do
    local safe = size == "390x844" and " --safe-area 0,47,0,34" or ""
    for _, mode in ipairs{"vertical", "diagonal"} do
        frame("trickling-relic-rush-"..mode.."-"..size, size,
            "--lua tests/fixtures/trickling;games/relic-rush/lua;. --review-game relic-rush --review-gravity "..mode.." --fall-time .04"..safe)
    end
end
-- Game packs/states already have canonical shots above. Only the engine's
-- default skin needs separate captures; review exporters reuse those shots.
for _, size in ipairs{"480x900", "390x844"} do
    local safe = size == "390x844" and " --safe-area 0,47,0,34" or ""
    frame("resource-icons-default-"..size,size,"--default-match3 --level 7"..safe)
end
frame("resource-icons-default-board-states","480x900","--default-match3 --level 7 --art-states")
frame("resource-icons-default-hud-states","480x900","--default-match3 --level 7 --hud-states")

for _, size in ipairs{"480x900", "390x844"} do
    local safe = size == "390x844" and " --safe-area 0,47,0,34" or ""
    local opts = "--lua tests/fixtures/dialogue;games/relic-rush/lua;."..safe
    frame("portrait-speaker-"..size,size,opts.." --frames 20")
    frame("portrait-listener-"..size,size,opts.." --frames 45")
end
reel("portrait-transitions", 42, 2, "390x844", "--lua tests/fixtures/dialogue;games/relic-rush/lua;. --safe-area 0,47,0,34")
frame("portrait-same-side-390x844", "390x844", "--lua tests/fixtures/dialogue;games/relic-rush/lua;. --safe-area 0,47,0,34 --same-side --frames 45")
reel("relic-rush-board-intro", 18, 6, "480x900", "--level 5 --present --reel")
reel("relic-rush-town-dive", 48, 4, "480x900", "--city 3 --dive --dive-back 120 --reel")   -- Play: the town dives into the board and back
reel("relic-rush-phone-board-intro", 12, 8, "390x844", "--level 9 --present --reel --safe-area 0,47,0,34")
local shuffle_review = "--lua tests/fixtures/shuffle;games/relic-rush/lua;tests/lua;. --reel"
reel("relic-rush-board-shuffle", 16, 4, "480x900", shuffle_review .. " --level 7")
reel("relic-rush-mixer-shuffle", 16, 4, "390x844", shuffle_review .. " --level 24 --shuffle-mixer --safe-area 0,47,0,34")
-- A swipe into a blocker: the free gem slides halfway and back.
local reject_review = "--lua tests/fixtures/swap-reject;games/relic-rush/lua;. --reel"
local chain_review = reject_review .. " --level 6"   -- the first board with chains over plaques
reel("chain-reject", 8, 4, "480x900", chain_review)
reel("chain-reject-phone", 8, 4, "390x844", chain_review .. " --safe-area 0,47,0,34")
reel("ice-reject", 8, 4, "480x900", reject_review .. " --level 7 --block ice")
reel("stone-reject", 8, 4, "480x900", reject_review .. " --level 15 --block stone")
reel("dialogue-to-board", 30, 8, "480x900", "--dialog intro --talk-through 45 --reel")
frame("entrance-settled-relic-rush-480x900", "480x900", "--level 5 --present --frames 180")
frame("entrance-settled-relic-rush-390x844", "390x844", "--level 5 --present --frames 180 --safe-area 0,47,0,34")

-- Building art must ride the popup; each top edge cell supplies the refill.
for _, size in ipairs{"480x900", "390x844"} do
    local safe = size == "390x844" and " --safe-area 0,47,0,34" or ""
    reel("relic-rush-building-entrance-"..size, 16, 3, size, "--card 1 --reel"..safe)
    reel("relic-rush-top-edge-refill-"..size, 16, 3, size,
        "--lua tests/fixtures/trickling;games/relic-rush/lua;. --review-top-edge --reel"..safe)
end

-- Continuous catalogues, including narrow safe-area layout.
shot("catalogue", "480x900", "--catalogue building")
shot("phone-catalogue", "390x844", "--catalogue building --safe-area 0,47,0,34")
shot("shop-status", "480x900", "--catalogue all")
shot("phone-shop-status", "390x844", "--catalogue all --safe-area 0,47,0,34")

reel("phone-catalogue-scroll",24,3,"390x844","--catalogue all --scroll-review --safe-area 0,47,0,34")
shot("phone-island-bubble","390x844","--dialog bubble --safe-area 0,47,0,34")

-- Full-script representative reads: longest line, thought, shout and the finale.
shot("story-opening", "480x900", "--story-beat before-01 --frames 240")
shot("phone-story-opening", "390x844", "--story-beat before-01 --frames 240 --safe-area 0,47,0,34")
shot("story-longest", "480x900", "--story-beat restore-61 --frames 240")
shot("phone-story-longest", "390x844", "--story-beat restore-61 --frames 240 --safe-area 0,47,0,34")
shot("ferry-pilot", "480x900", "--story-beat restore-21 --story-line 2 --frames 240")
shot("ferry-pilot-phone", "390x844", "--story-beat restore-21 --story-line 2 --frames 240 --safe-area 0,47,0,34")
shot("story-shout", "480x900", "--story-beat after-28 --frames 240")
shot("phone-story-shout", "390x844", "--story-beat after-28 --frames 240 --safe-area 0,47,0,34")
shot("story-finale", "480x900", "--story-beat after-100 --story-line 3 --frames 240")
shot("grain-lenders", "480x900", "--story-beat after-25 --story-line 1 --frames 240")
shot("phone-grain-lenders", "390x844", "--story-beat after-25 --story-line 1 --frames 240 --safe-area 0,47,0,34")
shot("phone-story-finale", "390x844", "--story-beat after-100 --story-line 3 --frames 240 --safe-area 0,47,0,34")
shot("story-level-20", "480x900", "--level 20")
shot("phone-story-level-30", "390x844", "--level 30 --safe-area 0,47,0,34")




-- tools/scenario_overview.py --capture: every board as it opens and the town after each
-- epoch of four purchases, for the scenario and epoch overviews.
-- Only with SPRITE_SCENARIO=1, so make test, test-full and shots never run them.
if getenv("SPRITE_SCENARIO") == "1" then
    for level = 1, 30 do frame(("scenario-relic-rush-board-%02d"):format(level), "480x900", "--level " .. level .. " --frames 3") end
    for epoch = 1, 5 do frame("scenario-relic-rush-town-epoch-" .. epoch, "480x900", "--epoch " .. epoch .. " --frames 3") end
    frame("scenario-relic-rush-landing", "480x900", "--level 30 --reveal 1 --frames 89")
    frame("scenario-relic-rush-resources", "480x900", "--victory 9 --frames 150")
end

shot("square-jade-steps", "480x900", "--level 2 --frames 6")
shot("square-tide-chamber", "390x844", "--level 10 --frames 6 --safe-area 0,47,0,34")
shot("square-fallen-colonnade", "480x900", "--level 11 --frames 6")
shot("square-heart-of-the-temple", "390x844", "--level 20 --frames 6 --safe-area 0,47,0,34")
shot("square-build-ready", "480x900", "--build-review ready --frames 48")
shot("square-build-cost", "390x844", "--build-review short --frames 48 --safe-area 0,47,0,34")
shot("square-build-progress", "480x900", "--city 3 --frames 48")
shot("square-build-progress-phone", "390x844", "--city 3 --frames 48 --safe-area 0,47,0,34")
shot("square-build-gate", "390x844", "--city 1 --frames 48 --safe-area 0,47,0,34")
shot("epoch-projects", "480x900", "--build-review ready --frames 48")
shot("epoch-projects-phone", "390x844", "--city 1 --frames 48 --safe-area 0,47,0,34")
shot("epoch-purchase-choice", "480x900", "--build-review choice --frames 48")
shot("epoch-purchase-choice-phone", "390x844", "--build-review choice --frames 48 --safe-area 0,47,0,34")
shot("epoch-next", "390x844", "--epoch 1 --safe-area 0,47,0,34")
shot("epoch-window", "480x900", "--epoch-window")
shot("epoch-window-phone", "390x844", "--epoch 1 --epoch-window --epoch-award --safe-area 0,47,0,34")

-- Store captures use the 2× macOS backing scale. See docs/APP_STORE_SCREENSHOTS.md.
if getenv("APP_STORE_SHOTS") == "1" then
    local town = "--lua tests/fixtures/app-store-town;games/relic-rush/lua;. --frames 45 --town-scene "
    local size, safe = "660x1434", " --safe-area 0,93,0,51"
    local prefix = "app-store-iphone-"
    shot(prefix .. "01-valley-harbor", size, town .. "harbor" .. safe)
    shot(prefix .. "02-line-gem-combo", size, "--level 30 --special-states --special-fire cross --frames 35" .. safe)
    shot(prefix .. "03-jewel-puzzle", size, "--level 20 --tiles jewels --frames 45" .. safe)
    shot(prefix .. "04-temple-gardens", size, town .. "gardens" .. safe)
    shot(prefix .. "05-rainbow-spark", size, "--level 11 --special-states --special-fire rainbow --frames 33" .. safe)
end

shot("town-story-purchase", "480x900", "--story-beat placed-workshop --frames 240")
shot("town-story-callback", "390x844", "--story-beat after-12 --story-line 1 --story-built --frames 240 --safe-area 0,47,0,34")

shot("resident-meeting", "480x900", "--story-beat meeting-map_room-aviary --story-line 2 --frames 240")
shot("resident-meeting-memory", "390x844", "--story-beat meeting-map_room-aviary --story-line 2 --story-asked --frames 240 --safe-area 0,47,0,34")
shot("resident-arrival", "480x900", "--story-beat placed-aviary --story-line 2 --frames 240")
shot("resident-return", "390x844", "--story-beat after-85 --story-built --story-line 2 --frames 240 --safe-area 0,47,0,34")
shot("resident-memory-unasked", "480x900", "--story-beat after-91 --story-line 2 --story-built --frames 240")
shot("resident-memory-asked", "390x844", "--story-beat after-91 --story-line 2 --story-asked --frames 240 --safe-area 0,47,0,34")

local visit = "--lua tests/fixtures/resident-visit;games/relic-rush/lua;. --visit-game relic-rush --frames 260 --visit-stage "
shot("resident-keep-talking", "480x900", visit .. "after-85 --visit-continue")
shot("resident-visit-first", "480x900", visit .. "placed-aviary")
shot("resident-visit-later", "390x844", visit .. "after-100 --safe-area 0,47,0,34")
shot("resident-questions-480", "480x900", visit .. "placed-aviary --visit-questions")
shot("resident-full-menu", "480x900", visit .. "after-92 --visit-meeting meeting-map_room-aviary --visit-ending --visit-full-menu --heard-at map_room")
shot("resident-full-menu-phone", "390x844", visit .. "after-92 --visit-meeting meeting-map_room-aviary --visit-ending --visit-full-menu --heard-at map_room --safe-area 0,47,0,34")
shot("resident-ending", "480x900", visit .. "after-92 --visit-meeting meeting-map_room-aviary --visit-ending --visit-site aviary")
shot("resident-ending-other", "390x844", visit .. "after-92 --visit-meeting meeting-map_room-aviary --visit-ending --visit-site map_room --heard-at aviary --safe-area 0,47,0,34")
shot("resident-keepsake", "480x900", visit .. "after-92 --visit-meeting meeting-map_room-aviary --visit-ending --visit-site aviary --visit-keepsake town")
shot("resident-keepsake-phone", "390x844", visit .. "after-92 --visit-meeting meeting-map_room-aviary --visit-ending --visit-site map_room --heard-at aviary --visit-keepsake town --safe-area 0,47,0,34")
shot("resident-keepsake-choices", "390x844", visit .. "after-92 --visit-meeting meeting-map_room-aviary --visit-ending --visit-site aviary --heard-at map_room --visit-keepsake choices --safe-area 0,47,0,34")
shot("meeting-recall", "480x900", "--story-beat after-92 --story-sides both --story-line 5 --frames 240")
shot("meeting-recall-phone", "390x844", "--story-beat after-92 --story-sides map_room --story-line 4 --frames 240 --safe-area 0,47,0,34")
shot("meeting-followup-direct", "390x844", visit .. "after-85 --visit-meeting meeting-map_room-aviary --visit-questions --safe-area 0,47,0,34")
shot("meeting-followup-answer", "480x900", visit .. "after-67 --visit-site map_room --visit-meeting meeting-map_room-aviary")
shot("meeting-reply-menu", "390x844", visit .. "after-85 --visit-meeting meeting-map_room-aviary --heard-at map_room --visit-questions --safe-area 0,47,0,34")
shot("meeting-reply-answer", "480x900", visit .. "after-67 --visit-site map_room --visit-meeting meeting-map_room-aviary --heard-at aviary")
shot("resident-questions-390", "390x844", visit .. "after-100 --visit-questions --safe-area 0,47,0,34")
shot("pilot-arrival", "480x900", "--story-beat placed-map_room --frames 240")
shot("pilot-questions", "390x844", visit .. "placed-map_room --visit-site map_room --visit-questions --safe-area 0,47,0,34")
shot("pilot-revisit", "390x844", visit .. "after-100 --visit-site map_room --visit-questions --safe-area 0,47,0,34")
shot("pilot-unasked", "480x900", "--story-beat after-67 --story-built --story-line 2 --frames 240")
shot("pilot-remembered", "390x844", "--story-beat after-67 --story-asked --story-line 2 --frames 240 --safe-area 0,47,0,34")

local marker = "--lua tests/fixtures/resident-visit;games/relic-rush/lua;. --visit-game relic-rush --visit-marker --frames 45"
shot("unheard-visit-480", "480x900", marker)
shot("unheard-visit-390", "390x844", marker .. " --safe-area 0,47,0,34")
