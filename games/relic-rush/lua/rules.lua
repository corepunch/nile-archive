-- rules.lua — hex match-4 rules and the ten-level campaign. Pure Lua: no
-- engine state, so tests/lua/relic.lua exercises it headlessly.
--
-- A connected group of four or more identical relics (sharing hex edges)
-- clears. Five leave a directional sun ray along the group's longest axis;
-- six or more leave a hex bomb, or a sun prism when six lie in a straight
-- line. Sand is excavated by clearing above it, chains and ice lock relics
-- until hit, and matched flames thaw the ice around them.
--
-- Cells are numbered 0..60 as in the original; tables are indexed by cell.
local M = {}

------------------------------------------------------------------ hex grid

-- 61 cells of a radius-4 hexagon in axial coordinates (q, r); neighbours are
-- numbered 0..5 and opposite directions differ by 3.
M.HEX_RADIUS, M.CELLS = 4, 61
local CELLS = M.CELLS
local qs, rs, index = {}, {}, {}
do
    local n = 0
    for q = -4, 4 do
        for r = math.max(-4, -q - 4), math.min(4, -q + 4) do
            qs[n], rs[n] = q, r
            index[q * 16 + r] = n
            n = n + 1
        end
    end
end
-- direction d: 0 = (+1, 0), 1 = (0, +1), 2 = (-1, +1), 3..5 the opposites
local dirs = {[0] = {1, 0}, {0, 1}, {-1, 1}, {-1, 0}, {0, -1}, {1, -1}}
local neighbors = {}
for i = 0, CELLS - 1 do
    neighbors[i] = {}
    for d = 0, 5 do
        local q, r = qs[i] + dirs[d][1], rs[i] + dirs[d][2]
        neighbors[i][d] = (math.abs(q) <= 4 and math.abs(r) <= 4 and math.abs(q + r) <= 4) and index[q * 16 + r] or -1
    end
end

function M.hex_index(q, r)
    if math.abs(q) > 4 or math.abs(r) > 4 or math.abs(q + r) > 4 then return -1 end
    return index[q * 16 + r]
end
function M.hex_q(cell) return qs[cell] or 0 end
function M.hex_r(cell) return rs[cell] or 0 end
function M.hex_neighbor(cell, d)
    local n = neighbors[cell]
    return n and n[d] or -1
end
function M.hex_center() return 30 end
function M.hex_distance(a, b)
    if a < 0 or a >= CELLS or b < 0 or b >= CELLS then return 10000 end
    local q, r = qs[a] - qs[b], rs[a] - rs[b]
    return (math.abs(q) + math.abs(r) + math.abs(q + r)) // 2
end
local hex_index, hex_q, hex_r, hex_neighbor, hex_distance, hex_center =
    M.hex_index, M.hex_q, M.hex_r, M.hex_neighbor, M.hex_distance, M.hex_center

------------------------------------------------------------------ campaign

M.LEVELS, M.COLORS, M.MATCH_MIN = 10, 6, 4
local LEVELS, COLORS, MATCH_MIN = M.LEVELS, M.COLORS, M.MATCH_MIN

-- Relic kinds with a meaning: idols are counted, flames thaw ice, leaves and
-- crystals are wood and stone for building.
M.RELIC_IDOL, M.RELIC_FLAME, M.RELIC_LEAF, M.RELIC_SCARAB, M.RELIC_CRYSTAL, M.RELIC_AMPHORA = 0, 1, 2, 3, 4, 5
M.NORMAL, M.ROW, M.COLUMN, M.DIAGONAL, M.BOMB, M.PRISM = 0, 1, 2, 3, 4, 5
local NORMAL, ROW, COLUMN, DIAGONAL, BOMB, PRISM = 0, 1, 2, 3, 4, 5
local RELIC_IDOL, RELIC_FLAME, RELIC_LEAF, RELIC_CRYSTAL = 0, 1, 2, 4

local function level(name, lesson, moves, score, relics, soil, chains, ice)
    return {name = name, lesson = lesson, moves = moves, score = score, relics = relics, soil = soil, chains = chains, ice = ice}
end

