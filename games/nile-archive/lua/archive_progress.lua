-- archive_progress.lua — what the player keeps between sessions: the wallet,
-- chapter wins and best stars, the island and the story beats already seen;
-- and the questions the screens ask of that progress.
local G = require("archive_state")
local content = require("archive_content")
local economy = require("archive_economy")
local beats = require("archive_story")
local COINS, INFLUENCE, CHAPTERS, STARS = G.COINS, G.INFLUENCE, G.CHAPTERS, G.STARS

local M = {}

function M.new_game()
    G.wallet = purse(economy.START_COINS, economy.START_INFLUENCE)
    G.wins, G.stars, G.clues, G.restored = {}, {}, {}, {[1] = true}
    for i = 1, content.SCENES do G.wins[i], G.stars[i], G.clues[i] = 0, 0, 0 end
    G.cache_done, G.migrated = false, false
    G.island.count = 0
    G.island.open = 1
    G.island:add(G.island:snap(vec2(850, 650), 0), 0, 0)
end

local function serialize(s)
    local reading = save.is_reading(s)
    local version = s:int("version", reading and 3 or 4)
    G.wallet[COINS] = s:int("coins", G.wallet[COINS])
    G.wallet[INFLUENCE] = s:int("influence", G.wallet[INFLUENCE])
    G.wins = s:ints("wins", G.wins)
    G.stars = s:ints("stars", G.stars)
    G.clues = s:ints("clues", G.clues)
    G.cache_done = s:int("cache_done", G.cache_done and 1 or 0) ~= 0
    G.reduced_motion = s:int("reduced_motion", G.reduced_motion and 1 or 0) ~= 0
    G.wallet[CHAPTERS] = economy.completed(G.wins)   -- non-spendable requirements, rebuilt from saved records
    G.wallet[STARS] = economy.stars(G.stars)
    G.island:serialize(s)
    story.serialize(s)
    if not reading then return end
    G.restored = {}
    if version < 4 then
        G.migrated = true
        -- Credit only the contiguous clues from older saves. The journal lists
        -- their notes in story order and visited searches stay playable.
        for i = 1, content.SCENES do
            if G.wins[i] == 0 then break end
            G.clues[i] = G.stars[i] == 3 and economy.clue_count(i) or 1
            if G.clues[i] < economy.clue_count(i) then break end
        end
    end
    for _, b in ipairs(G.island.items) do
        local kind = b.type + 1
        if kind <= content.RESTORATIONS then G.restored[kind] = true
        elseif version < 4 then G.wallet[INFLUENCE] = G.wallet[INFLUENCE] + G.buildings[kind].reward[INFLUENCE] end
    end
end

function M.save() save.write("progress", serialize) end
-- Land saved buildings on the grid, whichever tile projection they were saved under.
local function rehome_saved()
    local c = G.island
    local items = c.items
    c.count = 0
    for _, b in ipairs(items) do
        local spot = c:snap(b.pos, b.type)
        local ok = c:can_place(spot, b.type, -1)
        if not ok then ok, spot = c:find_spot(b.type, spot) end
        c:add(ok and spot or b.pos, b.type, b.stamp)
    end
end

function M.read()
    if save.read("progress", serialize) then rehome_saved() end
end

-- Progress of the old HTML version lived in localStorage["nile-v1"] as JSON.
function M.import_legacy()
    local json = app.web_storage("nile-v1")
    if not json then return end
    local function num(key) return tonumber(json:match('"' .. key .. '"%s*:%s*(-?%d+)')) or 0 end
    local wins = json:match('"wins"%s*:%s*%[([^%]]*)%]') or "0,0,0"
    local t = ("coins=%d\ninfluence=%d\nwins=%s\ncity.zones=%d\n"):format(num("coins"), num("prestige"), wins:gsub(",", " "), num("zones"))
    local n = 0
    for x, y, kind in (json:match('"buildings"%s*:%s*%[(.*)%]') or ""):gmatch("%[%s*(-?[%d.]+)%s*,%s*(-?[%d.]+)%s*,%s*(-?%d+)%s*%]") do
        t = t .. ("city.%d.pos=%s %s\ncity.%d.type=%s\n"):format(n, x, y, n, kind)
        n = n + 1
    end
    save.inject("progress", t .. ("city.count=%d\n"):format(n))
end

function M.play(key)
    return story.play(key, beats[key].lines)
end

function M.journal()
    local notes = {}
    for i, sc in ipairs(content.scenes) do
        if i == content.CACHE then
            if G.cache_done then notes[#notes + 1] = {id = "c1t2", title = sc.title, note = beats.c1t2.note} end
        else
            for j = 1, G.clues[i] do
                local key = sc.clues[j]
                notes[#notes + 1] = {id = key, title = sc.title, note = beats[key].note}
            end
        end
    end
    return notes
end

function M.blocker(i)
    local lock
    if i == content.CACHE then lock = economy.cache_lock(G)
    else lock = economy.lock(G, i) end
    if lock == "influence" then return ("Ещё %d влияния"):format(economy.gates[i] - G.wallet[INFLUENCE]), true end
    if lock == "fountain" then return "Восстановите фонтан", true end
    if lock == "clue" then return i == content.CACHE and "Соберите все улики" or "Нужны предыдущие улики", false end
    if lock == "done" then return "Тайник открыт", false end
end

-- The next search with an outstanding clue, or the temple cache.
function M.chapter_goal()
    for i = 1, content.SCENES do
        if G.clues[i] < economy.clue_count(i) then return i, M.blocker(i) end
    end
    if not G.cache_done then return content.CACHE, M.blocker(content.CACHE) end
end

-- Player level from influence: levels at 0, 10, 40, 90, 160 ... Returns the
-- level, the progress towards the next one and the influence it needs.
function M.level_of(influence)
    local n = math.floor(math.sqrt(influence / 10))
    local lo, hi = 10 * n * n, 10 * (n + 1) * (n + 1)
    return n + 1, (influence - lo) / (hi - lo), hi
end

return M
