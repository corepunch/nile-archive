local rules=require("rules")
local economy=require("economy")
local island=require("island")
local R=require("state")
require("main")
-- A plain cell inside a playable 3×3 area, for tool checks.
local function open_cell(g)
    for i=0,rules.CELLS-1 do
        local ok=rules.game_cell_active(g,i) and g.stone_hp[i]==0
        for x=-1,1 do
            for y=-1,1 do
                local j=rules.hex_index(rules.hex_q(i)+x,rules.hex_r(i)+y)
                ok=ok and rules.game_cell_active(g,j) and g.chain[j]==0 and g.stone_hp[j]==0
            end
        end
        if ok then return i end
    end
end
-- A win banks the ledger of matched resources. Unspent moves and town
-- decorations never change it, and replay claims stay idempotent.
do
    local town={items={{type=0},{type=37}}}
    local p={level=1,seed=1,wallet=purse(0,0,0,1)}
    local g=rules.game_start(0,99);g.won=true;g.moves=99;g.earnings={7,6,5}
    local reward=rules.reward_breakdown(g,p)
    check(reward.total[1]==7 and reward.total[2]==6 and reward.total[3]==5 and reward.total[4]==0,
        'only matched resources go into replay payouts')
    check(rules.progress_reward(p,g,island.wonders,town) and p.wallet[1]==7,'a replay banks its matches')
    check(not rules.progress_reward(p,g,island.wonders,town) and p.wallet[1]==7,'cannot claim twice')
end

