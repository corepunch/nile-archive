-- Presentation of optional match-three elements. Games provide the atlas;
-- rules and board layouts stay independent of this drawing code.
local E = {}

E.assets = {"stone-1", "stone-2", "stone-3", "tunnel-in", "tunnel-out",
    "hidden-covered", "hidden-partial", "hidden-revealed", "growth", "delivery", "delivery-exit", "object-goal"}
for kind = 0, 5 do
    for hp = 1, 2 do E.assets[#E.assets + 1] = ("crate-%d-%d"):format(kind, hp) end
end

for i=0,5 do
    E.assets[#E.assets+1]="kind-"..i
    E.assets[#E.assets+1]="goal-chip-"..i
end
for _,name in ipairs{"box","carry","jelly","lock","piggy","target-generator","trash"} do
    E.assets[#E.assets+1]="goal-"..name
end
for _,name in ipairs{"plane","chain-2","chain-1-mirror","carpet","cookie-1","cookie-2","cookie-3","cherry","honey-material","box-1","box-2","box-3","box-4","box-5","box-6"} do
    E.assets[#E.assets+1]=name
end

for hp=1,3 do
    for _,family in ipairs{"hazelnut","statue","cookie-stack"} do E.assets[#E.assets+1]=family.."-"..hp end
end
for hp=1,2 do E.assets[#E.assets+1]="membrane-fill-"..hp end

for n=1,9 do E.assets[#E.assets+1]="apple-platter-"..n end
for n=0,3 do E.assets[#E.assets+1]="donut-maker-"..n end
for _,name in ipairs{"blind-top","blind-body","generator-shell"} do E.assets[#E.assets+1]=name end

function E.load(art, skin)
    for _, name in ipairs(E.assets) do art[name] = assert(skin[name], "missing element art: " .. name) end
    art.object = art["object-goal"]
end

local function image(R, name, at, size, alpha)
    gfx.image(R.board_art[name], rect.centered(at, size2.splat(size)), color(255, 255, 255, alpha * 255))
end

-- Called after every well has been painted, before snow and pieces. A hidden
-- object's one authored image spans its complete footprint, not one per cell.
function E.ground(R, rules, sx)
    local g = R.g
    for _, object in ipairs(g.objects or {}) do
        local x, y, minx, maxx, miny, maxy = 0, 0, math.huge, -math.huge, math.huge, -math.huge
        for _, cell in ipairs(object.cells) do
            local p = R.cell_pos(cell) + vec2(sx, 0)
            x, y = x + p.x, y + p.y
            minx, maxx, miny, maxy = math.min(minx, p.x), math.max(maxx, p.x), math.min(miny, p.y), math.max(maxy, p.y)
        end
        if #object.cells > 0 then
            local size = 2 * R.HEX_R + math.max(maxx - minx, maxy - miny)
            local cx, cy = x / #object.cells, y / #object.cells
            local radius, height = R.HEX_R - .65, math.sqrt(3) * (R.HEX_R - .65)
            local alpha = R.intro and R.intro:fade() or 1
            local art = object.art and R.board_art[object.art] or R.board_art.carpet
            -- Each hex samples its portion of the same footprint image. This
            -- prevents a large object from spilling into holes or other wells.
            for _, cell in ipairs(object.cells) do
                local p = R.cell_pos(cell) + vec2(sx, 0)
                local src = rect((p.x - cx + size / 2 - radius) * 128 / size,
                    (p.y - cy + size / 2 - height / 2) * 128 / size,
                    2 * radius * 128 / size, height * 128 / size)
                gfx.image_hex(art, src, p, radius, 0, color(255, 255, 255, 255 * alpha))
            end
        end
    end
    for i = 0, rules.CELLS - 1 do
        if rules.game_cell_active(g, i) then
            local at = R.cell_pos(i) + vec2(sx, 0)
            local alpha = R.intro and R.intro:fade() or 1
            if g.hs then
                local c=g.hs.cells[i]
                if c.carpet then image(R,"carpet",at,2*(R.HEX_R-.65),alpha) end
                if (c.tile or 0)>0 then image(R,"membrane-fill-"..c.tile,at,2*R.HEX_R,alpha) end
            end
            if g.tunnel_to and g.tunnel_to[i] then R.say_at("IN",at+vec2(0,R.HEX_R*.6),10,R.PAL_WHITE,50) end
            if g.tunnel_from and g.tunnel_from[i] then R.say_at("OUT",at+vec2(0,R.HEX_R*.6),10,R.PAL_WHITE,50) end
            if g.delivery_exits and g.delivery_exits[i] then R.say_at("EXIT",at+vec2(0,R.HEX_R*.6),10,R.PAL_WHITE,50) end
        end
    end
end

local function group_art(R,group,sx)
    local cx,cy,minx,maxx,miny,maxy=0,0,math.huge,-math.huge,math.huge,-math.huge
    for _,cell in ipairs(group.cells) do
        local p=R.cell_pos(cell)
        cx,cy=cx+p.x,cy+p.y
        minx,maxx,miny,maxy=math.min(minx,p.x),math.max(maxx,p.x),math.min(miny,p.y),math.max(maxy,p.y)
    end
    local name=group.kind=='TARGET_GEN' and 'apple-platter-'..group.count
        or 'donut-maker-'..math.min(3,math.floor(group.hits*3/group.period))
    assert(R.board_art[name],"missing original group art: "..name)
    local size=math.min(maxx-minx+2*R.HEX_R,maxy-miny+math.sqrt(3)*R.HEX_R)
    image(R,name,vec2(cx/#group.cells+sx,cy/#group.cells),size,1)
end

local function generator_art(R,g,i,at,alpha)
    image(R,"generator-shell",at,2*R.HEX_R,alpha)
    local queue=g.hs.queues[i]
    local unit=queue and queue.units[queue.cursor]
    if not unit then return end
    local powers={b='bomb',f='plane',z='prism',l='ray-column',lh='ray-row',lv='ray-column'}
    local name=unit.element and unit.element..'-'..unit.hp or unit.special and powers[unit.special]
        or unit.color and 'kind-'..unit.color
    if name then image(R,name,at-vec2(0,R.HEX_R*.12),R.HEX_R*.95,alpha) end
end

-- Fixed blockers cover the piece area; growth covers a still-present piece.
function E.blockers(R, rules, sx)
    local g = R.g
    for i = 0, rules.CELLS - 1 do
        if rules.game_cell_active(g, i) then
            local name
            local hp = g.stone_hp and g.stone_hp[i] or 0
            local crate = g.crate_hp and g.crate_hp[i] or 0
            if hp > 0 then name = "box-" .. math.min(hp, 6)
            elseif crate > 0 then name = "box-"..math.min(crate,6)
            elseif g.hazard and (g.hazard[i] or 0) > 0 then name = "honey-material" end
            local label
            if g.hs then
                local c=g.hs.cells[i]
                if (c.box or 0)>0 then name="box-"..math.min(6,c.box);if c.color then label="C"..c.color end
                elseif (c.jelly or 0)>0 then name="honey-material";label="J"..c.jelly
                elseif (c.statue or 0)>0 then name="statue-"..c.statue
                elseif (c.stack or 0)>0 then name="cookie-stack-"..c.stack
                elseif c.group then
                    local group=g.hs.groups[c.group]
                    if group.kind=='SHUTTERS' then name="blind-body"
                    elseif c.group==i then group_art(R,group,sx) end
                elseif c.visibleGenerator then generator_art(R,g,i,R.cell_pos(i)+vec2(sx,0),1) end
            end
            if name then
                local visible, scale, alpha = true, 1, 1
                if R.intro then visible, scale, alpha = R.intro:blocker(i); alpha = alpha * R.intro:fade() end
                if visible then
                    local radius = (hp > 0 or crate > 0) and R.HEX_R - .65 or R.HEX_R
                    image(R, name, R.cell_pos(i) + vec2(sx, 0), 2 * radius * scale, alpha)
                end
            end
            if g.hs then
                local c=g.hs.cells[i]
                if c.group==i and g.hs.groups[i].kind=='SHUTTERS' then
                    image(R,"blind-top",R.cell_pos(i)+vec2(sx,-R.HEX_R*.7),2*R.HEX_R,1)
                end
            end
            if label then R.say_at(label,R.cell_pos(i)+vec2(sx,0),13,R.PAL_WHITE,50) end
        end
    end
end

-- Selection/hints animate the original piece; no legacy frame is drawn.
function E.selection_scale(R,i)
    if i==R.selected then return 1.08 end
    if R.phase==R.PH_IDLE and (i==R.hint_a or i==R.hint_b) then
        return R.reduced_motion and 1.06 or 1+.06*math.sin(R.now*5)^2
    end
    return 1
end

-- Leave room to see artwork underneath pieces on special floor cells.
function E.piece_scale(g, cell)
    if (g.tunnel_to and g.tunnel_to[cell]) or (g.tunnel_from and g.tunnel_from[cell])
        or (g.delivery_exits and g.delivery_exits[cell]) then return .58 end
    for _, object in ipairs(g.objects or {}) do
        for _, i in ipairs(object.cells) do if i == cell then return .58 end end
    end
    return 1
end

function E.chain(R,g,i)
    local c=g.hs and g.hs.cells[i]
    return R.board_art[g.chain[i]>1 and "chain-2" or c and c.mirror and "chain-1-mirror" or "chain"]
end

function E.delivery(R, rules, t, at, scale, alpha, aspect, size)
    if t.element then
        local name=t.element=='cookie' and 'cookie-'..t.hp or t.element=='cherry' and 'cherry' or t.element=='hazelnut' and 'hazelnut-'..t.hp
        assert(name and R.board_art[name],"missing original mobile element art: "..t.element)
        gfx.image(R.board_art[name],rect.centered(at,size2(size*scale*aspect,size*scale/aspect)),color(255,255,255,alpha))
        return true
    end
    if t.kind ~= rules.DELIVERY then return false end
    local box = rect.centered(at, size2(size * scale * aspect, size * scale / aspect))
    gfx.image(R.board_art.delivery, box, color(255, 255, 255, alpha))
    return true
end

return E
