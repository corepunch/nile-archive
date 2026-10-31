local archive=require('archive_economy')

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
