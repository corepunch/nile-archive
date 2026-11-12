-- Exercise the complete three-chapter route through actual scene taps, clue
-- awards, city purchases, project transactions and save/reload.
if not testing.extended then return end

local G = require("archive_state")
local content = require("archive_content")
local economy = require("archive_economy")
local progress = require("archive_progress")
local scene = require("archive_scene")
local H = require("support")
local COINS, INFLUENCE = G.COINS, G.INFLUENCE

G.island = H.city(content.buildings)
G.island.tile = content.TILE
G.island.clearance = size2(0, 0)
G.island.zones = {{area = rect(580, 200, 600, 1050)}}
G.buildings = content.buildings
story.setup(content.cast, {font = "sans", size = 20, color = color(255, 255, 255),
    padding = 16, width = 500, radius = 12, background = color(0, 0, 0, 180)})
G.reduced_motion = true

local function drain_story()
    while story.active() do story.next() end
end

local function play_scene(id, slow)
    check(not progress.blocker(id), ("scene %d is available"):format(id))
    scene.start(id)
    drain_story()
    G.cam = camera{center = vec2(600, 400), zoom = 1, world = size2(1200, 800),
        view = rect(0, 0, 1200, 800), min_zoom = 1, max_zoom = 1}
    G.clock = slow and 151 or 0
    G.misses = 1 -- compare the budget without optional perfect bonuses
    local sc = content.scenes[id]
    local count = content.cache_chapter(id) and #sc.names or G.ITEMS
    for item = 1, count do
        scene.tap(sc.at[item])
        if not content.cache_chapter(id) then scene.refill_slots(app.time() + 1, .8) end
        drain_story()
    end
    check(scene.found_count() == count, ("scene %d accepts all listed items"):format(id))
    if not content.cache_chapter(id) then
        check(G.result and G.result.complete and G.result.claimed, ("scene %d pays once"):format(id))
    end
    scene.go_home()
end

local function restoration(kind)
    local def = content.buildings[kind]
    check(G.wallet:covers(def.cost) and G.wallet:covers(def.needs), def.name .. " is affordable and unlocked")
    local ok, spot = G.island:find_spot(kind - 1, vec2(850 + kind * 60, 700))
    check(ok, def.name .. " has a valid placement")
    if not ok then return end
    G.island:begin_place(kind - 1, spot)
    local result = G.island:confirm(G.wallet, app.clock())
    check(result.result == city.BUILT, def.name .. " is built")
    G.restored[kind] = true
end

local function complete_clues(id, slow)
    local clears = 0
    for _ = 1, 4 do
        if G.clues[id] == economy.clue_count(id) then break end
        play_scene(id, slow)
        clears = clears + 1
    end
    check(G.clues[id] == economy.clue_count(id), ("scene %d awards its clues"):format(id))
    return clears
end

local function run_route(slow)
    progress.new_game()
    local count = complete_clues(1, slow)
    restoration(economy.FOUNTAIN)
    count = count + complete_clues(2, slow)
    restoration(2) -- temple gives the 50 Influence needed for search 3
    count = count + complete_clues(3, slow)
    restoration(3) -- archive gives 75 Influence for search 4
    count = count + complete_clues(4, slow)
    restoration(economy.WORKSHOP)
    count = count + complete_clues(5, slow)
    play_scene(content.CACHES[1], slow)
    check(G.caches[1] == 1 and G.cache_done, "first cache records both completion flags")
    check(count == (slow and 17 or 9), "chapter 1 clear count matches the budget")
    check(G.wallet[COINS] == (slow and 1520 or 920) and G.wallet[INFLUENCE] == 90,
        "chapter 1 wallet matches the budget")
    progress.save()
    progress.new_game()
    progress.read()
    check(G.caches[1] == 1 and economy.lock(G, 6) == "influence",
        "first cache survives reload and chapter 2 waits for Influence")

    for chapter = 2, 3 do
        local chapter_clears = 0
        for slot = 1, 5 do
            local project = (chapter - 2) * 5 + slot
            local id = (chapter - 1) * 5 + slot
            check(economy.claim_project(G, project), ("project %d is affordable"):format(project))
            chapter_clears = chapter_clears + complete_clues(id, slow)
        end
        check(chapter_clears == (slow and 20 or 10), ("chapter %d clear count matches budget"):format(chapter))
        local cache = content.CACHES[chapter]
        play_scene(cache, slow)
        check(G.caches[chapter] == 1, ("chapter %d cache is recorded"):format(chapter))
        local coins = G.wallet[COINS]
        check(not economy.claim_cache(G, chapter) and G.wallet[COINS] == coins, "cache cannot pay twice")
        progress.save()
        local influence = G.wallet[INFLUENCE]
        progress.new_game()
        progress.read()
        check(G.caches[chapter] == 1 and G.wallet[COINS] == coins and G.wallet[INFLUENCE] == influence,
            ("chapter %d progress survives reload"):format(chapter))
        for project = (chapter - 2) * 5 + 1, (chapter - 1) * 5 do
            check(G.projects[project] == 1, ("project %d survives reload"):format(project))
        end
    end
    check(G.wallet[COINS] == (slow and 3240 or 1040) and G.wallet[INFLUENCE] == 375,
        "finished wallet matches the complete campaign budget")
    check(economy.completed(G.wins) == 15 and #progress.journal() == 32, "all searches and journal entries are recorded")
    for chapter = 1, 3 do
        local first = chapter == 1 and 2 or 1
        for slot = first, 5 do
            check(story.seen(("c%ds%da"):format(chapter, slot)) and story.seen(("c%ds%db"):format(chapter, slot)),
                ("chapter %d scene %d clue beats were seen"):format(chapter, slot))
        end
        check(story.seen(("c%dt2"):format(chapter)), ("chapter %d finale was seen"):format(chapter))
    end
    check(story.seen("c1s1a"), "opening clue was seen")
end

run_route(false)
run_route(true)
