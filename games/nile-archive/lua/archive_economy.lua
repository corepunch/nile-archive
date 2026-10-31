-- Tested economy contract. Coins circulate; Influence comes only from building.
-- Three performance Stars per scene are best records, not spendable currency.
local M={START_COINS=0,START_INFLUENCE=10,BASE_COINS=80,FIRST_COINS=40,STAR_COINS=20,PERFECT_COINS=20}
M.gates={0,20,50}
M.buildings={
    {coins=70,influence=10,chapters=1},
    {coins=160,influence=30,chapters=2},
    {coins=130,influence=25,chapters=2},
    {coins=60,influence=10,chapters=1},
    {coins=100,influence=15,chapters=1},
}
M.shore_costs={120,180,240}

function M.completed(wins)
    local n=0
    for i=1,3 do if (wins[i] or 0)>0 then n=n+1 end end
    return n
end

-- Best Stars across chapters (at most 9): they unlock catalogue decorations and are never spent.
function M.stars(best)
    local n=0
    for i=1,3 do n=n+(best[i] or 0) end
    return n
end

function M.can_play(wins,influence,i)
    if not M.gates[i] then return false end
    -- Already visited scenes remain accessible in legacy, out-of-order saves.
    return (wins[i] or 0)>0 or ((i==1 or (wins[i-1] or 0)>0) and influence>=M.gates[i])
end

function M.reward(wins,best,stars,perfect)
    local new_stars=math.max(0,math.min(3,stars)-best)
    local first=wins==0 and M.FIRST_COINS or 0
    local mastery=new_stars*M.STAR_COINS
    local clean=perfect and M.PERFECT_COINS or 0
    return {base=M.BASE_COINS,first=first,mastery=mastery,perfect=clean,new_stars=new_stars,
            coins=M.BASE_COINS+first+mastery+clean}
end

function M.claim(state,i,result)
    if not result.complete or result.claimed or not M.can_play(state.wins,state.wallet[2],i) then return false end
    result.payout=M.reward(state.wins[i],state.stars[i],result.stars,result.perfect)
    state.wallet[1]=state.wallet[1]+result.payout.coins
    state.wins[i]=state.wins[i]+1
    state.stars[i]=math.max(state.stars[i],result.stars)
    state.wallet[3]=M.completed(state.wins)
    state.wallet[4]=M.stars(state.stars)
    result.claimed=true
    return true
end

return M
