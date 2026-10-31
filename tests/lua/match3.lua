-- Engine mechanics instantiate without either game's modules or assets.
local match3 = require("match3")
check(match3 == require("match3"), "built-in module is cached")
local function empty(rules)
    local g = rules.game_start(0, 123)
    for i = 0, rules.CELLS - 1 do
        g.active[i], g.tiles[i], g.chain[i], g.ice[i], g.soil[i] = true, rules.tile(-1), 0, 0, 0
    end
    return g
end
local a = match3.new{radius=2}
local b = match3.new{radius=3, match_min=4, flags=match3.NO_SPECIALS | match3.NO_TOOLS | match3.NO_TRICKLE}
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
    check(steps[1].from[center]==(flags==0 and left or above), "integer flag selects refill behavior")
end
do
    local g,m=empty(b),b.new_match()
    for q=-2,2 do g.tiles[b.hex_index(q,0)]=b.tile(1) end
    b.game_matches(g,m,-1)
    check(m.hits==5 and next(m.make)==nil, "NO_SPECIALS disables births")
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
for _, config in ipairs({{flags=1.5},{flags=64},{radius=0},{colors=1},{match_min=2}}) do
    check(not pcall(match3.new,config), "invalid descriptor is rejected")
end
print("match3 engine: independent games, configurable minimum, integer behavior/kind flags passed")
return 0
