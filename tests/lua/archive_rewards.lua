local archive = require("archive_economy")
local content = require("archive_content")
local G = require("archive_state")
local progress = require("archive_progress")
local H = require("support")

local function new_state()
    return {wallet = purse(0, 10), wins = {0, 0, 0, 0, 0}, stars = {0, 0, 0, 0, 0},
        clues = {0, 0, 0, 0, 0}, restored = {}}
end

local s = new_state()
local function complete(i, stars, perfect)
    local res = {complete = true, stars = stars, perfect = perfect}
    local influence = s.wallet[2]
    check(archive.claim(s, i, res), "eligible search pays")
    local coins = s.wallet[1]
    check(not archive.claim(s, i, res) and s.wallet[1] == coins, "a result pays only once")
    check(s.wallet[2] == influence, "searches do not grant Influence")
    return res
end

check(not archive.lock(s, 1) and archive.lock(s, 2) == "clue", "only the opening search is ready")
local res = complete(1, 1)
check(res.payout.coins == 140 and res.clue == 1, "slow first clear earns the first clue and enough to build")
check(archive.lock(s, 2) == "influence", "the first clue does not replace construction")
local fountain = archive.buildings[archive.FOUNTAIN]
s.wallet[1], s.wallet[2] = s.wallet[1] - fountain.coins, s.wallet[2] + fountain.influence
s.restored[archive.FOUNTAIN] = true
check(not archive.lock(s, 2), "the fountain opens the library")
check(complete(2, 1).clue == 1, "the first clear finds clue A")
s.wallet[2] = 90
check(archive.lock(s, 3) == "clue", "Influence cannot bypass clue B")
check(complete(2, 1).stars == 2, "the second clear guarantees two Stars")
res = complete(2, 1)
check(res.stars == 3 and not res.clue, "the clear that earns the third Star does not earn clue B")
check(complete(2, 1).clue == 2 and not archive.lock(s, 3), "a later clear earns clue B and opens the temple")
res = complete(2, 3, true)
check(not res.clue and res.payout.coins == 100, "a replay pays without another clue or milestone")
check(complete(3, 3).clue == 1 and complete(3, 3).clue == 2, "a fast search needs two clears for both clues")
complete(4, 3)
complete(4, 3)
s.restored[archive.FOUNTAIN] = nil
check(archive.lock(s, 5) == "fountain", "Influence from decorations cannot skip the restored fountain")
s.restored[archive.FOUNTAIN] = true
complete(5, 3)
check(archive.cache_lock(s) == "clue", "the cache waits for clue B from the library revisit")
complete(5, 3)
check(archive.completed(s.wins) == 5, "island requirements count each search once")
local coins, stars = s.wallet[1], s.wallet[4]
check(archive.claim_cache(s) and s.wallet[1] == coins + 150 and s.wallet[4] == stars, "the cache pays Coins without Stars")
check(not archive.claim_cache(s) and s.wallet[1] == coins + 150, "the cache cannot pay twice")
check(not archive.claim(s, 1, {complete = false, stars = 3}), "an abandoned search cannot pay")

-- Old saves keep visited locations, even if the newly required earlier clue
-- has yet to be found. A search visited out of order cannot reveal a new clue.
G.island = H.city(content.buildings)
G.buildings = content.buildings
progress.new_game()
save.inject("progress", [[version=3
coins=42
influence=50
wins=1 1 1
stars=3 2 3
city.count=2
city.0.pos=850 650
city.0.type=3
city.1.pos=910 700
city.1.type=5
]])
progress.read()
check(G.migrated and G.wins[3] == 1 and G.wins[5] == 0, "v3 search indices are preserved and new entries start fresh")
check(G.restored[archive.FOUNTAIN] and G.wallet[2] == 50 + content.buildings[6].reward[2], "legacy fountain and decoration credit are restored")
local notes = progress.journal()
check(#notes == 2 and notes[1].id == "c1s1a" and notes[2].id == "c1s2a", "migrated notes follow the clue order")
check(not archive.lock(G, 3), "legacy visited temple remains accessible")
res = {complete = true, stars = 3}
check(archive.claim(G, 3, res) and not res.clue, "a legacy replay cannot spoil a later clue")
save.inject("unused", "")

-- Version 4 had five search slots and one cache flag. Extend without replaying
-- its reward, losing its prior clues, or treating zero-valued project flags as owned.
progress.new_game()
save.inject("progress", [[version=4
coins=321
influence=90
wins=1 2 2 2 2
stars=3 3 3 3 3
clues=1 2 2 2 2
cache_done=1
city.count=2
city.0.pos=850 650
city.0.type=0
city.1.pos=910 700
city.1.type=3
]])
progress.read()
check(G.caches[1] == 1 and G.cache_done and G.caches[2] == 0 and G.caches[3] == 0,
    "v4 completed first cache migrates to the correct chapter")
check(G.wins[5] == 2 and G.clues[5] == 2 and G.wins[6] == 0 and G.stars[15] == 0 and G.clues[15] == 0,
    "v4 search records survive and later searches initialize empty")
check(G.wallet[1] == 321 and G.wallet[2] == 90 and G.projects[1] == 0,
    "v4 wallet survives without granting future projects")
check(not archive.claim_cache(G, 1) and G.wallet[1] == 321,
    "v4 completed cache cannot pay again")
check(archive.lock(G, 6) == "influence", "v4 completed cache unlocks the next chapter gate")
progress.save()
save.inject("unused", "")
progress.new_game()
progress.read()
check(G.caches[1] == 1 and G.cache_done and G.wins[6] == 0 and G.projects[1] == 0,
    "migrated v5 save preserves chapter and project flags")

-- Reset only the cache flag to exercise a fresh first-cache claim below.
G.cache_done, G.caches[1] = false, 0

for i = 1, 5 do G.clues[i] = archive.clue_count(i) end
check(archive.claim_cache(G), "the restored cache is payable")
local saved_coins, saved_influence = G.wallet[1], G.wallet[2]
progress.save()
progress.new_game()
progress.read()
check(G.cache_done and G.caches[1] == 1 and #progress.journal() == 10 and not G.migrated, "saved first cache and journal survive reload")
check(G.wallet[1] == saved_coins and G.wallet[2] == saved_influence and G.restored[archive.FOUNTAIN],
    "reload preserves the reward and restoration without double credit")
check(not archive.claim_cache(G), "reloading cannot make the cache payable again")
G.wallet[1] = 100
check(archive.claim_project(G, 1), "first project is available after first cache")
progress.save()
local after_project = G.wallet[2]
progress.new_game()
progress.read()
check(G.projects[1] == 1 and G.wallet[1] == 0 and G.wallet[2] == after_project,
    "project purchase and wallet survive reload")
G.wallet[1] = 100
check(not archive.claim_project(G, 1) and G.wallet[1] == 100 and G.wallet[2] == after_project,
    "reloading cannot make a project payable again")
