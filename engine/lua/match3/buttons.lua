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

-- Progress from 0 to 1 is a gauge across the bottom of the round marker: a
-- dark-cased bar over the rim, filled with jade from the left, so the rim
-- and picture stay whole. A full gauge is not drawn: the ready marker's glow
-- and trail say it instead.
local gauge_case = rgb(0x2A1709)
local gauge_track = rgb(0x5A3A1E)
local gauge_top, gauge_bottom = rgb(0x9BE27A), rgb(0x2FA05E)
local function progress_gauge(center, side, progress)
    local amount = num.saturate(progress)
    if amount >= 1 then return end
    local h = side * .17
    local bar = rect.centered(center + vec2(0, side * .44), size2(side * .78, h))
    gfx.round_rect(bar:offset(vec2(0, 2)), h / 2, shade)
    gfx.round_rect(bar, h / 2, gauge_case)
    local inner = bar:inflate(-h * .2)
    gfx.round_rect(inner, inner.h / 2, gauge_track)
    if amount > 0 then
        local fill = rect(inner.x, inner.y, math.max(inner.h, inner.w * amount), inner.h)
        gfx.round_rect_grad(fill, fill.h / 2, gauge_top, gauge_bottom)
    end
end

-- `progress` (0 to 1, optional) shows a gauge as on the medallion.
function B.paint(box, image, state, alpha, face_colors, progress)
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
        gfx.image_inset(image, dst, vec2(side * .014, side * .018), ink(face.inset or sandstone))
    else
        gfx.image(image, dst:offset(vec2(0, side * .018)), ink(shade))
        gfx.image(image, dst, ink(color.WHITE))
    end
    if progress then progress_gauge(center, side, progress) end
end

local corners = {vec2(0, 0), vec2(1, 0), vec2(1, 1), vec2(0, 1)}

