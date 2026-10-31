-- Christmas Market: every test, in one start of build/test/christmas-market. See docs/TESTING.md.
rules("relic_board")
rules("progression")
rules("match_matrix")
rules("trickling")
rules("building_economy")
default_frames = 3
rules("christmas")
smoke()

shot("market", "480x900", "--showcase")
shot("phone-market", "390x844", "--showcase --safe-area 0,47,0,34")
shot("main-character-board", "480x900", "--level 4")
shot("phone-board", "390x844", "--level 4 --safe-area 0,47,0,34")
shot("dialogue", "480x900", "--dialog intro --frames 180")
shot("main-character-dialogue", "390x844", "--dialog intro --frames 180 --safe-area 0,47,0,34")
shot("placement", "480x900", "--city 2 --placing")
shot("blocked-placement", "480x900", "--city 2 --placing blocked")
shot("region", "480x900", "--city 3 --zone 1")
shot("shop", "480x900", "--catalogue building")
shot("winter-wishes", "480x900", "--expeditions")
shot("reward", "480x900", "--victory")
-- the result dialog arriving on the motion module: 16 pictures, 6 frames apart
reel("christmas-market-reward-entrance", 16, 6, "480x900", "--victory --reel")
shot("pause", "480x900", "--level 4 --dialog pause")
shot("guide", "480x900", "--level 4 --dialog guide")
shot("failed", "480x900", "--level 4 --dialog failed")
shot("finale", "480x900", "--dialog finale")
shot("footprints", "480x900", "--showcase --footprints")
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
