local journey=require('journey')
local rules=require('rules')
local island=require('island')
local R=require('state')
require('main')
local function empty_queue() while story.active() do story.next() end end
local U=require('user_events_runtime')
local function owned(c) return function(index) return island.owned(c,island.wonder_kinds[index+1])>0 end end

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
    local g=rules.game_start(3,123)
    local a,b=plaques_of(g)
    local initial=g.oil_left
    check(a and b and initial==#rules.levels[4].oil, 'blue plaques are authored under both locked and ordinary pieces')
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
    local _,b=plaques_of(rules.game_start(3,123))
    local level=rules.levels[4]
    local saved=level.oil_double
    level.oil_double={b}
    local g=rules.game_start(3,123)
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
    local hammer=rules.game_start(3,123,{log_cabin=true})
    local g=rules.game_start(3,123,{camp=true,log_cabin=true})
    local _,b=plaques_of(g)
    hammer.tools[1], g.tools[1] = 1, 1
    hammer.tool_meter[1], g.tool_meter[1] = hammer.tool_threshold, g.tool_threshold
    local single, area=rules.game_tool_area(hammer,0,b), rules.game_tool_area(g,0,b)
    local n=0
    for i in pairs(area) do
        n=n+1
        check(math.max(math.abs(rules.hex_q(i)-rules.hex_q(b)), math.abs(rules.hex_r(i)-rules.hex_r(b)))<=1 and rules.game_cell_active(g,i), 'dynamite area stays within one step on the board')
    end
    check(single[b] and next(single,b)==nil and next(single)==b, 'the pickaxe area is its own cell')
    check(n>1 and g.tools[1]==1, 'previewing does not spend a charge')
    g.tools[1]=0
    check(rules.game_tool_area(g,0,b)==nil, 'no area without a charge')
end

-- Story pieces occupy one palette slot and remain distinct through refills.
for level=1,10 do
    local spec=rules.levels[level]
    check(not spec.story_piece and not spec.signal, 'chapter one has only board resources and goals')
end
-- Follow the actual rewards, purchase gate and scheduler through both chapters.
local p={level=0,seed=1,wallet=purse(),story_seen={}}
local c=city.new();island.island_setup(c)
R.prog, R.island, R.quiet = p, c, true
-- A hundred expeditions: one scene after each clear, ten restoration scenes and nine openings.
check(rules.LEVELS==100 and journey.find('before-01') and journey.find('after-100') and not journey.find('after-02'),'the campaign opens with the flood and allows quiet boards between scenes')   -- the story spans the whole campaign
local cast={}
for _,who in ipairs(R.cast) do cast[who.id]=true end
for _,b in ipairs(journey.beats) do
    check(#b.lines<=48,'each beat fits the engine queue')
    for _,line in ipairs(b.lines) do check(cast[line[1]],'each voiced line has a cast member: '..tostring(line[1])) end
end
for _,b in ipairs(journey.upgrades) do
    check(b.phase=='upgrade' and b.event and journey.find_upgrade(b.event)==b and U.by_id[b.event] and U.by_id[b.event].upgrade,
        'each upgrade scene belongs to an upgrade event: '..b.key)
    for _,line in ipairs(b.lines) do check(cast[line[1]],'each upgrade line has a cast member: '..tostring(line[1])) end
end
for level=1,rules.LEVELS do
    check(R.start_level(level-1), 'the next board opens once its story and restorations are complete')
    local before=journey.next(p,owned(c),level-1)
    if before then
        check(before.phase=='before' and before.level==level,'opening comes before its excavation')
        p.story_seen[before.key]=true
    end
    local g=rules.game_start(level-1,level);g.won=true;g.moves=0
    local specs=rules.level_of(g)
    local layers=0
    for _,e in ipairs(specs.chain_cells) do layers=layers+e.hits end
    for _,e in ipairs(specs.ice_cells or {}) do layers=layers+e.layers end
    check(g.initial_obstacles==layers+#(specs.stones or {}),
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
    for _, i in ipairs(specs.oil) do g.oil[i]=0 end
    g.oil_left=0
    rules.game_check_end(g)
    check(g.won and g.score==0 and g.relics==0, 'clearing all plaques wins without a score or item quota')
    g.moves=0
    local reveal=journey.result_beat(p,g)
    local written=journey.find(('after-%02d'):format(level))
    check(reveal==written,'only a scripted first clear interrupts the board')
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
    check(after==written,'a quiet board advances without a clear scene')
    check(R.start_level(level),'an unread result leaves the next expedition open')
    if after then p.story_seen[after.key]=true end
    for z=1,5 do c:unlock(z,p.wallet) end
    for _, step in ipairs(opened) do
        check(island.next_step(c,p.level)==step.kind,'restorations open in ladder order')
        if step.story then
            if level < rules.LEVELS then check(R.start_level(level),'the next board opens before construction') end
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
        check(placed and placed.key==('restore-%02d'):format(level),
            'confirmed construction or upgrade releases its scene')
        local built = island.buildings[island.wonder_kinds[kind] + 1]
        check(placed.building == built.name, 'the reviewed scene must match the purchase: ' .. built.name)
        if level==1 then
            check(placed.lines[1][1]=='oren' and placed.lines[1][2]:lower():find('bucket',1,true),
                'the first bucket opens the Well scene with Oren on screen')
        end
        if level==16 then
            check(placed.phase=='restore' and placed.choices and #placed.choices==2, 'Sela can offer her brother a place to sleep or help with the water')
        end
        p.story_seen[placed.key]=true
    end
    local replay=rules.game_start(level-1,100+level);replay.won=true;replay.moves=0
    local cleared=p.wallet[rules.CLEARED]
    check(rules.progress_reward(p,replay,island.wonders) and p.wallet[rules.CLEARED]==cleared,'replay does not advance the clear count')
    check(not journey.next(p,owned(c),nil),'replay cannot repeat a completed beat')
end
check(island.campaign_count(c)==#island.ladder and #island.ladder==20 and p.wallet[rules.CLEARED]==rules.LEVELS,
    'a hundred clears open all twenty purchases')
local unread=0
for _,b in ipairs(journey.beats) do if not p.story_seen[b.key] then unread=unread+1 end end
check(unread==0 and not journey.next(p,owned(c),rules.LEVELS-1),'the whole script has been read')

-- Take the normal Play, resume and Collect paths with an empty island.
R.island=city.new(); island.island_setup(R.island)
R.prog={level=0,seed=1,wallet=purse(),story_seen={}}
R.test_mode=true
for level=1,rules.LEVELS do
    check(R.play_level(level-1) and R.g.level==level-1,'Play opens expedition '..level)
    if level==1 then
        R.quiet=false
        R.story_tick()
        check(story.active() and R.story_current.key=='before-01','fresh Play explains the flood before a move')
        empty_queue();R.story_tick()
        R.quiet=true
    end
    local board=R.g
    R.on_island=true
    check(R.play_level(level-1) and R.g==board and not R.on_island,'Play resumes the same expedition')
    R.overlay=R.OV_RESULT
    for _,cell in ipairs(rules.level_of(board).oil) do board.oil[cell]=0 end
    board.oil_left=0
    rules.game_check_end(board)
    R.quiet=false
    R.story_tick()
    if level==1 then
        check(story.active() and R.story_current and R.story_current.key=='after-01',
            'the first result plays its own clear scene')
        empty_queue();R.story_tick()
    else
        check(not story.active() and not R.story_current,
            'an unbuilt restoration scene holds every later scene unread')
    end
    R.claim_reward()
    R.story_tick()
    check(R.prog.level==level and R.on_island and not story.active(),'Collect opens the next expedition')
    R.quiet=true
end
local read=0
for key in pairs(R.prog.story_seen) do read=read+1 end
check(R.island.count==0 and read==2 and R.prog.story_seen['before-01'] and R.prog.story_seen['after-01'],
    'all hundred expeditions clear without building; only the opening and first clear played')

-- Real queue completion, interruption and save/read use the runtime coordinator.
R.test_mode=true;R.quiet=false;R.overlay=R.OV_NONE;R.on_island=false
R.island=c;R.g=rules.game_start(0,1)
R.prog={level=0,story_seen={}}
empty_queue();R.story_current=nil
R.story_tick()
check(story.active() and R.story_current.key=='before-01','the first board opens with Sela returning home')
empty_queue();R.story_tick()
R.prog.level, R.on_island = 1, true
R.prog.story_seen['after-01']=true   -- the clear scene has played; the Well scene follows construction
R.story_tick()
check(story.active() and R.story_current.key=='restore-01','the Well opens with Oren tasting the water')
story.next()
check(not R.prog.story_seen['restore-01'],'a partially read beat is not acknowledged')
save.write('story-interrupted',function(s) journey.serialize(s,R.prog) end)
empty_queue();R.story_current=nil;R.prog={level=1,story_seen={['before-01']=true,['after-01']=true}}
save.read('story-interrupted',function(s) journey.serialize(s,R.prog) end)
R.story_tick()
check(story.active() and R.story_current.key=='restore-01','reload recovers the interrupted scene')
empty_queue();R.story_tick()
check(R.prog.story_seen['restore-01'] and not story.active(),'finishing or skipping acknowledges exactly one scene')
save.write('story-completed',function(s) journey.serialize(s,R.prog) end)
R.prog={level=0,story_seen={}}
save.read('story-completed',function(s) journey.serialize(s,R.prog) end)
check(R.prog.story_seen['restore-01'],'completed keys survive save/read')

-- A player from the twenty-expedition script keeps their clears and meets the next opening.
local old={level=20,seed=55,wallet=purse(1234,12,34,30,7)}
journey.migrate(old,5)
check(old.level==20 and old.wallet[1]==1234 and old.wallet[4]==30 and old.story_recap,'migration preserves the wallet and offers a recap')
check(journey.next(old,owned(c),20).key=='before-21','old completion opens the next epoch without replaying the earlier scenes')
local preserved=city.new();island.island_setup(preserved);preserved.open=63
preserved:add(c.items[1].pos,9,0)
island.restore_saved(preserved,20)
check(island.owned(preserved,9)==1,'migration never deletes the legacy temple')
check(journey.building_about(9,90,'ordinary')~=journey.building_about(9,91,'ordinary'),'the island responds to the restored warning')

-- Save a branch selection before its reply finishes. Reload must replay the
-- selected reply, then acknowledge the reveal once and unlock chapter two.
local reveal=journey.find('restore-16')
local selected={level=16,story_seen={},story_choices={['restore-16']=2}}
for _, b in ipairs(journey.beats) do if b.level<=16 and b.key~='restore-16' then selected.story_seen[b.key]=true end end
save.write('story-choice',function(s) journey.serialize(s,selected) end)
R.prog={level=16,story_seen={}}
save.read('story-choice',function(s) journey.serialize(s,R.prog) end)
R.on_island=true;R.overlay=R.OV_NONE;R.story_current=nil
R.story_tick()
check(R.story_current and R.story_current.lines==reveal.choices[2].lines,'reload resumes the chosen reply')
empty_queue();R.story_tick()
R.prog.level=20
check(R.prog.story_seen['restore-16'] and journey.next(R.prog,owned(c),nil).key=='after-20',
    'finishing the reply releases the next clear scene')
empty_queue()
