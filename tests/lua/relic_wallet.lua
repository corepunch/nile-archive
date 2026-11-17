local rules=require("rules")
local economy=require("economy")
local island=require("island")
local R=require("state")
require("main")
-- Lives regenerate offline, stop at five, and charge a failed attempt once.
do
    local p={lives=5,life_at=0}
    local g={lost=true}
    check(rules.lose_life(p,g,1000) and p.lives==4 and p.life_at==2800,'first failed attempt costs one life')
    check(not rules.lose_life(p,g,1001) and p.lives==4,'failed board charges once')
    check(rules.lose_life(p,{lost=true},1010) and p.lives==3 and p.life_at==2800,'timer does not restart when another life is spent')
    rules.refill_lives(p,2799);check(p.lives==3,'refill waits for the full interval')
    rules.refill_lives(p,2800);check(p.lives==4 and p.life_at==4600,'one interval restores one life')
    rules.refill_lives(p,10000);check(p.lives==5 and p.life_at==0,'offline refill caps at five')
    check(not rules.lose_life(p,{lost=false},10000),'winning boards cost no life')
end

-- Happiness is derived from placed items, and only optional purchases earn Gold.
do
    local town={items={{type=0},{type=37}}}
    local p={level=1,seed=1,wallet=purse(0,0,0,3)}
    local g=rules.game_start(0,99);g.won=true;g.moves=0
    check(island.happiness(town)==5,'wonder and decoration Happiness add together')
    local reward=rules.reward_breakdown(g,island.wonders,p,town)
    check(reward.happiness==1 and reward.total[1]==1,'Happiness Gold is itemized as part of the claim')
    check(rules.progress_reward(p,g,island.wonders,town) and p.wallet[1]==1,'a replay banks Happiness Gold')
    check(not rules.progress_reward(p,g,island.wonders,town) and p.wallet[1]==1,'cannot claim Happiness twice')
    for _=1,12 do town.items[#town.items+1]={type=37} end
    check(island.happiness(town)==17 and island.happiness_gold(town)==10,'Happiness continues above the Gold cap')
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
    check(island.island_place_next(R.island,bank,4,0),'place the camp before the well')
    local c=R.island
    local first = R.make_board(1,19)
    check(first.bonus_debut == economy.bonuses.hammer and first.tool_meter[1] == 0 and first.tools[1] == 0,
        'the camp introduces Hammer pieces and an empty Blast slot on expedition 2')
    local fits,spot=c:find_spot(economy.WELL_KIND,island.island_suggestion(economy.WELL_KIND))
    check(fits,'well fits first region')
    c:begin_place(economy.WELL_KIND,spot)
    check(R.make_board(4,19).resource_yields[3].key=='timber','placement preview does not unlock water')
    c:cancel()
    check(R.make_board(5,19).resource_yields[3].key=='timber','cancel still leaves the timber palette')
    check(island.island_place_next(c,bank,4,0),'confirm the earned well')
    check(not island.island_place_next(c,bank,6,0),'the next ladder restoration waits for clear 7')
    check(island.island_place_next(c,bank,7,0) and R.make_board(7,19).bonus_debut == economy.bonuses.dynamite,
        "the trapper's cabin upgrades Blast to Dynamite before the workshop")
    local previous_board = R.g
    first.tool_meter[1] = first.tool_threshold // 2
    R.g = first
    R.refresh_board_bonuses()
    R.g = previous_board
    check(first.tool_slots[1] == economy.bonuses.dynamite and first.bonus == economy.bonuses.dynamite
        and first.tool_meter[1] == first.tool_threshold // 2 and first.tools[1] == 0,
        'resuming an existing board upgrades the slot and its board gem without resetting the meter')
    local workshop=economy.WORKSHOP_KIND
    fits,spot=c:find_spot(workshop,island.island_suggestion(workshop))
    check(fits,'workshop has a placement spot')
    c:begin_place(workshop,spot)
    check(R.make_board(7,19).resource_yields[4].key=='stone','workshop preview does not unlock cut blocks')
    c:cancel()
    check(R.make_board(8,19).resource_yields[4].key=='stone','cancel preserves the stone palette')
    check(island.island_place_next(c,bank,7,0),'confirm the earned workshop')
    local before_market = R.make_board(9,19)
    check(before_market.resource_yields[1] ~= economy.unlock_of("market"),
        'rations are locked before restoring the market')
    check(not island.can_buy(c,bank,9,island.ladder[6].kind),'the market waits for the water mill')
    check(island.island_place_next(c,bank,9,0) and island.island_place_next(c,bank,9,0),
        'confirm the water mill and then the earned market')
    for level=0,rules.LEVELS-1 do
        local g=R.make_board(level,19)
        local spec=rules.level_of(g)
        local water=g.resource_yields[3]==economy.unlock_of("well")
        local blocks=g.resource_yields[4]==economy.unlock_of("workshop")
        local rations=g.resource_yields[1]==economy.unlock_of("market")
        check(water==(level>=4 and level~=8), 'water persists after its introduction except in the supply crate slot')
        check(blocks==(level>=7) and rations==(level>=9), 'workshop and market pieces stay unlocked')
        check(g.backdrop==(level>=1 and 1 or spec.background),'the latest restoration in force picks the lagoon')
        check(g.spawn_kinds==nil and rules.COLORS==6,'every expedition spawns all six kinds')
        local charge_kinds = 0
        for _, piece in pairs(g.resource_yields) do
            if piece.tool then charge_kinds = charge_kinds + 1 end
        end
        check(charge_kinds == (g.bonus and 1 or 0), 'at most one kind charges a bonus')
        if spec.story_piece then
            local piece = g.resource_yields[spec.goal_kind]
            check(not piece, 'story items neither pay into the wallet nor charge a bonus')
        end
        for kind in pairs(spec.score_pieces or {}) do
            local piece = g.resource_yields[kind]
            check(kind ~= spec.goal_kind and kind ~= spec.omit_kind and not (piece and piece.slot),
                'score pieces use their own active slot and never pay the wallet')
        end
    end

    check(R.make_board(13,19).backdrop==1,'the courtyard scene waits for the courtyard')
    local courtyard={camp=true,well=true,workshop=true,market=true,gateway=true}
    check(economy.board_backdrop(rules.levels[14],14,courtyard)==2 and economy.board_backdrop(rules.levels[13],13,courtyard)==1,
        'the courtyard brings the temple to boards from its first expedition')

    -- Act on the same first hint a player sees. The match must stock the town
    -- at its new rate while clearing the work site in the same move.
    for _, opening in ipairs{{4, economy.PROVISIONS, 9}, {8, economy.SUPPLIES, 15}} do
        local level, currency, expected = table.unpack(opening)
        local g = R.make_board(level, 73)
        local ok, a, b = rules.game_hint(g)
        check(ok and rules.game_swap(g, a, b, match), 'the resource opening offers a legal swap')
        local plaques = g.oil_left
        rules.game_apply(g, match)
        check(g.earnings[currency] == expected and g.oil_left < plaques,
            'the opening earns the upgraded resource and clears a plaque')
    end
end

-- The Shore Marker board has two different score pieces. A matching line of
-- either uses the normal scoring path, while a green apple still earns Food.
for _, entry in ipairs{{6, 1, 'flower'}, {6, 5, 'leaf'}, {1, 2, 'apple'}} do
    local level, kind, name = table.unpack(entry)
    local g = rules.game_start(level-1,123)
    local spec = rules.level_of(g)
    local yield = g.resource_yields[kind]
    local key = yield and yield.key or spec.score_pieces and spec.score_pieces[kind]
    check(key==name,'the selected expedition spawns ' .. name)
    local present = false
    for i=0,rules.CELLS-1 do present = present or g.tiles[i].kind == kind end
    check(present,'the opening contains ' .. name)
    for r=0,2 do g.tiles[rules.hex_index(-2,r)] = rules.tile(kind) end
    local m = rules.new_match()
    rules.game_matches(g,m,-1)
    check(m.hits >= 3,'a line of ' .. name .. ' matches')
    rules.game_apply(g,m)
    check(g.score > 0 and g.earnings[economy.GOLD] == 0 and g.earnings[economy.SUPPLIES] == 0
        and g.earnings[economy.PROVISIONS] == (yield and m.hits or 0),
        'apple matches pay Food and leaf or flower matches pay score only')
end

-- Roman finds change the appearance and payout of the same slot. The
-- Courtyard gates its whole sequence and the Temple owns the final emerald.
do
    local finds = {
        {2, "coin", 4}, {3, "silver-coin", 3}, {5, "coin", 4},
        {14, "helmet", 6}, {18, "ring", 7}, {21, "scarab", 8},
        {25, "sandal", 9}, {28, "harp", 10}, {30, "emerald", 11},
    }
    for _, find in ipairs(finds) do
        local number, key, amount = table.unpack(find)
        local g = rules.game_start(number - 1, 73, {gateway=true, trading_post=true, beached_ship=true,
            aviary=true, museum=true, temple=true})
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
    check(rules.game_start(27,73,{gateway=true}).resource_yields[0].key == "helmet","the Courtyard alone keeps helmets")
    check(rules.game_start(29,73,{gateway=true, museum=true}).resource_yields[0].key == "harp","the Temple gates emeralds")
end

-- Like Cradle of Rome's ladder, each new piece pays toward the next purchase.
for n, unlock in ipairs(economy.unlocks) do
    local following=island.ladder[n+1]
    local next_building=following and island.buildings[following.kind+1]
    if unlock.slot and next_building then
        check(next_building.cost[unlock.slot]>0,unlock.name .. ' helps pay for ' .. next_building.name)
    end
end

-- Late restorations charge the real wallet and change only subsequent boards.
do
    local c=R.island
    local wallet=purse(5000,5000,5000,90)
    for z=1,5 do c:unlock(z,wallet) end
    for i=7,#economy.unlocks do
        local unlock=economy.unlocks[i]
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
    check(final.resource_yields[0]==economy.unlock_of("temple") and final.resource_yields[1]==economy.unlock_of("lodge") and
          final.resource_yields[3]==economy.unlock_of("fountain") and final.resource_yields[4]==economy.unlock_of("archive"),
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

-- The Shutter Gear advances the story while the market's rations make their debut.
do
    local g, m = R.make_board(9, 73), rules.new_match()
    check(g.bonus == nil and g.resource_yields[1] == economy.unlock_of("market") and not g.resource_yields[g.goal_kind],
        'expedition 10 keeps both the story gear slot and newly unlocked ration jars')
    for _, cell in ipairs{rules.hex_index(0, -1), rules.hex_index(0, 0), rules.hex_index(0, 1)} do
        g.chain[cell], g.ice[cell], g.stone_hp[cell] = 0, 0, 0
        g.tiles[cell] = rules.tile(g.goal_kind)
    end
    rules.game_matches(g, m, -1)
    rules.game_apply(g, m)
    check(g.relics >= 3 and not m.bonus_charge_by_cell, 'a shutter gear match counts only toward the quest')
end

local function charge(g, bonus)
    g.tools[bonus.tool], g.tool_meter[bonus.tool] = 1, g.tool_threshold
    return bonus.tool - 1
end

-- Hammer and Dynamite share a meter, including a charged use earned before the upgrade.
do
    local B = economy.bonuses
    local restored = {camp=true, bonus_charge={}}
    local g, m = rules.game_start(1, 73, restored), rules.new_match()
    local kind = rules.level_of(g).goal_kind == 5 and 1 or 5
    check(g.bonus_debut == B.hammer and g.resource_yields[kind] == B.hammer, 'the Camp debuts Hammer')
    local line = {rules.hex_index(0, -1), rules.hex_index(0, 0), rules.hex_index(0, 1)}
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
    restored.log_cabin = true
    local later = rules.game_start(29, 1, restored)
    check(later.tool_slots[tool] == B.dynamite and later.tools[tool] == 1
        and later.tool_meter[tool] == g.tool_threshold, 'the stored Hammer use becomes a Dynamite use')
    local center = rules.hex_center()
    check(rules.game_tool(later, tool - 1, center, m) and m.hits == 7
        and later.moves == rules.level_of(later).moves, 'Dynamite blasts seven cells without spending a move')
    R.g = later
    R.update_bonus_charges()
    check(rules.game_start(29, 1, restored).tool_meter[tool] == 0, 'spending a charge clears it across boards')
end

-- Lightning previews its row and extra strikes without advancing the board seed.
do
    local B = economy.bonuses
    local restored = {amphitheater=true}
    local shield = rules.game_start(29, 3, restored)
    local tool = charge(shield, B.shield)
    local center = rules.hex_center()
    local row = rules.game_tool_area(shield, tool, center)
    check(row[center] and row[rules.hex_neighbor(center, 0)], 'Shield targets the selected row')
    for cell in pairs(row) do check(rules.hex_r(cell) == rules.hex_r(center), 'Shield stays on its axis') end
    restored.lighthouse = true
    local storm, m = rules.game_start(29, 3, restored), rules.new_match()
    charge(storm, B.lightning)
    local rng = storm.rng
    local preview = rules.game_tool_area(storm, tool, center)
    check(storm.rng == rng and storm.tools[tool + 1] == 1, 'previewing Lightning keeps the seed and charge')
    check(not rules.game_tool(storm, tool, nil, m), 'Lightning still needs a target')
    check(rules.game_tool(storm, tool, center, m) and m.hits == 20, 'Lightning strikes twenty distinct cells')
    for cell in pairs(row) do check(m.mask[cell], 'Lightning preserves every cell in the selected row') end
    for cell in pairs(preview) do check(m.mask[cell], 'Lightning hits exactly its previewed cells') end
end

-- Star II pierces one layer, while an extra layer still protects its gem.
for rank = 1, 2 do
    local B = economy.bonuses
    local restored = {clock_tower=true, observatory=rank == 2}
    local g, m = rules.game_start(29, 3, restored), rules.new_match()
    local center = rules.hex_center()
    local a, b = rules.hex_neighbor(center, 0), rules.hex_neighbor(center, 1)
    for _, cell in ipairs{center, a, b} do
        g.tiles[cell], g.chain[cell], g.ice[cell], g.stone_hp[cell] = rules.tile(2), 0, 0, 0
    end
    g.chain[a], g.ice[b] = 1, 2
    local tool = charge(g, rank == 2 and B["star-ii"] or B.star)
    check(rules.game_tool(g, tool, center, m) and m.mask[a] and m.mask[b], 'both ranks target protected copies')
    rules.game_apply(g, m)
    check(g.chain[a] == 0 and g.tiles[a].kind == (rank == 2 and -1 or 2),
        'Star II clears the gem once its last lock is gone')
    check(g.ice[b] == 1 and g.tiles[b].kind == 2, 'a second layer still protects the gem')
end

-- Plus gives exactly a quarter or half a charge to each other unlocked slot.
for rank = 1, 2 do
    local B = economy.bonuses
    local g, m = rules.game_start(29, 3, {camp=true, clock_tower=true, map_room=true, museum=rank == 2}), rules.new_match()
    local tool = charge(g, rank == 2 and B["plus-ii"] or B.plus)
    local moves = g.moves
    g.tool_meter[B.hammer.tool] = g.tool_threshold - 5
    local used, still = rules.game_tool(g, tool, nil, m)
    check(used and still == "charge" and g.tool_meter[B.hammer.tool] == g.tool_threshold and g.tools[B.hammer.tool] == 1
        and g.tool_meter[B.star.tool] == g.tool_threshold // (rank == 1 and 4 or 2)
        and g.tool_meter[tool + 1] == 0 and g.tool_meter[B.shield.tool] == nil and g.moves == moves,
        'Plus tops up other unlocked slots at its own rank without spending a move')
    for i in pairs(g.tool_meter) do g.tools[i], g.tool_meter[i] = 1, g.tool_threshold end
    check(not rules.game_tool(g, tool, nil, m) and g.tools[tool + 1] == 1,
        'Plus keeps its use when there is nothing to charge')
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
    check(island.next_step(c, 13) == 4 and island.can_buy(c, bank, 13, 4), 'the waived save builds its courtyard')
    local reserved, courtyard = island.reserved_cost(c, 13), island.buildings[5].cost
    check(reserved:covers(courtyard) and courtyard:covers(reserved), 'waived restorations are not reserved')
    local cabin = island.ladder[3].kind
    check(island.can_buy(c, bank, 13, cabin) and island.ladder_blocked(c, 13, cabin) == false,
        'a waived restoration stays on sale')
    R.island, R.prog = c, {level=13, wallet=purse(1, 2, 3), story_seen={}, bonus_charge={}}
    save.write("relic-ladder-waived", R.serialize_campaign)
    local fresh = city.new(); island.island_setup(fresh)
    R.island = fresh
    save.read("relic-ladder-waived", R.serialize_campaign)
    local waived = island.waived(fresh)
    check(waived[3] and waived[5] and waived[7] and waived[8] and not waived[9] and not waived[11],
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
    check(island.waived(old)[3] and island.next_step(old, 13) == 4, 'a version 3 save waives the passed restorations')
    R.island, R.prog = saved_island, saved_prog
end

-- Clear regular pieces through the real match resolver. A blocker absorbs
-- the first hit and the preview solver cannot alter the live ledger.
do
    local g=R.make_board(4,19)
    local a,b,c=rules.hex_index(-1,0),rules.hex_index(0,0),rules.hex_index(1,0)
    g.chain[a],g.chain[b],g.chain[c]=1,0,0
    g.tiles[a],g.tiles[b],g.tiles[c]=rules.tile(3),rules.tile(0),rules.tile(4)
    local m=rules.new_match()
    m.mask[a],m.mask[b],m.mask[c]=true,true,true
    rules.game_apply(g,m)
    check(g.earnings[1]==4 and g.earnings[2]==0 and g.earnings[3]==3,'credit paid-once gold and stone, protected water waits')
    local copy=rules.game_copy(g)
    m=rules.new_match();m.mask[a]=true
    rules.game_apply(copy,m)
    check(copy.earnings[2]==3 and g.earnings[2]==0,'water credits provisions and a board copy has an independent ledger')
    rules.game_apply(g,m)
    check(g.earnings[2]==3,'credit the water once when actually removed')

    local supply_run=R.make_board(8,19)
    local free={}
    for i=0,rules.CELLS-1 do
        if rules.game_cell_active(supply_run,i) and supply_run.chain[i]==0 and supply_run.ice[i]==0 then
            free[#free+1]=i
        end
    end
    local block,pack=free[1],free[2]
    supply_run.tiles[block],supply_run.tiles[pack]=rules.tile(4),rules.tile(3)
    m=rules.new_match();m.mask[block],m.mask[pack]=true,true
    rules.game_apply(supply_run,m)
    check(supply_run.relics==1 and supply_run.earnings[economy.SUPPLIES]==5,
        'one cut block pays five Supplies and only the blue pack advances the crate goal')
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
    g=rules.game_start(0,999);g.won=true;g.moves=999;g.earnings={8,camp[2]+2,camp[3]+4}
    check(rules.progress_reward(p,g,island.wonders),'replay resources bank')
    check(p.wallet[1]==48 and p.wallet[2]==camp[2]+2 and p.wallet[3]==camp[3]+4 and p.wallet[4]==3 and p.level==1,
        'replay pays matched resources and capped move bonus without discoveries')
    check(island.island_place_next(c,p.wallet,p.level,0) and island.wonder_count(c)==1,'replay can fund the camp')
    check(not rules.progress_reward(p,{won=false},island.wonders),'failed attempt pays nothing')
    local future=rules.game_start(4,887);future.won=true
    check(not rules.progress_reward({level=0},future,island.wonders),'future expedition pays nothing')
end

-- Migration and a completed award use the actual save serializer.
do
    R.island=city.new();island.island_setup(R.island)
    R.wonders=island.wonders
    R.prog={level=4,seed=1,wallet=purse(),story_seen={},lives=3}
    local bank=purse(700,90,90,12)
    check(island.island_place_next(R.island,bank,4,0),'legacy camp already placed')
    check(save.write('relic-resource-legacy',function(s)
        s:int('version',require('journey').version)
        s:int('level',4)
        s:ints('wallet',purse(155,7,2,12))
        R.island:serialize(s)
    end),'write legacy fixture')
    check(save.read('relic-resource-legacy',R.serialize),'load legacy fixture')
    check(R.make_board(4, 93).tool_meter[1] == 0, 'older saves start their unlocked bonus meters empty')
    local w=R.prog.wallet
    local well=island.wonders[2].cost[1]
    check(w[1]==math.max(155,well) and w[2]==0 and w[3]==9 and w[4]==12 and island.wonder_count(R.island)==1,
        'legacy saves preserve Gold, Stars, placements and combined Supplies')
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
    check(w[1]==well and w[2]==10 and w[3]==22 and w[4]==12,
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
    check(charges[B.hammer.tool] == 22 and charges[B.shield.tool] == economy.BONUS_THRESHOLD
        and charges[B.plus.tool] == economy.BONUS_THRESHOLD and charges[5] == nil,
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
    check(R.overlay==R.OV_RESULT and R.g.earnings[3]==7 and R.g.resource_yields[3]==economy.unlocks[2],
        'completed award restores its counts on the correct palette')
    check(R.g.tool_meter[1] == R.g.tool_threshold // 2, 'partial charge survives writing, loading and resuming an award')
    check(rules.progress_reward(R.prog,R.g,R.wonders) and not R.prog.completed,'claim consumes the pending award')
    check(not rules.progress_reward(R.prog,R.g,R.wonders),'loaded award cannot bank twice')
end
