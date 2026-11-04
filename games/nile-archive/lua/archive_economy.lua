-- Tested economy contract. Coins circulate; Influence comes only from building.
-- Stars are best records, with one guaranteed per clear up to three.
local M={START_COINS=0,START_INFLUENCE=10,BASE_COINS=80,FIRST_COINS=40,STAR_COINS=20,PERFECT_COINS=20}
M.gates={0,20,50,75,90}
M.FOUNTAIN=4
M.CACHE_COINS=150
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
    for i=1,#M.gates do if (wins[i] or 0)>0 then n=n+1 end end
    return n
end

-- Best Stars across searches unlock catalogue decorations and are never spent.
function M.stars(best)
    local n=0
    for i=1,#M.gates do n=n+(best[i] or 0) end
    return n
end

function M.clue_count(i) return i==1 and 1 or 2 end

function M.lock(state,i)
    if not M.gates[i] then return "unknown" end
    if i==5 and not state.restored[M.FOUNTAIN] then return "fountain" end
    -- Keep already visited searches accessible in old saves.
    if state.wins[i]>0 then return end
    if i>1 and state.clues[i-1]<M.clue_count(i-1) then return "clue" end
    if state.wallet[2]<M.gates[i] then return "influence" end
end

function M.cache_lock(state)
    if state.cache_done then return "done" end
    for i=1,#M.gates do
        if state.clues[i]<M.clue_count(i) then return "clue" end
    end
    if not state.restored[M.FOUNTAIN] then return "fountain" end
end

function M.decoration_influence(coins) return coins // 10 end

function M.claim_cache(state)
    if M.cache_lock(state) then return false end
    state.cache_done=true
    state.wallet[1]=state.wallet[1]+M.CACHE_COINS
    return true
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
    if not result.complete or result.claimed or M.lock(state,i) then return false end
    local best=state.stars[i]
    result.stars=math.max(result.stars, math.min(3,state.wins[i]+1))
    result.payout=M.reward(state.wins[i],best,result.stars,result.perfect)
    state.wallet[1]=state.wallet[1]+result.payout.coins
    state.wins[i]=state.wins[i]+1
    state.stars[i]=math.max(best,result.stars)
    if i==1 or state.clues[i-1]==M.clue_count(i-1) then
        local known=state.clues[i]
        if known==0 or (known==1 and i>1 and best==3) then
            state.clues[i]=known+1
            result.clue=known+1
        end
    end
    state.wallet[3]=M.completed(state.wins)
    state.wallet[4]=M.stars(state.stars)
    result.claimed=true
    return true
end

return M
