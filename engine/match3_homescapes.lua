-- Original-resource model semantics, adapted to axial cell IDs. Presentation is
-- still the shared phase controller; no game supplies rule callbacks.
local Base={}
local patterns=require('match3.patterns')
function Base.copy(value)
    if type(value)~='table' then return value end
    local out={};for k,v in pairs(value) do out[k]=Base.copy(v) end;return out
end
function Base.solid(g,i)
    local c=g.hs and g.hs.cells[i]
    return c and ((c.box or 0)>0 or (c.jelly or 0)>0 or (c.statue or 0)>0 or (c.stack or 0)>0 or c.group) or false
end
function Base.credit(g,kind,subtype,amount)
    if not g.hs then return end
    for _,goal in ipairs(g.hs.goals) do
        if goal.type==kind and (goal.subtype or '')==(subtype or '') then
            goal.current=math.min(goal.max,goal.current+(amount or 1))
        end
    end
end
function Base.won(g)
    for _,goal in ipairs(g.hs.goals) do if goal.current<goal.max then return false end end
    return true
end
function Base.bind(M,random)
    local H=setmetatable({}, {__index=Base})
    local function active(g,i) return i and i>=0 and M.game_cell_active(g,i) end
    local function unheld(g,i) return active(g,i) and not H.solid(g,i) and g.ice[i]==0 and g.chain[i]==0 end
    local function gem(t) return t.kind>=0 and t.special==M.NORMAL and not t.element end
    local specials={b=M.BOMB,f=M.PLANE,z=M.PRISM,lh=M.ROW,lv=M.COLUMN}
    local function choose(g,weights)
        local total=0
        for k=0,M.COLORS-1 do total=total+(weights and weights[k] or not weights and 100 or 0) end
        assert(total>0,'empty source colors')
        local value=random(g,total)
        for k=0,M.COLORS-1 do
            value=value-(weights and weights[k] or not weights and 100 or 0)
            if value<0 then return k end
        end
    end
    local function object(name,hp) return {kind=0,special=M.NORMAL,element=name,hp=hp or 1} end
    function H.init(g,spec)
        if not spec then return end
        g.hs={cells={},groups={},queues={},palettes={},sources={},goals=H.copy(spec.goals or {}),
            colors=H.copy(spec.colors),refill=H.copy(spec.refill or {}),pendingCookies=0}
        for _,goal in ipairs(g.hs.goals) do
            assert(({CHIPS=true,CELL_JELLY=true,BOX=true,TRASH=true,ICE=true,LOCK=true,CARRY=true,
                COLLECT_PIGGY=true,COLOR_BOX=true,TRASHSTONE=true,TARGET_GENERATOR=true,STATUE=true,
                BUBBLE_MEMBRANE=true,SHUTTERS=true,CELL_OIL=true})[goal.type],'unsupported source goal '..goal.type)
            goal.current=goal.current or 0
        end
        for i=0,M.CELLS-1 do if active(g,i) then
            local c={};g.hs.cells[i]=c;g.tiles[i]=M.tile(-1)
            for _,model in ipairs((spec.cells[i] or {}).models or {}) do
                local id,n=model.modelId,tonumber(model.level) or 1
                if id=='NORMAL' and tonumber(model.color) and tonumber(model.color)>=0 then g.tiles[i]=M.tile(tonumber(model.color))
                elseif id=='NORMAL' or id=='NONE_CHIP' then g.tiles[i]=M.tile(-1)
                elseif id=='RANDOM_CHIP' then
                    local colors=assert((spec.randomPatterns or {})[tonumber(model.id)+1],'missing RANDOM_CHIP pattern')
                    local weights={};for _,k in ipairs(colors) do weights[k]=(spec.colors or {})[k] or 100 end
                    g.tiles[i]=M.tile(choose(g,weights))
                elseif id=='BOMB' then g.tiles[i]=M.tile(0,M.BOMB)
                elseif id=='FISH' then g.tiles[i]=M.tile(0,M.PLANE)
                elseif id=='LIGHTNING' then g.tiles[i]=M.tile(0,M.PRISM)
                elseif id=='LINE' then g.tiles[i]=M.tile(0,model.line_orient=='0' and M.ROW or M.COLUMN)
                elseif id=='BOX' or id=='COLOR_BOX' then
                    c.box=n;c.color=id=='COLOR_BOX' and assert(tonumber(model.color),'missing box color') or nil
                    assert(not c.color or c.color>=0 and c.color<6,'invalid box color')
                elseif id=='HONEY' then c.jelly=n
                elseif id=='STATUE' then c.statue=n
                elseif id=='COOKIE_BOX' then c.stack=n
                elseif id=='TRASH' then g.tiles[i]=object('cookie',n)
                elseif id=='TRASH_STONE' then g.tiles[i]=object('hazelnut',n)
                elseif id=='CHERRY' then g.tiles[i]=object('cherry')
                elseif id=='CARRY' then g.tiles[i]=M.tile(M.DELIVERY)
                elseif id=='CARRY_EXIT' then g.delivery_exits[i]=true
                elseif id=='ICE' then g.ice[i]=n
                elseif id=='LOCK' then g.chain[i]=n;c.mirror=model.mirror=='true'
                elseif id=='JELLY' then c.carpet=true
                elseif id=='OIL' then g.oil[i]=1;g.oil_left=g.oil_left+1
                elseif id=='BUBBLE_MEMBRANE' then assert(n==1 or n==2,'invalid tile strength');c.tile=n
                elseif id=='CARRY_GEN_CELLS' then c.carrySpawn=true
                elseif id=='BORN' then g.hs.sources[i]=true
                elseif id=='ARTIFACT_GEN' then g.hs.queues[i]=patterns.queue(model,spec);c.visibleGenerator=model.isTexture=='1'
                elseif id=='PATTERN_COLOR_BORN' then g.hs.palettes[i]=patterns.palette(model,spec)
                elseif id=='TARGET_GEN' or id=='CARRY_GEN' or id=='SHUTTERS' then
                    local anchor=model.mainCell or i;c.group=anchor
                    if not model.mainCell then
                        local group={kind=id,hits=0,count=n,cells={}}
                        if id=='SHUTTERS' then
                            group.count=assert(tonumber(model.shutterHeight),'blind height')
                            assert(group.count>=1 and group.count<=9,'blind height')
                            for dy=0,group.count-1 do group.cells[#group.cells+1]=M.hex_index(M.hex_q(i),M.hex_r(i)+dy) end
                        else
                            group.cells={i,M.hex_neighbor(i,0),M.hex_neighbor(i,1),M.hex_index(M.hex_q(i)+1,M.hex_r(i)+1)}
                            if id=='CARRY_GEN' then
                                group.period=assert(tonumber(model.carryGenActivatePer),'maker period')
                                group.batch=assert(tonumber(model.carryGenMax),'maker batch')
                                assert(group.period>0 and group.batch>0,'maker configuration')
                            end
                        end
                        g.hs.groups[i]=group
                    end
                else error('unsupported source model '..tostring(id)) end
            end
        end end
        for anchor,group in pairs(g.hs.groups) do
            for _,i in ipairs(group.cells) do
                assert(active(g,i),'source footprint outside board')
                local c=g.hs.cells[i]
                assert(not c.group or c.group==anchor,'overlapping source footprints')
                c.group=anchor
            end
        end
        for i,c in pairs(g.hs.cells) do
            if c.group then
                local group=assert(g.hs.groups[c.group],'missing source group anchor')
                local found=false;for _,p in ipairs(group.cells) do found=found or p==i end
                assert(found,'source proxy outside footprint')
            end
        end
        g.obstacles=0
        for i=0,M.CELLS-1 do if active(g,i) then g.obstacles=g.obstacles+g.ice[i]+g.chain[i] end end
        g.initial_obstacles=g.obstacles
        -- Starting pieces are explicit; only initially empty cells consume queues.
        for i=0,M.CELLS-1 do if active(g,i) and not H.solid(g,i) and g.tiles[i].kind==-1 then
            local source=i
            while unheld(g,source) and not H.source(g,source) do source=M.hex_neighbor(source,4) end
            g.tiles[i]=unheld(g,source) and (g.hs.queues[source] or g.hs.palettes[source]) and H.spawn(g,source) or M.tile(choose(g,g.hs.colors))
        end end
    end
    function H.source(g,i)
        return g.hs and (g.hs.queues[i] or g.hs.palettes[i] or g.hs.sources[i])
    end
    function H.spawn(g,i,tiles)
        if not g.hs then return nil end
        local queue=g.hs.queues[i]
        local unit=queue and patterns.next(queue)
        if unit then
            if unit.element then return object(unit.element,unit.hp)
            elseif unit.special then return M.tile(0,unit.special=='l' and (random(g,3)+1) or specials[unit.special])
            else return M.tile(unit.color or choose(g,unit.weights or g.hs.palettes[i] or g.hs.colors)) end
        end
        for _,rule in ipairs(g.hs.refill) do
            local eligible=H.source(g,i) and (not rule.sources or rule.sources[i])
            local maker=false;for _,group in pairs(g.hs.groups) do maker=maker or group.kind=='CARRY_GEN' end
            if rule.goal=='CARRY' and maker then eligible=false end
            if eligible then
                local count,remaining=0,0
                for _,t in pairs(tiles or g.tiles) do if rule.element and t.element==rule.element or rule.goal=='CARRY' and t.kind==M.DELIVERY then count=count+1 end end
                for _,goal in ipairs(g.hs.goals) do if goal.type==rule.goal then remaining=remaining+math.max(0,goal.max-goal.current) end end
                if count<rule.max and (not rule.limited or count<remaining) and random(g,100)<rule.chance then
                    return rule.goal=='CARRY' and M.tile(M.DELIVERY) or object(rule.element,rule.hp)
                end
            end
        end
        return M.tile(choose(g,g.hs.palettes[i] or g.hs.colors))
    end
    function H.apply(g,m)
        if not g.hs then return {} end
        local protected,hitgroups,adjacent,colors={},{},{},{}
        for i=0,M.CELLS-1 do if m.mask[i] then
            if m.ordinary[i] then
                for d=0,5 do local n=M.hex_neighbor(i,d);if active(g,n) then
                    adjacent[n]=true;colors[n]=colors[n] or {};colors[n][g.tiles[i].kind]=true
                end end
            end
            if m.direct[i] then
                for d=0,5 do local n=M.hex_neighbor(i,d);if active(g,n) and (g.hs.cells[n].jelly or 0)>0 then adjacent[n]=true end end
            end
        end end
        for i=0,M.CELLS-1 do if active(g,i) and (m.mask[i] or adjacent[i]) then
            local c,t=g.hs.cells[i],g.tiles[i]
            local direct=m.direct[i]
            local hit=m.mask[i]
            local held=not unheld(g,i)
            if c.group then hitgroups[c.group]=true;protected[i]=true
            elseif g.ice[i]>0 then if hit and g.ice[i]==1 then H.credit(g,'ICE') end
            elseif g.chain[i]>0 then if hit and g.chain[i]==1 then H.credit(g,'LOCK') end
            elseif (c.jelly or 0)>0 then
                c.jelly=c.jelly-1;protected[i]=true;m.mask[i]=true
                if c.jelly==0 and t.element=='cherry' then g.tiles[i]=M.tile(-1);H.credit(g,'COLLECT_PIGGY') end
            elseif (c.box or 0)>0 then
                protected[i]=true
                if not c.color or direct or (colors[i] or {})[c.color] then
                    c.box=c.box-1;m.mask[i]=true
                    if c.box==0 then H.credit(g,c.color and 'COLOR_BOX' or 'BOX') end
                end
            elseif (c.statue or 0)>0 then
                protected[i]=true
                if direct then c.statue=c.statue-1;if c.statue==0 then H.credit(g,'STATUE') end end
            elseif (c.stack or 0)>0 then
                protected[i]=true;c.stack=c.stack-1;m.mask[i]=true
                if c.stack==0 then g.hs.pendingCookies=g.hs.pendingCookies+3 end
            elseif t.element then
                protected[i]=true
                local damage=t.element=='cookie' or t.element=='cherry' or direct
                if damage then
                    local next_tile=H.copy(t);next_tile.hp=next_tile.hp-1;m.mask[i]=true
                    if next_tile.hp<=0 then
                        H.credit(g,t.element=='cookie' and 'TRASH' or t.element=='hazelnut' and 'TRASHSTONE' or 'COLLECT_PIGGY')
                        g.tiles[i]=M.tile(-1)
                    else g.tiles[i]=next_tile end
                end
            elseif hit and gem(t) and not held then H.credit(g,'CHIPS',tostring(t.kind)) end
            if hit and not held and (c.tile or 0)>0 and (c.tile==1 or direct) then
                c.tile=c.tile-1;if c.tile==0 then H.credit(g,'BUBBLE_MEMBRANE') end
            end
            if hit and not H.solid(g,i) and not c.carpet and (m.carrycarpet or (m.spread or {})[i]) then
                c.carpet=true;H.credit(g,'CELL_JELLY')
            end
        end end
        for anchor in pairs(hitgroups) do
            local group=g.hs.groups[anchor]
            if group.kind=='CARRY_GEN' then group.hits=group.hits+1
            elseif group.kind=='SHUTTERS' then
                local i=group.cells[group.count];g.hs.cells[i].group=nil
                group.count=group.count-1
                if group.count==0 then H.credit(g,'SHUTTERS');g.hs.groups[anchor]=nil end
            else
                group.count=group.count-1;H.credit(g,'TARGET_GENERATOR')
                if group.count==0 then
                    for _,i in ipairs(group.cells) do g.hs.cells[i].group=nil end
                    g.hs.groups[anchor]=nil
                end
            end
        end
        return protected
    end
    function H.release(g)
        if not g.hs then return end
        for i=0,M.CELLS-1 do if g.hs.pendingCookies>0 and unheld(g,i) and gem(g.tiles[i]) then
            g.tiles[i]=object('cookie');g.hs.pendingCookies=g.hs.pendingCookies-1
        end end
        for anchor=0,M.CELLS-1 do
            local group=g.hs.groups[anchor]
            if group and group.kind=='CARRY_GEN' and group.hits>=group.period then
                local needed=0
                for _,goal in ipairs(g.hs.goals) do if goal.type=='CARRY' then needed=needed+goal.max-goal.current end end
                for _,t in pairs(g.tiles) do if t.kind==M.DELIVERY then needed=needed-1 end end
                local count=0
                for i=0,M.CELLS-1 do if count<math.min(group.batch,needed) and unheld(g,i) and g.hs.cells[i].carrySpawn and gem(g.tiles[i]) then
                    g.tiles[i]=M.tile(M.DELIVERY);count=count+1
                end end
                if count>0 then group.hits=0 end
            end
        end
    end
    return H
end
return Base
