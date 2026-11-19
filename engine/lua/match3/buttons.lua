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
local function frame_boxes(body, pressed)
    local side = math.min(body.w, body.h)
    local depth = side * .045
    local bezel = body:inflate(-side * .019):offset(vec2(0, -depth * (pressed and .15 or .65)))
    local well = bezel:inflate(-side * .053)
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

function B.paint(box, image, state, alpha, face_colors)
    local side = math.min(box.w, box.h) * .90
    if side <= 0 then return end
    local disabled, pressed = state == "disabled", state == "pressed"
    local rim, face = disabled and pewter or brass, face_colors or faces[state]
    local function ink(c) return alpha and alpha < 1 and color.alpha(c, alpha) or c end
    local center = box:center()
    local body = rect.centered(center, size2(side, side))
    local depth, bezel, well, enamel = frame_boxes(body, pressed)
    gfx.circle(center + vec2(0, depth), side * .5, ink(shade))
    gfx.circle(center, side * .5, ink(rim.edge))
    gfx.round_rect_grad(bezel, bezel.w / 2, ink(rim.top), ink(rim.bottom))
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
end

-- A circle's signed distance field for gfx.sdf_mask, built once. The circle's
-- radius is CIRCLE_RADIUS of the field's CIRCLE_TEXELS; outside is positive.
local CIRCLE_TEXELS, CIRCLE_RADIUS, CIRCLE_RANGE = 64, 28, 8
local circle_field
local function circle_mask(face)
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

-- The progress ring's ink: a dark groove, then jade filling clockwise from
-- the top, gold once full.
local groove = color(58, 34, 16, 150)
local progress_ink = {fill = rgb(0x71B953), edge = rgb(0x2E7046), full = rgb(0xFFD25A), full_edge = rgb(0xA8651F)}

local function ring_arc(center, radius, from, to, width, ink)
    local steps = math.max(2, math.ceil(48 * (to - from)))
    local points = {}
    for i = 0, steps do
        points[#points + 1] = center + vec2.polar(2 * math.pi * (from + (to - from) * i / steps) - math.pi / 2, radius)
    end
    gfx.polyline(points, width, ink)
    gfx.circle(points[1], width / 2, ink)
    gfx.circle(points[#points], width / 2, ink)
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
    local state = options.state or "normal"
    local disabled, pressed = state == "disabled", state == "pressed"
    local rim = disabled and pewter or brass
    local face = faces[state == "hover" and "hover" or "normal"]
    local center = box:center()
    local body = rect.centered(center, size2(side, side))
    local depth, bezel, well, enamel = frame_boxes(body, pressed)
    gfx.circle(center + vec2(0, depth), side * .5, shade)
    gfx.circle(center, side * .5, rim.edge)
    gfx.round_rect_grad(bezel, bezel.w / 2, rim.top, rim.bottom)
    if options.progress then
        local band = (bezel.w - well.w) / 2
        local mid = (bezel.w + well.w) / 4
        local amount = num.saturate(options.progress)
        local full = amount >= 1
        gfx.ring(bezel:center(), mid, band * .9, groove)
        if amount > 0 then
            ring_arc(bezel:center(), mid, 0, amount, band * .9, full and progress_ink.full_edge or progress_ink.edge)
            ring_arc(bezel:center(), mid, 0, amount, band * .55, full and progress_ink.full or progress_ink.fill)
        end
    end
    gfx.circle(well:center(), well.w / 2, rim.lip)
    gfx.round_rect_grad(enamel, enamel.w / 2, face.top, face.bottom)
    if not image then return end
    local size = texture.size(image)
    if size.w <= 0 or size.h <= 0 then return end
    local w = enamel.w * 1.08
    local h = math.max(enamel.h, w * size.h / size.w)
    circle_mask(enamel)
    gfx.image(image, rect(enamel:center().x - w / 2, enamel.y - enamel.h * .02, w, h),
        disabled and color(255, 255, 255, 140) or color.WHITE)
    gfx.sdf_unmask()
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
