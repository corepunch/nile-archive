-- The opt-in walkthrough calls the ordinary reward and placement paths.
local rules, island, journey = require('rules'), require('island'), require('journey')
local R = require('state')
local economy = require('economy')
require('main')
R.test_mode, R.quiet, R.overlay, R.on_island = true, true, R.OV_NONE, false
R.island = city.new(); island.island_setup(R.island)
R.wonders, R.buildings = island.wonders, island.buildings
R.prog = {level=0, seed=1, wallet=purse(), lives=rules.LIVES, life_at=0, story_seen={}}
R.g = rules.game_start(0, 1)
check(R.debug_skip_level() and R.g.won and R.overlay == R.OV_RESULT, 'skip opens the normal result')
check(not R.debug_skip_level(), 'a completed board cannot be skipped twice')
local expected = rules.reward_breakdown(R.g, R.wonders, R.prog).total
R.claim_reward()
check(R.prog.level == 1 and R.prog.wallet[1] == expected[1], 'first clear grants the normal reward')
local wallet = R.prog.wallet[1]
R.claim_reward()
check(R.prog.level == 1 and R.prog.wallet[1] == wallet, 'claiming twice is inert')
R.on_island, R.overlay = false, R.OV_NONE
R.g = rules.game_start(0, 2)
check(R.debug_skip_level(), 'a replay can be skipped')
R.claim_reward()
check(R.prog.level == 1 and R.prog.wallet[4] == expected[4], 'replay does not advance story or grant first-clear stars')
R.prog.level = journey.wonder_levels[1]
for slot = 1, purse.MAX do R.prog.wallet[slot] = 9999 end
R.town_setup()
check(R.debug_complete_task() and island.owned(R.island, 0) == 1, 'town action confirms the earned building')
check(not R.debug_complete_task() or island.owned(R.island, 0) == 1, 'repeated action does not duplicate the building')
R.on_island, R.overlay = true, R.OV_NONE

local relic = economy.TOOL_THRESHOLD ~= nil
local function reward_piece(g, reward)
    for kind, piece in pairs(g.resource_yields) do
        if piece == reward then return kind end
    end
end

local function check_unlock(index, reward, already_placed)
    local level = journey.wonder_levels[index]
    R.prog.level = level
    if not already_placed then
        local before = R.make_board(level, 2)
        check(reward_piece(before, reward) == nil, 'the reward waits for confirmed construction')
        check(R.debug_complete_task(), 'the walkthrough confirms the earned building')
    end
    check(reward_piece(R.make_board(level - 1, 2), reward) == nil, 'older boards keep their original palette')
    local next_board = R.make_board(level, 2)
    local kind = reward_piece(next_board, reward)
    check(kind ~= nil and next_board.resource_yields[kind].amount == reward.amount,
        'the next board introduces the new piece and its yield')
    local spawned = false
    for _, tile in pairs(next_board.tiles) do
        if tile.kind == kind then spawned = true; break end
    end
    check(spawned, 'the piece is present on the first board')
    return next_board, kind
end

local first_tool = relic and economy.unlocks[1] or economy.pieces[5]
local second_tool = relic and economy.unlocks[8] or economy.pieces[10]
local resource = relic and economy.unlocks[2] or economy.pieces[4]
local board
if relic then board = check_unlock(1, first_tool, true)
else check_unlock(1, resource, true) end
if relic then check_unlock(2, resource)
else board = check_unlock(2, first_tool) end

local tool = first_tool.tool
check(board.tools[tool] == 0 and board.tool_meter[tool] == 0, 'construction unlocks an empty tool')
local function charge_match(g)
    R.reset_board(g)
    for i = 0, rules.CELLS - 1 do g.tiles[i] = rules.tile(-1) end
    local kind = reward_piece(g, first_tool)
    for a = 0, rules.CELLS - 1 do
        local b = rules.hex_neighbor(a, 1)
        local c = b >= 0 and rules.hex_neighbor(b, 1) or -1
        if g.active[a] and g.active[b] and g.active[c] then
            for _, cell in ipairs{a, b, c} do
                g.tiles[cell], g.chain[cell], g.ice[cell] = rules.tile(kind), 0, 0
            end
            break
        end
    end
    rules.game_matches(g, R.pending, -1)
    check(R.pending.hits == 3, 'bonus pieces form an ordinary match')
    R.finish_wave()
end
R.reduced_motion, R.sound = true, false
R.vfx_wave = function() end
charge_match(board)
check(board.tool_meter[tool] == 9 and R.prog.tool_stock[tool] == 9, 'a triple earns and banks nine charge points')
local new_board = R.make_board(board.level + 1, 2)
check(new_board.tool_meter[tool] == 9, 'partial charge carries to the next board')
-- Start near a full meter so the same test works with both games' thresholds.
new_board.tool_meter[tool] = new_board.tool_threshold - 8
charge_match(new_board)
check(new_board.tools[tool] == 1 and new_board.tool_meter[tool] == 1, 'a full meter grants a use and keeps the excess')
check(save.write('walkthrough-tool-stock', R.serialize), 'write stock to the walkthrough save fixture')
R.prog.tool_stock = nil
check(save.read('walkthrough-tool-stock', R.serialize), 'read stock from the walkthrough save fixture')

for slot = 1, purse.MAX do R.prog.wallet[slot] = 9999 end
for zone = 1, 5 do R.island:unlock(zone, R.prog.wallet) end
local later = relic and 8 or 7
for i = 3, later - 1 do
    R.prog.level = journey.wonder_levels[i]
    check(R.debug_complete_task(), 'place the intervening restoration')
end
local newest = check_unlock(later, second_tool)
check(newest.charge_tool == second_tool.tool and not reward_piece(newest, first_tool),
    'the first eligible board features only the newly unlocked bonus pieces')
check(newest.tools[tool] == 1 and newest.tool_meter[tool] == 1, 'a saved tool is available on the other family’s board')
local next_level = newest.level + 1
local even, odd = R.make_board(next_level, 2), R.make_board(next_level, 3)
check(even.charge_tool ~= odd.charge_tool and even.tool_meter[tool] == 1 and odd.tool_meter[tool] == 1,
    'later boards select one unlocked family by seed and keep both inventories')
R.reset_board(newest)
local target = 0
while not newest.active[target] do target = target + 1 end
check(rules.game_tool(newest, tool - 1, target, R.pending), 'spend the previously banked use')
R.finish_wave()
check(R.make_board(next_level, 2).tools[tool] == 0 and R.prog.tool_stock[tool] == 1,
    'changing boards cannot recover a spent tool')
