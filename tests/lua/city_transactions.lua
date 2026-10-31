local H=require('support')
local t=H.suite('engine city transactions')
local spot=vec2(5000,5000)
local function purchase(c,w,mode)
    if mode=='confirm' then c:begin_place(0,spot);return c:confirm(w,app.clock()) end
    c.selected=0
    return c:update(input{tap=true,pos=spot,press_pos=spot,pinch=1},w,app.clock(),0)
end
for _,mode in ipairs({'confirm','quick'}) do
    for slot=1,purse.MAX do
        t:case(mode..' multi-resource short slot '..slot,function()
            local cost=purse(10,20,30,40,50,60)
            local c=H.city({{cost=cost,reward=purse(100,100,100,100,100,100)}})
            local w=purse(10,20,30,40,50,60);w[slot]=w[slot]-1
            local before=purse(table.unpack(w))
            t:check(purchase(c,w,mode).result==city.CANT_AFFORD,'reward cannot fund its own purchase')
            t:check(c.count==0 and H.same(w,before),'no partial deductions or rewards')
            w[slot]=w[slot]+1
            t:check(purchase(c,w,mode).result==city.BUILT,'retry succeeds with exact cost')
            t:check(H.same(w,purse(100,100,100,100,100,100)),'all costs subtracted, reward once')
        end)
        t:case(mode..' threshold slot '..slot,function()
            local cost,needs=purse(),purse();cost[slot],needs[slot]=5,10
            local c=H.city({{cost=cost,needs=needs}})
            local w=purse();w[slot]=9
            t:check(purchase(c,w,mode).result==city.LOCKED_TYPE and w[slot]==9,'gate checked before payment')
            w[slot]=10
            t:check(purchase(c,w,mode).result==city.BUILT and w[slot]==5,'threshold is retained, only cost spent')
        end)
    end
    t:case(mode..' blocked and full cities preserve stock',function()
        local c=H.city({{cost=purse(5),reward=purse(0,20)}})
        local w=purse(10)
        c.buildable=function()return false end
        t:check(purchase(c,w,mode).result==city.BLOCKED and w[1]==10 and w[2]==0,'invalid terrain is free')
        c.buildable=nil
        c.count=city.MAX
        t:check(purchase(c,w,mode).result==city.BLOCKED and w[1]==10 and w[2]==0,'full city is free')
    end)
end
t:case('timed income uses injected time and cannot pay twice',function()
    testing.reset()
    local c=H.city({{income=purse(7),income_period=60,height=100}})
    c:add(spot,0,app.clock())
    local w=purse()
    local tap=input{tap=true,pos=spot-vec2(0,20),press_pos=spot-vec2(0,20),pinch=1}
    t:check(c:update(tap,w,app.clock(),0).result==city.NOT_READY,'new building waits')
    testing.advance(59)
    t:check(not c:ready(0,app.clock()),'just before income boundary')
    testing.advance(1)
    t:check(c:update(tap,w,app.clock(),0).result==city.COLLECTED and w[1]==7,'exact boundary pays')
    t:check(c:update(tap,w,app.clock(),0).result==city.NOT_READY and w[1]==7,'duplicate collect pays nothing')
end)
t:case('injected hold picks up without spending, cancellation retains original',function()
    testing.reset()
    local c=H.city({{cost=purse(50),height=100}})
    c.movable=true
    local original=c:snap(spot,0)
    c:add(original,0,app.clock())
    local w=purse()
    local finger=original-vec2(0,20)
    local function tick(pointer,dt)
        testing.input(pointer)
        testing.advance(dt)
        c:update(input.get(),w,app.clock(),app.dt())
    end
    tick({pressed=true,down=true,pos=finger,press_pos=finger,pinch=1},0)
    tick({down=true,pos=finger,press_pos=finger,pinch=1},.49)
    t:check(c.placing==-1 and c.count==1,'short hold cannot pick up')
    tick({down=true,pos=finger,press_pos=finger,pinch=1},.02)
    t:check(c.moving==0 and c.placing==0 and w[1]==0,'long hold picks up even with empty wallet')
    tick({down=true,dragging=true,pos=finger+vec2(100,0),press_pos=finger,pinch=1},.01)
    tick({released=true,tap=true,pos=finger+vec2(100,0),press_pos=finger,pinch=1},.01)
    t:check(c.placing==0 and c.items[1].pos.x==original.x and w[1]==0,'release is only an uncommitted preview')
    c:cancel()
    t:check(c.items[1].pos.x==original.x and c.items[1].pos.y==original.y and w[1]==0,'cancel restores building without payment')
end)
for slot=1,purse.MAX do
    t:case('region short resource '..slot,function()
        local c=H.city({})
        local cost=purse(1,2,3,4,5,6)
        c.zones={{area=rect(0,0,1000,1000)}, {area=rect(1000,0,1000,1000),cost=cost,needs=purse(0,0,0,0,0,10)}}
        local w=purse(1,2,3,4,5,10);w[slot]=cost[slot]-1
        local before=purse(table.unpack(w))
        t:check(not c:unlock(1,w) and H.same(w,before) and c.open==1,'failed unlock is atomic')
        w=purse(1,2,3,4,5,10)
        t:check(c:unlock(1,w) and H.same(w,purse(0,0,0,0,0,4)),'unlock spends each cost, retains threshold')
        t:check(not c:unlock(1,w) and w[6]==4,'repeat unlock cannot charge')
    end)
end
return t:finish()