-- levels[lvl + 1] describes 0-based level lvl
M.levels = {
    level("First Light", "Join 4+ neighbors. Bends and diamonds count!", 24, 1100, 8, 0, 0, 0),
    level("The Jade Crescent", "Groups of five create a sun ray.", 28, 1800, 10, 7, 0, 0),
    level("Sunstone Spiral", "Excavate the spiral beneath the relics.", 32, 2300, 12, 12, 0, 0),
    level("The Vine Constellation", "Match locked relics to break their chains.", 34, 2700, 12, 10, 4, 0),
    level("Three Paths Meet", "Groups of six or more make a hex blast.", 36, 3100, 14, 13, 4, 0),
    level("Winter Lotus", "Break the ice around the frozen lotus.", 38, 3400, 14, 13, 0, 5),
    level("The Ember Ring", "Fire melts ice in all six neighboring cells.", 40, 3800, 16, 15, 4, 5),
    level("Prism Observatory", "Six in a straight line forge a sun prism.", 42, 4200, 16, 17, 4, 6),
    level("The Sixfold Seal", "Combine rays to clear all three axes.", 44, 4600, 18, 19, 5, 6),
    level("Heart of the Hexagon", "Uncover the ancient sun at the heart of the valley.", 46, 5000, 20, 22, 6, 6),
}
M.level_shapes = {"Hexagon", "Crescent", "Diamond", "Butterfly", "Hourglass", "Lotus", "Ring", "Twin courts", "Crossroads", "Sun crown"}

function M.level_of(g) return M.levels[g.level + 1] end

local function shape_cell(lvl, i)
    local q, r = hex_q(i), hex_r(i)
    local s, d, y = -q - r, hex_distance(i, hex_center()), 2 * r + q
    if lvl == 1 then return q <= 1 or (r < 0 and q + r < 3)
    elseif lvl == 2 then return math.abs(q) <= 3 and math.abs(r) <= 3
    elseif lvl == 3 then return math.abs(q) <= 1 or math.abs(y) >= 3
    elseif lvl == 4 then return math.abs(q) <= 2 or math.abs(y) <= 2
    elseif lvl == 5 then return d <= 3 or q == 0 or r == 0 or s == 0
    elseif lvl == 6 then return d > 1
    elseif lvl == 7 then return q ~= 0 or math.abs(r) <= 1
    elseif lvl == 8 then return math.abs(q) <= 1 or math.abs(r) <= 1 or math.abs(s) <= 1
    elseif lvl == 9 then return not (r < -1 and math.abs(q) <= 1)
    end
    return true
end

-- Lower ranks get sand, chains and ice first, giving each level its pattern.
local function terrain_rank(lvl, i)
    local q, r = hex_q(i), hex_r(i)
    local s, d = -q - r, hex_distance(i, hex_center())
    if lvl == 1 then return math.abs(d - 2) * 20 + math.abs(q + r) + q
    elseif lvl == 2 then return d * 12 + (q - r + 20) % 7
    elseif lvl == 3 then return ((q == 0 or r == 0 or s == 0) and 0 or 50) + d
    elseif lvl == 4 then return ((q == 0 or s == 0) and 0 or 40) + d
    elseif lvl == 5 then return math.abs(d - 2) * 20 + math.abs(q)
    elseif lvl == 6 then return math.abs(d - 2) * 20 + math.abs(r)
    elseif lvl == 7 then return ((q == r or q == -r or r == 0) and 0 or 40) + d
    elseif lvl == 8 then return math.abs(d - 3) * 20 + (q - r + 20) % 5
    end
    return d * 20 + (q - r + 20) % 6
end

--------------------------------------------------------------------- rules

-- xorshift32 on 32-bit values, the same stream as the C original
local function random_next(g)
    local x = g.rng
    x = x ~ ((x << 13) & 0xFFFFFFFF)
    x = x ~ (x >> 17)
    x = x ~ ((x << 5) & 0xFFFFFFFF)
    if x == 0 then x = 0x12345678 end
    g.rng = x
    return x
end
local function randn(g, n) return random_next(g) % n end

local function tile(kind, special) return {kind = kind, special = special or NORMAL} end
M.tile = tile

local function swap_tiles(g, a, b) g.tiles[a], g.tiles[b] = g.tiles[b], g.tiles[a] end
local function locked(g, i) return g.chain[i] > 0 or g.ice[i] > 0 end

local function cell_active(g, cell) return cell >= 0 and cell < CELLS and g.active[cell] end
M.game_cell_active = cell_active

local function equal(g, a, b)
    return cell_active(g, a) and cell_active(g, b) and g.tiles[a].kind >= 0 and g.tiles[a].kind == g.tiles[b].kind
end

local function ray_for_axis(axis) return axis == 0 and ROW or axis == 1 and COLUMN or DIAGONAL end
local function axis_of_ray(sp) return sp == ROW and 0 or sp == COLUMN and 1 or 2 end

