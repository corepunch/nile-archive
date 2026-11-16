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
local campaign = require('campaign')
local plaques = {}
for i, spec in ipairs(rules.levels) do plaques[i] = campaign.tablet_order(spec) end
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

local PLACE_SEEDS = math.max(12, SEEDS * 2 // 5)

-- Candidate plaque patches, each with the authored count: the authored
-- shape moved up to two cells, and a compact patch grown around every
-- playable cell. Each patch's signal plate (level 30) is the patch cell
-- nearest the authored one.
local function candidates_for(level, spec)
    local active, list, seen = {}, {}, {}
    for i = 0, rules.CELLS - 1 do if spec.mask:sub(i + 1, i + 1) == '1' then active[#active + 1] = i end end
    local is_active = {}
    for _, i in ipairs(active) do is_active[i] = true end
    local function add(cells, distance, kind)
        local key = {}
        for k, id in ipairs(cells) do key[k] = id end
        table.sort(key)
        key = table.concat(key, ',')
        if seen[key] then return end
        seen[key] = true
        local signal
        if spec.authored_signal then
            for _, id in ipairs(cells) do
                if not signal or rules.hex_distance(id, spec.authored_signal) < rules.hex_distance(signal, spec.authored_signal) then signal = id end
            end
        end
        list[#list + 1] = {cells=cells, signal=signal, distance=distance, kind=kind}
    end
    for dq = -2, 2 do
        for dr = -2, 2 do
            if math.abs(dq + dr) <= 2 then
                local cells = {}
                for k, id in ipairs(spec.authored_oil) do
                    local moved = rules.hex_index(rules.hex_q(id) + dq, rules.hex_r(id) + dr)
                    cells[k] = moved >= 0 and is_active[moved] and moved or nil
                    if not cells[k] then cells = nil; break end
                end
                if cells then add(cells, (math.abs(dq) + math.abs(dr) + math.abs(dq + dr)) // 2, 'shifted') end
            end
        end
    end
    for _, anchor in ipairs(active) do
        local order = {table.unpack(active)}
        table.sort(order, function(a, b)
            local da, db = rules.hex_distance(a, anchor), rules.hex_distance(b, anchor)
            if da ~= db then return da < db end
            return a < b
        end)
        add({table.unpack(order, 1, #spec.authored_oil)}, 10, 'grown')
    end
    return list
end

-- Bare win rate of every candidate patch at the curve budget. The hardest
-- that still leaves blockers headroom (target + 0.10) wins, then the
-- hardest that meets the target, else the easiest. Ties keep the patch
-- nearest its authored place.
local function place(level, spec, target)
    local candidates = candidates_for(level, spec)
    -- Stable order: nearest the authored place first.
    for k, c in ipairs(candidates) do c.order = k end
    table.sort(candidates, function(a, b)
        if a.distance ~= b.distance then return a.distance < b.distance end
        return a.order < b.order
    end)
    local function use(c)
        spec.oil, spec.signal_cell = c.cells, c.signal
        plaques[level] = campaign.tablet_order(spec)
    end
    for _, c in ipairs(candidates) do
        use(c)
        apply_load(spec, 0, level)
        local wins = 0
        for n = 1, PLACE_SEEDS do if play(level, 500 + n, target.moves) then wins = wins + 1 end end
        c.rate = wins / PLACE_SEEDS
    end
    local function hardest(floor)
        local best
        for _, c in ipairs(candidates) do
            if c.rate >= floor and (not best or c.rate < best.rate) then best = c end
        end
        return best
    end
    local best = hardest(math.min(1, target.win + 0.10)) or hardest(target.win)
    if not best then
        for _, c in ipairs(candidates) do if not best or c.rate > best.rate then best = c end end
    end
    use(best)
    return best, #candidates
end

for level = first, last do
    local spec = rules.levels[level]
    local target = difficulty.target(level)
    local load, note, authored = 0, '', spec.opening ~= nil
    local placed, placements = {distance=0, rate=-1, cells=spec.oil}, 1
    if not authored then placed, placements = place(level, spec, target) end
    if authored then
        note = 'authored opening: plaques and blockers kept'
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
        chains=spec.chains, double_chains=spec.double_chains or 0, tablets=#(spec.oil_double or {}), load=load,
        moved=placed.distance > 0, plaques=table.concat(spec.oil, ' '), signal=spec.signal_cell or -1,
        placement=placed.kind or 'authored', bare_win=placed.rate, placements=placements, moves=moves,
        median=used[math.max(1, (#used + 1) // 2)] or -1, fastest=used[1] or -1,
        bot_win=wins / FINAL, won_in_3=quick / FINAL, samples=FINAL, note=note,
    })
end
