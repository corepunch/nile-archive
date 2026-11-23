-- The opt-in walkthrough calls the ordinary reward and placement paths.
local rules, island, journey = require('rules'), require('island'), require('journey')
local R = require('state')
local economy = require('economy')
local relic = testing.game == 'relic-rush'
require('main')
R.test_mode, R.quiet, R.overlay, R.on_island = true, true, R.OV_NONE, false
R.island = city.new(); island.island_setup(R.island)
R.wonders, R.buildings = island.wonders, island.buildings
R.prog = {level=0, seed=1, wallet=purse(), story_seen={}}
R.g = rules.game_start(0, 1)
check(R.debug_skip_level() and R.g.won and R.overlay == R.OV_RESULT, 'skip opens the normal result')
check(not R.debug_skip_level(), 'a completed board cannot be skipped twice')
local expected = rules.level_reward(R.g, R.wonders, R.prog)
check(R.result_action(true, expected) == R.words.result.visit, 'the first clear opens the first construction')
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
R.board_art = {}   -- rule tests build the list without loading textures
local first_project, second_project = island.ladder[1], island.ladder[2]
local funded_wallet = R.prog.wallet
check(R.active_epoch() == 1 and R.can_build_project(), "the first epoch has an affordable project")
R.open_catalogue()
local stock = R.catalogue_form.nodes.stock
local function row(index) return stock.records[stock.children[index].item_key] end
check(not row(1).heading, "the phase's projects lead without a heading")
for i = 1, 4 do
    local project = row(i)
    check(project.kind == island.ladder[i].kind and project.project and project.available and project.reward,
        "the first four rows are the phase's projects in build order, each with what it brings")
end
check(row(5).heading == R.words.catalogue.decorations and not row(6).project,
    "decorations follow the four projects")
local quests = R.town.hooks.quests()
check(#quests == 4 and quests[1].ready and quests[1].note == R.words.catalogue.ready,
    "the town's tracker numbers the phase's four projects, ready ones saying so")
check(not R.catalogue_tile(island.buildings[island.ladder[5].kind + 1].key), "later phases' projects are left out")
R.prog.wallet = purse(5)
check(not R.can_build_project(), "a short wallet does not light the Build control")
R.prog.wallet = funded_wallet
R.open_project(second_project.kind)
check(R.inspect == second_project.kind and R.inspect_item == -1 and R.overlay == R.OV_WONDER,
    "each project opens its own details")
R.overlay = R.OV_NONE
check(R.debug_advance_town() and island.owned(R.island, first_project.kind) == 1, 'town action confirms the earned building')
R.prog.level = 20
check(R.active_epoch() == 1, "clearing all twenty boards keeps the phase open while it still has projects")
check(R.sync_epoch_regions() == 0 and not R.island:zone_open(1), "the first district stays fogged while projects are due")
R.prog.level = 1
check(not R.debug_advance_town() or island.owned(R.island, island.wonder_kinds and island.wonder_kinds[1] or 0) == 1, 'repeated action does not duplicate the building')
R.on_island, R.overlay = true, R.OV_NONE

R.prog.story_recap = true
R.quiet = false
R.story_tick()
check(not (R.story_current and R.story_current.key == 'recap'), 'older campaign saves cannot replay their recap')
R.quiet = true
R.prog.wallet = purse(0, 0, 0, 1)
R.g = R.make_board(1, 2)
R.on_island = false
check(R.debug_skip_level(), 'win an ordinary board')
check(R.result_action(true, purse()) == "COLLECT & PLAY NEXT", 'an ordinary result offers the next board')
R.claim_reward()
check(R.prog.level == 2 and R.g.level == 2 and not R.on_island and R.overlay == R.OV_NONE,
    'collecting an ordinary win starts the next board directly')
R.prog.wallet = funded_wallet
R.on_island = true

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
        check(R.debug_advance_town(), 'place the intervening restoration')
        return
    end
    while island.next_step(R.island, level) do
        local count = island.campaign_count(R.island)
        local placed = R.debug_advance_town() and island.campaign_count(R.island) == count + 1
        check(placed, 'place the intervening restoration')
        if not placed then break end
    end
end
local function check_unlock(level, reward, already_placed)
    R.prog.level = level
    if not already_placed then
        -- A ladder places the stalls between story buildings first.
        if island.next_step then place_due(level - 1) end
        R.prog.level = level
        local before = R.make_board(level, 2)
        check(reward_piece(before, reward) == nil, 'the reward waits for confirmed construction')
        check(R.debug_advance_town(), 'the walkthrough confirms the earned building')
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

local first_tool = economy.bonuses.hammer
local resource = relic and economy.unlock_of("well") or economy.pieces[economy.unlock_of("arch").kind]
check_unlock(journey.wonder_levels[1], resource, true)
local hammer_level = relic and economy.unlock_of("log_cabin").first_level - 1 or economy.unlock_of("reindeer_stable").after
local board = check_unlock(hammer_level, first_tool)

