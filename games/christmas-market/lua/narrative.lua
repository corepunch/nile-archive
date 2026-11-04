-- The cast and keyed story delivery. Portrait sources and crops are recorded
-- in docs/asset-catalogue.md#story-cast.
local R=require('state')
local journey=require('journey')
local island=require('island')
R.cast={
    {id='noelle',name='Noelle',role='Christmas market keeper',portrait_path='characters/noelle.png',color=color(136,42,43),mouth=vec2(.51,.42)},
    {id='theo',name='Theo Marsh',role='Tree seller',portrait_path='characters/theo.png',color=color(58,96,62),right=true,mouth=vec2(.38,.52)},
    {id='agnes',name='Agnes Holt',role='Baker',portrait_path='characters/agnes.png',color=color(150,92,48),right=true,mouth=vec2(.49,.45)},
    {id='henrik',name='Henrik Strand',role='Toymaker',portrait_path='characters/henrik.png',color=color(96,70,52),right=true,mouth=vec2(.47,.52)},
    {id='pip',name='Pip Larkin',role='Post runner',portrait_path='characters/pip.png',color=color(46,86,128),right=true,mouth=vec2(.35,.50)},
    {id='wren',name='Mr Wren',role='The man with the broom',portrait_path='characters/wren.png',color=color(92,92,104),right=true,mouth=vec2(.47,.46)},
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
    -- The opening plays at once, even over the market a new game starts on.
    local before=not R.on_island and R.g and R.g.level or (R.prog.level==0 and 0 or nil)
    local b=journey.next(R.prog,function(kind) return island.owned(R.island,kind)>0 end,before)
    if b then
        if b.phase=='after' then R.on_island=true end
        R.queue_story(b)
    end
end

return R
