-- The sixteen upgrades of docs/CAMPAIGN_DESIGN.md#upgrades, in either game: a
-- feat (real board events) brings the upgrade, who upgrades the building,
-- awards a trophy and gives one lasting perk (income in every win, or a tool
-- whose pieces charge one point more), with an arrival scene on the next
-- return to town. The game is the one this process runs (testing.game).
local rules=require("rules")
local economy=require("economy")
local island=require("island")
local journey=require("journey")
local R=require("state")
require("main")
local U=require("user_events_runtime")
local relic=testing.game=="relic-rush"

-- The design table: feat and perk by Rome 2 event, with Relic Rush / Christmas Market amounts.
-- {id, building (RR, CM), condition, {RR amount, CM amount}, perk resource or tool, {RR, CM} income}
local spec={
    {"man_03","well","arch","IF_PLAYER_GET_RESOURCE_IN_LEVEL","food",{245,240},{15,15}},
    {"man_04","log_cabin","reindeer_stable","IF_PLAYER_MAKE_MATCH","hammer",{5,5}},
    {"man_02","workshop","lumber","IF_PLAYER_GET_RESOURCE_IN_LEVEL","supplies",{520,395},{105,75}},
    {"man_01","camp","firework_stall","IF_PLAYER_MAKE_EFFECTIVE_MOVES_SERIES","bomb",{10,10}},
    {"man_05","market","bakery","IF_PLAYER_GET_RESOURCE_IN_LEVEL","food",{560,315},{95,50}},
    {"man_06","trading_post","chapel","IF_PLAYER_GET_RESOURCE_IN_LEVEL","supplies",{550,585},{110,115}},
    {"man_07","water_mill","cocoa","IF_PLAYER_GET_RESOURCE_IN_LEVEL","food",{625,400},{125,80}},
    {"man_08","clock_tower","igloo","IF_PLAYER_MAKE_MATCH_IN_LEVEL","shield",{5,5}},
    {"man_09","gateway","log_cabin","IF_PLAYER_GET_RESOURCE_IN_LEVEL","food",{850,575},{170,115}},
    {"man_10","amphitheater","toys","IF_PLAYER_GET_RESOURCE_IN_LEVEL","coins",{460,985},{90,195}},
    {"man_11","map_room","candles","IF_PLAYER_MAKE_MATCH_SERIES","lightning",{2,2}},
    {"man_12","lighthouse","post_office","IF_PLAYER_MAKE_MATCH_IN_TIME","plus",{15,15}},
    {"man_13","beached_ship","glassblower","IF_PLAYER_GET_RESOURCE_IN_LEVEL","coins",{690,1070},{140,210}},
    {"man_14","observatory","carousel","IF_PLAYER_COMPLETE_LEVELS_WITHOUT_LIFE_LOSS","mixer",{3,3}},
    {"man_15","museum","santa_workshop","IF_PLAYER_GET_RESOURCE_IN_LEVEL","coins",{990,1170},{200,235}},
    {"man_16","temple","tree","IF_PLAYER_MAKE_EFFECTIVE_MOVES_SERIES","star",{15,15}},
}
local pick=relic and 1 or 2
local SLOT={coins=1,food=2,supplies=3}

local saved_prog, saved_island, saved_quiet, saved_story = R.prog, R.island, R.quiet, R.story_current
local function fresh(read)
    R.prog={level=0,seed=1,wallet=purse(),story_seen={},bonus_charge={}}
    if read then for _,b in ipairs(journey.beats) do R.prog.story_seen[b.key]=true end end
    R.island=city.new();island.island_setup(R.island)
    R.toast=nil
end
local function breakdown(g)
    if relic then return rules.reward_breakdown(g,R.prog) end
    return rules.reward_breakdown(g,R.wonders or island.wonders,R.prog)
end
local function place(building)
    R.island:add(vec2(0,0),U.kinds[building],0)
    U.emit("island")
end
local function events_of(id) return U.by_id[id] end

