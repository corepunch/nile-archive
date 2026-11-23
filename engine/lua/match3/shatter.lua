-- match3/shatter.lua — a floor layer (tablet, ice) breaking apart: the cell's
-- own artwork is cut into Voronoi shards that crack, burst outwards, tumble and
-- fall under gravity, over billowing smoke (Kenney puff sprites). Presentation only, with its
-- own random stream and fixed pools (`require("match3.shatter").bind(R, rules)`,
-- called by match3.game after match3.vfx).
--
-- Fracture patterns are made once, at bind, in the shape of a cell. A break
-- picks one and one of the cell’s symmetries, so every break differs and
-- every shard is exactly the pixels of the layer that broke. Nothing is baked:
-- new tile art, packs and games shatter with no extra assets.
local S = {}

local PI, TAU, SQ3 = math.pi, 2 * math.pi, math.sqrt(3)

-- Tuning, in hex radii (r) and seconds; distances scale with the board.
S.PATTERNS, S.SITES, S.SITE_GAP = 8, 8, .44   -- fracture variety and shard count
S.CRACK = .07                                  -- shards hold, cracks glow, then burst
S.SPEED, S.LIFT, S.GRAVITY = {3.4, 8.5}, {1.6, 4.2}, 46   -- r/s, r/s up, r/s²
S.LIFE = {.43, .67}                            -- gone before they drop far below the cell
S.DUST = color(146, 118, 84)                   -- earthy smoke for every layer
-- Puff styles: how many, how fast they spread (r/s) and rise, their start and
-- end radius (r), life (s), how far the tint leans to white, and peak opacity.
S.SMOKE = {count = 4, speed = {1.6, 3.2}, lift = {.6, 1.4}, r0 = {.35, .5}, r1 = {.85, 1.15},
    life = {1.05, 1.45}, light = .7, alpha = .85}               -- a broken layer's dust
S.BURST = {count = 4, speed = {2.4, 4.2}, lift = {.3, .9}, r0 = {.4, .55}, r1 = {1, 1.35},
    life = {.4, .58}, light = .28, alpha = .9}                 -- a matched piece's coloured cloud
S.SHARD_CAP, S.PUFF_CAP = 220, 160

-- The unit hex: vertices at +-x like the board's cells, clockwise on screen.
local SQUARE = {{-1, -1}, {1, -1}, {1, 1}, {-1, 1}}
local HEX = {}
for k = 0, 5 do HEX[k + 1] = {math.cos(k * PI / 3), math.sin(k * PI / 3)} end

local function inside_hex(x, y)
    x, y = math.abs(x), math.abs(y)
    return y <= SQ3 / 2 and SQ3 * x + y <= SQ3
end

