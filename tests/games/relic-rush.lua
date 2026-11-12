-- Relic Rush: every test, in one start of build/test/relic-rush. See docs/TESTING.md.
rules("relic_story")
rules("match_matrix")
rules("trickling")
rules("haptics_board")
rules("building_economy")
rules("relic")
rules("relic_board")
rules("portrait_game")
rules("progression")
rules("campaign_play")
rules("campaign_layout", ".")
rules("relic_wallet")
rules("relic_leaderboard")
smoke()
smoke("--empty-lives","empty-lives")
smoke("--campaign","campaign")   -- all thirty expeditions and every story beat
smoke("--lua tests/fixtures/ui --data games/relic-rush/data --size 900x700", "ui")

shot("hex-first", "480x900")
shot("hex-late", "480x900", "--level 8")
shot("campaign-access", "480x900", "--level 13")
shot("campaign-thaw", "480x900", "--level 22")
shot("floating-hud", "480x900", "--level 9")
shot("phone-floating-hud", "390x844", "--level 9 --safe-area 0,47,0,34")
shot("art-catalogue", "480x900", "--art-states")
shot("hud-states", "480x900", "--level 7 --hud-states")
shot("phone-art-specials", "390x844", "--art-board --safe-area 0,47,0,34")
shot("art-specials", "480x900", "--art-board")
shot("art-jewels", "480x900", "--art-board --tiles jewels")
shot("art-resources", "480x900", "--art-board --tiles resources")
shot("stripe-states-relics", "480x900", "--stripe-states")
shot("stripe-states-jewels", "480x900", "--stripe-states --tiles jewels")
shot("stripe-states-resources", "480x900", "--stripe-states --tiles resources")
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
shot("building-card", "480x900", "--card 1")
shot("dialogue-elena", "480x900", "--dialog intro --frames 240")
shot("dialogue-mara", "480x900", "--dialog mara --frames 240")
shot("dialogue-tomas", "480x900", "--dialog tomas --frames 240")
shot("dialogue-adrian", "480x900", "--dialog adrian --frames 240")
shot("island-bubble", "480x900", "--dialog bubble --frames 30")
shot("phone-island", "390x844", "--city 3 --safe-area 0,47,0,34")
shot("phone-board", "390x844", "--safe-area 0,47,0,34")
shot("effect-ray", "480x900", "--fx ray --frames 10")
shot("effect-bomb", "480x900", "--fx bomb --frames 10")
shot("effect-prism", "480x900", "--fx prism --frames 10")
shot("phone-dialogue-intro", "390x844", "--dialog intro --frames 240 --safe-area 0,47,0,34")
shot("phone-dialogue-mara", "390x844", "--dialog mara --frames 240 --safe-area 0,47,0,34")
shot("phone-dialogue-tomas", "390x844", "--dialog tomas --frames 240 --safe-area 0,47,0,34")
shot("phone-dialogue-adrian", "390x844", "--dialog adrian --frames 240 --safe-area 0,47,0,34")

-- Pictures that documentation images are assembled from.
for _, pack in ipairs{"relics", "jewels", "resources"} do
    frame("tiles-" .. pack, "480x900", "--tiles " .. pack .. " --frames 3")
end
for level = 1, 10 do frame("shape-" .. level, "480x900", "--level " .. level .. " --frames 3") end
reel("fx-ray", 18, 2, "480x900", "--fx ray --reel")
reel("fx-bomb", 18, 2, "480x900", "--fx bomb --reel")
reel("fx-prism", 18, 2, "480x900", "--fx prism --reel")
reel("result", 36, 3, "480x900", "--victory --reel")
frame("ui-skins", "900x700", "--lua tests/fixtures/ui --data games/relic-rush/data --frames 3")
frame("ui-layers", "900x700", "--lua tests/fixtures/ui --data games/relic-rush/data --nested --frames 3")

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
reel("relic-rush-board-intro", 18, 6, "480x900", "--level 5 --present --reel")
reel("relic-rush-town-dive", 16, 3, "480x900", "--city 3 --dive --reel")   -- Play: the town dives into the board
reel("relic-rush-phone-board-intro", 12, 8, "390x844", "--level 9 --present --reel --safe-area 0,47,0,34")
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
shot("expeditions", "480x900", "--expeditions")
shot("phone-expeditions", "390x844", "--expeditions --safe-area 0,47,0,34")
shot("catalogue", "480x900", "--catalogue building")
shot("phone-catalogue", "390x844", "--catalogue building --safe-area 0,47,0,34")

reel("expeditions-scroll",24,3,"480x900","--expeditions --scroll-review")
reel("phone-catalogue-scroll",24,3,"390x844","--catalogue building --scroll-review --safe-area 0,47,0,34")
shot("phone-island-bubble","390x844","--dialog bubble --safe-area 0,47,0,34")

-- Full-script representative reads: longest line, thought, shout and the finale.
shot("story-opening", "480x900", "--story-beat before-01 --frames 240")
shot("phone-story-opening", "390x844", "--story-beat before-01 --frames 240 --safe-area 0,47,0,34")
shot("story-longest", "480x900", "--story-beat before-11 --frames 240")
shot("phone-story-longest", "390x844", "--story-beat before-11 --frames 240 --safe-area 0,47,0,34")
shot("story-shout", "480x900", "--story-beat after-28 --frames 240")
shot("phone-story-shout", "390x844", "--story-beat after-28 --frames 240 --safe-area 0,47,0,34")
shot("story-finale", "480x900", "--story-beat after-30 --story-line 9 --frames 240")
shot("story-radio", "480x900", "--story-beat after-05 --story-line 2 --frames 240")   -- Kessler: heard, never seen
shot("phone-story-radio", "390x844", "--story-beat after-05 --story-line 2 --frames 240 --safe-area 0,47,0,34")
shot("phone-story-finale", "390x844", "--story-beat after-30 --story-line 9 --frames 240 --safe-area 0,47,0,34")
shot("story-level-20", "480x900", "--level 20")
shot("phone-story-level-30", "390x844", "--level 30 --safe-area 0,47,0,34")
