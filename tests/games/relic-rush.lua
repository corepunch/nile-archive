rules("debug_walkthrough")
-- Relic Rush: every test, in one start of build/test/relic-rush. See docs/TESTING.md.
rules("relic_story")
rules("match_matrix")
rules("trickling")
rules("haptics_board")
rules("building_economy")
rules("relic")
rules("relic_board")
rules("portrait_game")
rules("campaign_play")
rules("relic_balance")
rules("tune_moves")
rules("campaign_layout", ".")
rules("match3_elements")
rules("relic_wallet")
rules("relic_quests")
rules("relic_user_events")
rules("relic_leaderboard")
smoke()
smoke("--debug-walkthrough --lua tests/fixtures/walkthrough;games/relic-rush/lua;. --review-game relic-rush", "walkthrough-pointer", "quick")
smoke("--lua tests/fixtures/relic-quests;games/relic-rush/lua;. --size 390x844 --safe-area 0,47,0,34", "quest-flow")
smoke("--campaign --size 240x450", "campaign")   -- same logical phone layout, fewer pixels per frame
smoke("--lua tests/fixtures/ui --data games/relic-rush/data --size 900x700", "ui")

shot("debug-board", "480x900", "--debug-walkthrough --level 4 --frames 180")
shot("debug-town", "480x900", "--debug-walkthrough --city 2 --frames 180")
shot("debug-phone-board", "390x844", "--debug-walkthrough --level 4 --frames 180 --safe-area 0,47,0,34")
shot("debug-phone-town", "390x844", "--debug-walkthrough --city 2 --frames 180 --safe-area 0,47,0,34")
shot("story-handoff", "480x900", "--city 4 --look 925,2110 --story-beat after-10 --story-line 5 --frames 180")
shot("story-handoff-phone", "390x844", "--city 4 --look 925,2110 --story-beat after-10 --story-line 5 --frames 180 --safe-area 0,47,0,34")
shot("story-choice", "480x900", "--story-choice after-10")
shot("story-choice-phone", "390x844", "--story-choice after-10 --safe-area 0,47,0,34")
shot("goal-board", "480x900", "--level 2 --frames 180")
shot("goal-board-phone", "390x844", "--level 2 --frames 180 --safe-area 0,47,0,34")
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
shot("tomas-arrival-phone", "390x844", "--story-beat restore-04 --frames 180 --safe-area 0,47,0,34")
shot("relay-pliers-alternate", "480x900", "--level 8 --tiles resources")
shot("campaign-access", "480x900", "--level 13")
shot("note-collection-phone", "390x844", "--level 13")
shot("note-read", "480x900", "--story-beat after-13 --story-line 1 --frames 120")
shot("note-courtyard", "480x900", "--story-beat restore-13 --story-line 1 --frames 220")
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
shot("landing-briefing", "390x844", "--story-beat before-22 --frames 180 --safe-area 0,47,0,34")
shot("dressing-tide-beat", "480x900", "--story-beat after-10 --story-line 6 --frames 180")
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
local tablet_review = "--lua tests/fixtures/tablet-hints;games/relic-rush/lua;. --level 5 --reel"
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
shot("quest-rail", "480x900", "--city 2 --quest-have 12")
shot("quest-rail-phone", "390x844", "--city 2 --quest-have 12 --safe-area 0,47,0,34")
shot("quest-rail-ready", "480x900", "--city 2 --quest-have 99")
shot("quest-rail-waiting", "480x900", "--city 3 --quest-have 5")
shot("quest-card", "480x900", "--city 2 --quest-have 12 --quest-card chart")
shot("quest-card-phone", "390x844", "--city 2 --quest-have 12 --quest-card chart --safe-area 0,47,0,34")
shot("quest-card-ready", "480x900", "--city 2 --quest-have 99 --quest-card chart")
shot("quest-board", "480x900", "--level 3")
shot("quest-board-phone", "390x844", "--level 3 --safe-area 0,47,0,34")
shot("quest-board-arrows", "480x900", "--level 6")
shot("quest-board-cable", "480x900", "--level 9")
shot("quest-result", "480x900", "--victory 3 --quest-have 0")
shot("quest-handoff-chart", "480x900", "--city 2 --quest-handoff chart")
shot("quest-handoff-cable-phone", "390x844", "--city 3 --quest-handoff cable --safe-area 0,47,0,34")
shot("economy-wallet", "390x844", "--city 2 --safe-area 0,47,0,34")
shot("economy-price-phone", "390x844", "--card 3 --safe-area 0,47,0,34")
shot("economy-shop", "480x900", "--catalogue building")
shot("quay-footprint", "480x900", "--city 4 --look 925,2195 --footprints")
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
shot("art-jewels", "480x900", "--art-board --tiles jewels")
shot("art-resources", "480x900", "--art-board --tiles resources")
shot("art-phone", "390x844", "--level 8 --safe-area 0,47,0,34")
shot("guide", "480x900", "--dialog guide")
shot("phone-guide", "390x844", "--dialog guide --safe-area 0,47,0,34")
shot("pause", "480x900", "--dialog pause")
shot("phone-pause", "390x844", "--dialog pause --safe-area 0,47,0,34")
shot("leaderboard", "480x900", "--dialog leaderboard --gamecenter-demo")
shot("phone-leaderboard", "390x844", "--dialog leaderboard --gamecenter-demo --safe-area 0,47,0,34")
shot("level-leaderboard", "480x900", "--victory --dialog level-leaderboard --gamecenter-demo")
shot("result-leaderboard", "480x900", "--victory --gamecenter-demo")
shot("phone-card", "390x844", "--card 1 --safe-area 0,47,0,34")
shot("island-village", "480x900", "--showcase")
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
shot("building-card", "480x900", "--card 1")
shot("dialogue-elena", "480x900", "--dialog intro --frames 240")
shot("dialogue-mara", "480x900", "--dialog mara --frames 240")
shot("dialogue-tomas", "480x900", "--dialog tomas --frames 240")
shot("dialogue-adrian", "480x900", "--dialog adrian --frames 240")
shot("island-bubble", "480x900", "--dialog bubble --frames 30")
shot("phone-island", "390x844", "--city 3 --safe-area 0,47,0,34")
shot("phone-board", "390x844", "--safe-area 0,47,0,34")
shot("effect-shatter", "480x900", "--fx shatter --frames 10")
shot("phone-dialogue-intro", "390x844", "--dialog intro --frames 240 --safe-area 0,47,0,34")
shot("phone-dialogue-mara", "390x844", "--dialog mara --frames 240 --safe-area 0,47,0,34")
shot("phone-dialogue-tomas", "390x844", "--dialog tomas --frames 240 --safe-area 0,47,0,34")
shot("phone-dialogue-adrian", "390x844", "--dialog adrian --frames 240 --safe-area 0,47,0,34")

