-- A single resource rendered with two independent skins, and stacked modals.
local template={root={kind='column',panel=true,padding=24,gap=16,children={
    {kind='label',id='title',height=46,role='title'},
    {kind='label',id='description',height=68,wrap=true},
    {kind='toggle',id='sound',height=54,on_text='SOUND ON',off_text='SOUND OFF'},
    {kind='progress',id='progress',height=24},
    {kind='spacer',grow=1},
    {kind='button',id='apply',height=54,text='APPLY',accent=true},
}},bindings={{id='title',field='title',readonly=true},{id='description',field='description',readonly=true},
    {id='sound',field='sound',type='boolean'},{id='progress',field='progress',type='number',readonly=true}}}
local models={
    {title='SUNSTONE',description='One template, a warm stone skin. Layout and control behaviour belong to the engine.',sound=true,progress=.65},
    {title='NIGHTFALL',description='The same controls and bindings in a second game skin. No duplicated input code.',sound=false,progress=.35},
}
local forms={ui.form(template),ui.form(template)}
local skins,stack,stage,clock,clicked_under={},nil,0,0,0
local function skin(f,dark)
    local t=ui.theme()
    local ink=dark and color.hex(0xE6F6F6) or color.hex(0x47341E)
    t.text=style{font=f,size=23,fill=ink};t.button=style{font=f,size=24,fill=ink};t.accent_text=t.button
    t.title=style{font=f,size=31,fill=dark and color.hex(0x5DE1DD) or color.hex(0x8B572C)}
    t.panel=dark and color.hex(0x142D42) or color.hex(0xFFF0C0);t.panel2=t.panel
    t.border=dark and color.hex(0x398B9B) or color.hex(0xBB9555)
    t.button_bg=dark and color.hex(0x234A60) or color.hex(0xEBCB84);t.button_bg2=t.button_bg
    t.button_hot=dark and color.hex(0x38738B) or color.hex(0xFFE3A1);t.button_border=t.border
    t.accent=dark and color.hex(0x40BDB6) or color.hex(0xD6AC62);t.accent2=t.accent
    t.active=dark and color.hex(0x77E2DC) or color.hex(0xAC713A);t.radius=dark and 4 or 20
    t.dim=color(4,15,25,150);t.backdrop_blur=7
    return {theme=t}
end
local function init()
    local f=font.load('fonts/LilitaOne-Regular.ttf');skins={skin(f,false),skin(f,true)}
    for i=1,2 do assert(forms[i]:push(models[i])) end
    if app.arg('nested') or app.arg('smoke') then
        stack=ui.modals(skins[2])
        assert(stack:open('first',forms[1],models[1],{bounds=rect(70,110,360,440)}))
        assert(stack:open('second',forms[2],models[2],{bounds=rect(360,220,360,440)}))
    end
end
local function frame(dt)
    clock=clock+1
    if stack then stack:begin() end
    for x=0,29 do for y=0,22 do
        gfx.rect(rect(x*30,y*30,30,30),(x+y)%2==0 and color.hex(0x466A56) or color.hex(0x1D3F43))
    end end
    local label=style{font=skins[1].theme.text.font,size=30,fill=color.WHITE}
    text.inside(label,rect(0,30,900,50),vec2(.5,.5),stack and 'MODAL LAYERS' or 'ONE TEMPLATE / TWO SKINS')
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
            local e=forms[i]:draw(rect(70+(i-1)*400,140,360,440),skins[i])
            if e and (e.kind=='change' or e.id=='apply') then assert(forms[i]:pull(models[i])) end
        end
    end
    if app.arg('smoke') then
        if clock%4==0 then
            stage=stage+1
            if stage==1 then app.inject_click(vec2(100,630)) -- modal must block this
            elseif stage==2 then assert(clicked_under==0);app.inject_click(forms[2].boxes.sound:center())
            elseif stage==3 then assert(forms[2]:get('sound')==true and models[2].sound==false);app.inject_click(forms[2].boxes.apply:center())
            elseif stage==4 then assert(#stack.layers==1 and models[2].sound);app.inject_click(forms[1].boxes.sound:center())
            elseif stage==5 then app.inject_click(forms[1].boxes.apply:center())
            elseif stage==6 then
                assert(not stack:active() and not models[1].sound and clicked_under==0)
                print('UI smoke: skins, bound toggles, staged commit and nested modal input passed');app.quit()
            end
        end
    end
end
return {title='Shared UI engine',id='ui-test',design=size2(900,700),fixed=true,clear=color(15,35,42),init=init,frame=frame}
