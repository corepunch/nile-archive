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

local relic = economy.bonuses ~= nil
local function reward_piece(g, reward)
    for kind, piece in pairs(g.resource_yields) do
        if piece == reward then return kind end
    end
end

-- Place what each intervening clear opens: one story building, or in Relic
-- Rush every ladder restoration due by then.
local function place_due(level)
    R.prog.level = level
    if not island.next_step then
        check(R.debug_complete_task(), 'place the intervening restoration')
        return
    end
    while island.next_step(R.island, level) do
        local count = R.island.count
        local placed = R.debug_complete_task() and R.island.count == count + 1
        check(placed, 'place the intervening restoration')
        if not placed then break end
    end
end
local function check_unlock(index, reward, already_placed)
    local level = journey.wonder_levels[index]
    R.prog.level = level
    if not already_placed then
        -- A ladder places the stalls between story buildings first.
        if island.next_step then place_due(level - 1) end
        R.prog.level = level
        local before = R.make_board(level, 2)
        check(reward_piece(before, reward) == nil, 'the reward waits for confirmed construction')
        check(R.debug_complete_task(), 'the walkthrough confirms the earned building')
    end
    if reward.rank ~= 2 then
        check(reward_piece(R.make_board(level - 1, 2), reward) == nil, 'older boards keep their original palette')
    end
    local next_board = R.make_board(level, 2)
    local kind = reward_piece(next_board, reward)
    check(kind ~= nil and next_board.resource_yields[kind].amount == reward.amount,
        'the next board introduces the new piece and its yield')
    local spawned = false
    for _, tile in pairs(next_board.tiles) do
        if tile.kind == kind then spawned = true; break end
    end
    check(spawned, 'the piece is present on the first board')
    return next_board
end

local first_tool = relic and economy.unlocks[1].bonus or economy.pieces[5]
local second_tool = relic and economy.unlock_of("observatory").bonus or economy.pieces[10]
local resource = relic and economy.unlocks[2] or economy.pieces[4]
local board
if relic then board = check_unlock(1, first_tool, true)
else check_unlock(1, resource, true) end
if relic then check_unlock(2, resource)
else board = check_unlock(2, first_tool) end

local tool = first_tool.tool
local stock_key = relic and 'bonus_charge' or 'tool_stock'
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
    local previous = g.tool_meter[tool]
    R.finish_wave()
    local airborne = 0
    for _, points in pairs(R.pending.bonus_charge_by_cell) do airborne = airborne + points end
    local expected_charge = first_tool.amount * 3
    if relic then expected_charge = math.min(expected_charge, g.tool_threshold - previous) end
    check(airborne == expected_charge, 'the cleared cells carry the full awarded charge to their booster')
end
R.reduced_motion, R.sound = true, false
R.vfx_wave = function() end
charge_match(board)
local triple = first_tool.amount * 3
check(board.tool_meter[tool] == triple and R.prog[stock_key][tool] == triple, 'a triple earns and banks its charge')
local new_board = R.make_board(board.level + 1, 2)
check(new_board.tool_meter[tool] == triple, 'partial charge carries to the next board')
-- Start near a full meter so the same test works with both games' thresholds.
new_board.tool_meter[tool] = new_board.tool_threshold - 8
charge_match(new_board)
local ready_meter = relic and new_board.tool_threshold or 1
check(new_board.tools[tool] == 1 and new_board.tool_meter[tool] == ready_meter, 'a full meter grants a use')
check(save.write('walkthrough-tool-stock', R.serialize), 'write stock to the walkthrough save fixture')
R.prog[stock_key] = nil
check(save.read('walkthrough-tool-stock', R.serialize), 'read stock from the walkthrough save fixture')

for slot = 1, purse.MAX do R.prog.wallet[slot] = 9999 end
for zone = 1, 5 do R.island:unlock(zone, R.prog.wallet) end
local later = relic and 8 or 7
for i = 3, later - 1 do place_due(journey.wonder_levels[i]) end
if island.next_step then place_due(journey.wonder_levels[later] - 1) end
local newest = check_unlock(later, second_tool)
check(reward_piece(newest, second_tool) and not reward_piece(newest, first_tool),
    'the first eligible board features only the newly unlocked bonus pieces')
-- Christmas Market banks points, so a lower threshold (its post office)
-- turns the same points into more uses.
local banked = R.prog[stock_key][tool]
local function stored(g)
    if relic then return 1, ready_meter end
    return banked // g.tool_threshold, banked % g.tool_threshold
end
local uses, meter = stored(newest)
check(uses >= 1 and newest.tools[tool] == uses and newest.tool_meter[tool] == meter,
    'a saved tool is available on the other family’s board')
local next_level = newest.level + 1
local even, odd = R.make_board(next_level, 2), R.make_board(next_level, 3)
check(even.bonus ~= odd.bonus or reward_piece(even, first_tool) ~= reward_piece(odd, first_tool),
    'later boards select a bonus family by seed')
check(even.tool_meter[tool] == select(2, stored(even)) and odd.tool_meter[tool] == select(2, stored(odd)),
    'each family keeps its inventory on later boards')
R.reset_board(newest)
local target = 0
while not newest.active[target] do target = target + 1 end
check(rules.game_tool(newest, tool - 1, target, R.pending), 'spend the previously banked use')
R.finish_wave()
local left = relic and 0 or (uses - 1) * newest.tool_threshold + meter
check(R.make_board(next_level, 2).tools[tool] == (relic and 0 or uses - 1) and R.prog[stock_key][tool] == left,
    'changing boards cannot recover a spent tool')
