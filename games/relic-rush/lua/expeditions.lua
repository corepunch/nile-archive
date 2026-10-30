-- Repeatable earning and the one-time discovery track share one scene browser.
local R=require('state')
local rules=require('rules')
local island=require('island')
local page=1
local stack=ui.modals(R.form_skin)
local form=ui.form{kind='column',panel=true,padding=20,gap=12,children={
    {kind='label',text='Expeditions',height=42,em=34},
    {kind='label',text='First clear: restoration grant + Discovery Stars.\nReplay: 60 Gold + up to 40 for moves saved.',wrap=true,em=17,palette=R.PAL_CREAM},
    {kind='list',id='levels',gap=12,item=function(e)
        return {kind='column',panel=true,padding=12,gap=6,children={
            {kind='label',text=e.title,wrap=true,text_align='start',em=24},
            {kind='label',text=e.note,wrap=true,text_align='start',em=15,palette=R.PAL_CREAM},
            {kind='button',id='play',text=e.action,enabled=e.available,height=42,em=21},
        }}
    end},
    {kind='row',height=38,gap=12,children={
        {kind='button',id='previous',text='PREV',width=90,em=17},
        {kind='label',id='page',grow=1,em=18},
        {kind='button',id='next',text='NEXT',width=90,em=17},
    }},
    {kind='button',id='close',text='BACK TO ISLAND',height=42,em=21},
}}
R.expedition_form=form

local function refresh()
    local entries={}
    for i=(page-1)*3,math.min(page*3-1,rules.LEVELS-1) do
        local done=i<R.prog.level
        local current=i==R.prog.level
        local pending=island.wonder_count(R.island)<R.prog.level
        local available=done or (current and not pending)
        entries[#entries+1]={id=tostring(i),level=i,title=('%d. %s'):format(i+1,rules.levels[i+1].name),available=available,
            action=done and 'REPLAY FOR GOLD' or current and (pending and 'RESTORE YOUR WONDER FIRST' or 'NEW DISCOVERY') or 'DISCOVER EARLIER LEVELS',
            note=done and 'Gold only. No extra Stars, Compasses or story unlocks.' or
                ('First clear: restoration funded + 80–120 spare Gold, 3 Stars, %d Compasses.'):format(rules.compass_rewards[i+1])}
    end
    assert(form:set_items('levels',entries))
    form:set('page',('%d / 4'):format(page))
    form.nodes.previous.enabled,form.nodes.next.enabled=page>1,page<4
    R.expedition_records=entries
end

function R.open_expeditions(selected_page)
    page=selected_page and num.clampi(selected_page,1,4) or math.min(4,math.floor(math.min(R.prog.level,9)/3)+1)
    refresh()
    if stack:active() then stack:close() end
    assert(stack:open('expeditions',form,{}, {width=448,blur=7,dim=color(5,22,22,185),cancel='close'}))
    R.overlay=R.OV_EXPEDITIONS
end

function R.draw_expeditions(dt)
    local ev=stack:draw(dt,{reduced_motion=R.reduced_motion})
    if not ev then return end
    if ev.id=='close' or ev.kind=='cancel' then stack:close();R.overlay=R.OV_NONE
    elseif ev.id=='previous' or ev.id=='next' then page=page+(ev.id=='next' and 1 or -1);refresh()
    elseif ev.source=='levels' then
        for _,e in ipairs(R.expedition_records) do
            if ev.key==e.id and e.available then stack:close();R.start_level(e.level);return end
        end
    end
end

return R
