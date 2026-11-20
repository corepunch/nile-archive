rules("debug_walkthrough")
-- Christmas Market: every test, in one start of build/test/christmas-market. See docs/TESTING.md.
rules("relic_board")
rules("portrait_game")
rules("progression")
rules("campaign_play")
rules("campaign_layout", ".")
rules("match3_elements")
rules("match_matrix")
rules("trickling")
rules("haptics_board")
rules("building_economy")
default_frames = 3
rules("christmas")
rules("christmas_story")
rules("upgrades")
rules("christmas_leaderboard")
smoke()
smoke("--debug-walkthrough --lua tests/fixtures/walkthrough;games/christmas-market/lua;. --review-game christmas-market", "walkthrough-pointer", "quick")
smoke("--campaign --size 240x450", "campaign")   -- same logical phone layout, fewer pixels per frame

shot("debug-board", "480x900", "--debug-walkthrough --level 4 --frames 180")
shot("debug-town", "480x900", "--debug-walkthrough --city 2 --frames 180")
shot("debug-phone-board", "390x844", "--debug-walkthrough --level 4 --frames 180 --safe-area 0,47,0,34")
shot("debug-phone-town", "390x844", "--debug-walkthrough --city 2 --frames 180 --safe-area 0,47,0,34")
shot("market", "480x900", "--showcase")
shot("phone-market", "390x844", "--showcase --safe-area 0,47,0,34")
shot("opening-market", "480x900", "")
shot("phone-opening-market", "390x844", "--safe-area 0,47,0,34")
shot("lantern-opening", "480x900", "--level 1")
shot("lantern-opening-phone", "390x844", "--level 1 --safe-area 0,47,0,34")
shot("main-character-board", "480x900", "--level 4")
local bonus_fixture = "--lua tests/fixtures/bonus-toolbar;games/christmas-market/lua;. "
local booster_review = bonus_fixture .. "--level 10 "
shot("booster-toolbar", "480x900", booster_review .. "--frames 10")
shot("booster-toolbar-phone", "390x844", booster_review .. "--frames 10 --safe-area 0,47,0,34")
shot("hammer-toolbar-phone", "390x844", bonus_fixture .. "--level 4 --frames 10 --safe-area 0,47,0,34")
shot("booster-spent", "390x844", booster_review .. "--spend-bonus --frames 25 --safe-area 0,47,0,34")
shot("chapel-reward", "480x900", "--catalogue-card 34 --frames 35")
shot("stable-reward", "480x900", "--catalogue-card 35 --frames 35")
local booster_flight = "--lua tests/fixtures/bonus-toolbar;games/christmas-market/lua;. --fly-bonus "
local booster_safe = " --safe-area 0,47,0,34"
reel("booster-hammer-flight", 23, 4, "390x844", booster_flight .. "--level 5" .. booster_safe)
reel("booster-lantern-flight", 23, 4, "390x844", booster_flight .. "--level 20" .. booster_safe)
shot("booster-reduced-motion", "480x900", booster_flight .. "--level 5 --flight-no-motion --frames 86")
shot("campaign-access", "480x900", "--level 13")
shot("campaign-thaw", "480x900", "--level 19")
shot("phone-campaign-thaw", "390x844", "--level 19 --safe-area 0,47,0,34")
for _, size in ipairs{"480x900", "390x844"} do
    local safe = size == "390x844" and " --safe-area 0,47,0,34" or ""
    for _, level in ipairs{24, 25, 28} do
        shot("story-floor-" .. level .. "-" .. size, size,
            "--level " .. level .. " --reveal 1 --frames 95" .. safe)
    end
end
shot("story-floor-ribbon-half", "480x900", "--level 24 --reveal .5 --frames 95")
shot("story-floor-telegram-half", "480x900", "--level 25 --reveal .5 --frames 95")
shot("story-floor-train-half", "480x900", "--level 28 --reveal .5 --frames 95")
shot("story-floor-train-scene", "480x900", "--level 28 --reveal 1 --frames 270")
reel("story-floor-train-win", 12, 12, "480x900", "--level 28 --reveal 1 --reel")
shot("element-states", "480x900", "--element-states")
reel("christmas-market-welcome-panes", 25, 15, "480x900", "--level 9 --floor-reel oil --reel")
frame("christmas-market-tablet-hints", "480x900",
    "--lua tests/fixtures/tablet-hints;games/christmas-market/lua;. --level 10 --hint-three --frames 55")