local tool = first_tool.tool
local stock_key = "bonus_charge"
check(board.tools[tool] == 0 and board.tool_meter[tool] == 0, 'construction unlocks an empty tool')
local function charge_match(g)
    R.reset_board(g)
    for i = 0, rules.CELLS - 1 do g.tiles[i] = rules.tile(-1) end
    local kind = reward_piece(g, first_tool)
    for _, cell in ipairs(require('support').open_line(rules, g)) do
        g.tiles[cell], g.chain[cell], g.ice[cell] = rules.tile(kind), 0, 0
    end
    rules.game_matches(g, R.pending, -1)
    check(R.pending.hits == rules.MATCH_MIN, 'bonus pieces form an ordinary match')
    local previous = g.tool_meter[tool]
    R.finish_wave()
    local airborne = 0
    for _, points in pairs(R.pending.bonus_charge_by_cell) do airborne = airborne + points end
    local expected_charge = math.min(first_tool.amount * rules.MATCH_MIN, g.tool_threshold - previous)
    check(airborne == expected_charge, 'the cleared cells carry the full awarded charge to their booster')
end
R.reduced_motion, R.sound = true, false
R.vfx_wave = function() end
charge_match(board)
local match_charge = first_tool.amount * rules.MATCH_MIN
check(board.tool_meter[tool] == match_charge and R.prog[stock_key][tool] == match_charge, 'a match earns and banks its charge')
local new_board = R.make_board(board.level + 1, 2)
check(new_board.tool_meter[tool] == match_charge, 'partial charge carries to the next board')
-- Start near a full meter so the same test works with both games' thresholds.
new_board.tool_meter[tool] = new_board.tool_threshold - 8
charge_match(new_board)
local ready_meter = new_board.tool_threshold
check(new_board.tools[tool] == 1 and new_board.tool_meter[tool] == ready_meter, 'a full meter grants a use')
check(save.write('walkthrough-tool-stock', R.serialize), 'write stock to the walkthrough save fixture')
R.prog[stock_key] = nil
check(save.read('walkthrough-tool-stock', R.serialize), 'read stock from the walkthrough save fixture')

local next_level = new_board.level + 1
local resumed = R.make_board(next_level, 2)
check(resumed.tools[tool] == 1 and resumed.tool_meter[tool] == ready_meter,
    'a saved use is ready on the next board')
R.reset_board(resumed)
local target = 0
while not resumed.active[target] do target = target + 1 end
check(rules.game_tool(resumed, tool - 1, target, R.pending), 'spend the previously banked use')
R.finish_wave()
check(R.make_board(next_level, 2).tools[tool] == 0 and R.prog[stock_key][tool] == 0,
    'changing boards cannot recover a spent tool')

-- A player can reach the boundary short of the last purchase. Confirming it
-- later opens the district once and preserves the epoch on reload.
R.island = city.new()
island.island_setup(R.island)
R.prog = {level=20, seed=1, wallet=purse(99999,99999,99999,20), story_seen={}}
R.on_island, R.overlay = true, R.OV_NONE
R.town_setup()
check(R.island.zone_count == 5 and R.island.open == 1, 'only the first of five districts starts open')
for z = 1, 4 do
    check(R.island:zone_of(R.island.zones[z + 1].marker) == z, 'each locked marker sits in its own district')
end
check(R.island:zone_of(vec2(1220, 860)) == 4, 'the old northern district belongs to the final phase')
for _ = 1, 3 do
    check(island.island_place_next(R.island, R.prog.wallet, 20, 0), 'place an earned project')
end
check(R.sync_epoch_regions() == 0 and not R.island:zone_open(1), 'three projects leave the next district fogged')
check(R.town:begin(island.ladder[4].kind, false) and R.town:confirm(), 'confirm the fourth project after level 20')
check(R.overlay == R.OV_EPOCH and R.epoch_award == 1 and R.island:zone_open(1),
    'late fourth purchase presents the award and opens its district')
R.close_epoch(false)
R.island.open = R.island.open | (1 << 2) | (1 << 5)
check(save.write('epoch-award', R.serialize), 'save the acknowledged award and previously opened land')
R.island.open, R.prog.epoch_seen = 1, nil
check(save.read('epoch-award', R.serialize) and R.island.open == 23 and R.prog.epoch_seen == 1
    and not R.show_epoch_award(R.completed_epochs()), 'reload preserves older map access and does not repeat the award')
R.open_menu()
R.menu.actions.continue()
check(R.on_menu and R.overlay == R.OV_EPOCH, 'Continue opens the medal screen over the main menu')
R.close_epoch(false)
check(R.on_menu and R.overlay == R.OV_NONE, 'Back on the medal screen returns to the main menu')
R.menu.actions.continue()
R.close_epoch(true)
check(not R.on_menu and not R.on_island and R.g.level == 20, 'Play opens the current phase at the next board')
check(R.debug_skip_level(), 'win the current board')
local pending = R.g
R.open_menu()
R.menu.actions.continue()
R.close_epoch(true)
check(R.overlay == R.OV_RESULT and R.g == pending and R.prog.level == 20,
    'Play restores an unclaimed result before advancing the campaign')