-- The data is the design table: sixteen upgrades, each on its own building, with its feat and perk.
do
    local n=0
    for _,e in ipairs(U.events) do if e.upgrade then n=n+1 end end
    check(n==16,'sixteen upgrades')
    local cast={}
    for _,who in ipairs(R.cast) do cast[who.id]=who end
    for _,row in ipairs(spec) do
        local id,building=row[1],row[1+pick]
        local e=events_of(id)
        check(e and e.upgrade,id..' is an upgrade')
        if e and e.upgrade then
            check(e.upgrade.building==building,id..' stands at '..building)
            check(e.If[1]==row[4],id..' feat '..e.If[1])
            local perk=e.Then[3]
            if economy.bonuses[row[5]] then
                check(perk[1]=="THEN_GAME_CHARGE_TOOL" and perk.id==row[5] and perk.amount==1,id..' charges '..row[5])
                check(e.If.length==row[6][pick] or e.If.amount==row[6][pick],id..' feat size')
            else
                check(perk[1]=="THEN_PLAYER_ADD_RESOURCE_PER_LEVEL" and perk.id==row[5] and perk.amount==row[7][pick],id..' income')
                check(e.If.id==row[5] and e.If.amount==row[6][pick],id..' feat amount')
            end
            check(cast[e.upgrade.keeper] and cast[e.upgrade.keeper].role,id..' is kept by a cast member: '..tostring(e.upgrade.keeper))
            check(e.upgrade.title and #e.upgrade.title>3 and not cast[e.upgrade.title],id..' has a title')
            check(U.kinds[building] and island.buildings[U.kinds[building]+1].name,id..' building exists')
            check(economy.unlock_of(building),id..' building is on the purchase ladder')
            check(U.trophy_names[e.Then[1].id],id..' trophy is named')
            -- the building arms it
            local city=U.by_id["city_"..building]
            check(city and city.Then[1].id==id,id..' is armed by placing '..building)
            check(e.available==false,id..' waits for its building')
        end
    end
end

-- Every feat can be met on real board events, once its building stands, and the upgrade then
-- upgrades the building, awards the trophy and gives the perk.
for _,row in ipairs(spec) do
    local id,building=row[1],row[1+pick]
    fresh()
    local st=U.state()
    local e=events_of(id)
    local g=R.make_board(0,7)
    U.emit("wave",{g=g,runs={5},longest=5})
    check(not st.done[id],id..' waits for its building even when the feat happens')
    place(building)
    check(st.available[id] and not st.done[id],id..' is armed when '..building..' stands')
    local c=e.If
    local kind=c[1]
    local b=g.user_events
    if kind=="IF_PLAYER_GET_RESOURCE_IN_LEVEL" then
        g.earnings[SLOT[c.id]]=c.amount-1
        U.emit("wave",{g=g,runs={},longest=0})
        check(not st.done[id],id..' one short of its feat')
        g.earnings[SLOT[c.id]]=c.amount
        U.emit("wave",{g=g,runs={},longest=0})
    elseif kind=="IF_PLAYER_MAKE_MATCH" then
        U.emit("wave",{g=g,runs={c.length-1},longest=c.length-1})
        check(not st.done[id],id..' a shorter line is not the feat')
        U.emit("wave",{g=g,runs={c.length},longest=c.length})
    elseif kind=="IF_PLAYER_MAKE_EFFECTIVE_MOVES_SERIES" then
        for i=1,c.amount do
            check(not st.done[id],id..' move '..i..' of the series')
            U.emit("move",{g=g,waves=1,longest=3,effective=true})
        end
    elseif kind=="IF_PLAYER_MAKE_MATCH_IN_LEVEL" then
        for _=1,c.amount do
            check(not st.done[id],id..' still counting matches')
            U.emit("wave",{g=g,runs={c.min_length},longest=c.min_length})
        end
    elseif kind=="IF_PLAYER_MAKE_MATCH_SERIES" then
        U.emit("move",{g=g,waves=1,longest=c.min_length,effective=false})
        U.emit("move",{g=g,waves=1,longest=3,effective=false})   -- a short move breaks the run
        U.emit("move",{g=g,waves=1,longest=c.min_length,effective=false})
        check(not st.done[id],id..' the run was broken')
        U.emit("move",{g=g,waves=1,longest=c.min_length,effective=false})
    elseif kind=="IF_PLAYER_MAKE_MATCH_IN_TIME" then
        for i=1,c.amount do
            b.time=i*2   -- too slow: fifteen matches over thirty seconds
            U.emit("wave",{g=g,runs={3},longest=3})
        end
        check(not st.done[id],id..' matches spread too thin')
        b.time=100
        for _=1,c.amount do U.emit("wave",{g=g,runs={3},longest=3}) end
    elseif kind=="IF_PLAYER_COMPLETE_LEVELS_WITHOUT_LIFE_LOSS" then
        U.emit("won",{g=g});U.emit("won",{g=g})
        U.lost()
        U.emit("won",{g=g})
        check(not st.done[id],id..' a failed board ends the run')
        U.emit("won",{g=g});U.emit("won",{g=g})
    end
    check(st.done[id],id..' feat brings the upgrade')
    check(U.upgrades(building)==1,id..' upgrades '..building)
    local trophy=false
    for _,t in ipairs(U.trophies()) do if t.id=="TROPHY_"..id:sub(5) and t.name:find(e.upgrade.title,1,true) then trophy=true end end
    check(trophy,id..' awards its trophy')
    -- the perk
    local perk=e.Then[3]
    if perk[1]=="THEN_PLAYER_ADD_RESOURCE_PER_LEVEL" then
        local win=rules.game_start(0,3);win.won=true;win.moves=0;win.earnings={10,20,30}
        local reward=breakdown(win)
        local add=U.win_income()
        for slot=1,3 do
            check(add[slot]==(slot==SLOT[perk.id] and perk.amount or 0),id..' income slot '..slot)
            check(reward.total[slot]==win.earnings[slot]+reward.income[slot],id..' reward slot '..slot..' is matched plus income')
        end
        check(reward.income[SLOT[perk.id]]==perk.amount,id..' income is in the results breakdown')
    else
        local tool=economy.bonuses[perk.id].tool
        local extra=U.tool_charges()
        check(extra[tool]==1,id..' adds one point to tool slot '..tool)
    end
end

-- Meeting the feat arms nothing twice and an upgrade never leaves.
do
    fresh()
    local st=U.state()
    place(relic and "well" or "arch")
    local g=R.make_board(0,7)
    g.earnings[2]=1000
    U.emit("wave",{g=g,runs={},longest=0})
    check(st.done.man_03,'the first upgrade arrived')
    local before=U.win_income()[2]
    U.emit("wave",{g=g,runs={},longest=0})
    check(U.win_income()[2]==before and U.upgrades(relic and "well" or "arch")==1,'an upgrade arrives once')
end

-- Income lands in the wallet with the win, on first clears and replays alike.
do
    fresh()
    local building=relic and "well" or "arch"
    place(building)
    local g=R.make_board(0,7)
    g.earnings={0,relic and 245 or 240,0}
    U.emit("wave",{g=g,runs={},longest=0})
    check(U.state().done.man_03,'the well upgrade came on its Food feat in one level')
    g.won,g.moves=true,0
    local matched=purse(table.unpack(g.earnings))
    local wallet=R.prog.wallet
    local reward=breakdown(g)
    check(reward.total[2]==matched[2]+15,'a win pays the matched Food and the upgrade\'s fifteen')
    check(reward.total[1]==matched[1] and reward.total[3]==matched[3],'no other currency changes')
    local ok=relic and rules.progress_reward(R.prog,g) or rules.progress_reward(R.prog,g,island.wonders)
    check(ok and R.prog.wallet[2]==wallet[2]+matched[2]+15,'the wallet gains the income when the win is claimed')
    local replay=rules.game_start(0,9);replay.won=true;replay.moves=0;replay.earnings={0,0,0}
    check(breakdown(replay).total[2]==15,'a replay win still pays the income')
end

-- A tool upgrade makes the tool's pieces charge one point more per match (4, not 3).
do
    fresh()
    local building=relic and "log_cabin" or "reindeer_stable"
    place(building)
    local g=R.make_board(9,7)
    local kind,piece
    for k,p in pairs(g.resource_yields) do if p.tool then kind,piece=k,p end end
    check(piece and piece.key=="hammer" and piece.amount==3,'the Hammer piece charges three per match')
    local cell
    for i=0,rules.CELLS-1 do if rules.game_cell_active(g,i) and g.stone_hp[i]==0 and g.chain[i]==0 then cell=i;break end end
    local function match_one()
        local before=g.tool_meter[piece.tool]
        g.tiles[cell]=rules.tile(kind)
        local m=rules.new_match()
        m.mask[cell]=true;m.ordinary[cell]=true
        rules.game_apply(g,m)
        return g.tool_meter[piece.tool]-before
    end
    check(match_one()==3,'before the upgrade a Hammer piece charges 3')
    local board=R.g
    R.g=g   -- the running board, as in the game
    U.emit("wave",{g=g,runs={5},longest=5})
    R.g=board
    check(U.state().done.man_04 and g.yield_amounts and g.yield_amounts[kind]==4,'the cabin upgrade came: the current board pays 4')
    check(match_one()==4,'after the upgrade a Hammer piece charges 4')
    check(g.resource_yields[kind]==piece and piece.amount==3,'the economy\'s own piece is untouched')
    local fresh_board=R.make_board(9,8)
    check(fresh_board.yield_amounts and fresh_board.yield_amounts[kind]==4,'later boards start with the faster charge')
    -- the other piece of the slot (Bomb) charges faster too, and a second upgrade of the slot stacks
    check(U.tool_charges()[economy.bonuses.bomb.tool]==1,'the Bomb replaces the Hammer in the same slot and keeps the bonus')
end

-- The arrival scene plays on the next return to town and never blocks progress.
do
    fresh(true)   -- the level story is read: only the upgrades' scenes are due
    R.quiet=false
    R.overlay=R.OV_NONE
    R.story_current,R.story_preview=nil,false
    local building=relic and "well" or "arch"
    local who=U.by_id.man_03.upgrade.keeper
    local beat={key="upgrade-man_03",phase="upgrade",event="man_03",building="x",
        lines={{who,"Water for everyone!"},{relic and "mara" or "noelle","Thank you."}}}
    -- set the authored scene aside to see the fallback, then use a known one
    local authored={}
    for i=#journey.upgrades,1,-1 do
        if journey.upgrades[i].event=="man_03" then table.insert(authored,table.remove(journey.upgrades,i)) end
    end
    check(not journey.find_upgrade("man_03"),'the scene is set aside')
    -- without a scene the arrival is a toast
    place(building)
    local g=R.make_board(0,7)
    g.earnings[2]=500
    U.emit("wave",{g=g,runs={},longest=0})
    check(R.toast and R.toast:find(U.by_id.man_03.upgrade.title,1,true),'no scene: a toast names the upgrade')
    -- with one, the scene waits for the town
    fresh(true);R.toast=nil
    table.insert(journey.upgrades,beat)
    place(building)
    check(journey.next_upgrade(R.prog,R.upgrade_done)==nil,'no scene before the arrival')
    g=R.make_board(0,7)
    g.earnings[2]=500
    U.emit("wave",{g=g,runs={},longest=0})
    check(R.toast==nil,'a scene replaces the toast')
    check(journey.next_upgrade(R.prog,R.upgrade_done)==beat,'the scene is due once the upgrade is here')
    R.on_island=false
    R.story_tick()
    check(R.story_current==nil,'the scene waits for the town, not the board')
    R.on_island=true
    R.story_tick()
    check(R.story_current==beat and story.active(),'the arrival scene plays on the return to town')
    while story.active() do story.next() end
    R.story_tick()
    check(R.prog.story_seen[beat.key] and not R.story_current,'the scene is acknowledged and saved')
    R.story_tick()
    check(R.story_current==nil,'a seen scene does not repeat')
    -- seen state persists
    check(save.write("upgrade-test",journey.serialize and function(s) journey.serialize(s,R.prog) end),'write the seen scene')
    R.prog.story_seen={}
    check(save.read("upgrade-test",function(s) journey.serialize(s,R.prog) end),'read the seen scene')
    check(R.prog.story_seen[beat.key],'a seen upgrade scene is remembered')
    -- an unseen level beat plays first: an upgrade never holds the story back
    R.prog.story_seen[beat.key]=nil
    R.prog.story_seen[journey.beats[1].key]=nil
    R.prog.level=5
    R.story_tick()
    check(R.story_current and R.story_current.phase~="upgrade",'level beats stay ahead of upgrade scenes')
    while story.active() do story.next() end
    R.story_current=nil
    table.remove(journey.upgrades)
    for _,b in ipairs(authored) do table.insert(journey.upgrades,b) end
    check(#authored==0 or journey.find_upgrade("man_03"),'the authored scene is back')
    R.on_island=false
end

-- The card names the upgrade and perk, or the feat while the upgrade is still to come.
do
    fresh()
    local building=relic and "well" or "arch"
    local kind=U.kinds[building]
    check(U.card(kind)==nil,'no upgrade before the building stands')
    place(building)
    local card=U.card(kind)
    check(card and card.caption=="FEAT" and card.about:find(U.by_id.man_03.upgrade.title,1,true),'armed: the card names the upgrade and the feat')
    check(#card.entries==1 and card.entries[1].amount==(relic and 245 or 240),'the feat\'s amount is a resource indicator, not text')
    check(not card.about:find(relic and "245" or "240",1,true),'no resource amount is written into the sentence')
    local g=R.make_board(0,7)
    g.earnings[2]=500
    U.emit("wave",{g=g,runs={},longest=0})
    card=U.card(kind)
    check(card and card.caption=="EVERY WIN" and card.entries[1].amount=="+15" and card.short:find("Upgraded: ",1,true),
        'arrived: the card shows the perk as an indicator and the tap line names the upgrade')
    local buildings=R.buildings
    R.buildings=buildings or island.buildings
    for index,item in ipairs(R.island.items) do
        if item.type==kind then
            check(R.building_words(index-1):find("Upgraded: ",1,true),'the tap line names the upgrade')
            break
        end
    end
    R.buildings=buildings
    local tool_building=relic and "log_cabin" or "reindeer_stable"
    place(tool_building)
    U.emit("wave",{g=g,runs={5},longest=5})
    card=U.card(U.kinds[tool_building])
    check(card.caption=="TOOL" and card.about:find("charges faster",1,true) and #card.entries==1,'a tool perk names the tool')
end

-- Progress survives a save; the perks are derived from it.
do
    fresh()
    local building=relic and "well" or "arch"
    place(building)
    local g=R.make_board(0,7)
    g.earnings[2]=500
    U.emit("wave",{g=g,runs={},longest=0})
    check(save.write("upgrades-test",U.serialize),'write upgrades')
    fresh()
    check(not U.state().done.man_03 and U.win_income()[2]==0,'a fresh profile has no upgrades')
    check(save.read("upgrades-test",U.serialize),'read upgrades')
    check(U.state().done.man_03 and U.win_income()[2]==15 and U.upgrades(building)==1,'an upgrade and their perk come back')
end

R.prog, R.island, R.quiet, R.story_current = saved_prog, saved_island, saved_quiet, saved_story
R.on_island=false
