-- Differential tests: previews and animation-free settlement must agree with
-- real swaps, damage, seeded refill and the normal animation-producing path.
local match3 = require('match3')
local function compare_board(rules, a, b)
    for _, key in ipairs{'rng','moves','score','relics','oil_left','obstacles','cleared','combo','last_gold','last_wood','last_stone'} do
        check(a[key] == b[key], 'settlement preserves ' .. key)
    end
    for i = 0, rules.CELLS - 1 do
        check(a.tiles[i].kind == b.tiles[i].kind and a.oil[i] == b.oil[i]
            and a.chain[i] == b.chain[i] and a.ice[i] == b.ice[i] and a.stone_hp[i] == b.stone_hp[i],
            'settlement preserves pieces and terrain')
    end
    for slot, value in pairs(a.earnings or {}) do check(b.earnings[slot] == value, 'settlement preserves income') end
    for slot, value in pairs(a.tool_meter or {}) do check(b.tool_meter[slot] == value, 'settlement preserves charges') end
end
local function exercise(config)
    config.levels = {{moves=200, score=0, relics=0, chains=0, ice=0, goals={'oil'}}}
    local rules = match3.new(config)
    local g = rules.game_start(0, 1234567)
    g.oil_left, g.obstacles = 0, 0
    for i = 0, rules.CELLS - 1 do
        g.oil[i] = i % 3 == 0 and 2 or 1
        g.oil_left = g.oil_left + 1
        if i % 11 == 0 then g.chain[i] = 2
        elseif i % 13 == 0 then g.ice[i] = 2
        elseif i % 17 == 0 then g.stone_hp[i], g.tiles[i] = 1, rules.tile(-1) end
        g.obstacles = g.obstacles + g.chain[i] + g.ice[i] + g.stone_hp[i]
    end
    check(rules.game_hint(g) or rules.game_shuffle(g), 'terrain fixture has a legal move')
    local before, probe, wave = rules.game_copy(g), rules.new_match(), rules.new_match()
    rules.game_matches(g, wave)
    check(wave.hits == 0, 'probe fixture is settled')
    local first_a, first_b
    for a = 0, rules.CELLS - 1 do
        for axis = 0, rules.AXES - 1 do
            local b = rules.hex_neighbor(a, axis)
            local legal, progress, score = rules.game_probe_swap(g, a, b, probe)
            local expected = rules.game_swap_matches(g, a, b)
            check((not not legal) == (not not expected), 'preview uses real swap legality')
            if legal then
                first_a, first_b = first_a or a, first_b or b
                local trial = rules.game_copy(g)
                check(rules.game_swap(trial, a, b, wave), 'previewed move really swaps')
                check(probe.hits == wave.hits, 'preview counts overlapping runs once')
                for i = 0, rules.CELLS - 1 do
                    check(probe.mask[i] == wave.mask[i], 'preview has exactly the real matched cells')
                end
                rules.game_apply(trial, wave)
                local removed = g.obstacles - trial.obstacles
                for i = 0, rules.CELLS - 1 do removed = removed + g.oil[i] - trial.oil[i] end
                check(progress == removed and score == trial.score - g.score, 'preview agrees with real layer damage and score')
            else check(probe.hits == 0 and not next(probe.mask), 'illegal probe clears stale matches') end
        end
    end
    compare_board(rules, g, before)
    for i = 0, rules.CELLS - 1 do check(g.tiles[i].kind == before.tiles[i].kind, 'probing restores swapped pieces') end
    check(first_a ~= nil, 'fixture exercises at least one legal preview')
    if first_a then
        rules.game_swap(g, first_a, first_b, wave)
        local fast = rules.game_copy(g)
        for _ = 1, 100 do
            rules.game_matches(g, wave)
            if wave.hits == 0 then break end
            rules.game_apply(g, wave)
            rules.game_apply(fast, wave)
            local from, steps = rules.game_collapse(g)
            local fast_from, fast_steps = rules.game_collapse(fast, true)
            check(steps ~= nil and fast_steps == nil, 'simulation omits only animation frames')
            for i = 0, rules.CELLS - 1 do check(from[i] == fast_from[i], 'simulation preserves refill origins') end
            compare_board(rules, g, fast)
        end
    end
end
for _, config in ipairs{
    {square=true, columns=7, rows=7, colors=5, refill_damping=2},
    {square=true, columns=7, rows=7, colors=5, match_min=4, refill_damping=1},
    {radius=3, colors=5, refill_damping=2},
    {radius=3, colors=5, flags=0},
    {square=true, columns=7, rows=7, colors=5, flags=match3.LINE_MATCHES | match3.NO_TRICKLE, refill_damping=1},
} do exercise(config) end
