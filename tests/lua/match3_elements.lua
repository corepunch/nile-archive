local E = require('match3')
local geo = E.new{radius=2}
local function cell(q,r) return geo.hex_index(q,r) end
local function level()
    return {name='elements',moves=20,score=0,relics=0,chains=0,ice=0,
        stones={{cell=cell(-1,0),hp=2}},
        deliveries={tokens={cell(1,-2)},exits={cell(1,1)}}}
end
local function rules(l) return E.new{radius=2,flags=E.LINE_MATCHES,levels={l}} end
local R = rules(level())
do
    local g, m = R.game_start(0,123), R.new_match()
    check(g.obstacles==2, 'obstacles count actual layers')
    check(not R.game_can_swap(g,cell(-1,0),cell(0,0)), 'stone blocks swaps')
    m.mask[cell(0,0)] = true; g.tiles[cell(0,0)] = R.tile(0)
    R.game_apply(g,m)
    check(g.stone_hp[cell(-1,0)]==1, 'adjacency damages stone')
    local copy=R.game_copy(g);copy.stone_hp[cell(-1,0)]=3
    check(g.stone_hp[cell(-1,0)]==1, 'copy owns mutable element state')
end

do
    local g=R.game_start(0, 351)
    for i=0,R.CELLS-1 do if g.tiles[i].kind~=R.DELIVERY then g.tiles[i]=R.tile(-1) end end
    local a,b=cell(0,0),cell(0,-1)
    g.tiles[a],g.tiles[b]=R.tile(2,R.PRISM),R.tile(3,R.BOMB)
    local before=R.game_copy(g)
    check(R.game_hint(g), 'hint finds a prism and bomb combination')
    for i=0,R.CELLS-1 do
        check(g.tiles[i].kind==before.tiles[i].kind and g.tiles[i].special==before.tiles[i].special
            and g.chain[i]==before.chain[i] and g.ice[i]==before.ice[i] and g.stone_hp[i]==before.stone_hp[i],
            'hint cannot mutate tiles or elements')
    end
    check(g.rng==before.rng and g.moves==before.moves and g.obstacles==before.obstacles
        and g.delivered==before.delivered, 'hint preserves counters')
end

do
    local g = R.game_start(0, 357)
    local token, stone = cell(1,-2),cell(-1,0)
    R.game_shuffle(g)
    check(g.tiles[token].kind==R.DELIVERY and g.stone_hp[stone]==2,
        'shuffle preserves fixed blockers and delivery token')
end

do
    local g, m = R.game_start(0, 789), R.new_match()
    local left, upper, blocker = cell(0,0), cell(-1,1), cell(-1,0)
    g.tiles[left], g.tiles[upper] = R.tile(0), R.tile(0)
    m.mask[left], m.mask[upper] = true, true
    R.game_apply(g,m)
    check(g.stone_hp[blocker]==1, 'two adjacent hits damage a stone only once per wave')
    local token=cell(1,-2)
    g.tiles[token]=R.tile(R.DELIVERY)
    m=R.new_match();m.mask[token],m.direct[token]=true,true
    R.game_apply(g,m)
    check(g.tiles[token].kind==R.DELIVERY, 'delivery token survives direct special damage')
end

do
    local l = level()
    local stone, neighbor = cell(-1, 0), cell(-1, 1)
    l.stones[2] = {cell=neighbor, hp=3}
    local ruleset = rules(l)
    local g = ruleset.game_start(0, 789)
    for hp = 1, 0, -1 do
        local m = ruleset.new_match()
        m.mask[stone], m.direct[stone] = true, true
        ruleset.game_apply(g, m)
        check(g.stone_hp[stone] == hp, 'each direct special hit removes one stone layer')
        check(g.stone_hp[neighbor] == 3, 'connected stone cells retain independent durability')
    end
    check(g.obstacles == 3, 'clearing one connected cell preserves the other cell in the goal')
end

do
    local g=R.game_start(0,987)
    g.obstacles=0
    R.game_check_end(g)
    check(not g.won, 'undelivered token prevents victory')
    g.delivered=g.delivery_total
    R.game_check_end(g)
    check(g.won, 'victory accepts the delivered token')
end

do
    local g=R.game_start(0,321)
    for i=0,R.CELLS-1 do
        g.active[i]=false;g.tiles[i]=R.tile(-1);g.chain[i]=0;g.ice[i]=0;g.stone_hp[i]=0
    end
    local top,exit=cell(0,-1),cell(0,0)
    g.active[top],g.active[exit]=true,true
    g.delivery_exits={[exit]=true};g.delivered=0;g.tiles[top]=R.tile(R.DELIVERY)
    local _,steps=R.game_collapse(g)
    check(g.delivered==1 and steps[1].from[exit]==top, 'delivery falls to its exit once')
    check(steps[1].tiles[exit].kind==R.DELIVERY, 'fall snapshot retains the delivered token')
    check(g.tiles[top].kind~=R.DELIVERY and g.tiles[exit].kind~=R.DELIVERY, 'delivered token is consumed')
