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

-- The palette keeps its matching slots. Only the built well changes the
-- sprite and proceeds of slot 3, and only on the two marker boards.
do
    R.island=city.new();island.island_setup(R.island)
    local bank=purse(700,90,90,12)
    check(island.island_place_next(R.island,bank,4,0),'place the camp before the well')
    local c=R.island
    local fits,spot=c:find_spot(economy.WELL_KIND,island.island_suggestion(economy.WELL_KIND))
    check(fits,'well fits first region')
    c:begin_place(economy.WELL_KIND,spot)
    check(R.make_board(4,19).resource_yields[3].key=='timber','placement preview does not unlock water')
    c:cancel()
    check(R.make_board(5,19).resource_yields[3].key=='timber','cancel still leaves the timber palette')
    check(island.island_place_next(c,bank,4,0),'confirm the earned well')
    for level=0,rules.LEVELS-1 do
        local g=R.make_board(level,19)
        local spec=rules.level_of(g)
        local water=g.resource_yields[3]==economy.water
        check(water==(level==4 or level==5),'water only replaces the blue slot on boards 5 and 6')
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
    check(g.earnings[1]==4 and g.earnings[2]==0 and g.earnings[3]==1,'credit paid-once gold and stone, protected water waits')
    local copy=rules.game_copy(g)
    m=rules.new_match();m.mask[a]=true
    rules.game_apply(copy,m)
    check(copy.earnings[2]==1 and g.earnings[2]==0,'water credits provisions and a board copy has an independent ledger')
    rules.game_apply(g,m)
    check(g.earnings[2]==1,'credit the water once when actually removed')
end

-- Even a tool-only clear funds the next restoration. Optional spending
-- cannot take away its price. Replays bank all three resources once.
do
    local p={level=0,seed=1,wallet=purse()}
    local c=city.new();island.island_setup(c)
    for level=0,rules.LEVELS-1 do
        local g=rules.game_start(level,level+1);g.won=true;g.moves=0
        check(rules.progress_reward(p,g,island.wonders),'first clear pays')
        local reserved=island.reserved_cost(c,p.level)
        check(p.wallet:covers(reserved),'exact shortfall keeps every mandatory purchase affordable')
        check(not rules.progress_reward(p,g,island.wonders),'the same win cannot pay twice')
        for z=1,5 do c:unlock(z,p.wallet) end
        local scheduled=rules.wonder_at(level+1)~=nil
        check(island.island_place_next(c,p.wallet,p.level,0)==scheduled,'only the scheduled clear earns a restoration')
    end
    check(c.count==10 and c.open==63 and p.wallet[4]==90,'full campaign remains affordable with zero matches')
    local g=rules.game_start(5,999);g.won=true;g.moves=999;g.earnings={8,12,14}
    local before=purse(table.unpack(p.wallet))
    check(rules.progress_reward(p,g,island.wonders),'replay resources bank')
    check(p.wallet[1]-before[1]==48 and p.wallet[2]-before[2]==12 and p.wallet[3]-before[3]==14
        and p.wallet[4]==before[4] and p.level==30,'replay pays all matches and capped move bonus without discoveries')
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
    check(w[1]==155 and w[2]==10 and w[3]==22 and w[4]==12 and island.wonder_count(R.island)==1,
        'legacy saves retain Gold, Stars, placements and funding for the earned well')
    check(not island.can_spend(R.island,w,4,purse(1,0,1)) and island.can_spend(R.island,w,4,purse(1)),
        'optional building cannot spend the reserved supplies')
    check(island.island_place_next(R.island,w,4,0),'migrated well is affordable')
    R.g=R.make_board(4,93);R.g.won=true;R.g.moves=4;R.g.earnings={8,3,7};R.test_mode=true
    R.stash_completed()
    check(save.write('relic-resource-complete',R.serialize),'write completed award')
    R.prog.completed=nil
    check(save.read('relic-resource-complete',R.serialize),'load completed award')
    R.resume_completed()
    check(R.overlay==R.OV_RESULT and R.g.earnings[3]==7 and R.g.resource_yields[3]==economy.water,
        'completed award restores its counts on the correct palette')
    check(rules.progress_reward(R.prog,R.g,R.wonders) and not R.prog.completed,'claim consumes the pending award')
    check(not rules.progress_reward(R.prog,R.g,R.wonders),'loaded award cannot bank twice')
end
