local budget = require('move_budget')
-- Outliers must not restore the old percentile-based budget inflation.
local samples = {48, 4, 12, 250, 8, 12, 80, 10, 120}
local moves, median = budget.fit(samples)
check(median == 12 and moves == 15, '12-move median gets exactly 25% headroom despite slow runs')
check(samples[1] == 48, 'fitting preserves the recorded sample order')
check(budget.fit({9, 9, 9}) == 12, 'fractional move allowance rounds up')
check(not pcall(budget.fit, {math.huge, 12, math.huge}), 'unreliable bot sample requires investigation')

-- Real rules: two five-piece incidental matches competes with a three-piece win.
-- The old score-first bot could choose the large match and leave the last pane.
local rules = require('match3').new{square=true, columns=9, rows=7, colors=5,
    levels={{moves=20, score=0, relics=0, chains=0, ice=0, goals={'oil'}}}}
local g = rules.game_start(0, 123)
local function cell(x, y) return rules.hex_index(x - 4, y - 3) end
for x = 0, 8 do
    for y = 0, 6 do g.tiles[cell(x, y)] = rules.tile((x + 2 * y) % 5) end
end
for x = 2, 6 do
    g.tiles[cell(x, 2)], g.tiles[cell(x, 3)] = rules.tile(0), rules.tile(1)
end
g.tiles[cell(4, 2)], g.tiles[cell(4, 3)] = rules.tile(1), rules.tile(0)
g.tiles[cell(1, 5)], g.tiles[cell(3, 4)] = rules.tile(4), rules.tile(3)
g.tiles[cell(1, 2)] = rules.tile(2)
g.tiles[cell(2, 5)], g.tiles[cell(3, 5)] = rules.tile(1), rules.tile(1)
g.tiles[cell(4, 5)], g.tiles[cell(4, 4)] = rules.tile(0), rules.tile(1)
local target = cell(4, 5)
g.oil[target], g.oil_left = 1, 1
local wave = rules.new_match()
rules.game_matches(g, wave)
local free = {}
for c in pairs(wave.mask) do free[#free + 1] = ('%d,%d'):format(rules.hex_q(c)+4, rules.hex_r(c)+3) end
check(wave.hits == 0, 'decision fixture starts without free matches: ' .. table.concat(free, ' '))
local incidental = rules.game_copy(g)
check(rules.game_swap(incidental, cell(4, 2), cell(4, 3), wave), 'large incidental match is available')
rules.game_apply(incidental, wave)
check(incidental.oil_left == 1 and incidental.cleared >= 10, 'large match leaves the objective untouched')
local before = rules.game_copy(g)
local best_move = require('greedy_bot')(rules)
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