-- Keep the part of convex polygon `poly` where (p - m) . d <= 0.
local function clip(poly, mx, my, dx, dy)
    local out = {}
    local n = #poly
    for i = 1, n do
        local a, b = poly[i], poly[i % n + 1]
        local da = (a[1] - mx) * dx + (a[2] - my) * dy
        local db = (b[1] - mx) * dx + (b[2] - my) * dy
        if da <= 0 then out[#out + 1] = a end
        if (da < 0) ~= (db < 0) and da ~= db then
            local t = da / (da - db)
            out[#out + 1] = {a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t}
        end
    end
    return out
end

local function area_centroid(poly)
    local a, cx, cy = 0, 0, 0
    local n = #poly
    for i = 1, n do
        local p, q = poly[i], poly[i % n + 1]
        local w = p[1] * q[2] - q[1] * p[2]
        a, cx, cy = a + w, cx + (p[1] + q[1]) * w, cy + (p[2] + q[2]) * w
    end
    if math.abs(a) < 1e-9 then return 0, 0, 0 end
    return a / 2, cx / (3 * a), cy / (3 * a)
end

-- One fracture: Voronoi cells of well-spread sites, clipped to the hex.
-- Returns shards {area, cx, cy, pts = {{x, y}, ...}} covering the whole hex.
function S.fracture(rand, sites, gap, square)
    local half_height = square and 1 or SQ3 / 2
    local seeds = {}
    for _ = 1, 400 do
        if #seeds >= sites then break end
        local x, y = rand() * 2 - 1, (rand() * 2 - 1) * half_height
        if square or inside_hex(x, y) then
            local ok = true
            for _, s in ipairs(seeds) do
                if (s[1] - x) ^ 2 + (s[2] - y) ^ 2 < gap * gap then ok = false; break end
            end
            if ok then seeds[#seeds + 1] = {x, y} end
        end
    end
    local shards = {}
    for i, s in ipairs(seeds) do
        local poly = square and SQUARE or HEX
        for j, o in ipairs(seeds) do
            if i ~= j and #poly >= 3 then
                poly = clip(poly, (s[1] + o[1]) / 2, (s[2] + o[2]) / 2, o[1] - s[1], o[2] - s[2])
            end
        end
        local area, cx, cy = area_centroid(poly)
        if #poly >= 3 and #poly <= 16 and math.abs(area) > 1e-4 then
            shards[#shards + 1] = {area = math.abs(area), cx = cx, cy = cy, pts = poly}
        end
    end
    return shards
end

function S.bind(R, rules)
    local rgba = color

    -- The shatter's own xorshift stream, apart from gameplay and match3.vfx.
    local rng = 0x2f6e2b1
    local function rand()
        local x = rng
        x = x ~ ((x << 13) & 0xFFFFFFFF)
        x = x ~ (x >> 17)
        x = x ~ ((x << 5) & 0xFFFFFFFF)
        rng = x
        return (x >> 8) * (1.0 / 16777216.0)
    end
    local function range(r) return r[1] + (r[2] - r[1]) * rand() end

    local patterns = {}
    for k = 1, S.PATTERNS do patterns[k] = S.fracture(rand, S.SITES, S.SITE_GAP, rules.square) end
    R.shatter_patterns = patterns   -- for tests

    local shards, puffs = {}, {}
    for i = 1, S.SHARD_CAP do shards[i] = {life = 0, n = 0, lx = {}, ly = {}, uv = {}} end
    for i = 1, S.PUFF_CAP do puffs[i] = {life = 0, age = 0, delay = 0} end
    local shard_next, puff_next = 0, 0

    local function reset()
        for i = 1, S.SHARD_CAP do shards[i].life = 0 end
        for i = 1, S.PUFF_CAP do puffs[i].life = 0 end
        shard_next, puff_next = 0, 0
    end

    -- Puffs billowing out of `at`, shaped by a style (S.SMOKE, S.BURST).
    local function emit_puffs(at, radius, tint, style, delay)
        for k = 1, style.count do
            local p = puffs[puff_next % S.PUFF_CAP + 1]
            puff_next = puff_next + 1
            local a, d = (k + rand()) * TAU / style.count, (.15 + .45 * rand()) * radius
            p.x, p.y = at.x + math.cos(a) * d, at.y + math.sin(a) * d * .85
            local speed = range(style.speed) * radius
            p.vx, p.vy = math.cos(a) * speed, math.sin(a) * speed * .7 - range(style.lift) * radius
            p.r0, p.r1 = range(style.r0) * radius, range(style.r1) * radius
            p.frame, p.angle, p.spin = 1 + math.floor(rand() * 4), rand() * TAU, (rand() - .5) * 1.6
            p.tint, p.light, p.alpha = tint, style.light, style.alpha
            p.age, p.delay, p.life = 0, delay + .05 * rand(), range(style.life)
        end
    end

    -- Break `art` into shards over a puff of dust (`dust`, default S.DUST). The art is drawn
    -- as floor cells are: a 2r square centred on `at`, or, given `src`, that
    -- texture rectangle mapped onto the hex (gfx.image_hex). Reduce Motion
    -- shows nothing.
    function R.vfx_shatter(at, radius, art, dust, src)
        if R.reduced_motion or not art then return end
        local pattern = patterns[1 + math.floor(rand() * #patterns)]
        local sides = rules.square and 4 or 6
        local turn, flip = math.floor(rand() * sides) * TAU / sides, rand() < .5 and -1 or 1
        local cs, sn = math.cos(turn), math.sin(turn)
        local ox, oy, w, h, vy = 0, 0, art.w, art.h, .5
        if src then ox, oy, w, h, vy = src.x, src.y, src.w, src.h, 1 / SQ3 end
        local biggest = 0
        for _, f in ipairs(pattern) do biggest = math.max(biggest, f.area) end
        for _, f in ipairs(pattern) do
            local s = shards[shard_next % S.SHARD_CAP + 1]
            shard_next = shard_next + 1
            -- the shard's centre in the unit hex after the chosen symmetry
            local fx = f.cx * flip
            local cx, cy = fx * cs - f.cy * sn, fx * sn + f.cy * cs
            s.n = #f.pts
            for k, p in ipairs(f.pts) do
                local px = p[1] * flip
                local ux, uy = px * cs - p[2] * sn, px * sn + p[2] * cs
                s.lx[k], s.ly[k] = (ux - cx) * radius, (uy - cy) * radius
                s.uv[k] = vec2(ox + (ux * .5 + .5) * w, oy + (uy * vy + .5) * h)
            end
            for k = s.n + 1, #s.lx do s.lx[k], s.ly[k], s.uv[k] = nil, nil, nil end
            s.art, s.radius = art, radius
            s.x, s.y = at.x + cx * radius, at.y + cy * radius
            -- outwards from the impact, smaller pieces faster and spinning harder
            local size = f.area / biggest
            local d = math.sqrt(cx * cx + cy * cy)
            local dir = d > .08 and math.atan(cy, cx) or rand() * TAU
            dir = dir + (rand() - .5) * .7
            local speed = range(S.SPEED) * (1.3 - .45 * size) * radius
            s.vx = math.cos(dir) * speed
            s.vy = math.sin(dir) * speed * .8 - range(S.LIFT) * radius
            s.angle, s.spin = 0, (rand() < .5 and -1 or 1) * (2.5 + 7 * rand()) * (1.25 - .5 * size)
            -- a tumble: the shard flips about its own axis, catching the light
            s.axis, s.tilt, s.flip = rand() * PI, rand() * .6, (2 + 5 * rand()) * (rand() < .5 and -1 or 1)
            s.tilt0 = s.tilt
            s.pop = rand() < .35 and .18 + .22 * rand() or 0   -- some come towards the camera
            s.age, s.delay, s.life = 0, S.CRACK + d * .035, range(S.LIFE)
        end
        emit_puffs(at, radius, dust or S.DUST, S.SMOKE, S.CRACK * .6)
    end

    -- A matched piece's cloud: a few quick puffs in its own colour.
    function R.vfx_burst(at, radius, tint)
        if R.reduced_motion then return end
        emit_puffs(at, radius, tint, S.BURST, 0)
    end

    local function update(dt)
        local g = S.GRAVITY
        for i = 1, S.SHARD_CAP do
            local s = shards[i]
            if s.life > 0 then
                s.age = s.age + dt
                local t = s.age - s.delay
                if t >= s.life then s.life = 0
                elseif t > 0 then
                    local drag = 1 - 1.1 * dt
                    s.vx, s.vy = s.vx * drag, (s.vy + g * s.radius * dt) * drag
                    s.x, s.y = s.x + s.vx * dt, s.y + s.vy * dt
                    s.angle = s.angle + s.spin * dt
                    s.tilt = s.tilt + s.flip * dt
                end
            end
        end
        for i = 1, S.PUFF_CAP do
            local p = puffs[i]
            if p.life > 0 then
                p.age = p.age + dt
                local t = p.age - p.delay
                if t >= p.life then p.life = 0
                elseif t > 0 then
                    local drag = 1 - 2.6 * dt
                    p.vx, p.vy = p.vx * drag, p.vy * drag
                    p.x, p.y = p.x + p.vx * dt, p.y + p.vy * dt
                    p.angle = p.angle + p.spin * dt
                end
            end
        end
    end

    local pts, side = {}, {}
    local function draw_shard(s)
        local t = math.max(0, s.age - s.delay)
        local u = t / s.life
        local fade = u < .6 and 1 or 1 - (u - .6) / .4
        local fold = math.cos(s.tilt)                    -- 1 face-on, 0 edge-on
        local squash = math.max(.18, math.abs(fold))
        local scale = (1 + s.pop * math.sin(math.min(1, u * 1.4) * PI)) * (1 - .2 * u)
        local ca, sa = math.cos(s.angle), math.sin(s.angle)
        local cx, sx = math.cos(s.axis), math.sin(s.axis)
        -- the tumble shows the shard's thickness on the side turning towards us
        local depth = math.sin(s.tilt) * s.radius * .11 * scale
        local ex, ey = -sx * depth, cx * depth
        ex, ey = ex * ca - ey * sa, ex * sa + ey * ca
        for k = 1, s.n do
            -- squash along the tumble axis, then spin and scale about the shard's centre
            local x, y = s.lx[k], s.ly[k]
            local along, across = x * cx + y * sx, -x * sx + y * cx
            along = along * squash
            x, y = along * cx - across * sx, along * sx + across * cx
            x, y = (x * ca - y * sa) * scale, (x * sa + y * ca) * scale
            pts[k] = vec2(s.x + x, s.y + y)
            side[k] = vec2(s.x + x + ex, s.y + y + ey)
        end
        for k = s.n + 1, #pts do pts[k], side[k] = nil, nil end
        local alpha = math.floor(255 * fade)
        if s.age > s.delay then gfx.image_poly(s.art, side, s.uv, rgba(105, 115, 120, alpha)) end
        -- the face darkens as it turns away and flares as it turns through the light
        local light = .66 + .34 * math.max(0, fold)
        local c = math.floor(255 * light)
        gfx.image_poly(s.art, pts, s.uv, rgba(c, c, c, alpha))
        local turned = math.min(1, math.abs(s.tilt - s.tilt0) / 1.2)
        local flare = math.max(0, fold) ^ 10 * fade * turned
        if flare > .05 then
            gfx.additive(true)
            gfx.poly(pts, rgba(255, 255, 255, math.floor(90 * flare)))
            gfx.additive(false)
        end
        if s.age < s.delay + .1 then   -- the cracks glow as the layer gives way
            local glow = s.age < s.delay and s.age / s.delay or 1 - (s.age - s.delay) / .1
            pts[s.n + 1] = pts[1]
            gfx.additive(true)
            gfx.polyline(pts, math.max(1, s.radius * .045), rgba(235, 255, 255, math.floor(200 * glow)))
            gfx.additive(false)
            pts[s.n + 1] = nil
        end
    end

    local function draw()
        if R.reduced_motion then return end
        local smoke = R.vfx_smoke
        for i = 1, S.PUFF_CAP do
            local p = puffs[i]
            local t = p.age - (p.delay or 0)
            if p.life > 0 and t > 0 then
                local u = t / p.life
                local grow = 1 - (1 - u) ^ 3
                local alpha = p.alpha * math.min(1, u / .07) * (1 - u) ^ 1.3
                local c, light = p.tint, p.light
                local r, g, b = c.r + (255 - c.r) * light, c.g + (255 - c.g) * light, c.b + (255 - c.b) * light
                local size = 2 * (p.r0 + (p.r1 - p.r0) * grow)
                gfx.image_rot(smoke[p.frame], rect.centered(vec2(p.x, p.y), size2.splat(size)), p.angle,
                    rgba(math.floor(r), math.floor(g), math.floor(b), math.floor(255 * alpha)))
            end
        end
        for i = 1, S.SHARD_CAP do
            local s = shards[i]
            if s.life > 0 then draw_shard(s) end
        end
    end

    -- Layers a clearing wave removed: ice, then tablets (two layers, then one).
    local elements = require("match3.elements_view")
    local function wave()
        local g = R.g
        local floor = R.board_floor and R.board_floor()
        local radius = R.HEX_R - (R.GROUND and R.GROUND.seam_width or .18)
        for i = 0, rules.CELLS - 1 do
            local oil, ice = R.wave_oil[i] or 0, R.wave_ice[i] or 0
            local art, src
            if ice > (g.ice[i] or 0) then
                art, src = elements.layer_art(R, floor, 0, ice)
            elseif g.oil and oil > (g.oil[i] or 0) then
                art, src = elements.layer_art(R, floor, oil, 0)
            end
            if art then R.vfx_shatter(R.cell_pos(i), radius, art, nil, src) end
        end
    end

    -- Ride along with match3.vfx: the same reset, clock, wave and draw pass.
    local base_reset, base_update, base_wave, base_particles = R.vfx_reset, R.vfx_update, R.vfx_wave, R.vfx_particles
    function R.vfx_reset() base_reset(); reset() end
    function R.vfx_update(dt) base_update(dt); update(dt) end
    function R.vfx_wave(old_score) base_wave(old_score); wave() end
    function R.vfx_particles() draw(); base_particles() end
end

return S
