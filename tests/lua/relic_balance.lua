-- Balance runner for the square campaigns (Relic Rush and Christmas Market): rules and the greedy bot only, no screen, story
-- or animation. CI plays three fixed boards. With BALANCE_RUNS set, every
-- board is played that many times (make test-balance defaults to 40, the
-- sample the committed prices were fitted on) with the
-- unlocks the ladder has delivered by then. The report gives the win rate,
-- moves left and mean income per won board in each currency, then fits every
-- restoration price to that income as docs/resource-expedition.md describes.
--
--   make test-balance
--   make test-balance BALANCE_RUNS=80
--
-- tools/balance.py splits the work across processes: with TUNE_LEVELS=A-B this
-- plays only that range and prints one INCOME_JSON line per board; with a
-- `balance_incomes` module on the path (the collected lines) it plays nothing
-- and fits from them, printing one PRICE_JSON line per restoration.
if not testing.extended then return end

local rules = require('rules')
local economy = require('economy')
local island = require('island')

local SHARE = .8   -- a stop spends 80% of the expected wallet in the currencies it uses
local CURRENCIES = #economy.currencies
local m = rules.new_match()

-- The reference bot (tests/lua/greedy_bot.lua): best evaluated swap, no tools.
local best_move = require('greedy_bot')(rules)
local function play(g)
    while not g.won and not g.lost do
        local a, b = best_move(g)
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

-- Consecutive small seeds start xorshift on similar streams and bias the
-- boards, so every sample seed is hashed first (as tests/lua/tune_moves.lua does).
-- The game itself seeds from the previous board's random state.
local function seed_of(n) return (n * 2654435761 + 0x9E3779B9) & 0x7FFFFFFF | 1 end

-- Board n is played with every ladder restoration due before it.
local function restored_by(number)
    local restored = {}
    for _, unlock in ipairs(economy.unlocks) do
        if unlock.after < number then restored[unlock.building] = true end
    end
    return restored
end

local function play_board(level, run, restored)
    local g = rules.game_start(level - 1, seed_of(1000 * level + run), restored)
    play(g)
    return g
end

local RUNS = testing.balance_runs
if not RUNS then
    if not economy.PROVISIONS then return end   -- the CI sample checks Relic Rush's currencies
    for _, level in ipairs{1, 5, rules.LEVELS} do
        -- A budget leaves the bot about two games in three; one of five is a win.
        local g
        for run = 1, 5 do
            g = play_board(level, run, restored_by(level))
            if g.won then break end
        end
        assert(g.won, ('balance sample: bot lost board %d five times'):format(level))
        local reward = rules.reward_breakdown(g).total
        -- The landing spawns coins and score pieces only.
        for slot, currency in ipairs(economy.currencies) do
            local available = slot == economy.GOLD or slot == economy.PROVISIONS and level >= 2
                or slot == economy.SUPPLIES and level >= 8
            check((reward[slot] > 0) == available, ('board %d pays %s'):format(level, currency.name))
        end
    end
    return
end

local found, given = pcall(require, 'balance_incomes')
local boards = found and given or {}
local first, last = 1, rules.LEVELS
if testing.tune_levels then
    first, last = testing.tune_levels:match('^(%d+)%-(%d+)$')
    first, last = tonumber(first), tonumber(last)
end
for level = first, found and 0 or last do
    local stats = {wins = 0, moves = 0, income = {}}
    for slot = 1, CURRENCIES do stats.income[slot] = 0 end
    local restored = restored_by(level)
    for run = 1, RUNS do
        local g = play_board(level, run, restored)
        if g.won then
            local reward = rules.reward_breakdown(g, {}).total
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
    print(('INCOME_JSON {"level":%d,"wins":%d,"moves":%.2f,"income":[%s]}'):format(level, stats.wins, stats.moves,
        table.concat((function() local t = {} for s = 1, CURRENCIES do t[s] = ('%.3f'):format(stats.income[s]) end return t end)(), ',')))
    check(stats.wins > 0, ('the bot wins board %d at least once'):format(level))
end
if testing.tune_levels then return end

-- Stops are the ladder's `after` clears.
local stops, order = {}, {}
for _, step in ipairs(island.ladder) do
    if step.after > rules.LEVELS then break end
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
        -- Rounding to fives can ask for more than a thin wallet holds: trim
        -- the stop's dearest price in that currency until it fits.
        for slot = 1, CURRENCIES do
            while true do
                local sum, dearest = 0, nil
                for _, b in ipairs(stops[after]) do
                    local price = fitted[b.key][slot]
                    sum = sum + price
                    if price > 5 and (not dearest or price > fitted[dearest.key][slot]) then dearest = b end
                end
                if sum <= carry[slot] or not dearest then break end
                fitted[dearest.key][slot] = fitted[dearest.key][slot] - 5
            end
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
        print(('PRICE_JSON {"key":"%s","after":%d,"cost":[%d,%d,%d]}'):format(b.key, after, f[1], f[2], f[3]))
    end
end

-- A purchase can wait for income from later expeditions until a story
-- restoration is due. In particular the Mill opens at 10, but its Supplies
-- first arrive on 11 after placing the Workshop.
local story_due = {}
for position, step in ipairs(island.ladder) do
    if step.story then story_due[step.after] = position end
end

local function walk(label, price_of)
    print(('expected campaign with %s prices (Coins/Food/Supplies):'):format(label))
    local wallet, replays, lowest = {}, 0, {}
    local next_purchase = 1
    for slot = 1, CURRENCIES do wallet[slot], lowest[slot] = 0, math.huge end
    for level = 1, rules.LEVELS do
        local income = boards[level].income
        for slot = 1, CURRENCIES do wallet[slot] = wallet[slot] + income[slot] end
        local bought, extra = {}, 0
        while island.ladder[next_purchase] and island.ladder[next_purchase].after <= level do
            local b = island.buildings[island.ladder[next_purchase].kind + 1]
            local price, need = price_of(b), 0
            for slot = 1, CURRENCIES do
                local short = price[slot] - wallet[slot]
                if short > 0 then need = math.max(need, income[slot] > 0 and math.ceil(short / income[slot]) or math.huge) end
            end
            if need > 0 and next_purchase > (story_due[level] or 0) then break end
            assert(need < math.huge, ('board %d pays none of a currency %s needs'):format(level, b.key))
            for slot = 1, CURRENCIES do
                wallet[slot] = wallet[slot] + need * income[slot] - price[slot]
                lowest[slot] = math.min(lowest[slot], wallet[slot])
            end
            extra, bought[#bought + 1] = extra + need, b.key
            next_purchase = next_purchase + 1
        end
        replays = replays + extra
        if #bought > 0 then
            print(('  board %02d · bought %s · replays %d · wallet %.0f/%.0f/%.0f'):format(level, table.concat(bought, ', '),
                extra, wallet[1], wallet[2], wallet[3]))
        end
    end
    check(not island.ladder[next_purchase] or island.ladder[next_purchase].after > rules.LEVELS, 'the expected campaign buys every earned restoration at ' .. label .. ' prices')
    print(('expected campaign (%s): %d replays, lowest wallet after a purchase %.0f/%.0f/%.0f, final %.0f/%.0f/%.0f'):format(
        label, replays, lowest[1], lowest[2], lowest[3], wallet[1], wallet[2], wallet[3]))
end
walk('current', function(b) return b.cost end)
walk('fitted', function(b) return fitted[b.key] end)
