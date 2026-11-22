-- Relic Rush's user_events.lua: Cradle of Rome's If/Then events, tutorials and upgrades.
local rules=require("rules")
local economy=require("economy")
local island=require("island")
local R=require("state")
require("main")
local U=require("user_events_runtime")

-- Every event names known conditions, effects, events, buildings, pieces and resources.
do
    local pieces={coins=true,food=true,supplies=true,score=true}
    local keys={}
    for _,p in pairs(economy.pieces) do keys[p.key]=true end
    for _,u in ipairs(economy.unlocks) do if u.key then keys[u.key]=true end end
    for key in pairs(economy.bonuses) do keys[key]=true end
    local ok=true
    for _,e in ipairs(U.events) do
        local c=e.If
        if not U.IF[c[1]] then ok=false;print("unknown condition",e.id,c[1]) end
        if c[1]=="IF_PLAYER_BUILT_CONSTRUCTION" and not U.kinds[c.id] then ok=false;print("unknown building",e.id,c.id) end
        if (c[1]=="IF_PLAYER_GET_RESOURCE" or c[1]=="IF_PLAYER_GET_RESOURCE_IN_LEVEL") and not pieces[c.id] then ok=false;print("unknown resource",e.id) end
        if (c[1]=="IF_GAME_BALL_APPEAR" or c[1]=="IF_GAME_BONUS_READY") and not keys[c.id] then ok=false;print("unknown piece",e.id,c.id) end
        for _,t in ipairs(e.Then) do
            if not U.THEN[t[1]] then ok=false;print("unknown effect",e.id,t[1]) end
            if t[1]=="THEN_USER_EVENT_AVAILABLE" then
                for id in t.id:gmatch("%S+") do if not U.by_id[id] then ok=false;print("unknown event",e.id,id) end end
            end
            if t[1]=="THEN_CITY_UPGRADE_BUILDING" and not U.kinds[t.id] then ok=false;print("unknown building",e.id,t.id) end
            if t[1]=="THEN_GAME_CHANGE_CHIP_WEIGHT" and not keys[t.id] then ok=false;print("unknown piece",e.id,t.id) end
            if t[1]=="THEN_GAME_CHARGE_TOOL" and not economy.bonuses[t.id] then ok=false;print("unknown tool",e.id,t.id) end
            if (t[1]=="THEN_PLAYER_ADD_RESOURCE" or t[1]=="THEN_PLAYER_ADD_RESOURCE_PER_LEVEL") and not pieces[t.id] then ok=false;print("unknown resource",e.id) end
            if t[1]=="THEN_PLAYER_ADD_TROPHY" and not U.trophy_names[t.id] then ok=false;print("unnamed trophy",e.id,t.id) end
        end
    end
    check(ok,'user events reference only known types, events, buildings, pieces and resources')
    local reached={}
    for _,e in ipairs(U.events) do
        for _,t in ipairs(e.Then) do
            if t[1]=="THEN_USER_EVENT_AVAILABLE" and t.available~=false then
                for id in t.id:gmatch("%S+") do reached[id]=true end
            end
        end
    end
    local stranded=nil
    for _,e in ipairs(U.events) do if e.available==false and not reached[e.id] then stranded=e.id end end
    check(not stranded,'every event that starts off is switched on by another: '..tostring(stranded))
end

local saved_prog, saved_island = R.prog, R.island
R.prog={level=0,seed=1,wallet=purse(),story_seen={},bonus_charge={}}
R.island=city.new();island.island_setup(R.island)

-- The move hint shows until the first line of four, which opens the next tutorials.
do
    local g=R.make_board(0,7)
    local st=U.state()
    U.emit("hint",{g=g}) -- the board counts hints itself; emit sees the count it keeps
    check(not st.done.hint_01_1,'the first hint waits for the board to count a suggestion')
    g.user_events.hints=1;U.emit("hint",{g=g})
    check(st.done.hint_01_1 and not st.done.hint_01_2,'the first suggestion shows the first move hint only')
    U.emit("wave",{g=g,runs={4},longest=4})
    check(st.done.hint_01_close and not st.available.hint_01_2 and st.available.hint_02_1,
        'a first line of four retires the move hints and opens the plaque hint')
    g.user_events.hints=2;U.emit("hint",{g=g})
    check(not st.done.hint_01_2,'a retired hint no longer shows')
end

-- An upgrade is armed once its building stands (tests/lua/upgrades.lua covers all sixteen).
do
    local st=U.state()
    U.emit("island")
    check(not st.available.man_03,'the well upgrade waits for the well')
    R.island:add(vec2(0,0),U.kinds.well,0)
    U.emit("island")
    check(st.done.city_well and st.available.man_03,'placing the well arms its upgrade')
    local g=R.make_board(11,7)
    g.earnings[economy.PROVISIONS]=244
    U.emit("wave",{g=g,runs={4},longest=4})
    check(not st.done.man_03,'244 Food is not the feat')
    g.earnings[economy.PROVISIONS]=245
    U.emit("wave",{g=g,runs={4},longest=4})
    check(st.done.man_03 and U.upgrades("well")==1,'245 Food in one level upgrades the well')
    g.won,g.moves=true,0
    local reward=rules.reward_breakdown(g,R.prog)
    check(reward.total[economy.PROVISIONS]==260 and reward.total[economy.SUPPLIES]==0,'the well upgrade adds fifteen Food to a win and no Supplies')
    local found=false
    for _,t in ipairs(U.trophies()) do if t.id=="TROPHY_03" then found=t.name:find("a second rope",1,true)~=nil end end
    check(found,'the well upgrade is a named trophy')
end

-- A chip weight changes what a piece pays while clearing, without replacing the economy's tables.
do
    local st=U.state()
    local g={resource_yields={[2]=economy.bonuses.hammer,[0]=economy.pieces[0]}}
    U.apply_weights(g)
    check(g.yield_amounts==nil,'no upgrade, no weights')
    st.done.man_02=true
    U.apply_weights(g)
    check(g.yield_amounts==nil,'an income upgrade leaves the thirty-piece Hammer charge alone')
    local board=R.make_board(1,7)
    local kind,piece=next(board.resource_yields)
    board.yield_amounts={[kind]=piece.amount+1}
    rules.game_apply(board,rules.new_match())
    check(board.resource_yields[kind]==piece,'clearing restores the economy piece after a weighted wave')
    st.done.man_02=nil
end

-- Lines are read from the matched cells before they clear.
do
    local g=R.make_board(0,7)
    local m=rules.new_match()
    local c=rules.hex_neighbor(rules.hex_neighbor(rules.hex_center(),3),3)
    for _=1,5 do g.tiles[c]=rules.tile(0);m.ordinary[c]=true;c=rules.hex_neighbor(c,0) end
    local runs=U.runs_of(g,m)
    check(#runs==1 and runs[1]==5,'five matched cells in a row read as one line of five')
end

-- Progress survives a save; lasting effects are derived from it.
do
    check(save.write("user-events-test",U.serialize),'write user events')
    R.prog={level=0,seed=1,wallet=purse(),story_seen={},bonus_charge={}}
    check(not U.state().done.man_03,'a fresh profile starts with no upgrades')
    check(save.read("user-events-test",U.serialize),'read user events')
    local st=U.state()
    check(st.done.man_03 and st.done.hint_01_close and not st.available.hint_01_2 and U.win_income()[economy.PROVISIONS]==15,
        'done and switched-off events come back with their income')
end

R.prog, R.island = saved_prog, saved_island
