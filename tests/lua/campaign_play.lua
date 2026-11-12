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
R.prog = {level=0, seed=1, wallet=purse(), lives=rules.LIVES, life_at=0, story_seen={}}
R.story_current, R.story_preview = nil, false
local m = rules.new_match()
local attempts, wins, earned, bonus = 0, 0, 0, 0
local played = {}

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

local function play(g)
    while not g.won and not g.lost do
        local best, a, b = -1, -1, -1
        for i = 0, rules.CELLS - 1 do
            for d = 0, 2 do
                local j = rules.hex_neighbor(i, d)
                local value = rules.game_evaluate_move(g, i, j)
                if value > best then best, a, b = value, i, j end
            end
        end
        if a < 0 then
            rules.game_shuffle(g)
        else
            assert(rules.game_swap(g, a, b, m), 'bot chose an illegal move')
            local settled = false
            for _ = 1, 200 do
                rules.game_apply(g, m)
                rules.game_collapse(g)
                rules.game_matches(g, m, -1)
                if m.hits == 0 then rules.game_check_end(g); settled = true; break end
            end
            assert(settled, 'board did not settle')
        end
    end
end

for level = 1, rules.LEVELS do
    R.on_island, R.overlay = false, R.OV_NONE
    R.g = rules.game_start(level - 1, 1)
    local next_beat = journey.next(R.prog, function(kind) return island.owned(R.island, kind) > 0 end, level - 1)
    if next_beat and next_beat.phase == 'before' then scene(next_beat.key) end
    local won
    -- Fixed independent starts permit a failed board to be retried. They are
    -- a reproducible bot sample, not a prediction of human win rates.
    for seed = 1, 4 do
        R.g = rules.game_start(level - 1, seed)
        attempts = attempts + 1
        play(R.g)
        if R.g.won then won = true; break end
    end
    assert(won, ('bot failed all four starts on level %d'):format(level))
    wins = wins + 1
    local after = ('after-%02d'):format(level)
    local first_exchange = journey.result_beat(R.prog, R.g)
    if first_exchange then
        R.overlay = R.OV_RESULT
        scene(after, true)
    end
    local reward = rules.reward_breakdown(R.g, R.wonders, R.prog)
    local before = R.prog.wallet[1]
    R.claim_reward()
    check(R.prog.level == level and R.prog.wallet[1] == before + reward.total[1], 'win pays once and advances')
    earned, bonus = earned + reward.total[1], bonus + reward.bonus
    if journey.clear_before_result and not first_exchange then scene(after) end
    local kind = journey.wonder_at(level)
    if kind then
        check(not journey.next(R.prog, function(k) return island.owned(R.island, k) > 0 end, nil), 'story waits for construction')
        for z = 1, 5 do R.island:unlock(z, R.prog.wallet) end
        assert(island.island_place_next(R.island, R.prog.wallet, R.prog.level, 0), 'cannot place funded building')
        if journey.clear_before_result then scene(('restore-%02d'):format(level)) end
    end
    if not journey.clear_before_result then scene(after) end
end
check(#played == #journey.beats, 'every story beat played')
for i, beat in ipairs(journey.beats) do check(played[i] == beat.key, 'story order: ' .. beat.key) end
check(island.wonder_count(R.island) == island.WONDERS, 'all story buildings placed')
print(('campaign play: %d wins, %d failed attempts, %d total earned, %d move bonus, %d remaining, %d stars, %d scenes'):format(
    wins, attempts-wins, earned, bonus, R.prog.wallet[1], R.prog.wallet[4], #played))
