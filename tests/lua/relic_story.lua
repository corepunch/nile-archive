local journey=require('journey')
local rules=require('rules')
local island=require('island')
local quests=require('quests')
local R=require('state')
require('main')
local function empty_queue() while story.active() do story.next() end end
local function owned(c) return function(kind) return island.owned(c,kind)>0 end end

-- Follow the actual rewards, purchase gate and scheduler through all 30 clears.
local p={level=0,seed=1,wallet=purse(),story_seen={}}
local c=city.new();island.island_setup(c)
check(rules.LEVELS==30 and #journey.beats==46,'all chapters and their restoration scenes are playable')
for _,b in ipairs(journey.beats) do
    check(#b.lines<=48,'each beat fits the engine queue')
    for _,line in ipairs(b.lines) do
        check(({elena=true,mara=true,tomas=true,adrian=true,kessler=true})[line[1]],'every line has a real cast member')
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
    if level<=10 then
        check(rules.level_of(g).quest_object, 'first-clear story retains its quest object')
    end
    g.score,g.relics,g.obstacles=0,0,0
    rules.game_check_end(g)
    check(not g.won, 'ordinary match-3 goals must be met')
    g.score,g.relics=99999,999
    g.delivered,g.carpeted,g.oil_left=g.delivery_total,g.carpet_total,0
    rules.game_check_end(g)
    check(g.won, 'completing the match-3 goals wins without an object')
    g.moves=0
    local reveal=journey.result_beat(p,g)
    check(level==10 and reveal==nil or reveal and reveal.level==level,
        'the first-clear exchange precedes results except the town choice')
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
