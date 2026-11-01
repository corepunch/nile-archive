-- Repeatable earning and the one-time discovery track share one scene browser.
local R=require('state')
local rules=require('rules')
local island=require('island')
local stack=ui.modals(R.form_skin)
local form=ui.form{kind='column',panel=true,padding=20,gap=12,children={
    {kind='label',text='Expeditions',height=42,em=34},
    {kind='label',text='First clear: restoration grant + Discovery Stars.\nReplay: 60 Amulets + up to 40 for moves saved.',wrap=true,em=17,text_style=R.PAL_CREAM},
    {kind='list',id='levels',scroll=true,height=430,gap=12,item=function(e)
        return {kind='column',panel=true,padding=12,gap=6,children={
            {kind='label',text=e.title,wrap=true,text_align='start',em=24},
            {kind='label',text=e.note,wrap=true,text_align='start',em=15,text_style=R.PAL_CREAM},
            {kind='button',id='play',text=e.action,enabled=e.available,height=42,em=21},
        }}
    end},
    {kind='button',id='close',text='BACK TO ISLAND',height=42,em=21},
}}
R.expedition_form=form

local function refresh()
    local entries={}
    for i=0,rules.LEVELS-1 do
        local done=i<R.prog.level
        local current=i==R.prog.level
        local pending=island.wonder_count(R.island)<R.prog.level
        local available=done or (current and not pending)
        local active=R.g and R.g.level==i and not R.g.won and not R.g.lost
        entries[#entries+1]={id=tostring(i),level=i,title=('%d. %s'):format(i+1,rules.levels[i+1].name),available=available,
            action=active and available and 'RESUME EXPEDITION' or done and 'REPLAY FOR AMULETS' or current and (pending and 'RESTORE YOUR WONDER FIRST' or 'NEW DISCOVERY') or 'DISCOVER EARLIER LEVELS',
            note=active and available and 'Continue the unfinished board. Rewards are paid only after a win.' or done and 'Amulets only. No extra Stars or story unlocks.' or
                'First clear: restoration funded + 80–120 spare Amulets and 3 Stars.'}
    end
    assert(form:set_items('levels',entries))
    R.expedition_records=entries
end

function R.open_expeditions()
    refresh()
    if stack:active() then stack:close() end
    assert(stack:open('expeditions',form,{}, {width=448,snap_backdrop=true,blur=7,dim=color(5,22,22,185),cancel='close'}))
    R.overlay=R.OV_EXPEDITIONS
end

function R.draw_expeditions(dt)
    local ev=stack:draw(dt,{reduced_motion=R.reduced_motion})
    if not ev then return end
    if ev.id=='close' or ev.kind=='cancel' then stack:close();R.overlay=R.OV_NONE

    elseif ev.source=='levels' then
        for _,e in ipairs(R.expedition_records) do
            if ev.key==e.id and e.available then stack:close();R.play_level(e.level);return end
        end
    end
end

return R
