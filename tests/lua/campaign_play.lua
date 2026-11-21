-- Extended, window-free campaign: win real boards, then use the game's reward
-- and story coordinators and the city purchase rules. The separate campaign
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
local played, purchase_level = {}, {}
local relic_rush = testing.game == 'relic-rush'
local user_events = relic_rush and require('user_events_runtime')
local function owns_wonder(index)
    return island.owned(R.island, island.wonder_kinds and island.wonder_kinds[index + 1] or index) > 0
end

local function scene(expected, before_reward)
    R.story_tick()
    check(R.story_current and R.story_current.key == expected, 'expected story scene ' .. expected)
    if not R.story_current then error('missing story scene ' .. expected) end
    played[#played + 1] = R.story_current.key
    while story.active() do story.next() end
    R.story_tick()
    if R.overlay == R.OV_STORY_CHOICE then
        assert(R.choose_story_option(2), 'could not choose the reply')
        while story.active() do story.next() end
        R.story_tick()
    end
    if before_reward then check(R.g.story_clear == expected, 'reply waits for the reward transaction')
    else check(R.prog.story_seen[expected], 'finished scene acknowledged: ' .. expected) end
end

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
    local next_beat = journey.next(R.prog, owns_wonder, level - 1)
    if next_beat and next_beat.phase == 'before' then scene(next_beat.key) end
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
    local after = ('after-%02d'):format(level)
    local first_exchange = journey.result_beat(R.prog, R.g, rules.level_of(R.g))
    if first_exchange then
        R.overlay = R.OV_RESULT
        -- Allow the headless clock to advance through any object reveal or
        -- signal scene before the first-clear exchange.
        for _ = 1, 8 do
            R.story_tick()
            if R.story_current then break end
            R.now = R.now + 1
        end
        scene(after, true)
    end
    local reward = rules.level_reward(R.g, R.wonders, R.prog)
    local expected_wallet = R.prog.wallet + reward
    R.claim_reward()
    if R.overlay == R.OV_COMPLETE then R.overlay = R.OV_NONE end
    check(R.prog.level == level, 'first win advances one level')
    for slot = 1, 4 do
        check(R.prog.wallet[slot] == expected_wallet[slot], 'win pays once in wallet slot ' .. slot)
    end
    earned = earned + reward[1]
    if rules.FOOD then
        local income, wallet = reward, R.prog.wallet
        print(("wish %02d · earned %d/%d/%d · stock %d/%d/%d · %d moves left"):format(
            level, income[1], income[3], income[2], wallet[1], wallet[3], wallet[2], R.g.moves))
    end
    if journey.clear_before_result and not first_exchange and journey.find(after) and journey.find(after).phase == 'after' then scene(after) end
    local kind = journey.wonder_at(level)
    if kind then
        check(not journey.next(R.prog, owns_wonder, nil), 'story waits for construction')
    end
    for z = 1, 5 do R.island:unlock(z, R.prog.wallet) end
    if island.next_step then
        -- A ladder: place each open restoration when affordable. When the story
        -- needs one the wallet cannot cover, replay this board for income.
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
    elseif kind then
        assert(island.island_place_next(R.island, R.prog.wallet, R.prog.level, 0), 'cannot place funded building')
    end
    if user_events then user_events.emit('island') end
    local pending = journey.next(R.prog, owns_wonder, nil)
    while pending do
        scene(pending.key)
        pending = journey.next(R.prog, owns_wonder, nil)
    end
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
local index = 0
for _, beat in ipairs(journey.beats) do
    if beat.level <= rules.LEVELS then
        index = index + 1
        check(played[index] == beat.key, 'story order: ' .. beat.key)
    end
end
check(replays == 0, ('the reference playthrough needs %d replays for income'):format(replays))
print(('campaign play: %d wins, %d failed attempts, %d replays for income, %d of %d purchases, %d total earned, %d remaining, %d stars, %d scenes'):format(
    wins, attempts-wins, replays, island.campaign_count(R.island), due, earned, R.prog.wallet[1], R.prog.wallet[4], #played))

if profile then profile.report() end
