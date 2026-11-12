-- Shared rules, using original-archive fixtures and independent outcome checks.
local E,H=require('match3'),require('support')
local P=require('match3.patterns')
local t=H.suite('Homescapes hex port')
local R=E.new{flags=E.LINE_MATCHES}
local center=R.hex_center()
local function fixture(models,goals)
    local g=H.board(R)
    local spec={cells={},colors={[0]=100,[1]=100,[2]=100},goals=goals or {}}
    for i,entries in pairs(models) do spec.cells[i]={models=entries} end
    require('match3.homescapes').bind(R,function()return 0 end).init(g,spec)
    return g
end
local function hit(g,cell,direct)
    local m=R.new_match();m.mask[cell]=true
    m.direct=direct and {[cell]=true} or {};m.ordinary=direct and {} or {[cell]=true}
    R.game_apply(g,m);return m
end
for axis=0,2 do
    for count=3,5 do t:case('straight '..axis..' count '..count,function()
        local g,m=H.board(R),R.new_match();local i=R.hex_neighbor(center,axis+3)
        for _=1,count do g.tiles[i]=R.tile(2);i=R.hex_neighbor(i,axis) end
        R.game_matches(g,m,center)
        t:check(m.hits==count,'exact line clear')
        t:check(m.make[center]==(count==4 and axis+1 or count==5 and R.PRISM or nil),'source reward')
    end) end
    t:case('rhombus '..axis,function()
        local g,m=H.board(R),R.new_match()
        local a,b=R.hex_neighbor(center,axis),R.hex_neighbor(center,axis+1)
        for _,i in ipairs{center,a,b,R.hex_neighbor(a,axis+1)} do g.tiles[i]=R.tile(3) end
        R.game_matches(g,m,center)
        t:check(m.hits==4 and m.make[center]==R.PLANE,'rhombus creates plane')
    end)
