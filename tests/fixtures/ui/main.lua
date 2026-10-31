-- A single resource rendered with two independent skins, and stacked modals.
local template={root={kind='column',panel=true,padding=24,gap=14,children={
    {kind='label',id='title',height=46,role='title'},
    {kind='label',id='description',height=68,wrap=true},
    {kind='toggle',id='sound',height=54,on_text='SOUND ON',off_text='SOUND OFF'},
    {kind='checkbox',id='hints',text='Show hints',height=40},
    {kind='checkbox',id='locked',text='Cloud saves',height=40,enabled=false,value=true},
    {kind='progress',id='progress',height=24},
    {kind='spacer',grow=1},
    {kind='row',gap=12,height=54,children={
        {kind='button',id='reset',text='RESET',grow=1,enabled=false},
        {kind='button',id='apply',text='APPLY',grow=1,accent=true},
    }},
}},bindings={{id='title',field='title',readonly=true},{id='description',field='description',readonly=true},
    {id='sound',field='sound',type='boolean'},{id='hints',field='hints',type='boolean'},
    {id='progress',field='progress',type='number',readonly=true}}}
local models={
    {title='SUNSTONE',description='One template, a warm stone skin file. Layout and control behaviour belong to the engine.',sound=true,hints=true,progress=.65},
    {title='NIGHTFALL',description='The same controls and bindings in a second skin file. No duplicated input code.',sound=false,hints=false,progress=.35},
}
local forms={ui.form(template),ui.form(template)}
-- Each look is one data file: fonts, colours, text styles and per-state control looks.
local skins={require('sunstone_skin'),require('nightfall_skin')}
local stack,stage,clock,clicked_under=nil,0,0,0
local function init()
    for i=1,2 do assert(forms[i]:push(models[i])) end
    if app.arg('nested') or app.arg('smoke') then
        stack=ui.modals(skins[2])
        assert(stack:open('first',forms[1],models[1],{bounds=rect(70,96,360,540)}))
        assert(stack:open('second',forms[2],models[2],{bounds=rect(400,140,360,540)}))
    end
end
local function frame(dt)
    clock=clock+1
    if stack then stack:begin() end
    for x=0,29 do for y=0,22 do
        gfx.rect(rect(x*30,y*30,30,30),(x+y)%2==0 and color.hex(0x466A56) or color.hex(0x1D3F43))
    end end
    local label=style{font=skins[1]:font('display'),size=30,fill=color.WHITE}
    text.inside(label,rect(0,24,900,50),vec2(.5,.5),stack and 'MODAL LAYERS' or 'ONE TEMPLATE / TWO SKIN FILES')
    local event
    if stack then
        if ui.button(rect(20,600,200,60),'UNDERLYING',ui.FLAT) then clicked_under=clicked_under+1 end
        event=stack:draw(dt,{reduced_motion=true})
        if event and event.id=='apply' then
            local i=event.modal=='second' and 2 or 1
            assert(forms[i]:pull(models[i]));assert(stack:close(event.modal))
        end
    else
        for i=1,2 do
            local e=forms[i]:draw(rect(70+(i-1)*400,96,360,540),skins[i])
            if e and (e.kind=='change' or e.id=='apply') then assert(forms[i]:pull(models[i])) end
        end
    end
    if app.arg('smoke') then
        if clock%4==0 then
            stage=stage+1
            if stage==1 then app.inject_click(vec2(100,630)) -- modal must block this
            elseif stage==2 then assert(clicked_under==0);app.inject_click(forms[2].boxes.sound:center())
            elseif stage==3 then assert(forms[2]:get('sound')==true and models[2].sound==false);app.inject_click(forms[2].boxes.hints:center())
            elseif stage==4 then
                assert(forms[2]:get('hints')==true and models[2].hints==false,'checkbox toggles its value, not the model')
                app.inject_click(forms[2].boxes.locked:center())
            elseif stage==5 then
                assert(forms[2]:get('locked')==true,'a disabled checkbox ignores input')
                app.inject_click(forms[2].boxes.apply:center())
            elseif stage==6 then assert(#stack.layers==1 and models[2].sound and models[2].hints);app.inject_click(forms[1].boxes.sound:center())
            elseif stage==7 then app.inject_click(forms[1].boxes.apply:center())
            elseif stage==8 then
                assert(not stack:active() and not models[1].sound and clicked_under==0)
                print('UI smoke: skin files, bound toggles and checkboxes, staged commit and nested modal input passed');app.quit()
            end
        end
    end
end
return {title='Shared UI engine',id='ui-test',design=size2(900,700),fixed=true,clear=color(15,35,42),init=init,frame=frame}
