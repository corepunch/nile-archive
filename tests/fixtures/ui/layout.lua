-- Borders, uniform grids and a prefab, in both skin files (--layout).
-- One record becomes one card; the grid's row follows the number of records.
ui.prefab('fixture_resource',function(p)
    return {kind='border',role='card',padding={6,8,6,8},children={
        {kind='column',gap=2,children={
            {kind='custom',height=34,paint=function(box)
                gfx.circle(box:center(),16,color.hex(0x5A3A1C));gfx.circle(box:center(),13,p.tint)
            end},
            {kind='label',text=p.amount,em=24},
            {kind='label',text=p.name,em=14,text_style='muted'},
        }},
    }}
end)
local function caption(text) return {kind='label',text=text,em=15,text_style='muted'} end
local corners={}
for i,radius in ipairs({0,6,12,18,24}) do
    corners[i]={kind='border',background='card_face',border_color='card_edge',border_width=2,radius=radius,padding={4,9,4,9},
        children={{kind='label',text='r '..radius,em=18}}}
end
local template={kind='column',panel=true,children={
    {kind='label',id='title',height=40,role='title'},
    caption('rows = 1: a resource prefab per record'),
    {kind='uniform_grid',id='bank',rows=1,gap=8,item=function(r)
        return {kind='fixture_resource',amount=r.amount,name=r.name,tint=r.tint}
    end},
    caption('columns = 3: five borders wrap to a second row'),
    {kind='uniform_grid',columns=3,gap=8,children=corners},
    caption('border: its width and padding inset the child'),
    {kind='border',background='card_face',border_color='card_edge',border_width=6,radius=16,padding=10,children={
        {kind='label',wrap=true,em=17,text='A border holds one child. This label wraps inside the six-unit rim plus ten of padding.'},
    }},
}}
local coin,crate,basket,gem=color.hex(0xF2B33D),color.hex(0xB97A45),color.hex(0xD9573F),color.hex(0x4FB7C9)
local banks={
    {{id='coins',amount='+24',name='Coins',tint=coin},{id='supplies',amount='+14',name='Supplies',tint=crate},
     {id='food',amount='+9',name='Food',tint=basket}},
    {{id='coins',amount='+24',name='Coins',tint=coin},{id='supplies',amount='+14',name='Supplies',tint=crate},
     {id='food',amount='+9',name='Food',tint=basket},{id='gems',amount='+2',name='Gems',tint=gem}},
}
local forms={ui.form(template),ui.form(template)}
for i,form in ipairs(forms) do
    form:set('title',i==1 and 'THREE RECORDS' or 'FOUR RECORDS')
    assert(form:set_items('bank',banks[i]))
end
return function(skins)
    for i,form in ipairs(forms) do
        local _,height=form:measure(380,skins[i])
        form:draw(rect(50+(i-1)*420,96,380,height),skins[i])
    end
end
