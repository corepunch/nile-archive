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
    if version<3 then
        -- Legacy clears remain clears; already-built stalls stay. A recap
        -- bridges Noelle's old short lines without replaying rewards.
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
    local lines={{'noelle','Back in Bellmere! Gran sent me to get her old market going for Christmas. Three weeks, that\'s all.'}}
    if level>=7 then
        lines[#lines+1]={'agnes',"The oven's lit, the lights are going up, and you've still got that parcel. There's buns."}
        lines[#lines+1]={'pip','And the Kind Word box is busy! You never ask who. That\'s the rule.'}
    else
        lines[#lines+1]={'agnes',"You're Rosa's girl. Come in when you can't feel your nose. There's buns."}
    end
    return lines
end

-- Pip announces each region as it opens (docs/story.md#small-lines).
M.regions={
    "Lantern Lane's clear! There's a lamp post that still works if you kick it.",
    "Gingerbread Green's open! It doesn't smell of gingerbread yet. Give it a week.",
    "Carolers Court's open! Mrs Alder's already in it, singing flat.",
    "Starlight Terrace is open! You can see all the way to Fenwick. We're winning.",
    "Evergreen Hill's open! You can see the whole line from up here!",
}

-- Tap bubbles that change as the threads move.
function M.building_about(kind,level,fallback)
    if kind==0 and level>=22 then return "Theo's trees go round it now. He says it was his idea." end
    if kind==2 and level>=20 then return 'Two cups on the windowsill.' end
    if kind==4 and level>=20 then return "The window's been cleaned. On both sides of the square." end
    if kind==7 and level>=23 then return "Twelve horses, twelve families. The third one's a touch to the left." end
    if kind==9 and level>=30 then return "There's a broom against the arch. Nobody's moved it." end
    return fallback
end

return M
