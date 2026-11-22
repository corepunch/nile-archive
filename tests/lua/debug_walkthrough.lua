-- The opt-in walkthrough calls the ordinary reward and placement paths.
local rules, island, journey = require('rules'), require('island'), require('journey')
local R = require('state')
local economy = require('economy')
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
local phase, projects = R.epoch_projects()
check(phase == R.words.epochs[1] and #projects == 4, "the current phase has four projects")
check(projects[1].state == "ready" and projects[2].state == "locked", "the earned purchase and a future purchase look different")
local funded_wallet = R.prog.wallet
R.prog.wallet = purse(5)
local _, funding_projects = R.epoch_projects()
check(funding_projects[1].state == "funding" and funding_projects[1].progress > 0 and funding_projects[1].progress < 1,
    "an earned project with a shortfall shows its funding progress")
R.prog.wallet = funded_wallet
for i, project in ipairs(projects) do
    local bounds = R.town.project_boxes[project.id]
    check(project.id == island.ladder[i].kind and bounds:max().x < R.town.buttons.play.x,
        "projects follow construction order before Play")
end
R.open_project(projects[2].id)
check(R.inspect == projects[2].id and R.inspect_item == -1 and R.overlay == R.OV_WONDER,
    "a locked project opens its own details")
R.overlay = R.OV_NONE
check(R.debug_advance_town() and island.owned(R.island, island.wonder_kinds and island.wonder_kinds[1] or 0) == 1, 'town action confirms the earned building')
local _, built_projects = R.epoch_projects()
check(built_projects[1].state == "built", "the finished project stays on the row in color")
R.prog.level = 20
check(R.epoch_projects() == phase, "clearing all twenty boards keeps the phase open while it still has projects")
check(R.sync_epoch_regions() == 0 and not R.island:zone_open(1), "the first district stays fogged while projects are due")
R.prog.level = 1
check(not R.debug_advance_town() or island.owned(R.island, island.wonder_kinds and island.wonder_kinds[1] or 0) == 1, 'repeated action does not duplicate the building')
R.on_island, R.overlay = true, R.OV_NONE

local relic = testing.game == "relic-rush"
if not relic then
    local theo = R.project_keeper(island.kinds.lumber)
    check(theo.id == "theo" and theo == R.project_keeper(island.kinds.rink)
        and theo == R.project_keeper(island.kinds.fir_snowy), 'related projects share Theo’s portrait')
    for _, step in ipairs(island.ladder) do
        check(R.project_keeper(step.kind).portrait_path ~= nil, 'each construction has a project portrait')
    end
end
R.prog.story_recap = true
R.quiet = false
R.story_tick()
check(not R.story_current and not story.active(), 'older campaign saves cannot replay their recap')
R.quiet = true
R.g = R.make_board(1, 2)
R.on_island = false
check(R.debug_skip_level(), 'win an ordinary board')
check(R.result_action(true, purse()) == "COLLECT & PLAY NEXT", 'an ordinary result offers the next board')
R.claim_reward()
check(R.prog.level == 2 and R.g.level == 2 and not R.on_island and R.overlay == R.OV_NONE,
    'collecting an ordinary win starts the next board directly')
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
for _ = 1, 3 do
    check(island.island_place_next(R.island, R.prog.wallet, 20, 0), 'place an earned project')
end
check(R.sync_epoch_regions() == 0 and not R.island:zone_open(1), 'three projects leave the next district fogged')
check(R.town:begin(island.ladder[4].kind, false) and R.town:confirm(), 'confirm the fourth project after level 20')
check(R.overlay == R.OV_EPOCH and R.epoch_award == 1 and R.island:zone_open(1),
    'late fourth purchase presents the award and opens its district')
R.close_epoch(false)
R.island.open = R.island.open | (1 << 2)
check(save.write('epoch-award', R.serialize), 'save the acknowledged award and previously opened land')
R.island.open, R.prog.epoch_seen = 1, nil
check(save.read('epoch-award', R.serialize) and R.island:zone_open(2) and R.prog.epoch_seen == 1
    and not R.show_epoch_award(R.completed_epochs()), 'reload preserves older map access and does not repeat the award')
R.open_epoch(4)
R.close_epoch(true)
check(R.on_island and not R.epoch_replay_end, 'a future phase cannot start')
R.open_epoch(1)
R.close_epoch(true)
check(not R.on_island and R.g.level == 0 and R.epoch_replay_end == 20, 'replaying the first phase starts its opening board')
check(R.debug_skip_level(), 'win the replayed board')
R.claim_reward()
check(R.g.level == 1 and R.prog.level == 20 and not R.on_island, 'replay continues through the phase without advancing the campaign')
