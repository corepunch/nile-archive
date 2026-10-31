local rules=require('rules')
local island=require('island')
local archive=require('archive_economy')

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
    check(spare==800 and c.open==63 and p.wallet[5]==0,'ten clears fund 800 free Gold and all 20-compass land costs')
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

-- The hidden-object economy has a different contract: scene skill earns Coins,
-- placed buildings earn Influence, and clues must be discovered in order.
do
    local function state() return {wallet=purse(archive.START_COINS,archive.START_INFLUENCE),wins={0,0,0},stars={0,0,0}} end
    local s=state()
    check(archive.can_play(s.wins,10,1) and not archive.can_play(s.wins,1000,2),'wealth cannot skip the first clue')
    local function complete(i,stars,perfect)
        local result={complete=true,stars=stars,perfect=perfect}
        local influence=s.wallet[2]
        check(archive.claim(s,i,result),'eligible hidden-object completion pays')
        local gold=s.wallet[1]
        check(not archive.claim(s,i,result) and s.wallet[1]==gold,'hidden-object completion pays once')
        check(s.wallet[2]==influence,'playing never manufactures Influence')
        return result
    end
    local result=complete(1,1,false)
    check(result.payout.coins==140,'slow first clear has a reliable floor')
    check(not archive.can_play(s.wins,s.wallet[2],2),'first clue alone does not replace building')
    -- Buy the cheapest eligible restoration; repeat the same low-skill policy.
    local fountain=archive.buildings[4]
    s.wallet[1]=s.wallet[1]-fountain.coins;s.wallet[2]=s.wallet[2]+fountain.influence
    check(archive.can_play(s.wins,s.wallet[2],2),'first clear funds a building that opens chapter two')
    complete(2,1,false)
    local temple=archive.buildings[2]
    check(s.wallet[1]>=temple.coins and s.wallet[3]>=temple.chapters,'second low-skill clear funds the temple')
    s.wallet[1]=s.wallet[1]-temple.coins;s.wallet[2]=s.wallet[2]+temple.influence
    check(archive.can_play(s.wins,s.wallet[2],3),'two clears and two buildings reach chapter three without grinding')
    complete(3,1,false)
    check(archive.completed(s.wins)==3,'completion requirements count unique chapters')
    local baseline=s.wallet[1]
    for _=1,10 do complete(1,1,false) end
    check(s.wallet[1]==baseline+800 and s.wallet[2]==50 and s.wallet[3]==3,'replays replenish Coins without advancing the island')
    result=complete(1,3,true)
    check(result.payout.coins==140 and result.payout.new_stars==2,'new best Stars pay only the improvement')
    result=complete(1,3,true)
    check(result.payout.coins==100 and result.payout.mastery==0,'matching a best never repays its milestone')
    check(archive.reward(0,0,3,true).coins==200,'maximum first-clear reward is explicit')
    check(archive.can_play({0,0,1},0,3),'legacy out-of-order completed scenes stay accessible')
    check(not archive.can_play({1,0,0},999,3),'Influence cannot skip the second clue')
    check(not archive.claim(s,1,{complete=false,stars=3}),'abandoned scene cannot pay')
    -- Every optional shore purchase can be recovered through finite replay work.
    for _,cost in ipairs(archive.shore_costs) do
        local replays=math.ceil(cost/archive.BASE_COINS)
        check(replays<=3,'an optional shore costs at most three minimum-reward replays')
    end
end

