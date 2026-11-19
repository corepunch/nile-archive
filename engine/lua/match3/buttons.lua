-- The rim and enamel face follow the control's drawn size. Only the inset
-- illustration is a sprite, shared by every interaction state.
local B = {}
-- Normalized centers of opacity for board pieces also used on round buttons.
B.centers = setmetatable({}, {__mode = "k"})
local rgb = color.hex
local faces = {
    normal   = {top=rgb(0xFFF4D1), bottom=rgb(0xEBC284)},
    hover    = {top=rgb(0xFFFCED), bottom=rgb(0xFFE3A1)},
    selected = {top=rgb(0x83DAB1), bottom=rgb(0x288969)},
    pressed  = {top=rgb(0xCC9147), bottom=rgb(0xF0C476)},
    disabled = {top=rgb(0xF0E5D4), bottom=rgb(0xD8C8B6)},
}
local brass = {edge=rgb(0x77421F), top=rgb(0xFFF1AA), bottom=rgb(0xBF742E), lip=rgb(0xAB6C32)}
local pewter = {edge=rgb(0x736653), top=rgb(0xE7DFCB), bottom=rgb(0x9C8C72), lip=rgb(0x998871)}
local sandstone = rgb(0xBEAA91)
local shade = color(46, 29, 18, 94)

-- Thicknesses and the raised bezel offset follow the short axis for both shapes.
-- `rim` (default 1) widens the brass band for the progress styles that sit on it.
local function frame_boxes(body, pressed, rim)
    local side = math.min(body.w, body.h)
    local depth = side * .045
    local bezel = body:inflate(-side * .019):offset(vec2(0, -depth * (pressed and .15 or .65)))
    local well = bezel:inflate(-side * .053 * (rim or 1))
    return depth, bezel, well, well:inflate(-side * .014)
end

-- Paint hollow bands so the game's translucent wallet colour sits over the scenery.
function B.wallet(fill)
    return {layers = {{fixed = true, paint = function(_, _, st, _, out, alpha)
        local pressed = st and st.held
        local depth, bezel, well, face = frame_boxes(out, pressed)
        local function ink(c) return alpha < 1 and color.alpha(c, alpha) or c end
        local function band(box, width, top, bottom)
            local path = box:inflate(-width * .5)
            gfx.round_rect_line_grad(path, path.h * .5, width, ink(top), ink(bottom or top))
        end
        gfx.round_rect(out:offset(vec2(0, depth)), out.h * .5, ink(shade))
        band(out, (out.h - face.h) * .5 + depth, brass.edge)
        band(bezel, (bezel.h - well.h) * .5, brass.top, brass.bottom)
        band(well, (well.h - face.h) * .5, brass.lip)
        gfx.round_rect(face, face.h * .5, ink(fill))
    end}}}
end

