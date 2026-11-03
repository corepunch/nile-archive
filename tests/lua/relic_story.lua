local journey=require('journey')
local rules=require('rules')
local island=require('island')
local R=require('state')
require('main')
local function empty_queue() while story.active() do story.next() end end
local function owned(c) return function(kind) return island.owned(c,kind)>0 end end

-- Follow the actual rewards, purchase gate and scheduler through all 30 clears.
local p={level=0,seed=1,wallet=purse(),story_seen={}}
local c=city.new();island.island_setup(c)
check(rules.LEVELS==30 and #journey.beats==36,'all three episodes are playable')
local lines=0
for _,b in ipairs(journey.beats) do
    check(#b.lines<=48,'each beat fits the engine queue')
    for _,line in ipairs(b.lines) do
        check(({elena=true,mara=true,tomas=true,adrian=true,kessler=true})[line[1]],'every line has a real cast member')
        lines=lines+1
    end
end
check(lines==214,'the entire reviewed script ships')
for level=1,30 do
    local before=journey.next(p,owned(c),level-1)
    if before then
        check(before.phase=='before' and before.level==level,'opening comes before its excavation')
        p.story_seen[before.key]=true
    end
    local g=rules.game_start(level-1,level);g.won=true;g.moves=0
    check(rules.progress_reward(p,g,island.wonders),'first clear advances the campaign')
    local kind=journey.wonder_at(level)
    if kind then
        check(not journey.next(p,owned(c),nil),'wonder story waits for confirmed construction')
        check(island.can_buy(c,p.wallet,p.level,kind-1),'earned restoration is affordable')
        check(island.reserved_gold(c,p.level)==island.wonders[kind].cost[1],'reserve covers the earned building')
        for z=1,5 do c:unlock(z,p.wallet) end
        check(island.island_place_next(c,p.wallet,p.level,0),'scheduled building fits open land')
    else
        check(not island.island_place_next(c,p.wallet,p.level,0),'ordinary clue creates no extra building')
    end
    local after=journey.next(p,owned(c),nil)
    check(after and after.key==('after-%02d'):format(level),'the right post-clear beat follows every result')
    check(journey.awaiting_return(p),'unread result blocks the next new excavation')
    p.story_seen[after.key]=true
    local replay=rules.game_start(level-1,100+level);replay.won=true;replay.moves=0
    local stars=p.wallet[4]
    check(rules.progress_reward(p,replay,island.wonders) and p.wallet[4]==stars,'replay gives no story progress or stars')
    check(not journey.next(p,owned(c),nil),'replay cannot repeat a completed beat')
end
check(c.count==10 and c.open==63 and p.wallet[4]==90,'thirty clears restore ten wonders and fund every region')
check(journey.next(p,owned(c),30)==nil,'finale ends at thirty, not the tenth wonder')

-- Real queue completion, interruption and save/read use the runtime coordinator.
R.test_mode=true;R.quiet=false;R.overlay=R.OV_NONE;R.on_island=false
R.island=c;R.g=rules.game_start(0,1)
R.prog={level=0,story_seen={}}
empty_queue();R.story_current=nil
R.story_tick()
check(story.active() and R.story_current.key=='before-01','new game opens the full eight-line scene')
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
check(journey.next(old,owned(c),nil).key=='after-13','an already-owned later wonder satisfies its story gate')
local preserved=city.new();island.island_setup(preserved);preserved.open=63
preserved:add(c.items[10].pos,9,0)
island.restore_saved(preserved,10)
check(island.owned(preserved,9)==1,'migration never deletes the legacy temple')
check(journey.building_about(1,15,'ordinary')~=journey.building_about(1,30,'ordinary'),'the island responds to the frost and restored song')
empty_queue()
