-- The full cast and presentation use the existing authored portraits and island.
local R=require('state')
local journey=require('journey')
local island=require('island')
R.cast={
    {id='elena',name='Elena Voss',role='Archaeologist, expedition lead',portrait_path='characters/elena.png',color=color(44,108,84),mouth=vec2(.46,.51)},
    {id='mara',name='Mara Bell',role='Pilot of the Marigold',portrait_path='characters/mara.png',color=color(150,74,40),right=true,mouth=vec2(.60,.49)},
    {id='tomas',name='Tomas Reed',role='Island archivist',portrait_path='characters/tomas.png',color=color(92,112,58),right=true,mouth=vec2(.44,.52)},
    {id='adrian',name='Adrian Vale',role='Expedition financier',portrait_path='characters/adrian.png',color=color(104,48,92),right=true,mouth=vec2(.46,.52)},
    -- Heard, never seen: the radio or a loudhailer. No bust, so the engine captions his lines.
    {id='kessler',name='Kessler',role='Meridian Society',color=color(60,62,70)},
}
R.intro_lines=journey.find('before-01').lines
R.finale=journey.find('after-30').lines

function R.queue_story(beat, preview)
    R.story_current=beat
    R.story_preview=preview
    for _,line in ipairs(beat.lines) do story.add(line) end
end

function R.story_tick()
    if R.story_current then
        if story.active() then return end
        local b=R.story_current
        R.story_current=nil
        if R.story_preview then R.story_preview=false;return end
        if b.key=='recap' then R.prog.story_recap=false
        else R.prog.story_seen[b.key]=true end
        R.save_progress()
        if b.key=='after-30' then R.overlay=R.OV_FINALE;return end
    end
    if R.quiet or story.active() or R.overlay~=R.OV_NONE or R.island.placing>=0 then return end
    if R.prog.story_recap then
        R.on_island=true
        R.queue_story({key='recap',lines=journey.recap(R.prog.level)})
        return
    end
    local before=not R.on_island and R.g and R.g.level or nil
    local b=journey.next(R.prog,function(kind) return island.owned(R.island,kind)>0 end,before)
    if b then
        if b.phase=='after' then R.on_island=true end
        R.queue_story(b)
    end
end

return R