-- The progress ring sits on the brass band between the bezel's edge and the
-- well. Its two round edges come from an anti-aliased signed distance field
-- of that band, built once in the bezel's proportions; a stroke wider than
-- the band fills it, so only the stroke's ends, where the percentage cuts it,
-- are its own. A dark groove shows the part still to fill.
-- The field spans RING_PAD times the bezel, so the ring stays clear of the
-- texture's clamped edge.
local RING_TEXELS, RING_RANGE, RING_PAD = 128, 4, 1.25
local ring_field
local groove = color(58, 34, 16, 150)
local progress_fill = rgb(0x71B953)
local function ring_mask(bezel, well)
    local half = RING_TEXELS / 2
    if not ring_field then
        local outer = half / RING_PAD
        local band = outer * (1 - .856 / .962)   -- frame_boxes: well 0.856, bezel 0.962 of the side
        local mid, width = outer - band / 2, band * .315
        local px = {}
        for y = 0, RING_TEXELS - 1 do
            for x = 0, RING_TEXELS - 1 do
                local r = math.sqrt((x + .5 - half) ^ 2 + (y + .5 - half) ^ 2)
                local d = math.abs(r - mid) - width
                local v = math.floor(num.saturate(.5 + d / (2 * RING_RANGE)) * 255 + .5)
                px[#px + 1] = string.char(v, v, v, 255)
            end
        end
        ring_field = texture.from_pixels(table.concat(px), RING_TEXELS, RING_TEXELS)
    end
    local area = rect.centered(bezel:center(), size2(bezel.w * RING_PAD, bezel.h * RING_PAD))
    gfx.sdf_mask(ring_field, area, RING_RANGE * area.w / RING_TEXELS, 0, 0)
end

-- Progress from 0 to 1, clockwise from the top. A full ring is not drawn:
-- the ready marker's glow and trail say it instead.
local function progress_ring(bezel, well, progress)
    local amount = num.saturate(progress)
    if amount >= 1 then return end
    ring_mask(bezel, well)
    gfx.rect(bezel, groove)
    if amount > 0 then
        local center, radius = bezel:center(), (bezel.w + well.w) / 4
        local steps = math.max(2, math.ceil(96 * amount))
        local points = {}
        for i = 0, steps do
            points[#points + 1] = center + vec2.polar(2 * math.pi * amount * i / steps - math.pi / 2, radius)
        end
        gfx.polyline(points, (bezel.w - well.w), progress_fill)
    end
    gfx.sdf_unmask()
end

-- PROGRESS STYLES UNDER REVIEW. Each keeps the brass rim legible against the
-- grass and fog behind the markers; B.ring_style picks one (0 is the jade
-- band above), `--ring-style N` sets it and `--medallion-review` lays all of
-- them out side by side.
B.ring_style = tonumber(app.arg and app.arg("ring-style") or "") or 0
B.RING_STYLES = 8

local circle_mask   -- defined with the portrait mask below
local ink_dark = rgb(0x2A1709)
local jade = rgb(0x2FA05E)
local jade_light = rgb(0x9BE27A)
local cream = rgb(0xFFF4D1)

-- An arc from the top, clockwise, as a stroke `width` wide at `radius`.
local function arc(center, radius, width, from, to, ink)
    if to <= from then return end
    local steps = math.max(2, math.ceil(96 * (to - from)))
    local points = {}
    for i = 0, steps do
        local t = from + (to - from) * i / steps
        points[#points + 1] = center + vec2.polar(2 * math.pi * t - math.pi / 2, radius)
    end
    gfx.polyline(points, width, ink)
end

local function circle_line(center, radius, width, ink)
    local box = rect.centered(center, size2(radius * 2, radius * 2))
    gfx.round_rect_line_grad(box, radius, width, ink, ink)
end

-- Each style: `scale` shrinks the medallion inside its box to leave room
-- outside it; `under(g)` paints after the bezel, before the lip; `over(g)`
-- paints on top of the picture. g = {center, side, bezel, well, enamel, amount}.
local styles = {
    -- 1 Outer track: a separate dark-cased ring outside the untouched rim.
    {scale = .84, over = function(g)
        local r, w = g.side * .5 / .84 * .93, g.side * .085
        circle_line(g.center, r, w + 3, ink_dark)
        circle_line(g.center, r, w, color(255, 244, 209, 90))
        arc(g.center, r, w, 0, g.amount, jade_light)
    end},
    -- 2 Inlay groove: a narrow dark channel down the middle of the band, brass
    -- showing either side, filled with deep jade.
    {rim = 2.4, under = function(g)
        local r, band = (g.bezel.w + g.well.w) / 4, (g.bezel.w - g.well.w) / 2
        circle_line(g.center, r, band * .55, ink_dark)
        arc(g.center, r, band * .34, 0, g.amount, jade_light)
    end},
    -- 3 Inner bezel: the rim is untouched; the ring runs just inside the lip,
    -- over the picture's edge, on a dark backing.
    {over = function(g)
        local r, w = g.enamel.w * .5 - g.side * .035, g.side * .06
        circle_line(g.center, r, w + 2.5, ink_dark)
        circle_line(g.center, r, w, color(255, 244, 209, 110))
        arc(g.center, r, w, 0, g.amount, jade_light)
    end},
    -- 4 Segments: ten studs on the band, lit jade as pieces are banked.
    {rim = 2.4, under = function(g)
        local r, band, n = (g.bezel.w + g.well.w) / 4, (g.bezel.w - g.well.w) / 2, 10
        local lit = math.floor(g.amount * n + 1e-6)
        for i = 0, n - 1 do
            local at = g.center + vec2.polar(2 * math.pi * (i + .5) / n - math.pi / 2, r)
            gfx.circle(at, band * .3, ink_dark)
            gfx.circle(at, band * .21, i < lit and jade_light or rgb(0x6B4A2A))
        end
    end},
    -- 5 Gauge: a cased bar across the bottom of the medallion, over the rim.
    {over = function(g)
        local w, h = g.side * .78, g.side * .17
        local bar = rect.centered(g.center + vec2(0, g.side * .44), size2(w, h))
        gfx.round_rect(bar:offset(vec2(0, 2)), h / 2, shade)
        gfx.round_rect(bar, h / 2, ink_dark)
        local inner = bar:inflate(-h * .2)
        gfx.round_rect(inner, inner.h / 2, rgb(0x5A3A1E))
        if g.amount > 0 then
            local fill = rect(inner.x, inner.y, math.max(inner.h, inner.w * g.amount), inner.h)
            gfx.round_rect_grad(fill, fill.h / 2, jade_light, jade)
        end
    end},
    -- 6 Clock shade: the part still to gather shades the portrait, like a
    -- cooldown; the rim is untouched.
    {over = function(g)
        if g.amount >= 1 then return end
        local r = g.enamel.w / 2
        circle_mask(g.enamel)
        arc(g.center, r / 2, r * 1.02, g.amount, 1, color(30, 18, 8, 150))
        gfx.sdf_unmask()
        if g.amount > 0 then
            gfx.polyline({g.center, g.center + vec2.polar(-math.pi / 2, r)}, 2, cream)
            gfx.polyline({g.center, g.center + vec2.polar(2 * math.pi * g.amount - math.pi / 2, r)}, 2, cream)
        end
    end},
    -- 7 Badge: a small pie medallion at the lower right of the rim.
    {over = function(g)
        local at, r = g.center + vec2(g.side * .36, g.side * .34), g.side * .2
        gfx.circle(at + vec2(0, 1.5), r, shade)
        gfx.circle(at, r, ink_dark)
        gfx.circle(at, r * .8, rgb(0x5A3A1E))
        arc(at, r * .4, r * .8, 0, g.amount, jade_light)
        circle_line(at, r * .8, 1.2, cream)
    end},
    -- 8 Cased band: the jade arc keeps today's place on the band, but darker,
    -- and thin dark lines re-draw the band's two edges over it.
    {rim = 2.4, under = function(g)
        local r, band = (g.bezel.w + g.well.w) / 4, (g.bezel.w - g.well.w) / 2
        circle_line(g.center, r, band * .8, color(58, 34, 16, 120))
        arc(g.center, r, band * .8, 0, g.amount, jade)
        circle_line(g.center, r - band * .45, 1.4, ink_dark)
        circle_line(g.center, r + band * .45, 1.4, ink_dark)
    end},
}

-- The chosen style's hooks, or nil for the jade band. A full ring is never
-- drawn: the ready marker's trail says it.
local function ring_style(style) return styles[style or B.ring_style] end
local function ring_hook(st, hook, center, side, bezel, well, enamel, progress)
    if not (st and st[hook] and progress) then return end
    local amount = num.saturate(progress)
    if amount >= 1 then return end
    st[hook]({center=center, side=side, bezel=bezel, well=well, enamel=enamel, amount=amount})
end

-- `progress` (0 to 1, optional) rings the brass band as on the medallion.
function B.paint(box, image, state, alpha, face_colors, progress, style)
    local st = progress and ring_style(style)
    local side = math.min(box.w, box.h) * .90 * (st and st.scale or 1)
    if side <= 0 then return end
    local disabled, pressed = state == "disabled", state == "pressed"
    local rim, face = disabled and pewter or brass, face_colors or faces[state]
    local function ink(c) return alpha and alpha < 1 and color.alpha(c, alpha) or c end
    local center = box:center()
    local body = rect.centered(center, size2(side, side))
    local depth, bezel, well, enamel = frame_boxes(body, pressed, st and st.rim)
    gfx.circle(center + vec2(0, depth), side * .5, ink(shade))
    gfx.circle(center, side * .5, ink(rim.edge))
    gfx.round_rect_grad(bezel, bezel.w / 2, ink(rim.top), ink(rim.bottom))
    if progress and not st then progress_ring(bezel, well, progress) end
    ring_hook(st, "under", bezel:center(), side, bezel, well, enamel, progress)
    gfx.circle(well:center(), well.w / 2, ink(rim.lip))
    gfx.round_rect_grad(enamel, enamel.w / 2, ink(face.top), ink(face.bottom))
    local dst = rect.centered(enamel:center(), size2(side * .78, side * .78)):fit(texture.size(image))
    local anchor = B.centers[image]
    if anchor then dst = dst:offset(enamel:center() - dst:point(anchor)) end
    if disabled then
        gfx.image_inset(image, dst, vec2(side * .014, side * .018), ink(sandstone))
    else
        gfx.image(image, dst:offset(vec2(0, side * .018)), ink(shade))
        gfx.image(image, dst, ink(color.WHITE))
    end
    ring_hook(st, "over", bezel:center(), side, bezel, well, enamel, progress)
end

-- A circle's signed distance field for gfx.sdf_mask, built once. The circle's
-- radius is CIRCLE_RADIUS of the field's CIRCLE_TEXELS; outside is positive.
local CIRCLE_TEXELS, CIRCLE_RADIUS, CIRCLE_RANGE = 64, 28, 8
local circle_field
circle_mask = function(face)
    if not circle_field then
        local px, half = {}, CIRCLE_TEXELS / 2
        for y = 0, CIRCLE_TEXELS - 1 do
            for x = 0, CIRCLE_TEXELS - 1 do
                local d = math.sqrt((x + .5 - half) ^ 2 + (y + .5 - half) ^ 2) - CIRCLE_RADIUS
                local v = math.floor(num.saturate(.5 + d / (2 * CIRCLE_RANGE)) * 255 + .5)
                px[#px + 1] = string.char(v, v, v, 255)
            end
        end
        circle_field = texture.from_pixels(table.concat(px), CIRCLE_TEXELS, CIRCLE_TEXELS)
    end
    local texel = face.w / (2 * CIRCLE_RADIUS)
    gfx.sdf_mask(circle_field, rect.centered(face:center(), size2(CIRCLE_TEXELS * texel, CIRCLE_TEXELS * texel)),
        CIRCLE_RANGE * texel, 0, 0)
end

-- A character's portrait in the round buttons' brass rim: the picture fills
-- the enamel face, its top at the face's top so the head sits in the upper
-- half and the shoulders meet the rim. `options` may give a `state` (normal,
-- hover, pressed or disabled, as for the buttons: pressed sinks, disabled
-- turns the rim pewter and fades the picture) and a `progress` from 0 to 1,
-- drawn as a ring filling the brass band clockwise from the top.
function B.medallion(box, image, options)
    options = options or {}
    local side = math.min(box.w, box.h)
    if side <= 0 then return end
    local st = options.progress and ring_style(options.style)
    side = side * (st and st.scale or 1)
    local state = options.state or "normal"
    local disabled, pressed = state == "disabled", state == "pressed"
    local rim = disabled and pewter or brass
    local face = faces[state == "hover" and "hover" or "normal"]
    local center = box:center()
    local body = rect.centered(center, size2(side, side))
    local depth, bezel, well, enamel = frame_boxes(body, pressed, st and st.rim)
    gfx.circle(center + vec2(0, depth), side * .5, shade)
    gfx.circle(center, side * .5, rim.edge)
    gfx.round_rect_grad(bezel, bezel.w / 2, rim.top, rim.bottom)
    if options.progress and not st then progress_ring(bezel, well, options.progress) end
    ring_hook(st, "under", bezel:center(), side, bezel, well, enamel, options.progress)
    gfx.circle(well:center(), well.w / 2, rim.lip)
    gfx.round_rect_grad(enamel, enamel.w / 2, face.top, face.bottom)
    local size = image and texture.size(image)
    if not size or size.w <= 0 or size.h <= 0 then
        return ring_hook(st, "over", bezel:center(), side, bezel, well, enamel, options.progress)
    end
    local w = enamel.w * 1.08
    local h = math.max(enamel.h, w * size.h / size.w)
    circle_mask(enamel)
    gfx.image(image, rect(enamel:center().x - w / 2, enamel.y - enamel.h * .02, w, h),
        disabled and color(255, 255, 255, 140) or color.WHITE)
    gfx.sdf_unmask()
    ring_hook(st, "over", bezel:center(), side, bezel, well, enamel, options.progress)
end

-- `caption` adds the control's caption keys (text, em, text_align, text_fit)
-- for a button that also shows a figure, as Play shows its level.
function B.navigation(name, caption, palette)
    local spec = {}
    for key, value in pairs(caption or {}) do spec[key] = value end
    for state in pairs(faces) do
        spec[state] = {offset={0, 0}, layers={{paint=function(_, _, _, skin, out, alpha)
            B.paint(out, skin.images["action-" .. name], state, alpha, palette and palette[state])
        end}}}
    end
    return spec
end

return B
