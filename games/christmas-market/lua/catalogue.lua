-- The engine owns measured rows, focus, hit testing and modal input capture.
local R = require('state')
local island = require('island')
local journey = require('journey')
local categories = {{'all','All Christmas magic'}, {'wonder','Market wishes'}, {'building','Decorations'},
    {'tree','Snowy trees'}, {'cottage','Cottages'}}
local category = 1
local stack = ui.modals(R.form_skin)
local form = require('match3').catalogue_form('Build your market',
    'Choose Christmas magic for the market.', 'BACK TO MARKET', R.PAL_CREAM, R.picture_fit)
R.catalogue_form = form

local function refresh()
    local records = {}
    local cat=categories[category][1]
    for i,meta in ipairs(island.catalogue) do
        if cat=='all' or meta.category==cat then
            local def=R.buildings[i]
            local owned=island.owned(R.island,i-1)
            local available=island.can_buy(R.island,R.prog.wallet,R.prog.level,i-1)
            local action='CHOOSE LOCATION'
            if i<=island.WONDERS then
                action=owned>0 and 'BUILT' or journey.wonder_levels[i]>R.prog.level and ('COMPLETE WISH '..journey.wonder_levels[i]) or
                    i-1~=island.wonder_count(R.island) and 'BUILD EARLIER STALLS' or action
            elseif R.prog.wallet[4]<meta.stars then action=('REQUIRES %d STARS'):format(meta.stars)
            elseif not R.prog.wallet:covers(def.cost) then action='MORE GOLD NEEDED'
            elseif R.prog.wallet[1]-island.reserved_gold(R.island,R.prog.level)<def.cost[1] then action='GOLD RESERVED FOR STALLS'
            elseif R.island.count>=160 then action='MARKET IS FULL' end
            local price=('%d gold'):format(def.cost[1])
            if i>island.WONDERS then price=price..('  /  %d stars to unlock'):format(meta.stars)
            end
            records[#records+1]={id=meta.key,kind=i-1,name=def.name,sprite=def.sprite,
                details=('%d x %d tiles  /  Owned %d\n%s'):format(meta.size.w,meta.size.h,owned,price),
                available=available,action=action}
        end
    end
    assert(form:set_items('stock',records))
    form:set('category',categories[category][2])
    local reserved=island.reserved_gold(R.island,R.prog.level)
    form:set('wallet',('%d spendable Gold / %d reserved / %d Stars'):format(math.max(0,R.prog.wallet[1]-reserved),reserved,R.prog.wallet[4]))
    return records
end

function R.open_catalogue(filter, review_page)
    local old_category=category
    if filter then
        for i,cat in ipairs(categories) do if cat[1]==filter then category=i end end
    end
    if stack:active() then stack:close() end
    local records=refresh()
    if review_page and #records>0 then
        local index=num.clampi((math.floor(review_page)-1)*4+1,1,#records)
        form:scroll_to('stock',records[index].id)
    elseif category~=old_category then form:scroll_to('stock') end
    assert(stack:open('catalogue',form,{}, {width=448,blur=7,dim=color(5,22,22,185),cancel='close'}))
    R.overlay=R.OV_SHOP
end

function R.draw_catalogue(dt)
    local event=stack:draw(dt,{reduced_motion=R.reduced_motion})
    if not event then return end
    if event.id=='close' or event.kind=='cancel' then stack:close();R.overlay=R.OV_NONE
    elseif event.id=='category_prev' or event.id=='category_next' then
        category=(category-1+(event.id=='category_next' and 1 or -1))%#categories+1
        refresh()
        form:scroll_to('stock')
    elseif event.source=='stock' then
        local record=form:get_item('stock',event.key)
        if record and record.available then stack:close();R.island_begin(record.kind,true) end
    end
end

return R
