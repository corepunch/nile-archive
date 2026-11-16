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

-- Confirmed restorations persist across eligible boards without taking story slots.
do
    R.island=city.new();island.island_setup(R.island)
    local bank=purse(700,90,90,27)
    check(island.island_place_next(R.island,bank,4,0),'place the camp before the well')
    local c=R.island
    local fits,spot=c:find_spot(economy.WELL_KIND,island.island_suggestion(economy.WELL_KIND))
    check(fits,'well fits first region')
    c:begin_place(economy.WELL_KIND,spot)
    check(R.make_board(4,19).resource_yields[3].key=='timber','placement preview does not unlock water')
    c:cancel()
    check(R.make_board(5,19).resource_yields[3].key=='timber','cancel still leaves the timber palette')
    check(island.island_place_next(c,bank,4,0),'confirm the earned well')
    local workshop=economy.WORKSHOP_KIND
    fits,spot=c:find_spot(workshop,island.island_suggestion(workshop))
    check(fits,'workshop has a placement spot')
    c:begin_place(workshop,spot)
    check(R.make_board(8,19).resource_yields[4].key=='stone','workshop preview does not unlock cut blocks')
    c:cancel()
    check(R.make_board(8,19).resource_yields[4].key=='stone','cancel preserves the stone palette')
    check(island.island_place_next(c,bank,7,0),'confirm the earned workshop')
    check(not R.make_board(8,19).resource_yields[5],'the early amphora has no wallet yield')
    check(R.make_board(9,19).resource_yields[1].key=='berries','rations are locked before the market')
    check(island.island_place_next(c,bank,9,0),'confirm the earned market')
    for level=0,rules.LEVELS-1 do
        local g=R.make_board(level,19)
        local spec=rules.level_of(g)
        local water=g.resource_yields[3]==economy.unlocks.water
        local blocks=g.resource_yields[4]==economy.unlocks['cut-blocks']
        local rations=g.resource_yields[1]==economy.unlocks.rations
        check(water==(level>=4 and level~=8), 'water persists after its introduction except in the supply crate slot')
        check(blocks==(level>=8) and rations==(level>=9), 'workshop and market pieces stay unlocked')
        if not spec.story_piece then check(#g.spawn_kinds==5,'ordinary expeditions spawn five pieces') end
        if spec.story_piece then check(not g.resource_yields[spec.goal_kind],'story pieces only earn story progress') end
    end
end

-- Clear regular pieces through the real match resolver. A blocker absorbs
-- the first hit and the preview solver cannot alter the live ledger.
do
    local g=R.make_board(4,19)
    local a,b,c=rules.hex_index(-1,0),rules.hex_index(0,0),rules.hex_index(1,0)
    g.chain[a],g.chain[b],g.chain[c]=1,0,0
    g.tiles[a],g.tiles[b],g.tiles[c]=rules.tile(3),rules.tile(0),rules.tile(4)
    local m=rules.new_match()
    m.mask[a],m.mask[b],m.mask[c],m.make[b]=true,true,true,rules.ROW
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
    g=rules.game_start(0,999);g.won=true;g.moves=999;g.earnings={8,12,14}
    check(rules.progress_reward(p,g,island.wonders),'replay resources bank')
    check(p.wallet[1]==48 and p.wallet[2]==12 and p.wallet[3]==14 and p.wallet[4]==3 and p.level==1,
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
    local w=R.prog.wallet
    check(w[1]==155 and w[2]==0 and w[3]==9 and w[4]==12 and island.wonder_count(R.island)==1,
        'legacy saves preserve Gold, Stars, placements and combined Supplies')
    check(not island.can_spend(R.island,w,4,purse(56)) and island.can_spend(R.island,w,4,purse(55)),
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
    check(w[1]==100 and w[2]==10 and w[3]==22 and w[4]==12,
        'migration covers an earned restoration at the new price and preserves other balances')
    check(island.island_place_next(R.island,w,4,0),'migrated well is affordable')
    R.g=R.make_board(4,93);R.g.won=true;R.g.moves=4;R.g.earnings={8,3,7};R.test_mode=true
    R.stash_completed()
    check(save.write('relic-resource-complete',R.serialize),'write completed award')
    R.prog.completed=nil
    check(save.read('relic-resource-complete',R.serialize),'load completed award')
    R.resume_completed()
    check(R.overlay==R.OV_RESULT and R.g.earnings[3]==7 and R.g.resource_yields[3]==economy.unlocks.water,
        'completed award restores its counts on the correct palette')
    check(rules.progress_reward(R.prog,R.g,R.wonders) and not R.prog.completed,'claim consumes the pending award')
    check(not rules.progress_reward(R.prog,R.g,R.wonders),'loaded award cannot bank twice')
end
