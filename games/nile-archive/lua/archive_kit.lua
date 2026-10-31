-- archive_kit.lua — Nile Archive's look: June's Journey's UI in the
-- archive's colours. Deep teal panels inside a bevelled gold rim with a
-- filigree line and corner studs, parchment cards, red ribbon headers, glossy
-- pill buttons with a lip, round gold-ringed icon buttons with a caption,
-- dark currency capsules with a green "+", and icons drawn as simple shapes
-- in cream with a dark under-stroke, so no icon art is needed.
--
-- The text styles live in K.styles, filled by K.setup_theme once the fonts
-- are loaded; the widgets read them at draw time.
local hex, rgba = color.hex, color

local K = {}

local WHITE = color.WHITE
local GOLD_HI, GOLD, GOLD_LO, GOLD_SEAM = hex(0xF8E3A3), hex(0xDDB362), hex(0x93682A), hex(0x5E3F14)
local TEAL_HI, TEAL_LO = hex(0x22545C), hex(0x0F2E36)
local PARCH_HI, PARCH_LO = hex(0xFCF3DD), hex(0xEBD6A8)
local INK, INK_SOFT = hex(0x3A2914), hex(0x6B5435)
local ICON, ICON_DARK = hex(0xFFF4D8), rgba(20, 40, 44, 200)
K.WHITE = WHITE
K.GOLD_HI, K.GOLD, K.GOLD_LO, K.GOLD_SEAM = GOLD_HI, GOLD, GOLD_LO, GOLD_SEAM
K.TEAL_HI, K.TEAL_LO = TEAL_HI, TEAL_LO
K.PARCH_HI, K.PARCH_LO = PARCH_HI, PARCH_LO
K.INK, K.INK_SOFT = INK, INK_SOFT

local BUTTONS = {
    green = {hex(0xA8E46C), hex(0x4AA536), hex(0x2A6A1E)},
    blue = {hex(0x67C0D6), hex(0x2D7E97), hex(0x184A5B)},
    red = {hex(0xE57A5E), hex(0xB13F2C), hex(0x6E2017)},
    off = {hex(0x9AA3A0), hex(0x66706E), hex(0x3B4443)},
}

local S = {}
K.styles = S

------------------------------------------------------------------- panels

local function stud(p, r)
    gfx.ngon(p, r + 1.5, 4, 0, GOLD_SEAM)
    gfx.ngon(p, r, 4, 0, GOLD)
    gfx.ngon(p - vec2(0, r * .25), r * .45, 4, 0, GOLD_HI)
end

-- An ornate panel: teal (or parchment) inside a bevelled gold rim.
function K.frame(r, parchment, radius)
    radius = radius or 20
    gfx.shadow(r:offset(vec2(0, 10)), radius + 2, 28, rgba(0, 0, 0, 130))
    gfx.round_rect_grad(r, radius, GOLD_HI, GOLD_LO)
    gfx.round_rect(r:inflate(-3), radius - 3, GOLD_SEAM)
    local inner = r:inflate(-5)
    if parchment then gfx.round_rect_grad(inner, radius - 5, PARCH_HI, PARCH_LO)
    else gfx.round_rect_grad(inner, radius - 5, TEAL_HI, TEAL_LO) end
    local line = inner:inflate(-7)
    gfx.round_rect_line(line, math.max(4, radius - 10), 1.2, parchment and rgba(176, 132, 60, 150) or rgba(233, 199, 123, 105))
    if r.w > 120 and r.h > 90 then
        for _, a in ipairs({vec2(0, 0), vec2(1, 0), vec2(0, 1), vec2(1, 1)}) do stud(line:point(a), 5) end
    end
    ui.block(r)
    return inner
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

