-- The engine owns measured rows, focus, hit testing and modal input capture.
local R = require('state')
local island = require('island')
local categories = {
    {'all','All treasures'}, {'wonder','Story wonders'}, {'building','Buildings'},
    {'tree','Trees'}, {'bush','Shrubs'}, {'flower','Flowers'}, {'statue','Monuments'},
    {'water','Water gardens'}, {'garden','Garden furniture'}, {'camp','Expedition supplies'},
    {'animal','Wildlife'}, {'rock','Rocks & crystals'},
}
local category = 3
local stack = ui.modals(R.form_skin)
local form = ui.form{kind='column',panel=true,padding=18,gap=8,children={
    {kind='label',text='Build your valley',height=40,em=32},
    {kind='label',id='wallet',height=24,em=16,text_style=R.PAL_CREAM},
    {kind='row',height=38,gap=8,children={
        {kind='button',id='category_prev',text='<',width=42,em=22},
        {kind='label',id='category',grow=1,em=21},
        {kind='button',id='category_next',text='>',width=42,em=22},
    }},
    {kind='label',text='Choose a treasure, then place it on open grass.',height=24,em=14,text_style=R.PAL_CREAM},
    {kind='list',id='stock',scroll=true,height=430,gap=10,item=function(entry)
        return {kind='row',height=116,gap=12,align='center',children={
            {kind='custom',width=98,height=100,paint=function(box) R.picture_fit(entry.sprite,box,255) end},
            {kind='column',grow=1,gap=4,children={
                {kind='label',text=entry.name,wrap=true,text_align='start',em=20},
                {kind='label',text=entry.details,wrap=true,text_align='start',em=14,text_style=R.PAL_CREAM},
                {kind='button',id='buy',text=entry.action,height=34,em=17,enabled=entry.available},
            }},
        }}
    end},
    {kind='button',id='close',text='BACK TO ISLAND',height=42,em=21},
}}
R.catalogue_form = form

local function refresh()
    local filtered, records = {}, {}
    local cat=categories[category][1]
    for i,meta in ipairs(island.catalogue) do
        if cat=='all' or meta.category==cat then filtered[#filtered+1]=i end
    end
    for at=1,#filtered do
        local i=filtered[at]
        local meta,def=island.catalogue[i],R.buildings[i]
        local owned=island.owned(R.island,i-1)
        local available=island.can_buy(R.island,R.prog.wallet,R.prog.level,i-1)
        local action='CHOOSE LOCATION'
        if i<=island.WONDERS then
            action=owned>0 and 'RESTORED' or i>R.prog.level and ('COMPLETE EXPEDITION '..i) or
                i-1~=island.wonder_count(R.island) and 'RESTORE EARLIER WONDERS' or action
        elseif R.prog.wallet[4]<meta.stars then action=('REQUIRES %d STARS'):format(meta.stars)
        elseif not R.prog.wallet:covers(def.cost) then action='MORE AMULETS NEEDED'
        elseif R.prog.wallet[1]-island.reserved_gold(R.island,R.prog.level)<def.cost[1] then action='AMULETS RESERVED FOR WONDERS'
        elseif R.island.count>=160 then action='ISLAND IS FULL' end
        local price=i<=island.WONDERS and ('%d amulets'):format(def.cost[1]) or
            ('%d amulets  /  %d stars to unlock'):format(def.cost[1],meta.stars)
        records[#records+1]={id=meta.key,kind=i-1,name=def.name,sprite=def.sprite,
            details=('%d x %d tiles  /  Owned %d\n%s'):format(meta.size.w,meta.size.h,owned,price),
            available=available,action=action}
    end
    assert(form:set_items('stock',records))
    form:set('category',categories[category][2])
    local reserved=island.reserved_gold(R.island,R.prog.level)
    form:set('wallet',('%d spendable Amulets / %d reserved / %d Stars'):format(math.max(0,R.prog.wallet[1]-reserved),reserved,R.prog.wallet[4]))
    R.catalogue_records=records
end

function R.open_catalogue(filter)
    if filter then
        for i,cat in ipairs(categories) do if cat[1]==filter then category=i end end
    end
    if stack:active() then stack:close() end
    refresh()
    assert(stack:open('catalogue',form,{}, {width=448,snap_backdrop=true,blur=7,dim=color(5,22,22,185),cancel='close'}))
    R.overlay=R.OV_SHOP
end

function R.draw_catalogue(dt)
    local event=stack:draw(dt,{reduced_motion=R.reduced_motion})
    if not event then return end
    if event.id=='close' or event.kind=='cancel' then stack:close();R.overlay=R.OV_NONE
    elseif event.id=='category_prev' or event.id=='category_next' then
        category=(category-1+(event.id=='category_next' and 1 or -1))%#categories+1
        form.nodes.stock.scroll_state=nil;refresh()

    else
        -- Engine list events carry stable item keys independently of row order.
        local key=event.source=='stock' and event.key
        for _,record in ipairs(R.catalogue_records) do
            if record.id==key and record.available then
                stack:close();R.island_begin(record.kind,true);return
            end
        end
    end
end

return R
