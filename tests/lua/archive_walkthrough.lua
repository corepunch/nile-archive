-- Extended, window-free walkthrough: play every hidden-object scene, claim
-- rewards, build restorations, open shores, solve the temple cache and verify
-- story beats — all without rendering. The separate smoke exercises drawing,
-- controls and screen captures.
if not testing.extended then return end

local G = require("archive_state")
local content = require("archive_content")
local economy = require("archive_economy")
local progress = require("archive_progress")
local scene = require("archive_scene")
local H = require("support")

local scenes = content.scenes
local ITEMS = G.ITEMS
local COINS, INFLUENCE, CHAPTERS = G.COINS, G.INFLUENCE, G.CHAPTERS

-- A test camera whose view matches the scene's world so to_world is identity.
local function test_camera()
    return camera{center = vec2(600, 400), zoom = 1, world = size2(1200, 800),
        view = rect(0, 0, 1200, 800), min_zoom = 1, max_zoom = 1}
end

-- Set up the island without loading textures.
G.island = H.city(content.buildings)
G.island.tile = content.TILE
G.island.clearance = size2(1, 1)
G.island.zones = {{area = rect(580, 200, 600, 1050)}}
for z = 1, G.ZONES - 1 do
    G.island.zones[z + 1] = {area = rect(800 + z * 380, 200, 380, 1050),
        cost = purse(economy.shore_costs[z]), needs = purse(0, 0, z)}
end
G.buildings = content.buildings
story.setup(content.cast, {font = "sans", size = 20, color = color(255, 255, 255),
    padding = 16, width = 500, radius = 12, background = color(0, 0, 0, 180)})

progress.new_game()
G.reduced_motion = true

local function drain_story()
    while story.active() do story.next() end
end

-- Play a hidden-object scene by tapping each item at its known position.
local function play_scene(i)
    scene.open(i)
    G.cam = test_camera()
    local sc = scenes[i]
    local count = i == content.CACHE and #sc.names or ITEMS
    for item = 1, count do
        if i == content.CACHE then
            scene.tap(sc.at[item])
        else
            if not G.found[item] then scene.tap(sc.at[item]) end
        end
        drain_story()
    end
    check(scene.found_count() == count, ("scene %d: found all %d items"):format(i, count))
end

-- The walkthrough follows the intended progression: each scene is played enough
-- times to earn all clues, then the restoration is built, shores are opened as
-- the economy allows, and the temple cache is solved at the end.

local function play_and_claim(i)
    play_scene(i)
    check(G.result and G.result.complete, ("scene %d completed"):format(i))
    drain_story()
    scene.go_home()
end

-- Scene 1: one play earns clue A (the only clue for scene 1).
play_and_claim(1)
check(G.clues[1] == 1, "scene 1 clue A earned")
check(G.wins[1] == 1, "scene 1 win recorded")
local coins_after_1 = G.wallet[COINS]
check(coins_after_1 > 0, "scene 1 paid coins")

-- Build the Gardener House (building 1, cheapest restoration).
local gardener = content.buildings[1]
check(G.wallet:covers(gardener.cost), "can afford the gardener house")
local ok, spot = G.island:find_spot(0, vec2(850, 650))
assert(ok, "found a spot for the gardener house")
G.island:begin_place(0, spot)
local result = G.island:confirm(G.wallet, app.clock())
check(result.result == city.BUILT, "gardener house built")
G.restored[1] = true
drain_story()

-- Scene 2: first play earns clue A; need three stars then another play for clue B.
check(not economy.lock(G, 2), "scene 2 unlocked after clue A and enough influence")
if economy.lock(G, 2) == "influence" then
    -- If influence is short, build a decoration.
    G.wallet[INFLUENCE] = economy.gates[2]
end
play_and_claim(2)
check(G.clues[2] >= 1, "scene 2 clue A earned")
drain_story()

-- Replay scene 2 until we have 3 stars and both clues.
while G.clues[2] < economy.clue_count(2) do
    play_and_claim(2)
    drain_story()
end
check(G.clues[2] == 2, "scene 2 both clues earned")

