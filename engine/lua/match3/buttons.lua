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

local function paint_funding_tag(skin, out, alpha)
    local side = math.min(out.w, out.h)
    local width, height = side * .81, side * .22
    local tag = rect.centered(out:center() + vec2(0, side * .37), size2(width, height))
    local radius = height * .38
    gfx.shadow(tag:offset(vec2(0, height * .1)), radius, height * .15, color.alpha(rgb(0x2D180C), alpha * .65))
    gfx.round_rect(tag, radius, color.alpha(rgb(0xE2B978), alpha))
    gfx.round_rect(tag:inflate(-height * .06), radius - height * .06, color.alpha(rgb(0x723620), alpha))
    text.fit(skin:text("funding_tag", height * .64):faded(1 - alpha), tag:inflate2(vec2(-width * .06, 0)),
        vec2(.5, .5), "NEED FUNDS")
end

local function button_state(st)
    if st.disabled then return "disabled" end
    if st.held then return "pressed" end
    if st.hot then return "hover" end
    return "normal"
end

-- Atlas rows follow the four projects in each advent or expedition epoch.
function B.project(unlocks)
    local thumbnails
    return {
        normal = {layers = {{paint = function(_, node, st, skin, out, alpha)
            local project = node.project
            if not project then return end
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
            local state = button_state(st)
            local built = project.state == "built"
            B.medallion(out:inflate(-math.min(out.w, out.h) * .02), thumbnails[project.key], {
                state = state, alpha = alpha, crop = true,
                tint = built and rgb(0xA6A6A6) or color.WHITE,
            })
            if state == "pressed" then out = out:offset(vec2(0, out.h * .023)) end
            local tick = skin.images.tick
            if built and tick then
                local side = math.min(out.w, out.h) * .66
                local dst = rect.centered(out:center(), size2(side, side)):fit(texture.size(tick))
                gfx.image(tick, dst:offset(vec2(0, side * .06)), color.alpha(rgb(0x24160B), alpha * .7))
                gfx.image(tick, dst, color.alpha(color.WHITE, alpha))
            elseif project.state == "funding" then
                paint_funding_tag(skin, out, alpha)
            end
        end}}},
        pressed = {offset = {0, 0}},
    }
end

-- Shared painted face. The level number sits inside the widest part of the triangle.
local play_states = {"normal", "hover", "pressed", "disabled"}
function B.project_play()
    local frames
    return {
        normal = {layers = {{paint = function(_, node, st, skin, out, alpha)
            if not frames then
                local sheet = texture.load_engine("data/board/town-play.png")
                assert(sheet.tex, "missing town Play atlas")
                local cell = sheet.w / 2
                frames = {}
                for i, state in ipairs(play_states) do
                    local x, y = (i - 1) % 2 * cell, ((i - 1) // 2) * cell
                    frames[state] = texture.region(sheet, rect(x, y, cell, cell))
                end
            end
            local state = button_state(st)
            local side = math.min(out.w, out.h)
            local depth = state == "pressed" and side * .02 or 0
            local artwork = rect.centered(out:center() + vec2(0, depth), size2.splat(side * 1.05))
            local function ink(c) return color.alpha(c, alpha) end
            gfx.image(frames[state], artwork, ink(color.WHITE))
            local center = artwork:point(vec2(.43, .48))
            if node.level then
                local number = rect.centered(center, size2(side * .42, side * .44))
                text.fit(skin:text("cream", side * .36):faded(1 - alpha), number, vec2(.5, .5), tostring(node.level))
            elseif skin.images.tick then
                local icon = skin.images.tick
                local dst = rect.centered(center, size2(side * .42, side * .42)):fit(texture.size(icon))
                gfx.image(icon, dst, ink(color.WHITE))
            end
        end}}},
        pressed = {offset = {0, 0}},
    }
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
-- Square project paintings set `crop` for a centred cut and can supply a `tint`.
function B.medallion(box, image, options)
    options = options or {}
    local side = math.min(box.w, box.h)
    if side <= 0 then return end
    local state = options.state or "normal"
    local disabled, pressed = state == "disabled", state == "pressed"
    local rim = disabled and pewter or brass
    local face = faces[state == "hover" and "hover" or "normal"]
    local top, bottom = rim.top, rim.bottom
    if options.crop and state == "hover" then top, bottom = rgb(0xFFFCED), rgb(0xD69951) end
    local alpha = options.alpha or 1
    local function ink(c) return alpha < 1 and color.alpha(c, alpha) or c end
    local center = box:center()
    local body = rect.centered(center, size2(side, side))
    local depth, bezel, well, enamel = frame_boxes(body, pressed)
    gfx.circle(center + vec2(0, depth), side * .5, ink(shade))
    gfx.circle(center, side * .5, ink(rim.edge))
    gfx.round_rect_grad(bezel, bezel.w / 2, ink(top), ink(bottom))
    gfx.circle(well:center(), well.w / 2, ink(rim.lip))
    gfx.round_rect_grad(enamel, enamel.w / 2, ink(face.top), ink(face.bottom))
    local size = image and texture.size(image)
    if size and size.w > 0 and size.h > 0 then
        local w = enamel.w * 1.08
        local h = math.max(enamel.h, w * size.h / size.w)
        local dst = rect.centered(enamel:center(), size2(w, h))
        if not options.crop then dst = rect(dst.x, enamel.y - enamel.h * .02, w, h) end
        local tint = color.alpha(options.tint or color.WHITE, alpha * (disabled and .55 or 1))
        portrait_cut(image, dst, enamel, tint)
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
