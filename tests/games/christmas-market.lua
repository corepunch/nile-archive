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
rules("christmas_leaderboard")
smoke()
smoke("--debug-walkthrough --lua tests/fixtures/walkthrough;games/christmas-market/lua;. --review-game christmas-market", "walkthrough-pointer")
smoke("--campaign", "campaign")   -- all thirty winter wishes and every story beat

shot("debug-board", "480x900", "--debug-walkthrough --level 4 --frames 180")
shot("debug-town", "480x900", "--debug-walkthrough --city 2 --frames 180")
shot("debug-phone-board", "390x844", "--debug-walkthrough --level 4 --frames 180 --safe-area 0,47,0,34")
shot("debug-phone-town", "390x844", "--debug-walkthrough --city 2 --frames 180 --safe-area 0,47,0,34")
shot("market", "480x900", "--showcase")
shot("phone-market", "390x844", "--showcase --safe-area 0,47,0,34")
shot("main-character-board", "480x900", "--level 4")
shot("campaign-access", "480x900", "--level 13")
shot("campaign-thaw", "480x900", "--level 22")
shot("element-states", "480x900", "--element-states")
shot("designed-lanes", "480x900", "--level 4")
shot("designed-chambers", "390x844", "--level 7 --safe-area 0,47,0,34")
shot("delivery-finale", "480x900", "--level 30")
shot("phone-element-states", "390x844", "--element-states --safe-area 0,47,0,34")
shot("phone-board", "390x844", "--level 4 --safe-area 0,47,0,34")
shot("dialogue", "480x900", "--dialog intro --frames 180")
shot("main-character-dialogue", "390x844", "--dialog intro --frames 180 --safe-area 0,47,0,34")
shot("placement", "480x900", "--city 2 --placing")
shot("phone-placement", "390x844", "--city 2 --placing --safe-area 0,47,0,34")
shot("blocked-placement", "480x900", "--city 2 --placing blocked")
shot("region", "480x900", "--city 3 --open 1 --zone 1")
shot("shop", "480x900", "--catalogue building")
shot("winter-wishes", "480x900", "--expeditions")
shot("phone-shop", "390x844", "--catalogue building --safe-area 0,47,0,34")
shot("phone-winter-wishes", "390x844", "--expeditions --safe-area 0,47,0,34")
shot("reward", "480x900", "--victory")
shot("result-layer-480", "480x900", "--victory")
shot("result-layer-390", "390x844", "--victory --safe-area 0,47,0,34")
shot("reward-story", "480x900", "--victory clue")
shot("mission", "480x900", "--level 5 --mission --frames 60")
shot("kudos", "480x900", "--level 5 --kudos 3 --frames 20")
shot("goals-met", "480x900", "--level 5 --goals-met")
-- the result dialog arriving on the motion module: 16 pictures, 6 frames apart
reel("christmas-market-reward-entrance", 16, 6, "480x900", "--victory --reel")
reel("christmas-market-town-dive", 16, 3, "480x900", "--city 3 --dive --reel")   -- Play: the town dives into the board
shot("pause", "480x900", "--level 4 --dialog pause")
shot("phone-pause", "390x844", "--level 4 --dialog pause --safe-area 0,47,0,34")
shot("leaderboard", "480x900", "--level 4 --dialog leaderboard --gamecenter-demo")
shot("phone-leaderboard", "390x844", "--level 4 --dialog leaderboard --gamecenter-demo --safe-area 0,47,0,34")
shot("level-leaderboard", "480x900", "--victory --dialog level-leaderboard --gamecenter-demo")
shot("restart", "480x900", "--level 4 --dialog confirm")
shot("guide", "480x900", "--level 4 --dialog guide")
shot("phone-guide", "390x844", "--level 4 --dialog guide --safe-area 0,47,0,34")
shot("failed", "480x900", "--level 4 --dialog failed --empty-lives")
shot("finale", "480x900", "--dialog finale")
shot("footprints", "480x900", "--showcase --footprints")
shot("phone-footprints", "390x844", "--showcase --footprints --safe-area 0,47,0,34")
local footprints = "--lua tests/fixtures/christmas-footprints;games/christmas-market/lua;."
shot("adjacent-foundations", "480x900", footprints)
shot("phone-adjacent-foundations", "390x844", footprints .. " --safe-area 0,47,0,34")
shot("art-states", "480x900", "--art-states")
shot("hud-states", "480x900", "--hud-states")
shot("specials-board", "480x900", "--art-board")
shot("building-card", "480x900", "--card 2")
reel("christmas-market-board-intro", 18, 6, "480x900", "--level 4 --present --reel")
for page = 1, 10 do shot("building-review-" .. page, "480x900", "--building-review " .. page .. " --footprints") end

-- Shared-engine atlas and refill captures: all runs share this test process.
for _, size in ipairs{"480x900", "390x844"} do
    local safe = size == "390x844" and " --safe-area 0,47,0,34" or ""
    for _, mode in ipairs{"vertical", "diagonal"} do
        frame("trickling-christmas-market-"..mode.."-"..size, size,
            "--lua tests/fixtures/trickling;games/christmas-market/lua;. --review-game christmas-market --review-gravity "..mode.." --fall-time .04"..safe)
    end
end
-- Board/HUD states reuse the art-states and hud-states shots above.
frame("atlas-christmas-market-effects", "480x900", "--fx bomb --frames 8")

reel("christmas-market-phone-board-intro", 12, 8, "390x844", "--level 4 --present --reel --safe-area 0,47,0,34")
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
    shot(prefix .. "wren", size, "--story-beat before-01 --story-line 6 --frames 240" .. safe)
    shot(prefix .. "henrik", size, "--story-beat after-13 --frames 240" .. safe)
    shot(prefix .. "shout", size, "--story-beat after-03 --frames 240" .. safe)
    shot(prefix .. "finale", size, "--story-beat after-30 --story-line 15 --frames 240" .. safe)
    shot(prefix .. "end", size, "--dialog finale" .. safe)
end
shot("story-level-20", "480x900", "--level 20")
shot("phone-story-level-30", "390x844", "--level 30 --safe-area 0,47,0,34")
shot("dialogue-bar-480", "480x900", "--story-beat before-01 --talk-through 270 --frames 535")
shot("dialogue-bar-390", "390x844", "--story-beat before-01 --talk-through 270 --frames 535 --safe-area 0,47,0,34")

shot("homescapes-queue", "480x900", "--homescapes st0065")
shot("phone-homescapes-queue", "390x844", "--homescapes st0065 --safe-area 0,47,0,34")
shot("homescapes-generator", "390x844", "--homescapes st0255 --safe-area 0,47,0,34")
reel("fx-plane",18,2,"480x900","--fx plane --reel")
shot("phone-specials-board","390x844","--art-board --safe-area 0,47,0,34")

shot("homescapes-art", "480x900", "--homescapes-art")
shot("phone-homescapes-art", "390x844", "--homescapes-art --safe-area 0,47,0,34")
shot("homescapes-art-generators", "480x900", "--homescapes-art generators")
shot("phone-homescapes-art-generators", "390x844", "--homescapes-art generators --safe-area 0,47,0,34")
