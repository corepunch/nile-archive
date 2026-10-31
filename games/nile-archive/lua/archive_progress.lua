-- archive_progress.lua — what the player keeps between sessions: the wallet,
-- chapter wins and best stars, the island and the story beats already seen;
-- and the questions the screens ask of that progress.
local G = require("archive_state")
local content = require("archive_content")
local economy = require("archive_economy")
local COINS, INFLUENCE, CHAPTERS, STARS = G.COINS, G.INFLUENCE, G.CHAPTERS, G.STARS

local M = {}

function M.new_game()
    G.wallet = purse(economy.START_COINS, economy.START_INFLUENCE)
    G.wins = {0, 0, 0}
    G.stars = {0, 0, 0}
    G.island.count = 0
    G.island.open = 1
    G.island:add(G.island:snap(vec2(850, 650), 0), 0, 0)
end

local function serialize(s)
    s:int("version", 3)
    G.wallet[COINS] = s:int("coins", G.wallet[COINS])
    G.wallet[INFLUENCE] = s:int("influence", G.wallet[INFLUENCE])
    G.wins = s:ints("wins", G.wins)
    G.stars = s:ints("stars", G.stars)
    G.wallet[CHAPTERS] = economy.completed(G.wins)   -- non-spendable requirements, rebuilt from saved records
    G.wallet[STARS] = economy.stars(G.stars)
    G.island:serialize(s)
    story.serialize(s)
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

-- The next chapter to win and whether it can be played now; nil once all are won.
function M.chapter_goal()
    for i = 1, content.SCENES do
        if G.wins[i] == 0 then return i, economy.can_play(G.wins, G.wallet[INFLUENCE], i) end
    end
    return nil, true
end

-- Player level from influence: levels at 0, 10, 40, 90, 160 ... Returns the
-- level, the progress towards the next one and the influence it needs.
function M.level_of(influence)
    local n = math.floor(math.sqrt(influence / 10))
    local lo, hi = 10 * n * n, 10 * (n + 1) * (n + 1)
    return n + 1, (influence - lo) / (hi - lo), hi
end

return M