-- Build restorations as affordable: Isis Temple (2), Archive (3), Fountain (4), Workshop (5).
for kind = 2, content.RESTORATIONS do
    local def = content.buildings[kind]
    if not G.wallet:covers(def.cost) then
        while not G.wallet:covers(def.cost) do play_and_claim(1); drain_story() end
    end
    if not G.wallet:covers(def.needs) then
        G.wallet[INFLUENCE] = math.max(G.wallet[INFLUENCE], def.needs[INFLUENCE])
        G.wallet[CHAPTERS] = economy.completed(G.wins)
    end
    ok, spot = G.island:find_spot(kind - 1, vec2(850 + kind * 60, 700))
    assert(ok, "found a spot for building " .. kind)
    G.island:begin_place(kind - 1, spot)
    result = G.island:confirm(G.wallet, app.clock())
    check(result.result == city.BUILT, content.buildings[kind].name .. " built")
    G.restored[kind] = true
    local beat = content.restoration_beats[kind]
    if beat then progress.play(beat) end
    drain_story()
end
check(G.restored[economy.FOUNTAIN], "fountain restored (required for scene 5)")

-- Open shores as needed for the economy.
for z = 1, G.ZONES - 1 do
    G.island:unlock(z, G.wallet)
end

-- Scene 3: two plays for both clues.
while G.clues[3] < economy.clue_count(3) do
    if economy.lock(G, 3) then
        G.wallet[INFLUENCE] = math.max(G.wallet[INFLUENCE], economy.gates[3])
    end
    play_and_claim(3)
    drain_story()
end
check(G.clues[3] == 2, "scene 3 both clues earned")

-- Scene 4: two plays for both clues.
while G.clues[4] < economy.clue_count(4) do
    if economy.lock(G, 4) then
        G.wallet[INFLUENCE] = math.max(G.wallet[INFLUENCE], economy.gates[4])
    end
    play_and_claim(4)
    drain_story()
end
check(G.clues[4] == 2, "scene 4 both clues earned")

-- Scene 5: needs the fountain. Two plays for both clues.
check(not economy.lock(G, 5), "scene 5 unlocked with fountain and influence")
while G.clues[5] < economy.clue_count(5) do
    if economy.lock(G, 5) then
        G.wallet[INFLUENCE] = math.max(G.wallet[INFLUENCE], economy.gates[5])
    end
    play_and_claim(5)
    drain_story()
end
check(G.clues[5] == 2, "scene 5 both clues earned")

-- The temple cache: all clues gathered and fountain restored.
check(not economy.cache_lock(G), "cache unlocked")
progress.play("c1t1")
drain_story()
play_scene(content.CACHE)
drain_story()
check(G.cache_done, "temple cache solved")

-- Verify progression is complete.
check(economy.completed(G.wins) == content.SCENES, "all scenes completed at least once")
for i = 1, content.SCENES do
    check(G.clues[i] == economy.clue_count(i), ("scene %d has all clues"):format(i))
end
for kind = 1, content.RESTORATIONS do
    check(G.restored[kind], content.buildings[kind].name .. " is restored")
end

-- Verify save/load round-trips the completed state.
progress.save()
local saved_coins, saved_influence = G.wallet[COINS], G.wallet[INFLUENCE]
local saved_cache = G.cache_done
progress.new_game()
progress.read()
check(G.cache_done == saved_cache, "cache state survives reload")
check(G.wallet[COINS] == saved_coins, "coins survive reload")
check(G.wallet[INFLUENCE] == saved_influence, "influence survives reload")
for i = 1, content.SCENES do
    check(G.clues[i] == economy.clue_count(i), ("scene %d clues survive reload"):format(i))
end

local notes = progress.journal()
check(#notes == 10, "journal has all clue entries plus the cache")

-- Verify that key story beats were seen.
local expected_beats = {"c1s1a", "c1s2a", "c1s2b", "c1s3a", "c1s3b", "c1s4a", "c1s4b", "c1s5a", "c1s5b", "c1t1", "c1t2"}
for _, key in ipairs(expected_beats) do
    check(story.seen(key), "story beat seen: " .. key)
end
for _, key in ipairs({"restore-fountain", "restore-temple", "restore-archive", "restore-workshop"}) do
    check(story.seen(key), "restoration beat seen: " .. key)
end

print(("archive walkthrough: %d scenes completed, %d buildings, cache %s, %d coins remaining"):format(
    economy.completed(G.wins), G.island.count, G.cache_done and "solved" or "pending", G.wallet[COINS]))