reel("christmas-market-sawdust-panes", 25, 15, "480x900", "--level 4 --floor-reel oil --reel")
shot("designed-lanes", "480x900", "--level 4")
shot("find-letter-480", "480x900", "--level 19")
shot("find-letter-390", "390x844", "--level 19 --safe-area 0,47,0,34")
shot("find-cocoa", "480x900", "--level 9")
shot("find-scarf", "480x900", "--level 16")
shot("find-ribbon", "480x900", "--level 24")
shot("find-telegram", "480x900", "--level 25")
shot("find-lantern", "480x900", "--level 27")
shot("find-letter-reward", "390x844", "--victory 19 --safe-area 0,47,0,34")
shot("designed-chambers", "390x844", "--level 7 --safe-area 0,47,0,34")
shot("tree-finale", "480x900", "--level 30")
shot("phone-element-states", "390x844", "--element-states --safe-area 0,47,0,34")
shot("phone-board", "390x844", "--level 4 --safe-area 0,47,0,34")
shot("dialogue", "480x900", "--dialog intro --frames 180")
shot("main-character-dialogue", "390x844", "--dialog intro --frames 180 --safe-area 0,47,0,34")
shot("placement", "480x900", "--city 2 --placing")
shot("phone-placement", "390x844", "--city 2 --placing --safe-area 0,47,0,34")
shot("blocked-placement", "480x900", "--city 2 --placing blocked")
shot("region", "480x900", "--city 3 --open 1 --zone 1")
shot("shop", "480x900", "--catalogue building")
shot("phone-shop", "390x844", "--catalogue building --safe-area 0,47,0,34")
shot("reward", "480x900", "--victory")
shot("result-layer-480", "480x900", "--victory")
shot("result-layer-390", "390x844", "--victory --safe-area 0,47,0,34")
shot("reward-story", "480x900", "--victory clue")
shot("mission", "480x900", "--level 5 --mission --frames 60")
shot("kudos", "480x900", "--level 5 --kudos 3 --frames 20")
shot("goals-met", "480x900", "--level 5 --goals-met")
-- the result dialog arriving on the motion module: 16 pictures, 6 frames apart
reel("christmas-market-reward-entrance", 16, 6, "480x900", "--victory --reel")
reel("christmas-market-level-end", 29, 3, "390x844",
    "--lua tests/fixtures/level-end;games/christmas-market/lua;. --dialog failed --reel --safe-area 0,47,0,34")
reel("christmas-market-town-dive", 48, 4, "480x900", "--city 3 --dive --dive-back 120 --reel")   -- Play: the town dives into the board and back
shot("pause", "480x900", "--level 4 --dialog pause")
shot("phone-pause", "390x844", "--level 4 --dialog pause --safe-area 0,47,0,34")
shot("leaderboard", "480x900", "--level 4 --dialog leaderboard --gamecenter-demo")
shot("phone-leaderboard", "390x844", "--level 4 --dialog leaderboard --gamecenter-demo --safe-area 0,47,0,34")
shot("restart", "480x900", "--level 4 --dialog confirm")
shot("guide", "480x900", "--level 4 --dialog guide")
shot("phone-guide", "390x844", "--level 4 --dialog guide --safe-area 0,47,0,34")
shot("failed", "480x900", "--level 4 --dialog failed")
shot("finale", "480x900", "--dialog finale")
shot("footprints", "480x900", "--showcase --footprints")
shot("phone-footprints", "390x844", "--showcase --footprints --safe-area 0,47,0,34")
local footprints = "--lua tests/fixtures/christmas-footprints;games/christmas-market/lua;."
shot("adjacent-foundations", "480x900", footprints)
shot("phone-adjacent-foundations", "390x844", footprints .. " --safe-area 0,47,0,34")
shot("art-states", "480x900", "--art-states")
shot("bonus-art-states", "480x900", "--art-states bonuses")
shot("hud-states", "480x900", "--hud-states")
shot("pieces-board", "480x900", "--art-board")
shot("building-card", "480x900", "--card 2")
reel("christmas-market-board-intro", 18, 6, "480x900", "--level 4 --present --reel")
for page = 1, 10 do shot("building-review-" .. page, "480x900", "--building-review " .. page .. " --footprints") end
shot("second-row-footprints", "480x900", "--building-review 10 --footprints")
shot("second-row-footprints-phone", "390x844", "--building-review 10 --footprints --safe-area 0,47,0,34")
for _, page in ipairs{1, 2, 8, 9, 10} do
    shot("chimney-page-" .. page, "480x900", "--building-review " .. page .. " --frames 120")
end
shot("chimney-phone", "390x844", "--building-review 10 --frames 120 --safe-area 0,47,0,34")
reel("chimney-smoke", 12, 12, "480x900", "--building-review 10 --reel")

-- Shared-engine atlas and refill captures: all runs share this test process.
for _, size in ipairs{"480x900", "390x844"} do
    local safe = size == "390x844" and " --safe-area 0,47,0,34" or ""
    for _, mode in ipairs{"vertical", "diagonal"} do
        frame("trickling-christmas-market-"..mode.."-"..size, size,
            "--lua tests/fixtures/trickling;games/christmas-market/lua;. --review-game christmas-market --review-gravity "..mode.." --fall-time .04"..safe)
    end
