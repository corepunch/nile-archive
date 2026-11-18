-- Move budgets for the authored boards, run by tools/tune_moves.py. Each board
-- in TUNE_LEVELS is played TUNE_SEEDS times (BALANCE_RUNS, default 40) by the
-- greedy bot with no move limit. The budget is the bot's median game times the
-- tier's margin (tutorial 2.5, easy 2, normal 1.4, hard 1.2, boss 1). The
-- median is stable where the bot's slowest games are not: a budget read from
-- that tail gave one easy board 12 moves and the next 48. Prints one
-- MOVES_JSON line per board.
if not testing.tune_levels then return end

local rules = require('rules')
local first, last = testing.tune_levels:match('^(%d+)%-(%d+)$')
first, last = tonumber(first), tonumber(last)
local SEEDS = testing.balance_runs or 40
local CAP = 250   -- a board the bot cannot clear in 250 moves needs redesign, not a budget
local MARGIN = {tutorial=2.5, easy=2, normal=1.4, hard=1.2, boss=1}
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
    local median = used[(SEEDS + 1) // 2]
    check(median < math.huge, ('the bot clears board %d within %d moves in half its games'):format(level, CAP))
    local need = median < math.huge and math.min(CAP, math.ceil(median * MARGIN[tier])) or CAP
    local wins, within = 0, 0
    for _, v in ipairs(used) do
        if v < math.huge then wins = wins + 1 end
        if v <= need then within = within + 1 end
    end
    print(('MOVES_JSON {"level":%d,"tier":"%s","moves":%d,"median":%d,"fastest":%d,"within":%d,"wins":%d,"seeds":%d}'):format(
        level, tier, need, median < math.huge and median or -1, used[1] < math.huge and used[1] or -1, within, wins, SEEDS))
end
