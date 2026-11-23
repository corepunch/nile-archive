-- TRY AGAIN deals a new board: a lost attempt moves the seed on, as a win does.
local rules = require("rules")
local island = require("island")
local R = require("state")
require("main")

local saved_prog, saved_g, saved_quiet, saved_island = R.prog, R.g, R.quiet, R.island
R.quiet = true
R.island = city.new(); island.island_setup(R.island)
R.prog = {level=3, seed=12345, wallet=purse(), story_seen={}, bonus_charge={}}

local function deal()
    local kinds = {}
    for i = 0, rules.CELLS - 1 do kinds[#kinds + 1] = R.g.tiles[i] and R.g.tiles[i].kind or -2 end
    return table.concat(kinds, ",")
end

R.start_level(3)
local first, seed = deal(), R.prog.seed
R.start_level(3)
check(deal() == first and R.prog.seed == seed, "starting a level again without losing keeps its deal")

R.g.lost = true
R.start_level(3)
check(R.prog.seed ~= seed, "a lost attempt moves the seed on")
check(deal() ~= first, "the retry deals a different board")

R.prog, R.g, R.quiet, R.island = saved_prog, saved_g, saved_quiet, saved_island
