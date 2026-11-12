-- Tested economy contract. Coins circulate; Influence comes only from building.
-- Stars are best records, with one guaranteed per clear up to three.
local M={START_COINS=0,START_INFLUENCE=10,BASE_COINS=80,FIRST_COINS=40,STAR_COINS=20,PERFECT_COINS=20}
M.gates={0,20,50,75,90,100,120,145,170,200,230,260,295,330,370}
M.FOUNTAIN=4
M.WORKSHOP=5
M.CACHE_COINS=150
M.cache_rewards={150,150,200}
M.buildings={
    {coins=70,influence=10,chapters=1},
    {coins=160,influence=30,chapters=2},
    {coins=130,influence=25,chapters=2},
    {coins=60,influence=10,chapters=1},
    {coins=100,influence=15,chapters=1},
}
M.shore_costs={120,180,240}
-- Save data stores these project flags in catalogue order. Append new entries.
M.projects={
    {id="archive_survey",name="Обследовать архив",coins=100,influence=15,chapter=2},
    {id="channel_survey",name="Обследовать канал",coins=150,influence=20,chapter=2},
    {id="workshop_records",name="Разобрать записи мастерской",coins=200,influence=25,chapter=2},
    {id="temple_records",name="Разобрать записи храма",coins=250,influence=25,chapter=2},
    {id="garden_survey",name="Обследовать сад",coins=300,influence=30,chapter=2},
    {id="archive_work",name="Работы в архиве",coins=300,influence=30,chapter=3},
    {id="channel_work",name="Работы на канале",coins=320,influence=30,chapter=3},
    {id="workshop_work",name="Работы в мастерской",coins=360,influence=35,chapter=3},
    {id="temple_work",name="Работы в храме",coins=400,influence=35,chapter=3},
    {id="garden_work",name="Работы в саду",coins=450,influence=40,chapter=3},
}

local function cache_complete(state, chapter)
    if chapter == 1 and state.cache_done == true then return true end
    return state.caches and state.caches[chapter] == 1
end

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
    if i==15 and not state.restored[M.WORKSHOP] then return "workshop" end
    -- Keep already visited searches accessible in old saves.
    if (state.wins[i] or 0)>0 then return end
    if i>5 and not cache_complete(state, math.floor((i-1)/5)) then return "chapter" end
    if i>1 and (state.clues[i-1] or 0)<M.clue_count(i-1) then return "clue" end
    if state.wallet[2]<M.gates[i] then return "influence" end
end

function M.cache_lock(state,chapter)
    chapter=chapter or 1
    if not M.cache_rewards[chapter] then return "unknown" end
    if cache_complete(state,chapter) then return "done" end
    if chapter>1 and not cache_complete(state,chapter-1) then return "chapter" end
    for i=(chapter-1)*5+1,chapter*5 do
        if (state.clues[i] or 0)<M.clue_count(i) then return "clue" end
    end
    if chapter==1 and not state.restored[M.FOUNTAIN] then return "fountain" end
    if chapter==3 and not state.restored[M.WORKSHOP] then return "workshop" end
end

function M.decoration_influence(coins) return coins // 10 end

function M.claim_cache(state,chapter)
    chapter=chapter or 1
    if M.cache_lock(state,chapter) then return false end
    state.caches=state.caches or {0,0,0}
    state.caches[chapter]=1
    if chapter==1 then state.cache_done=true end
    state.wallet[1]=state.wallet[1]+M.cache_rewards[chapter]
    return true
end

function M.project_lock(state,id)
    local project=M.projects[id]
    if not project then return "unknown" end
    if state.projects and state.projects[id]==1 then return "done" end
    if not cache_complete(state,project.chapter-1) then return "chapter" end
    if state.wallet[1]<project.coins then return "coins" end
end

function M.claim_project(state,id)
    if M.project_lock(state,id) then return false end
    local project=M.projects[id]
    state.projects=state.projects or {}
    state.wallet[1]=state.wallet[1]-project.coins
    state.wallet[2]=state.wallet[2]+project.influence
    state.projects[id]=1
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
