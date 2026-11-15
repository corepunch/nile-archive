local journey=require('journey')
local rules=require('rules')
local island=require('island')
local quests=require('quests')
local R=require('state')
require('main')
local function empty_queue() while story.active() do story.next() end end
local function owned(c) return function(kind) return island.owned(c,kind)>0 end end

local collections = {
    [1]={10,"Camp timber",5,0}, [2]={10,"Lamp lens",3,5}, [3]={12,"Relay cable",4},
    [4]={15,"Tide chart",0}, [5]={14,"Quay marker",2,5}, [6]={14,"Shore marker",2},
    [7]={16,"Tool roll",1}, [8]={16,"Broken cable",4,5}, [9]={18,"Supply crate",3}, [10]={20,"Shutter gear",5,0},
    [13]={14,"Folded note",0,5},
}

-- Story pieces occupy one palette slot and advance its matching goal.
for board, spec in pairs(collections) do
    local _, _, target, omitted = table.unpack(spec)
    local expected_count = omitted~=nil and 5 or 6
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
    check(count==expected_count and kinds[target] and not kinds[omitted],
        'opening uses the configured palette including the story piece')
    for _, entry in ipairs(R.goal_entries()) do
        if entry.id=='idols' then check(entry.kind==target, 'the HUD tracks the story kind') end
    end
    local a,b=free[1],free[2]
    local regular=target~=rules.RELIC_IDOL and omitted~=rules.RELIC_IDOL and rules.RELIC_IDOL or rules.RELIC_FLAME
    g.tiles[a],g.tiles[b]=rules.tile(target),rules.tile(regular)
    local m=rules.new_match()
    m.mask[a],m.mask[b]=true,true
    rules.game_apply(g,m)
    check(g.relics==1, 'only the story piece advances collection')
    rules.game_collapse(g)
    for i=0,rules.CELLS-1 do
        local kind=g.tiles[i].kind
        check(kind==-1 or kinds[kind], 'refill stays within the configured palette')
    end
end

-- Follow the actual rewards, purchase gate and scheduler through all 30 clears.
local p={level=0,seed=1,wallet=purse(),story_seen={}}
local c=city.new();island.island_setup(c)
check(rules.LEVELS==30 and #journey.beats==47,'all chapters and their restoration scenes are playable')
check(journey.find('before-22').lines[1][2]:find('Ice',1,true),'the Frozen Stair introduces ice before play')
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
    if level<=10 or level==13 then
        check(rules.level_of(g).quest_object, 'first-clear story retains its quest object')
    end
    g.score,g.relics,g.obstacles=0,0,0
    rules.game_check_end(g)
    check(not g.won, 'ordinary match-3 goals must be met')
    if collections[level] then
        local spec=rules.level_of(g)
        local target, reward=table.unpack(collections[level])
        g.relics,g.carpeted=target-1,g.carpet_total
        rules.game_check_end(g)
        check(spec.relics==target and not g.won and g.oil_left==0 and not spec.reveal,
            'the story piece collection is required after the other goals are met')
        check(R.award_for(g).name==reward, 'the assembled object is the first-clear reward')
    end
    g.score,g.relics=99999,999
    g.delivered,g.carpeted,g.oil_left=g.delivery_total,g.carpet_total,0
    rules.game_check_end(g)
    check(g.won, 'completing the match-3 goals wins')
    g.moves=0
    local reveal=journey.result_beat(p,g)
    check(level==10 and reveal==nil or reveal and reveal.level==level,
        'the first-clear exchange precedes results except the town choice')
    if level==13 then
        check(reveal.lines[1][2]:find('I. R.',1,true), 'Elena reads the initials before the courtyard is built')
        check(journey.find('restore-13').lines[1][2]:find('Ines Reed',1,true),
            'Tomas names the sender at the courtyard')
    end
    check(rules.progress_reward(p,g,island.wonders),'first clear advances the campaign')
    local after=journey.next(p,owned(c),nil)
    check(after and after.key==('after-%02d'):format(level),'every first clear has a story beat')
    check(journey.awaiting_return(p),'unread result blocks the next new expedition')
    p.story_seen[after.key]=true
    local kind=journey.wonder_at(level)
    if kind then
        local _, next_task=quests.current(p,c)
        check(next_task and next_task.kind==kind-1,'the funded upgrade is the next quest task')
        check(not journey.next(p,owned(c),nil),'restoration story waits for confirmed construction')
        check(island.can_buy(c,p.wallet,p.level,kind-1),'earned restoration is affordable')
        check(island.reserved_gold(c,p.level)==island.wonders[kind].cost[1],'reserve covers the earned building')
        for z=1,5 do c:unlock(z,p.wallet) end
        check(island.island_place_next(c,p.wallet,p.level,0),'scheduled building fits open land')
        local placed=journey.next(p,owned(c),nil)
        check(placed and placed.key==('restore-%02d'):format(level),'confirmed placement releases its scene')
        p.story_seen[placed.key]=true
    else
        check(not island.island_place_next(c,p.wallet,p.level,0),'ordinary clue creates no extra building')
    end
    local replay=rules.game_start(level-1,100+level);replay.won=true;replay.moves=0
    local stars=p.wallet[4]
    check(rules.progress_reward(p,replay,island.wonders) and p.wallet[4]==stars,'replay gives no story progress or stars')
    check(not journey.next(p,owned(c),nil),'replay cannot repeat a completed beat')
end
check(c.count==10 and c.open==63 and p.wallet[4]==90 and quests.points(c)==40,
    'thirty clears restore ten wonders, fund every region and award 40 points')
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

-- Land the physical token using the ordinary gravity and exit rules. A plate
-- alone is insufficient, and the finale precedes the first-clear dialogue.
R.g=rules.game_start(29,1)
R.prog={level=29,story_seen={}}
R.on_island,R.overlay=false,R.OV_RESULT
local g=R.g
local delivery=rules.level_of(g).deliveries
local exit, cell=delivery.exits[1], rules.hex_neighbor(delivery.tokens[1],1)
while cell >= 0 do
    g.tiles[cell],g.chain[cell],g.ice[cell]=rules.tile(-1),0,0
    rules.game_collapse(g)
    if cell==exit then break end
    cell=rules.hex_neighbor(cell,1)
end
rules.game_check_end(g)
check(g.delivered==1 and not g.won and not R.clear_scene(),'the signal plate reaches its exit while blockers still stand')
g.obstacles=0
rules.game_check_end(g)
R.story_tick()
local scene=R.clear_scene()
check(scene and scene.exit==exit and not story.active(),'a completed delivery and the cleared board run the landing scene before dialogue')
R.now=R.now+5
R.story_tick()
check(R.story_current and R.story_current.key=='after-30','the landing scene hands off to the finale dialogue')
empty_queue(); R.story_tick()
R.g=rules.game_start(29,2)
R.g.delivered,R.g.won=1,true
R.prog.level=30
check(not R.clear_scene(),'a replay cannot run the landing scene again')
