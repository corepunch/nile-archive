local E = require('match3')
local geo = E.new{radius=2}
local function cell(q,r) return geo.hex_index(q,r) end
local function level()
    return {name='elements',moves=20,score=0,relics=0,soil=0,chains=0,ice=0,
        stones={{cell=cell(-1,0),hp=2}}, crates={{cell=cell(1,0),hp=2,kind=1}},
        objects={{cells={cell(0,1),cell(1,-1)}}}, hazards={cell(-2,0)},
        tunnels={{entrance=cell(0,-2),exit=cell(0,2)}},
        deliveries={tokens={cell(1,-2)},exits={cell(1,1)}}}
end
local function rules(l) return E.new{radius=2,flags=E.LINE_MATCHES,levels={l}} end
local R = rules(level())
do
    local g, m = R.game_start(0,123), R.new_match()
    check(g.initial_soil==2 and g.obstacles==5, 'terrain objectives count actual layers')
    check(not R.game_can_swap(g,cell(-1,0),cell(0,0)), 'stone blocks swaps')
    m.mask[cell(0,0)] = true; g.tiles[cell(0,0)] = R.tile(0)
    R.game_apply(g,m)
    check(g.stone_hp[cell(-1,0)]==1 and g.crate_hp[cell(1,0)]==2, 'adjacency damages stone but wrong colour cannot damage crate')
    m=R.new_match();m.mask[cell(0,0)]=true;g.tiles[cell(0,0)]=R.tile(1)
    R.game_apply(g,m)
    check(g.stone_hp[cell(-1,0)]==0 and g.crate_hp[cell(1,0)]==1, 'matching colour hits crate once per wave')
    m=R.new_match();check(R.game_tool(g,0,cell(1,0),m), 'pickaxe targets crate');R.game_apply(g,m)
    check(g.crate_hp[cell(1,0)]==0, 'tool bypasses crate colour')
    local first, second = cell(0,1),cell(1,-1)
    m=R.new_match();m.mask[first]=true;R.game_apply(g,m)
    check(g.objects[1].state=='partial' and g.discovered==0, 'object remains undiscovered after partial excavation')
    m=R.new_match();m.mask[second]=true;R.game_apply(g,m)
    check(g.objects[1].state=='revealed' and g.discovered==1, 'complete footprint discovers one object')
    R.game_apply(g,m);check(g.discovered==1, 'discovery cannot be counted twice')
    local copy=R.game_copy(g);copy.stone_hp[first]=3;copy.objects[1].state='hidden'
    check(g.stone_hp[first]~=3 and g.objects[1].state=='revealed', 'copy owns mutable element state')
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
            and g.soil[i]==before.soil[i] and g.chain[i]==before.chain[i] and g.ice[i]==before.ice[i]
            and g.stone_hp[i]==before.stone_hp[i] and g.crate_hp[i]==before.crate_hp[i]
            and g.crate_kind[i]==before.crate_kind[i] and g.hazard[i]==before.hazard[i],
            'hint cannot mutate tiles, terrain or elements')
    end
    check(g.rng==before.rng and g.moves==before.moves and g.obstacles==before.obstacles
        and g.discovered==before.discovered and g.delivered==before.delivered
        and g.objects[1].state==before.objects[1].state, 'hint preserves counters and object progress')
end

do
    local g = R.game_start(0, 357)
    local token, stone, crate = cell(1,-2),cell(-1,0),cell(1,0)
    R.game_shuffle(g)
    check(g.tiles[token].kind==R.DELIVERY and g.stone_hp[stone]==2 and g.crate_hp[crate]==2,
        'shuffle preserves fixed blockers and delivery token')
end

do
    local g, m = R.game_start(0, 789), R.new_match()
    local left, upper, blocker = cell(0,0), cell(-1,1), cell(-1,0)
    g.tiles[left], g.tiles[upper] = R.tile(0), R.tile(0)
    m.mask[left], m.mask[upper] = true, true
    R.game_apply(g,m)
    check(g.stone_hp[blocker]==1, 'two adjacent hits damage a stone only once per wave')
    local crate=cell(1,0)
    m=R.new_match();m.mask[crate],m.direct[crate]=true,true
    R.game_apply(g,m)
    check(g.crate_hp[crate]==1, 'special direct damage bypasses colour without multiple hits')
    local token=cell(1,-2)
    g.tiles[token]=R.tile(R.DELIVERY)
    m=R.new_match();m.mask[token],m.direct[token]=true,true
    R.game_apply(g,m)
    check(g.tiles[token].kind==R.DELIVERY, 'delivery token survives direct special damage')
    local hazard=cell(-2,0)
    m=R.new_match();m.mask[hazard],m.direct[hazard]=true,true
    R.game_apply(g,m)
    check(g.hazard[hazard]==0 and g.hazard_damaged, 'direct hit damages spreading hazard')
    g.turn_pending=true
    check(not R.game_end_turn(g), 'hazard damage suppresses growth after the cascade')
end

do
    local g=R.game_start(0,987)
    g.dug,g.obstacles=g.initial_soil,0
    R.game_check_end(g)
    check(not g.won, 'undiscovered footprint prevents victory')
    g.discovered=#g.objects
    R.game_check_end(g)
    check(not g.won, 'undelivered token prevents victory')
    g.delivered=g.delivery_total
    R.game_check_end(g)
    check(g.won, 'victory requires and accepts both new objectives')
end

