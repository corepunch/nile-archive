local sim=require('emergency_sim')
local levels=require('emergency_levels')
local art=require('emergency_art')
-- Shared engine geometry and blocker semantics, including final off-graph approach.
local n=nav.new();n.nodes={{x=0,y=0},{x=30,y=0},{x=60,y=0},{x=90,y=0}}
n.blockers={{pos={x=45,y=0},radius=10}}
check(not n:find({x=0,y=0},{x=90,y=0}),'live blocker closes route')
check(#n.path==0,'failed route is empty')
check(n:find({x=0,y=0},{x=45,y=0},0,{x=12,y=6}),'target blocker exemption')
check(math.abs(n.path[#n.path].x-33)<.01,'approach stops at footprint')
n.blockers={};check(n:find({x=0,y=0},{x=90,y=0}),'clearing opens route')
check(math.abs(n.length-90)<.01,'route length')
n.blockers={{pos={x=100,y=0},radius=5}}
check(not n:find({x=0,y=0},{x=110,y=0}),'off-graph final segment also blocked')
check(n.length==0,'failed final approach clears route length')
check(not pcall(function()n.nodes=string.rep('a',2) end),'invalid graph rejected')
local f={source={x=5,y=8,w=20,h=40},pivot={x=.25,y=.75}}
local r=sprite.bounds(f,{x=100,y=200},2)
check(r.x==90 and r.y==140 and r.w==40 and r.h==80,'pivot-aware sprite bounds')
check(sprite.sample({f,{source={x=20,y=0,w=10,h=10}}},2,.5).source.x==20,'authored animation timing')
check(sprite.sample({},2,1).source.w==0,'empty animation safe')
for _,a in pairs(art) do
    for _,frame in ipairs(a.frames) do
        check(frame.source.w>0 and frame.source.h>0,'nonempty authored frame')
    end
end
for i,level in ipairs(levels) do
    for _,order in ipairs({'normal','reverse','yard'}) do
        local g=sim.new(level)
        check(#g.workers== (i==1 and 2 or 3),'worker count map '..i)
        sim.update(g,.1)
        check(g.rescued==0,'initial resident gates map '..i)
        local before=g.time;g.paused=true;sim.update(g,.2)
        check(g.time==before and not sim.click(g,g.objects[4]),'pause prevents updates and orders')
        g.paused=false
        local max_time=1800
        local frames=0
        while not g.won and g.time<max_time do
            if frames%10==0 then
                local e=sim.suggest(g,order)
                if e then
                    local old=g.wallet.food+g.wallet.wood+g.wallet.money
                    sim.click(g,e)
                    if e.assigned then
                        check(not sim.dispatch(g,e),'assignment prevents duplicate spending')
                        check(g.wallet.food+g.wallet.wood+g.wallet.money<=old,'spend only at dispatch')
                    end
                end
            end
            sim.update(g,.1);g.events={};frames=frames+1
            if g.wallet.food<0 or g.wallet.wood<0 or g.wallet.money<0 then error('negative stock') end
        end
        check(g.won,('map %d (%s) completes at %.0fs: people %d/%d pets %d/%d routes %d/%d'):format(i,order,g.time,g.rescued,level.people,g.animals,level.animals,g.cleared,g.routes))
        check(g.cleared==g.routes,'all route objectives restored')
        check(g.rescued==level.people and g.animals==level.animals,'all residents and pets reach home')
        local restart=sim.new(level)
        check(restart.time==0 and restart.rescued==0 and restart.wallet.food==40,'restart restores mission')
        print(('emergency map %d %s: %.1fs, %s'):format(i,order,g.time,tostring(g.won)))
    end
end
-- Unreachable queued jobs spend nothing, cancel cleanly and cannot duplicate reservations.
local queued=sim.new(levels[1]);local target
for _,e in ipairs(queued.objects) do if e.id==22 then target=e end end
check(sim.click(queued,target) and target.queued and not target.assigned,'blocked target queues')
check(queued.wallet.food==40 and queued.wallet.wood==20,'queue does not spend supplies')
check(sim.click(queued,target) and not target.queued and #queued.queue==0,'queue cancellation removes the reservation')
check(sim.click(queued,target) and #queued.queue==1,'requeue creates exactly one order')
local before=queued.wallet.food
for _=1,6 do sim.update(queued,.1) end
check(not target.assigned and queued.wallet.food==before,'retry does not pay for an unreachable target')
-- Empty food still recovers from a previously repaired kitchen.
local g=sim.new(levels[1]);local kitchen
for _,e in ipairs(g.objects) do if e.type=='eruption-kitchen' then kitchen=e end end
check(sim.dispatch(g,kitchen),'starting kitchen can be repaired')
while not kitchen.done do sim.update(g,.1) end
g.wallet.food=0
for _=1,51 do sim.update(g,.1) end
check(g.wallet.food>=5,'automatic food recovery')
