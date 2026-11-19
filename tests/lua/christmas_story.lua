local journey=require('journey')
local rules=require('rules')
local island=require('island')
local R=require('state')
require('main')
local function empty_queue() while story.active() do story.next() end end
local function owned(c) return function(kind) return island.owned(c,kind)>0 end end
local cast={}
for _,who in ipairs(R.cast) do cast[who.id]=true end

-- Follow the actual rewards, purchase gate and scheduler through all 100 clears.
local p={level=0,seed=1,wallet=purse(),story_seen={}}
local c=city.new();island.island_setup(c)
check(rules.LEVELS==100 and #journey.beats==110,'all hundred winter wishes are playable')
local stocked = rules.game_start(0, 1)
check(#stocked.spawn_kinds == 5 and stocked.tools[1] == 0, "opening board has three score pieces and two coins")
check(stocked.resource_yields[2].amount == 3 and stocked.resource_yields[3].amount == 5,
      "both opening coins keep their wallet values")
local intro = rules.game_start(3, 1)   -- wish 4 first ties tinsel over panes
intro.tools[1], intro.tool_meter[1] = 1, intro.tool_threshold
local tied
for _, i in ipairs(rules.level_of(intro).oil) do
    if intro.chain[i] > 0 and intro.ice[i] == 0 then tied = i; break end
end
check(tied ~= nil, "the first tinsel board has a chain over a blue pane")
if tied then
    local wave = rules.new_match()
    check(rules.game_tool(intro, 0, tied, wave), "hammer can hit tinsel")
    rules.game_apply(intro, wave)
    check(intro.chain[tied] == 0 and intro.oil[tied] == 1, "untangling tinsel leaves the pane blue")
    intro.tools[1], intro.tool_meter[1] = 1, intro.tool_threshold
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
check(lines==331,'the entire reviewed script ships')
local finds = 0
for level=1,rules.LEVELS do
    local before=journey.next(p,owned(c),level-1)
    if before then
        check(before.phase=='before' and before.level==level,'opening comes before its winter wish')
        p.story_seen[before.key]=true
    end
    local g=rules.game_start(level-1,level)
    local spec = rules.level_of(g)
    check(g.oil_left == #spec.oil and g.oil_left > 0, "every wish opens with fixed blue panes")
    check(#spec.goals == 1 and spec.goals[1] == "oil", "only the blue panes count toward the win")
    local layers = #(spec.stones or {})
    for _, e in ipairs(spec.chain_cells) do layers = layers + e.hits end
    for _, e in ipairs(spec.ice_cells or {}) do layers = layers + e.layers end
    check(g.initial_obstacles == layers, "every wish places exactly its authored tinsel, frost and stones")
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
        if level == 21 then
            -- An older market has the first four stalls and the old bakery grant.
            R.island, R.prog = c, {level=21, wallet=purse()}
            local function wallet(s)
                R.prog.wallet = s:ints("wallet", R.prog.wallet)
                R.serialize_campaign(s)
            end
            local bakery = island.buildings[island.kinds.bakery + 1].cost
            save.write("old-market-prices", function(s) s:ints("wallet", purse(100)) end)
            save.read("old-market-prices", wallet)
            check(R.prog.wallet[1] == bakery[1] and R.prog.wallet[2] == 0 and R.prog.wallet[3] == bakery[3], "the revised bakery has enough Gold and Supplies")
            check(island.can_buy(c, R.prog.wallet, 21, 2), "the bakery can be built before continuing")
            check(not island.can_buy(c, R.prog.wallet, 21, 15), "the reserved grant cannot buy a lamp post")
            save.write("new-market-prices", wallet)
            save.read("new-market-prices", wallet)
            check(R.prog.wallet[1] == bakery[1] and R.prog.wallet[2] == 0 and R.prog.wallet[3] == bakery[3], "saving the migrated wallet prevents a second top-up")
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
    p.story_seen[after.key]=true
    local replay=rules.game_start(level-1,100+level);replay.won=true;replay.moves=0
    local stars=p.wallet[4]
    check(rules.progress_reward(p,replay,island.wonders) and p.wallet[4]==stars,'replay gives no story progress or stars')
    check(not journey.next(p,owned(c),nil),'replay cannot repeat a completed beat')
end
check(finds == 6, "the six story finds do not consume a piece slot")
check(c.count==20 and c.open==63 and p.wallet[4]==100,'a hundred clears open all twenty stalls and all five new regions')
check(journey.next(p,owned(c),100)==nil,'finale ends at the hundredth wish, not the last stall')

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

R.island, R.prog = c, {level=10, wallet=purse()}
save.write("stacked-market-tools", function(s)
    s:int("market_resources", 4)
    s:ints("tool_stock", purse(183, 0, 37, 0))
end)
save.read("stacked-market-tools", R.serialize_campaign)
check(R.prog.bonus_charge[1] == 90 and R.prog.bonus_charge[2] == 0 and R.prog.bonus_charge[4] == 37,
      "legacy stock clamps Hammer to one use and moves Lantern's partial meter to its shared slot")
local migrated = R.make_board(9, 123)
check(migrated.tool_slots[1].key == "bomb" and migrated.tools[1] == 1,
      "the upgraded slot carries exactly one use from the old save")
save.write("shared-market-tools", R.serialize_campaign)
R.prog.bonus_charge = nil
save.read("shared-market-tools", R.serialize_campaign)
check(R.prog.bonus_charge[1] == 90 and R.prog.bonus_charge[4] == 37, "shared slot storage round-trips")

local chapel = island.ladder_position[island.kinds.chapel]
local cocoa = island.ladder_position[island.kinds.cocoa]
local stable = island.ladder_position[island.kinds.reindeer_stable]
-- A save older than version 7 names the stalls by their old ladder positions
-- (here bit 5, the old sixth permit, which is the chapel now). Its waivers are
-- discarded and rebuilt from what the save owns and how far the story has got.
local fresh = city.new(); island.island_setup(fresh)
R.island = fresh
save.write("pre-chapel-permits", function(s)
    s:int("market_resources", 5)
    s:int("ladder_waived", 1 << 5)
end)
R.prog.level = 30
save.read("pre-chapel-permits", R.serialize_campaign)
check(island.waived(fresh)[stable] and not island.waived(fresh)[chapel] and not island.waived(fresh)[cocoa],
      "old permit waivers are rebuilt: stalls before the latest earned story stall are optional, later ones still owed")
R.prog.level = 31
save.read("pre-chapel-permits", R.serialize_campaign)
check(island.waived(fresh)[chapel], "existing players who passed the chapel gate can build it at their leisure")
R.island = c

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
local old={level=19,seed=55,wallet=purse(1234,12,34,30,7)}
journey.migrate(old,2)
check(old.level==19 and old.wallet[1]==1234 and old.wallet[4]==30 and old.story_recap,'migration preserves the wallet and offers a recap')
check(journey.next(old,owned(c),19).key=='before-20','old progress opens the next scene without replaying what it has read')
local preserved=city.new();island.island_setup(preserved);preserved.open=63
preserved:add(c.items[1].pos,9,0)
island.restore_saved(preserved,10)
check(island.owned(preserved,9)==1,'migration never deletes the legacy Christmas tree')
check(journey.building_about(9,99,'ordinary')~=journey.building_about(9,100,'ordinary'),'the Christmas tree answers at level 100')
empty_queue()
