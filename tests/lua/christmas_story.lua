local journey=require('journey')
local rules=require('rules')
local island=require('island')
local R=require('state')
require('main')
local function empty_queue() while story.active() do story.next() end end
local function owned(c) return function(kind) return island.owned(c,kind)>0 end end
local cast={}
for _,who in ipairs(R.cast) do cast[who.id]=true end

-- Follow the actual rewards, purchase gate and scheduler through all 30 clears.
local p={level=0,seed=1,wallet=purse(),story_seen={}}
local c=city.new();island.island_setup(c)
check(rules.LEVELS==30 and #journey.beats==36,'all three episodes are playable')
local stocked = rules.game_start(0, 1)
check(#stocked.spawn_kinds == 4 and stocked.tools[1] == 0, "opening board has two score pieces and two coins")
local cell = rules.hex_center()
for kind = 0, 3 do
    local wave = rules.new_match()
    stocked.tiles[cell], stocked.tools[1] = rules.tile(kind), 1
    check(rules.game_tool(stocked, 0, cell, wave), "hammer can hit a regular piece")
    rules.game_apply(stocked, wave)
end
check(stocked.earnings[1] == 8 and stocked.earnings[2] == 0 and stocked.earnings[3] == 0,
      "only the coins pay on the opening board")
local intro = rules.game_start(4, 1)
intro.tools[1] = 1
local tied
for _, i in ipairs(rules.level_of(intro).oil) do
    if intro.chain[i] > 0 then tied = i; break end
end
check(tied ~= nil, "the first tinsel board has a chain over a blue pane")
if tied then
    local wave = rules.new_match()
    check(rules.game_tool(intro, 0, tied, wave), "hammer can hit tinsel")
    rules.game_apply(intro, wave)
    check(intro.chain[tied] == 0 and intro.oil[tied] == 1, "untangling tinsel leaves the pane blue")
    intro.tools[1] = 1
    check(rules.game_tool(intro, 0, tied, wave), "hammer can hit the freed treat")
    rules.game_apply(intro, wave)
    check(intro.oil[tied] == 0, "clearing the freed treat lights the pane")
end

local lines=0
for _,b in ipairs(journey.beats) do
    check(#b.lines<=48,'each beat fits the engine queue')
    for _,line in ipairs(b.lines) do
        check(cast[line[1]],'every line has a real cast member')
        lines=lines+1
    end
end
check(lines==198,'the entire reviewed script ships')
local finds = 0
for level=1,30 do
    local before=journey.next(p,owned(c),level-1)
    if before then
        check(before.phase=='before' and before.level==level,'opening comes before its winter wish')
        p.story_seen[before.key]=true
    end
    local g=rules.game_start(level-1,level)
    local spec = rules.level_of(g)
    check(spec.oil_still and g.oil_left == #spec.oil and g.oil_left > 0, "every wish opens with fixed blue panes")
    check(#spec.goals == 1 and spec.goals[1] == "oil", "only the blue panes count toward the win")
    check(g.initial_obstacles == spec.chains and g.carpet_total == 0 and g.delivery_total == 0,
          "tinsel is the only campaign blocker")
    if spec.story_piece then
        finds = finds + 1
        check(not spec.story_piece.kind and not g.goal_kind, "story finds leave all the board's goods in play")
    end
    g.won=true;g.moves=0
    -- Supply the income for every ladder stall this clear opens.
    local opened, price = {}, purse()
    for _, step in ipairs(island.ladder) do
        if step.after == level then opened[#opened + 1], price = step, price + island.buildings[step.kind + 1].cost end
    end
    g.earnings = {price[1], price[2], price[3]}
    check(rules.progress_reward(p,g,island.wonders),'first clear advances the campaign')
    for z=1,5 do c:unlock(z,p.wallet) end
    local kind=journey.wonder_at(level)
    if kind then
        if level == 7 then
            -- An older market has the first two stalls and the old bakery grant.
            R.island, R.prog = c, {level=7, wallet=purse()}
            local function wallet(s)
                R.prog.wallet = s:ints("wallet", R.prog.wallet)
                R.serialize_campaign(s)
            end
            save.write("old-market-prices", function(s) s:ints("wallet", purse(100)) end)
            save.read("old-market-prices", wallet)
            check(R.prog.wallet[1] == 300 and R.prog.wallet[2] == 0 and R.prog.wallet[3] == 200, "the revised bakery has enough Gold and Supplies")
            check(island.can_buy(c, R.prog.wallet, 7, 2), "the bakery can be built before continuing")
            check(not island.can_buy(c, R.prog.wallet, 7, 15), "the reserved grant cannot buy a lamp post")
            save.write("new-market-prices", wallet)
            save.read("new-market-prices", wallet)
            check(R.prog.wallet[1] == 300 and R.prog.wallet[2] == 0 and R.prog.wallet[3] == 200, "saving the migrated wallet prevents a second top-up")
        end
        check(not journey.next(p,owned(c),nil),'stall story waits for confirmed construction')
    end
    for _, step in ipairs(opened) do
        check(island.next_step(c,p.level)==step.kind and island.can_buy(c,p.wallet,p.level,step.kind),
            'earned stall is next on the ladder and affordable')
        check(island.island_place_next(c,p.wallet,p.level,0),'scheduled stall fits open land')
    end
    check(not island.island_place_next(c,p.wallet,p.level,0),'a wish opens only its own stalls')
    local after=journey.next(p,owned(c),nil)
    check(after and after.key==('after-%02d'):format(level),'the right post-clear beat follows every result')
    check(journey.awaiting_return(p),'unread result blocks the next new wish')
    p.story_seen[after.key]=true
    local replay=rules.game_start(level-1,100+level);replay.won=true;replay.moves=0
    local stars=p.wallet[4]
    check(rules.progress_reward(p,replay,island.wonders) and p.wallet[4]==stars,'replay gives no story progress or stars')
    check(not journey.next(p,owned(c),nil),'replay cannot repeat a completed beat')
end
check(finds == 6, "six story wishes have authored finds")
check(c.count==20 and c.open==63 and p.wallet[4]==90,'thirty clears build twenty stalls and open every region')
check(journey.next(p,owned(c),30)==nil,'finale ends at thirty, not the tenth stall')

R.prog = {level=0, wallet=purse(), completed={level=0, rng=4, moves=10, score=400, earnings={33, 6, 9}}}
save.write("pending-market-resources", R.serialize_campaign)
R.prog.completed = nil
save.read("pending-market-resources", R.serialize_campaign)
R.resume_completed()
check(R.g.won and R.g.oil_left == 0 and R.overlay == R.OV_RESULT, "a saved win resumes at Collect")
check(R.g.earnings[1] == 33 and R.g.earnings[2] == 6 and R.g.earnings[3] == 9,
      "an unclaimed win retains every matched resource after reloading")
check(rules.progress_reward(R.prog, R.g, island.wonders) and not R.prog.completed,
      "Collect consumes the completed snapshot")

-- Real queue completion, interruption and save/read use the runtime coordinator.
R.test_mode=true;R.quiet=false;R.overlay=R.OV_NONE;R.on_island=false
R.island=c;R.g=rules.game_start(0,1)
R.prog={level=0,story_seen={}}
empty_queue();R.story_current=nil
R.story_tick()
check(story.active() and R.story_current.key=='before-01','new game opens the full opening scene')
story.next()
check(not R.prog.story_seen['before-01'],'a partially read beat is not acknowledged')
save.write('story-interrupted',function(s) journey.serialize(s,R.prog) end)
empty_queue();R.story_current=nil;R.prog={level=0,story_seen={}}
save.read('story-interrupted',function(s) journey.serialize(s,R.prog) end)
R.on_island=true   -- a new game starts in the market; the opening still plays
R.story_tick()
check(story.active() and R.story_current.key=='before-01','reload recovers the interrupted scene')
empty_queue();R.story_tick()
check(R.prog.story_seen['before-01'] and not story.active(),'finishing or skipping acknowledges exactly one scene')
save.write('story-completed',function(s) journey.serialize(s,R.prog) end)
R.prog={level=0,story_seen={}}
save.read('story-completed',function(s) journey.serialize(s,R.prog) end)
check(R.prog.story_seen['before-01'],'completed keys survive save/read')

-- A version 2 player keeps every stall already built and starts episode two.
local old={level=10,seed=55,wallet=purse(1234,12,34,30,7)}
journey.migrate(old,2)
check(old.level==10 and old.wallet[1]==1234 and old.wallet[4]==30 and old.story_recap,'migration preserves the wallet and offers a recap')
check(journey.next(old,owned(c),10).key=='before-11','old completion opens the new episode without replaying episode one')
old.level=13;old.story_seen['before-11']=true
old.story_seen['after-11'],old.story_seen['after-12']=true,true
check(journey.next(old,owned(c),nil).key=='after-13','an already-built later stall satisfies its story gate')
local preserved=city.new();island.island_setup(preserved);preserved.open=63
preserved:add(c.items[10].pos,9,0)
island.restore_saved(preserved,10)
check(island.owned(preserved,9)==1,'migration never deletes the legacy Christmas tree')
check(journey.building_about(4,19,'ordinary')~=journey.building_about(4,20,'ordinary'),'the market answers the letter at level 20')
empty_queue()

-- The picture holds on its own, then its existing scene plays before Collect.
for _, level in ipairs{24, 25, 28} do
    local key = ('after-%02d'):format(level)
    local index = level - 1
    R.g, R.overlay, R.now = rules.game_start(index, 1), R.OV_RESULT, 0
    R.g.won = true
    R.prog = {level=index, wallet=purse(), story_seen={}}
    R.story_tick()
    check(not story.active(), 'level ' .. level .. ' holds its finished picture before speaking')
    R.now = 2
    R.story_tick()
    check(story.active() and R.story_current.key == key, 'the picture hands off to ' .. key)
    empty_queue(); R.story_tick()
    check(R.g.story_clear == key and not R.prog.story_seen[key], 'the scene waits for reward collection')
    R.wonders = island.wonders
    R.claim_reward()
    check(R.prog.level == level and R.prog.story_seen[key], 'Collect banks the scene with the win')
    R.g, R.overlay = rules.game_start(index, 1), R.OV_RESULT
    R.g.won = true
    R.story_tick()
    check(not story.active() and not require('match3.elements_view').reveal_holding(R, rules),
          'a replay skips the picture and its scene')
end
