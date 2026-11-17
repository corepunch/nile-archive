-- Relic Rush balance runner: rules and the greedy bot only, no screen, story
-- or animation. Every board is played BALANCE_RUNS times (default 10) with the
-- unlocks the ladder has delivered by then. The report gives the win rate,
-- moves left and mean income per won board in each currency, then fits every
-- restoration price to that income as docs/resource-expedition.md describes.
--
--   build/test/relic-rush --extended "rules relic_balance"
--   BALANCE_RUNS=40 build/test/relic-rush --extended "rules relic_balance"
if not testing.extended then return end

local rules = require('rules')
local economy = require('economy')
local island = require('island')

local RUNS = testing.balance_runs or 10
local SHARE = .8   -- a stop spends 80% of the expected wallet in the currencies it uses
local CURRENCIES = #economy.currencies
local m = rules.new_match()

-- The greedy campaign bot: best evaluated swap, no tools.
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
            if not rules.game_shuffle(g) then g.lost = true end
        else
            assert(rules.game_swap(g, a, b, m), 'bot chose an illegal move')
            repeat
                rules.game_apply(g, m)
                rules.game_collapse(g)
                rules.game_matches(g, m)
            until m.hits == 0
            rules.game_check_end(g)
        end
    end
end

-- Board n is played with every ladder restoration due before it.
local function restored_by(number)
    local restored = {}
    for _, unlock in ipairs(economy.unlocks) do
        if unlock.first_level <= number then restored[unlock.building] = true end
    end
    return restored
end

local boards = {}
for level = 1, rules.LEVELS do
    local stats = {wins = 0, moves = 0, income = {}}
    for slot = 1, CURRENCIES do stats.income[slot] = 0 end
    local restored = restored_by(level)
    for run = 1, RUNS do
        local g = rules.game_start(level - 1, 7919 * run + level, restored)
        play(g)
        if g.won then
            local reward = rules.reward_breakdown(g, {}, nil).total
            stats.wins, stats.moves = stats.wins + 1, stats.moves + g.moves
            for slot = 1, CURRENCIES do stats.income[slot] = stats.income[slot] + reward[slot] end
        end
    end
    -- Mean income per win: a board pays when it is won, and a loss is retried.
    for slot = 1, CURRENCIES do stats.income[slot] = stats.income[slot] / math.max(1, stats.wins) end
    stats.moves = stats.wins > 0 and stats.moves / stats.wins or 0
    boards[level] = stats
    print(('board %02d · wins %d/%d · moves left %.1f · income %s'):format(level, stats.wins, RUNS, stats.moves,
        table.concat((function() local t = {} for s = 1, CURRENCIES do t[s] = ('%.0f'):format(stats.income[s]) end return t end)(), '/')))
    check(stats.wins > 0, ('the bot wins board %d at least once'):format(level))
end

-- Stops are the ladder's `after` clears.
local stops, order = {}, {}
for _, step in ipairs(island.ladder) do
    local stop = stops[step.after]
    if not stop then stop = {}; stops[step.after] = stop; order[#order + 1] = step.after end
    stop[#stop + 1] = island.buildings[step.kind + 1]
end
table.sort(order)
local function round5(v) return v <= 0 and 0 or math.max(5, math.floor(v / 5 + .5) * 5) end

-- Fit: at each stop, spend SHARE of what the expected wallet holds in every
-- currency the stop's restorations use, split by their current prices. The
-- rest carries over, so every currency runs low and none piles up unused.
local fitted, carry = {}, {}
for slot = 1, CURRENCIES do carry[slot] = 0 end
local next_stop = 1
for level = 1, rules.LEVELS do
    for slot = 1, CURRENCIES do carry[slot] = carry[slot] + boards[level].income[slot] end
    local after = order[next_stop]
    if after == level then
        local totals = {}
        for slot = 1, CURRENCIES do
            totals[slot] = 0
            for _, b in ipairs(stops[after]) do totals[slot] = totals[slot] + b.cost[slot] end
        end
        for _, b in ipairs(stops[after]) do
            local price = {}
            for slot = 1, CURRENCIES do
                local share = totals[slot] > 0 and b.cost[slot] / totals[slot] or 0
                price[slot] = round5(SHARE * carry[slot] * share)
            end
            fitted[b.key] = price
        end
        for _, b in ipairs(stops[after]) do
            for slot = 1, CURRENCIES do carry[slot] = carry[slot] - fitted[b.key][slot] end
        end
        next_stop = next_stop + 1
    end
end
print('fitted prices (Coins/Food/Supplies), current -> fitted:')
for _, after in ipairs(order) do
    for _, b in ipairs(stops[after]) do
        local f = fitted[b.key]
        print(('  after %02d  %-14s %d/%d/%d -> %d/%d/%d'):format(after, b.key,
            b.cost[1], b.cost[2], b.cost[3], f[1], f[2], f[3]))
    end
end

-- The expected campaign: bank each board's mean income, then buy each
-- restoration at its stop. A short wallet replays the stop's board until it
-- can pay, as the campaign bot does.
local stop_of = {}
for _, after in ipairs(order) do stop_of[after] = stops[after] end
local function walk(label, price_of)
print(('expected campaign with %s prices (Coins/Food/Supplies):'):format(label))
local wallet, replays, lowest = {}, 0, {}
for slot = 1, CURRENCIES do wallet[slot], lowest[slot] = 0, math.huge end
for level = 1, rules.LEVELS do
    local income = boards[level].income
    for slot = 1, CURRENCIES do wallet[slot] = wallet[slot] + income[slot] end
    local bought, extra = {}, 0
    for _, b in ipairs(stop_of[level] or {}) do
        local need = 0
        for slot = 1, CURRENCIES do
            local short = price_of(b)[slot] - wallet[slot]
            if short > 0 then need = math.max(need, income[slot] > 0 and math.ceil(short / income[slot]) or math.huge) end
        end
        assert(need < math.huge, ('board %d pays none of a currency %s needs'):format(level, b.key))
        for slot = 1, CURRENCIES do wallet[slot] = wallet[slot] + need * income[slot] - price_of(b)[slot] end
        extra, bought[#bought + 1] = extra + need, b.key
        for slot = 1, CURRENCIES do lowest[slot] = math.min(lowest[slot], wallet[slot]) end
    end
    replays = replays + extra
    if #bought > 0 then
        print(('  board %02d · bought %s · replays %d · wallet %.0f/%.0f/%.0f'):format(level, table.concat(bought, ', '),
            extra, wallet[1], wallet[2], wallet[3]))
    end
end
print(('expected campaign (%s): %d replays, lowest wallet after a purchase %.0f/%.0f/%.0f, final %.0f/%.0f/%.0f'):format(
    label, replays, lowest[1], lowest[2], lowest[3], wallet[1], wallet[2], wallet[3]))
end
walk('current', function(b) return b.cost end)
walk('fitted', function(b) return fitted[b.key] end)
