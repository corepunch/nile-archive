-- Presentation of optional match-three elements. Games provide the atlas;
-- rules and board layouts stay independent of this drawing code.
local E = {}

E.assets = {"stone-1", "stone-2", "stone-3", "delivery", "delivery-exit", "carry-exit-arrow"}
local stone_art = {"stone-material", "stone-mark-1", "stone-mark-2", "stone-mark-3", "goal-stone"}

for _,name in ipairs{"box","carry","jelly","lock","piggy","target-generator","trash"} do
    E.assets[#E.assets+1]="goal-"..name
end
for _,name in ipairs{"plane","chain-2","chain-1-mirror","carpet-swatch","goal-carpet","oil-material","oil-bubbles","goal-oil","cookie-1","cookie-2","cookie-3","cherry","box-1","box-2","box-3","box-4","box-5","box-6"} do
    E.assets[#E.assets+1]=name
end

for hp=1,3 do
    for _,family in ipairs{"hazelnut","statue","cookie-stack"} do E.assets[#E.assets+1]=family.."-"..hp end
end
for hp=1,2 do E.assets[#E.assets+1]="membrane-fill-"..hp end
for hp=1,6 do E.assets[#E.assets+1]="jelly-"..hp end
for hp=1,2 do E.assets[#E.assets+1]="jelly-"..hp.."-cherry" end

for n=1,9 do E.assets[#E.assets+1]="apple-platter-"..n end
for n=0,5 do E.assets[#E.assets+1]="donut-maker-"..n end
for _,name in ipairs{"blind-top","blind-body","generator-shell"} do E.assets[#E.assets+1]=name end

function E.load(art, skin)
    for _, name in ipairs(E.assets) do art[name] = assert(skin[name], "missing element art: " .. name) end
    if skin["stone-material"] then
        for _, name in ipairs(stone_art) do art[name] = assert(skin[name], "missing stone art: " .. name) end
    end
end

local function image(R, name, at, size, alpha)
    gfx.image(R.board_art[name], rect.centered(at, size2.splat(size)), color(255, 255, 255, alpha * 255))
end

-- Carpet, oil and stone each form a continuous patch: a signed
-- distance field of their cells (texture.hex_field, rounded outside corners,
-- filleted inside ones) masks a tiled material, and the rim is shaded. A field
-- is rebuilt only when its cells change. Oil also carries two layers of
-- bubbles drifting at different speeds, as Homescapes' oil shader does.
-- Polynomial smooth-min rounds an inside corner by about a quarter of its fillet.
local PATCH = {
    carpet = {material = "carpet-swatch", corner = .25, fillet = .8, range = .6, texel = 2, tile = 1.15, rim = 5, shade = .5},
    oil = {material = "oil-material", corner = .25, fillet = .8, range = .6, texel = 2, tile = 1.4, rim = 4, shade = .35,
        bubbles = {{"oil-bubbles", 4, -9, 1.6, 200}, {"oil-bubbles", -3, -14, 1.1, 150}}},   -- art, drift x/y (px/s), size, opacity
    stone = {material = "stone-material", corner = .20, fillet = .64, range = .6, texel = 2, tile = 1.6, rim = 6, shade = .48},
}
local function patch_cells(R, rules, layer)
    local g, cells = R.g, {}
    for i = 0, rules.CELLS - 1 do
        local on
        if layer == "carpet" then
            on = g.hs and g.hs.cells[i] and g.hs.cells[i].carpet or not g.hs and g.carpet and (g.carpet[i] or 0) > 0
        elseif layer == "stone" then
            on = g.stone_hp and (g.stone_hp[i] or 0) > 0
                and (not R.intro or R.intro:blocker(i))
        else on = g.oil and (g.oil[i] or 0) > 0 end
        if on and rules.game_cell_active(g, i) then cells[#cells + 1] = i end
    end
    return cells
end
local function patch_field(R, layer, cells)
    local spec = PATCH[layer]
    local origin = R.board_origin
    local key = table.concat({R.HEX_R, origin.x, origin.y, table.concat(cells, ",")}, ":")
    R.patch_fields = R.patch_fields or {}
    local cache = R.patch_fields[layer]
    if cache and cache.key == key then return cache end
    if cache and cache.texture then texture.free(cache.texture) end
    local r = R.HEX_R
    local range = spec.range * r
    local minx, miny, maxx, maxy, xy = math.huge, math.huge, -math.huge, -math.huge, {}
    for _, cell in ipairs(cells) do
        local p = R.cell_pos(cell)
        xy[#xy + 1], xy[#xy + 2] = p.x, p.y
        minx, miny, maxx, maxy = math.min(minx, p.x), math.min(miny, p.y), math.max(maxx, p.x), math.max(maxy, p.y)
    end
    local pad = r + range
    local area = rect(minx - pad, miny - pad, maxx - minx + 2 * pad, maxy - miny + 2 * pad)
    local w, h = math.ceil(area.w / spec.texel), math.ceil(area.h / spec.texel)
    local field = texture.hex_field(string.pack(("ff"):rep(#cells), table.unpack(xy)), #cells, r,
        spec.corner * r, spec.fillet * r, area, w, h, range)
    R.patch_fields[layer] = {key = key, texture = field, area = area, range = range}
    return R.patch_fields[layer]
end
-- Anchor material to the board so growing or clearing a patch leaves the
-- surviving surface in place. Mirrored UVs meet without a hard repeat seam.
local function tile(t, area, side, origin, tint, mirror)
    local first_col, last_col = math.floor((area.x - origin.x) / side), math.ceil((area.x + area.w - origin.x) / side) - 1
    local first_row, last_row = math.floor((area.y - origin.y) / side), math.ceil((area.y + area.h - origin.y) / side) - 1
    for row = first_row, last_row do
        local y, h = 1, 126
        if mirror and row % 2 ~= 0 then y, h = 127, -126 end
        for col = first_col, last_col do
            local x, w = 1, 126
            if mirror and col % 2 ~= 0 then x, w = 127, -126 end
            gfx.image_part(t, rect(x, y, w, h), rect(origin.x + col * side, origin.y + row * side, side, side), tint)
        end
    end
end
local function draw_patch(R, layer, cells, sx)
    local spec, field = PATCH[layer], patch_field(R, layer, cells)
    local area = field.area:offset(vec2(sx, 0))
    local alpha = R.intro and R.intro:fade() or 1
    local side = 2 * R.HEX_R * spec.tile
    local origin = R.board_origin + vec2(sx, 0)
    gfx.sdf_mask(field.texture, area, field.range, spec.rim, spec.shade)
    tile(R.board_art[spec.material], area, side, origin, color(255, 255, 255, 255 * alpha), true)
    local now = R.reduced_motion and 0 or (R.now or 0)
    for _, layer_spec in ipairs(spec.bubbles or {}) do
        local art, dx, dy, scale, opacity = table.unpack(layer_spec)
        tile(R.board_art[art], area, side * scale, origin + vec2(dx * now, dy * now), color(255, 255, 255, opacity * alpha))
    end
    gfx.sdf_unmask()
end
function E.patch(R, rules, layer, sx)
    local cells = patch_cells(R, rules, layer)
    if #cells == 0 then return end
    draw_patch(R, layer, cells, sx)
    if layer == "stone" then
        local alpha = R.intro and R.intro:fade() or 1
        for _, cell in ipairs(cells) do
            local hp = R.g.stone_hp[cell]
            image(R, "stone-mark-" .. hp, R.cell_pos(cell) + vec2(sx, 0), 2 * R.HEX_R, alpha)
        end
    end
end
function E.carpet(R, rules, sx) E.patch(R, rules, "carpet", sx) end

-- Called after every well has been painted, before pieces.
function E.ground(R, rules, sx)
    local g = R.g
    E.patch(R, rules, "carpet", sx)
    E.patch(R, rules, "oil", sx)
    for i = 0, rules.CELLS - 1 do
        if rules.game_cell_active(g, i) then
            local at = R.cell_pos(i) + vec2(sx, 0)
            local alpha = R.intro and R.intro:fade() or 1
            if g.hs then
                local c=g.hs.cells[i]
                if (c.tile or 0)>0 then image(R,"membrane-fill-"..c.tile,at,2*R.HEX_R,alpha) end
            end
            if g.delivery_exits and g.delivery_exits[i] then
                -- Original CarryArrows uses three staggered copies with a cosine fade.
                local elapsed = R.reduced_motion and 0 or R.now
                for n=0,2 do
                    local phase = (elapsed + n) % 3 / 3
                    local fade = (1 - math.cos(2 * math.pi * phase)) * .5 * (180 / 255)
                    image(R, "carry-exit-arrow", at + vec2(0, R.HEX_R * (.42 + phase * .5)), R.HEX_R * 1.5, alpha * fade)
                end
            end
        end
    end
end

-- Final visible stage in each of the source client's per-hit effect groups.
local maker_poses = {
    {5}, {2,5}, {2,3,5}, {1,2,3,5}, {1,2,3,4,5},
}

-- Approximate visible transitions from the 30 fps tutorial; hit intervals are
-- player-dependent, and flashes obscure the original effect curves.
local maker_duration = {.5, 1.9, .3, .5, .2}
local function maker_pose(group, hits)
    if hits <= 0 then return 0 end
    local poses=maker_poses[group.period]
    return poses and poses[math.min(hits,group.period)] or math.floor(math.min(hits,group.period)*5/group.period)
end

-- Queue visual changes independently of the rules so a cascade cannot skip a
-- stage, and a new board cannot inherit another board's pending animation.
function E.maker_observe(R)
    if R.maker_game ~= R.g then R.maker_game, R.maker_visual = R.g, {} end
    local visuals=R.maker_visual
    for anchor,group in pairs(R.g.hs and R.g.hs.groups or {}) do
        if group.kind=='CARRY_GEN' then
            local v=visuals[anchor]
            if not v then
                v={hits=group.hits,pose=maker_pose(group,group.hits),queue={}}
                visuals[anchor]=v
            elseif v.hits~=group.hits then
                local from=maker_pose(group,v.hits)
                local target=maker_pose(group,group.hits)
                if target>from then
                    for pose=from+1,target do v.queue[#v.queue+1]={pose=pose,duration=maker_duration[pose]} end
                elseif target<from then
                    v.queue[#v.queue+1]={pose=target,duration=.1}
                end
                v.hits=group.hits
            end
        end
    end
end

function E.maker_busy(R)
    for _,v in pairs(R.maker_visual or {}) do if v.queue[1] then return true end end
    return false
end

function E.maker_update(R,dt)
    E.maker_observe(R)
    for _,v in pairs(R.maker_visual) do
        if R.reduced_motion then
            while #v.queue>0 do v.pose=table.remove(v.queue,1).pose end
            v.elapsed=0
        else
            v.elapsed=(v.elapsed or 0)+dt
            while v.queue[1] and v.elapsed>=v.queue[1].duration do
                v.elapsed=v.elapsed-v.queue[1].duration
                v.pose=table.remove(v.queue,1).pose
            end
            if not v.queue[1] then v.elapsed=0 end
        end
    end
end

local function group_art(R,group,sx,anchor)
    local cx,cy,minx,maxx,miny,maxy=0,0,math.huge,-math.huge,math.huge,-math.huge
    for _,cell in ipairs(group.cells) do
        local p=R.cell_pos(cell)
        cx,cy=cx+p.x,cy+p.y
        minx,maxx,miny,maxy=math.min(minx,p.x),math.max(maxx,p.x),math.min(miny,p.y),math.max(maxy,p.y)
    end
    local name
    if group.kind=='TARGET_GEN' then
        name='apple-platter-'..group.count
    else
        local visual=R.maker_game==R.g and R.maker_visual and R.maker_visual[anchor]
        name='donut-maker-'..(visual and visual.pose or maker_pose(group,group.hits))
    end
    assert(R.board_art[name],"missing original group art: "..name)
    local size=math.min(maxx-minx+2*R.HEX_R,maxy-miny+math.sqrt(3)*R.HEX_R)
    local at=vec2(cx/#group.cells+sx,cy/#group.cells)
    image(R,name,at,size,1)
    local visual=R.maker_game==R.g and R.maker_visual and R.maker_visual[anchor]
    if group.kind=='CARRY_GEN' and visual and visual.queue[1] then
        local next_stage=visual.queue[1]
        image(R,'donut-maker-'..next_stage.pose,at,size,math.min(1,(visual.elapsed or 0)/next_stage.duration))
    end
end

local function generator_art(R,g,i,at,alpha)
    image(R,"generator-shell",at,2*R.HEX_R,alpha)
    local queue=g.hs.queues[i]
    local unit=queue and queue.units[queue.cursor]
    if not unit then return end
    local powers={b='bomb',f='plane',z='prism',l='ray-column',lh='ray-row',lv='ray-column'}
    local name=unit.element and unit.element..'-'..unit.hp or unit.special and powers[unit.special]
    local pos = at-vec2(0,R.HEX_R*.12)
    if name then image(R,name,pos,R.HEX_R*.95,alpha)
    elseif unit.color then
        gfx.image(R.relics[unit.color+1],rect.centered(pos,size2.splat(R.HEX_R*.95)),color(255,255,255,alpha*255))
    end
end

-- Fixed blockers cover the piece area.
function E.blockers(R, rules, sx)
    local g = R.g
    local themed_stone = R.board_art["stone-material"]
    if themed_stone then E.patch(R, rules, "stone", sx) end
    for i = 0, rules.CELLS - 1 do
        if rules.game_cell_active(g, i) then
            local name
            local hp = g.stone_hp and g.stone_hp[i] or 0
            if hp > 0 and not themed_stone then name = "box-" .. math.min(hp, 6) end
            if g.hs then
                local c=g.hs.cells[i]
                if (c.box or 0)>0 then
                    local health=math.min(6,c.box)
                    name="box-"..health
                elseif (c.jelly or 0)>0 then
                    local cherry = c.jelly <= 2 and g.tiles[i].element == "cherry"
                    name = "jelly-" .. c.jelly .. (cherry and "-cherry" or "")
                elseif (c.statue or 0)>0 then name="statue-"..c.statue
                elseif (c.stack or 0)>0 then name="cookie-stack-"..c.stack
                elseif c.group then
                    local group=g.hs.groups[c.group]
                    if group.kind=='SHUTTERS' then name="blind-body"
                    elseif c.group==i then group_art(R,group,sx,i) end
                elseif c.visibleGenerator then generator_art(R,g,i,R.cell_pos(i)+vec2(sx,0),1) end
            end
            if name then
                local visible, scale, alpha = true, 1, 1
                if R.intro then visible, scale, alpha = R.intro:blocker(i); alpha = alpha * R.intro:fade() end
                if visible then
                    local radius = hp > 0 and R.HEX_R - .65 or R.HEX_R
                    image(R, name, R.cell_pos(i) + vec2(sx, 0), 2 * radius * scale, alpha)
                end
            end
            if g.hs then
                local c=g.hs.cells[i]
                if c.group==i and g.hs.groups[i].kind=='SHUTTERS' then
                    image(R,"blind-top",R.cell_pos(i)+vec2(sx,-R.HEX_R*.7),2*R.HEX_R,1)
                end
            end
        end
    end
end

function E.covers_cherry(g, cell, piece)
    return piece.element == "cherry" and g.hs and (g.hs.cells[cell].jelly or 0) > 0
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
    return g.delivery_exits and g.delivery_exits[cell] and .58 or 1
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
