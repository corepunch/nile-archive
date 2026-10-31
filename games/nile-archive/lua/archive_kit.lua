-- archive_kit.lua — Nile Archive's look: June's Journey's UI in the
-- archive's colours. Deep teal panels inside a bevelled gold rim with a
-- filigree line and corner studs, parchment cards, red ribbon headers, glossy
-- pill buttons with a lip, round gold-ringed icon buttons with a caption,
-- dark currency capsules with a green "+", and icons drawn as simple shapes
-- in cream with a dark under-stroke, so no icon art is needed.
--
-- Fonts, text styles, the theme, frames and pill buttons are data in
-- archive_skin.lua; K.styles is filled from it by K.setup_theme once the
-- fonts load. This file keeps the drawn icons, ribbons and ornaments.
local hex, rgba = color.hex, color
local skin = require("archive_skin")

local K = {skin = skin}

local WHITE = color.WHITE
local GOLD_HI, GOLD, GOLD_LO, GOLD_SEAM = skin:color("gold_hi"), skin:color("gold"), skin:color("gold_lo"), skin:color("gold_seam")
local TEAL_HI, TEAL_LO = skin:color("teal_hi"), skin:color("teal_lo")
local PARCH_HI, PARCH_LO = skin:color("parch_hi"), skin:color("parch_lo")
local INK, INK_SOFT = skin:color("ink_brown"), skin:color("ink_soft")
local ICON, ICON_DARK = hex(0xFFF4D8), rgba(20, 40, 44, 200)
K.WHITE = WHITE
K.GOLD_HI, K.GOLD, K.GOLD_LO, K.GOLD_SEAM = GOLD_HI, GOLD, GOLD_LO, GOLD_SEAM
K.TEAL_HI, K.TEAL_LO = TEAL_HI, TEAL_LO
K.PARCH_HI, K.PARCH_LO = PARCH_HI, PARCH_LO
K.INK, K.INK_SOFT = INK, INK_SOFT

local S = {}
K.styles = S

------------------------------------------------------------------- panels

-- An ornate panel: teal (or parchment) inside a bevelled gold rim, drawn by
-- the skin's panel. Returns the area inside the rim.
function K.frame(r, parchment, radius)
    skin:paint("panel", r, nil, {role = parchment and "parchment" or nil, radius = radius or 20})
    ui.block(r)
    return r:inflate(-5)
end

-- A red ribbon with notched tails, centred on `c`.
function K.ribbon(c, w, label)
    local h = 48
    local body = rect.anchor(c, size2(w, h), vec2(.5, .5))
    for side = -1, 1, 2 do
        local x0 = side < 0 and body.x + 22 or body:max().x - 22
        local x1 = x0 + side * 58
        local y0, y1 = body.y + 12, body:max().y + 12
        local mid, notch = (y0 + y1) / 2, x1 - side * 16
        local dark = hex(0x6B1D16)
        gfx.poly({vec2(x0, y0), vec2(x1, y0), vec2(notch, mid), vec2(x0, mid)}, dark)
        gfx.poly({vec2(x0, mid), vec2(notch, mid), vec2(x1, y1), vec2(x0, y1)}, dark)
        local fold = side < 0 and body.x + 22 or body:max().x - 22
        gfx.poly({vec2(fold, body:max().y), vec2(fold, y1), vec2(fold - side * 22, body:max().y)}, hex(0x3E0F0B))
    end
    gfx.shadow(body:offset(vec2(0, 5)), 8, 10, rgba(0, 0, 0, 90))
    gfx.round_rect_grad(body:inflate(3), 8, GOLD_HI, GOLD_LO)
    gfx.round_rect_grad(body, 6, hex(0xD25D47), hex(0x922F23))
    gfx.round_rect(rect(body.x + 8, body.y + 4, body.w - 16, h * .32), 5, rgba(255, 255, 255, 38))
    text.fit(S.ribbon, body:inflate2(vec2(-24, -4)), vec2(.5, .52), label)
end

-- A glossy pill button with a darker lip; kind: green, blue, red, off (disabled).
function K.button(r, label, kind)
    kind = kind or "green"
    return skin:draw_button(r, label, {kind = "pill", role = kind ~= "green" and kind ~= "off" and kind or nil,
                                       enabled = kind ~= "off", radius = math.min(16, r.h * .5)})
end

------------------------------------------------------------------- icons

function K.icon_house(p, s, col)
    col = col or ICON
    for pass = 1, 2 do
        local c, o = pass == 1 and ICON_DARK or col, pass == 1 and vec2(0, 2) or vec2(0, 0)
        gfx.poly({p + o + vec2(-s * .95, -s * .05), p + o + vec2(0, -s * .9), p + o + vec2(s * .95, -s * .05)}, c)
        gfx.rect(rect(p.x - s * .6 + o.x, p.y - s * .12 + o.y, s * 1.2, s * .85), c)
    end
    gfx.round_rect(rect(p.x - s * .17, p.y + s * .25, s * .34, s * .48), 3, hex(0x7A5222))
end

