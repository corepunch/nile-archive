-- Presentation of optional match-three elements. Games provide the atlas;
-- rules and board layouts stay independent of this drawing code.
local E = {}

E.assets = {"stone-1", "delivery", "donut", "delivery-exit", "carry-exit-arrow"}

for _,name in ipairs{"box","carry","jelly","lock","piggy","target-generator","trash"} do
    E.assets[#E.assets+1]="goal-"..name
end
for _,name in ipairs{"plane","chain-2","chain-1-mirror","carpet-swatch","goal-carpet","oil-material","goal-oil","cookie-1","cookie-2","cookie-3","cherry","box-1","box-2","box-3","box-4","box-5","box-6"} do
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

-- A story mosaic's picture and its frosted copy: during play the floor shows
-- the picture as through frosted glass; the win clears it to the sharp one.
local FROST_BLUR = 9                        -- image pixels
-- Each restored cell is its own glass tile over the picture (gfx.image_glass).
-- --glass N previews the variants; 0 is one flat frosted pane.
local GLASS = {
    [0] = {mode = 0, strength = 0, light = 0},
    {mode = 1, strength = .14, light = .55},   -- pillow: a convex lens per tile
    {mode = 2, strength = .16, light = .65},   -- bevelled rim, flat centre
    {mode = 3, strength = .12, light = .35},   -- reeded flutes
    {mode = 4, strength = .10, light = .55},   -- cut facets
}
local GLASS_INSET = 1.2                     -- grout between tiles, logical px
local FROST_WASH = color(236, 244, 255, 46)  -- the glass's milky sheen
function E.load_picture(art, name, path)
    art[name] = texture.load(path)
    art[name .. "-frost"] = texture.load_blurred(path, FROST_BLUR)
end

function E.load(art, skin)
    for _, name in ipairs(E.assets) do art[name] = assert(skin[name], "missing element art: " .. name) end
end

local function image(R, name, at, size, alpha)
    gfx.image(R.board_art[name], rect.centered(at, size2.splat(size)), color(255, 255, 255, alpha * 255))
end

-- The spreading coverage objective forms a continuous patch: a signed
-- distance field of their cells (texture.hex_field, rounded outside corners,
-- filleted inside ones) masks a tiled material, and the rim is shaded. A field
-- is rebuilt only when its cells or layout change.
-- Polynomial smooth-min rounds an inside corner by about a quarter of its fillet.
local CARPET_PATCH = {
    corner = .25, fillet = .8, range = .6, texel = 1.5, tile = 1.15,
    inset = 1.4, rim = 2.3, shade = .26, bevel = .15, shadow_y = 1.4, softness = 2.4, opacity = 76,
}
local function patch_field(R, cells, spec)
    local origin = R.board_origin
    local key = table.concat({R.HEX_R, origin.x, origin.y, table.concat(cells, ",")}, ":")
    local cache = R.carpet_field
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
        spec.corner * r, spec.fillet * r, area, w, h, range, spec.inset or 0)
    R.carpet_field = {key = key, texture = field, area = area, range = range}
    return R.carpet_field
end
-- Anchor material to the board so growing or clearing a patch leaves the
-- surviving surface in place. Mirrored UVs meet without a hard repeat seam.
local function tile(t, area, side, origin, tint)
    local first_col, last_col = math.floor((area.x - origin.x) / side), math.ceil((area.x + area.w - origin.x) / side) - 1
    local first_row, last_row = math.floor((area.y - origin.y) / side), math.ceil((area.y + area.h - origin.y) / side) - 1
    for row = first_row, last_row do
        local y, h = 1, 126
        if row % 2 ~= 0 then y, h = 127, -126 end
        for col = first_col, last_col do
            local x, w = 1, 126
            if col % 2 ~= 0 then x, w = 127, -126 end
            gfx.image_part(t, rect(x, y, w, h), rect(origin.x + col * side, origin.y + row * side, side, side), tint)
        end
    end
end
-- A first-clear picture replaces restored carpet, or peeks through the
-- original hazard cells as they are cleared (`reveal.floor = "oil"`).
-- On the win the pieces clear away (E.reveal_cover) and the finished picture
-- holds for a moment before the first-clear beat (E.reveal_holding).
local REVEAL_FADE, REVEAL_HOLD = .6, 1.2
local function reveal(R, rules)
    local g = R.g
    if not g then return end
    if R.reveal_game ~= g then
        local spec = rules.level_of(g).reveal
        R.reveal_game, R.reveal_won, R.reveal_barked = g, nil, false
        R.reveal_spec = spec and (not R.prog or g.level >= R.prog.level) and spec or nil
    end
    local spec = R.reveal_spec
    if not spec then return end
    if g.won and not R.reveal_won then R.reveal_won = R.now end
    if spec.bark and spec.floor ~= "oil" and not R.reveal_barked and not g.won and g.carpeted * 2 >= g.carpet_total then
        R.reveal_barked = true
        R.notice(spec.bark)
    end
    return spec
