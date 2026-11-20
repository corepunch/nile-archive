local E, H = require("match3"), require("support")
local t = H.suite("optional match-3 specials")
local function fixture(names)
    local R = E.new{special_rules=names}
    return R,H.board(R),R.new_match()
end
local function step(R, cell, axis, count)
    for _=1,count do cell=R.hex_neighbor(cell,axis) end
    return cell
end
local function run(R,g,cell,axis,length)
    for k=0,length-1 do g.tiles[step(R,cell,axis,k)]=R.tile(1) end
end
for _,name in ipairs{"striped","color_bomb"} do
    for axis=0,2 do
        for _,reverse in ipairs{false,true} do
            t:case(name .. " swap on axis " .. axis .. " reverse=" .. tostring(reverse),function()
                local R,g,m=fixture({name})
                local center=R.hex_center()
                local first=step(R,center,axis+3,2)
                local donor=R.hex_neighbor(center,(axis+1)%3)
                run(R,g,first,axis,name=="striped" and 4 or 5)
                g.tiles[center],g.tiles[donor]=R.tile(2),R.tile(1)
                local a,b=donor,center
                if reverse then a,b=b,a end
                t:check(R.game_swap_matches(g,a,b),"hint sees valid move")
                t:check(R.game_swap(g,a,b,m),"swap accepted")
                R.game_apply(g,m)
                t:check(g.tiles[center].special==name,"make special at matched swapped cell")
                local copy=R.game_copy(g)
                t:check(copy.tiles[center].special==name,"simulation preserves special")
                local to=R.hex_neighbor(center,axis)
                local target=R.hex_index(0,-3)
                if name=="striped" then target=step(R,to,axis,1) end
                g.tiles[to],g.tiles[target]=R.tile(2),R.tile(2)
                t:check(R.game_swap(g,center,to,m),"activate without a color match")
                t:check(m.mask[target] and m.special_effects[1].name==name,"effect hits target and emits event")
                R.game_apply(g,m)
                t:check(g.tiles[target].kind==-1 and g.tiles[to].kind==-1,"target and special are consumed")
            end)
        end
    end
end
for axis=0,2 do
    t:case("rhombus axis " .. axis,function()
        for _,enabled in ipairs{false,true} do
            local R,g,m=fixture(enabled and {"plane"} or {})
            local c=R.hex_center()
            local a,b=R.hex_neighbor(c,axis),R.hex_neighbor(c,axis+1)
            local d=R.hex_neighbor(a,axis+1)
            local donor=R.hex_neighbor(c,axis+3)
            for _,i in ipairs{a,b,d,donor} do g.tiles[i]=R.tile(1) end
            g.tiles[c]=R.tile(2)
            t:check(R.game_swap_matches(g,donor,c)==enabled,"hint agrees with enabled rule")
            t:check(R.game_swap(g,donor,c,m)==enabled,"rhombus only when enabled")
            if enabled then
                R.game_apply(g,m)
                t:check(g.tiles[c].special=="plane","plane created at swapped cell")
                local target=R.hex_index(0,-3)
                g.tiles[a],g.tiles[target]=R.tile(3),R.tile(2)
                g.oil[target],g.oil_left=1,1
                t:check(R.game_swap(g,c,a,m),"plane can be launched")
                t:check(m.special_effects[1].target==target,"plane seeks plaque")
                R.game_apply(g,m)
                t:check(g.oil_left==0,"plane clears plaque on impact")
            end
        end
    end)
end
t:case("T shape and bomb blast",function()
    local R,g,m=fixture({"t_bomb"})
    local c=R.hex_center()
    run(R,g,R.hex_neighbor(c,3),0,3)
    run(R,g,c,1,3)
    R.game_matches(g,m,c)
    t:check(m.hits==5,"T clears five distinct cells")
    R.game_apply(g,m)
    t:check(g.tiles[c].special=="t_bomb","T awards bomb")
    local a=R.hex_neighbor(c,0)
    local target=R.hex_neighbor(a,1)
    g.tiles[a],g.tiles[target]=R.tile(3),R.tile(2)
    t:check(R.game_swap(g,c,a,m),"activate bomb")
    t:check(m.mask[target] and m.special_effects[1].name=="t_bomb","bomb hits its neighbors")
end)
t:case("ordinary long lines by default",function()
    local R,g,m=fixture({})
    local c=R.hex_center()
    run(R,g,step(R,c,3,2),0,5)
    R.game_matches(g,m)
    t:check(m.hits==5 and m.special_awards==nil,"no implicit bonuses")
end)
t:case("two specials chained once each",function()
    local R,g,m=fixture({"striped","t_bomb"})
    local c=R.hex_center()
    local a=R.hex_neighbor(c,0)
    local b=R.hex_neighbor(a,0)
    local target=R.hex_neighbor(b,1)
    g.tiles[c],g.tiles[a]=R.tile(1,"striped",0),R.tile(2)
    g.tiles[b],g.tiles[target]=R.tile(2,"t_bomb"),R.tile(3)
    t:check(R.game_swap(g,c,a,m),"valid chained activation")
    t:check(m.mask[target] and #m.special_effects==2,"striped hit triggers bomb once")
    R.game_apply(g,m)
    t:check(g.tiles[target].kind==-1 and #m.special_effects==2,"application does not duplicate the chain")
end)
t:case("overlapping line and T prioritize color bomb",function()
    local R,g,m=fixture({"t_bomb","striped","color_bomb"})
    local c=R.hex_center()
    run(R,g,step(R,c,3,2),0,5)
    run(R,g,c,1,3)
    R.game_matches(g,m,c)
    t:check(m.hits==7,"crossing cells count only once")
    t:check(m.special_awards[c].name=="color_bomb" and next(m.special_awards,c)==nil,
        "priority yields one reward")
end)
check(t:finish()==0)
