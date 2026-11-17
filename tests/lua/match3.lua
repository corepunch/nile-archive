-- Engine mechanics instantiate without either game's modules or assets.
local match3 = require("match3")
check(match3 == require("match3"), "built-in module is cached")
local function empty(rules)
    local g = rules.game_start(0, 123)
    for i = 0, rules.CELLS - 1 do
        g.active[i], g.tiles[i], g.chain[i], g.ice[i] = true, rules.tile(-1), 0, 0
    end
    return g
end
local a = match3.new{radius=2}
local b = match3.new{radius=3, match_min=4, flags=match3.NO_TOOLS | match3.NO_TRICKLE}
check(a.CELLS==19 and b.CELLS==37 and a.MATCH_MIN==3 and b.MATCH_MIN==4)
check(a.hex_center()==9 and a.hex_index(3,0)==-1 and b.hex_index(3,0)>=0, "independent geometry")
for _, r in ipairs({a,b}) do
    local g, m = empty(r), r.new_match()
    for q=-1,1 do g.tiles[r.hex_index(q,0)]=r.tile(2) end
    r.game_matches(g,m,-1)
    check(m.hits==(r==a and 3 or 0), "instance match minimum")
end
for _, flags in ipairs({0, match3.NO_TRICKLE}) do
    local r = match3.new{radius=2, flags=flags}
    local g = empty(r)
    for i=0,r.CELLS-1 do g.active[i]=false end
    local center, left, above = r.hex_index(0,0), r.hex_index(-1,0), r.hex_index(0,-1)
    g.active[center],g.active[left],g.active[above]=true,true,true
    g.tiles[left],g.tiles[above]=r.tile(4),r.tile(2)
    local _, steps = r.game_collapse(g)
    check(steps[1].from[center]==above, "straight fall has priority with either flag")
    g.chain[above],g.tiles[center]=1,r.tile(-1)
    _, steps = r.game_collapse(g)
    check(flags==0 and steps[1].from[center]==left or flags~=0 and #steps==0 and g.tiles[center].kind<0,
          "trickling feeds around a chain; without it the chain is a gate and the cell waits")
end
do
    local g,m=empty(b),b.new_match()
    for q=-2,2 do g.tiles[b.hex_index(q,0)]=b.tile(1) end
    b.game_matches(g,m,-1)
    b.game_apply(g,m)
    local births=0
    for i=0,b.CELLS-1 do if g.tiles[i].kind>=0 then births=births+1 end end
    check(m.hits==5 and births==0, "a long line only clears: no piece is born in its place")
    local charges=g.tools[1]
    check(not b.game_tool(g,0,b.hex_center(),m) and g.tools[1]==charges, "NO_TOOLS preserves charges")
end
do
    local r=match3.new{radius=2,kind_flags={[1]=match3.GOAL | match3.WOOD}}
    local g,m=empty(r),r.new_match()
    local c=r.hex_center()
    g.tiles[c],m.mask[c]=r.tile(1),true
    r.game_apply(g,m)
    check(g.relics==1 and g.wood==1 and g.stone==0, "kind flags combine collection behavior")
end
for _, config in ipairs({{flags=1.5},{flags=512},{radius=0},{colors=1},{match_min=2}}) do
    check(not pcall(match3.new,config), "invalid descriptor is rejected")
end
-- A loadout adds moves to the level's budget.
do
    local r = match3.new{radius=4}
    local loadout = {kinds={0, 1, 2, 3, 4}, multipliers={}, tool_threshold=200, tool_meter={}}
    local plain = r.game_start(0, 77, {}, loadout)
    loadout.extra_moves = 3
    check(r.game_start(0, 77, {}, loadout).moves == plain.moves + 3, "extra_moves adds to the level's budget")
end

-- A fracture must tile the cell exactly, or a hole shows as the layer cracks.
do
    local shatter = require("match3.shatter")
    local seed = 0x1234567
    local function rand() seed = (seed * 1103515245 + 12345) % 2147483648; return seed / 2147483648 end
    for _ = 1, 20 do
        local shards = shatter.fracture(rand, shatter.SITES, shatter.SITE_GAP)
        local area = 0
        for _, f in ipairs(shards) do
            area = area + f.area
            check(#f.pts >= 3 and #f.pts <= 16, "a shard fits gfx.image_poly")
        end
        check(#shards >= shatter.SITES - 2, "a fracture has its shards")
        near(area, 3 * math.sqrt(3) / 2, "shards cover the hex once")
    end
end

-- A chained bottleneck is a gate: the cells it feeds start empty and get no
-- new pieces until the chain breaks; then pieces trickle through.
do
    local r = match3.new{radius=2}
    local g = r.game_start(0, 5)
    for i = 0, r.CELLS - 1 do g.active[i], g.chain[i], g.ice[i], g.stone_hp[i], g.tiles[i] = false, 0, 0, 0, r.tile(-1) end
    -- A one-cell neck at (0,0) between an upper and a lower chamber.
    local neck, above, below = r.hex_index(0, 0), r.hex_index(0, -1), r.hex_index(0, 1)
    for _, i in ipairs{r.hex_index(0, -2), above, neck, below, r.hex_index(0, 2)} do g.active[i] = true end
    for _, i in ipairs{above, r.hex_index(0, -2)} do g.tiles[i] = r.tile(1) end
    g.tiles[neck], g.chain[neck] = r.tile(2), 1
    local fed = r.game_fed_cells(g)
    check(fed[above] and not fed[neck] and not fed[below], "a chain gates the cells below it")
    r.game_collapse(g)
    check(g.tiles[below].kind == -1 and g.tiles[r.hex_index(0, 2)].kind == -1, "nothing refills behind a closed gate")
    g.chain[neck] = 0
    r.game_collapse(g)
    check(g.tiles[r.hex_index(0, 2)].kind == 2 and g.tiles[below].kind >= 0 and g.tiles[neck].kind >= 0,
          "an open gate lets pieces fall through and the inlet refills")
    local s = r.game_start(0, 5)
    for i = 0, r.CELLS - 1 do s.tiles[i] = r.tile(i % 3) end
    s.tiles[r.hex_index(0, 1)] = r.tile(-1)
    local before = s.tiles[r.hex_index(0, 1)]
    r.game_shuffle(s)
    check(s.tiles[r.hex_index(0, 1)] == before, "a shuffle leaves empty cells where they are")
end

print("match3 engine: independent games, configurable minimum, integer behavior/kind flags passed")
return 0
