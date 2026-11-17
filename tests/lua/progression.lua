local rules = require("rules")
local island = require("island")

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

local wood = rules.game_start(1, 18, island.wonder_count(c))
check(#wood.spawn_kinds == 5 and wood.resource_yields[4].amount == 5, "confirmed arch adds firewood")
local plain = rules.game_start(1, 18, 0)
check(not plain.resource_yields[4], "a cleared board alone does not add firewood")

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
line(wood, 4, 4, wave)
check(wood.earnings[3] == 40 and wood.earnings[1] == 0 and wood.earnings[2] == 0,
      "four pieces credit eight times the base resource")
local hammer = rules.game_start(4, 42, 2)
hammer.tool_meter[1] = 194
line(hammer, 5, 3, wave)
check(hammer.tools[1] == 1 and hammer.tool_meter[1] == 3 and hammer.earnings[1] == 0,
      "matching hammers earns a charge and no Gold")
check(rules.game_tool(hammer, 0, column_top(hammer), wave) and hammer.tools[1] == 0,
      "the charged hammer can be spent")

local lightning = rules.game_start(19, 7, 7)
lightning.tools[3] = 1
local at = rules.hex_center()
local area = rules.game_tool_area(lightning, 2, at)
check(rules.game_tool(lightning, 2, at, wave) and wave.hits == 15, "lightning hits 15 cells")
local pane_hit = false
for i = 0, rules.CELLS - 1 do
    check(area[i] == wave.mask[i], "lightning previews exactly the cells it hits")
    if area[i] and lightning.oil[i] > 0 then pane_hit = true end
end
check(pane_hit and lightning.tools[3] == 0, "lightning spends one charge and reaches a blue pane")
local future = rules.game_start(5, 99)
future.won = true
check(not rules.progress_reward(p, future, island.wonders), "future wish cannot be claimed")
