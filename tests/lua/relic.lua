-- Relic Rush rules: hex grid, match-4 detection, specials, blockers, gravity,
-- tools, the campaign's boards and economy, and the island on the engine
-- city. Ported from the original tests/test_relic.c.
local rules = require("rules")
local island = require("island")
local CELLS, LEVELS, COLORS = rules.CELLS, rules.LEVELS, rules.COLORS
local NORMAL, ROW, COLUMN, DIAGONAL, BOMB, PRISM = rules.NORMAL, rules.ROW, rules.COLUMN, rules.DIAGONAL, rules.BOMB, rules.PRISM
local hex_index, hex_q, hex_r, hex_neighbor, hex_distance, hex_center =
    rules.hex_index, rules.hex_q, rules.hex_r, rules.hex_neighbor, rules.hex_distance, rules.hex_center
local tile = rules.tile

local failures, checks = 0, 0
local function check(cond, what)
    checks = checks + 1
    if not cond then failures = failures + 1; print("FAIL " .. what) end
end

local function blank()
    local g = {tiles = {}, active = {}, soil = {}, chain = {}, ice = {}, level = 0, moves = 80, score = 0, relics = 0, dug = 0,
               obstacles = 0, initial_obstacles = 0, initial_soil = 0, combo = 0, cleared = 0, last_gold = 0, last_wood = 0,
               last_stone = 0, wood = 0, stone = 0, rng = 123, won = false, lost = false, tools = {0, 0, 0}}
    for i = 0, CELLS - 1 do
        g.active[i] = true
        g.tiles[i] = tile(-1, NORMAL)
        g.soil[i], g.chain[i], g.ice[i] = 0, 0, 0
    end
    return g
end

-- A board with no group of four anywhere.
local function pattern()
    local g = blank()
    for i = 0, CELLS - 1 do g.tiles[i].kind = (hex_q(i) + 2 * hex_r(i) + 12) % 6 end
    return g
end

local function resolve(g, m)
    for _ = 1, 200 do
        rules.game_apply(g, m)
        rules.game_collapse(g)
        rules.game_matches(g, m, -1)
        if m.hits == 0 then
            rules.game_check_end(g)
            return true
        end
    end
    return false
end

local function line(g, start, axis, n, kind)
    local cell = start
    for k = 1, n do
        g.tiles[cell] = tile(kind, NORMAL)
        if k < n then cell = hex_neighbor(cell, axis) end
    end
    return cell
end

local function same_tile(a, b) return a.kind == b.kind and a.special == b.special end

local function test_grid()
    local c = hex_center()
    check(c == hex_index(0, 0), "centre")
    for i = 0, CELLS - 1 do
        check(hex_index(hex_q(i), hex_r(i)) == i, "index round trip")
        local n = 0
        for d = 0, 5 do
            local j = hex_neighbor(i, d)
            if j >= 0 then
                n = n + 1
                check(hex_distance(i, j) == 1 and hex_neighbor(j, (d + 3) % 6) == i, "neighbour symmetry")
            end
        end
        if hex_distance(i, c) < 4 then check(n == 6, "inner cells have six neighbours") end
    end
end