end
-- Piece and blocker opacity, 1 until the win and 0 once the picture is clear.
function E.reveal_cover(R, rules)
    if not reveal(R, rules) or not R.reveal_won then return 1 end
    return R.reduced_motion and 0 or 1 - ease.out_cubic(math.min(1, (R.now - R.reveal_won) / REVEAL_FADE))
end
function E.reveal_holding(R, rules)
    return reveal(R, rules) ~= nil and R.reveal_won ~= nil and R.now - R.reveal_won < REVEAL_FADE + REVEAL_HOLD
end
local function picture_crop(R, rules, t)
    local minx, miny, maxx, maxy = math.huge, math.huge, -math.huge, -math.huge
    for i = 0, rules.CELLS - 1 do
        if rules.game_cell_active(R.g, i) then
            local p = R.cell_pos(i)
            minx, miny, maxx, maxy = math.min(minx, p.x), math.min(miny, p.y), math.max(maxx, p.x), math.max(maxy, p.y)
        end
    end
    local rx, ry = R.HEX_R, R.HEX_R * math.sqrt(3) / 2
    local box = rect(minx - rx, miny - ry, maxx - minx + 2 * rx, maxy - miny + 2 * ry)
    local size = texture.size(t)
    local s = math.min(size.w / box.w, size.h / box.h)   -- cover the board, cropping the longer side
    return box, rect((size.w - box.w * s) / 2, (size.h - box.h * s) / 2, box.w * s, box.h * s)
