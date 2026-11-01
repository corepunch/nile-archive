local rules=require('rules')
local island=require('island')


-- Worst case: no efficiency bonus, buy decorations with every available coin.
-- Every restoration and the full map still fit the ten first-clear budgets.
do
    local p={level=0,seed=1,wallet=purse()}
    local c=city.new();island.island_setup(c)
    local spare=0
    for i=0,9 do
        local g=rules.game_start(i,i+1);g.won=true;g.moves=0
        check(rules.progress_reward(p,g,island.wonders),'first discovery pays')
        local gold=p.wallet[1]
        check(not rules.progress_reward(p,g,island.wonders) and p.wallet[1]==gold,'result cannot pay twice')
        local reserved=island.reserved_gold(c,p.level)
        check(p.wallet[1]-reserved==rules.FIRST_GOLD,'minimum discretionary budget is predictable')
        spare=spare+p.wallet[1]-reserved
        p.wallet[1]=reserved -- adversarial optional spend, never the restoration reserve
        for z=1,5 do c:unlock(z,p.wallet) end
        check(island.island_place_next(c,p.wallet,p.level,0),'zero-bonus discovery funds and fits next wonder')
        check(p.wallet[1]==0 and p.wallet[2]==0 and p.wallet[3]==0,'materials have no accidental surplus')
    end
    check(spare==800 and c.open==63 and p.wallet[5]==0,'ten clears fund 800 free Gold and all land requirements')
    local stars,wood,stone,level=p.wallet[4],p.wallet[2],p.wallet[3],p.level
    for i=0,9 do
        local g=rules.game_start(i,100+i);g.won=true;g.moves=999
        local before=p.wallet[1]
        check(rules.progress_reward(p,g,island.wonders),'each completed expedition can be replayed')
        check(p.wallet[1]==before+100,'replay efficiency bonus is capped')
        check(p.level==level and p.wallet[4]==stars and p.wallet[5]==0 and p.wallet[2]==wood and p.wallet[3]==stone,
            'replay cannot mint discoveries, materials or expansion currency')
    end
    local g=rules.game_start(0,99);g.won=false
    check(not rules.progress_reward(p,g,island.wonders),'failed expedition pays nothing')
    local next_progress={level=0,seed=1,wallet=purse()}
    g=rules.game_start(1,99);g.won=true
    check(not rules.progress_reward(next_progress,g,island.wonders),'future expedition cannot be claimed')
    local a=rules.game_start(0,1);a.moves=0
    local first=rules.level_reward(a,island.wonders,next_progress)
    a.relics,a.wood,a.stone=9999,9999,9999
    local second=rules.level_reward(a,island.wonders,next_progress)
    check(first[1]==second[1] and first[2]==second[2] and first[3]==second[3],
        'random match colours never change the grant')
end