function K.icon_glass(p, s)
    for pass = 1, 2 do
        local c, o = pass == 1 and ICON_DARK or ICON, pass == 1 and vec2(0, 2) or vec2(0, 0)
        local q = p + o + vec2(-s * .15, -s * .15)
        gfx.line(q + vec2(s * .45, s * .45), q + vec2(s * .95, s * .95), s * .3, c)
        gfx.ring(q, s * .55, s * .2, c)
    end
    gfx.glow(p + vec2(-s * .2, -s * .22), s * .4, rgba(170, 230, 255, 160), rgba(170, 230, 255, 0))
end

function K.icon_people(p, s)
    for pass = 1, 2 do
        local o = pass == 1 and vec2(0, 2) or vec2(0, 0)
        local back, front = pass == 1 and ICON_DARK or hex(0xD9C8A0), pass == 1 and ICON_DARK or ICON
        gfx.circle(p + o + vec2(-s * .38, -s * .42), s * .3, back)
        gfx.round_rect(rect(p.x - s * .85 + o.x, p.y - s * .08 + o.y, s * .9, s * .8), s * .38, back)
        gfx.circle(p + o + vec2(s * .2, -s * .3), s * .34, front)
        gfx.round_rect(rect(p.x - s * .35 + o.x, p.y + s * .08 + o.y, s * 1.1, s * .82), s * .42, front)
    end
end

function K.icon_boat(p, s)
    for pass = 1, 2 do
        local c, o = pass == 1 and ICON_DARK or ICON, pass == 1 and vec2(0, 2) or vec2(0, 0)
        gfx.poly({p + o + vec2(-s, s * .25), p + o + vec2(s, s * .25), p + o + vec2(s * .6, s * .8), p + o + vec2(-s * .6, s * .8)}, c)
        gfx.poly({p + o + vec2(-s * .05, -s * .95), p + o + vec2(s * .7, s * .12), p + o + vec2(-s * .05, s * .12)}, c)
        gfx.poly({p + o + vec2(-s * .18, -s * .6), p + o + vec2(-s * .18, s * .12), p + o + vec2(-s * .7, s * .12)}, c)
    end
end

function K.icon_bulb(p, s, lit)
    local glass = lit and hex(0xFFE27A) or hex(0xB9B4A2)
    if lit then gfx.glow(p - vec2(0, s * .2), s * 1.3, rgba(255, 220, 110, 120), rgba(255, 220, 110, 0)) end
    gfx.circle(p + vec2(0, 2 - s * .2), s * .62, ICON_DARK)
    gfx.circle(p - vec2(0, s * .2), s * .62, glass)
    gfx.poly({p + vec2(-s * .42, s * .1), p + vec2(s * .42, s * .1), p + vec2(s * .3, s * .5), p + vec2(-s * .3, s * .5)}, glass)
    gfx.round_rect(rect(p.x - s * .3, p.y + s * .48, s * .6, s * .38), 3, hex(0x8B8F92))
    gfx.line(p + vec2(-s * .3, s * .62), p + vec2(s * .3, s * .62), 1.5, hex(0x5C6064))
    gfx.circle(p + vec2(-s * .2, -s * .4), s * .14, rgba(255, 255, 255, 170))
end

function K.icon_close(p, s)
    gfx.line(p + vec2(-s, -s + 2), p + vec2(s, s + 2), s * .5, ICON_DARK)
    gfx.line(p + vec2(s, -s + 2), p + vec2(-s, s + 2), s * .5, ICON_DARK)
    gfx.line(p + vec2(-s, -s), p + vec2(s, s), s * .5, ICON)
    gfx.line(p + vec2(s, -s), p + vec2(-s, s), s * .5, ICON)
end

function K.icon_lock(p, s, col)
    col = col or ICON
    gfx.ring(p - vec2(0, s * .25), s * .45, s * .18, col)
    gfx.round_rect(rect(p.x - s * .62, p.y - s * .2, s * 1.24, s * .95), 4, col)
    gfx.circle(p + vec2(0, s * .2), s * .14, INK)
end

local function plus_badge(p, r)
    gfx.circle(p + vec2(0, 2), r, hex(0x1F5316))
    gfx.circle(p, r, hex(0x2A6A1E))
    gfx.circle(p - vec2(0, 1), r - 2, hex(0x5DBA3F))
    gfx.glow(p - vec2(0, r * .35), r * .8, rgba(255, 255, 255, 70), rgba(255, 255, 255, 0))
    gfx.rect(rect.centered(p, size2(r * 1.1, r * .32)), WHITE)
    gfx.rect(rect.centered(p, size2(r * .32, r * 1.1)), WHITE)
end

function K.notify_dot(p)
    gfx.circle(p + vec2(0, 1.5), 10, rgba(0, 0, 0, 90))
    gfx.circle(p, 10, hex(0xFFF1D2))
    gfx.circle(p, 8, hex(0xD9432F))
    text.draw(S.badge, p, vec2(.5, .52), "!")
end

----------------------------------------------------------------- controls