do
    local g=R.game_start(0,321)
    for i=0,R.CELLS-1 do
        g.active[i]=false;g.tiles[i]=R.tile(-1);g.chain[i]=0;g.ice[i]=0
        g.hazard[i]=0;g.stone_hp[i]=0;g.crate_hp[i]=0
    end
    local entrance,exit=cell(0,-2),cell(0,2)
    g.active[entrance],g.active[exit]=true,true
    g.tunnel_to,g.tunnel_from={[entrance]=exit},{[exit]=entrance}
    g.delivery_exits={[exit]=true};g.delivered=0;g.tiles[entrance]=R.tile(R.DELIVERY)
    local _,steps=R.game_collapse(g)
    check(g.delivered==1 and steps[1].from[exit]==entrance, 'tunnel carries delivery to exit once')
    check(steps[1].tiles[exit].kind==R.DELIVERY, 'fall snapshot retains the delivered token')
    check(g.tiles[entrance].kind~=R.DELIVERY and g.tiles[exit].kind~=R.DELIVERY, 'delivered token is consumed')
end

do
    local g=R.game_start(0,721)
    local left, stone, crate = cell(0,0),cell(-1,0),cell(1,0)
    g.tiles[left]=R.tile(1);g.ice[left]=1;g.obstacles=g.obstacles+1
    local m=R.new_match();m.mask[left],m.ordinary[left]=true,true
    R.game_apply(g,m)
    check(g.ice[left]==0 and g.stone_hp[stone]==1 and g.crate_hp[crate]==1,
        'a matched frozen piece still damages adjacent stone and matching crate')
end

do
    local g=R.game_start(0,731)
    for i=0,R.CELLS-1 do
        g.active[i]=false;g.tiles[i]=R.tile(-1);g.chain[i]=0;g.ice[i]=0
        g.hazard[i]=0;g.stone_hp[i]=0;g.crate_hp[i]=0
    end
    local entrance,child,exit=cell(0,-1),cell(0,0),cell(1,1)
    g.active[entrance],g.active[child],g.active[exit]=true,true,true
    g.tunnel_to,g.tunnel_from={[entrance]=exit},{[exit]=entrance}
    g.delivery_exits={}
    g.tiles[entrance],g.tiles[exit]=R.tile(1,R.ROW),R.tile(3)
    local _,steps=R.game_collapse(g)
    check(#steps>0 and steps[1].from[child]<0 and g.tiles[entrance].special==R.ROW,
        'normal child refills while redirected parent waits for occupied tunnel exit')
end

do
    local g=R.game_start(0,732)
    for i=0,R.CELLS-1 do
        g.active[i]=false;g.tiles[i]=R.tile(-1);g.chain[i]=0;g.ice[i]=0
        g.hazard[i]=0;g.stone_hp[i]=0;g.crate_hp[i]=0
    end
    local entrance,above,exit=cell(0,-2),cell(0,1),cell(0,2)
    g.active[entrance],g.active[above],g.active[exit]=true,true,true
    g.tunnel_to,g.tunnel_from={[entrance]=exit},{[exit]=entrance}
    g.delivery_exits={};g.tiles[entrance],g.tiles[above]=R.tile(1,R.ROW),R.tile(3)
    local _,steps=R.game_collapse(g)
    local count=0
    for i=0,R.CELLS-1 do if steps[1].tiles[i].special==R.ROW then count=count+1 end end
    check(steps[1].from[exit]==entrance and count==1, 'portal priority transfers a piece without duplication')
end

-- A tunnel entrance cannot feed a diagonal neighbour. If its other parents
-- are blocked, that neighbour must spawn instead of waiting forever.
for _, side in ipairs{{-1,0}, {1,-1}} do
    local g=R.game_start(0,733)
    for i=0,R.CELLS-1 do
        g.active[i]=false;g.tiles[i]=R.tile(-1);g.chain[i]=0;g.ice[i]=0
        g.hazard[i]=0;g.stone_hp[i]=0;g.crate_hp[i]=0
    end
    local target,above,entrance,exit=cell(0,0),cell(0,-1),cell(side[1],side[2]),cell(0,1)
    g.active[target],g.active[above],g.active[entrance],g.active[exit]=true,true,true,true
    g.tiles[above],g.tiles[entrance],g.tiles[exit]=R.tile(2),R.tile(1,R.ROW),R.tile(3)
    g.chain[above]=1
    g.tunnel_to,g.tunnel_from={[entrance]=exit},{[exit]=entrance}
    g.delivery_exits={}
    local _,steps=R.game_collapse(g)
    check(steps[1].from[target]<0 and g.tiles[target].kind>=0,
        'isolated cell refills beside a redirected tunnel entrance')
    check(g.tiles[entrance].special==R.ROW, 'refill does not steal from the tunnel entrance')
    local _,idle=R.game_collapse(g)
    check(#idle==0, 'refilled tunnel neighbour remains settled')
end

do
    local g=R.game_start(0,456);local before=g.obstacles
    g.turn_pending,g.hazard_damaged=true,false
    check(R.game_end_turn(g) and g.obstacles==before+1, 'one hazard grows after undamaged turn')
    check(not R.game_end_turn(g) and g.obstacles==before+1, 'repeated settle does not grow twice')
    g.turn_pending,g.hazard_damaged=true,true
    check(not R.game_end_turn(g) and g.obstacles==before+1, 'damage suppresses growth for whole turn')
end

do
    local invalid=level();invalid.tunnels={{entrance=cell(0,2),exit=cell(0,-2)}}
    check(not pcall(function() rules(invalid).game_start(0,1) end), 'upward/cyclic tunnel is rejected')
    invalid=level();invalid.crates[1].cell=invalid.stones[1].cell
    check(not pcall(function() rules(invalid).game_start(0,1) end), 'overlapping solid elements are rejected')
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
print('match3 elements: blocker provenance, discoveries, tunnels, deliveries and hazard turns passed')
return 0