end

do
    local g=R.game_start(0,721)
    local left, stone = cell(0,0),cell(-1,0)
    g.tiles[left]=R.tile(1);g.ice[left]=1;g.obstacles=g.obstacles+1
    local m=R.new_match();m.mask[left],m.ordinary[left]=true,true
    R.game_apply(g,m)
    check(g.ice[left]==0 and g.stone_hp[stone]==1, 'a matched frozen piece still damages an adjacent stone')
end

do
    local invalid=level();invalid.stones[1].cell=invalid.deliveries.tokens[1]
    check(not pcall(function() rules(invalid).game_start(0,1) end), 'overlapping elements are rejected')
    invalid=level();invalid.deliveries.exits={}
    check(not pcall(function() rules(invalid).game_start(0,1) end), 'token requires an exit')
    invalid=level();invalid.deliveries.exits={cell(2,-2)}
    check(not pcall(function() rules(invalid).game_start(0,1) end), 'uphill unreachable delivery exit is rejected')
end
-- Compare the fast hint search with the actual swap operation in both match
-- modes, including live blockers and delivery pieces.
for _, flags in ipairs({0,E.LINE_MATCHES}) do
    local r=E.new{radius=2,flags=flags,levels={level()}}
    for seed=1,4 do
        local g=r.game_start(0,seed)
        local expected,a,b=false,nil,nil
        for i=0,r.CELLS-1 do
            for d=0,2 do
                local j=r.hex_neighbor(i,d)
                if r.game_can_swap(g,i,j) and r.game_swap(r.game_copy(g),i,j,r.new_match()) then
                    expected,a,b=true,i,j
                    break
                end
            end
            if expected then break end
        end
        local found,x,y=r.game_hint(g)
        check(found==expected and (not found or x==a and y==b), 'fast hint agrees with full swap oracle')
    end
end
-- Carpet spreads only through a match that touches it, and counts down the
-- cells left to cover.
do
    local C = rules{name='carpet',moves=20,score=0,relics=0,chains=0,ice=0,carpet={cell(0,0)},goals={'carpet'}}
    local g = C.game_start(0,7)
    check(g.carpeted==1 and g.carpet_total==C.CELLS - (function() local n=0 for i=0,C.CELLS-1 do if not g.active[i] then n=n+1 end end return n end)(),
        'carpet goal covers every active cell')
    for i=0,C.CELLS-1 do g.tiles[i]=C.tile(-1) end
    local away = {cell(2,-2),cell(2,-1),cell(2,0)}
    for _,i in ipairs(away) do g.tiles[i]=C.tile(1) end
    local m=C.new_match();C.game_matches(g,m,-1);C.game_apply(g,m)
    check(g.carpeted==1 and g.carpet[away[2]]==0, 'a match away from the carpet does not spread it')
    local line = {cell(0,-1),cell(0,0),cell(0,1)}
    for i=0,C.CELLS-1 do g.tiles[i]=C.tile(-1) end
    for _,i in ipairs(line) do g.tiles[i]=C.tile(2) end
    m=C.new_match();C.game_matches(g,m,-1);C.game_apply(g,m)
    check(g.carpeted==3 and g.carpet[line[1]]==1 and g.carpet[line[3]]==1, 'a match through the carpet carpets every matched cell')
    check(C.game_copy(g).carpet ~= g.carpet, 'copy owns the carpet layer')
end

-- Oil clears under a match on it and spreads after a move that clears none.
do
    local C = rules{name='oil',moves=20,score=0,relics=0,chains=0,ice=0,oil={cell(0,0),cell(0,1)},goals={'oil'}}
    local g = C.game_start(0,9)
    check(g.oil_left==2, 'oil seeds count')
    for i=0,C.CELLS-1 do g.tiles[i]=C.tile(-1) end
    for _,i in ipairs({cell(-1,0),cell(0,0),cell(1,0)}) do g.tiles[i]=C.tile(3) end
    g.turn_pending,g.oil_cleared = true,false
    local m=C.new_match();C.game_matches(g,m,-1);C.game_apply(g,m)
    check(g.oil[cell(0,0)]==0 and g.oil_left==1 and g.oil_cleared, 'a match on oil clears it')
    check(not C.game_end_turn(g) and g.oil_left==1, 'oil does not spread after a move that cleared some')
    g.turn_pending,g.oil_cleared = true,false
    check(C.game_end_turn(g) and g.oil_left==2, 'oil spreads after a move that cleared none')
    local grown = g.oil_grew
    check(grown and g.oil[grown]==1 and grown~=cell(0,1), 'it spreads into a new cell')
    check(C.game_copy(g).oil ~= g.oil, 'copy owns the oil layer')
    g.oil_left = 0; g.turn_pending = false
    C.game_check_end(g)
    check(g.won, 'clearing the oil wins an oil-only level')
end

print('match3 elements: stones, deliveries, carpet and oil passed')
return 0
