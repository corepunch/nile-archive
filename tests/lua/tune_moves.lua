-- Move budgets for the authored boards, run by tools/tune_moves.py. Each board
-- in TUNE_LEVELS is played TUNE_SEEDS times (BALANCE_RUNS, default 40) by the
-- greedy bot with a 250-move ceiling and the earned buildings in place.
-- The median times 1.25 sets the budget; slow runs never inflate it. Prints one
-- MOVES_JSON line per board, and one CELLS_JSON line per game with the move
-- each plaque was cleared on.
if not testing.tune_levels then return end

local rules = require('rules')
local island = require('island')
local first, last = testing.tune_levels:match('^(%d+)%-(%d+)$')
first, last = tonumber(first), tonumber(last)
local SEEDS = testing.balance_runs or 40
local CAP = 250   -- a board the bot cannot clear in 250 moves needs redesign, not a budget
local budget = require('move_budget')
local m = rules.new_match()
local best_move = require('greedy_bot')(rules)

local function seed_of(n) return (n * 2654435761 + 0x9E3779B9) & 0x7FFFFFFF | 1 end

-- Base moves the bot needed to clear the board, or nil. `cleared` receives
-- the move on which each plaque went: the plaques that go last, or never,
-- are the ones that make a board long (tools/balance_plaques.py).
local function play(level, seed, restored, cleared)
    local g = rules.game_start(level - 1, seed, restored)
    local start = g.moves
    local shuffles = 0
    local pending = {}
    for i = 0, rules.CELLS - 1 do if g.active[i] and g.oil[i] > 0 then pending[i] = true end end
    while not g.won and not g.lost do
        local a, b = best_move(g)
        if a < 0 then
            shuffles = shuffles + 1
            if shuffles > 50 or not rules.game_shuffle(g) then return nil end
        else
            assert(rules.game_swap(g, a, b, m), 'bot chose an illegal move')
            for _ = 1, 500 do
                rules.game_apply(g, m); rules.game_collapse(g, true); rules.game_matches(g, m, -1)
                if m.hits == 0 then break end
            end
            rules.game_check_end(g)
            for i in pairs(pending) do
                if g.oil[i] == 0 then pending[i] = nil; cleared[#cleared + 1] = ('[%d,%d]'):format(i, start - g.moves) end
            end
        end
    end
    return g.won and math.max(1, start - g.moves) or nil
end

for level = first, last do
    local spec = rules.levels[level]
    local tier = spec.tier or 'normal'
    local restored = {}
    for _, step in ipairs(island.ladder) do
        if step.after < level then restored[step.unlock.building] = true end
    end
    local original_moves = spec.moves
    spec.moves = CAP
    local used = {}
    for n = 1, SEEDS do
        local cleared = {}
        used[n] = play(level, seed_of(1000 * level + n), restored, cleared) or math.huge
        print(('CELLS_JSON {"level":%d,"seed":%d,"cleared":[%s]}'):format(level, n, table.concat(cleared, ',')))
    end
    spec.moves = original_moves
    table.sort(used)
    local need, median = budget.fit(used)
    local wins, within = 0, 0
    for _, v in ipairs(used) do
        if v < math.huge then wins = wins + 1 end
        if v <= need then within = within + 1 end
    end
    print(('MOVES_JSON {"level":%d,"tier":"%s","moves":%d,"median":%d,"fastest":%d,"within":%d,"wins":%d,"seeds":%d}'):format(
        level, tier, need, median < math.huge and median or -1, used[1] < math.huge and used[1] or -1, within, wins, SEEDS))
end
