-- Every real catalogue entry goes through the shared engine purchase path.
local H = require('support')
local t = H.suite(testing.game .. ' building payments')
local defs
if testing.game=='nile-archive' then defs=require('archive_content').buildings
else defs=require('buildings') end
local spot=vec2(5000,5000)
for kind, def in ipairs(defs) do
    local label=def.name or tostring(kind)
    for slot=1,purse.MAX do
        if def.cost[slot]>0 then
            t:case(label..' insufficient resource '..slot, function()
                local c,w=H.city(defs),H.wallet(def)
                w[slot]=def.cost[slot]-1
                local before=purse(table.unpack(w))
                c:begin_place(kind-1,spot)
                t:check(c:confirm(w,0).result~=city.BUILT, 'short wallet cannot build')
                t:check(c.count==0 and H.same(w,before), 'failure is atomic in every slot')
                t:check(c.placing==kind-1, 'failed purchase retains preview')
            end)
        end
        if def.needs[slot]>0 then
            t:case(label..' unmet requirement '..slot, function()
                local c,w=H.city(defs),H.wallet(def)
                w[slot]=def.needs[slot]-1
                local before=purse(table.unpack(w))
                c:begin_place(kind-1,spot)
                t:check(c:confirm(w,0).result==city.LOCKED_TYPE, 'requirements gate construction')
                t:check(c.count==0 and H.same(w,before), 'requirements failure preserves wallet')
            end)
        end
    end
    t:case(label..' exact funds, cancel, confirm, repeat', function()
        local c,w=H.city(defs),purse()
        for slot=1,purse.MAX do w[slot]=math.max(def.cost[slot],def.needs[slot]) end
        local before=purse(table.unpack(w))
        c:begin_place(kind-1,spot)
        t:check(H.same(w,before) and c.count==0, 'preview reserves no money')
        c:cancel()
        t:check(H.same(w,before) and c.count==0, 'cancel spends nothing')
        c:begin_place(kind-1,spot)
        local ev=c:confirm(w,123)
        t:check(ev.result==city.BUILT and c.count==1 and c.items[1].type==kind-1, 'exact funds buy correct building')
        for slot=1,purse.MAX do
            t:check(w[slot]==before[slot]-def.cost[slot]+(def.reward and def.reward[slot] or 0),
                'only costs spent, rewards granted once: slot '..slot)
            t:check(ev.amount[slot]==def.cost[slot], 'event reports actual payment')
        end
        local paid=purse(table.unpack(w))
        t:check(c:confirm(w,123).result==city.NONE and c.count==1 and H.same(w,paid), 'double confirm is inert')
        c:begin_move(0)
        c.ghost=spot+vec2(1000,500)
        t:check(c:confirm(w,124).result==city.MOVED and H.same(w,paid), 'moving neither charges nor regrants reward')
    end)
end
return t:finish()
