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

local SHARE, OPENING_SHARE = .65, .5
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
                rules.game_collapse(g, true)
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
    for _, step in ipairs(island.ladder) do
        if step.after < number then restored[step.unlock.building] = true end
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
local function amounts(values, format, separator)
    local out = {}
    for slot = 1, CURRENCIES do out[slot] = format:format(values[slot]) end
    return table.concat(out, separator)
end

for level = first, found and 0 or last do
    local stats = {wins = 0, moves = 0, income = {}, planning = {}}
    local samples = {}
    for slot = 1, CURRENCIES do stats.income[slot], samples[slot] = 0, {} end
    local restored = restored_by(level)
    for run = 1, RUNS do
        local g = play_board(level, 500 + run, restored)   -- separate seeds from the move fit
        if g.won then
            local reward = rules.reward_breakdown(g, {}).total
            stats.wins, stats.moves = stats.wins + 1, stats.moves + g.moves
            for slot = 1, CURRENCIES do
                stats.income[slot] = stats.income[slot] + reward[slot]
                samples[slot][stats.wins] = reward[slot]
            end
        end
    end
    -- Mean income per win: a board pays when it is won, and a loss is retried.
    for slot = 1, CURRENCIES do
        stats.income[slot] = stats.income[slot] / math.max(1, stats.wins)
        table.sort(samples[slot])
        local lower_quartile = samples[slot][math.ceil(stats.wins / 4)] or 0
        stats.planning[slot] = (stats.income[slot] + math.min(lower_quartile, stats.income[slot])) / 2
    end
    stats.moves = stats.wins > 0 and stats.moves / stats.wins or 0
    boards[level] = stats
    print(('board %02d · wins %d/%d · moves left %.1f · income %s'):format(
        level, stats.wins, RUNS, stats.moves, amounts(stats.income, '%.0f', '/')))
    print(('INCOME_JSON {"level":%d,"wins":%d,"moves":%.2f,"income":[%s],"planning":[%s]}'):format(
        level, stats.wins, stats.moves, amounts(stats.income, '%.3f', ','), amounts(stats.planning, '%.3f', ',')))
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

-- Budget from the average of a typical and a lower-quartile win, then leave
-- part of that wallet for later purchases. Keep the first buy cheap enough
-- for a short tutorial clear.
local fitted, carry = {}, {}
for slot = 1, CURRENCIES do carry[slot] = 0 end
local next_stop = 1
for level = 1, rules.LEVELS do
    for slot = 1, CURRENCIES do carry[slot] = carry[slot] + boards[level].planning[slot] end
    local after = order[next_stop]
    if after == level then
        local totals = {}
        for slot = 1, CURRENCIES do
            totals[slot] = 0
            for _, b in ipairs(stops[after]) do totals[slot] = totals[slot] + b.cost[slot] end
        end
        for _, b in ipairs(stops[after]) do
            local price = {}
            local budget = level == 1 and OPENING_SHARE or SHARE
            for slot = 1, CURRENCIES do
                local share = totals[slot] > 0 and b.cost[slot] / totals[slot] or 0
                price[slot] = round5(budget * carry[slot] * share)
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
-- Work backwards and cap early price spikes at the next price. Only reduce
-- prices so the wallet computed at each purchase still covers its cost.
local ladder = {}
for _, after in ipairs(order) do
    for _, b in ipairs(stops[after]) do ladder[#ladder + 1] = b end
end
local function total(price) local t = 0 for slot = 1, CURRENCIES do t = t + price[slot] end return t end
local ceiling = math.huge
for i = #ladder, 1, -1 do
    local price = fitted[ladder[i].key]
    local proposed = total(price)
    if proposed > ceiling then
        local scale = ceiling / proposed
        for slot = 1, CURRENCIES do
            if price[slot] > 0 then price[slot] = math.max(5, math.floor(price[slot] * scale / 5) * 5) end
        end
        assert(total(price) <= ceiling, 'price cap must keep every priced currency')
    end
    ceiling = total(price)
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

-- Report any delayed purchases or replays the current ladder would need.
-- Require the fitted ladder to buy each building on its unlock clear.
local story_due = {}
for position, step in ipairs(island.ladder) do
    if step.story then story_due[step.after] = position end
end

local function walk(label, price_of, planning)
    print(('expected campaign with %s prices (Coins/Food/Supplies):'):format(label))
    local wallet, replays, delayed = {}, 0, 0
    local next_purchase = 1
    for slot = 1, CURRENCIES do wallet[slot] = 0 end
    for level = 1, rules.LEVELS do
        local income = boards[level][planning and 'planning' or 'income']
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
            end
            extra, bought[#bought + 1] = extra + need, b.key
            if island.ladder[next_purchase].after < level then delayed = delayed + 1 end
            next_purchase = next_purchase + 1
        end
        replays = replays + extra
        if #bought > 0 then
            print(('  board %02d · bought %s · replays %d · wallet %.0f/%.0f/%.0f'):format(level, table.concat(bought, ', '),
                extra, wallet[1], wallet[2], wallet[3]))
        end
    end
    check(not island.ladder[next_purchase] or island.ladder[next_purchase].after > rules.LEVELS, 'the expected campaign buys every earned restoration at ' .. label .. ' prices')
    if planning then
        check(replays == 0 and delayed == 0, ('the fitted ladder needs %d replays and delays %d purchases'):format(replays, delayed))
    end
    print(('expected campaign (%s): %d replays, %d delayed purchases, final wallet %s'):format(
        label, replays, delayed, amounts(wallet, '%.0f', '/')))
end
walk('current', function(b) return b.cost end)
walk('fitted', function(b) return fitted[b.key] end, true)