-- An empty match: which cells clear (mask) and which specials appear (make).
local function new_match() return {mask = {}, make = {}, hits = 0} end
M.new_match = new_match

local function count_hits(m)
    local n = 0
    for i = 0, CELLS - 1 do if m.mask[i] then n = n + 1 end end
    m.hits = n
    return n
end

-- Flood fill of identical relics through shared hex edges.
local function collect_group(g, start, cells)
    if not cell_active(g, start) or g.tiles[start].kind < 0 then return 0 end
    local seen = {[start] = true}
    local n, head = 1, 1
    cells[1] = start
    while head <= n do
        local a = cells[head]
        head = head + 1
        local na = neighbors[a]
        for d = 0, 5 do
            local b = na[d]
            if b >= 0 and not seen[b] and equal(g, start, b) then
                seen[b] = true
                n = n + 1
                cells[n] = b
            end
        end
    end
    return n
end

local function mark_line(g, m, cell, axis)
    if cell_active(g, cell) then m.mask[cell] = true end
    for sign = 0, 1 do
        local d = axis + (sign == 1 and 3 or 0)
        local c = hex_neighbor(cell, d)
        while c >= 0 do
            if cell_active(g, c) then m.mask[c] = true end
            c = hex_neighbor(c, d)
        end
    end
end

local function mark_area(g, m, cell, radius)
    for i = 0, CELLS - 1 do
        if cell_active(g, i) and hex_distance(cell, i) <= radius then m.mask[i] = true end
    end
end

local function mark_color(g, m, kind)
    for i = 0, CELLS - 1 do
        if cell_active(g, i) and g.tiles[i].kind == kind then m.mask[i] = true end
    end
end

function M.game_matches(g, m, preferred)
    m.mask, m.make, m.hits = {}, {}, 0
    local seen = {}
    local cells = {}
    for i = 0, CELLS - 1 do
        if cell_active(g, i) and g.tiles[i].kind >= 0 and not seen[i] then
            local n = collect_group(g, i, cells)
            local pick, longest, long_axis = -1, 0, 0
            for k = 1, n do seen[cells[k]] = true end
            if n >= MATCH_MIN then
                for k = 1, n do
                    local a = cells[k]
                    m.mask[a] = true
                    m.hits = m.hits + 1
                    if g.tiles[a].special == NORMAL and not locked(g, a) and (pick < 0 or a == preferred) then pick = a end
                    for axis = 0, 2 do
                        if not equal(g, a, hex_neighbor(a, axis + 3)) then   -- count each run from its start
                            local run, c = 0, a
                            while c >= 0 and equal(g, a, c) do
                                run = run + 1
                                c = hex_neighbor(c, axis)
                            end
                            if run > longest then longest, long_axis = run, axis end
                        end
                    end
                end
                -- four is the base match; larger groups reward deliberate combinations
                local sp = n >= 6 and (longest >= 6 and PRISM or BOMB) or n == 5 and ray_for_axis(long_axis) or NORMAL
                if pick >= 0 and sp ~= NORMAL then m.make[pick] = sp end
            end
        end
    end
end
local game_matches = M.game_matches

function M.game_can_swap(g, a, b)
    return cell_active(g, a) and cell_active(g, b) and hex_distance(a, b) == 1 and not locked(g, a) and not locked(g, b)
        and g.tiles[a].kind >= 0 and g.tiles[b].kind >= 0
end
local game_can_swap = M.game_can_swap

-- false (and the board unchanged) if nothing would clear
function M.game_swap(g, a, b, m)
    if g.won or g.lost or not game_can_swap(g, a, b) then return false end
    swap_tiles(g, a, b)
    m.mask, m.make, m.hits = {}, {}, 0
    local sa, sb = g.tiles[a].special, g.tiles[b].special
    if sa == PRISM or sb == PRISM then
        local p = sa == PRISM and a or b
        local o = p == a and b or a
        if sa == PRISM and sb == PRISM then
            for i = 0, CELLS - 1 do if cell_active(g, i) then m.mask[i] = true end end
        else
            local kind = g.tiles[o].kind
            mark_color(g, m, kind)
            if g.tiles[o].special ~= NORMAL then   -- prism + special: that colour turns special first
                for i = 0, CELLS - 1 do
                    if g.tiles[i].kind == kind then g.tiles[i].special = g.tiles[o].special end
                end
            end
        end
        m.mask[p], m.mask[o] = true, true
        g.tiles[p].special = NORMAL
    elseif sa ~= NORMAL and sb ~= NORMAL then
        m.mask[a], m.mask[b] = true, true
        if sa == BOMB and sb == BOMB then
            mark_area(g, m, b, 2)
        elseif sa == BOMB or sb == BOMB then
            for i = 0, CELLS - 1 do
                if hex_distance(b, i) <= 1 then
                    for z = 0, 2 do mark_line(g, m, i, z) end
                end
            end
        else
            for z = 0, 2 do mark_line(g, m, b, z) end
        end
    else
        game_matches(g, m, b)
        if not m.mask[a] and not m.mask[b] then
            swap_tiles(g, a, b)
            m.mask, m.make, m.hits = {}, {}, 0
            return false
        end
    end
    if count_hits(m) == 0 then
        swap_tiles(g, a, b)
        return false
    end
    g.moves = g.moves - 1
    g.combo = 0
    return true
