-- Presentation of optional match-three elements. Games provide the atlas;
-- rules and board layouts stay independent of this drawing code.
local E = {}

E.assets = {"stone-1", "chain-2"}

function E.load(art, skin)
    for _, name in ipairs(E.assets) do art[name] = assert(skin[name], "missing element art: " .. name) end
end

local function image(R, name, at, size, alpha)
    gfx.image(R.board_art[name], rect.centered(at, size2.splat(size)), color(255, 255, 255, alpha * 255))
end

-- A revealed picture fills the board as one continuous patch: a signed
-- distance field of its cells (texture.hex_field, rounded outside corners,
-- filleted inside ones) masks it, unshaded. A field is rebuilt only when its
-- cells or layout change.
-- Polynomial smooth-min rounds an inside corner by about a quarter of its fillet.
local BOARD_PATCH = {
    corner = .25, fillet = .8, range = .6, texel = 1.5, tile = 1.15,
    inset = 1.4,
}
local function patch_field(R, cells, spec)
    local origin = R.board_origin
    local key = table.concat({R.HEX_R, origin.x, origin.y, table.concat(cells, ",")}, ":")
    local cache = R.patch_field
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
    R.patch_field = {key = key, texture = field, area = area, range = range}
    return R.patch_field
end
-- A story picture peeks through the tablet cells as they are cleared
-- (`reveal.floor = "oil"`).
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
    local half = spec.object and g.oil_left * 2 <= #rules.level_of(g).oil
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
        local field = patch_field(R, cells, BOARD_PATCH)
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

local FLOOR_INSET = .18
local TABLET = "tile-tablet-single"

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
    art["frame-decorations"] = paths
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