end
t:case('cross makes bomb; powerups have no match color',function()
    local g,m=H.board(R),R.new_match()
    for d=0,4 do if d~=2 then g.tiles[R.hex_neighbor(center,d)]=R.tile(2) end end
    g.tiles[center]=R.tile(2);R.game_matches(g,m,center)
    t:check(m.hits==5 and m.make[center]==R.BOMB,'intersecting threes make bomb')
    g.tiles[center]=R.tile(2,R.ROW);R.game_matches(g,m,center)
    t:check(m.hits==0,'rocket cannot complete a colored line')
end)
for a=1,6 do for b=a,6 do t:case('combination '..a..' + '..b,function()
    local g,m=H.board(R),R.new_match();local n=R.hex_neighbor(center,0)
    for i=0,R.CELLS-1 do g.tiles[i]=R.tile(i%6) end
    g.tiles[center],g.tiles[n]=R.tile(0,a),R.tile(1,b)
    t:check(R.game_swap(g,center,n,m),'special pair is legal without color match')
    R.game_apply(g,m)
    t:check(g.moves==19 and g.tiles[center].kind==-1 and g.tiles[n].kind==-1,'both consumed for one move')
    if (a==6 or b==6) and a~=5 and b~=5 then
        t:check(#m.flights==(a==6 and b==6 and 3 or 1),'plane combination flight count')
    end
end) end end
t:case('rainbow conversion reaches the effect controller',function()
    local g,m=H.board(R),R.new_match();local n=R.hex_neighbor(center,0)
    for i=0,R.CELLS-1 do g.tiles[i]=R.tile(2) end
    g.tiles[center],g.tiles[n]=R.tile(0,R.PRISM),R.tile(1,R.ROW)
    t:check(R.game_swap(g,center,n,m),'rainbow and rocket combine');R.game_apply(g,m)
    local count=0;for _,special in pairs(m.activations) do if special==R.ROW then count=count+1 end end
    t:check(count==R.CELLS-2,'every converted rocket emits its activation for animation')
end)
t:case('activation does not need adjacent match',function()
    local g,m=H.board(R),R.new_match();g.tiles[center]=R.tile(4,R.PLANE)
    t:check(R.game_activate(g,center,m),'plane activates');R.game_apply(g,m)
    t:check(g.moves==19 and #m.flights==1,'single move and visible flight event')
end)
t:case('queue repeats, independent cursors, finite fallback',function()
    local model={id='0',pattern='[t1][c6][lh]',isLooped='0'}
    local spec={bornPatterns={{str=model.pattern,isLooped='false',settings={{{name='CountProperty',count='2'}},{},{}}}}}
    local a,b=P.queue(model,spec),P.queue(model,spec)
    t:check(P.next(a).element=='cookie' and P.next(a).element=='cookie','repeat count')
    t:check(P.next(a).color==5 and P.next(b).element=='cookie','independent cursors and one-based color')
    t:check(P.next(a).special=='lh' and P.next(a)==nil,'finite exhausted')
    for _,bad in ipairs{'[c]tail','[bad]','[[c]]',''} do
        model.pattern=bad;spec.bornPatterns[1].str=bad
        t:check(not pcall(P.queue,model,spec),'unknown syntax rejected')
    end
end)
t:case('layer precedence and covered tile',function()
    local g=fixture({[center]={{modelId='NORMAL',color='1'},{modelId='ICE',level='1'},{modelId='LOCK',level='1'},{modelId='BUBBLE_MEMBRANE',level='2'}}},
        {{type='ICE',max=1},{type='LOCK',max=1},{type='BUBBLE_MEMBRANE',max=1}})
    hit(g,center,true);t:check(g.ice[center]==0 and g.chain[center]==1 and g.hs.cells[center].tile==2,'ice absorbs before chain and tile')
    hit(g,center,true);t:check(g.chain[center]==0 and g.hs.cells[center].tile==2,'chain absorbs before floor')
    hit(g,center,false);t:check(g.hs.cells[center].tile==2,'double tile needs powerup')
    g.tiles[center]=R.tile(1);hit(g,center,true);t:check(g.hs.cells[center].tile==1,'powerup breaks first layer')
    g.tiles[center]=R.tile(1);hit(g,center,false)
    t:check(g.hs.goals[3].current==1,'single tile clears by match')
end)
for _,pair in ipairs{{'BOX','BOX'},{'TRASH','TRASH'},{'TRASH_STONE','TRASHSTONE'},{'STATUE','STATUE'}} do
    t:case('durability '..pair[1],function()
        local g=fixture({[center]={{modelId=pair[1],level='2'}}},{{type=pair[2],max=1}})
        hit(g,center,true);t:check(g.hs.goals[1].current==0,'not credited prematurely')
        hit(g,center,true);t:check(g.hs.goals[1].current==1,'credited on destruction')
    end)
end
t:case('colored boxes and nuts resist wrong damage',function()
    local n=R.hex_neighbor(center,0)
    local g=fixture({[center]={{modelId='COLOR_BOX',color='2',level='1'}},[n]={{modelId='NORMAL',color='1'}}})
    hit(g,n,false);t:check(g.hs.cells[center].box==1,'wrong adjacent color')
    g.tiles[n]=R.tile(2);hit(g,n,false);t:check(g.hs.cells[center].box==0,'matching adjacent color')
    g=fixture({[center]={{modelId='TRASH_STONE',level='2'}},[n]={{modelId='NORMAL',color='1'}}})
    hit(g,n,false);t:check(g.tiles[center].hp==2,'nuts ignore adjacent matches')
end)
t:case('shared footprint receives one hit per wave',function()
    local g=fixture({[center]={{modelId='TARGET_GEN',level='2'}}},{{type='TARGET_GENERATOR',max=2}})
    local group=g.hs.groups[center];local m=R.new_match();m.direct={}
    for _,i in ipairs(group.cells) do m.mask[i],m.direct[i]=true,true end
    R.game_apply(g,m);t:check(group.count==1 and g.hs.goals[1].current==1,'one apple despite four cells hit')
    R.game_apply(g,m);t:check(g.hs.groups[center]==nil and g.hs.goals[1].current==2,'group removed together')
end)
t:case('copy isolates generator and mobile durability',function()
    local g=fixture({[center]={{modelId='TRASH',level='3'}}})
    local copy=R.game_copy(g);hit(copy,center,true)
    t:check(g.tiles[center].hp==3 and copy.tiles[center].hp==2,'simulating hint cannot mutate live cookie')
end)
t:case('simultaneous refill obeys the global population cap',function()
    local g=H.board(R);local a,b=R.hex_index(-2,-1),R.hex_index(2,-1)
    for i=0,R.CELLS-1 do g.active[i]=i==a or i==b end
    require('match3.homescapes').bind(R,function()return 0 end).init(g,{
        cells={[a]={models={{modelId='BORN'},{modelId='NORMAL',color='0'}}},
               [b]={models={{modelId='BORN'},{modelId='NORMAL',color='1'}}}},
        goals={{type='TRASH',max=5}},refill={{goal='TRASH',element='cookie',hp=1,chance=100,max=1,limited=true}}})
    g.tiles[a],g.tiles[b]=R.tile(-1),R.tile(-1)
    R.game_collapse(g)
    local count=0;for _,i in ipairs{a,b} do if g.tiles[i].element=='cookie' then count=count+1 end end
    t:check(count==1,'two simultaneous inlets cannot each claim the last available slot')
end)
t:case('blind opens from bottom once per wave',function()
    local g=fixture({[center]={{modelId='SHUTTERS',shutterHeight='3'}}},{{type='SHUTTERS',max=1}})
    local group=g.hs.groups[center];local bottom=group.cells[3]
    local m=R.new_match();m.direct={}
    for _,i in ipairs(group.cells) do m.mask[i],m.direct[i]=true,true end
    R.game_apply(g,m)
    t:check(group.count==2 and not g.hs.cells[bottom].group and g.hs.cells[center].group==center,'only bottom cell released')
    hit(g,center,true);hit(g,center,true)
    t:check(g.hs.goals[1].current==1 and not g.hs.groups[center],'one goal at complete opening')
end)
t:case('destroyed stack releases three animated cookies',function()
    local g=fixture({[center]={{modelId='COOKIE_BOX',level='1'}}})
    hit(g,center,true);local _,steps=R.game_collapse(g)
    local count=0;for _,piece in pairs(g.tiles) do if piece.element=='cookie' then count=count+1 end end
    t:check(count==3 and g.hs.pendingCookies==0,'exact release count')
    local births=0;for _,from in pairs(steps[#steps].from) do if from<0 then births=births+1 end end
    t:check(births==3,'release enters existing fall/birth animation steps')
end)
t:case('maker respects designated cells and remaining goal',function()
    local destinations={R.hex_index(-3,0),R.hex_index(-3,1),R.hex_index(-3,2)}
    local models={[center]={{modelId='CARRY_GEN',carryGenActivatePer='1',carryGenMax='3'}}}
    for _,i in ipairs(destinations) do models[i]={{modelId='CARRY_GEN_CELLS'},{modelId='NORMAL',color='2'}} end
    local g=fixture(models,{{type='CARRY',max=2}})
    hit(g,center,true);R.game_collapse(g)
    local count=0;for i,piece in pairs(g.tiles) do if piece.kind==R.DELIVERY then
        count=count+1;t:check(g.hs.cells[i].carrySpawn,'designated source destination')
    end end
    t:check(count==2 and g.hs.groups[center].hits==0,'batch capped by remaining goal and charge reset')
end)
local references=require('match3.reference')
for name,ref in pairs(references) do t:case('original archive '..name,function()
    local rules=E.new{flags=E.LINE_MATCHES,radius=ref.radius,levels={ref.level}}
    local g=rules.game_start(0,ref.seed)
    t:check(g.moves==ref.level.moves and #g.hs.goals==#ref.level.homescapes.goals,'source moves and goals')
    local active=0
    for i=0,rules.CELLS-1 do if rules.game_cell_active(g,i) then active=active+1 end end
    local count=0;for _ in pairs(ref.level.homescapes.cells) do count=count+1 end
    t:check(active==count,'source topology retained')
    for _=1,3 do
        local ok,a,b=rules.game_hint(g)
        if not ok then break end
        local m=rules.new_match();t:check(rules.game_swap(g,a,b,m),'hint plays')
        local waves=0
        repeat rules.game_apply(g,m);rules.game_collapse(g);rules.game_matches(g,m,-1);waves=waves+1 until m.hits==0 or waves==30
        t:check(waves<30,'source board settles')
        t:check(g.obstacles>=0,'source restraint counter never becomes negative')
    end
end) end
return t:finish()
