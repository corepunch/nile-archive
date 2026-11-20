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
replay.earnings, replay.moves = {80, 0, 0}, 999
check(not rules.progress_reward(p, replay, island.wonders), "a failed wish banks nothing")
replay.won = true
check(rules.progress_reward(p, replay, island.wonders), "replay can bank resources")
check(p.wallet[1] == 80 and p.wallet[4] == 1 and p.level == 1, "replays pay actual matches")
check(island.island_place_next(c, p.wallet, p.level, 0), "funded arch can be built")
check(p.wallet[1] == 80 - island.buildings[island.kinds.arch + 1].cost[1], "confirmed placement debits Gold once")

local wine = rules.game_start(1, 18, island.wonder_count(c))
check(#wine.spawn_kinds == 5 and wine.resource_yields[8].amount == 3, "confirmed arch adds mulled wine")
local plain = rules.game_start(1, 18, 0)
check(not plain.resource_yields[8], "a cleared board alone does not add mulled wine")

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
line(wine, 8, 3, wave)
check(wine.earnings[2] == 9 and wine.earnings[3] == 0, "mulled wine earns treats to fund the stable")
local wood = rules.game_start(11, 18)
check(#wood.spawn_kinds == 5 and wood.resource_yields[4].slot == 3
      and not rules.game_start(10, 18).resource_yields[4], "pine materials start after the workshop opens")
line(wood, 4, 4, wave)
check(wood.earnings[3] == 20 and wood.earnings[1] == 0 and wood.earnings[2] == 0,
      "four pieces credit four times the base resource")
local hammer = rules.game_start(6, 42, {reindeer_stable=true})
local has_vase = false
for _, kind in ipairs(hammer.spawn_kinds) do if kind == 20 then has_vase = true end end
check(has_vase and #hammer.spawn_kinds == 5 and not hammer.resource_yields[20],
      "the stable adds a score-only vase in the mitten's slot")
for _ = 1, 7 do line(hammer, economy.SPECIAL_KIND, 4, wave) end
check(hammer.tools[1] == 0 and hammer.tool_meter[1] == 84, "28 matched hammers leave the tool uncharged")
line(hammer, economy.SPECIAL_KIND, 3, wave)
line(hammer, economy.SPECIAL_KIND, 3, wave)
check(hammer.tools[1] == 1 and hammer.tool_meter[1] == hammer.tool_threshold and hammer.earnings[1] == 0,
      "extra matched hammers cannot bank a second hit")
check(rules.game_tool(hammer, 0, column_top(hammer), wave) and hammer.tools[1] == 0,
      "the charged hammer can be spent")

local bakery, cocoa = rules.game_start(21, 42), rules.game_start(31, 42)
check(#bakery.spawn_kinds == 5 and bakery.resource_yields[7].amount == 4 and not bakery.resource_yields[8],
      "the bakery replaces mulled wine with gingerbread")
check(#cocoa.spawn_kinds == 5 and cocoa.resource_yields[11].amount == 5 and not cocoa.resource_yields[7],
      "the kiosk replaces gingerbread with cocoa")
local quarried = {lumber=true, chapel=true}
local masonry = rules.game_start(26, 42, quarried)
check(#masonry.spawn_kinds == 5 and masonry.resource_yields[12].slot == 3 and masonry.resource_yields[12].amount == 7
      and not masonry.resource_yields[4], "the chapel gives dressed stone the timber slot")
check(rules.game_start(25, 42, quarried).resource_yields[4].amount == 5,
      "replays of earlier wishes retain the timber")
check(not rules.game_start(26, 42, {lumber=true}).resource_yields[12], "dressed stone requires construction")
local later = economy.board_loadout(55, {chapel=true, toys=true, log_cabin=true}, 42)
check(later[6].slot == 1 and later[6].amount == 7 and later[12].slot == 3 and later[21].amount == 6,
      "toys earn tokens and the lakeside smokehouse's trout earns treats alongside dressed stone")
local gifts = {glassblower=true, rink=true, santa_workshop=true, sleigh=true, tree=true}
local snowman, reindeer, cap = economy.board_loadout(82, gifts), economy.board_loadout(87, gifts), economy.board_loadout(97, gifts)
check(snowman[17].amount == 10 and not snowman[14] and reindeer[18].amount == 11 and not reindeer[17]
      and cap[19].amount == 12 and not cap[18], "premium goods upgrade the same coin slot one at a time")
local _, carousel = economy.board_loadout(77, {carousel=true})
check(carousel.win_income[2] == 30, "the carousel still pays its Treats per win")
local winter_catch = economy.board_loadout(47, {log_cabin=true, station_kiosk=true})
check(winter_catch[16].slot == 2 and winter_catch[16].amount == 7 and not winter_catch[21],
      "the station kiosk's pretzels upgrade the smokehouse's trout in the late Treats slot")

local lightning = rules.game_start(9, 7, {candles=true, bonus_charge={[4]=90}})
check(rules.game_tool_area(lightning, 3, rules.hex_center()) == nil,
      "the lantern's lightning is an instant tool")
check(rules.game_tool(lightning, 3, nil, wave) and wave.hits == 15
      and lightning.tools[4] == 0 and lightning.tool_meter[4] == 0,
      "the lantern spends a single charge to hit fifteen cells")
local future = rules.game_start(5, 99)
future.won = true
check(not rules.progress_reward(p, future, island.wonders), "future wish cannot be claimed")