-- A glossy pill button with a darker lip; kind: green, blue, red, off.
function K.button(r, label, kind)
    kind = kind or "green"
    local c = BUTTONS[kind]
    local st = ui.hit(r, kind == "off" and ui.DISABLED or 0)
    local rad = math.min(16, r.h * .5)
    local b = st.held and r:offset(vec2(0, 3)) or r
    if not st.held then gfx.shadow(r:offset(vec2(0, 6)), rad + 2, 10, rgba(0, 0, 0, 100)) end
    gfx.round_rect(r:offset(vec2(0, 4)):inflate(2), rad + 2, c[3])          -- the lip
    gfx.round_rect(b:inflate(2), rad + 2, c[3])
    gfx.round_rect_grad(b, rad, st.hot and c[1]:shade(1.06) or c[1], c[2])
    gfx.round_rect(rect(b.x + 7, b.y + 3, b.w - 14, b.h * .4), rad * .7, rgba(255, 255, 255, 60))
    text.fit(S.button:outlined(2, c[3]), b:inflate2(vec2(-14, -4)), vec2(.5, .52), label)
    return st.clicked
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
function K.setup_theme()
    K.serif = font.load("fonts/Philosopher-Bold.ttf")
    K.sans = font.load("fonts/PT_Sans-Web-Regular.ttf")
    K.sans_bold = font.load("fonts/PT_Sans-Web-Bold.ttf")
    font.set_fallback(K.serif, K.sans_bold)
    local serif, sans, sans_bold = K.serif, K.sans, K.sans_bold

    local cream, ink = hex(0xF4E8CA), hex(0x0B2426)
    local base = style{font = sans, size = 17, fill = cream, shadow = rgba(0, 0, 0, 90), shadow_offset = vec2(0, 1), shadow_blur = 1}
    S.body = base
    S.eyebrow = style{font = sans_bold, size = 12, fill = hex(0xE9D7A8), tracking = 1.6, shadow = rgba(0, 0, 0, 120), shadow_offset = vec2(0, 1), shadow_blur = 1}
    S.number = style{font = sans_bold, size = 20, fill = cream, outline = ink, outline_width = 1}
    S.tiny = style{font = sans_bold, size = 11, fill = WHITE, outline = rgba(10, 40, 50, 220), outline_width = 1}
    S.name = style{font = serif, size = 20, fill = cream, outline = ink, outline_width = 1.2}
    S.badge = style{font = sans_bold, size = 16, fill = WHITE, outline = hex(0x6B4410), outline_width = 1.6}
    S.caption = style{font = sans_bold, size = 13, fill = cream}
    S.button = style{font = sans_bold, size = 21, fill = WHITE, shadow = rgba(0, 0, 0, 80), shadow_offset = vec2(0, 2), shadow_blur = 1}
    S.ribbon = style{font = serif, size = 26}:grad(hex(0xFFF6DC), hex(0xF5D58E)):outlined(1.6, hex(0x5A150F)):shadowed(vec2(0, 2), 2, rgba(0, 0, 0, 120))
    S.score = style{font = serif, size = 30}:grad(hex(0xFFF3D1), hex(0xE2B46A)):outlined(1.4, ink):shadowed(vec2(0, 2), 3, rgba(0, 0, 0, 140))
    S.card_title = style{font = serif, size = 18, fill = INK}
    S.reward = style{font = serif, size = 28, fill = INK}
    S.ink_body = style{font = sans, size = 17, fill = INK}
    S.ink_small = style{font = sans, size = 14, fill = INK_SOFT}
    S.goal_eyebrow = style{font = sans_bold, size = 11, fill = hex(0x8A5A22), tracking = 1.4}
    S.goal_title = style{font = serif, size = 20, fill = INK}
    S.pill_text = style{font = sans_bold, size = 30, fill = WHITE, outline = rgba(40, 24, 10, 230), outline_width = 2,
                        shadow = rgba(0, 0, 0, 120), shadow_offset = vec2(0, 2), shadow_blur = 2}
    S.bonus = style{font = sans_bold, size = 22, fill = WHITE, outline = rgba(10, 50, 70, 220), outline_width = 1.6}
    S.multiplier = style{font = serif, size = 24}:grad(hex(0xF6C24A), hex(0xB8761C)):outlined(1.2, hex(0x5A3608))
    S.float = style{font = serif, size = 26}:grad(hex(0xFFF6DC), hex(0xF5C860)):outlined(1.6, hex(0x4A2A08))
    S.float_miss = style{font = serif, size = 22, fill = hex(0xFF8A70), outline = hex(0x3A0E08), outline_width = 1.4}

    ui.set_theme(ui_theme{
        text = base,
        small = S.eyebrow,
        title = style{font = serif, size = 30}:grad(hex(0xFFF3D1), hex(0xE2B46A)):outlined(1.4, ink):shadowed(vec2(0, 3), 4, rgba(0, 0, 0, 140)),
        button = style{font = sans_bold, size = 21}:grad(hex(0xFFF6DC), hex(0xF5D58E))
            :outlined(1, ink):shadowed(vec2(0, 1), 1, rgba(0, 0, 0, 120)),
        accent_text = style{font = sans_bold, size = 21}:grad(hex(0x203C36), ink)
            :shadowed(vec2(0, 1), 0, rgba(255, 246, 220, 150)),
        panel = hex(0x1D4442), panel2 = hex(0x183A39), border = rgba(167, 173, 117, 90),
        button_bg = hex(0x2A524F), button_bg2 = hex(0x1F4442), button_hot = hex(0x38615B),
        button_border = rgba(191, 166, 107, 110),
        accent = hex(0xF0CF8E), accent2 = hex(0xD8AE66), active = hex(0xE4C080),
        dim = rgba(6, 22, 26, 200), toast_bg = hex(0xF6E7C1), toast_text = INK, radius = 10,
    })
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
