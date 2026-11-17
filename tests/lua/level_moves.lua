-- Move budgets for the authored boards, run by tools/tune_moves.py. Each board
-- in TUNE_LEVELS is played TUNE_SEEDS times (BALANCE_RUNS, default 40) by the
-- greedy bot with no move limit. The budget is the moves the bot needed in the
-- tier's target share of those games (tutorial 95%, easy 92%, normal 80%,
-- hard 62%, boss 50%). Prints one MOVES_JSON line per board.
if not testing.tune_levels then return end

local rules = require('rules')
local first, last = testing.tune_levels:match('^(%d+)%-(%d+)$')
first, last = tonumber(first), tonumber(last)
local SEEDS = testing.balance_runs or 40
local CAP = 250   -- a board the bot cannot clear in 250 moves needs redesign, not a budget
local WIN = {tutorial=0.95, easy=0.92, normal=0.80, hard=0.62, boss=0.50}
local m = rules.new_match()
local best_move = require('greedy_bot')(rules)

local function seed_of(n) return (n * 2654435761 + 0x9E3779B9) & 0x7FFFFFFF | 1 end

-- Base moves the bot needed to clear the board, or nil.
local function play(level, seed)
    rules.levels[level].moves = CAP
    local g = rules.game_start(level - 1, seed)
    local shuffles = 0
    while not g.won and not g.lost do
        local a, b = best_move(g)
        if a < 0 then
            shuffles = shuffles + 1
            if shuffles > 50 or not rules.game_shuffle(g) then return nil end
        else
            assert(rules.game_swap(g, a, b, m), 'bot chose an illegal move')
            for _ = 1, 500 do
                rules.game_apply(g, m); rules.game_collapse(g); rules.game_matches(g, m, -1)
                if m.hits == 0 then break end
            end
            rules.game_check_end(g)
        end
    end
    return g.won and math.max(1, CAP - g.moves) or nil   -- loadout extra moves come on top
end

for level = first, last do
    local spec = rules.levels[level]
    local tier = spec.tier or 'normal'
    local used = {}
    for n = 1, SEEDS do used[n] = play(level, seed_of(1000 * level + n)) or math.huge end
    table.sort(used)
    local need = used[math.max(1, math.ceil(WIN[tier] * SEEDS))]
    check(need < math.huge, ('the bot clears board %d within %d moves'):format(level, CAP))
    local wins = 0
    for _, v in ipairs(used) do if v < math.huge then wins = wins + 1 end end
    print(('MOVES_JSON {"level":%d,"tier":"%s","moves":%d,"median":%d,"fastest":%d,"wins":%d,"seeds":%d}'):format(
        level, tier, need < math.huge and need or CAP, used[(SEEDS + 1) // 2] < math.huge and used[(SEEDS + 1) // 2] or -1,
        used[1] < math.huge and used[1] or -1, wins, SEEDS))
end