local function opening_edges(edges, radius)
    local candidates = {}
    for _, edge in ipairs(edges) do
        if edge.direction == SOUTH_EDGE and edge.empty >= 0 then
            local at = edge.at
            local left, right = opening_sides(edges, at + vec2(0, radius * .65))
            if left and math.min(at.x - left, right - at.x) >= radius * .72
                and opening_sides(edges, at + vec2(0, radius * 1.25)) then
                candidates[#candidates + 1] = edge
            end
        end
    end
    table.sort(candidates, function(left, right)
        local a, b = left.at, right.at
        if math.abs(a.y - b.y) < .01 then return a.x < b.x end
        return a.y < b.y
    end)
    local points = {}
    for _, candidate in ipairs(candidates) do
        local separate = true
        for _, point in ipairs(points) do
            if math.abs(point.at.x - candidate.at.x) < radius * 1.75 then
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
            if left and right - left >= radius * 2.25 and (not points[side] or p.y < points[side].p.y) then
                points[side] = corner
            end
        end
    end
    return points
end

-- Replace the plain join at each chosen position with a stone-and-ornament
-- region. Inner variants belong to a specific shoulder of the empty hex.
local corner_directions = {{-1, -1}, {1, -1}, {1, 1}}
local function decorate_joins(decor, edges, convex, inner_joins, radius)
    for i, variants in ipairs(decor.corners or {}) do
        local d = corner_directions[i]
        local best, score
        for _, c in ipairs(convex) do
            local next_score = d[1] * c.p.x + d[2] * c.p.y
            if not best or next_score > score then best, score = c, next_score end
        end
        if best then best.join.paint = variants[best.direction] end
    end
    local openings = opening_edges(edges, radius)
    for i, spec in ipairs(decor.inner or {}) do
        local opening = openings[i]
        local shoulders = opening and inner_joins[opening.empty]
        local join = shoulders and shoulders[spec.direction]
        if join then join.paint = spec.part end
    end
    if #openings == 0 and decor.walls then
        local walls = wall_points(edges, convex, radius)
        for i, part in ipairs(decor.walls) do
            if walls[i] then walls[i].join.paint = part end
        end
    end
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
    local edges, joins, convex, north, centres, inner_joins = {}, {}, {}, {}, {}, {}
    for i = 0, rules.CELLS - 1 do
        if active[i] then
            local centre = R.cell_pos(i) - R.board_origin
            centres[#centres + 1] = centre
            local open = {}
            for k = 0, 5 do
                local neighbor = rules.hex_neighbor(i, k)
                open[k] = not active[neighbor] and neighbor
            end
            for k = 0, 5 do
                if open[k] then
                    local a = centre + frame_vertices[k]:scale(r)
                    local b = centre + frame_vertices[(k + 1) % 6]:scale(r)
                    local edge = {a = a, b = b, at = (a + b):scale(.5), source = frame_sources[0][k],
                                  direction = k, empty = open[k]}
                    edges[#edges + 1] = edge
                    if k == NORTH_EDGE then
                        -- The highest north-facing edge in each column is on
                        -- the outer rim. Lower ones can border openings.
                        local q = rules.hex_q(i)
                        if not north[q] or edge.at.y < north[q].at.y then north[q] = edge end
                    end
                    local join = {at = a}
                    joins[#joins + 1] = join
                    if open[(k + 5) % 6] then
                        join.source = frame_sources[1][k]
                        convex[#convex + 1] = {p = a, direction = k, join = join}
                    else
                        -- Two cells touch this vertex. The exposed edge that
                        -- starts here owns the join. Index it by the empty
                        -- neighbour's corner, rotated four steps from k.
                        local direction = (k + 4) % 6
                        join.source = frame_sources[2][direction]
                        if edge.empty >= 0 then
                            inner_joins[edge.empty] = inner_joins[edge.empty] or {}
                            inner_joins[edge.empty][direction] = join
                        end
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
    local decor = R.board_art["frame-decorations"]
    if decor then decorate_joins(decor, edges, convex, inner_joins, r) end
    local painted = {}
    local scale = r / FRAME_RADIUS
    for _, j in ipairs(joins) do
        if j.paint then
            local x, y, w, h, dx, dy = table.unpack(j.paint)
            local area = rect(j.at.x + dx * scale, j.at.y + dy * scale, w * scale, h * scale)
            painted[#painted + 1] = {source = rect(x, y, w, h), area = area}
        end
    end
    local shadow = R.GROUND.drop_shadow and #centres > 0 and shadow_field(centres, r, R.GROUND.drop_shadow)
    local layout = {game = g, radius = r, active = active, edges = edges, joins = joins,
                    painted = painted, shadow = shadow}
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
    if alpha <= 0 or not art or art.w == 0 then return end
    local tint = color(255, 255, 255, 255 * alpha)
    local scale = R.HEX_R / FRAME_RADIUS
    local layout = frame_layout(R, rules)
    local origin = R.board_origin + vec2(sx, 0)
    local size = size2.splat(FRAME_SLOT * scale)
    draw_drop_shadow(layout.shadow, origin, alpha)
    for _, e in ipairs(layout.edges) do
        gfx.image_part(art, e.north and NORTH_RIM or e.source, rect.centered(e.at + origin, size), tint)
    end
    for _, j in ipairs(layout.joins) do
        if not j.paint then gfx.image_part(art, j.source, rect.centered(j.at + origin, size), tint) end
    end
    return layout
end

local function draw_ground_backing(R, rules, sx, alpha, frame_alpha, textured)
    local look = R.GROUND
    local frame = draw_stone(R, rules, sx, frame_alpha)
    local rim = look.frame and R.board_art["frame-entrance"]
    if rim and frame_alpha < 1 and not R.intro.reduced then
        local tint = color(255, 255, 255, 255 * (1 - frame_alpha))
        local rim_size = ENTRY_RIM.w * R.HEX_R / FRAME_RADIUS
        each_ground_cell(R, rules, sx, function(_, at, scale, turn)
            gfx.image_rot(rim, rect.centered(at, size2.splat(rim_size * scale)), turn, tint)
        end)
    end
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

-- The art a cell's breakable floor layer is painted with, as E.ground paints
-- it, for effects that break it (match3.shatter): ice, else the top tablet
-- layer. Tablets use the Cradle of Rome tablet tiles.
function E.layer_art(R, floor, oil, ice)
    local tiles = R.GROUND.tiles or {}
    if ice > 0 then return tiles.ice and R.board_art[tiles.ice] end
    local double = floor and floor.double or tiles.double
    if oil > 1 and double then return R.board_art[double] end
    if oil > 0 then return R.board_art[floor and floor.covered or TABLET] end
end

local function draw_floor_cell(R, i, at, material, alpha)
    local scale, turn, lift = floor_pose(R, i)
    if scale <= .02 then return end
    at = at + vec2(0, lift)
    local tint = color(255, 255, 255, 255 * alpha)
    local radius = (R.HEX_R - (R.GROUND.seam_width or FLOOR_INSET)) * scale
    gfx.image_rot(R.board_art[material or TABLET], rect.centered(at, size2.splat(2 * radius)), turn, tint)
end

local function draw_tablet_hints(R, rules, sx, floor)
    local g = R.g
    if not (floor and floor.tablet_hint and g.oil_left > 0 and g.oil_left <= 3)
        or R.reduced_motion or R.overlay ~= R.OV_NONE then return end
    local time = R.tablet_hint_time(R.idle_hint_age())
    if not time then return end
    local radius = R.HEX_R - (R.GROUND.seam_width or FLOOR_INSET) - 1
    for i = 0, rules.CELLS - 1 do
        local layers = g.oil[i] or 0
        if layers > 0 and rules.game_cell_active(g, i) then
            R.vfx_tablet_hint(R.cell_pos(i) + vec2(sx, 0), radius, frame_vertices, time, layers > 1)
        end
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

-- The trim is a painted top-edge strip. Turn it onto the exposed edges
-- and leave the inside seams to the dark grout underneath.
local square_edges = {
    {direction=4, turn=0},
    {direction=0, turn=math.pi / 2},
    {direction=1, turn=math.pi},
    {direction=3, turn=-math.pi / 2},
}
local square_corners = {
    {x=-1, y=-1, a=4, b=3, turn=0},
    {x=1, y=-1, a=4, b=0, turn=math.pi / 2},
    {x=1, y=1, a=1, b=0, turn=math.pi},
    {x=-1, y=1, a=1, b=3, turn=-math.pi / 2},
}
local square_cells = {"square-plain", "square-target", "square-double", "square-selected", "square-grout"}
local square_trim = {"square-trim", "square-foliage", "square-joint", "square-medallion"}
local square_frame = {"square-frame-edge", "square-frame-outer", "square-frame-inner", "square-frame-diagonal",
    "square-frame-inner-bare"}

function E.load_square(art, skin, modular_frame)
    for _, key in ipairs(square_cells) do art[key] = assert(skin[key], key) end
    for _, key in ipairs(modular_frame and square_frame or square_trim) do art[key] = assert(skin[key], key) end
end

-- Each frame tile is centred at a grid vertex, with bits for the four
-- surrounding floor cells in clockwise order from the northwest.
-- The entry selects a painted tile and its clockwise quarter turns.
local EDGE, OUTER, INNER, DIAGONAL, BARE = 1, 2, 3, 4, 5
local square_frame_tiles = {
    [12]={EDGE, 0}, [9]={EDGE, 1}, [3]={EDGE, 2}, [6]={EDGE, 3},
    [4]={OUTER, 0}, [8]={OUTER, 1}, [1]={OUTER, 2}, [2]={OUTER, 3},
    [14]={INNER, 0}, [13]={INNER, 1}, [11]={INNER, 2}, [7]={INNER, 3},
    [5]={DIAGONAL, 0}, [10]={DIAGONAL, 1},
}

local function draw_square_frame(R, rules, sx, tint)
    if tint.a <= 0 then return end
    local r, art = R.HEX_R, R.board_art
    local origin = R.board_origin + vec2(sx, 0)
    -- The art uses 128 pixels per grid step. A larger canvas can extend
    -- beyond the joins while keeping the same scale and vertex pivot.
    local scale = 2 * r / 128
    local function occupied(q, row, bit)
        return rules.game_cell_active(R.g, rules.hex_index(q, row)) and bit or 0
    end
    local q0, row0 = rules.hex_q(0), rules.hex_r(0)
    -- Alternate along each facing direction so mirrored staircases do
    -- not put every sprig on the same side of the board.
    local leafy = {[0]=true, false, true, false}
    for q = q0, q0 + rules.COLUMNS do
        for row = row0, row0 + rules.ROWS do
            local mask = occupied(q - 1, row - 1, 1) | occupied(q, row - 1, 2)
                | occupied(q, row, 4) | occupied(q - 1, row, 8)
            local tile = square_frame_tiles[mask]
            if tile then
                local at = origin + vec2((2 * q - 1) * r, (2 * row - 1) * r)
                local kind, turn = tile[1], tile[2]
                if kind == INNER then
                    kind = leafy[turn] and INNER or BARE
                    leafy[turn] = not leafy[turn]
                end
                local sprite = art[square_frame[kind]]
                local box = rect.centered(at, size2.splat(sprite.w * scale))
                gfx.image_rot(sprite, box, turn * math.pi / 2, tint)
            end
        end
    end
end

local function draw_square_corners(R, rules, sx, tint)
    local r, game = R.HEX_R, R.g
    local active, neighbor = rules.game_cell_active, rules.hex_neighbor
    each_ground_cell(R, rules, sx, function(i, at, scale, turn)
        local q, row = rules.hex_q(i), rules.hex_r(i)
        for _, corner in ipairs(square_corners) do
            local a, b = active(game, neighbor(i, corner.a)), active(game, neighbor(i, corner.b))
            local position = at + vec2.polar(math.atan(corner.y, corner.x) + turn, math.sqrt(2) * r * scale)
            local angle = corner.turn + turn
            if a and b and not active(game, rules.hex_index(q + corner.x, row + corner.y)) then
                -- The two adjacent cells enclose a 90-degree pocket in the rim.
                -- The painted bracket hugs its corner and the leaves fan into the pocket.
                local size = r * 1.94 * scale
                local outward = vec2.polar(angle - 3 * math.pi / 4, size * .52)
                gfx.image_rot(R.board_art["square-foliage"],
                    rect.centered(position + outward, size2.splat(size)), angle, tint)
            elseif not a and not b then
                local key = (q + row) % 3 == 0 and "square-medallion" or "square-joint"
                gfx.image_rot(R.board_art[key],
                    rect.centered(position, size2.splat(r * .66 * scale)), angle, tint)
            end
        end
    end)
end

local function draw_square_edges(R, rules, sx, rim, tint)
    local active, game, r = rules.game_cell_active, R.g, R.HEX_R
    each_ground_cell(R, rules, sx, function(i, at, scale, turn)
        for _, edge in ipairs(square_edges) do
            if not active(game, rules.hex_neighbor(i, edge.direction)) then
                local center = at + vec2.polar(edge.turn + turn - math.pi / 2, 1):scale((r + rim * .4) * scale)
                local box = rect.centered(center, size2((2 * r + rim * 1.7) * scale, rim * 1.8 * scale))
                gfx.image_rot(R.board_art["square-trim"], box, edge.turn + turn, tint)
            end
        end
    end)
end

local function draw_square_ground(R, rules, sx, floor, alpha, frame_alpha)
    local active, game = rules.game_cell_active, R.g
    local r, art = R.HEX_R, R.board_art
    local modular_frame = art["square-frame-edge"]
    local rim = modular_frame and 0 or r * .36
    local tint = color(255, 255, 255, 255 * frame_alpha)
    each_ground_cell(R, rules, sx, function(_, at, scale, turn)
        local box = rect.centered(at, size2.splat((2 * r + rim * 2) * scale))
        gfx.image_rot(art["square-grout"], box, turn, tint)
    end)
    if not modular_frame then draw_square_edges(R, rules, sx, rim, tint) end
    each_ground_cell(R, rules, sx, function(i, at, scale, turn)
        local box = rect.centered(at, size2.splat(2 * (r - R.GROUND.seam_width) * scale))
        local layers = game.oil[i]
        local key = layers > 1 and floor.double or layers > 0 and floor.covered or floor.normal
        gfx.image_rot(art[key], box, turn, color(255, 255, 255, 255 * alpha))
    end)
    if modular_frame then draw_square_frame(R, rules, sx, tint)
    else draw_square_corners(R, rules, sx, tint) end
    local function outline(i, opacity)
        draw_floor_cell(R, i, R.cell_pos(i) + vec2(sx, 0), "square-selected", alpha * opacity)
    end
    local aim = R.aim_cell or -1
    if aim >= 0 then
        for i in pairs(rules.game_tool_area(game, R.tool, aim) or {}) do outline(i, .82) end
    end
    local selected = R.selected or -1
    if active(game, selected) then outline(selected, 1) end
end

-- Paint the full board surface before pieces and blockers.
function E.ground(R, rules, sx, floor)
    local g, intro = R.g, R.intro
    local alpha = intro and intro:fade() or 1
    local frame_alpha = intro and intro:frame_fade() or 1
    if rules.square then
        draw_square_ground(R, rules, sx, floor, alpha, frame_alpha)
        return
    end
    local frame = draw_ground_backing(R, rules, sx, alpha, frame_alpha, floor and floor.normal)
    -- A reveal can show during play or wait for the first clear.
    local level = rules.level_of(g)
    local story = reveal(R, rules) or level.reveal
    local cover = E.reveal_cover(R, rules)
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
        end
    end
    E.cell_highlights(R, rules, sx, alpha)
    if story and story.floor == "oil" then
        draw_buried_picture(R, rules, story, sx, alpha, cover, floor and floor.excavated and R.board_art[floor.excavated])
    end
    if frame then
        -- The painted joins sit over the tile faces, so leaves crossing
        -- the lip keep their full silhouette. Pieces are drawn afterwards.
        local origin = R.board_origin + vec2(sx, 0)
        local tint = color(255, 255, 255, 255 * frame_alpha)
        local art = R.board_art[R.GROUND.frame]
        for _, p in ipairs(frame.painted) do gfx.image_part(art, p.source, p.area:offset(origin), tint) end
    end
    draw_tablet_hints(R, rules, sx, floor)
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
            if name then
                local visible, scale, alpha = true, 1, 1
                if R.intro then visible, scale, alpha = R.intro:blocker(i); alpha = alpha * R.intro:fade() end
                if visible then
                    image(R, name, R.cell_pos(i) + vec2(sx, 0), 2 * (R.HEX_R - .65) * scale, alpha * cover)
                end
            end
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

function E.chain(R,g,i)
    return R.board_art[g.chain[i]>1 and "chain-2" or "chain"]
end

return E