-- Pictures that documentation images are assembled from.
for _, pack in ipairs{"relics", "jewels", "resources"} do
    frame("tiles-" .. pack, "480x900", "--tiles " .. pack .. " --frames 3")
end
for level = 1, 10 do frame("shape-" .. level, "480x900", "--level " .. level .. " --frames 3") end
reel("fx-shatter", 24, 2, "480x900", "--fx shatter --reel")
reel("result", 36, 3, "480x900", "--victory --reel")
frame("ui-skins", "900x700", "--lua tests/fixtures/ui --data games/relic-rush/data --frames 3")
frame("ui-layers", "900x700", "--lua tests/fixtures/ui --data games/relic-rush/data --nested --frames 3")
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
shot("story-longest", "480x900", "--story-beat before-11 --frames 240")
shot("phone-story-longest", "390x844", "--story-beat before-11 --frames 240 --safe-area 0,47,0,34")
shot("story-shout", "480x900", "--story-beat after-28 --frames 240")
shot("phone-story-shout", "390x844", "--story-beat after-28 --frames 240 --safe-area 0,47,0,34")
shot("story-finale", "480x900", "--story-beat after-30 --story-line 3 --frames 240")
shot("story-radio", "480x900", "--story-beat after-05 --story-line 2 --frames 240")   -- Kessler: heard, never seen
shot("phone-story-radio", "390x844", "--story-beat after-05 --story-line 2 --frames 240 --safe-area 0,47,0,34")
shot("phone-story-finale", "390x844", "--story-beat after-30 --story-line 3 --frames 240 --safe-area 0,47,0,34")
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