-- Confirmed restorations persist across eligible boards without taking story slots.
do
    R.island=city.new();island.island_setup(R.island)
    local bank=purse(9000,9000,9000,90)
    local locked=R.make_board(1,19)
    local match=rules.new_match()
    check(next(locked.tool_meter) == nil, 'all bonus sockets require confirmed construction')
    check(not rules.game_tool(locked,1,rules.hex_center(),match),'locked dynamite cannot be used')
    check(locked.backdrop==economy.opening_backdrop,'with nothing restored the board shows the landing')
    local c, well = R.island, island.kinds.well
    local fits, spot = c:find_spot(well,island.island_suggestion(well))
    check(fits,'well fits the first region')
    c:begin_place(well, spot)
    check(R.make_board(1,19).resource_yields[3]==nil,'a placement preview cannot unlock water')
    check(R.make_board(1,19).backdrop==economy.opening_backdrop,'a placement preview leaves the backdrop alone')
    c:cancel()
    check(R.make_board(1,19).resource_yields[3]==nil,'cancelling keeps water locked')
    check(island.island_place_next(c,bank,1,0),'confirm the well')
    check(R.make_board(1,19).resource_yields[3]==economy.unlock_of("well"),'water follows construction')
    check(R.make_board(1,19).backdrop=="well",'confirming the well unlocks its backdrop')
    check(not island.island_place_next(c,bank,5,0),'the cabin waits for clear six')
    check(island.island_place_next(c,bank,6,0),'confirm the cabin')
    local first = R.make_board(6,19)
    check(first.bonus_debut == economy.bonuses.hammer and first.tool_meter[1]==0,'the cabin debuts Hammer')
    local workshop = island.kinds.workshop
    fits,spot = c:find_spot(workshop,island.island_suggestion(workshop))
    check(fits,'workshop has a placement spot')
    c:begin_place(workshop,spot)
    check(R.make_board(11,19).resource_yields[4]==nil,'timber waits for confirmation')
    c:cancel()
    local steps, price = island.kinds.quay_steps, island.buildings[workshop+1].cost
    check(island.owned(c,steps)==0 and not island.can_buy(c,bank,11,steps),'the retired staircase stays off sale')
    local balance=purse(table.unpack(bank))
    check(island.island_place_next(c,bank,11,0),'confirm the workshop')
    for slot=1,3 do check(bank[slot]==balance[slot]-price[slot],'the workshop charges its listed price') end
    check(c.items[c.count].type==workshop and island.owned(c,steps)==0,'the workshop stands on its own')
    check(island.island_place_next(c,bank,16,0),'confirm the camp')
    local previous=R.g
    R.g,first.tool_meter[1]=first,first.tool_threshold//2
    R.refresh_board_bonuses()
    R.g=previous
    check(first.tool_slots[1]==economy.bonuses.bomb and first.bonus==economy.bonuses.bomb
        and first.tool_meter[1]==first.tool_threshold//2,'a parked board replaces Hammer and preserves its charge')
    check(first.backdrop=="log_cabin",'refreshing a parked expedition respects its original backdrop gate')
    check(island.island_place_next(c,bank,21,0),'confirm the market')
    for level=0,rules.LEVELS-1 do
        local g=R.make_board(level,19)
        check(g.spawn_kinds==nil and rules.COLORS==5,'every expedition keeps its five kinds')
        local charge_kinds=0
        for _,piece in pairs(g.resource_yields) do if piece.tool then charge_kinds=charge_kinds+1 end end
        check(charge_kinds==(g.bonus and 1 or 0),'only the selected family spawns')
        local spec=rules.level_of(g)
        if spec.story_piece then check(not g.resource_yields[spec.goal_kind],'story pieces keep their slot') end
    end
    local restored = {}
    local previous_backdrop = economy.opening_backdrop
    for _, unlock in ipairs(economy.unlocks) do
        local level, building = unlock.first_level, unlock.building
        check(economy.board_backdrop(level, restored)==previous_backdrop,'unbuilt ' .. building .. ' keeps the previous backdrop')
        restored[building] = true
        check(economy.board_backdrop(level-1, restored)==previous_backdrop,'earlier expeditions keep their backdrop')
        check(economy.board_backdrop(level, restored)==building,'eligible expeditions show the ' .. building .. ' backdrop')
        previous_backdrop = building
    end
end

-- The landing opens with five pieces. Its leaf, flower,
-- amphora use the normal scoring path and pay nothing; only the two coins pay.
do
    local g = rules.game_start(0,123)
    local keys = {}
    for kind = 0, rules.COLORS - 1 do keys[kind + 1] = economy.pieces[kind].key end
    check(table.concat(keys,' ')=='coin silver-coin leaf flower amphora',"the base pool has five pieces")
    for kind, piece in pairs(g.resource_yields) do
        check(piece.slot==economy.GOLD,'before any restoration a board pays Coins only: ' .. kind)
    end
    check(g.resource_yields[0].amount==5 and g.resource_yields[1].amount==3,'gold coins pay 5 and silver coins 3')
end
for _, entry in ipairs{{1, 2, 'leaf'}, {1, 3, 'flower'}, {6, 4, 'amphora'}} do
    local level, kind, name = table.unpack(entry)
    local g = rules.game_start(level-1,123)
    local yield = g.resource_yields[kind]
    check(not yield and economy.pieces[kind].key==name,'the selected expedition spawns ' .. name)
    local present = false
    for i=0,rules.CELLS-1 do present = present or g.tiles[i].kind == kind end
    check(present,'the opening contains ' .. name)
    for _, i in ipairs(require('support').open_line(rules, g)) do
        g.tiles[i], g.chain[i], g.ice[i] = rules.tile(kind), 0, 0
    end
    local m = rules.new_match()
    rules.game_matches(g,m,-1)
    check(m.hits >= rules.MATCH_MIN,'a line of ' .. name .. ' matches')
    rules.game_apply(g,m)
    check(g.score > 0 and g.earnings[economy.GOLD] == 0 and g.earnings[economy.SUPPLIES] == 0
        and g.earnings[economy.PROVISIONS] == 0,
        'leaf, flower and amphora matches pay score only')
end

do
    local restored = {gateway=true, lodge=true, amphitheater=true, map_room=true, archive=true}
    local lodge = rules.game_start(46, 123, restored)
    local map_room = rules.game_start(56, 123, restored)
    local ring = rules.game_start(61, 123, restored)
    check(lodge.bonus_debut == economy.bonuses.hourglass and lodge.resource_yields[3].key == "shrimp"
        and lodge.resource_yields[3].amount == 6, "the lodge adds only the Hourglass")
    check(map_room.bonus_debut == economy.bonuses.lightning and map_room.resource_yields[0].key == "helmet"
        and ring.resource_yields[0].key == "ring", "only the archive replaces helmets with rings")
end

-- Like Cradle of Rome's ladder, each new piece pays toward the next purchase.
for n, step in ipairs(island.ladder) do
    local unlock=step.unlock
    local following=island.ladder[n+1]
    local next_building=following and island.buildings[following.kind+1]
    if unlock.slot and next_building then
        check(next_building.cost[unlock.slot]>0,unlock.name .. ' helps pay for ' .. next_building.name)
    end
end

local function charge(g, bonus)
    g.tools[bonus.tool], g.tool_meter[bonus.tool] = 1, g.tool_threshold
    return bonus.tool - 1
end

-- Hammer and Dynamite share a meter, including a charged use earned before the upgrade.
do
    local B = economy.bonuses
    local restored = {log_cabin=true, bonus_charge={}}
    local g, m = rules.game_start(6, 73, restored), rules.new_match()
    local kind = economy.SPECIAL_KIND
    check(g.bonus_debut == B.hammer and g.resource_yields[kind] == B.hammer, 'the cabin debuts Hammer')
    local line = require('support').open_line(rules, g)
    for match = 1, 11 do
        for _, cell in ipairs(line) do
            g.chain[cell], g.ice[cell], g.stone_hp[cell] = 0, 0, 0
            g.tiles[cell] = rules.tile(kind)
        end
        rules.game_matches(g, m, -1)
        rules.game_apply(g, m)
        check(g.tools[B.hammer.tool] == (match < 10 and 0 or 1), 'the charge arrives on the thirtieth Hammer piece')
    end
    local tool = B.hammer.tool
    check(g.tools[tool] == 1 and g.tool_meter[tool] == g.tool_threshold, 'extra matches cannot bank a second use')
    local copy = rules.game_copy(g)
    copy.tools[tool], copy.tool_meter[tool] = 0, 0
    check(g.tools[tool] == 1 and g.tool_meter[tool] == g.tool_threshold, 'preview copies preserve the live meters')
    R.g, R.prog, R.test_mode = g, {bonus_charge=restored.bonus_charge}, true
    R.update_bonus_charges()
    restored.camp = true
    local later = rules.game_start(rules.LEVELS - 1, 1, restored)
    check(later.tool_slots[tool] == B.bomb and later.tools[tool] == 1
        and later.tool_meter[tool] == g.tool_threshold, 'the stored Hammer use becomes a Dynamite use')
    local center = open_cell(later)
    check(rules.game_tool(later, tool - 1, center, m) and m.hits == 9
        and later.moves == rules.level_of(later).moves, 'Bomb blasts nine cells without spending a move')
    R.g = later
    R.update_bonus_charges()
    check(rules.game_start(rules.LEVELS - 1, 1, restored).tool_meter[tool] == 0, 'spending a charge clears it across boards')
end

-- Compare targeted previews with the actual hit mask, and verify instant tools on live boards.
do
    local B = economy.bonuses
    for _, key in ipairs{"shield","star"} do
        local bonus = B[key]
        local g = rules.game_start(rules.LEVELS - 1,3,{clock_tower=true,temple=true})
        local m, center = rules.new_match(), open_cell(g)
        local tool = charge(g,bonus)
        local preview = rules.game_tool_area(g,tool,center)
        check(preview and preview[center] and g.tools[tool+1]==1,"target preview retains the charge")
        check(rules.game_tool(g,tool,center,m) and m.hits>1,key .. " hits its pattern")
        for i=0,rules.CELLS-1 do
            check(m.mask[i]==preview[i],"effect hits precisely its preview")
            if key=="star" and m.mask[i] then check(g.tiles[i].kind==g.tiles[center].kind,"Star targets one kind") end
        end
    end
    do
        local g, m = rules.game_start(rules.LEVELS - 1,3,{lighthouse=true,log_cabin=true}),rules.new_match()
        local tool, cell = charge(g,B.plus),open_cell(g)
        g.tiles[cell] = rules.tile(0)
        check(rules.game_tool(g,tool,cell,m) and g.earnings[economy.GOLD]==100 and m.hits==0,
            "Plus awards the selected currency without clearing the tile")
        charge(g,B.plus)
        check(rules.game_tool(g,tool,nil,m,B.hammer.tool) and g.tool_meter[B.hammer.tool]==g.tool_threshold//4,
            "Plus charges the selected socket by a quarter")
        charge(g,B.plus)
        check(not rules.game_tool(g,tool,nil,m,B.star.tool) and g.tools[tool+1]==1,"a locked target preserves Plus")
    end
    for _, key in ipairs{"lightning","hourglass","mixer"} do
        local bonus = B[key]
        local g = rules.game_start(rules.LEVELS - 1,3,{map_room=true,lodge=true,observatory=key=="mixer"})
        local m, moves = rules.new_match(), g.moves
        local tool = charge(g,bonus)
        check(rules.game_tool_untargeted(tool,g) and rules.game_tool(g,tool,nil,m),key .. " activates from its socket")
        check(g.tool_meter[tool+1]==0 and g.moves==moves+(key=="hourglass" and 5 or 0),"instant bonus applies once")
        if key=="lightning" then check(m.hits==15,"Lightning strikes fifteen distinct cells") end
        if key=="mixer" then check(rules.game_hint(g)~=nil,"Mixer leaves a playable board") end
    end
end

-- A save from before the ladder keeps playing: the new restorations it had
-- already passed become optional, survive a save and never hold its board.
do
    local saved_island, saved_prog = R.island, R.prog
    local c = city.new(); island.island_setup(c)
    local bank = purse(5000, 5000, 5000, 90)
    for z = 1, 5 do c:unlock(z, bank) end
    local market = island.kinds.market
    for _, n in ipairs{1, 4} do   -- the well and the camp, the story buildings before the market
        local kind = island.ladder[n].kind
        local ok, spot = c:find_spot(kind, island.island_suggestion(kind))
        c:begin_place(kind, spot)
        check(ok and c:confirm(bank, 0).result == city.BUILT, 'an old save owns its first story restorations')
    end
    check(not island.can_buy(c, bank, 21, market), 'without a waiver the market waits for the earlier ladder')
    island.waive_passed(c, 21)
    island.waived(c)[island.ladder_position[island.kinds.log_cabin]] = true -- this pre-epoch save had already passed the cabin
    check(island.next_step(c, 21) == market and island.can_buy(c, bank, 21, market), 'the waived save builds its market')
    local reserved, price = island.reserved_cost(c, 21), island.buildings[market + 1].cost
    check(reserved:covers(price) and price:covers(reserved), 'waived restorations are not reserved')
    local cabin = island.kinds.log_cabin
    check(island.can_buy(c, bank, 21, cabin) and island.ladder_blocked(c, 21, cabin) == false,
        'a waived restoration stays on sale')
    R.island, R.prog = c, {level=21, wallet=purse(1, 2, 3), story_seen={}, bonus_charge={}}
    save.write("relic-ladder-waived", R.serialize_campaign)
    local fresh = city.new(); island.island_setup(fresh)
    R.island = fresh
    save.read("relic-ladder-waived", R.serialize_campaign)
    local waived = island.waived(fresh)
    check(waived[2] and waived[3] and not waived[5] and not waived[6],
        'the waived positions survive a save')
    local wallet = R.prog.wallet
    check(wallet[1] == 1 and wallet[2] == 2 and wallet[3] == 3, 'reading a current save leaves the wallet alone')
    -- A version 3 save read at the same point waives them itself.
    local old = city.new(); island.island_setup(old)
    for z = 1, 5 do old:unlock(z, bank) end
    for _, n in ipairs{1, 4} do
        local kind = island.ladder[n].kind
        local _, spot = old:find_spot(kind, island.island_suggestion(kind))
        old:begin_place(kind, spot); old:confirm(bank, 0)
    end
    save.write("relic-ladder-v3", function(s) s:int("resource_version", 3) end)
    R.island = old
    save.read("relic-ladder-v3", R.serialize_campaign)
    check(island.waived(old)[2] and island.next_step(old, 21) == market, 'a version 3 save waives the passed restorations')
    R.island, R.prog = saved_island, saved_prog
end

-- Clear regular pieces through the real match resolver. A blocker absorbs
-- the first hit and the preview solver cannot alter the live ledger.
do
    local g=R.make_board(6,19)
    local b=open_cell(g)
    local a,c=rules.hex_neighbor(b,3),rules.hex_neighbor(b,0)
    for _,i in ipairs{a,b,c} do g.ice[i],g.oil[i]=0,0 end
    g.chain[a],g.chain[b],g.chain[c]=1,0,0
    g.tiles[a],g.tiles[b],g.tiles[c]=rules.tile(3),rules.tile(0),rules.tile(1)
    local m=rules.new_match()
    m.mask[a],m.mask[b],m.mask[c]=true,true,true
    rules.game_apply(g,m)
    check(g.earnings[1]==8 and g.earnings[2]==0 and g.earnings[3]==0,'credit paid-once gold and silver coins, protected water waits')
    local copy=rules.game_copy(g)
    m=rules.new_match();m.mask[a]=true
    rules.game_apply(copy,m)
    check(copy.earnings[2]==3 and g.earnings[2]==0,'water credits provisions and a board copy has an independent ledger')
    rules.game_apply(g,m)
    check(g.earnings[2]==3,'credit the water once when actually removed')

    local direct = rules.new_match()
    local cash = g.earnings[1]
    g.tiles[b] = rules.tile(0)
    direct.mask[b], direct.direct[b] = true, true
    rules.game_apply(g,direct)
    check(g.earnings[1]==cash, 'tool-only clears do not earn match resources')
end

-- The first clear funds the Spring well even when no Coins were matched.
do
    local p={level=0,seed=1,wallet=purse()}
    local c=city.new();island.island_setup(c)
    local cost=island.buildings[island.kinds.well+1].cost
    local g=rules.game_start(0,1);g.won=true;g.moves=0
    local reward=rules.level_reward(g,island.wonders,p)
    check(reward[1]==cost[1] and reward[2]==0 and reward[3]==0,'the first reward shows enough Coins for the well')
    check(rules.progress_reward(p,g,island.wonders) and p.level==1 and p.wallet[1]==reward[1],
        'claim banks the first-clear reward and unlocks the well')
    check(not rules.progress_reward(p,g,island.wonders),'the same win cannot pay twice')
    check(island.island_place_next(c,p.wallet,p.level,0) and island.owned(c,island.kinds.well)==1 and p.wallet[1]==0,
        'the first payout alone buys the Spring well')
    g=rules.game_start(0,999);g.won=true;g.moves=999;g.earnings={cost[1]+8,2,4}
    check(rules.level_reward(g,island.wonders,{level=0})[1]==cost[1]+8,'a larger first win keeps all its Coins')
    check(rules.progress_reward(p,g,island.wonders),'replay resources bank')
    check(p.wallet[1]==cost[1]+8 and p.wallet[2]==2 and p.wallet[3]==4 and p.wallet[4]==1 and p.level==1,
        'replay pays the matched resources exactly')
    local next_win=rules.game_start(1,1);next_win.won=true;next_win.earnings={9,3,0}
    check(rules.level_reward(next_win,island.wonders,p)[1]==9,'the next first clear uses its normal payout')
    check(not rules.progress_reward(p,{won=false},island.wonders),'failed attempt pays nothing')
    local future=rules.game_start(4,887);future.won=true
    check(not rules.progress_reward({level=0},future,island.wonders),'future expedition pays nothing')
end

-- Migration and a completed award use the actual save serializer.
do
    R.island=city.new();island.island_setup(R.island)
    R.wonders=island.wonders
    R.prog={level=16,seed=1,wallet=purse(),story_seen={}}
    local bank=purse(9000,9000,9000,12)
    check(island.island_place_next(R.island,bank,1,0) and island.island_place_next(R.island,bank,6,0),
        'legacy well and cabin already placed')
    check(save.write('relic-resource-legacy',function(s)
        s:int('version',require('journey').version)
        s:int('level',16)
        s:ints('wallet',purse(155,7,2,12))
        R.island:serialize(s)
    end),'write legacy fixture')
    check(save.read('relic-resource-legacy',R.serialize),'load legacy fixture')
    check(R.make_board(6, 93).tool_meter[1] == 0, 'older saves start their unlocked bonus meters empty')
    local w=R.prog.wallet
    local camp=island.wonders[2].cost
    check(w[1]==math.max(155,camp[1]) and w[2]==camp[2] and w[3]==math.max(camp[3],9) and w[4]==16 and island.wonder_count(R.island)==1,
        'legacy saves preserve Gold, placements and combined Supplies; old stars become boards cleared')
    local spare=w[1]-camp[1]
    check(not island.can_spend(R.island,w,16,purse(spare+1)) and (spare==0 or island.can_spend(R.island,w,16,purse(spare))),
        'optional building cannot spend the Gold reserved for the camp')
    check(save.write('relic-resource-v1',function(s)
        s:int('version',require('journey').version)
        s:int('resource_version',1)
        s:int('level',16)
        s:ints('wallet',purse(20,10,22,12))
        R.island:serialize(s)
    end),'write an old wallet with the previous camp price')
    check(save.read('relic-resource-v1',R.serialize),'load the old price')
    w=R.prog.wallet
    check(w[1]==math.max(20,camp[1]) and w[2]==math.max(10,camp[2]) and w[3]==math.max(22,camp[3]) and w[4]==16,
        'migration covers an earned restoration at the new price and preserves other balances')
    check(island.island_place_next(R.island,w,16,0),'migrated camp is affordable')
    -- Relic Rush serializes each meter by name. Reordered tools retain their
    -- own charges, and neither retired bonus can be selected or inherited.
    check(save.write('relic-eight-bonuses', function(s)
        s:int('version', require('journey').version)
        s:int('resource_version', 4)
        s:int('level', 16)
        s:int('bonus_hammer', 4)
        s:int('bonus_dynamite', 7)
        s:int('bonus_shield', 6)
        s:int('bonus_lightning', 12)
        s:int('bonus_plus', 18)
        s:int('bonus_mixer', 18)
        s:int('bonus_hourglass', 18)
        R.island:serialize(s)
    end), 'write the named meters from the eight-bonus version')
    check(save.read('relic-eight-bonuses', R.serialize), 'load a save from the eight-bonus version')
    local charges = R.prog.bonus_charge
    local B = economy.bonuses
    check(charges[B.hammer.tool] == 55 and charges[B.lightning.tool] == 60 and charges[B.shield.tool] == economy.BONUS_THRESHOLD
        and charges[B.hourglass.tool] == economy.BONUS_THRESHOLD and charges[5] == nil,
        'legacy paired meters merge by name, keep their fractions and cap at one use')
    R.g=R.make_board(6,93);R.g.won=true;R.g.moves=4;R.g.earnings={8,3,7};R.test_mode=true
    R.g.tool_meter[1] = R.g.tool_threshold // 2
    R.update_bonus_charges()
    R.stash_completed()
    check(save.write('relic-resource-complete',R.serialize),'write completed award')
    R.prog.completed=nil
    R.prog.bonus_charge=nil
    check(save.read('relic-resource-complete',R.serialize),'load completed award')
    R.resume_completed()
    check(R.overlay==R.OV_RESULT and R.g.earnings[3]==7 and R.g.resource_yields[3]==economy.unlock_of("well"),
        'completed award restores its counts on the correct palette')
    check(R.g.tool_meter[1] == R.g.tool_threshold // 2, 'partial charge survives writing, loading and resuming an award')
    check(rules.progress_reward(R.prog,R.g,R.wonders) and not R.prog.completed,'claim consumes the pending award')
    check(not rules.progress_reward(R.prog,R.g,R.wonders),'loaded award cannot bank twice')

    local market, steps = island.kinds.market, island.kinds.quay_steps
    local _, plot = R.island:find_spot(market, island.island_suggestion(market))
    R.island:add(plot, market, 0)
    local old_site = R.island:snap(vec2(925,2195), steps)
    R.island:add(old_site, steps, 0)
    check(save.write('relic-old-quay', function(s)
        s:int('version', require('journey').version)
        s:int('resource_version', 5)
        s:int('level', 16)
        s:ints('wallet', purse(12, 34, 56, 10))
        s:int('narrative.v1.restore-16', 1)
        s:int('narrative.choice.restore-16', 2)
        R.island:serialize(s)
    end), 'write a pre-repair save after the chapter-one choice')
    check(save.read('relic-old-quay', R.serialize), 'load the pre-repair save')
    w = R.prog.wallet
    check(island.owned(R.island, market) == 1 and island.owned(R.island, steps) == 0
        and w[1] == 12 and w[2] == 34 and w[3] == 56, 'drop the saved staircase and preserve the market and wallet')
    check(R.prog.story_seen['restore-16'] and R.prog.story_choices['restore-16'] == 2,
        'keep the chosen reply and acknowledged scene')
end

-- A full old town with a paid Workshop keeps its whole inventory, and the
-- removal of the old sixth paid step does not move a waiver to a different building.
do
    local c = city.new(); island.island_setup(c)
    local shrub = island.kinds.shrub
    check(c:can_place(c:snap(vec2(925,2195), shrub), shrub, -1), "the former stair site is free for placement")
    c:add(vec2(760,2030), island.kinds.workshop, 0)
    for i=2,160 do c:add(vec2(760+i,2030), island.kinds.shrub, 0) end
    R.island, R.prog = c, {level=10, wallet=purse(12,34,56,10), story_seen={}, bonus_charge={}}
    save.write("relic-epoch-v6", function(s)
        s:int("resource_version", 6)
        s:int("ladder_waived", 1 << 6) -- the old clock tower
    end)
    save.read("relic-epoch-v6", R.serialize_campaign)
    check(c.count==160 and island.owned(c,island.kinds.quay_steps)==0 and island.owned(c,island.kinds.shrub)==159,
        "a full legacy town keeps every other item")
    check(island.waived(c)[island.ladder_position[island.kinds.clock_tower]] and R.prog.wallet[1]==12,
        "the clock tower waiver and the wallet survive migration")
    save.write("relic-epoch-upgraded", function(s) c:serialize(s) end)
    local reload=city.new(); island.island_setup(reload)
    save.read("relic-epoch-upgraded", function(s) reload:serialize(s) end)
    check(reload.count==160 and island.owned(reload,island.kinds.quay_steps)==0,
        "the legacy inventory round-trips without reintroducing the staircase")
end
