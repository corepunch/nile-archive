local rules=require("rules")
local economy=require("economy")
local island=require("island")
local R=require("state")
require("main")
-- A plain cell whose six neighbours are all playable, for tool checks.
local function open_cell(g)
    for i=0,rules.CELLS-1 do
        local ok=rules.game_cell_active(g,i) and g.stone_hp[i]==0
        for d=0,5 do
            local j=rules.hex_neighbor(i,d)
            ok=ok and j>=0 and rules.game_cell_active(g,j) and g.stone_hp[j]==0
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
    local bank=purse(5000,5000,5000,90)
    local locked=R.make_board(1,19)
    local match=rules.new_match()
    check(next(locked.tool_meter) == nil, 'all bonus sockets require confirmed construction')
    check(not rules.game_tool(locked,1,rules.hex_center(),match),'locked dynamite cannot be used')
    check(locked.backdrop==rules.level_of(locked).background,'with nothing restored the board keeps its own scene')
    local c, well = R.island, island.kinds.well
    local fits, spot = c:find_spot(well,island.island_suggestion(well))
    check(fits,'well fits the first region')
    c:begin_place(well, spot)
    check(R.make_board(1,19).resource_yields[3]==nil,'a placement preview cannot unlock water')
    c:cancel()
    check(R.make_board(1,19).resource_yields[3]==nil,'cancelling keeps water locked')
    check(island.island_place_next(c,bank,1,0),'confirm the well')
    check(R.make_board(1,19).resource_yields[3]==economy.unlock_of("well"),'water follows construction')
    check(not island.island_place_next(c,bank,3,0),'the hut waits for clear four')
    check(island.island_place_next(c,bank,4,0),'confirm the hut')
    local first = R.make_board(4,19)
    check(first.bonus_debut == economy.bonuses.hammer and first.tool_meter[1]==0,'the hut debuts Hammer')
    local workshop = island.kinds.workshop
    fits,spot = c:find_spot(workshop,island.island_suggestion(workshop))
    check(fits,'sawmill has a placement spot')
    c:begin_place(workshop,spot)
    check(R.make_board(7,19).resource_yields[4]==nil,'timber waits for confirmation')
    c:cancel()
    local steps, price = island.kinds.quay_steps, island.buildings[workshop+1].cost
    check(island.owned(c,steps)==0 and not island.can_buy(c,bank,7,steps),'the fixed quay stays off sale')
    local balance=purse(table.unpack(bank))
    check(island.island_place_next(c,bank,7,0),'confirm the sawmill')
    for slot=1,3 do check(bank[slot]==balance[slot]-price[slot],'one price pays for the mill and quay') end
    local quay=c.items[c.count]
    check(quay.type==steps and (quay.pos-c:snap(island.island_suggestion(steps),steps)):len()<.01,
        'repair occupies the registered quay footprint')
    c:begin_move(c.count-1)
    check(c.placing<0,'the repaired quay stays fixed')
    island.purchase_confirmed(c,workshop,0)
    check(island.owned(c,steps)==1,'reprocessing the repair is idempotent')
    check(island.island_place_next(c,bank,10,0),'confirm the village')
    local previous=R.g
    R.g,first.tool_meter[1]=first,first.tool_threshold//2
    R.refresh_board_bonuses()
    R.g=previous
    check(first.tool_slots[1]==economy.bonuses.bomb and first.bonus==economy.bonuses.bomb
        and first.tool_meter[1]==first.tool_threshold//2,'a parked board replaces Hammer and preserves its charge')
    check(island.island_place_next(c,bank,11,0),'confirm the farm')
    for level=0,rules.LEVELS-1 do
        local g=R.make_board(level,19)
        check(g.spawn_kinds==nil and rules.COLORS==5,'every expedition keeps its five kinds')
        local charge_kinds=0
        for _,piece in pairs(g.resource_yields) do if piece.tool then charge_kinds=charge_kinds+1 end end
        check(charge_kinds==(g.bonus and 1 or 0),'only the selected family spawns')
        local spec=rules.level_of(g)
        if spec.story_piece then check(not g.resource_yields[spec.goal_kind],'story pieces keep their slot') end
    end
    check(economy.board_backdrop(rules.levels[14],14,{gateway=true})==2,'port opens the temple backdrop')
end

-- The landing opens with Cradle of Rome's pool. Its leaf, flower and amphora
-- use the normal scoring path and pay nothing; only the two coins pay.
do
    local g = rules.game_start(0,123)
    local keys = {}
    for kind = 0, rules.COLORS - 1 do keys[kind + 1] = economy.pieces[kind].key end
    check(table.concat(keys,' ')=='coin silver-coin leaf flower amphora',"the base pool is Cradle of Rome's first level")
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

-- Roman finds change the appearance and payout of the same slot. The
-- Courtyard gates its whole sequence and the Temple owns the final emerald.
do
    local finds = {
        {2, "coin", 5}, {5, "coin", 5},
        {18, "helmet", 6}, {20, "ring", 7}, {22, "scarab", 8},
        {25, "sandal", 9}, {26, "harp", 10}, {30, "emerald", 11},
    }
    for _, find in ipairs(finds) do
        local number, key, amount = table.unpack(find)
        local g = rules.game_start(number - 1, 73, {amphitheater=true, archive=true, beached_ship=true,
            aviary=true, museum=true, fountain=true})
        local piece = g.resource_yields[0]
        check(piece.key == key and piece.slot == economy.GOLD, "the coin slot uses " .. key)
        local m = rules.new_match()
        for cell=0,rules.CELLS-1 do
            if rules.game_cell_active(g,cell) then
                g.chain[cell],g.ice[cell],g.stone_hp[cell] = 0,0,0
                g.tiles[cell] = rules.tile(0)
                m.mask[cell] = true
                break
            end
        end
        rules.game_apply(g,m)
        check(g.earnings[economy.GOLD] == amount,key .. " banks its listed Coins")
    end
    check(rules.game_start(27,73,{}).resource_yields[0].key == "coin","each find waits for its restoration")
    check(rules.game_start(27,73,{amphitheater=true}).resource_yields[0].key == "helmet","the Courtyard alone keeps helmets")
    check(rules.game_start(29,73,{gateway=true, museum=true}).resource_yields[0].key == "harp","the Temple gates emeralds")
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

-- Late restorations charge the real wallet and change only subsequent boards.
do
    local c=R.island
    local wallet=purse(100000,100000,100000,90)   -- more than every fitted price together
    for z=1,5 do c:unlock(z,wallet) end
    for i=6,#island.ladder do
        local unlock=island.ladder[i].unlock
        local building=island.buildings[island.ladder[i].kind+1]
        local before=R.make_board(unlock.first_level-1,41)
        if unlock.bonus then
            local bonus = unlock.bonus
            check(before.tool_slots[bonus.tool].rank == 1
                and (before.tool_meter[bonus.tool] ~= nil) == (bonus.rank == 2),
                'construction unlocks a slot or raises its current rank')
        end
        if unlock.kind then check(before.resource_yields[unlock.kind]~=unlock, unlock.name .. ' is locked until construction') end
        local cost=building.cost
        local balance=purse(table.unpack(wallet))
        check(island.island_place_next(c,wallet,unlock.after,0),'confirm ' .. building.name)
        for slot=1,3 do check(wallet[slot]==balance[slot]-cost[slot],'restoration spends the listed price') end
        local g=R.make_board(unlock.first_level-1,41)
        local cell=rules.hex_center()
        if not rules.game_cell_active(g,cell) then
            for n=0,rules.CELLS-1 do
                if rules.game_cell_active(g,n) then cell=n; break end
            end
        end
        g.chain[cell],g.ice[cell],g.stone_hp[cell]=0,0,0
        local m=rules.new_match()
        if unlock.bonus then
            check(g.bonus_debut == unlock.bonus and g.tool_meter[unlock.bonus.tool] == 0, 'newly restored bonus gets its first board')
        end
        if unlock.kind then
            check(g.resource_yields[unlock.kind]==unlock,'opening uses ' .. unlock.name)
            g.tiles[cell]=rules.tile(unlock.kind)
            m.mask[cell]=true
            rules.game_apply(g,m)
            check(g.earnings[unlock.slot]==unlock.amount,unlock.name .. ' pays its configured yield')
        end
    end
    local final=R.make_board(29,41)
    check(final.resource_yields[0]==economy.unlock_of("fountain") and final.resource_yields[1]==economy.unlock_of("water_mill") and
          final.resource_yields[3]==economy.unlock_of("gateway") and final.resource_yields[4]==economy.unlock_of("trading_post"),
          'the last board combines all current chip upgrades')
    local seen = {}
    for seed = 1, #economy.bonus_slots do
        local g = R.make_board(29, seed)
        seen[g.bonus] = true
        for tool, bonus in ipairs(g.tool_slots) do
            check(g.tool_meter[tool] == 0 and bonus.rank == 2, 'all four upgraded sockets remain available across boards')
        end
    end
    for _, bonus in ipairs(final.tool_slots) do check(seen[bonus], 'seeded rotation includes ' .. bonus.name) end
end

local function charge(g, bonus)
    g.tools[bonus.tool], g.tool_meter[bonus.tool] = 1, g.tool_threshold
    return bonus.tool - 1
end

-- Hammer and Dynamite share a meter, including a charged use earned before the upgrade.
do
    local B = economy.bonuses
    local restored = {log_cabin=true, bonus_charge={}}
    local g, m = rules.game_start(4, 73, restored), rules.new_match()
    local kind = rules.level_of(g).goal_kind == economy.SPECIAL_KIND and economy.SPECIAL_FALLBACK or economy.SPECIAL_KIND
    check(g.bonus_debut == B.hammer and g.resource_yields[kind] == B.hammer, 'the Camp debuts Hammer')
    local line = require('support').open_line(rules, g)
    for _ = 1, 3 do
        for _, cell in ipairs(line) do
            g.chain[cell], g.ice[cell], g.stone_hp[cell] = 0, 0, 0
            g.tiles[cell] = rules.tile(kind)
        end
        rules.game_matches(g, m, -1)
        rules.game_apply(g, m)
    end
    local tool = B.hammer.tool
    check(g.tools[tool] == 1 and g.tool_meter[tool] == g.tool_threshold, 'extra matches cannot bank a second use')
    local copy = rules.game_copy(g)
    copy.tools[tool], copy.tool_meter[tool] = 0, 0
    check(g.tools[tool] == 1 and g.tool_meter[tool] == g.tool_threshold, 'preview copies preserve the live meters')
    R.g, R.prog, R.test_mode = g, {bonus_charge=restored.bonus_charge}, true
    R.update_bonus_charges()
    restored.camp = true
    local later = rules.game_start(29, 1, restored)
    check(later.tool_slots[tool] == B.bomb and later.tools[tool] == 1
        and later.tool_meter[tool] == g.tool_threshold, 'the stored Hammer use becomes a Dynamite use')
    local center = open_cell(later)
    check(rules.game_tool(later, tool - 1, center, m) and m.hits == 7
        and later.moves == rules.level_of(later).moves, 'Dynamite blasts seven cells without spending a move')
    R.g = later
    R.update_bonus_charges()
    check(rules.game_start(29, 1, restored).tool_meter[tool] == 0, 'spending a charge clears it across boards')
end

-- Compare targeted previews with the actual hit mask, and verify instant tools on live boards.
do
    local B = economy.bonuses
    for _, key in ipairs{"shield","star"} do
        local bonus = B[key]
        local g = rules.game_start(29,3,{clock_tower=true,temple=true})
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
        local g, m = rules.game_start(29,3,{lighthouse=true,log_cabin=true}),rules.new_match()
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
        local g = rules.game_start(29,3,{map_room=true,lodge=true,observatory=key=="mixer"})
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
    for kind = 0, 3 do
        local ok, spot = c:find_spot(kind, island.island_suggestion(kind))
        c:begin_place(kind, spot)
        check(ok and c:confirm(bank, 0).result == city.BUILT, 'an old save owns its first four restorations')
    end
    check(not island.can_buy(c, bank, 13, 4), 'without a waiver the courtyard waits for the earlier ladder')
    island.waive_passed(c, 13)
    island.waived(c)[island.ladder_position[island.kinds.log_cabin]] = true -- this pre-epoch save had already passed the cabin
    local steps = island.kinds.quay_steps
    local can_restore, site = c:find_spot(steps, island.island_suggestion(steps))
    check(can_restore, 'the migration can grant the earlier quay repair')
    c:add(site, steps, 0)
    check(island.next_step(c, 13) == 4 and island.can_buy(c, bank, 13, 4), 'the waived save builds its courtyard')
    local reserved, courtyard = island.reserved_cost(c, 13), island.buildings[5].cost
    check(reserved:covers(courtyard) and courtyard:covers(reserved), 'waived restorations are not reserved')
    local cabin = island.kinds.log_cabin
    check(island.can_buy(c, bank, 13, cabin) and island.ladder_blocked(c, 13, cabin) == false,
        'a waived restoration stays on sale')
    R.island, R.prog = c, {level=13, wallet=purse(1, 2, 3), story_seen={}, bonus_charge={}}
    save.write("relic-ladder-waived", R.serialize_campaign)
    local fresh = city.new(); island.island_setup(fresh)
    R.island = fresh
    save.read("relic-ladder-waived", R.serialize_campaign)
    local waived = island.waived(fresh)
    check(waived[2] and waived[6] and waived[7] and waived[8] and not waived[9] and not waived[10],
        'the waived positions survive a save')
    local wallet = R.prog.wallet
    check(wallet[1] == 1 and wallet[2] == 2 and wallet[3] == 3, 'reading a current save leaves the wallet alone')
    -- A version 3 save read at the same point waives them itself.
    local old = city.new(); island.island_setup(old)
    for z = 1, 5 do old:unlock(z, bank) end
    for kind = 0, 3 do
        local _, spot = old:find_spot(kind, island.island_suggestion(kind))
        old:begin_place(kind, spot); old:confirm(bank, 0)
    end
    save.write("relic-ladder-v3", function(s) s:int("resource_version", 3) end)
    R.island = old
    save.read("relic-ladder-v3", R.serialize_campaign)
    check(island.waived(old)[2] and island.next_step(old, 13) == 4, 'a version 3 save waives the passed restorations')
    R.island, R.prog = saved_island, saved_prog
end

-- Clear regular pieces through the real match resolver. A blocker absorbs
-- the first hit and the preview solver cannot alter the live ledger.
do
    local g=R.make_board(4,19)
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

-- Story progress earns building access. Players can replay to pay the price.
do
    local p={level=0,seed=1,wallet=purse()}
    local c=city.new();island.island_setup(c)
    local g=rules.game_start(0,1);g.won=true;g.moves=0
    check(rules.progress_reward(p,g,island.wonders) and p.level==1,'first clear unlocks the camp')
    check(not p.wallet:covers(island.reserved_cost(c,p.level)) and not island.island_place_next(c,p.wallet,p.level,0),
        'a clear without income cannot buy the camp')
    check(not rules.progress_reward(p,g,island.wonders),'the same win cannot pay twice')
    local camp=island.wonders[1].cost
    g=rules.game_start(0,999);g.won=true;g.moves=999;g.earnings={camp[1]+8,camp[2]+2,camp[3]+4}
    check(rules.progress_reward(p,g,island.wonders),'replay resources bank')
    check(p.wallet[1]==camp[1]+8 and p.wallet[2]==camp[2]+2 and p.wallet[3]==camp[3]+4 and p.wallet[4]==1 and p.level==1,
        'replay pays the matched resources exactly')
    check(island.island_place_next(c,p.wallet,p.level,0) and island.wonder_count(c)==1,'replay can fund the camp')
    check(not rules.progress_reward(p,{won=false},island.wonders),'failed attempt pays nothing')
    local future=rules.game_start(4,887);future.won=true
    check(not rules.progress_reward({level=0},future,island.wonders),'future expedition pays nothing')
end

-- Migration and a completed award use the actual save serializer.
do
    R.island=city.new();island.island_setup(R.island)
    R.wonders=island.wonders
    R.prog={level=4,seed=1,wallet=purse(),story_seen={}}
    local bank=purse(700,90,90,12)
    check(island.island_place_next(R.island,bank,4,0),'legacy camp already placed')
    check(save.write('relic-resource-legacy',function(s)
        s:int('version',require('journey').version)
        s:int('level',4)
        s:ints('wallet',purse(155,7,2,12))
        R.island:serialize(s)
    end),'write legacy fixture')
    check(save.read('relic-resource-legacy',R.serialize),'load legacy fixture')
    check(R.make_board(4, 93).tool_meter[1] == nil, 'older saves start their unlocked bonus meters empty')
    local w=R.prog.wallet
    local well=island.wonders[2].cost[1]
    check(w[1]==math.max(155,well) and w[2]==island.wonders[2].cost[2] and w[3]==9 and w[4]==4 and island.wonder_count(R.island)==1,
        'legacy saves preserve Gold, placements and combined Supplies; old stars become boards cleared')
    local spare=w[1]-well
    check(not island.can_spend(R.island,w,4,purse(spare+1)) and (spare==0 or island.can_spend(R.island,w,4,purse(spare))),
        'optional building cannot spend the Gold reserved for the well')
    check(save.write('relic-resource-v1',function(s)
        s:int('version',require('journey').version)
        s:int('resource_version',1)
        s:int('level',4)
        s:ints('wallet',purse(20,10,22,12))
        R.island:serialize(s)
    end),'write an old wallet with the previous well price')
    check(save.read('relic-resource-v1',R.serialize),'load the old price')
    w=R.prog.wallet
    check(w[1]==math.max(20,well) and w[2]==math.max(10,island.wonders[2].cost[2]) and w[3]==22 and w[4]==4,
        'migration covers an earned restoration at the new price and preserves other balances')
    check(island.island_place_next(R.island,w,4,0),'migrated well is affordable')
    -- Relic Rush serializes each meter by name. Reordered tools retain their
    -- own charges, and neither retired bonus can be selected or inherited.
    check(save.write('relic-eight-bonuses', function(s)
        s:int('version', require('journey').version)
        s:int('resource_version', 4)
        s:int('level', 4)
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
    check(charges[B.hammer.tool] == 22 and charges[B.lightning.tool] == 24 and charges[B.shield.tool] == economy.BONUS_THRESHOLD
        and charges[B.hourglass.tool] == economy.BONUS_THRESHOLD and charges[5] == nil,
        'legacy paired meters merge by name, keep their fractions and cap at one use')
    R.g=R.make_board(4,93);R.g.won=true;R.g.moves=4;R.g.earnings={8,3,7};R.test_mode=true
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
    check(save.write('relic-old-quay', function(s)
        s:int('version', require('journey').version)
        s:int('resource_version', 5)
        s:int('level', 10)
        s:ints('wallet', purse(12, 34, 56, 10))
        s:int('narrative.v1.after-10', 1)
        s:int('narrative.choice.after-10', 2)
        R.island:serialize(s)
    end), 'write a pre-repair save after the chapter-one choice')
    check(save.read('relic-old-quay', R.serialize), 'load the pre-repair save')
    w = R.prog.wallet
    check(island.owned(R.island, market) == 1 and island.owned(R.island, steps) == 1
        and w[1] == 12 and w[2] == 34 and w[3] == 56, 'keep the market and restore the steps at no expense')
    check(R.prog.story_seen['after-10'] and R.prog.story_choices['after-10'] == 2,
        'keep the chosen reply and acknowledged scene')
end

-- A full old town with a paid Workshop keeps its whole inventory, and the
-- removal of the old sixth paid step does not move a waiver to a different building.
do
    local c = city.new(); island.island_setup(c)
    c:add(vec2(760,2030), island.kinds.workshop, 0)
    for i=2,160 do c:add(vec2(760+i,2030), island.kinds.shrub, 0) end
    R.island, R.prog = c, {level=10, wallet=purse(12,34,56,10), story_seen={}, bonus_charge={}}
    save.write("relic-epoch-v6", function(s)
        s:int("resource_version", 6)
        s:int("ladder_waived", 1 << 6) -- the old clock tower
    end)
    save.read("relic-epoch-v6", R.serialize_campaign)
    check(c.count==161 and island.owned(c,island.kinds.quay_steps)==1 and island.owned(c,island.kinds.shrub)==159,
        "a full legacy town keeps every item and receives its original quay")
    check(island.waived(c)[island.ladder_position[island.kinds.clock_tower]] and R.prog.wallet[1]==12,
        "the clock tower waiver and the wallet survive migration")
    save.write("relic-epoch-upgraded", function(s) c:serialize(s) end)
    local reload=city.new(); island.island_setup(reload)
    save.read("relic-epoch-upgraded", function(s) reload:serialize(s) end)
    check(reload.count==161 and island.owned(reload,island.kinds.quay_steps)==1,
        "the granted landmark round-trips with a full town")
end