end
local function draw_carpet(R, rules, story, sx, alpha, cover)
    local g, cells = R.g, {}
    for i = 0, rules.CELLS - 1 do
        local on = g.hs and g.hs.cells[i] and g.hs.cells[i].carpet or not g.hs and g.carpet and (g.carpet[i] or 0) > 0
        if on and rules.game_cell_active(g, i) then cells[#cells + 1] = i end
    end
    if #cells == 0 then return end
    local spec = R.carpet_patch or CARPET_PATCH
    local field = patch_field(R, cells, spec)
    local area = field.area:offset(vec2(sx, 0))
    local side = 2 * R.HEX_R * spec.tile
    local origin = R.board_origin + vec2(sx, 0)
    if spec.shadow_y then
        local shadow = area:offset(vec2(1, spec.shadow_y))
        gfx.sdf_mask(field.texture, shadow, field.range, 0, 0, 0, spec.softness)
        gfx.rect(shadow, color(12, 10, 8, spec.opacity * alpha))
    end
    gfx.sdf_mask(field.texture, area, field.range, spec.rim, spec.shade, spec.bevel, spec.feather or 0)
    if story and story.floor ~= "oil" then
        local t = R.board_art[story.picture]
        local box, src = picture_crop(R, rules, t)
        local opacity = 1 - cover * (1 - (R.reveal_play_opacity or 1))
        local frost, dst = R.board_art[story.picture .. "-frost"], box:offset(vec2(sx, 0))
        local sharp = frost and frost.tex and 1 - cover or 1
        if sharp < 1 then
            local glass = GLASS[tonumber(app.arg("glass") or "") or 1] or GLASS[1]
            local tint, scale = color(255, 255, 255, 255 * alpha * opacity), src.w / box.w
            local face = size2(2 * R.HEX_R * scale, math.sqrt(3) * R.HEX_R * scale)
            if glass.mode == 0 then gfx.image_part(frost, src, dst, tint) end
            for _, i in ipairs(glass.mode > 0 and cells or {}) do
                local p = R.cell_pos(i)
                local uv = vec2(src.x + (p.x - box.x) * scale, src.y + (p.y - box.y) * scale)
                gfx.image_glass(frost, rect.centered(uv, face), p + vec2(sx, 0), R.HEX_R - GLASS_INSET,
                                glass.mode, glass.strength, glass.light, tint)
            end
            gfx.rect(area, color(FROST_WASH.r, FROST_WASH.g, FROST_WASH.b, FROST_WASH.a * alpha * cover))
        end
        if sharp > 0 then gfx.image_part(t, src, dst, color(255, 255, 255, 255 * alpha * opacity * sharp)) end
    else tile(R.board_art["carpet-swatch"], area, side, origin, color(255, 255, 255, 255 * alpha)) end
    gfx.sdf_unmask()
end

local function draw_buried_picture(R, rules, story, sx, alpha, cover)
    local g, cells = R.g, {}
    local t = R.board_art[story.picture]
    local box, src = picture_crop(R, rules, t)
    if cover < 1 then
        for i = 0, rules.CELLS - 1 do
            if rules.game_cell_active(g, i) then cells[#cells + 1] = i end
        end
        local field = patch_field(R, cells, CARPET_PATCH)
        gfx.sdf_mask(field.texture, field.area:offset(vec2(sx, 0)), field.range, 0, 0, 0, 1)
        gfx.image_part(t, src, box:offset(vec2(sx, 0)), color(255, 255, 255, 255 * alpha * (1 - cover)))
        gfx.sdf_unmask()
    end
    if cover == 0 then return end
    -- Snow can spread back over these cells. Read the live mask every frame.
    local scale = src.w / box.w
    local radius = R.HEX_R
    local face = size2(2 * radius * scale, math.sqrt(3) * radius * scale)
    local tint = color(255, 255, 255, 255 * alpha * (R.reveal_play_opacity or 1) * cover)
    local frost = R.board_art[story.picture .. "-frost"]
    if not (frost and frost.tex) then frost = t end
    for _, i in ipairs(rules.level_of(g).oil) do
        if g.oil[i] == 0 then
            local p = R.cell_pos(i)
            local uv = vec2(src.x + (p.x - box.x) * scale, src.y + (p.y - box.y) * scale)
            gfx.image_hex(frost, rect.centered(uv, face), p + vec2(sx, 0), radius, 0, tint)
        end
    end
end

-- Sample the material at its painted proportions inside the flat-top face.
local OIL_SAMPLE = rect.centered(vec2(64, 64), size2(82, 82 * math.sqrt(3) / 2))

-- Called after every well has been painted, before pieces.
function E.ground(R, rules, sx)
    local g, intro = R.g, R.intro
    local alpha = intro and intro:fade() or 1
    local story = reveal(R, rules)
    local cover = story and E.reveal_cover(R, rules) or 1
    draw_carpet(R, rules, story, sx, alpha, cover)
    if story and story.floor == "oil" then draw_buried_picture(R, rules, story, sx, alpha, cover) end
    for i = 0, rules.CELLS - 1 do
        if rules.game_cell_active(g, i) then
            local at = R.cell_pos(i) + vec2(sx, 0)
            if g.oil and (g.oil[i] or 0) > 0 then
                local scale, turn, lift = 1, 0, 0
                if intro then scale, turn, lift = intro:cell(i) end
                if scale > .02 then
                    gfx.image_hex(R.board_art["oil-material"], OIL_SAMPLE, at + vec2(0, lift), R.HEX_R * scale, turn,
                        color(255, 255, 255, 255 * alpha))
                end
            end
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
    local cover = E.reveal_cover(R, rules)
    if cover <= 0 then return end
    for i = 0, rules.CELLS - 1 do
        if rules.game_cell_active(g, i) then
            local name
            local hp = g.stone_hp and g.stone_hp[i] or 0
            if hp > 0 then name = "stone-1" end
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
                    image(R, name, R.cell_pos(i) + vec2(sx, 0), 2 * radius * scale, alpha * cover)
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

-- A soft drop shadow under a board piece, so it stays legible on bright floor
-- art: the piece's silhouette inked dark blue (a single full-width stripe),
-- dropped and spread over a ring of faint taps. size is the piece's drawn
-- width in logical pixels.
local SHADOW_TAPS = 8
local SHADOW_DROP, SHADOW_SPREAD, SHADOW_TAP_ALPHA = .035, .025, 11
local SHADOW_INK = color(22, 38, 92, 255)
function E.piece_shadow(tex, dst, alpha, size)
    local drop, spread = size * SHADOW_DROP, size * SHADOW_SPREAD
    local tint = color(255, 255, 255, SHADOW_TAP_ALPHA * alpha / 255)
    local base = dst:offset(vec2(0, drop))
    gfx.image_striped(tex, base, 0, 1, 1, SHADOW_INK, tint)
    for k = 1, SHADOW_TAPS do
        local a = k / SHADOW_TAPS * 2 * math.pi
        gfx.image_striped(tex, base:offset(vec2(math.cos(a) * spread, math.sin(a) * spread)), 0, 1, 1, SHADOW_INK, tint)
    end
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
    local art = R.g and R.g.hs and R.board_art.donut or R.board_art.delivery
    gfx.image(art, box, color(255, 255, 255, alpha))
    return true
end

return E