-- Follow the rounded bevel within image_poly's 16-point limit.
local function rounded_picture(image, box, radius, tint)
    local inner = box:inflate(-radius)
    local points, uv = {}, {}
    for corner, position in ipairs(corners) do
        local center = inner:point(position)
        local start = math.pi * (1 + (corner - 1) * .5)
        for segment = 0, 3 do
            local point = center + vec2.polar(start + math.pi * segment / 6, radius)
            points[#points + 1] = point
            uv[#uv + 1] = vec2((point.x - box.x) / box.w * image.w, (point.y - box.y) / box.h * image.h)
        end
    end
    gfx.image_poly(image, points, uv, tint)
end

-- Leave the cast shadow fixed when the rounded bevel sinks on press.
local stone_rim = {
    {shadow = "#38211485", radius = 16, blur = 5, inset = {1, 1, 1, 2}, offset = {0, 5}, fixed = true},
    {fill = "#795131", radius = 16},
    {name = "lit_stone", fill = "#FFE5AC", fill2 = "#BC8A51", radius = 14, inset = {1, 1, 1, 3}},
    {fill = "#6F4729", radius = 12, inset = {4, 4, 4, 5}},
}

local function stone_tile(face)
    local layers = {table.unpack(stone_rim)}
    for _, layer in ipairs(face) do layers[#layers + 1] = layer end
    return layers
end

local function paint_funding_tag(box, skin, out, alpha)
    local scale = out.w / box.w
    local width = math.min(out.w - 6 * scale, 68 * scale)
    local tag = rect(out.x + (out.w - width) / 2, out:max().y - 23 * scale, width, 20 * scale)
    gfx.shadow(tag:offset(vec2(0, 2 * scale)), 6 * scale, 3 * scale, color.alpha(rgb(0x2D180C), alpha * .65))
    gfx.round_rect(tag, 6 * scale, color.alpha(rgb(0xE2B978), alpha))
    gfx.round_rect(tag:inflate(-scale), 5 * scale, color.alpha(rgb(0x723620), alpha))
    text.fit(skin:text("funding_tag", 12), tag:inflate2(vec2(-4 * scale, 0)), vec2(.5, .5), "NEED FUNDS")
end

-- Atlas rows follow the four projects in each advent or expedition epoch.
function B.project(unlocks)
    local thumbnails
    return {
        normal = {layers = stone_tile{
            {inset = {6, 6, 6, 6}, paint = function(box, node, _, skin, out, alpha)
                local project = node.project
                if not project then return end
                local built = project.state == "built"
                if not thumbnails then
                    local sheet = texture.load("city/epochs/projects.jpg")
                    assert(sheet.tex, "missing project thumbnails")
                    local cell = sheet.w / 4
                    thumbnails = {}
                    for i, unlock in ipairs(unlocks) do
                        local x, y = (i - 1) % 4 * cell, ((i - 1) // 4) * cell
                        thumbnails[unlock.building] = texture.region(sheet, rect(x, y, cell, cell))
                    end
                end
                local image = thumbnails[project.key]
                local tint = built and rgb(0xA6A6A6) or color.WHITE
                -- Preserve the dive transition's mask while rounding the painting.
                rounded_picture(image, out, 10 * out.w / box.w, color.alpha(tint, alpha))
                local tick = skin.images.tick
                if built and tick then
                    local side = math.min(out.w, out.h) * .76
                    local dst = rect.centered(out:center(), size2(side, side)):fit(texture.size(tick))
                    gfx.image(tick, dst:offset(vec2(0, side * .06)), color.alpha(rgb(0x24160B), alpha * .7))
                    gfx.image(tick, dst, color.alpha(color.WHITE, alpha))
                elseif project.state == "funding" then
                    paint_funding_tag(box, skin, out, alpha)
                end
            end},
        }},
        hover = {set = {lit_stone = {fill = "#FFF3D1"}}},
        pressed = {offset = {0, 2}},
    }
end

-- Terracotta is the default; winter markets can supply their own enamel colors.
function B.project_play(palette)
    palette = palette or {
        normal = {fill = "#C36543", fill2 = "#913F28"},
        hover = {fill = "#D0714C", fill2 = "#A4482D"},
        pressed = {fill = "#A84C30", fill2 = "#823523"},
    }
    return {
        text = "cream", em = 25, text_wrap = true,
        normal = {layers = stone_tile{
            {fill = "#E8A264", radius = 10, inset = {6, 6, 6, 7}},
            {name = "enamel", fill = palette.normal.fill, fill2 = palette.normal.fill2, radius = 9, inset = {7, 7, 7, 9}},
            {paint = function(_, node, _, skin, out, alpha)
                if node and node.text and node.text ~= "" then return end
                local icon = skin.images["action-play"]
                if icon then gfx.image(icon, out:inflate(-out.h * .21):fit(texture.size(icon)), color.alpha(color.WHITE, alpha)) end
            end},
        }},
        hover = {set = {enamel = palette.hover}},
        pressed = {offset = {0, 2}, set = {enamel = palette.pressed}},
        disabled = {alpha = .55},
    }
end

function B.project_bar()
    return {normal = {layers = {
        {image = "city/epochs/town-bar.jpg"},
        {fill = "#835934", height_ratio = .025},
        {fill = "#FAE3AE", height_ratio = .035, offset = {0, 2}},
        {fill = "#AA7A4680", height_ratio = .025, offset = {0, 6}},
    }}}
end

function B.epoch_medal()
    return {normal = {layers={{paint=function(_, node, _, _, out, alpha)
        local medal = node.medal
        local icon = out:fit(texture.size(medal.icon))
        local tint = color.alpha(color.WHITE, alpha)
        if medal.done then
            gfx.image_striped(medal.icon, icon, 0, .1, 1, rgb(0xB9AA8E), tint)
        else gfx.image(medal.icon, icon, tint) end
    end}}}}
end

-- The portrait is cut to the face as a 16-gon with gfx.image_poly, never with
-- gfx.sdf_mask: the renderer has one mask, and a medallion drawn inside a
-- masked scene (the town under the dive wipe) must not replace or clear it.
-- The polygon's sides touch the face's circle; its corners, 2% further out,
-- hide under the brass lip drawn over the cut.
local CUT_SIDES = 16
local function portrait_cut(image, dst, face, tint)
    local size = texture.size(image)
    local c, r = face:center(), face.w / 2 / math.cos(math.pi / CUT_SIDES)
    local pts, uvs = {}, {}
    for i = 1, CUT_SIDES do
        local p = c + vec2.polar(2 * math.pi * (i - .5) / CUT_SIDES, r)
        pts[i] = p
        uvs[i] = vec2((p.x - dst.x) / dst.w * size.w, (p.y - dst.y) / dst.h * size.h)
    end
    gfx.image_poly(image, pts, uvs, tint)
end

-- A character's portrait in the round buttons' brass rim: the picture fills
-- the enamel face, its top at the face's top so the head sits in the upper
-- half and the shoulders meet the rim. `options` may give a `state` (normal,
-- hover, pressed or disabled, as for the buttons: pressed sinks, disabled
-- turns the rim pewter and fades the picture) and a `progress` from 0 to 1,
-- drawn as a gauge across the bottom; `alpha` (0 to 1) fades it with a popup.
function B.medallion(box, image, options)
    options = options or {}
    local side = math.min(box.w, box.h)
    if side <= 0 then return end
    local state = options.state or "normal"
    local disabled, pressed = state == "disabled", state == "pressed"
    local rim = disabled and pewter or brass
    local face = faces[state == "hover" and "hover" or "normal"]
    local alpha = options.alpha or 1
    local function ink(c) return alpha < 1 and color.alpha(c, alpha) or c end
    local center = box:center()
    local body = rect.centered(center, size2(side, side))
    local depth, bezel, well, enamel = frame_boxes(body, pressed)
    gfx.circle(center + vec2(0, depth), side * .5, ink(shade))
    gfx.circle(center, side * .5, ink(rim.edge))
    gfx.round_rect_grad(bezel, bezel.w / 2, ink(rim.top), ink(rim.bottom))
    gfx.circle(well:center(), well.w / 2, ink(rim.lip))
    gfx.round_rect_grad(enamel, enamel.w / 2, ink(face.top), ink(face.bottom))
    local size = image and texture.size(image)
    if size and size.w > 0 and size.h > 0 then
        local w = enamel.w * 1.08
        local h = math.max(enamel.h, w * size.h / size.w)
        portrait_cut(image, rect(enamel:center().x - w / 2, enamel.y - enamel.h * .02, w, h), enamel,
            color(255, 255, 255, math.floor((disabled and 140 or 255) * alpha + .5)))
        local lip = (well.w - enamel.w) / 2
        gfx.ring(enamel:center(), enamel.w / 2 + lip / 2, lip, ink(rim.lip))
    end
    if options.progress then progress_gauge(center, side, options.progress) end
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