end
-- Board/HUD states reuse the art-states and hud-states shots above.
frame("atlas-christmas-market-effects", "480x900", "--fx shatter --frames 8")

reel("christmas-market-phone-board-intro", 12, 8, "390x844", "--level 4 --present --reel --safe-area 0,47,0,34")
reel("christmas-market-board-shuffle", 16, 4, "390x844",
    "--lua tests/fixtures/shuffle;games/christmas-market/lua;tests/lua;. --level 7 --reel --safe-area 0,47,0,34")
frame("entrance-settled-christmas-market-480x900", "480x900", "--level 4 --present --frames 180")
frame("entrance-settled-christmas-market-390x844", "390x844", "--level 4 --present --frames 180 --safe-area 0,47,0,34")

-- Building art must ride the popup; each top edge cell supplies the refill.
for _, size in ipairs{"480x900", "390x844"} do
    local safe = size == "390x844" and " --safe-area 0,47,0,34" or ""
    reel("christmas-market-building-entrance-"..size, 16, 3, size, "--card 1 --reel"..safe)
    reel("christmas-market-top-edge-refill-"..size, 16, 3, size,
        "--lua tests/fixtures/trickling;games/christmas-market/lua;. --review-top-edge --reel"..safe)
end

-- Story review (docs/review/story): all new busts, the longest line, the finale
-- and its end screen, at both phone sizes.
for _, size in ipairs{"480x900", "390x844"} do
    local safe = size == "390x844" and " --safe-area 0,47,0,34" or ""
    local prefix = size == "390x844" and "phone-story-" or "story-"
    shot(prefix .. "opening", size, "--story-beat before-01 --frames 240" .. safe)
    shot(prefix .. "agnes", size, "--story-beat before-01 --story-line 2 --frames 240" .. safe)
    shot(prefix .. "theo", size, "--story-beat after-01 --frames 240" .. safe)
    shot(prefix .. "wren", size, "--story-beat before-01 --story-line 3 --frames 240" .. safe)
    shot(prefix .. "henrik", size, "--story-beat after-13 --frames 240" .. safe)
    shot(prefix .. "shout", size, "--story-beat after-03 --frames 240" .. safe)
    shot(prefix .. "finale", size, "--story-beat after-30 --story-line 3 --frames 240" .. safe)
    shot(prefix .. "end", size, "--dialog finale" .. safe)
end
shot("story-level-20", "480x900", "--level 20")
local new_cast = {alder = "before-40 --story-line 2", finch = "after-47 --story-line 3",
                  mary = "after-94 --story-line 2", rosa = "after-95 --story-line 2"}
for _, speaker in ipairs{"alder", "finch", "mary", "rosa"} do
    local args = "--story-beat " .. new_cast[speaker] .. " --frames 240"
    shot("new-cast-" .. speaker, "480x900", args)
    shot("new-cast-" .. speaker .. "-phone", "390x844", args .. " --safe-area 0,47,0,34")
end
shot("story-borrowed-lamps", "480x900", "--story-beat after-27 --story-line 3 --frames 240")
shot("story-staying", "390x844", "--story-beat after-29 --story-line 2 --frames 240 --safe-area 0,47,0,34")
shot("phone-story-level-30", "390x844", "--level 30 --safe-area 0,47,0,34")
shot("dialogue-bar-480", "480x900", "--story-beat before-01 --talk-through 270 --frames 535")
shot("dialogue-bar-390", "390x844", "--story-beat before-01 --talk-through 270 --frames 535 --safe-area 0,47,0,34")

reel("fx-shatter",24,2,"480x900","--fx shatter --reel")
shot("phone-pieces-board","390x844","--art-board --safe-area 0,47,0,34")



-- tools/scenario_overview.py --capture: every board as it opens and the town after each
-- epoch of four purchases, for the scenario and epoch overviews.
-- Only with SPRITE_SCENARIO=1, so make test, test-full and shots never run them.
if getenv("SPRITE_SCENARIO") == "1" then
    for level = 1, 30 do frame(("scenario-christmas-market-board-%02d"):format(level), "480x900", "--level " .. level .. " --frames 3") end
    for epoch = 1, 5 do frame("scenario-christmas-market-town-epoch-" .. epoch, "480x900", "--epoch " .. epoch .. " --frames 3") end
end
rules("relic_balance")
rules("tune_moves")

shot("square-winter-wreath", "390x844", "--level 2 --frames 6 --safe-area 0,47,0,34")
shot("square-christmas-star", "480x900", "--level 10 --frames 6")