-- A round gold-ringed button with an icon and an optional caption under it.
function K.round_button(c, radius, icon, caption, green)
    local hit = rect.centered(c + vec2(0, caption and 10 or 0), size2(radius * 2 + 8, radius * 2 + (caption and 28 or 8)))
    local st = ui.hit(hit, 0)
    local p = st.held and c + vec2(0, 2) or c
    gfx.circle(c + vec2(0, 6), radius + 4, rgba(0, 0, 0, 80))
    gfx.circle(p, radius + 4, GOLD_SEAM)
    gfx.circle(p, radius + 3, GOLD_LO)
    gfx.circle(p - vec2(0, 1.5), radius + 1.5, GOLD)
    gfx.circle(p, radius - 2, GOLD_SEAM)
    local hi, lo = green and hex(0x7CCB52) or TEAL_HI:shade(1.25), green and hex(0x2E7D22) or TEAL_LO
    gfx.circle(p, radius - 3, lo)
    gfx.glow(p - vec2(0, radius * .35), radius * 1.05, hi, hi:alpha(0))
    if st.hot then gfx.circle(p, radius - 3, rgba(255, 255, 255, 18)) end
    icon(p, radius * .52)
    if caption then
        local s = S.caption
        local w = text.measure(s, caption).w + 18
        local tag = rect.anchor(p + vec2(0, radius + 2), size2(w, 22), vec2(.5, .5))
        gfx.round_rect(tag, 11, rgba(10, 30, 34, 225))
        gfx.round_rect_line(tag, 11, 1, rgba(233, 199, 123, 150))
        text.draw(s, tag:center(), vec2(.5, .52), caption)
    end
    return st.clicked
end

-- A dark capsule with a currency icon overlapping its left end and a green "+".
function K.capsule(r, icon, value)
    local st = ui.hit(r, 0)
    gfx.shadow(r:offset(vec2(0, 3)), r.h * .5, 6, rgba(0, 0, 0, 90))
    gfx.round_rect(r, r.h * .5, rgba(9, 28, 32, 222))
    gfx.round_rect_line(r, r.h * .5, 1.6, rgba(233, 199, 123, 190))
    local ic = rect.centered(vec2(r.x + 6, r:center().y), size2(r.h + 14, r.h + 14))
    gfx.image(icon, ic, WHITE)
    text.fit(S.number, rect(r.x + r.h * .5 + 18, r.y, r.w - r.h * 1.5 - 22, r.h), vec2(.5, .5), value)
    plus_badge(vec2(r:max().x - r.h * .5, r:center().y), r.h * .5 - 3)
    return st.clicked
end

-- An icon followed by a figure, anchored at `pos` by `pivot`.
function K.amount(pos, pivot, icon, str, s)
    local icon_size = s.size * 1.35
    local w = icon_size + 6 + text.measure(s, str).w
    local box = rect.anchor(pos, size2(w, icon_size), pivot)
    gfx.image(icon, box:left(icon_size), WHITE)
    text.draw(s, box:offset(vec2(icon_size + 6, 0)):point(vec2(0, .5)), vec2(0, .5), str)
    return box
end

-- Three stars, the middle one raised; with `t` the earned ones pop in one by one.
function K.star_row(c, size, earned, t)
    for k = 1, 3 do
        local big = k == 2
        local r = size * (big and 1.2 or 1)
        local p = c + vec2((k - 2) * size * 2.3, big and -size * .35 or 0)
        local pop = t and ease.out_back(num.saturate((t - .25 - k * .18) * 3)) or 1
        gfx.star(p + vec2(0, 3), r * 1.08, .48, 5, -math.pi / 2, rgba(0, 0, 0, 90))
        gfx.star(p, r * 1.08, .48, 5, -math.pi / 2, GOLD_SEAM)
        gfx.star(p, r, .48, 5, -math.pi / 2, hex(0x2A3F44))
        if k <= earned and pop > 0 then
            gfx.star(p, r * pop, .48, 5, -math.pi / 2, hex(0xF2B637))
            gfx.star(p - vec2(0, r * .12 * pop), r * .7 * pop, .48, 5, -math.pi / 2, hex(0xFFE37A))
        end
    end
end

-------------------------------------------------------------------- theme

-- Loads the fonts, fills K.styles and installs the engine's UI theme.
local STYLES = {"body", "eyebrow", "number", "tiny", "name", "badge", "caption", "button", "ribbon", "score",
                "card_title", "reward", "ink_body", "ink_small", "goal_eyebrow", "goal_title", "pill_text", "bonus",
                "multiplier", "float", "float_miss"}
function K.setup_theme()
    K.serif, K.sans, K.sans_bold = skin:font("serif"), skin:font("sans"), skin:font("sans_bold")
    for _, name in ipairs(STYLES) do S[name] = skin:text(name) end
    ui.set_theme(skin.theme)
end

-- How the engine stages the cast's dialogue; needs the fonts from setup_theme.
function K.dialogue_style()
    return story_style{
        text = style{font = K.sans, size = 22, fill = hex(0x203C36)},
        name = style{font = K.sans_bold, size = 17, fill = hex(0xFFF6E0)},
        bubble = hex(0xFBF1DA), edge = hex(0x9C7A3C), dim = rgba(6, 28, 33, 120),
        portrait_height = .64, skip = "Пропустить",
    }
end

return K