local function test_matching()
    local m = rules.new_match()
    local c = hex_center()
    for lvl = 0, LEVELS - 1 do
        for seed = 1, 100 do
            local g = rules.game_start(lvl, seed)
            rules.game_matches(g, m, -1)
            check(m.hits == 0 and rules.game_hint(g), "fresh board has a move and no match")
            check(g.initial_soil == rules.levels[lvl + 1].soil, "soil count")
            local obstacles = 0
            for i = 0, CELLS - 1 do obstacles = obstacles + g.ice[i] + g.chain[i] end
            check(g.obstacles == obstacles, "obstacle count")
        end
    end
    for axis = 0, 2 do
        local start = hex_neighbor(hex_neighbor(c, axis + 3), axis + 3)
        local g = blank()
        line(g, start, axis, 4, 2)
        rules.game_matches(g, m, c)
        check(m.hits == 4 and (m.make[c] or NORMAL) == NORMAL, "four in a line")
        g = blank()
        line(g, start, axis, 5, 2)
        rules.game_matches(g, m, c)
        check(m.hits == 5 and m.make[c] == (axis == 0 and ROW or axis == 1 and COLUMN or DIAGONAL), "five make a ray")
        g = blank()
        line(g, hex_neighbor(start, axis + 3), axis, 6, 2)
        rules.game_matches(g, m, c)
        check(m.hits == 6 and m.make[c] == PRISM, "six in a line make a prism")
        g = pattern()   -- a ray clears exactly its axis
        g.tiles[c] = tile(3, axis == 0 and ROW or axis == 1 and COLUMN or DIAGONAL)
        m = rules.new_match()
        m.mask[c] = true
        rules.game_apply(g, m)
        for i = 0, CELLS - 1 do
            local q, r = hex_q(i), hex_r(i)
            local on = axis == 0 and r == 0 or axis == 1 and q == 0 or axis == 2 and q + r == 0
            check((g.tiles[i].kind < 0) == on, "ray clears its axis")
        end
    end
    local g = blank()
    line(g, hex_neighbor(c, 3), 0, 4, 0)
    line(g, hex_neighbor(c, 4), 1, 4, 0)
    rules.game_matches(g, m, c)
    check(m.make[c] == BOMB, "a big bent group makes a bomb")
    for d = 0, 5 do   -- every rotation of a bent four counts; three never do
        g = blank()
        local a, b, e = hex_neighbor(c, d), hex_neighbor(c, (d + 1) % 6), hex_neighbor(hex_neighbor(c, d), d)
        g.tiles[c].kind, g.tiles[a].kind, g.tiles[b].kind = 0, 0, 0
        rules.game_matches(g, m, c)
        check(m.hits == 0, "three do not match")
        g.tiles[e].kind = 0
        rules.game_matches(g, m, c)
        check(m.hits == 4 and (m.make[c] or NORMAL) == NORMAL, "bent four matches")
    end
    g = blank()   -- two compact triangles make a four-cell diamond
    g.tiles[c].kind, g.tiles[hex_index(1, 0)].kind, g.tiles[hex_index(0, 1)].kind, g.tiles[hex_index(1, 1)].kind = 2, 2, 2, 2
    rules.game_matches(g, m, c)
    check(m.hits == 4, "diamond matches")
end

local function test_holes_and_shapes()
    local m = rules.new_match()
    local c = hex_center()
    local g = blank()   -- a missing cell splits a group, refuses swaps and tools, and stays empty
    line(g, hex_index(0, -2), 1, 5, 0)
    g.active[c] = false
    g.tiles[c].kind = -1
    rules.game_matches(g, m, c)
    check(m.hits == 0 and not rules.game_can_swap(g, c, hex_neighbor(c, 1)) and not rules.game_tool(g, 0, c, m), "hole splits")
    g.tiles[hex_index(0, -1)].kind = -1
    local below = g.tiles[hex_index(0, 1)]
    rules.game_collapse(g)
    check(g.tiles[c].kind == -1 and same_tile(below, g.tiles[hex_index(0, 1)]), "hole stays empty")

    local shapes = {}
    for lvl = 0, LEVELS - 1 do   -- ten unique connected masks, nothing in the voids
        g = rules.game_start(lvl, 31)
        shapes[lvl] = {}
        local n_active, start = 0, -1
        for i = 0, CELLS - 1 do
            shapes[lvl][i] = g.active[i]
            if g.active[i] then n_active, start = n_active + 1, i
            else check(g.tiles[i].kind == -1 and g.soil[i] == 0 and g.ice[i] == 0 and g.chain[i] == 0 and not rules.game_tool(g, 0, i, m), "void is empty") end
        end
        for earlier = 0, lvl - 1 do
            local same = true
            for i = 0, CELLS - 1 do if shapes[lvl][i] ~= shapes[earlier][i] then same = false end end
            check(not same, "shapes are unique")
        end
        local queue, head, n, seen = {start}, 1, 1, {[start] = true}
        while head <= n do
            local i = queue[head]
            head = head + 1
            for d = 0, 5 do
                local j = hex_neighbor(i, d)
                if j >= 0 and g.active[j] and not seen[j] then seen[j] = true; n = n + 1; queue[n] = j end
            end
        end
        check(n == n_active, "shape is connected")
        rules.game_collapse(g)
        for i = 0, CELLS - 1 do check(g.active[i] and g.tiles[i].kind >= 0 or not g.active[i] and g.tiles[i].kind == -1, "collapse fills only the shape") end
    end