end
local game_swap = M.game_swap

-- Clear one wave, fire specials; returns the relics cleared.
function M.game_apply(g, m)
    local fired, thaw = {}, {}
    local more = true
    while more do   -- specials hit by the wave fire, possibly hitting more specials
        more = false
        for i = 0, CELLS - 1 do
            if cell_active(g, i) and m.mask[i] and not m.make[i] and not fired[i] and g.tiles[i].special ~= NORMAL and not locked(g, i) then
                fired[i] = true
                more = true
                local sp = g.tiles[i].special
                if sp == ROW or sp == COLUMN or sp == DIAGONAL then mark_line(g, m, i, axis_of_ray(sp))
                elseif sp == BOMB then mark_area(g, m, i, 1)
                else mark_color(g, m, g.tiles[i].kind) end
            end
        end
    end
    for i = 0, CELLS - 1 do   -- matched flames thaw the ice around them
        if cell_active(g, i) and m.mask[i] and g.tiles[i].kind == RELIC_FLAME and not locked(g, i) then
            for d = 0, 5 do
                local j = hex_neighbor(i, d)
                if cell_active(g, j) and g.ice[j] > 0 and not m.mask[j] then thaw[j] = true end
            end
        end
    end
    local cleared = 0
    g.last_gold, g.last_wood, g.last_stone = 0, 0, 0
    g.combo = g.combo + 1
    for i = 0, CELLS - 1 do
        if cell_active(g, i) then
            if thaw[i] then g.ice[i], g.obstacles = g.ice[i] - 1, g.obstacles - 1 end
            if m.mask[i] then
                if g.ice[i] > 0 then
                    g.ice[i], g.obstacles, g.score = g.ice[i] - 1, g.obstacles - 1, g.score + 20
                elseif g.chain[i] > 0 then
                    g.chain[i], g.obstacles, g.score = g.chain[i] - 1, g.obstacles - 1, g.score + 20
                else
                    if g.soil[i] > 0 then g.soil[i], g.dug, g.score = g.soil[i] - 1, g.dug + 1, g.score + 30 end
                    local k = g.tiles[i].kind
                    if k >= 0 then
                        if k == RELIC_IDOL then g.relics, g.last_gold = g.relics + 1, g.last_gold + 1 end
                        if k == RELIC_LEAF then g.wood, g.last_wood = g.wood + 1, g.last_wood + 1 end
                        if k == RELIC_CRYSTAL then g.stone, g.last_stone = g.stone + 1, g.last_stone + 1 end
                        g.score = g.score + 50 * g.combo
                        cleared = cleared + 1
                        if m.make[i] then g.tiles[i].special = m.make[i]
                        else g.tiles[i] = tile(-1, NORMAL) end
                    end
                end
            end
        end
    end
    g.cleared = g.cleared + cleared
    return cleared
end
local game_apply = M.game_apply

