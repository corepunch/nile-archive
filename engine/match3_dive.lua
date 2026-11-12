-- match3_dive.lua — the town <-> board transition styles
-- (`require("match3.dive")`, used by match3.game). game.json's "dive" block
-- picks the style and dresses it in the game's theme; `--dive-style NAME`
-- overrides the style for review. A style covers the screen being left in
-- `out` seconds and uncovers the next one in `inn`. `look(d, leaving, u)` gives
-- the town camera's zoom and pan while the town shows; `draw(d, leaving, u)`
-- paints the cover. d.focus is the point of the screen showing now (the newest
-- building, or the board's centre), d.theme the game's dress, d.label an
-- optional caption and d.say the game's text call.
local D = {}

local CLEAR, WHITE = color(0, 0, 0, 0), color(255, 255, 255)
local SQRT3, PI = math.sqrt(3), math.pi

local function hash(i) local x = math.sin(i * 12.9898) * 43758.5453; return x - math.floor(x) end
local function window(u, from, to) return num.saturate((u - from) / (to - from)) end
local function reach(full, p)   -- distance from p to the farthest corner
    local far = 0
    for _, uv in ipairs{vec2(0, 0), vec2(1, 0), vec2(1, 1), vec2(0, 1)} do
        far = math.max(far, rect.point(full, uv):dist(p))
    end
    return far
end
local function fade(c, a) return color(c.r, c.g, c.b, c.a * num.saturate(a)) end

------------------------------------------------------------------ the theme

local function parse(s) return color.hex(tonumber(s:gsub("^#", ""), 16)) end
local DEFAULT = {motif = "", face = {"#25625C", "#102F32"}, rim = "#F1BE52", accent = "#FFF7E0",
                 bands = {"#F1BE52", "#FFF7E0", "#25625C", "#102F32"}, lights = {"#F1BE52"},
                 drift = "#F0F5FC", drift_shade = "#BECFE4", drift_light = "#FFFFFF", badge = "#102F32"}
function D.theme(spec)
    spec = spec or {}
    local t = {motif = spec.motif or DEFAULT.motif}
    for _, k in ipairs{"rim", "accent", "drift", "drift_shade", "drift_light", "badge"} do t[k] = parse(spec[k] or DEFAULT[k]) end
    for _, k in ipairs{"face", "face_alt", "bands", "lights"} do
        t[k] = {}
        for i, s in ipairs(spec[k] or spec.face or DEFAULT[k] or DEFAULT.face) do t[k][i] = parse(s) end
    end
    return t
end

------------------------------------------------------------------ motifs

local function snowflake(c, r, angle, col, plain)
    for k = 0, 2 do
        local a = vec2.polar(angle + k * PI / 3, r)
        gfx.line(c - a, c + a, math.max(1.5, r * .16), col)
    end
    if plain then return end
    for k = 0, 5 do
        local dir = angle + k * PI / 3
        local m = c + vec2.polar(dir, r * .58)
        gfx.line(m, m + vec2.polar(dir + .8, r * .32), math.max(1.2, r * .12), col)
        gfx.line(m, m + vec2.polar(dir - .8, r * .32), math.max(1.2, r * .12), col)
    end
end

-- A pointed leaf, lit on one half; `flat` for its shadow.
local function leaf(c, len, angle, col, flat)
    local base, tip = c + vec2(-len, 0):rotate(angle), c + vec2(len, 0):rotate(angle)
    local up, down = {base}, {base}
    for i = 1, 9 do
        local x, w = -len + 2 * len * i / 10, len * .4 * math.sin(PI * i / 10) ^ .8
        up[#up + 1] = c + vec2(x, -w):rotate(angle)
        down[#down + 1] = c + vec2(x, w):rotate(angle)
    end
    up[#up + 1], down[#down + 1] = tip, tip
    gfx.poly(up, col)
    gfx.poly(down, flat and col or color.shade(col, .8))
    if not flat then gfx.line(base, tip, math.max(1.2, len * .05), color.lerp(col, WHITE, .3)) end
end

local function sun(c, r, angle, col, core)
    gfx.star(c, r, .62, 12, angle, col)
    gfx.circle(c, r * .52, core)
    gfx.circle(c, r * .3, col)
end

-- The theme's emblem: a snowflake, a sun amulet or a star.
local function emblem(theme, c, r, angle, small)
    if theme.motif == "snow" then snowflake(c, r, angle, theme.accent, small)
    elseif theme.motif == "leaves" then sun(c, r, angle, theme.rim, theme.face[2])
    else gfx.star(c, r, .45, 5, angle, theme.rim) end
end

local styles = {}

------------------------------------------------------------------ flash

-- The original: a warm flash and blur while the town's camera rushes in.
styles.flash = {
    out = .32, inn = .38,
    look = function(_, leaving, u)
        if leaving then return 1 + 2.4 * ease.in_cubic(u) end
        return 1 + 2 * (1 - ease.out_cubic(u))
    end,
    draw = function(_, leaving, u)
        local blur, flash
        if leaving then blur, flash = 16 * ease.in_cubic(u), 110 * num.saturate((u - .55) / .45)
        else blur, flash = 14 * (1 - ease.out_cubic(u)), 110 * (1 - u) * (1 - u) end
        gfx.backdrop(blur, color(255, 247, 224, flash))
    end,
}

------------------------------------------------------------------ hex

-- Hex bloom: the board's own flat-top cells ripple out from the building,
-- spinning into a honeycomb of the theme's tiles, then fall away from the board.
styles.hex = {
    out = .48, inn = .52,
    look = function(_, leaving, u)
        if leaving then return 1 + .45 * ease.in_cubic(u) end
        return 1 + .3 * (1 - ease.out_cubic(u))
    end,
    draw = function(d, leaving, u)
        local th, full, r = d.theme, app.bleed(), 46
        local far = reach(full, d.focus)
        local cols, rows = math.ceil(far / (1.5 * r)) + 1, math.ceil(far / (SQRT3 * r)) + 1
        for i = -cols, cols do
            for j = -rows, rows do
                local c = d.focus + vec2(i * 1.5 * r, (j + (i % 2) * .5) * SQRT3 * r)
                if rect.contains(rect.inflate(full, r), c) then
                    local delay = c:dist(d.focus) / far * .55
                    local p = window(u, delay, delay + .45)
                    local s = leaving and ease.out_back(p, 1.3) or 1 - ease.in_back(p, 1.3)
                    if s > .01 then
                        local spin = (leaving and 1 - p or p) * -1.1
                        local h = hash(i * 31 + j * 17)
                        local face = h > .7 and th.face_alt or th.face
                        gfx.ngon(c, r * 1.03 * s, 6, spin, th.rim)
                        gfx.ngon_grad(c, (r - 3.5) * s, 6, spin, face[1], face[2])
                        if h < .3 and s > .4 then emblem(th, c, r * .42 * s, spin * 2) end
                    end
                end
            end
        end
        local pulse = leaving and window(u, .7, 1) or 1 - window(u, 0, .35)
        if pulse > 0 then
            gfx.additive(true)
            gfx.glow(d.focus, 60 + 140 * pulse, fade(th.accent, .65 * pulse), CLEAR)
            gfx.additive(false)
            emblem(th, d.focus, 30 * ease.out_back(pulse, 2.5), u * 2)
        end
    end,
}

------------------------------------------------------------------ drift

-- Drift: two banks sweep in from the sides and meet over the town, then part
-- to show the board: snowdrifts under falling snow, jungle leaves, or clouds.
-- The shapes of one bank, back to front: {centre, size, angle, colour}.
local function bank_shapes(th, full, side, edge, t, seed)
    local leaves, out = th.motif == "leaves", {}
    local rows = math.ceil(full.h / 60) + 2
    for ring = 4, 0, -1 do   -- deeper rows first, the ragged front last
        for k = -1, rows do
            local h = hash(seed + ring * 97 + k * 5)
            local r = (leaves and 50 or 58) + 40 * h - ring * 2
            local sway = math.sin(t * 6 + k * 1.7 + ring) * (ring == 0 and 7 or 3)
            local x = edge - side * (r * .3 + ring * 95 + 40 * hash(seed + k * 3 + ring))
            local y = full.y + (k + (ring % 2) * .5) * 60 + 20 * hash(seed + k + ring * 13)
            local angle = (side < 0 and 0 or PI) + (hash(seed + k * 13 + ring) - .5) * 1.8 + sway * .02
            local col = leaves and ((k + ring) % 3 == 0 and th.drift_light or th.drift) or th.drift
            out[#out + 1] = {vec2(x + sway, y), r, angle, col}
        end
    end
    return out
end
local function drift_body(th, full, side, edge)
    local body = side < 0 and rect(edge - full.w - 400, full.y - 200, full.w + 400, full.h + 400)
                          or rect(edge, full.y - 200, full.w + 400, full.h + 400)
    if th.motif == "leaves" then gfx.rect(body, color.shade(th.drift_shade, .8))
    else gfx.rect_grad(body, th.drift, th.drift_shade) end
end
local function drift_front(th, shapes)
    local shadow = color.shade(th.drift_shade, th.motif == "leaves" and .7 or .95)
    for _, s in ipairs(shapes) do
        if th.motif == "leaves" then
            leaf(s[1] + vec2(3, 8), s[2], s[3], shadow, true)
            leaf(s[1], s[2], s[3], s[4])
        else
            gfx.circle(s[1] + vec2(0, s[2] * .16), s[2], shadow)
            gfx.circle(s[1], s[2], s[4])
            gfx.circle(s[1] - vec2(s[2] * .22, s[2] * .26), s[2] * .55, th.drift_light)
        end
    end
end
local function flurry(th, full, t, amount)   -- what blows across while the banks close
    for k = 1, 42 do
        local x = full.x + full.w * hash(k * 3.1)
        local y = full.y + (full.h * hash(k * 5.7) + t * (180 + 140 * hash(k))) % (full.h + 60) - 30
        local c = vec2(x + math.sin(t * 3 + k) * 22, y)
        local r = 5 + 9 * hash(k * 9.3)
        if th.motif == "leaves" then leaf(c, r * 1.6, t * 4 + k, fade(th.drift_light, amount), true)
        elseif th.motif == "snow" then snowflake(c, r, t * 2 + k, fade(th.accent, amount), r < 9)
        else gfx.circle(c, r * .5, fade(WHITE, amount * .6)) end
    end
end
styles.drift = {
    out = .55, inn = .6,
    look = function(_, leaving, u)
        if leaving then return 1 + .3 * ease.in_out_cubic(u) end
        return 1 + .2 * (1 - ease.out_cubic(u))
    end,
    draw = function(d, leaving, u)
        local th, full = d.theme, app.bleed()
        local cx = full:center().x
        local e = leaving and ease.in_out_cubic(u) or 1 - ease.in_out_cubic(u)
        gfx.backdrop(6 * e, CLEAR)
        local left, right = num.lerp(full.x - 520, cx + 24, e), num.lerp(full.x + full.w + 520, cx - 24, e)
        drift_body(th, full, -1, left - 300)
        drift_body(th, full, 1, right + 300)
        drift_front(th, bank_shapes(th, full, -1, left, d.t, 11))
        drift_front(th, bank_shapes(th, full, 1, right, d.t, 47))
        flurry(th, full, d.t, math.sin(e * PI) + e * .4)
        local pop = leaving and window(u, .8, 1) or 1 - window(u, 0, .3)
        if pop > 0 then
            gfx.additive(true)
            gfx.glow(vec2(cx, full:center().y), 160 * pop, fade(th.accent, .5 * pop), CLEAR)
            gfx.additive(false)
            emblem(th, full:center(), 40 * ease.out_back(pop, 2.5), d.t * 2)
        end
    end,
}

------------------------------------------------------------------ iris

-- Iris: the camera pushes in while a rimmed iris frames the building, holds a
-- beat, then snaps shut on the theme's emblem; it pops open on the board.
-- The rim carries the theme's lights: fairy lights, or gold studs.
styles.iris = {
    out = .62, inn = .6,
    look = function(_, leaving, u)
        if leaving then return 1 + 1.3 * ease.in_cubic(u) end
        return 1 + .6 * (1 - ease.out_cubic(u))
    end,
    draw = function(d, leaving, u)
        local th, full = d.theme, app.bleed()
        local far, hold = reach(full, d.focus) + 20, 82
        local r
        if leaving then
            r = u < .6 and num.lerp(far, hold, ease.out_cubic(u / .6)) or hold * (1 - ease.in_back(window(u, .6, 1), 2.2))
        else
            r = u < .3 and hold * ease.out_back(u / .3, 2) or num.lerp(hold, far, ease.in_quart(window(u, .4, 1)))
        end
        r = math.max(0, r)
        local thick = 2 * far + 200
        gfx.ring(d.focus, r + thick / 2, thick, th.face[2])
        if r > 1 then
            gfx.ring(d.focus, r + 22, 30, fade(th.face[1], .9))
            gfx.ring(d.focus, r + 4, 8, th.rim)
            local n = math.max(6, math.floor(2 * PI * (r + 22) / 30))
            for k = 0, n - 1 do
                local c = d.focus + vec2.polar(k / n * 2 * PI + d.t * .8, r + 22)
                local lit = th.motif == "snow" and .55 + .45 * math.sin(d.t * 14 + k * 2.1) or 1
                local col = th.lights[k % #th.lights + 1]
                if th.motif == "snow" then
                    gfx.additive(true)
                    gfx.glow(c, 13, fade(col, .55 * lit), CLEAR)
                    gfx.additive(false)
                end
                gfx.circle(c, th.motif == "snow" and 4.5 or 3.5, fade(col, .4 + .6 * lit))
            end
        end
        if th.motif ~= "" then flurry(th, full, d.t, .9) end
        local pop = leaving and window(u, .82, 1) or 1 - window(u, 0, .32)
        if pop > 0 then emblem(th, d.focus, 34 * ease.out_back(pop, 2.5), u * 2) end
    end,
}

------------------------------------------------------------------ bands

-- Bands: diagonal bands in the theme's colours sweep across carrying the
-- level's name on a tag, then peel off in the same direction. Snow wraps the
-- top band like a present; leaves draw an explorer's dashed trail to an X.
-- The part of a convex polygon between lo and hi along s, measured from o.
local function clip(pts, o, s, lo, hi)
    local function cut(list, f)
        local out = {}
        for i = 1, #list do
            local p, q = list[i], list[i % #list + 1]
            local fp, fq = f(p), f(q)
            if fp >= 0 then out[#out + 1] = p end
            if (fp >= 0) ~= (fq >= 0) then out[#out + 1] = p + (q - p):scale(fp / (fp - fq)) end
        end
        return out
    end
    pts = cut(pts, function(p) return (p - o):dot(s) - lo end)
    return cut(pts, function(p) return hi - (p - o):dot(s) end)
end
local function band_dress(d, o, s, n, far, a, b)
    local th = d.theme
    local function at(ps, pn) return o + s:scale(ps) + n:scale(pn) end
    if th.motif == "snow" then
        for k = 1, 60 do
            local ps, pn = (hash(k * 2.3) * 2 - 1) * far, (hash(k * 4.1) * 2 - 1) * far
            if ps > a + 14 and ps < b - 14 then snowflake(at(ps, pn), 6 + 10 * hash(k), k, fade(th.accent, .35), true) end
        end
        -- the wrapping's ribbon cross, cut to the band
        local function strip(r, c)
            local pts = clip({rect.point(r, vec2(0, 0)), rect.point(r, vec2(1, 0)), r:max(), rect.point(r, vec2(0, 1))}, o, s, a, b)
            if #pts >= 3 then gfx.poly(pts, c) end
        end
        local tall, wide = rect.centered(o, size2(36, 2 * far)), rect.centered(o, size2(2 * far, 36))
        strip(tall, th.rim); strip(wide, th.rim)
        strip(tall:inflate2(vec2(-12, 0)), color.shade(th.rim, .85)); strip(wide:inflate2(vec2(0, -12)), color.shade(th.rim, .85))
    elseif th.motif == "leaves" then
        local trail = function(ps) return 150 * math.sin(ps / 120) - 120 end
        for ps = -far, far, 26 do
            if ps > a and ps + 14 < b then gfx.line(at(ps, trail(ps)), at(ps + 14, trail(ps + 14)), 5, fade(th.rim, .8)) end
        end
        local x = -80   -- above the tag on a phone screen
        if x > a + 20 and x < b - 20 then
            local c = at(x, trail(x))
            gfx.line(c - vec2(14, 14), c + vec2(14, 14), 7, th.lights[#th.lights])
            gfx.line(c - vec2(14, -14), c + vec2(14, -14), 7, th.lights[#th.lights])
        end
    end
end
local function badge(d, o, b)
    local th = d.theme
    local box = rect.centered(o, size2(320 * b, 66 * b))
    gfx.shadow(box:offset(vec2(0, 6)), 33 * b, 14, color(0, 0, 0, 90))
    if th.motif == "snow" then   -- a gift tag's bow
        local top = vec2(o.x, box.y + 2 * b)
        gfx.circle(top + vec2(-22 * b, -10 * b), 16 * b, th.rim)
        gfx.circle(top + vec2(22 * b, -10 * b), 16 * b, th.rim)
        gfx.circle(top + vec2(-22 * b, -10 * b), 8 * b, th.badge)
        gfx.circle(top + vec2(22 * b, -10 * b), 8 * b, th.badge)
    elseif th.motif == "leaves" then
        leaf(vec2(box.x + 6 * b, o.y - 14 * b), 34 * b, PI + .5, th.drift)
        leaf(vec2(box:max().x - 6 * b, o.y - 14 * b), 34 * b, -.5, th.drift)
    end
    gfx.round_rect(box, 33 * b, th.rim)
    gfx.round_rect(box:inflate(-4 * b), 29 * b, th.badge)
    if th.motif == "snow" then gfx.circle(vec2(o.x, box.y + 2 * b), 9 * b, th.rim) end
    if b > .35 then d.say(d.label, box:inflate(-12 * b), 24 * b, "cream") end
end
styles.bands = {
    out = .5, inn = .55,
    look = function(_, leaving, u)
        if leaving then return 1 + .15 * ease.in_cubic(u), vec2(-90 * ease.in_cubic(u), 0) end
        return 1 + .1 * (1 - ease.out_cubic(u)), vec2(90 * (1 - ease.out_cubic(u)), 0)
    end,
    draw = function(d, leaving, u)
        local bands, full = d.theme.bands, app.bleed()
        local o = full:center()
        local s, n = vec2.polar(-.35, 1), vec2.polar(-.35 + PI / 2, 1)
        local far = reach(full, o) + 40
        local function band(a, b, c)
            if b <= a then return end
            local l = n:scale(far + 60)
            gfx.poly({o + s:scale(a) + l, o + s:scale(b) + l, o + s:scale(b) - l, o + s:scale(a) - l}, c)
        end
        gfx.backdrop(4 * (leaving and u or 1 - u), CLEAR)
        local a, b
        for k, c in ipairs(bands) do
            local delay = (leaving and k - 1 or #bands - k) * .075
            local edge = num.lerp(-far, far, ease.in_out_cubic(window(u, delay, delay + 1 - .075 * (#bands - 1))))
            if leaving then a, b = -far - 10, edge else a, b = edge, far + 10 end
            band(a, b, c)
            if leaving then band(edge - 7, edge, color.shade(c, 1.25)) else band(edge, edge + 7, color.shade(c, 1.25)) end
        end
        band_dress(d, o, s, n, far, a, b)
        local k = leaving and ease.out_back(window(u, .55, 1), 1.8) or 1 - ease.in_back(window(u, 0, .45), 1.8)
        if d.label and k > .02 then badge(d, o, k) end
    end,
}

D.names = {"flash", "hex", "drift", "iris", "bands"}
function D.get(name) return styles[name or "flash"] or styles.flash end

return D