end

local function test_moves_and_blockers()
    local m = rules.new_match()
    local c = hex_center()
    local g = rules.game_start(0, 5)
    local ok, a, b = rules.game_hint(g)
    check(ok, "hint")
    local moves = g.moves
    check(rules.game_swap(g, a, b, m) and g.moves == moves - 1, "swap spends a move")
    check(resolve(g, m) and g.score > 0, "resolve scores")
    g = rules.game_start(0, 7)
    local before = rules.game_copy(g)
    check(not rules.game_swap(g, 0, CELLS - 1, m) and not rules.game_can_swap(g, -1, c), "far swap refused")
    local same = true
    for i = 0, CELLS - 1 do if not same_tile(before.tiles[i], g.tiles[i]) then same = false end end
    check(same and before.moves == g.moves, "refused swap changes nothing")

    g = pattern()
    g.chain[c] = 1
    check(not rules.game_can_swap(g, c, hex_neighbor(c, 0)), "chains lock")
    g.chain[c] = 0
    g.ice[c] = 2
    g.obstacles = 2
    g.tools[1] = 2
    check(rules.game_tool(g, 0, c, m), "pickaxe")
    rules.game_apply(g, m)
    check(g.ice[c] == 1 and g.obstacles == 1, "double ice takes two hits")
    check(rules.game_tool(g, 0, c, m), "pickaxe again")
    rules.game_apply(g, m)
    check(g.ice[c] == 0, "ice gone")

    g = pattern()   -- a matched flame thaws one layer of ice on all six sides
    g.tiles[c].kind = rules.RELIC_FLAME
    for d = 0, 5 do g.ice[hex_neighbor(c, d)] = 2 end
    g.obstacles = 12
    m = rules.new_match()
    m.mask[c] = true
    rules.game_apply(g, m)
    for d = 0, 5 do check(g.ice[hex_neighbor(c, d)] == 1, "flame thaws") end
    check(g.obstacles == 6, "thaw counts obstacles")

    g = pattern()
    g.tools[2] = 1
    check(rules.game_tool(g, 1, c, m) and m.hits == 7, "dynamite hits seven")
    g = pattern()
    g.tools[3] = 1
    check(rules.game_tool(g, 2, c, m) and m.hits == 25, "sunburst hits three axes")

    g = pattern()   -- prism + relic clears that colour
    g.tiles[c].special = PRISM
    b = hex_neighbor(c, 0)
    local colour = g.tiles[b].kind
    check(rules.game_swap(g, c, b, m), "prism swap")
    rules.game_apply(g, m)
    for i = 0, CELLS - 1 do check(g.tiles[i].kind ~= colour, "prism clears the colour") end

    g = pattern()   -- gravity stops at a chained relic
    g.chain[c] = 1
    local above, top, under = hex_index(0, -2), hex_index(0, -4), hex_index(0, 1)
    g.tiles[above].kind, g.tiles[top].kind = -1, -1
    local lock, lower = g.tiles[c], g.tiles[under]
    rules.game_collapse(g)
    check(same_tile(lock, g.tiles[c]) and same_tile(lower, g.tiles[under]), "gravity stops at chains")
    for i = 0, CELLS - 1 do check(g.tiles[i].kind >= 0 and g.tiles[i].kind < COLORS, "board full") end
end

