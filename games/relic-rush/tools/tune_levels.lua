-- Run through tools/tune_levels.py. Simulates the real rules on seeded starts
-- and fits each board's blockers and move budget to lua/difficulty.lua.
-- Consecutive small seeds start xorshift on similar streams, so every sample
-- seed is hashed first.
-- Arguments: --tune-levels A-B (one-based, inclusive), --tune-seeds N.
local rules, difficulty = require('rules'), require('difficulty')
local first, last = (app.arg('tune-levels') or ('1-' .. rules.LEVELS)):match('^(%d+)%-(%d+)$')
first, last = tonumber(first), tonumber(last)
local SEEDS = tonumber(app.arg('tune-seeds') or '40')
local FINAL = SEEDS * 2            -- the fit is measured again on fresh starts
local CHAIN_MAX = 12               -- single chains first, then convert them to doubles
local m = rules.new_match()

local function best_move(g)
    local best, a, b = -1, -1, -1
    for i = 0, rules.CELLS - 1 do
        for d = 0, 2 do
            local j = rules.hex_neighbor(i, d)
            local value = rules.game_evaluate_move(g, i, j)
            if value > best then best, a, b = value, i, j end
        end
    end
    return a, b
end

local function seed_of(n) return (n * 2654435761 + 0x9E3779B9) & 0x7FFFFFFF | 1 end

-- Moves the bot needed to win within cap, or nil.
local function play(level, n, cap)
    rules.levels[level].moves = cap
    local g = rules.game_start(level - 1, seed_of(n))
    local shuffles = 0
    while not g.won and not g.lost do
        local a, b = best_move(g)
        if a < 0 then
            shuffles = shuffles + 1
            if shuffles > 50 then return nil end
            rules.game_shuffle(g)
        else
            assert(rules.game_swap(g, a, b, m), 'bot chose an illegal move')
            for _ = 1, 500 do
                rules.game_apply(g, m); rules.game_collapse(g); rules.game_matches(g, m, -1)
                if m.hits == 0 then rules.game_check_end(g); break end
            end
        end
    end
    return g.won and cap - g.moves or nil
end

-- Blocker load, one step at a time: chains and green double tablets
-- alternate (each capped), then chains turn into crossed double chains.
local plaques = {}
for i, spec in ipairs(rules.levels) do plaques[i] = require('campaign').tablet_order(spec) end
local function split(level, load)
    local patch = #plaques[level]
    local chains, tablets = math.min(CHAIN_MAX, (load + 1) // 2), math.min(patch, load // 2)
    local rest = load - chains - tablets
    local more = math.min(rest, CHAIN_MAX - chains); chains, rest = chains + more, rest - more
    more = math.min(rest, patch - tablets); tablets, rest = tablets + more, rest - more
    return chains, tablets, math.min(rest, chains)
end
local function max_load(level) return CHAIN_MAX * 2 + #plaques[level] end
local function apply_load(spec, load, level)
    local chains, tablets, doubles = split(level, load)
    spec.chains, spec.double_chains = chains, doubles
    spec.oil_double = {table.unpack(plaques[level], 1, tablets)}
end

local function feasible(level, load)
    apply_load(rules.levels[level], load, level)
    return pcall(rules.game_start, level - 1, 1)
end

-- Does the bot win at least share of the starts within moves? Sampling stops
-- as soon as the answer is certain.
local function holds(level, load, moves, share)
    apply_load(rules.levels[level], load, level)
    local need = math.ceil(share * SEEDS)
    local wins, losses = 0, 0
    for n = 1, SEEDS do
        if play(level, n, moves) then wins = wins + 1 else losses = losses + 1 end
        if wins >= need then return true end
        if losses > SEEDS - need then return false end
    end
    return wins >= need
end

local function json(t)
    local parts = {}
    for k, v in pairs(t) do
        local value = type(v) == 'string' and ('"' .. v .. '"') or tostring(v)
        parts[#parts + 1] = ('"%s":%s'):format(k, value)
    end
    table.sort(parts)
    return '{' .. table.concat(parts, ',') .. '}'
end

for level = first, last do
    local spec = rules.levels[level]
    local target = difficulty.target(level)
    local load, note, authored = 0, '', spec.opening ~= nil
    if authored then
        note = 'authored opening: blockers kept'
    elseif target.blockers and not holds(level, 0, target.moves, target.win) then
        note = 'hard without blockers: moves raised'
    elseif target.blockers then
        -- The most blockers that still leave the target share winnable.
        local pass, fail, top = 0, nil, max_load(level)
        while not feasible(level, top) do top = top - 1 end
        local loads = {}
        for _, step in ipairs{1, 2, 4, 6, 9, 12, 16, 20, 25, 30, 36, 42, 48} do
            if step < top then loads[#loads + 1] = step end
        end
        loads[#loads + 1] = top
        for _, step in ipairs(loads) do
            if holds(level, step, target.moves, target.win) then pass = step else fail = step; break end
        end
        if fail then
            while fail - pass > 1 do
                local mid = (pass + fail) // 2
                if holds(level, mid, target.moves, target.win) then pass = mid else fail = mid end
            end
        else note = 'blocker cap reached: moves lowered' end
        load = pass
    end
    -- The budget is read off fresh starts: the fewest moves in which the bot
    -- wins the target share, never below the curve's floor.
    if not authored then apply_load(spec, load, level) end
    local cap, used, quick = target.moves * 2, {}, 0
    for n = 1000, 1000 + FINAL - 1 do
        local took = play(level, n, cap)
        if took then used[#used + 1] = took end
        if took and took <= 3 then quick = quick + 1 end
    end
    table.sort(used)
    local need = math.ceil(target.win * FINAL)
    local moves = used[need] or cap
    if not used[need] then note = 'bot misses the target even at twice the curve' end
    moves = math.max(moves, target.min_moves)
    local wins = 0
    for _, took in ipairs(used) do if took <= moves then wins = wins + 1 end end
    print('TUNE_JSON ' .. json{
        level=level, name=spec.name, tier=target.tier, target_moves=target.moves, target_win=target.win,
        chains=spec.chains, double_chains=spec.double_chains or 0, tablets=#(spec.oil_double or {}), load=load, moves=moves,
        median=used[math.max(1, (#used + 1) // 2)] or -1, fastest=used[1] or -1,
        bot_win=wins / FINAL, won_in_3=quick / FINAL, samples=FINAL, note=note,
    })
end
