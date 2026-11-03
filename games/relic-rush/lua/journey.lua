-- Narrative checkpoints are stable keys, acknowledged after a whole beat ends.
-- The engine's transient queue is deliberately not used as the save checkpoint.
local M = {beats=require('story_content'), wonder_levels=require('campaign').wonder_levels}

function M.earned(level)
    local n=0
    for _,at in ipairs(M.wonder_levels) do if level>=at then n=n+1 end end
    return n
end

function M.wonder_at(level)
    for i,at in ipairs(M.wonder_levels) do if level==at then return i end end
end

function M.find(key)
    for _,beat in ipairs(M.beats) do if beat.key==key then return beat end end
end

function M.migrate(p, version)
    p.story_seen=p.story_seen or {}
    if version<4 then
        -- Legacy clears remain clears; even later, already-owned wonders stay.
        -- A recap bridges the old abbreviated dialogue without replaying rewards.
        for _,b in ipairs(M.beats) do
            if b.level<=p.level then p.story_seen[b.key]=true end
        end
        p.story_recap=p.level>0
    end
end

function M.serialize(s,p)
    p.story_seen=p.story_seen or {}
    for _,b in ipairs(M.beats) do
        p.story_seen[b.key]=s:int('narrative.v1.'..b.key,p.story_seen[b.key] and 1 or 0)==1
    end
    p.story_recap=s:int('narrative.recap',p.story_recap and 1 or 0)==1
end

function M.next(p, owns, before_level)
    for _,b in ipairs(M.beats) do
        if not (p.story_seen or {})[b.key] then
            if b.phase=='before' then
                if before_level==b.level-1 and p.level>=b.level-1 then return b end
            elseif p.level>=b.level then
                local wonder=M.wonder_at(b.level)
                if not wonder or owns(wonder-1) then return b end
            end
            return nil
        end
    end
end

function M.awaiting_return(p)
    for _,b in ipairs(M.beats) do
        if not (p.story_seen or {})[b.key] then return b.phase=='after' and p.level>=b.level end
    end
    return false
end

function M.recap(level)
    local lines={{'elena','Back in the Lost Valley. We came to record its people, and nothing leaves this island.'}}
    if level>=10 then
        lines[#lines+1]={'mara','The golden sun was only a socket. Someone cut its Heart out with a Vale and Sons chisel.'}
        lines[#lines+1]={'adrian',"My father's chisel. He came here thirty years ago. None of his expedition came home."}
    elseif level>=6 then
        lines[#lines+1]={'elena','The sunstones split from inside. Frost is climbing from the lower halls, even in this heat.'}
        lines[#lines+1]={'mara','And all three valley roads lead to the beach. Where did everyone go?'}
    elseif level>=3 then
        lines[#lines+1]={'elena','Tomas says the valley once sang at noon. Someone silenced the temple. We need to learn why.'}
    else
        lines[#lines+1]={'mara',"The Marigold is ready. And Tomas, our island archivist, knows more than he's telling."}
    end
    return lines
end

M.regions={
    'Sunlit coast is clear! Good beach for a landing, if you don\'t mind the crabs.',
    'Fern meadow\'s open. I\'ve found three snakes so far, and named them all.',
    'Sun garden\'s open. Everything\'s still in rows, as if someone meant to come back.',
    'The heights are open. You can see the whole valley from up here, frost and all.',
    'Temple ridge is open. Nothing between you and that temple now but stairs.',
}

function M.building_about(kind,level,fallback)
    if kind==1 and level>=30 then return 'The well is filling. Warm water runs through the valley again.' end
    if kind==1 and level>=15 then return 'The frost is above the second terrace. The well cannot last much longer.' end
    if kind==4 and level>=13 then return 'Eleven names remain on the wall. The twelfth has been carefully cut away.' end
    if kind==6 and level>=19 then return 'A photograph of twelve men. Beside Cornelius Vale stands a young Tomas Reed.' end
    if kind==7 and level>=23 then return 'Six bearings, not stars. One is this island. Five are still out at sea.' end
    if kind==8 and level>=26 then return 'Under the old fountain: the only warm room, where Tomas kept the Heart.' end
    if kind==9 and level>=30 then return 'At noon the valley sings again. Five lights answer from the sea.' end
    return fallback
end

return M