local function test_island()
    -- every win pays for the next wonder exactly once, and it fits somewhere
    local c = city.new()
    island.island_setup(c)
    local p = {level = 0, seed = 0, wallet = purse()}
    for i = 0, LEVELS - 1 do
        local g = rules.game_start(i, i + 1)
        g.won = true
        rules.progress_reward(p, g, island.wonders)
        local gold = p.wallet[rules.GOLD]
        rules.progress_reward(p, g, island.wonders)
        check(p.wallet[rules.GOLD] == gold and p.level == i + 1, "reward once")
        for z = 1, island.ISLAND_ZONES - 1 do c:unlock(z, p.wallet) end
        check(island.island_place_next(c, p.wallet, p.level, 0) and c.count == i + 1, "next wonder fits")
        check(not island.island_place_next(c, p.wallet, p.level, 0), "only one wonder per win")
    end
    check(p.wallet[rules.STARS] == 30, "stars accumulate")

    -- shoreline, collisions, failed builds change nothing, moving is free
    c = city.new()
    island.island_setup(c)
    c.open = 63
    local wallet = purse(5000, 5000, 5000)
    c:begin_place(0, vec2(10, 10))
    check(c:confirm(wallet, 0).result == city.BLOCKED and c.count == 0 and wallet[1] == 5000, "water blocks")
    c:begin_place(0, vec2(760, 2030))
    check(c:confirm(wallet, 0).result == city.BUILT, "lawn builds")
    c:begin_place(1, vec2(760, 2030))
    check(c:confirm(wallet, 0).result == city.BLOCKED, "overlap blocks")
    c:cancel()
    local gold = wallet[1]
    c:begin_move(0)
    c.ghost = vec2(836, 2040)
    check(c:confirm(wallet, 0).result == city.MOVED and wallet[1] == gold, "moving is free")
    c:begin_move(0)
    c.ghost = vec2(12, 12)
    check(c:confirm(wallet, 0).result == city.BLOCKED, "cannot move into water")

    -- regions need stars (kept) and compasses (spent), and must touch open land
    c = city.new()
    island.island_setup(c)
    wallet = purse()
    check(not c:unlock(1, wallet) and not c:can_place(vec2(1330, 2100), 0), "closed region")
    wallet[rules.STARS] = 6
    check(not c:unlock(1, wallet), "stars alone are not enough")
    wallet[rules.COMPASSES] = 2
    check(c:unlock(1, wallet) and wallet[rules.COMPASSES] == 0 and wallet[rules.STARS] == 6, "compasses spent, stars kept")
    check(not c:unlock(1, wallet) and c:can_place(vec2(1330, 2100), 0), "open region builds")
    check(not island.island_zone_touches(5, 1), "the temple ridge is far from the harbour")
end

local function test_campaign()
    local m = rules.new_match()
    local total, runs = 0, 0
    for lvl = 0, LEVELS - 1 do
        local wins = 0
        for seed = 1, 4 do
            local g = rules.game_start(lvl, seed)
            runs = runs + 1
            for _ = 1, 100 do
                if g.won or g.lost then break end
                local best, ba, bb = -1, -1, -1
                for i = 0, CELLS - 1 do
                    for d = 0, 2 do
                        local j = hex_neighbor(i, d)
                        local v = rules.game_evaluate_move(g, i, j)
                        if v > best then best, ba, bb = v, i, j end
                    end
                end
                if ba < 0 then
                    rules.game_shuffle(g)
                else
                    check(rules.game_swap(g, ba, bb, m), "greedy move is legal")
                    check(resolve(g, m), "board resolves")
                end
            end
            if g.won then wins = wins + 1 end
        end
        total = total + wins
    end
    check(total >= runs // 4, "the greedy bot wins a share of expeditions")
    print(("relic rush: greedy bot won %d of %d expeditions without tools"):format(total, runs))
end

test_grid()
test_matching()
test_holes_and_shapes()
test_moves_and_blockers()
test_island()
test_campaign()
print(("relic rush: %d checks, %d failures"):format(checks, failures))
return failures
