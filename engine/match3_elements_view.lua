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

function E.load(art, skin)
    for _, name in ipairs(E.assets) do art[name] = assert(skin[name], "missing element art: " .. name) end
end

local function image(R, name, at, size, alpha)
    gfx.image(R.board_art[name], rect.centered(at, size2.splat(size)), color(255, 255, 255, alpha * 255))
end

-- The spreading coverage objective forms a continuous patch: a signed
-- distance field of their cells (texture.hex_field, rounded outside corners,
-- filleted inside ones) masks a tiled material or picture, unshaded. A field
-- is rebuilt only when its cells or layout change.
-- Polynomial smooth-min rounds an inside corner by about a quarter of its fillet.
local CARPET_PATCH = {
    corner = .25, fillet = .8, range = .6, texel = 1.5, tile = 1.15,
    inset = 1.4,
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
-- A story picture replaces restored carpet, or peeks through the
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
    local half = spec.floor ~= "oil" and g.carpeted * 2 >= g.carpet_total
        or spec.object and g.oil_left * 2 <= #rules.level_of(g).oil   -- a still cover; snow can drift back
    if spec.bark and not R.reveal_barked and not g.won and half then
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
    gfx.sdf_mask(field.texture, area, field.range, 0, 0, 0, spec.feather or 0)
    if story and story.floor ~= "oil" then
        local t = R.board_art[story.picture]
        local box, src = picture_crop(R, rules, t)
        local opacity = 1 - cover * (1 - (R.reveal_play_opacity or 1))
        local dst = box:offset(vec2(sx, 0))
        -- `reveal.mosaic` is the same picture cut into stones: it shows during
        -- play and the painting fades in over it with the win.
        local stones = story.mosaic and cover > 0 and R.board_art[story.mosaic]
        if stones then
            gfx.image_part(stones, src, dst, color(255, 255, 255, 255 * alpha * opacity))
            if cover < 1 then gfx.image_part(t, src, dst, color(255, 255, 255, 255 * alpha * (1 - cover))) end
        else gfx.image_part(t, src, dst, color(255, 255, 255, 255 * alpha * opacity)) end
    else tile(R.board_art["carpet-swatch"], area, side, origin, color(255, 255, 255, 255 * alpha)) end
    gfx.sdf_unmask()
end

-- A buried find is one object, not a floor-wide painting: the whole image
-- covers the cells that hide it (`reveal.object`, the level's `oil`). The
-- art carries its own transparent margin, so every cell samples inside it.
local function object_crop(R, rules, t)
    local minx, miny, maxx, maxy = math.huge, math.huge, -math.huge, -math.huge
    for _, i in ipairs(rules.level_of(R.g).oil) do
        local p = R.cell_pos(i)
        minx, miny, maxx, maxy = math.min(minx, p.x), math.min(miny, p.y), math.max(maxx, p.x), math.max(maxy, p.y)
    end
    local w, h = maxx - minx + 2 * R.HEX_R, maxy - miny + math.sqrt(3) * R.HEX_R
    local size = texture.size(t)
    local s = math.max(w / size.w, h / size.h)
    return rect.centered(vec2((minx + maxx) / 2, (miny + maxy) / 2), size2(size.w * s, size.h * s)),
        rect(0, 0, size.w, size.h)
end

local function draw_buried_picture(R, rules, story, sx, alpha, cover, trench)
    if story.on_clear and cover == 1 then return end
    local g, cells = R.g, {}
    local t = R.board_art[story.picture]
    local silhouette = story.covered_picture and R.board_art[story.covered_picture]
    local box, src
    if story.object then box, src = object_crop(R, rules, t) else box, src = picture_crop(R, rules, t) end
    if cover < 1 then
        for i = 0, rules.CELLS - 1 do
            if rules.game_cell_active(g, i) then cells[#cells + 1] = i end
        end
        local field = patch_field(R, cells, CARPET_PATCH)
        gfx.sdf_mask(field.texture, field.area:offset(vec2(sx, 0)), field.range, 0, 0, 0, 1)
        gfx.image_part(t, src, box:offset(vec2(sx, 0)), color(255, 255, 255, 255 * alpha * (1 - cover)))
        gfx.sdf_unmask()
    end
    if cover == 0 or story.on_clear then return end
    -- Select the authored state for each live excavation cell.
    local scale = src.w / box.w
    local radius = R.HEX_R
    local face = size2(2 * radius * scale, math.sqrt(3) * radius * scale)
    local tint = color(255, 255, 255, 255 * alpha * (R.reveal_play_opacity or 1) * cover)
    local ink = silhouette and color(255, 255, 255, 255 * alpha)
    for _, i in ipairs(rules.level_of(g).oil) do
        local uncovered = g.oil[i] == 0
        if uncovered or silhouette then
            local p = R.cell_pos(i)
            local uv = vec2(src.x + (p.x - box.x) * scale, src.y + (p.y - box.y) * scale)
            local at = p + vec2(sx, 0)
            local crop = rect.centered(uv, face)
            if uncovered then
                if trench then
                    gfx.image(trench, rect.centered(at, size2.splat(2 * (radius - .65))),
                        color(255, 255, 255, 255 * alpha * cover))
                end
                gfx.image_hex(t, crop, at, radius, 0, tint)
            else
                local amount, turn, lift = 1, 0, 0
                if R.intro then amount, turn, lift = R.intro:cell(i) end
                if amount > .02 then
                    gfx.image_hex(silhouette, crop, at + vec2(0, lift), radius * amount, turn, ink)
                end
            end
        end
    end
end

-- Sample the material at its painted proportions inside the flat-top face.
local OIL_SAMPLE = rect.centered(vec2(64, 64), size2(82, 82 * math.sqrt(3) / 2))
local FLOOR_INSET = .18

local function floor_pose(R, i)
    local scale, turn, lift = 1, 0, 0
    if R.intro then scale, turn, lift = R.intro:cell(i) end
    return scale, turn, lift
end

local function each_ground_cell(R, rules, sx, fn)
    for i = 0, rules.CELLS - 1 do
        if rules.game_cell_active(R.g, i) then
            local scale, turn, lift = floor_pose(R, i)
            if scale > .02 then fn(i, R.cell_pos(i) + vec2(sx, lift), scale, turn) end
        end
    end
end

-- Registration for the templates from tools/board_frame.py. The 80 px
-- perimeter slots and 168 px entrance slot are painted at a 64 px hex radius.
local FRAME_RADIUS, FRAME_SLOT = 64, 80
local ENTRY_RIM = rect(0, 3 * FRAME_SLOT, 168, 168)
local SOUTH_EDGE, NORTH_EDGE = 1, 4
local NORTH_RIM = rect(3 * FRAME_SLOT, 3 * FRAME_SLOT, FRAME_SLOT, FRAME_SLOT)
local frame_vertices, frame_sources = {}, {}
for k = 0, 5 do
    local angle = math.rad(60 * k)
    frame_vertices[k] = vec2(math.cos(angle), math.sin(angle))
end
for row = 0, 2 do
    frame_sources[row] = {}
    for k = 0, 5 do
        frame_sources[row][k] = rect(k * FRAME_SLOT, row * FRAME_SLOT, FRAME_SLOT, FRAME_SLOT)
    end
end

function E.load_frame(art, paths)
    local sheet = texture.load(paths.stone)
    art["frame-stone"] = sheet
    art["frame-entrance"] = texture.region(sheet, ENTRY_RIM)
    art["frame-north"] = paths.north_edge
    local images = {}
    local function load(specs)
        local sprites = {}
        for i, spec in ipairs(specs or {}) do
            images[spec.path] = images[spec.path] or texture.load(spec.path)
            sprites[i] = {art = images[spec.path], width = spec.width, outward = spec.outward}
        end
        return sprites
    end
    art["frame-decorations"] = {corners = load(paths.corners), inner = load(paths.inner), walls = load(paths.walls)}
end

-- Intersect the outline at y. Wings of an arch and walls of an enclosed
-- hole both bound empty space on the left and right.
local function opening_sides(edges, at)
    local left, right, crossings = -math.huge, math.huge, 0
    for _, edge in ipairs(edges) do
        local a, b = edge.a, edge.b
        if (a.y > at.y) ~= (b.y > at.y) then
            local x = a.x + (b.x - a.x) * (at.y - a.y) / (b.y - a.y)
            if x < at.x then
                left = math.max(left, x)
            else
                right, crossings = math.min(right, x), crossings + 1
            end
        end
    end
    if left > -math.huge and right < math.huge and crossings % 2 == 0 then return left, right end
end

local function opening_cells(edges, radius)
    local candidates = {}
    local to_centre = vec2(0, radius * math.sqrt(3) / 2)
    for _, edge in ipairs(edges) do
        if edge.direction == SOUTH_EDGE then
            local at = edge.at
            local left, right = opening_sides(edges, at + vec2(0, radius * .65))
            if left and math.min(at.x - left, right - at.x) >= radius * .72
                and opening_sides(edges, at + vec2(0, radius * 1.25)) then
                -- The side-mounted art is registered to the empty hex below
                -- this edge, with the stem already painted on the shoulder.
                candidates[#candidates + 1] = at + to_centre
            end
        end
    end
    table.sort(candidates, function(a, b)
        if math.abs(a.y - b.y) < .01 then return a.x < b.x end
        return a.y < b.y
    end)
    local points = {}
    for _, candidate in ipairs(candidates) do
        local separate = true
        for _, point in ipairs(points) do
            if math.abs(point.x - candidate.x) < radius * 1.75 then
                separate = false
                break
            end
        end
        if separate then points[#points + 1] = candidate end
    end
    return points
end

local function wall_points(edges, convex, radius)
    local points = {}
    for _, corner in ipairs(convex) do
        if corner.direction == 0 or corner.direction == 3 then
            local side = corner.direction == 0 and 1 or 2
            local sign = side == 1 and 1 or -1
            local p = corner.p
            local left, right = opening_sides(edges, p + vec2(sign * radius * .85, 0))
            if left and right - left >= radius * 2.25 and (not points[side] or p.y < points[side].y) then
                points[side] = p + vec2(sign * radius * .16, 0)
            end
        end
    end
    return points
end

local function shadow_field(centres, radius, spec)
    local xy = {}
    local minx, miny, maxx, maxy = math.huge, math.huge, -math.huge, -math.huge
    for _, p in ipairs(centres) do
        xy[#xy + 1], xy[#xy + 2] = p.x, p.y
        minx, miny, maxx, maxy = math.min(minx, p.x), math.min(miny, p.y), math.max(maxx, p.x), math.max(maxy, p.y)
    end

    local scale = radius / (FRAME_RADIUS / 2)
    local reach, spread = spec.reach * scale, spec.spread * scale
    -- Rounded growth increases the apothem by reach, then uses the same
    -- rounding radius. Outside the board this is distance to the original
    -- silhouette minus reach, including along the walls of holes.
    local grown = radius + 2 * reach / math.sqrt(3)
    local range = spread + 2
    local pad = grown + range
    local area = rect(minx - pad, miny - pad, maxx - minx + 2 * pad, maxy - miny + 2 * pad)
    local mask = texture.hex_field(string.pack(("ff"):rep(#centres), table.unpack(xy)), #centres, grown, reach, 0,
        area, math.ceil(area.w), math.ceil(area.h), range)
    return {mask = mask, area = area:offset(vec2(0, spec.drop * scale)), range = range,
            spread = spread, ink = color(0, 0, 0, spec.alpha * 255)}
end

local function frame_layout(R, rules)
    local g, r = R.g, R.HEX_R
    local old, active = R.frame_layout, {}
    local same = old and old.game == g and old.radius == r
    for i = 0, rules.CELLS - 1 do
        active[i] = rules.game_cell_active(g, i) == true
        same = same and active[i] == old.active[i]
    end
    if same then return old end
    if old and old.shadow then texture.free(old.shadow.mask) end

    -- Store positions relative to the board so a resize or shake moves the
    -- whole frame and its shadow without rebuilding the list of sprites.
    local edges, joins, convex, north, centres = {}, {}, {}, {}, {}
    for i = 0, rules.CELLS - 1 do
        if active[i] then
            local centre = R.cell_pos(i) - R.board_origin
            centres[#centres + 1] = centre
            local open = {}
            for k = 0, 5 do open[k] = not active[rules.hex_neighbor(i, k)] end
            for k = 0, 5 do
                if open[k] then
                    local a = centre + frame_vertices[k]:scale(r)
                    local b = centre + frame_vertices[(k + 1) % 6]:scale(r)
                    local edge = {a = a, b = b, at = (a + b):scale(.5), source = frame_sources[0][k], direction = k}
                    edges[#edges + 1] = edge
                    if k == NORTH_EDGE then
                        -- The highest north-facing edge in each column is on
                        -- the outer rim. Lower ones can border openings.
                        local q = rules.hex_q(i)
                        if not north[q] or edge.at.y < north[q].at.y then north[q] = edge end
                    end
                    if open[(k + 5) % 6] then
                        joins[#joins + 1] = {at = a, source = frame_sources[1][k]}
                        convex[#convex + 1] = {p = a, angle = math.rad(60 * k), direction = k}
                    else
                        -- Two cells touch this vertex. The exposed edge that
                        -- starts here owns the join. Index it by the empty
                        -- neighbour's corner, rotated four steps from k.
                        joins[#joins + 1] = {at = a, source = frame_sources[2][(k + 4) % 6]}
                    end
                end
            end
        end
    end
    local snow = R.board_art["frame-north"]
    if snow then
        for _, edge in pairs(north) do
            edge.north = not opening_sides(edges, edge.at - vec2(0, r * .65))
        end
    end
    local openings = opening_cells(edges, r)
    local decor = R.board_art["frame-decorations"]
    -- An open-top channel has no upper shoulders. Its inward tips can
    -- support sprigs on the sides.
    local walls = #openings == 0 and decor and #decor.walls > 0 and wall_points(edges, convex, r) or {}
    local shadow = R.GROUND.drop_shadow and #centres > 0 and shadow_field(centres, r, R.GROUND.drop_shadow)
    local layout = {game = g, radius = r, active = active, edges = edges, joins = joins, convex = convex,
                    openings = openings, walls = walls, shadow = shadow}
    R.frame_layout = layout
    return layout
end

local function draw_drop_shadow(shadow, origin, alpha)
    if not shadow or shadow.mask.w == 0 then return end
    local area = shadow.area:offset(origin)
    gfx.sdf_mask(shadow.mask, area, shadow.range, 0, 0, 0, shadow.spread)
    gfx.rect(area, color.alpha(shadow.ink, alpha))
    gfx.sdf_unmask()
end

local function draw_stone(R, rules, sx, alpha)
    local art = R.GROUND.frame and R.board_art[R.GROUND.frame]
    if not art or art.w == 0 then return end
    local tint = color(255, 255, 255, 255 * alpha)
    local scale = R.HEX_R / FRAME_RADIUS
    if R.intro then
        each_ground_cell(R, rules, sx, function(_, at, amount, turn)
            local size = ENTRY_RIM.w * scale * amount
            gfx.image_rot(R.board_art["frame-entrance"], rect.centered(at, size2.splat(size)), turn, tint)
        end)
        return
    end
    local layout = frame_layout(R, rules)
    local origin = R.board_origin + vec2(sx, 0)
    local size = size2.splat(FRAME_SLOT * scale)
    draw_drop_shadow(layout.shadow, origin, alpha)
    for _, e in ipairs(layout.edges) do
        gfx.image_part(art, e.north and NORTH_RIM or e.source, rect.centered(e.at + origin, size), tint)
    end
    for _, j in ipairs(layout.joins) do gfx.image_part(art, j.source, rect.centered(j.at + origin, size), tint) end
    return layout
end

-- Corners are selected clockwise from north-west.
local corner_directions = {{-1, -1}, {1, -1}, {1, 1}}
local function draw_inner_sprites(sprites, points, origin, radius, tint)
    for i, spec in ipairs(sprites) do
        local at = points[i]
        if at then gfx.image(spec.art, rect.centered(origin + at, size2.splat(radius * spec.width)), tint) end
    end
end

local function draw_frame_decorations(R, frame, sx, alpha)
    local decor = R.board_art["frame-decorations"]
    if not decor then return end
    local origin = R.board_origin + vec2(sx, 0)
    local tint = color(255, 255, 255, 255 * alpha)
    local r = R.HEX_R
    for k, spec in ipairs(decor.corners) do
        local d = corner_directions[k]
        local best, score
        for _, c in ipairs(frame.convex) do
            local next_score = d[1] * c.p.x + d[2] * c.p.y
            if not best or next_score > score then best, score = c, next_score end
        end
        if best then
            local dst = rect.centered(origin + best.p, size2.splat(r * spec.width))
            local turn = spec.outward and best.angle + math.pi / 2 or 0
            gfx.image_rot(spec.art, dst, turn, tint)
        end
    end
    draw_inner_sprites(decor.inner, frame.openings, origin, r, tint)
    draw_inner_sprites(decor.walls, frame.walls, origin, r, tint)
end

local function draw_ground_backing(R, rules, sx, alpha, textured)
    local look = R.GROUND
    local frame = draw_stone(R, rules, sx, alpha)
    local seam = color.alpha(look.seam, alpha)
    local face = color.alpha(look.face, alpha)
    local inset = look.seam_width or FLOOR_INSET
    each_ground_cell(R, rules, sx, function(i, at, scale, turn)
        gfx.ngon(at, R.HEX_R * scale, 6, turn, seam)
        if not textured or R.g.stone_hp[i] > 0 then
            gfx.ngon(at, (R.HEX_R - inset) * scale, 6, turn, face)
        end
    end)
    return frame
end

-- Cradle of Rome's board, shared by the match-3 games. The games supply the
-- stone and leaf sprites independently of the floor tiles.
E.CRADLE_GROUND = {
    seam = color.hex(0x6A4214), seam_width = 1.4,
    frame = "frame-stone",
    drop_shadow = {reach = 5.95, spread = 5, drop = 3, alpha = .55},
    tiles = {selected = "tile-selected", hover = "tile-hover", bonus = "tile-bonus-area",
             wave = "tile-light-wave", ice = "tile-ice", double = "tile-tablet-double"},
}

function E.cradle_ground(R)
    for key, value in pairs(E.CRADLE_GROUND) do R.GROUND[key] = value end
end

local function draw_floor_cell(R, i, at, material, alpha)
    local scale, turn, lift = floor_pose(R, i)
    if scale <= .02 then return end
    at = at + vec2(0, lift)
    local tint = color(255, 255, 255, 255 * alpha)
    local radius = (R.HEX_R - (R.GROUND.seam_width or FLOOR_INSET)) * scale
    if material then
        gfx.image_rot(R.board_art[material], rect.centered(at, size2.splat(2 * radius)), turn, tint)
    else
        gfx.image_hex(R.board_art["oil-material"], OIL_SAMPLE, at, radius, turn, tint)
    end
end

-- Cell states drawn as whole tiles over the floor and under the pieces, from
-- the art keys in R.GROUND.tiles: the cells an armed tool would hit
-- (`bonus`), the mouse-hovered cell (`hover`) and the selected cell
-- (`selected`). Missing keys draw nothing.
function E.cell_highlights(R, rules, sx, alpha)
    local tiles, g = R.GROUND.tiles, R.g
    if not tiles then return end
    local function draw(i, key, amount)
        if key and i >= 0 and rules.game_cell_active(g, i) then
            draw_floor_cell(R, i, R.cell_pos(i) + vec2(sx, 0), key, alpha * amount)
        end
    end
    local area = tiles.bonus and (R.aim_cell or -1) >= 0 and rules.game_tool_area(g, R.tool, R.aim_cell)
    if area then
        local pulse = R.reduced_motion and .85 or .75 + .2 * math.sin(R.now * 6)
        for i in pairs(area) do draw(i, tiles.bonus, pulse) end
    end
    local hover = R.hover_cell or -1
    if hover ~= R.selected and not (area and area[hover]) then draw(hover, tiles.hover, .6) end
    draw(R.selected or -1, tiles.selected, 1)
end

-- Paint the full board surface before pieces and blockers.
function E.ground(R, rules, sx, floor, sweep)
    local g, intro = R.g, R.intro
    local alpha = intro and intro:fade() or 1
    local frame = draw_ground_backing(R, rules, sx, alpha, sweep or floor and floor.normal)
    -- A reveal can show during play or wait for the first clear.
    local level = rules.level_of(g)
    local story = reveal(R, rules) or level.reveal
    local cover = E.reveal_cover(R, rules)
    if sweep then
        for i = 0, rules.CELLS - 1 do
            if rules.game_cell_active(g, i) and g.stone_hp[i] == 0 then
                local material = g.carpet[i] > 0 and sweep.clean or sweep.dirty
                draw_floor_cell(R, i, R.cell_pos(i) + vec2(sx, 0), material, alpha)
            end
        end
    else
        draw_carpet(R, rules, story, sx, alpha, cover)
    end
    for i = 0, rules.CELLS - 1 do
        if rules.game_cell_active(g, i) then
            local at = R.cell_pos(i) + vec2(sx, 0)
            local tiles = R.GROUND.tiles or {}
            if tiles.ice and (g.ice[i] or 0) > 0 then
                draw_floor_cell(R, i, at, tiles.ice, alpha)
            elseif g.oil and (g.oil[i] or 0) > 1 and tiles.double then
                draw_floor_cell(R, i, at, tiles.double, alpha)
            elseif g.oil and (g.oil[i] or 0) > 0 then
                draw_floor_cell(R, i, at, floor and floor.covered, alpha)
            elseif floor and floor.normal and g.stone_hp[i] == 0 then
                local material = level.floor_marks and not level.floor_marks[i] and floor.plain or floor.normal
                draw_floor_cell(R, i, at, material, alpha)
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
    if frame then draw_frame_decorations(R, frame, sx, alpha) end
    E.cell_highlights(R, rules, sx, alpha)
    if story and story.floor == "oil" then
        draw_buried_picture(R, rules, story, sx, alpha, cover, floor and floor.excavated and R.board_art[floor.excavated])
    end
    if intro then
        for i = 0, rules.CELLS - 1 do
            if rules.game_cell_active(g, i) then
                local scale, _, lift, flash = intro:cell(i)
                if scale > .02 and flash > 0 then
                    local wave = (R.GROUND.tiles or {}).wave
                    if wave then   -- the light wave sweeps across the board as it arrives
                        draw_floor_cell(R, i, R.cell_pos(i) + vec2(sx, 0), wave, flash)
                    else
                        R.vfx_halo(R.cell_pos(i) + vec2(sx, lift), R.HEX_R * 1.6 * scale, color(255, 226, 150, 120 * flash))
                    end
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
    local spec = R.g and rules.level_of(R.g).deliveries
    local key = R.g and R.g.hs and "donut" or spec and spec.icon or "delivery"
    local art = R.board_art[key]
    gfx.image(art, box, color(255, 255, 255, alpha))
    return true
end

return E
