local H=require('support')
local sim=require('emergency_sim')
local t=H.suite('emergency dispatch payments')
local function mission(kind)
    return sim.new{food=100,wood=100,people=1,animals=1,nodes={{x=0,y=0},{x=30,y=0},{x=60,y=0}},objects={
        {id=1,type='hq',x=0,y=0},{id=2,type='worker',x=0,y=0},{id=3,type=kind,x=60,y=0}}}
end
for kind,def in pairs(sim.defs) do
    if def.cost then
        for resource,cost in pairs(def.cost) do
            t:case(kind..' short '..resource,function()
                local g=mission(kind);g.wallet.money=1000
                local e=g.objects[3];g.wallet[resource]=cost-1
                local before={food=g.wallet.food,wood=g.wallet.wood,money=g.wallet.money}
                t:check(not sim.affordable(g,e) and not sim.dispatch(g,e),'cannot dispatch short supplies')
                t:check(H.same(g.wallet,before) and not e.assigned and g.workers[1].phase=='idle','failure reserves and spends nothing')
            end)
        end
        t:case(kind..' exact cost and duplicate assignment',function()
            local g=mission(kind);local e=g.objects[3]
            for _,r in ipairs({'food','wood','money'}) do g.wallet[r]=(def.cost[r] or 0) end
            t:check(sim.dispatch(g,e),'exact funds dispatch')
            t:check(g.wallet.food==0 and g.wallet.wood==0 and g.wallet.money==0,'deduct every resource exactly')
            t:check(not sim.dispatch(g,e) and e.assigned,'cannot charge assignment twice')
            for _=1,100 do sim.update(g,.1) end
            t:check(e.done,'paid job completes')
        end)
    end
end
for _,mode in ipairs({'paused','won','busy','unreachable'}) do
    t:case('dispatch blocked: '..mode,function()
        local g=mission('eruption-kitchen');local e=g.objects[3]
        if mode=='busy' then g.workers[1].phase='working'
        elseif mode=='unreachable' then g.nav.blockers={{pos=vec2(30,0),radius=20}}
        else g[mode]=true end
        local before={food=g.wallet.food,wood=g.wallet.wood,money=g.wallet.money}
        t:check(not sim.dispatch(g,e) and H.same(g.wallet,before) and not e.assigned,'blocked dispatch preserves stock')
    end)
end
return t:finish()
