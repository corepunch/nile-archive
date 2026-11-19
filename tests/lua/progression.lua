local rules = require("rules")
local island = require("island")
local economy = require("economy")

local p = {level=0, seed=1, wallet=purse()}
local c = city.new()
island.island_setup(c)

local g = rules.game_start(0, 7, 0)
g.won, g.moves = true, 999
check(rules.progress_reward(p, g, island.wonders), "first clear pays")
check(not rules.progress_reward(p, g, island.wonders), "result pays once")
check(p.wallet[1] == 0 and p.wallet[4] == 1 and p.level == 1, "first clear only pays matched Gold and counts the board")
check(not island.can_buy(c, p.wallet, p.level, 0), "story checkpoint does not give away the arch")

local replay = rules.game_start(0, 7, 0)
replay.earnings, replay.moves = {60, 0, 0}, 999
check(not rules.progress_reward(p, replay, island.wonders), "a failed wish banks nothing")
replay.won = true
check(rules.progress_reward(p, replay, island.wonders), "replay can bank resources")
check(p.wallet[1] == 60 and p.wallet[4] == 1 and p.level == 1, "replays pay actual matches")
check(island.island_place_next(c, p.wallet, p.level, 0), "funded arch can be built")
check(p.wallet[1] == 10, "confirmed placement debits Gold once")

local cider = rules.game_start(1, 18, island.wonder_count(c))
check(#cider.spawn_kinds == 5 and cider.resource_yields[8].amount == 3, "confirmed arch adds cider")
local plain = rules.game_start(1, 18, 0)
check(not plain.resource_yields[8], "a cleared board alone does not add cider")

-- The top of the first column of four playable cells, straight down.
local function column_top(board)
    for i = 0, rules.CELLS - 1 do
        local ok, cell = true, i
        for _ = 1, 4 do
            ok = ok and cell >= 0 and rules.game_cell_active(board, cell) and board.stone_hp[cell] == 0
            cell = ok and rules.hex_neighbor(cell, 1) or -1
        end
        if ok then return i end
    end
end
local function line(board, kind, length, wave)
    for i = 0, rules.CELLS - 1 do board.tiles[i] = rules.tile(-1) end
    local cell = column_top(board)
    for _ = 1, length do
        board.tiles[cell], board.chain[cell] = rules.tile(kind), 0
        cell = rules.hex_neighbor(cell, 1)
    end
    rules.game_matches(board, wave, -1)
    rules.game_apply(board, wave)
end
local wave = rules.new_match()
line(cider, 8, 3, wave)
check(cider.earnings[2] == 9 and cider.earnings[3] == 0, "cider earns treats to fund the stable")
local wood = rules.game_start(4, 18)
check(#wood.spawn_kinds == 5 and wood.resource_yields[4].slot == 3
      and not rules.game_start(3, 18).resource_yields[4], "pine materials start after the workshop opens")
line(wood, 4, 4, wave)
check(wood.earnings[3] == 20 and wood.earnings[1] == 0 and wood.earnings[2] == 0,
      "four pieces credit four times the base resource")
local hammer = rules.game_start(2, 42, {reindeer_stable=true})
for _ = 1, 7 do line(hammer, economy.SPECIAL_KIND, 4, wave) end
check(hammer.tools[1] == 0 and hammer.tool_meter[1] == 84, "28 matched hammers leave the tool uncharged")
line(hammer, economy.SPECIAL_KIND, 3, wave)
line(hammer, economy.SPECIAL_KIND, 3, wave)
check(hammer.tools[1] == 1 and hammer.tool_meter[1] == hammer.tool_threshold and hammer.earnings[1] == 0,
      "extra matched hammers cannot bank a second hit")
check(rules.game_tool(hammer, 0, column_top(hammer), wave) and hammer.tools[1] == 0,
      "the charged hammer can be spent")

local bakery, cocoa = rules.game_start(7, 42), rules.game_start(9, 42)
check(#bakery.spawn_kinds == 5 and bakery.resource_yields[7].amount == 4 and not bakery.resource_yields[8],
      "the bakery replaces cider with gingerbread")
check(#cocoa.spawn_kinds == 5 and cocoa.resource_yields[11].amount == 5 and not cocoa.resource_yields[7],
      "the kiosk replaces gingerbread with cocoa")

local lightning = rules.game_start(9, 7, {candles=true, bonus_charge={[4]=90}})
check(rules.game_tool_area(lightning, 3, rules.hex_center()) == nil,
      "the lantern's lightning is an instant tool")
check(rules.game_tool(lightning, 3, nil, wave) and wave.hits == 15
      and lightning.tools[4] == 0 and lightning.tool_meter[4] == 0,
      "the lantern spends a single charge to hit fifteen cells")
local future = rules.game_start(5, 99)
future.won = true
check(not rules.progress_reward(p, future, island.wonders), "future wish cannot be claimed")