-- Gravity runs down each column (constant q) in segments separated by holes
-- and locked cells; new relics spawn at the top of each segment. Returns
-- from[cell] = source cell, or -n for the n-th relic spawned above.
function M.game_collapse(g)
    local from = {}
    for i = 0, CELLS - 1 do from[i] = i end
    for q = -4, 4 do
        local lane, n = {}, 0
        for r = -4, 4 do
            local i = hex_index(q, r)
            if i >= 0 then lane[n] = i; n = n + 1 end
        end
        local bottom = n - 1
        while bottom >= 0 do
            local i = lane[bottom]
            if not cell_active(g, i) or locked(g, i) then
                bottom = bottom - 1
            else
                local top = bottom
                while top > 0 and cell_active(g, lane[top - 1]) and not locked(g, lane[top - 1]) do top = top - 1 end
                local dst = bottom
                for y = bottom, top, -1 do
                    if g.tiles[lane[y]].kind >= 0 then
                        g.tiles[lane[dst]] = g.tiles[lane[y]]
                        from[lane[dst]] = lane[y]
                        dst = dst - 1
                    end
                end
                local spawn = 1
                while dst >= top do
                    g.tiles[lane[dst]] = tile(randn(g, COLORS), NORMAL)
                    from[lane[dst]] = -spawn
                    spawn = spawn + 1
                    dst = dst - 1
                end
                bottom = top - 1
            end
        end
    end
    return from
end
local game_collapse = M.game_collapse

local function copy_array(t)
    local c = {}
    for i = 0, CELLS - 1 do c[i] = t[i] end
    return c
end

-- A deep copy of a game, for trying moves out.
function M.game_copy(g)
    local c = {}
    for k, v in pairs(g) do c[k] = v end
    c.tiles = {}
    for i = 0, CELLS - 1 do c.tiles[i] = tile(g.tiles[i].kind, g.tiles[i].special) end
    c.active, c.soil, c.chain, c.ice = copy_array(g.active), copy_array(g.soil), copy_array(g.chain), copy_array(g.ice)
    c.tools = {g.tools[1], g.tools[2], g.tools[3]}
    return c
end
local game_copy = M.game_copy

-- Any move that clears something: ok, a, b.
function M.game_hint(g)
    local m = new_match()
    for i = 0, CELLS - 1 do
        for d = 0, 2 do
            local j = hex_neighbor(i, d)
            if game_can_swap(g, i, j) then
                local copy = game_copy(g)
                if game_swap(copy, i, j, m) then return true, i, j end
            end
        end
    end
    return false
end
local game_hint = M.game_hint

local function fill_without_matches(g)
    local cells = {}
    for i = 0, CELLS - 1 do
        if not locked(g, i) then g.tiles[i] = tile(-1, NORMAL) end
    end
    for i = 0, CELLS - 1 do
        if cell_active(g, i) and not locked(g, i) then
            local choices, n = {}, 0
            for k = 0, COLORS - 1 do
                g.tiles[i] = tile(k, NORMAL)
                if collect_group(g, i, cells) < MATCH_MIN then n = n + 1; choices[n] = k end
            end
            if n == 0 then return false end
            g.tiles[i] = tile(choices[randn(g, n) + 1], NORMAL)
        end
    end
    return true
end

function M.game_shuffle(g)
    -- never erase blockers or fill a hole merely to manufacture a move
    local m = new_match()
    for _ = 1, 2000 do
        if fill_without_matches(g) then
            game_matches(g, m, -1)
            if m.hits == 0 and game_hint(g) then return end
        end
    end
end
local game_shuffle = M.game_shuffle

function M.game_start(lvl, seed)
    lvl = num.clampi(lvl, 0, LEVELS - 1)
    local g = {
        tiles = {}, active = {}, soil = {}, chain = {}, ice = {},
        level = lvl, moves = 0, score = 0, relics = 0, dug = 0, obstacles = 0, initial_obstacles = 0, initial_soil = 0,
        combo = 0, cleared = 0, last_gold = 0, last_wood = 0, last_stone = 0, wood = 0, stone = 0,
        rng = (seed and seed ~= 0) and (seed & 0xFFFFFFFF) or 12345,
        won = false, lost = false,
        tools = {2, 2, 2},   -- pickaxe, dynamite, sunburst charges
    }
    local l = M.levels[lvl + 1]
    g.moves = l.moves
    local order, n = {}, 0
    for i = 0, CELLS - 1 do
        g.active[i] = shape_cell(lvl, i)
        g.tiles[i] = tile(-1, NORMAL)
        g.soil[i], g.chain[i], g.ice[i] = 0, 0, 0
        if g.active[i] then n = n + 1; order[n] = i end
    end
    game_shuffle(g)
    for i = 1, n do   -- selection sort, exactly as the original orders ties
        for j = i + 1, n do
            if terrain_rank(lvl, order[j]) < terrain_rank(lvl, order[i]) then order[i], order[j] = order[j], order[i] end
        end
    end
    for i = 1, math.min(l.soil, n) do g.soil[order[i]] = 1 end
    local taken = {}
    for i = 0, math.min(l.chains, n) - 1 do
        local cell = order[(i * 3 + 1) % n + 1]
        g.chain[cell], taken[cell] = 1, true
    end
    local count = 0
    for k = 0, n - 1 do
        if count >= l.ice then break end
        local cell = order[(k + 4) % n + 1]
        if not taken[cell] and hex_distance(cell, hex_center()) <= 3 then
            g.ice[cell] = (lvl >= 6 and count % 3 == 0) and 2 or 1
            taken[cell] = true
            count = count + 1
        end
    end
    for i = 0, CELLS - 1 do g.initial_obstacles = g.initial_obstacles + g.ice[i] + g.chain[i] end
    g.obstacles = g.initial_obstacles
    g.initial_soil = l.soil
    local m = new_match()
    game_matches(g, m, -1)
    if m.hits > 0 or not game_hint(g) then game_shuffle(g) end
    return g
