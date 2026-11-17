local journey=require('journey')
local rules=require('rules')
local island=require('island')
local quests=require('quests')
local R=require('state')
require('main')
local function empty_queue() while story.active() do story.next() end end
local function owned(c) return function(kind) return island.owned(c,kind)>0 end end

-- A plaque is fixed to a cell. Nearby clears and blocker damage leave it in place.
-- Board 6 first puts chains over plaques.
local function plaques_of(g)
    local locked, plain
    for i=0,rules.CELLS-1 do
        if g.oil[i]==1 and g.ice[i]==0 then
            if g.chain[i]>0 and not locked then locked=i elseif g.chain[i]==0 and not plain then plain=i end
        end
    end
    return locked, plain
end
do
    local g=rules.game_start(5,123)
    local a,b=plaques_of(g)
    local initial=g.oil_left
    check(a and b and initial==#rules.levels[6].oil, 'blue plaques are authored under both locked and ordinary pieces')
    local m=rules.new_match()
    m.mask[a]=true
    g.chain[a]=1
    rules.game_apply(g,m)
    check(g.oil_left==initial and g.chain[a]==0, 'the first hit removes the lock')
    rules.game_apply(g,m)
    check(g.oil[a]==0 and g.oil[b]==1 and g.oil_left==initial-1, 'a direct clear removes only the plaque it reaches')
end

-- A double tablet takes two hits and counts once toward the goal.
do
    local _,b=plaques_of(rules.game_start(5,123))
    local level=rules.levels[6]
    local saved=level.oil_double
    level.oil_double={b}
    local g=rules.game_start(5,123)
    level.oil_double=saved
    local initial=g.oil_left
    check(g.oil[b]==2 and initial==#level.oil, 'oil_double starts a plaque at two layers without adding a goal')
    local m=rules.new_match()
    m.mask[b]=true
    rules.game_apply(g,m)
    check(g.oil[b]==1 and g.oil_left==initial, 'the first hit leaves a single tablet')
    rules.game_apply(g,m)
    check(g.oil[b]==0 and g.oil_left==initial-1, 'the second hit clears it')
end

-- The bonus-area preview names exactly the cells a tool would hit, without using it.
do
    local hammer=rules.game_start(5,123,{camp=true})
    local g=rules.game_start(5,123,{camp=true,log_cabin=true})
    local _,b=plaques_of(g)
    hammer.tools[1], g.tools[1] = 1, 1
    local single, area=rules.game_tool_area(hammer,0,b), rules.game_tool_area(g,0,b)
    local n=0
    for i in pairs(area) do
        n=n+1
        check(rules.hex_distance(i,b)<=1 and rules.game_cell_active(g,i), 'dynamite area stays within one step on the board')
    end
    check(single[b] and next(single,b)==nil and next(single)==b, 'the pickaxe area is its own cell')
    check(n>1 and g.tools[1]==1, 'previewing does not spend a charge')
    g.tools[1]=0
    check(rules.game_tool_area(g,0,b)==nil, 'no area without a charge')
end

local collections = {
    [1]={"Camp timber",3}, [2]={"Lamp lens",3}, [3]={"Relay cable",4},
    [4]={"Tide chart",0}, [5]={"Quay marker",2}, [6]={"Shore marker",2},
    [7]={"Tool roll",1}, [8]={"Relay pliers",2}, [9]={"Supply crate",3}, [10]={"Shutter gear",2},
    [13]={"Folded note",0},
}

-- Story pieces occupy one palette slot and remain distinct through refills.
for board, spec in pairs(collections) do
    local _, target, omitted = table.unpack(spec)
    local expected_count = 5   -- every board spawns all five kinds
    local g = rules.game_start(board-1,123)
    R.g = g
    local kinds, free = {}, {}
    for i=0,rules.CELLS-1 do
        if g.active[i] and g.tiles[i].kind>=0 then
            kinds[g.tiles[i].kind] = true
            if g.chain[i]==0 and g.ice[i]==0 then free[#free+1] = i end
        end
    end
    local count = 0
    for _ in pairs(kinds) do count = count+1 end
    -- An authored opening may show fewer kinds; refills bring the rest.
    check((count==expected_count or rules.levels[board].opening) and kinds[target] and not kinds[omitted],
        'opening uses the configured palette including the story piece')
    local a,b=free[1],free[2]
    local regular=target~=rules.RELIC_IDOL and omitted~=rules.RELIC_IDOL and rules.RELIC_IDOL or rules.RELIC_FLAME
    g.tiles[a],g.tiles[b]=rules.tile(target),rules.tile(regular)
    local m=rules.new_match()
    m.mask[a],m.mask[b]=true,true
    rules.game_apply(g,m)
    check(g.relics==1 and g.tiles[a].kind<0, 'the quest piece matches like an ordinary piece')
    if board==1 then check(g.earnings[3]==2,'ordinary camp timber earns two Supplies') end
    rules.game_collapse(g)
    for i=0,rules.CELLS-1 do
        local kind=g.tiles[i].kind
        check(kind>=-1 and kind<rules.COLORS and kind~=omitted, 'refill stays within the configured palette')
    end
end

-- Follow the actual rewards, purchase gate and scheduler through all 30 clears.
local p={level=0,seed=1,wallet=purse(),story_seen={}}
local c=city.new();island.island_setup(c)
check(rules.LEVELS==100 and #journey.beats==47,'all chapters and their restoration scenes are playable')
for _,b in ipairs(journey.beats) do
    check(#b.lines<=48,'each beat fits the engine queue')
    for _,line in ipairs(b.lines) do
        check(({elena=true,mara=true,tomas=true,adrian=true,kessler=true,ines=true})[line[1]],'every line has a real cast member')
    end
end
for level=1,30 do
    local quest, task=quests.current(p,c)
    check(quest and task.board==level and quests.points(c)>=quests.required_points(level),
        'each actual board has a funded quest and its own task')
    local before=journey.next(p,owned(c),level-1)
    if before then
        check(before.phase=='before' and before.level==level,'opening comes before its excavation')
        p.story_seen[before.key]=true
    end
    local g=rules.game_start(level-1,level);g.won=true;g.moves=0
    local specs=rules.level_of(g)
    local layers=0
    for _,e in ipairs(specs.chain_cells) do layers=layers+e.hits end
    for _,e in ipairs(specs.ice_cells) do layers=layers+e.layers end
    check(g.initial_obstacles==layers+#specs.stones,
        'Relic Rush expeditions place exactly their authored blockers')
    check(#specs.goals==1 and specs.goals[1]=='oil',
        'fixed blue plaques are the only win condition')
    check(g.oil_left>0 and g.oil_left==#specs.oil, 'each authored plaque is present on an active cell')
    for _, i in ipairs(specs.oil) do
        check(g.active[i] and g.stone_hp[i]==0, 'plaque is visible on a playable cell')
    end
    if specs.signal_cell then
        check(g.oil[specs.signal_cell]>=1, 'the signal plate appears on the cleared final site')
    end
    rules.game_check_end(g)
    check(not g.won, 'a board cannot win before its plaques are cleared')
    if collections[level] then
        check(R.award_for(g).name==collections[level][1], 'the story object remains the first-clear reward')
    end
    for _, i in ipairs(specs.oil) do g.oil[i]=0 end
    g.oil_left=0
    rules.game_check_end(g)
    check(g.won and g.score==0 and g.relics==0, 'clearing all plaques wins without a score or item quota')
    g.moves=0
    local reveal=journey.result_beat(p,g)
    check(level==10 and reveal==nil or reveal and reveal.level==level,
        'the first-clear exchange precedes results except the town choice')
    if level==13 then
        check(reveal.lines[1][2]:find('I. R.',1,true), 'Elena reads the initials before the courtyard is built')
        check(journey.find('restore-13').lines[1][2]:find('Ines Reed',1,true),
            'Tomas names the sender at the courtyard')
    end
    local kind=journey.wonder_at(level)
    -- This test skips matches to isolate the story, so supply the board income
    -- for every ladder restoration this clear opens.
    local opened, income = {}, purse()
    for _, step in ipairs(island.ladder) do
        if step.after==level then
            opened[#opened+1]=step
            income=income+island.buildings[step.kind+1].cost
        end
    end
    g.earnings={income[1],income[2],income[3]}
    check(rules.progress_reward(p,g,island.wonders),'first clear advances the campaign')
    local after=journey.next(p,owned(c),nil)
    check(after and after.key==('after-%02d'):format(level),'every first clear has a story beat')
    check(journey.awaiting_return(p),'unread result blocks the next new expedition')
    p.story_seen[after.key]=true
    for z=1,5 do c:unlock(z,p.wallet) end
    for _, step in ipairs(opened) do
        local _, next_task=quests.current(p,c)
        check(next_task and next_task.kind==step.kind,'the funded restoration is the next quest task')
        check(island.next_step(c,p.level)==step.kind,'restorations open in ladder order')
        if step.story then
            check(not journey.next(p,owned(c),nil),'restoration story waits for confirmed construction')
            local reserve,cost=island.reserved_cost(c,p.level),island.buildings[step.kind+1].cost
            check(reserve:covers(cost) and cost:covers(reserve),'reserve covers all costs of the earned building')
        end
        check(island.can_buy(c,p.wallet,p.level,step.kind),'earned restoration is affordable')
        check(island.island_place_next(c,p.wallet,p.level,0),'scheduled building fits open land')
    end
    check(not island.island_place_next(c,p.wallet,p.level,0),'a clear opens only its own restorations')
    if kind then
        local placed=journey.next(p,owned(c),nil)
        check(placed and placed.key==('restore-%02d'):format(level),'confirmed placement releases its scene')
        p.story_seen[placed.key]=true
    end
    local replay=rules.game_start(level-1,100+level);replay.won=true;replay.moves=0
    local stars=p.wallet[4]
    check(rules.progress_reward(p,replay,island.wonders) and p.wallet[4]==stars,'replay gives no story progress or stars')
    check(not journey.next(p,owned(c),nil),'replay cannot repeat a completed beat')
end
check(c.count==20 and c.open==63 and p.wallet[4]==30 and quests.points(c)==80,
    'thirty clears restore twenty buildings, fund every region and award 80 points')
check(not quests.current(p,c),'all nine quests finish')
check(journey.next(p,owned(c),30)==nil,'finale ends at thirty, not the tenth wonder')

-- Real queue completion, interruption and save/read use the runtime coordinator.
R.test_mode=true;R.quiet=false;R.overlay=R.OV_NONE;R.on_island=false
R.island=c;R.g=rules.game_start(0,1)
R.prog={level=0,story_seen={}}
empty_queue();R.story_current=nil
R.story_tick()
check(story.active() and R.story_current.key=='before-01','new game opens with Mara’s signal')
story.next()
check(not R.prog.story_seen['before-01'],'a partially read beat is not acknowledged')
save.write('story-interrupted',function(s) journey.serialize(s,R.prog) end)
empty_queue();R.story_current=nil;R.prog={level=0,story_seen={}}
save.read('story-interrupted',function(s) journey.serialize(s,R.prog) end)
R.story_tick()
check(story.active() and R.story_current.key=='before-01','reload recovers the interrupted scene')
empty_queue();R.story_tick()
check(R.prog.story_seen['before-01'] and not story.active(),'finishing or skipping acknowledges exactly one scene')
save.write('story-completed',function(s) journey.serialize(s,R.prog) end)
R.prog={level=0,story_seen={}}
save.read('story-completed',function(s) journey.serialize(s,R.prog) end)
check(R.prog.story_seen['before-01'],'completed keys survive save/read')

-- A legacy player keeps all ten purchased wonders and starts episode two.
local old={level=10,seed=55,wallet=purse(1234,12,34,30,7)}
journey.migrate(old,3)
check(old.level==10 and old.wallet[1]==1234 and old.wallet[4]==30 and old.story_recap,'migration preserves the wallet and offers a recap')
check(journey.next(old,owned(c),10).key=='before-11','old completion opens the new episode without replaying episode one')
old.level=13;old.story_seen['before-11']=true
old.story_seen['after-11'],old.story_seen['after-12']=true,true
old.story_seen['after-13']=true
check(journey.next(old,owned(c),nil).key=='restore-13','an already-owned later wonder satisfies its story gate')
local preserved=city.new();island.island_setup(preserved);preserved.open=63
preserved:add(c.items[10].pos,9,0)
island.restore_saved(preserved,10)
check(island.owned(preserved,9)==1,'migration never deletes the legacy temple')
check(journey.building_about(9,29,'ordinary')~=journey.building_about(9,30,'ordinary'),'the island responds to the restored warning')

-- Save a branch selection before its reply finishes. Reload must replay the
-- selected reply, then acknowledge the reveal once and unlock chapter two.
local reveal=journey.find('after-10')
local selected={level=10,story_seen={},story_choices={['after-10']=2}}
for _, b in ipairs(journey.beats) do if b.level<10 or b.phase=='before' and b.level==10 then selected.story_seen[b.key]=true end end
save.write('story-choice',function(s) journey.serialize(s,selected) end)
R.prog={level=10,story_seen={}}
save.read('story-choice',function(s) journey.serialize(s,R.prog) end)
R.on_island=true;R.overlay=R.OV_NONE;R.story_current=nil
R.story_tick()
check(R.story_current and R.story_current.lines==reveal.choices[2].lines,'reload resumes Tomas’s chosen reply')
empty_queue();R.story_tick()
check(R.prog.story_seen['after-10'] and journey.next(R.prog,owned(c),10).key=='before-11',
    'finishing the reply unlocks chapter two')
empty_queue()

-- The final plaque reveals the signal plate and plays the landing scene
-- before the first-clear dialogue.
R.g=rules.game_start(29,1)
R.prog={level=29,story_seen={}}
R.on_island,R.overlay=false,R.OV_RESULT
local g=R.g
local level=rules.level_of(g)
local signal=level.signal_cell
for _, i in ipairs(level.oil) do
    if i~=signal then g.oil[i]=0 end
end
g.oil_left=1
local m=rules.new_match()
m.mask[signal]=true
for _=1,g.chain[signal]+g.ice[signal]+g.oil[signal] do rules.game_apply(g,m) end
rules.game_check_end(g)
check(g.won and g.oil[signal]==0 and g.obstacles>0,'the final plaque wins even while ordinary blockers remain')
R.story_tick()
local scene=R.clear_scene()
check(scene and scene.cell==signal and not story.active(),'the recovered plate runs the landing scene before dialogue')
R.now=R.now+5
R.story_tick()
check(R.story_current and R.story_current.key=='after-30','the landing scene hands off to the finale dialogue')
empty_queue(); R.story_tick()
R.g=rules.game_start(29,2)
R.g.won=true
R.prog.level=30
check(not R.clear_scene(),'a replay cannot run the landing scene again')
