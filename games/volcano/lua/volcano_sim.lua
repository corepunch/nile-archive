-- Volcano rules. Rendering, paths, widgets, dialogue and persistence live in the engine.
local M = {}
M.defs = {
    ['eruption-timber']={kind='obstacle',title='Salvage roof beams',sprite='volcano/timber',action='wood',cost={food=20},reward={wood=20}},
    ['eruption-ash']={kind='obstacle',title='Clear ash and rubble',sprite='volcano/ash',action='pick',cost={food=20}},
    ['eruption-wall']={kind='obstacle',title='Dismantle collapsed wall',sprite='volcano/wall',action='pick',cost={food=20}},
    ['eruption-basalt']={kind='obstacle',title='Clear heavy basalt',sprite='volcano/basalt',action='pick',cost={food=40,money=100}},
    road={kind='obstacle',title='Repair the road',sprite='road',action='srepair',cost={wood=20}},
    ['eruption-kitchen']={kind='station',title='Field kitchen',sprite='volcano/kitchen',action='repair',cost={wood=20},resource='food',income=5},
    ['eruption-yard']={kind='station',title='Timber yard',sprite='volcano/yard',action='repair',cost={wood=20},resource='wood',income=5},
    ['eruption-office']={kind='station',title='District office',sprite='volcano/office',action='repair',cost={wood=30},resource='money',income=10},
    cat={kind='animal',title='Rescue a cat',action='pet',cost={food=10},duration=1.2},
    dog={kind='animal',title='Rescue a dog',action='pet',cost={food=10},duration=1.2},
    civilian={kind='civilian',title='Resident'},worker={kind='worker',title='Rescue worker'},hq={kind='base',title='Rescue headquarters',sprite='hq'},
}
local function pos(e) return {x=e.x,y=e.y} end
local function distance(a,b) return math.sqrt((a.x-b.x)^2+(a.y-b.y)^2) end
local function refresh(g)
    local blocks={}
    for _,e in ipairs(g.objects) do
        if e.def.kind=='obstacle' then
            e.block=#blocks
            blocks[#blocks+1]={pos=pos(e),radius=e.done and 0 or 20}
        end
    end
    g.nav.blockers=blocks
    g.dirty=true
end
function M.new(level)
    local g={level=level,objects={},workers={},evacuees={},wallet={food=level.food,wood=level.wood,money=0},
        time=0,rescued=0,animals=0,cleared=0,routes=0,queue={},events={},paused=false,won=false,accumulator=0}
    g.nav=nav.new(); g.nav.nodes=level.nodes; g.nav.link_distance=50
    for _,o in ipairs(level.objects) do
        local e={id=o.id,type=o.type,x=o.x,y=o.y,variant=o.variant,def=assert(M.defs[o.type],o.type),clock=0}
        g.objects[#g.objects+1]=e
        if e.def.kind=='base' then g.home=pos(e) end
        if e.def.kind=='obstacle' then g.routes=g.routes+1 end
    end
    assert(g.home,'mission needs a base')
    for _,e in ipairs(g.objects) do
        if e.def.kind=='worker' then
            e.phase=distance(e,g.home)<80 and 'idle' or 'stranded'
            e.recruit=e.phase=='stranded'; g.workers[#g.workers+1]=e
        elseif e.def.kind=='civilian' then
            e.phase='stranded';g.evacuees[#g.evacuees+1]=e
        end
    end
    refresh(g)
    return g
end
function M.route(g,from,target,footprint)
    local is_object=target.def~=nil
    local ignore=is_object and target.block or -1
    if g.nav:find(pos(from),pos(target),ignore or -1,footprint or {x=0,y=0}) then return g.nav.path,g.nav.length end
end
function M.affordable(g,e)
    for r,n in pairs(e.def.cost or {}) do if g.wallet[r]<n then return false end end
    return true
end
function M.actionable(e)
    return not e.done and not e.assigned and (e.def.kind=='obstacle' or e.def.kind=='station' or e.def.kind=='animal')
end
local function footprint(e)
    return e.def.kind=='animal' and {x=0,y=0} or {x=24,y=12}
end
function M.dispatch(g,e)
    if g.paused or g.won or not M.actionable(e) or not M.affordable(g,e) then return false end
    local chosen,path,shortest=nil,nil,math.huge
    for _,w in ipairs(g.workers) do
        if w.phase=='idle' then
            local p,d=M.route(g,w,e,footprint(e))
            if p and d<shortest then chosen,path,shortest=w,p,d end
        end
    end
    if not chosen then return false end
    for r,n in pairs(e.def.cost or {}) do g.wallet[r]=g.wallet[r]-n end
    e.assigned=true;e.queued=false
    chosen.target=e;chosen.path=path;chosen.step=2;chosen.phase='outbound';chosen.work=0
    return true
end
function M.click(g,e)
    if g.paused or g.won or not M.actionable(e) then return false end
    if e.queued then
        e.queued=false
        for i=#g.queue,1,-1 do if g.queue[i]==e then table.remove(g.queue,i) end end
        return true
    end
    if M.dispatch(g,e) then return true end
    e.queued=true;g.queue[#g.queue+1]=e
    return true
end
function M.detail(g,e)
    if not e then return 'Tap a job to send a worker. Tap again to cancel a queued job.' end
    if e.done then return e.def.kind=='station' and 'Supplies arrive automatically every 5 seconds.' or 'Restored.' end
    if e.assigned then return 'A worker is on the way.' end
    if e.def.kind=='civilian' or e.recruit then return 'Returns to headquarters automatically once the route is safe.' end
    local t={}
    for _,r in ipairs({'food','wood','money'}) do local n=(e.def.cost or {})[r];if n then t[#t+1]=n..' '..r end end
    return table.concat(t,'  /  ')..(e.queued and '  |  Queued - tap to cancel' or '  |  Tap to assign')
end
local function travel(w,dt)
    local budget=175*dt
    while budget>0 and w.step<=#w.path do
        local p=w.path[w.step];local d=distance(w,p)
        if d>.001 then w.direction=math.floor(math.atan(-(p.y-w.y),p.x-w.x)*4/math.pi+.5)%8 end
        if d<=budget then w.x,w.y=p.x,p.y;w.step=w.step+1;budget=budget-d
        else w.x=w.x+(p.x-w.x)*budget/d;w.y=w.y+(p.y-w.y)*budget/d;budget=0 end
    end
    return w.step>#w.path
end
local function return_home(g,w)
    local path=M.route(g,w,g.home)
    assert(path,'return route lost after completing a job')
    w.path=path;w.step=2;w.phase='returning'
end
local function event(g,e,kind)
    g.events[#g.events+1]={x=e.x,y=e.y,kind=kind}
end
local function tick(g,dt)
    g.time=g.time+dt
    for _,w in ipairs(g.workers) do
        if w.phase=='outbound' then
            if travel(w,dt) then w.phase='working';w.work=0 end
        elseif w.phase=='working' then
            w.work=w.work+dt
            local e=w.target
            if w.work+1e-7>=(e.def.duration or 5) then
                e.done=true;e.queued=false;e.clock=0
                for r,n in pairs(e.def.reward or {}) do g.wallet[r]=g.wallet[r]+n end
                if e.def.kind=='obstacle' then g.cleared=g.cleared+1;refresh(g) end
                event(g,e,'complete');return_home(g,w)
            end
        elseif w.phase=='returning' then
            if travel(w,dt) then
                if w.recruit then w.recruit=false;g.rescued=g.rescued+1;event(g,w,'rescue') end
                if w.target then
                    local e=w.target;e.assigned=false
                    if e.def.kind=='animal' then g.animals=g.animals+1;event(g,e,'rescue') end
                    w.target=nil
                end
                w.phase='idle'
            end
        end
    end
    -- Route changes wake stranded residents and recruits; civilians do not use a worker.
    if g.dirty then
        g.dirty=false
        for _,list in ipairs({g.workers,g.evacuees}) do
            for _,w in ipairs(list) do
                if w.phase=='stranded' then
                    local p=M.route(g,w,g.home)
                    if p then w.path=p;w.step=2;w.phase='returning' end
                end
            end
        end
    end
    for _,e in ipairs(g.evacuees) do
        if e.phase=='returning' and travel(e,dt) then
            e.phase='safe';e.done=true;g.rescued=g.rescued+1;event(g,e,'rescue')
        end
    end
    for _,e in ipairs(g.objects) do
        if e.def.kind=='station' and e.done then
            e.clock=e.clock+dt
            while e.clock+1e-7>=5 do
                e.clock=e.clock-5;g.wallet[e.def.resource]=g.wallet[e.def.resource]+e.def.income
                event(g,e,'income')
            end
        end
    end
    -- Retry the entire ordered queue, so one costly blocked job cannot starve repairs.
    g.retry=(g.retry or 0)+dt
    if g.retry>=.25 then
        g.retry=0;local pending={}
        for _,e in ipairs(g.queue) do if e.queued then
            if not M.dispatch(g,e) then pending[#pending+1]=e end
        end end
        g.queue=pending
    end
    g.won=g.rescued>=g.level.people and g.animals>=g.level.animals and g.cleared==g.routes
end
function M.update(g,dt)
    if g.paused or g.won then return end
    g.accumulator=g.accumulator+math.min(math.max(dt,0),.25)
    while g.accumulator+1e-9>=1/60 and not g.won do g.accumulator=g.accumulator-1/60;tick(g,1/60) end
end
-- An ordinary-action planner used for regressions and the optional on-screen hint.
-- It only selects a reachable affordable job; dispatch still pays and reserves normally.
function M.suggest(g,order)
    local best,score=nil,math.huge
    for _,e in ipairs(g.objects) do if M.actionable(e) and not e.queued and M.affordable(g,e) then
        local p=M.route(g,g.home,e,footprint(e))
        if p then
            local rank=e.def.kind=='station' and (e.def.resource=='food' and 0 or e.def.resource=='wood' and 1 or 2) or 10
            if order=='reverse' and rank>=10 then rank=rank-e.id*.001 end
            if order=='yard' and e.def.resource=='wood' then rank=-1 end
            if rank<score then best,score=e,rank end
        end
    end end
    return best
end
return M