end

function M.game_check_end(g)
    local l = M.levels[g.level + 1]
    g.won = g.score >= l.score and g.relics >= l.relics and g.dug >= l.soil and g.obstacles == 0
    g.lost = not g.won and g.moves <= 0
    if not g.won and not g.lost and not game_hint(g) then
        game_shuffle(g)
        return true   -- presentation must discard stale selection/hints after a reshuffle
    end
    return false
end

-- Tools: 0 pickaxe (one cell), 1 dynamite (radius 1), 2 sunburst (three axes).
function M.game_tool(g, tool, cell, m)
    if tool < 0 or tool > 2 or g.tools[tool + 1] <= 0 or g.won or g.lost or not cell_active(g, cell) then return false end
    m.mask, m.make, m.hits = {}, {}, 0
    g.tools[tool + 1] = g.tools[tool + 1] - 1
    g.combo = 0
    if tool == 0 then m.mask[cell] = true
    elseif tool == 1 then mark_area(g, m, cell, 1)
    else for z = 0, 2 do mark_line(g, m, cell, z) end end
    count_hits(m)
    return true
end

-- How good a move is for a greedy player: score plus weighted goal progress.
function M.game_evaluate_move(g, a, b)
    if not game_can_swap(g, a, b) then return -1 end
    local c = game_copy(g)
    local m = new_match()
    if not game_swap(c, a, b, m) then return -1 end
    game_apply(c, m)
    local goal = M.levels[g.level + 1].relics
    local relics = math.min(c.relics, goal) - math.min(g.relics, goal)
    return c.score - g.score + relics * 90 + (c.dug - g.dug) * 200 + (g.obstacles - c.obstacles) * 220
end

------------------------------------------------------------------- economy

M.GOLD, M.WOOD, M.STONE, M.STARS, M.COMPASSES = 1, 2, 3, 4, 5   -- purse slots

-- Guaranteed restoration funding is separate from the discretionary Gold purse.
-- Matches score points; their random colour mix cannot reduce a building grant.
M.FIRST_GOLD, M.REPLAY_GOLD, M.MOVE_GOLD, M.MAX_MOVE_GOLD = 80, 60, 2, 40
-- Pays the 20-compass land budget by the ninth discovery, at the Star gates.
M.compass_rewards = {1, 1, 3, 2, 2, 2, 3, 3, 3, 0}

function M.discovery_compasses(count)
    local n=0
    for i=1,math.min(count,LEVELS) do n=n+M.compass_rewards[i] end
    return n
end

function M.reward_breakdown(g, wonders, progress)
    local first = not progress or g.level == progress.level
    local bonus = math.min(M.MAX_MOVE_GOLD, math.max(0, g.moves) * M.MOVE_GOLD)
    local w = wonders[g.level + 1]
    local grant = first and w.cost or purse()
    local gold = first and M.FIRST_GOLD or M.REPLAY_GOLD
    return {first=first, grant=grant, base=gold, bonus=bonus,
        total=purse(grant[1]+gold+bonus, grant[2], grant[3], first and 3 or 0,
                    first and M.compass_rewards[g.level+1] or 0)}
end

function M.level_reward(g, wonders, progress)
    return M.reward_breakdown(g,wonders,progress).total
end

function M.progress_reward(p, g, wonders)
    if not g.won or g.reward_claimed or g.level < 0 or g.level >= LEVELS or g.level > p.level then return false end
    local reward = M.reward_breakdown(g,wonders,p)
    p.wallet = p.wallet + reward.total
    if reward.first then p.level = p.level + 1 end
    p.seed = g.rng
    g.reward_claimed = true
    return true, reward.first
end

return M
