-- Relic Rush: every test, in one start of build/test/relic-rush. See docs/TESTING.md.
rules("match_matrix")
rules("trickling")
rules("building_economy")
rules("relic")
rules("relic_board")
rules("progression")
smoke()
smoke("--lua tests/fixtures/ui --data games/relic-rush/data --size 900x700", "ui")

shot("hex-first", "480x900")
shot("hex-late", "480x900", "--level 8")
shot("floating-hud", "480x900", "--level 9")
shot("phone-floating-hud", "390x844", "--level 9 --safe-area 0,47,0,34")
shot("art-catalogue", "480x900", "--art-states")
shot("art-specials", "480x900", "--art-board")
shot("art-jewels", "480x900", "--art-board --tiles jewels")
shot("art-resources", "480x900", "--art-board --tiles resources")
shot("art-phone", "390x844", "--level 8 --safe-area 0,47,0,34")
shot("guide", "480x900", "--dialog guide")
shot("phone-guide", "390x844", "--dialog guide --safe-area 0,47,0,34")
shot("pause", "480x900", "--dialog pause")
shot("phone-pause", "390x844", "--dialog pause --safe-area 0,47,0,34")
shot("phone-card", "390x844", "--card 1 --safe-area 0,47,0,34")
shot("island-village", "480x900", "--showcase")
shot("footprints", "480x900", "--showcase --footprints")
shot("island-placement", "480x900", "--city 6 --placing")
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
frame("atlas-relic-rush-board", "480x900", "--level 7 --art-states")
frame("atlas-relic-rush-hud", "480x900", "--level 7 --hud-states")
frame("atlas-relic-rush-effects", "480x900", "--fx bomb --frames 8")

for _, size in ipairs{"480x900", "390x844"} do
    local safe = size == "390x844" and " --safe-area 0,47,0,34" or ""
    frame("resource-icons-default-"..size,size,"--default-match3 --level 7"..safe)
    for _, pack in ipairs{"relics", "jewels", "resources"} do
        frame("resource-icons-"..pack.."-"..size,size,"--level 7 --tiles "..pack..safe)
    end
end
frame("resource-icons-guide","480x900","--level 7 --dialog guide")
frame("resource-icons-default-board-states","480x900","--default-match3 --level 7 --art-states")
frame("resource-icons-default-hud-states","480x900","--default-match3 --level 7 --hud-states")
