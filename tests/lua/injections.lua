local t = require('support').suite('test-only injections')
t:case('clock advances instantly without sleeping', function()
    testing.reset()
    local epoch = app.clock()
    t:check(app.time()==0 and app.dt()==0, 'reset frame time')
    testing.advance(60)
    t:check(app.clock()==epoch+60 and app.time()==60 and app.dt()==60, 'advance both clocks')
    t:check(not pcall(testing.advance, -1), 'negative dt rejected')
    t:check(not pcall(testing.advance, math.huge), 'infinite dt rejected')
    t:check(not pcall(testing.advance, 0/0), 'NaN dt rejected')
end)
t:case('injected input reaches the real engine input getter', function()
    testing.input{pos=vec2(200,300),press_pos=vec2(200,300),pressed=true,down=true,pinch=1}
    local p=input.get()
    t:check(p.pressed and p.down and p.pos.x==200 and p.pos.y==300, 'press')
    testing.input{pos=vec2(210,310),released=true,pinch=1}
    p=input.get()
    t:check(p.released and not p.down and not p.pressed, 'release clears press')
    testing.reset()
    t:check(not input.get().released and app.time()==0, 'reset clears injected state')
end)
t:case('named cases report and continue after Lua errors', function()
    local probe=require('support').suite('expected harness failure')
    probe.expected_failures=true
    -- Suppress the deliberately failing case's diagnostic.
    local original=print
    print=function() end
    probe:case('throws',function() error('expected') end)
    print=original
    probe:case('continues',function() probe:check(true) end)
    t:check(probe.failures==1 and probe.cases==2, 'one error cannot skip later cases')
end)
t:case('engine-to-Lua callback errors reach the enclosing case', function()
    local c=require('support').city({{cost=purse()}})
    local w=purse()
    c.buildable=function()error('injected terrain failure')end
    c:begin_place(0,vec2(5000,5000))
    local ok,err=pcall(function()c:confirm(w,0)end)
    t:check(not ok and tostring(err):find('injected terrain failure',1,true), 'callback error is catchable')
    t:check(c.count==0 and w[1]==0, 'callback failure did not charge')
    c.buildable=nil
    t:check(c:confirm(w,0).result==city.BUILT, 'later engine calls still work')
end)
return t:finish()
