local budget = require('move_budget')
-- Outliers must not restore the old percentile-based budget inflation.
local samples = {48, 4, 12, 250, 8, 12, 80, 10, 120}
local moves, median = budget.fit(samples, 'christmas-market')
check(median == 12 and moves == 15, 'Christmas Market keeps 25% headroom despite slow runs')
moves, median = budget.fit(samples, 'relic-rush')
check(median == 12 and moves == 23, 'Relic Rush scales the fitted budget by 1.5 and rounds up')
check(budget.fit({5, 5, 5}, 'relic-rush') == 11, 'Relic Rush scales the rounded base budget')
check(samples[1] == 48, 'fitting preserves the recorded sample order')
check(budget.fit({9, 9, 9}) == 12, 'fractional move allowance rounds up')
check(not pcall(budget.fit, {math.huge, 12, math.huge}), 'unreliable bot sample requires investigation')

-- Real rules: two five-piece incidental matches compete with a three-piece win.
-- The old score-first bot could choose the large match and leave the last pane.
local rules = require('match3').new{square=true, columns=9, rows=7, colors=5,
    levels={{moves=20, score=0, relics=0, chains=0, ice=0, goals={'oil'}}}}
local g = rules.game_start(0, 123)
local function at(x, y) return rules.hex_index(x - 4, y - 3) end
for x = 0, 8 do
    for y = 0, 6 do g.tiles[at(x, y)] = rules.tile((x + 2 * y) % 5) end
end
for x = 2, 6 do
    g.tiles[at(x, 2)], g.tiles[at(x, 3)] = rules.tile(0), rules.tile(1)
end
g.tiles[at(4, 2)], g.tiles[at(4, 3)] = rules.tile(1), rules.tile(0)
g.tiles[at(1, 5)], g.tiles[at(3, 4)] = rules.tile(4), rules.tile(3)
g.tiles[at(1, 2)] = rules.tile(2)
g.tiles[at(2, 5)], g.tiles[at(3, 5)] = rules.tile(1), rules.tile(1)
g.tiles[at(4, 5)], g.tiles[at(4, 4)] = rules.tile(0), rules.tile(1)
local target = at(4, 5)
g.oil[target], g.oil_left = 1, 1
local wave = rules.new_match()
rules.game_matches(g, wave)
local free = {}
for c in pairs(wave.mask) do free[#free + 1] = ('%d,%d'):format(rules.hex_q(c)+4, rules.hex_r(c)+3) end
check(wave.hits == 0, 'decision fixture starts without free matches: ' .. table.concat(free, ' '))
local incidental = rules.game_copy(g)
check(rules.game_swap(incidental, at(4, 2), at(4, 3), wave), 'large incidental match is available')
rules.game_apply(incidental, wave)
check(incidental.oil_left == 1 and incidental.cleared >= 10, 'large match leaves the objective untouched')
local before = rules.game_copy(g)
local best_move = require('match3.bot')(rules)
local a, b = best_move(g)
local alternate = rules.game_copy(g)
alternate.rng = g.rng ~ 0x13579BDF
local other_a, other_b = best_move(alternate)
check(a == other_a and b == other_b, 'identical visible boards choose the same move regardless of hidden RNG')
check(g.rng == before.rng and g.moves == before.moves and g.score == before.score,
    'bot decision does not advance the live game')
for i = 0, rules.CELLS - 1 do
    check(g.tiles[i].kind == before.tiles[i].kind and g.oil[i] == before.oil[i], 'bot leaves live pieces and targets intact')
end
check(rules.game_swap(g, a, b, wave), 'bot chooses a legal swap')
rules.game_apply(g, wave)
rules.game_check_end(g)
check(g.won, 'bot takes an available win instead of a larger incidental match')

-- Cross-check against actual swaps at every campaign opening in extended runs,
-- and representative single/double-target and chained boards in normal CI.
local campaign = require('rules')
local levels = {1, 4, 10, 62, 100}
if testing.extended then
    levels = {}
    for level = 1, campaign.LEVELS do levels[#levels + 1] = level end
end
local preview, actual = campaign.new_match(), campaign.new_match()
for _, level in ipairs(levels) do
    local board = campaign.game_start(level - 1, (level * 2654435761) & 0x7FFFFFFF | 1)
    local first_a, first_b
    for i = 0, campaign.CELLS - 1 do
        for axis = 0, campaign.AXES - 1 do
            local j = campaign.hex_neighbor(i, axis)
            local legal, progress, score = campaign.game_probe_swap(board, i, j, preview)
            check((not not legal) == (not not campaign.game_swap_matches(board, i, j)), 'campaign preview has real legality')
            if legal then
                first_a, first_b = first_a or i, first_b or j
                local trial = campaign.game_copy(board)
                campaign.game_swap(trial, i, j, actual)
                local order, expected_order = {}, {}
                for cell in pairs(preview.mask) do order[#order + 1] = cell end
                for cell in pairs(actual.mask) do expected_order[#expected_order + 1] = cell end
                check(table.concat(order, ',') == table.concat(expected_order, ','), 'preview preserves match iteration and numeric tie breaks')
                campaign.game_apply(trial, actual)
                local removed = board.obstacles - trial.obstacles
                for cell = 0, campaign.CELLS - 1 do removed = removed + board.oil[cell] - trial.oil[cell] end
                check(progress == removed and score == trial.score - board.score, 'campaign preview preserves target priorities')
            end
        end
    end
    check(first_a ~= nil, 'campaign opening has a legal move')
    if first_a then
        campaign.game_swap(board, first_a, first_b, actual)
        local fast = campaign.game_copy(board)
        for _ = 1, 200 do
            campaign.game_matches(board, actual)
            if actual.hits == 0 then break end
            campaign.game_apply(board, actual)
            campaign.game_apply(fast, actual)
            local origins = campaign.game_collapse(board)
            local fast_origins = campaign.game_collapse(fast, true)
            check(board.rng == fast.rng and board.score == fast.score and board.oil_left == fast.oil_left
                and board.obstacles == fast.obstacles, 'simulation preserves cascade RNG, score and goals')
            for cell = 0, campaign.CELLS - 1 do
                check(board.tiles[cell].kind == fast.tiles[cell].kind and origins[cell] == fast_origins[cell],
                    'simulation preserves campaign refill and damping')
            end
            for slot, amount in pairs(board.earnings) do check(fast.earnings[slot] == amount, 'simulation preserves banked resources') end
            for slot, amount in pairs(board.tool_meter or {}) do check(fast.tool_meter[slot] == amount, 'simulation preserves earned tools') end
        end
    end

end
