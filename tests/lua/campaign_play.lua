-- Extended, window-free campaign: win real boards, then use the game's reward
-- coordinator and the city purchase rules. The separate campaign
-- smoke exercises the controls, rendering and placement interaction.
if not testing.extended then return end

local rules = require('rules')
local island = require('island')
local journey = require('journey')
local R = require('state')
require('main')

R.test_mode, R.quiet, R.overlay = true, false, R.OV_NONE
R.island = city.new()
island.island_setup(R.island)
R.wonders = island.wonders
R.prog = {level=0, seed=1, wallet=purse(), story_seen={}}
R.story_current, R.story_preview = nil, false
local m = rules.new_match()
local attempts, wins, earned, replays = 0, 0, 0, 0
local purchase_level = {}
local relic_rush = testing.game == 'relic-rush'
local user_events = relic_rush and require('user_events_runtime')
-- The reference bot the move budgets are fitted to (tests/lua/tune_moves.lua).
local profile = testing.bot_profile and require('bot_profile')(rules)
local best_move = require('match3.bot')(profile and profile.rules or rules)
local function play(g)
    while not g.won and not g.lost do
        local a, b = best_move(g)
        if a < 0 then
            if not rules.game_shuffle(g) then g.lost = true end
        else
            assert(rules.game_swap(g, a, b, m), 'bot chose an illegal move')
            local settled = false
            for _ = 1, 200 do
                rules.game_apply(g, m)
                rules.game_collapse(g, true)
                rules.game_matches(g, m, -1)
                if m.hits == 0 then rules.game_check_end(g); settled = true; break end
            end
            assert(settled, 'board did not settle')
        end
    end
end

for level = 1, rules.LEVELS do
    R.on_island, R.overlay = false, R.OV_NONE
    R.g = R.make_board(level - 1, 1)
    R.story_tick()
    check(not story.active() and not R.story_current, 'the board opens without dialogue')
    local won
    -- Fixed independent starts permit a failed board to be retried. They are
    -- a reproducible bot sample, not a prediction of human win rates.
    -- A boss is allowed more starts before the whole playthrough fails.
    for seed = 1, rules.level_of and (rules.levels[level].tier == 'boss' and 16 or 8) or 8 do
        if seed > 1 then R.g = R.make_board(level - 1, seed) end
        attempts = attempts + 1
        play(R.g)
        if R.g.won then won = true; break end
    end
    assert(won, ('bot failed every start on level %d'):format(level))
    wins = wins + 1
    R.overlay = R.OV_RESULT
    R.story_tick()
    check(not story.active() and not R.story_current, 'the results open without dialogue')
    local moves_left = R.g.moves
    local reward = rules.level_reward(R.g, R.wonders, R.prog)
    local expected_wallet = R.prog.wallet + reward
    R.claim_reward()
    if level == rules.LEVELS then
        check(R.overlay == R.OV_COMPLETE and R.on_island, 'the last result opens the completion card')
        R.overlay = R.OV_NONE
    end
    check(R.prog.level == level, 'first win advances one level')
    for slot = 1, 4 do
        check(R.prog.wallet[slot] == expected_wallet[slot], 'win pays once in wallet slot ' .. slot)
    end
    earned = earned + reward[1]
    if rules.FOOD then
        local income, wallet = reward, R.prog.wallet
        print(("wish %02d · earned %d/%d/%d · stock %d/%d/%d · %d moves left"):format(
            level, income[1], income[3], income[2], wallet[1], wallet[3], wallet[2], moves_left))
    end
    for z = 1, 5 do R.island:unlock(z, R.prog.wallet) end
    if island.next_step then
        -- Place each affordable project. A shortfall at a milestone would need a replay.
        local placed, short = {}, 0
        while true do
            local next_kind = island.next_step(R.island, R.prog.level)
            if not next_kind then break end
            local building = island.buildings[next_kind + 1]
            local owed = island.wonder_count(R.island) < journey.earned(R.prog.level)
            if island.island_place_next(R.island, R.prog.wallet, R.prog.level, 0) then
                placed[#placed + 1] = building.key
                purchase_level[next_kind] = level
            elseif not owed then break
            else
                short = short + 1
                assert(short <= 20, 'twenty replays could not fund ' .. building.key)
                local replay
                for seed = 1, 8 do
                    replay = R.make_board(level - 1, 100 * short + seed)
                    play(replay)
                    if replay.won then break end
                end
                if replay.won then
                    R.g = replay
                    R.claim_reward()
                end
            end
        end
        replays = replays + short
        local wallet = R.prog.wallet
        print(("expedition %02d · earned %d/%d/%d · stock %d/%d/%d · replays %d · placed %s"):format(
            level, reward[1], reward[3], reward[2], wallet[1], wallet[3], wallet[2], short,
            #placed > 0 and table.concat(placed, ", ") or "-"))
    end
    if user_events then user_events.emit('island') end
end
local due = 0
for _, step in ipairs(island.ladder) do
    if step.after <= rules.LEVELS then
        due = due + 1
        check(purchase_level[step.kind] == step.after, ('placed %s after clear %d'):format(step.unlock.building, step.after))
    end
end
check(island.wonder_count(R.island) == journey.earned(rules.LEVELS), 'all earned story buildings placed')
check(island.campaign_count(R.island) == due, 'every earned purchase placed')
check(replays == 0, ('the reference playthrough needs %d replays for income'):format(replays))
print(('campaign play: %d wins, %d failed attempts, %d replays for income, %d of %d purchases, %d total earned, %d remaining, %d stars'):format(
    wins, attempts-wins, replays, island.campaign_count(R.island), due, earned, R.prog.wallet[1], R.prog.wallet[4]))

if profile then profile.report() end
