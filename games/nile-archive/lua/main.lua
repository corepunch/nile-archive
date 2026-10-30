-- Nile Archive — hidden-object chapters feeding an island-restoration meta-game.
--
-- The whole interface (header, chapters, shop, dialogs) is drawn by the shared
-- engine; this file holds the content, the hidden-object rules and the screen
-- layout. The island itself is an engine city.
local hex, rgba = color.hex, color

------------------------------------------------------------------- content

local COINS, INFLUENCE = 1, 2
local ITEMS, ZONES = 8, 4

local scenes = {
    {title = "Двор хранителя", teaser = "На столах двора остались вещи отца. Начните с них.",
     clue = {{"nefra", "На свитке — печать семейной мастерской. Отец успел спрятать архив до наводнения."}},
     background = "scene0.png", gate = 0,
     names = {"Анх", "Веер", "Гранат", "Скарабей", "Ключ", "Кошка", "Свиток", "Перо"},
     at = {vec2(133, 133), vec2(268, 422), vec2(491, 316), vec2(574, 660), vec2(1150, 368), vec2(965, 575), vec2(195, 598), vec2(1094, 170)},
     radius = {vec2(27, 55), vec2(82, 42), vec2(30, 30), vec2(40, 24), vec2(45, 20), vec2(95, 70), vec2(90, 42), vec2(42, 55)}},
    {title = "Библиотека писца", teaser = "В библиотеке спрятан второй след. Для доступа нужно 20 влияния.",
     clue = {{"nefra", "На обороте печати проступил план острова. След ведёт к старому храму у восточного берега."}},
     background = "scene1.png", gate = 20,
     names = {"Анх", "Веер", "Гранат", "Скарабей", "Ключ", "Кошка", "Карта", "Перо"},
     at = {vec2(180, 78), vec2(1023, 617), vec2(115, 430), vec2(513, 163), vec2(450, 617), vec2(1063, 453), vec2(273, 500), vec2(1070, 226)},
     radius = {vec2(25, 52), vec2(115, 55), vec2(35, 35), vec2(30, 42), vec2(45, 22), vec2(90, 70), vec2(195, 55), vec2(45, 55)}},
    {title = "Храм на закате", teaser = "Соберите последнюю цепочку улик. Нужно 50 влияния.",
     clue = {{"nefra", "Последняя записка отца раскрыта."},
             {"horem", "Книги спрятаны под храмом. Восстанови остров — и библиотека снова откроется.", story.THOUGHT}},
     background = "scene2.png", gate = 50,
     names = {"Анх", "Веер", "Яблоко", "Скарабей", "Ключ", "Кошка", "Свиток", "Перо"},
     at = {vec2(61, 109), vec2(1027, 530), vec2(120, 514), vec2(527, 334), vec2(1109, 114), vec2(656, 574), vec2(234, 98), vec2(379, 634)},
     radius = {vec2(30, 72), vec2(95, 50), vec2(35, 35), vec2(42, 24), vec2(25, 62), vec2(105, 58), vec2(70, 28), vec2(95, 30)}},
}
local SCENES = #scenes

-- Each sprite's footprint is measured in its own pixels (docs/BUILDINGS.md):
-- the ground centre it stands on (pivot), the width from its left corner to
-- its right one, and its size in whole TILE tiles.
local TILE = size2(24, 12)   -- half extents: a tile is 48 x 24 world units

local function building(title, w, h, pivot, base, coins, influence, path)
    return {name = title, sprite_path = path, size = size2(w, h), pivot = pivot, base_width = base, cost = purse(coins), reward = purse(0, influence)}
end

local buildings = {
    building("Дом садовника", 2, 2, vec2(81, 200), 150, 70, 10, "buildings/0.png"),
    building("Храм Исиды", 3, 2, vec2(86, 198), 171, 160, 30, "buildings/1.png"),
    building("Архив", 3, 2, vec2(76, 187), 151, 130, 25, "buildings/2.png"),
    building("Фонтан", 2, 2, vec2(80, 192), 151, 60, 10, "buildings/3.png"),
    building("Мастерская", 2, 2, vec2(76, 187), 143, 100, 15, "buildings/4.png"),
}

local cast = {
    {id = "nefra", name = "Нефра", role = "Дочь хранителя · ищет отца и архив", portrait_path = "characters/nefra.png",
     color = rgba(46, 140, 134), mouth = vec2(.48, .23)},
    {id = "horem", name = "Хорем", role = "Пропавший хранитель · оставил подсказки", portrait_path = "characters/horem.png",
     color = rgba(185, 134, 46), right = true, mouth = vec2(.42, .21)},
    {id = "merit", name = "Мерит", role = "Лодочница · проводник будущих глав", portrait_path = "characters/merit.png",
     color = rgba(181, 84, 58), right = true, mouth = vec2(.40, .22)},
}

-- First launch.
local intro = {
    {"nefra", "Отец исчез после наводнения, а библиотека опустела."},
    {"nefra", "Но он успел спрятать книги и оставил подсказки. Я восстановлю наше поместье — и найду архив."},
}
local merit_shore = {"merit", "Открыт новый берег! Перетащите остров влево, чтобы его осмотреть.", story.SHOUT}

local scene_reward = purse(240, 20)


--------------------------------------------------------------------- state

local MODAL_NONE, MODAL_WIN, MODAL_CAST, MODAL_CHAPTERS, MODAL_PAUSE = 0, 1, 2, 3, 4

-- Hidden-object scoring, after June's Journey: each find scores more while a
-- combo is alive, a stray tap costs points, and the stars come from the time.
local FIND_POINTS, MISS_POINTS = 300, 60
local COMBO_WINDOW, COMBO_MAX = 5, 5
local HINT_RECHARGE = 20
local SLOTS = 3                   -- names on show at once, as in June's Journey
local STAR_TIMES = {75, 150}      -- seconds for three and two stars

local G = {
    wallet = purse(),
    wins = {0, 0, 0},
    stars = {0, 0, 0},            -- best stars per chapter
    island = nil,                 -- the engine city
    scene = nil,                  -- 1-based chapter, nil = island
    found = {},                   -- found[i] = time the item was found
    hint = nil, hint_ready = 0,
    slots = {}, slot_time = {},   -- the item bar: item per slot, when it arrived
    score = 0, combo = 0, combo_left = 0, clock = 0, result = nil,
    cam = nil,                    -- hidden-object camera
    focus = vec2(), focus_time = 0,
    modal = MODAL_NONE, modal_time = 0,
    tray = false,                 -- the building tray is open
    spots = {},                   -- where key controls were drawn this frame (smoke test)
    backgrounds = {}, coin = nil, influence = nil,
    serif = nil, sans = nil, sans_bold = nil,
    theme = nil, eyebrow = nil, heading = nil, body = nil, muted = nil, number = nil,
}

--------------------------------------------------------------- the island

-- Approximate land outline of island.png: an ellipse minus the pond.
local function island_buildable(c, p)
    if p.y < 400 or p.y > 1170 then return false end
    if (p - vec2(1230, 800)):ellipse(vec2(760, 530)) > 1 then return false end
    return not rect(1030, 920, 290, 180):contains(p)
end

local function island_setup()
    local c = city.new()
    c.defs = buildings
    c.tile = TILE
    c.clearance = size2(1, 1)   -- half a tile of ground around every base
    c.spacing = 120
    c.movable = true
    c.buildable = island_buildable
    local zones = {{area = rect(580, 200, 600, 1050)}}
    for z = 1, ZONES - 1 do zones[z + 1] = {area = rect(800 + z * 380, 200, 380, 1050), cost = purse(z * 180)} end
    c.zones = zones
    c.cam = camera{center = vec2(900, 650), zoom = .8, min_zoom = .35, max_zoom = 2, cover = true}
    c:init("island.png")
    G.island = c
    buildings = c.defs   -- with the sprites loaded
end

local function new_game()
    G.wallet = purse(260, 10)
    G.wins = {0, 0, 0}
    G.island.count = 0
    G.island.open = 1
    G.island:add(G.island:snap(vec2(850, 650), 0), 0, 0)
end


local function serialize(s)
    s:int("version", 2)
    G.wallet[COINS] = s:int("coins", G.wallet[COINS])
    G.wallet[INFLUENCE] = s:int("influence", G.wallet[INFLUENCE])
    G.wins = s:ints("wins", G.wins)
    G.stars = s:ints("stars", G.stars)
    G.island:serialize(s)
    story.serialize(s)
end

local function save_progress() save.write("progress", serialize) end

-- Progress of the old HTML version lived in localStorage["nile-v1"] as JSON.
local function legacy_progress()
    local json = app.web_storage("nile-v1")
    if not json then return end
    local function num(key) return tonumber(json:match('"' .. key .. '"%s*:%s*(-?%d+)')) or 0 end
    local wins = json:match('"wins"%s*:%s*%[([^%]]*)%]') or "0,0,0"
    local t = ("coins=%d\ninfluence=%d\nwins=%s\ncity.zones=%d\n"):format(num("coins"), num("prestige"), wins:gsub(",", " "), num("zones"))
    local n = 0
    for x, y, kind in (json:match('"buildings"%s*:%s*%[(.*)%]') or ""):gmatch("%[%s*(-?[%d.]+)%s*,%s*(-?[%d.]+)%s*,%s*(-?%d+)%s*%]") do
        t = t .. ("city.%d.pos=%s %s\ncity.%d.type=%s\n"):format(n, x, y, n, kind)
        n = n + 1
    end
    save.inject("progress", t .. ("city.count=%d\n"):format(n))
end


---------------------------------------------------------- hidden objects

local function found_count()
    local n = 0
    for i = 1, ITEMS do if G.found[i] then n = n + 1 end end
    return n
end

local function in_slots(i)
    for k = 1, SLOTS do if G.slots[k] == i then return true end end
    return false
end

-- Fill empty slots (and slots whose item was found a moment ago) from the list.
local function refill_slots(now, linger)
    for k = 1, SLOTS do
        local i = G.slots[k]
        if not i or (G.found[i] and now - G.found[i] > linger) then
            G.slots[k] = nil
            for j = 1, ITEMS do
                if not G.found[j] and not in_slots(j) then
                    G.slots[k], G.slot_time[k] = j, now
                    break
                end
            end
        end
    end
end

local function open_scene(i)
    G.scene = i
    G.found = {}
    G.hint, G.hint_ready = nil, 0
    G.slots, G.slot_time = {}, {}
    G.score, G.combo, G.combo_left, G.clock, G.result = 0, 0, 0, 0, nil
    G.island.selected = -1
    G.tray = false
    G.modal = MODAL_NONE
    G.cam = camera{center = vec2(600, 400), zoom = 0, world = size2(1200, 800), cover = true}
    refill_slots(app.time(), 0)
    for k = 1, SLOTS do G.slot_time[k] = app.time() - 10 end   -- the opening list is simply there; refills slide in
    fx.clear()
end

local function go_home()
    G.scene = nil
    G.modal = MODAL_NONE
    fx.clear()
end

local function show_hint()
    local pick
    for k = 1, SLOTS do   -- a name the player can read in the bar first
        local i = G.slots[k]
        if i and not G.found[i] then pick = i break end
    end
    for i = 1, ITEMS do if not pick and not G.found[i] then pick = i end end
    if not pick then return end
    G.hint = pick
    G.hint_ready = G.clock + HINT_RECHARGE
    G.focus = scenes[G.scene].at[pick]
    G.focus_time = .6
end

local function stars_for(seconds)
    if seconds <= STAR_TIMES[1] then return 3 elseif seconds <= STAR_TIMES[2] then return 2 end
    return 1
end

local function scene_tap(screen)
    local sc = scenes[G.scene]
    local p = G.cam:to_world(screen)
    for i = 1, ITEMS do
        if not G.found[i] and (p - sc.at[i]):ellipse(sc.radius[i]) <= 1 then
            G.found[i] = app.time()
            if G.hint == i then G.hint = nil end
            G.combo = G.combo_left > 0 and math.min(G.combo + 1, COMBO_MAX) or 1
            G.combo_left = COMBO_WINDOW
            local gain = FIND_POINTS * G.combo
            G.score = G.score + gain
            local at = G.cam:to_screen(sc.at[i])
            fx.sparkle(at, 40 * G.cam.zoom + 20, hex(0xFFE7A0))
            fx.text(at - vec2(0, 30), G.float, ("+%d"):format(gain))
            if found_count() == ITEMS then
                local stars = stars_for(G.clock)
                G.result = {score = G.score, time = G.clock, stars = stars}
                G.wallet = G.wallet + scene_reward
                G.wins[G.scene] = G.wins[G.scene] + 1
                G.stars[G.scene] = math.max(G.stars[G.scene], stars)
                story.play(("chapter-%d"):format(G.scene - 1), sc.clue)   -- the clue, the first time
                save_progress()
                G.modal = MODAL_WIN
                G.modal_time = 0
            end
            return
        end
    end
    -- a stray tap: points lost and the combo broken
    G.score = math.max(0, G.score - MISS_POINTS)
    G.combo, G.combo_left = 0, 0
    fx.text(screen - vec2(0, 20), G.float_miss, ("−%d"):format(MISS_POINTS))
end

------------------------------------------------------------ the UI kit
-- June's Journey's look, in the archive's colours: deep teal panels inside a
-- bevelled gold rim with a filigree line and corner studs, parchment cards,
-- red ribbon headers, glossy pill buttons with a lip, round gold-ringed icon
-- buttons with a caption, and dark currency capsules with a green "+".

local WHITE = color.WHITE
local GOLD_HI, GOLD, GOLD_LO, GOLD_SEAM = hex(0xF8E3A3), hex(0xDDB362), hex(0x93682A), hex(0x5E3F14)
local TEAL_HI, TEAL_LO = hex(0x22545C), hex(0x0F2E36)
local PARCH_HI, PARCH_LO = hex(0xFCF3DD), hex(0xEBD6A8)
local INK, INK_SOFT = hex(0x3A2914), hex(0x6B5435)

local BUTTONS = {
    green = {hex(0xA8E46C), hex(0x4AA536), hex(0x2A6A1E)},
    blue = {hex(0x67C0D6), hex(0x2D7E97), hex(0x184A5B)},
    red = {hex(0xE57A5E), hex(0xB13F2C), hex(0x6E2017)},
    off = {hex(0x9AA3A0), hex(0x66706E), hex(0x3B4443)},
}

local function stud(p, r)
    gfx.ngon(p, r + 1.5, 4, 0, GOLD_SEAM)
    gfx.ngon(p, r, 4, 0, GOLD)
    gfx.ngon(p - vec2(0, r * .25), r * .45, 4, 0, GOLD_HI)
end

-- An ornate panel: teal (or parchment) inside a bevelled gold rim.
local function frame(r, parchment, radius)
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
local function ribbon(c, w, label)
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
    text.fit(G.ribbon, body:inflate2(vec2(-24, -4)), vec2(.5, .52), label)
end

-- A glossy pill button with a darker lip; kind: green, blue, red, off.
local function button(r, label, kind)
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
    text.fit(G.button:outlined(2, c[3]), b:inflate2(vec2(-14, -4)), vec2(.5, .52), label)
    return st.clicked
end

------------------------------------------------------------------ icons
-- Simple shapes drawn in cream with a dark under-stroke, so no icon art is needed.

local ICON, ICON_DARK = hex(0xFFF4D8), rgba(20, 40, 44, 200)

local function icon_house(p, s, col)
    col = col or ICON
    for pass = 1, 2 do
        local c, o = pass == 1 and ICON_DARK or col, pass == 1 and vec2(0, 2) or vec2(0, 0)
        gfx.poly({p + o + vec2(-s * .95, -s * .05), p + o + vec2(0, -s * .9), p + o + vec2(s * .95, -s * .05)}, c)
        gfx.rect(rect(p.x - s * .6 + o.x, p.y - s * .12 + o.y, s * 1.2, s * .85), c)
    end
    gfx.round_rect(rect(p.x - s * .17, p.y + s * .25, s * .34, s * .48), 3, hex(0x7A5222))
end

local function icon_glass(p, s)
    for pass = 1, 2 do
        local c, o = pass == 1 and ICON_DARK or ICON, pass == 1 and vec2(0, 2) or vec2(0, 0)
        local q = p + o + vec2(-s * .15, -s * .15)
        gfx.line(q + vec2(s * .45, s * .45), q + vec2(s * .95, s * .95), s * .3, c)
        gfx.ring(q, s * .55, s * .2, c)
    end
    gfx.glow(p + vec2(-s * .2, -s * .22), s * .4, rgba(170, 230, 255, 160), rgba(170, 230, 255, 0))
end

local function icon_people(p, s)
    for pass = 1, 2 do
        local o = pass == 1 and vec2(0, 2) or vec2(0, 0)
        local back, front = pass == 1 and ICON_DARK or hex(0xD9C8A0), pass == 1 and ICON_DARK or ICON
        gfx.circle(p + o + vec2(-s * .38, -s * .42), s * .3, back)
        gfx.round_rect(rect(p.x - s * .85 + o.x, p.y - s * .08 + o.y, s * .9, s * .8), s * .38, back)
        gfx.circle(p + o + vec2(s * .2, -s * .3), s * .34, front)
        gfx.round_rect(rect(p.x - s * .35 + o.x, p.y + s * .08 + o.y, s * 1.1, s * .82), s * .42, front)
    end
end

local function icon_boat(p, s)
    for pass = 1, 2 do
        local c, o = pass == 1 and ICON_DARK or ICON, pass == 1 and vec2(0, 2) or vec2(0, 0)
        gfx.poly({p + o + vec2(-s, s * .25), p + o + vec2(s, s * .25), p + o + vec2(s * .6, s * .8), p + o + vec2(-s * .6, s * .8)}, c)
        gfx.poly({p + o + vec2(-s * .05, -s * .95), p + o + vec2(s * .7, s * .12), p + o + vec2(-s * .05, s * .12)}, c)
        gfx.poly({p + o + vec2(-s * .18, -s * .6), p + o + vec2(-s * .18, s * .12), p + o + vec2(-s * .7, s * .12)}, c)
    end
end

local function icon_bulb(p, s, lit)
    local glass = lit and hex(0xFFE27A) or hex(0xB9B4A2)
    if lit then gfx.glow(p - vec2(0, s * .2), s * 1.3, rgba(255, 220, 110, 120), rgba(255, 220, 110, 0)) end
    gfx.circle(p + vec2(0, 2 - s * .2), s * .62, ICON_DARK)
    gfx.circle(p - vec2(0, s * .2), s * .62, glass)
    gfx.poly({p + vec2(-s * .42, s * .1), p + vec2(s * .42, s * .1), p + vec2(s * .3, s * .5), p + vec2(-s * .3, s * .5)}, glass)
    gfx.round_rect(rect(p.x - s * .3, p.y + s * .48, s * .6, s * .38), 3, hex(0x8B8F92))
    gfx.line(p + vec2(-s * .3, s * .62), p + vec2(s * .3, s * .62), 1.5, hex(0x5C6064))
    gfx.circle(p + vec2(-s * .2, -s * .4), s * .14, rgba(255, 255, 255, 170))
end

local function icon_close(p, s)
    gfx.line(p + vec2(-s, -s + 2), p + vec2(s, s + 2), s * .5, ICON_DARK)
    gfx.line(p + vec2(s, -s + 2), p + vec2(-s, s + 2), s * .5, ICON_DARK)
    gfx.line(p + vec2(-s, -s), p + vec2(s, s), s * .5, ICON)
    gfx.line(p + vec2(s, -s), p + vec2(-s, s), s * .5, ICON)
end

local function icon_clock(p, s)
    gfx.circle(p, s, ICON)
    gfx.ring(p, s, s * .22, GOLD_LO)
    gfx.line(p, p + vec2(0, -s * .6), 2, INK)
    gfx.line(p, p + vec2(s * .45, 0), 2, INK)
end

local function icon_lock(p, s, col)
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

local function notify_dot(p)
    gfx.circle(p + vec2(0, 1.5), 10, rgba(0, 0, 0, 90))
    gfx.circle(p, 10, hex(0xFFF1D2))
    gfx.circle(p, 8, hex(0xD9432F))
    text.draw(G.badge, p, vec2(.5, .52), "!")
end

-- A round gold-ringed button with an icon and an optional caption under it.
local function round_button(c, radius, icon, caption, green)
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
        local s = G.caption
        local w = text.measure(s, caption).w + 18
        local tag = rect.anchor(p + vec2(0, radius + 2), size2(w, 22), vec2(.5, .5))
        gfx.round_rect(tag, 11, rgba(10, 30, 34, 225))
        gfx.round_rect_line(tag, 11, 1, rgba(233, 199, 123, 150))
        text.draw(s, tag:center(), vec2(.5, .52), caption)
    end
    return st.clicked
end

-- A dark capsule with a currency icon overlapping its left end and a green "+".
local function capsule(r, icon, value)
    local st = ui.hit(r, 0)
    gfx.shadow(r:offset(vec2(0, 3)), r.h * .5, 6, rgba(0, 0, 0, 90))
    gfx.round_rect(r, r.h * .5, rgba(9, 28, 32, 222))
    gfx.round_rect_line(r, r.h * .5, 1.6, rgba(233, 199, 123, 190))
    local ic = rect.centered(vec2(r.x + 6, r:center().y), size2(r.h + 14, r.h + 14))
    gfx.image(icon, ic, WHITE)
    text.fit(G.number, rect(r.x + r.h * .5 + 18, r.y, r.w - r.h * 1.5 - 22, r.h), vec2(.5, .5), value)
    plus_badge(vec2(r:max().x - r.h * .5, r:center().y), r.h * .5 - 3)
    return st.clicked
end

local function amount(pos, pivot, icon, str, s)
    local icon_size = s.size * 1.35
    local w = icon_size + 6 + text.measure(s, str).w
    local box = rect.anchor(pos, size2(w, icon_size), pivot)
    gfx.image(icon, box:left(icon_size), WHITE)
    text.draw(s, box:offset(vec2(icon_size + 6, 0)):point(vec2(0, .5)), vec2(0, .5), str)
    return box
end

local function star_row(c, size, earned, t)
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

local function level_of(influence)   -- levels at 0, 10, 40, 90, 160 ... influence
    local n = math.floor(math.sqrt(influence / 10))
    local lo, hi = 10 * n * n, 10 * (n + 1) * (n + 1)
    return n + 1, (influence - lo) / (hi - lo), hi
end

------------------------------------------------------------- the island

local function chapter_goal()
    for i = 1, SCENES do
        if G.wins[i] == 0 then return i, G.wallet[INFLUENCE] >= scenes[i].gate end
    end
    return nil, true
end

local function draw_player(at)
    local nefra = story.character("nefra")
    local level, progress, next_at = level_of(G.wallet[INFLUENCE])
    local avatar = rect(at.x, at.y, 78, 78)
    local plate = rect(avatar:center().x, avatar.y + 14, 250, 54)
    gfx.shadow(plate:offset(vec2(0, 4)), 27, 8, rgba(0, 0, 0, 90))
    gfx.round_rect(plate, 27, rgba(9, 28, 32, 222))
    gfx.round_rect_line(plate, 27, 1.6, rgba(233, 199, 123, 190))
    local info = plate:inflate2(vec2(-14, -7))
    info:cut_left(avatar.w * .5 + 6)
    text.draw(G.name, info:pos(), vec2(0, 0), nefra.name)
    local bar = info:bottom(15)
    gfx.round_rect(bar, 7.5, rgba(0, 0, 0, 120))
    local fill = rect(bar.x, bar.y, math.max(bar.h, bar.w * progress), bar.h)
    gfx.round_rect_grad(fill, 7.5, hex(0x8FE0F0), hex(0x2F95B3))
    gfx.round_rect_line(bar, 7.5, 1, rgba(233, 199, 123, 120))
    text.fit(G.tiny, bar:inflate2(vec2(-4, 0)), vec2(.5, .5), ("%d / %d"):format(G.wallet[INFLUENCE], next_at))

    gfx.shadow(avatar:offset(vec2(0, 5)), 18, 12, rgba(0, 0, 0, 120))
    gfx.round_rect_grad(avatar, 18, GOLD_HI, GOLD_LO)
    gfx.round_rect(avatar:inflate(-3), 15, GOLD_SEAM)
    local face = avatar:inflate(-5)
    gfx.round_rect(face, 13, hex(0x2E7F7A))
    local ps = texture.size(nefra.portrait)
    gfx.image_part(nefra.portrait, rect(ps.w * .27, ps.h * .02, ps.w * .42, ps.w * .42), face:inflate(-2), WHITE)
    gfx.round_rect_line(face, 13, 3, GOLD_LO)
    local star = avatar:point(vec2(.92, .92))
    gfx.star(star + vec2(0, 2), 21, .55, 5, -math.pi / 2, rgba(0, 0, 0, 100))
    gfx.star(star, 21, .55, 5, -math.pi / 2, GOLD_SEAM)
    gfx.star(star, 18.5, .55, 5, -math.pi / 2, hex(0xF2B637))
    gfx.star(star - vec2(0, 2), 12, .55, 5, -math.pi / 2, hex(0xFFE37A))
    text.draw(G.badge, star + vec2(0, 1), vec2(.5, .5), tostring(level))
    ui.block(avatar:union(plate))
end

local function draw_goal(c)
    local i, ready = chapter_goal()
    local eyebrow, title
    if not i then eyebrow, title = "АРХИВ СОБРАН", "Переиграйте главы на три звезды"
    elseif ready then eyebrow, title = ("ГЛАВА %d ГОТОВА"):format(i), scenes[i].title
    else eyebrow, title = ("ГЛАВА %d · НУЖНО %d ВЛИЯНИЯ"):format(i, scenes[i].gate), "Стройте здания на острове" end
    local w = math.max(text.measure(G.goal_title, title).w, text.measure(G.goal_eyebrow, eyebrow).w) + 110
    local r = rect.anchor(c, size2(w, 66), vec2(.5, 1))
    local st = ui.hit(r, 0)
    local inner = frame(st.held and r:offset(vec2(0, 2)) or r, true, 16)
    local icon = inner:cut_left(56)
    if ready and i then icon_glass(icon:center() + vec2(2, 0), 13) else icon_house(icon:center() + vec2(2, 4), 14) end
    text.draw(G.goal_eyebrow, inner:pos() + vec2(0, 11), vec2(0, 0), eyebrow)
    text.draw(G.goal_title, inner:pos() + vec2(0, 27), vec2(0, 0), title)
    local arrow = vec2(inner:max().x - 18, inner:center().y)
    gfx.poly({arrow + vec2(-6, -9), arrow + vec2(6, 0), arrow + vec2(-6, 9)}, INK_SOFT)
    if st.clicked then G.modal, G.modal_time = MODAL_CHAPTERS, 0 end
end

local function draw_tray(r)
    local inner = frame(r, false, 20)
    local head = inner:cut_top(30)
    text.draw(G.eyebrow, head:pos() + vec2(16, 12), vec2(0, 0), "ПОСТРОЙКИ · ВЫБЕРИТЕ И КОСНИТЕСЬ ОСТРОВА")
    if round_button(vec2(r:max().x - 8, r.y + 8), 20, icon_close) then G.tray = false; G.island.selected = -1 end
    local cards = inner:inflate2(vec2(-14, -10))
    cards:cut_top(-2)
    for i, d in ipairs(buildings) do
        local card = cards:col(#buildings, i - 1, 12)
        local selected = G.island.selected == i - 1
        local st = ui.hit(card, 0)
        if st.clicked then G.island.selected = selected and -1 or i - 1 end
        local c = st.held and card:offset(vec2(0, 2)) or card
        if selected then gfx.glow(c:center(), c.w * .75, rgba(255, 220, 120, 90), rgba(255, 220, 120, 0)) end
        gfx.round_rect_grad(c, 12, selected and hex(0xFFF1B8) or GOLD_HI, selected and hex(0xE8A93C) or GOLD_LO)
        local body = c:inflate(-3)
        gfx.round_rect_grad(body, 10, PARCH_HI, PARCH_LO)
        local price = body:cut_bottom(28)
        gfx.round_rect(price:inflate2(vec2(-6, -3)), 10, rgba(58, 41, 20, 30))
        local afford = G.wallet[COINS] >= d.cost[COINS]
        amount(price:center(), vec2(.5, .5), G.coin, tostring(d.cost[COINS]), G.price:filled(afford and INK or hex(0xA83A2A)))
        local name = body:cut_top(24)
        text.fit(G.card_title, name:inflate2(vec2(-6, 0)), vec2(.5, .6), d.name)
        local pic = body:inflate(-2)
        gfx.clip(pic)   -- the sprites carry transparent margins: draw them larger, clipped to the card
        gfx.image(d.sprite, pic:fit(texture.size(d.sprite)):scale(1.4), WHITE)
        gfx.unclip()
        local tag = rect.anchor(body:point(vec2(1, 0)) + vec2(-4, 28), size2(54, 22), vec2(1, 0))
        gfx.round_rect(tag, 11, rgba(30, 79, 86, 230))
        amount(tag:center(), vec2(.5, .5), G.influence, ("+%d"):format(d.reward[INFLUENCE]), G.tiny_num)
    end
end

local function island_frame(screen, world)
    local island = G.island
    local cam = island.cam
    cam.view = app.bleed()   -- the island runs under the status bar and the home indicator
    island.cam = cam
    if G.modal == MODAL_NONE then
        local ev = island:update(world, G.wallet, app.clock(), app.dt())
        if ev.result == city.BUILT then
            save_progress()
            fx.burst(ev.screen, 26, hex(0xF2D29A), 260, 9)
            ui.toast(("Постройка готова · +%d влияния"):format(buildings[island.items[ev.building + 1].type + 1].reward[INFLUENCE]))
        elseif ev.result == city.CANT_AFFORD then
            ui.toast("Недостаточно монет. Пройдите сцену ещё раз.")
        elseif ev.result == city.BLOCKED then
            ui.toast("Нужно свободное место на открытом берегу")
        end
    end
    local full = app.bleed()
    gfx.bleed(true)
    island:draw(world, app.clock())
    -- a soft vignette keeps the corners readable under the HUD
    gfx.rect_grad(rect(full.x, full.y, full.w, screen.y - full.y + 120), rgba(6, 22, 26, 150), rgba(6, 22, 26, 0))
    local low = screen:max().y - 150
    gfx.rect_grad(rect(full.x, low, full.w, full:max().y - low), rgba(6, 22, 26, 0), rgba(6, 22, 26, 150))
    fx.draw()
    gfx.bleed(false)

    local m = 18
    local area = screen:inflate(-m)
    draw_player(area:pos())

    -- currencies, top right
    local top = area:top(46)
    local influence = top:cut_right(150)
    top:cut_right(22)
    local coins = top:cut_right(170)
    if capsule(coins:inflate2(vec2(0, -2)), G.coin, tostring(G.wallet[COINS])) then ui.toast("Монеты дают найденные предметы: пройдите главу") end
    if capsule(influence:inflate2(vec2(0, -2)), G.influence, tostring(G.wallet[INFLUENCE])) then ui.toast("Влияние дают постройки на острове") end

    if story.active() then return end   -- story scenes keep the stage clear, as June's Journey does

    -- the left column: people and the next shore
    local x = area.x + 39
    if round_button(vec2(x, area.y + 150), 32, icon_people, "Герои") then G.modal, G.modal_time = MODAL_CAST, 0 end
    local nxt = island:next_zone(G.wallet)
    if nxt >= 0 then
        local cost = island.zones[nxt + 1].cost[COINS]
        if round_button(vec2(x, area.y + 250), 32, icon_boat, ("Берег · %d"):format(cost)) then
            if island:unlock(nxt, G.wallet) then
                save_progress()
                story.add(merit_shore)
            else
                ui.toast(("Новый берег стоит %d монет — пройдите главу"):format(cost))
            end
        end
    end

    if G.tray then
        local tray = area:bottom(184)
        draw_tray(tray)
        if island.selected >= 0 then
            local s = G.eyebrow:sized(14)
            local label = ("Коснитесь свободного места: %s"):format(buildings[island.selected + 1].name)
            local pill = rect.anchor(vec2(screen:center().x, tray.y - 18), size2(text.measure(s, label).w + 36, 36), vec2(.5, 1))
            gfx.round_rect(pill, 18, rgba(9, 28, 32, 222))
            gfx.round_rect_line(pill, 18, 1.4, rgba(233, 199, 123, 170))
            text.draw(s, pill:center(), vec2(.5, .5), label)
        end
        return
    end

    -- bottom: build, the current goal, play
    if round_button(vec2(area.x + 46, area:max().y - 56), 40, icon_house, "Строить") then G.tray = true end
    draw_goal(vec2(screen:center().x, area:max().y))
    local play = vec2(area:max().x - 62, area:max().y - 66)
    G.spots.chapters = play
    if round_button(play, 54, icon_glass, "Главы", true) then G.modal, G.modal_time = MODAL_CHAPTERS, 0 end
    local i, ready = chapter_goal()
    if i and ready then notify_dot(play + vec2(40, -40)) end
end

------------------------------------------------------------ the scene

local function scene_frame(screen, world, dt)
    local sc = scenes[G.scene]
    -- the picture covers the whole display, safe-area margins included (no
    -- bars); drag to see its edges. The HUD floats over it inside the safe screen.
    local view = app.bleed()
    local playing = G.modal == MODAL_NONE and not story.active()
    if playing then
        G.clock = G.clock + dt
        G.combo_left = math.max(0, G.combo_left - dt)
        if G.combo_left <= 0 then G.combo = 0 end
    end
    refill_slots(app.time(), .8)

    G.cam.view = view
    G.cam.min_zoom = 0                -- cover sets the floor: the picture always fills the view
    G.cam.max_zoom = G.cam:fit_zoom() * 3.4
    G.cam = G.cam:clamp()
    if G.modal == MODAL_NONE then
        G.cam = G.cam:input(world):clamp()
        if world.tap and view:contains(world.pos) then scene_tap(world.pos) end
    end
    if G.focus_time > 0 then
        G.focus_time = G.focus_time - dt
        G.cam = G.cam:look(G.cam.center:approach(G.focus, 10, dt)):clamp()
    end

    local bg = G.backgrounds[G.scene]
    gfx.bleed(true)
    gfx.clip(view)
    G.cam:draw_texture(bg)
    local now = app.time()
    for i = 1, ITEMS do
        local p = G.cam:to_screen(sc.at[i])
        if G.found[i] then
            local t = ease.out_back(num.saturate((now - G.found[i]) * 3))
            gfx.ring(p, 15 * t, 2.5, rgba(172, 239, 195, 230))
            gfx.ring(p, 21 * t, 1.5, rgba(172, 239, 195, 120))
        elseif G.hint == i then
            local r = math.max(25, math.min(sc.radius[i].x, sc.radius[i].y)) * G.cam.zoom
            local pulse = 1 + math.sin(now * 6) * .06
            gfx.glow(p, r * 1.6, rgba(255, 225, 116, 70), rgba(255, 225, 116, 0))
            gfx.ring(p, r * pulse, 3, rgba(255, 225, 116, 255))
        end
    end
    fx.draw()
    gfx.unclip()
    gfx.bleed(false)

    -- June's Journey keeps the picture clear: a bonus bar while a combo runs and
    -- a pause button on top, translucent name pills and the hint bulb below.
    -- Score and time wait for the result.
    local area = screen:inflate(-18)

    -- pause, top right: a glassy circle
    local pc = vec2(area:max().x - 30, area.y + 30)
    local pause = ui.hit(rect.centered(pc, size2(64, 64)), 0)
    local pp = pause.held and pc + vec2(0, 2) or pc
    gfx.circle(pp, 29, rgba(20, 16, 12, pause.hot and 150 or 110))
    gfx.ring(pp, 28, 3, rgba(255, 248, 230, 235))
    for k = -1, 1, 2 do gfx.round_rect(rect.centered(pp + vec2(k * 6.5, 0), size2(7, 22)), 2.5, rgba(255, 248, 230, 245)) end
    if pause.clicked then G.modal, G.modal_time = MODAL_PAUSE, 0 end

    -- the bonus bar: it fills on each find and drains; the badge counts the chain
    local shown = G.combo >= 2 and 1 or 0
    G.bonus_in = (G.bonus_in or 0) + (shown - (G.bonus_in or 0)) * math.min(1, dt * 10)
    if G.bonus_in > .02 then
        local a = G.bonus_in
        local bar = rect.anchor(vec2(screen:center().x - 30, area.y + 30), size2(330, 40), vec2(.5, .5))
        gfx.round_rect(bar:inflate(2), 22, rgba(255, 236, 190, 170 * a))
        gfx.round_rect(bar, 20, rgba(20, 16, 12, 130 * a))
        local f = num.saturate(G.combo_left / COMBO_WINDOW)
        local fill = rect(bar.x + 3, bar.y + 3, math.max(34, (bar.w - 6) * f), bar.h - 6)
        gfx.round_rect_grad(fill, 17, hex(0x7FE3F5):alpha(a), hex(0x1E97C2):alpha(a))
        gfx.round_rect(rect(fill.x + 6, fill.y + 2, fill.w - 12, fill.h * .35), 8, rgba(255, 255, 255, 70 * a))
        text.draw(G.bonus:faded(1 - a), bar:center() - vec2(14, 0), vec2(.5, .52), "Бонус")
        local c = vec2(bar:max().x, bar:center().y)
        gfx.circle(c + vec2(0, 3), 31, rgba(0, 0, 0, 70 * a))
        gfx.circle(c, 30, GOLD_SEAM:alpha(a))
        gfx.circle(c, 28, GOLD:alpha(a))
        gfx.circle(c, 24, hex(0xFFF6DE):alpha(a))
        text.draw(G.multiplier:faded(1 - a), c + vec2(0, 1), vec2(.5, .5), ("%dx"):format(G.combo))
    end

    -- hint, bottom right: a glowing bulb in a gold ring
    local ready = G.clock >= G.hint_ready
    local hc = vec2(area:max().x - 44, area:max().y - 38)
    local hint = ui.hit(rect.centered(hc, size2(96, 96)), 0)
    local hp = hint.held and hc + vec2(0, 2) or hc
    if ready then gfx.glow(hp, 62, rgba(255, 214, 110, 150 + 40 * math.sin(now * 3)), rgba(255, 214, 110, 0)) end
    gfx.circle(hp, 42, GOLD_SEAM)
    gfx.circle(hp, 40, ready and GOLD_HI or hex(0xB8A27A))
    gfx.circle(hp, 34, GOLD_SEAM)
    gfx.circle(hp, 33, rgba(30, 22, 14, 150))
    icon_bulb(hp + vec2(0, 2), 20, ready)
    if not ready then   -- the recharge sweeps round the ring
        local f = 1 - (G.hint_ready - G.clock) / HINT_RECHARGE
        local pts = {}
        for k = 0, 40 do
            local ang = -math.pi / 2 + (k / 40) * f * math.pi * 2
            pts[#pts + 1] = hp + vec2(math.cos(ang), math.sin(ang)):scale(37)
        end
        if #pts > 1 then gfx.polyline(pts, 5, hex(0x8FE0F0)) end
    end
    if hint.clicked and ready then show_hint() end

    -- the names: three translucent pills across the bottom, the picture showing through
    local row = rect(area.x, area:max().y - 66, hc.x - 56 - area.x, 60)
    for k = 1, SLOTS do
        local slot = row:col(SLOTS, k - 1, 14)
        local i = G.slots[k]
        if i then
            local arrive = ease.out_back(num.saturate((now - (G.slot_time[k] or 0)) * 4))
            local leave = G.found[i] and num.saturate((now - G.found[i] - .45) / .35) or 0
            local a = num.saturate(arrive) * (1 - leave)
            local pill = slot:offset(vec2(0, (1 - arrive) * 30 + leave * 24))
            local hinted = G.hint == i and not G.found[i]
            gfx.round_rect(pill:inflate(2.5), pill.h * .5 + 2.5, (hinted and hex(0xFFE08A) or hex(0xE2BC6E)):alpha(a))
            local fill = hinted and rgba(176, 118, 36, 215) or rgba(48, 28, 12, 168)
            gfx.round_rect(pill, pill.h * .5, fill:alpha(a))
            gfx.round_rect(rect(pill.x + pill.h * .4, pill.y + 3, pill.w - pill.h * .8, pill.h * .3), pill.h * .15, rgba(255, 236, 200, 16 * a))
            local ink = text.fit(G.pill_text:faded(1 - a), pill:inflate2(vec2(-pill.h * .5, -8)), vec2(.5, .54), sc.names[i])
            if G.found[i] then
                local t = num.saturate((now - G.found[i]) / .45)
                gfx.line(ink:point(vec2(0, .55)), ink:point(vec2(t, .55)), 3, rgba(150, 235, 140, 240 * a))
            end
            ui.block(pill)
        end
    end
end

----------------------------------------------------------------- popups

local function popup(w, h, t, title)
    local s = app.screen()
    local box = rect.centered(s:center() + vec2(0, 14), size2(math.min(w, s.w - 40), math.min(h, s.h - 70)))
    local k = .9 + .1 * ease.out_back(num.saturate(t * 4))
    box = box:scale(k)
    local inner = frame(box, false, 24)
    ribbon(vec2(box:center().x, box.y + 2), math.min(420, box.w * .6), title)
    return box, inner
end

local function close_button(box)
    if round_button(box:point(vec2(1, 0)) + vec2(-6, 6), 22, icon_close) then G.modal = MODAL_NONE end
end

local function win_dialog(t)
    local sc = scenes[G.scene]
    local res = G.result or {score = G.score, time = G.clock, stars = 1}
    local clue = #sc.clue > 1 and ("%s «%s»"):format(sc.clue[1][2], sc.clue[2][2]) or sc.clue[1][2]
    local clue_s = G.ink_body
    local clue_h = text.box_size(clue_s, 560 - 80, clue).h
    local box, r = popup(640, 410 + clue_h, t, "Глава пройдена!")
    r:cut_top(44)
    star_row(r:point(vec2(.5, 0)) + vec2(0, 34), 26, res.stars, t)
    r:cut_top(84)
    local stats = r:cut_top(56)
    local half = stats:col(2, 0, 0)
    text.draw(G.eyebrow, half:point(vec2(.5, 0)), vec2(.5, 0), "ОЧКИ")
    text.draw(G.score_style, half:point(vec2(.5, 1)), vec2(.5, 1), tostring(res.score))
    half = stats:col(2, 1, 0)
    text.draw(G.eyebrow, half:point(vec2(.5, 0)), vec2(.5, 0), "ВРЕМЯ")
    text.draw(G.score_style, half:point(vec2(.5, 1)), vec2(.5, 1), ("%d:%02d"):format(math.floor(res.time / 60), math.floor(res.time % 60)))
    r:cut_top(14)
    local rewards = r:cut_top(64):inflate2(vec2(-110, 0))
    for k, item in ipairs({{G.coin, scene_reward[COINS]}, {G.influence, scene_reward[INFLUENCE]}}) do
        local tile = rewards:col(2, k - 1, 20)
        local inner = frame(tile, true, 14)
        amount(inner:center(), vec2(.5, .5), item[1], ("+%d"):format(item[2]), G.reward)
    end
    r:cut_top(16)
    local note = r:cut_top(clue_h + 46):inflate2(vec2(-24, 0))
    local paper = frame(note, true, 14)
    text.draw(G.goal_eyebrow, paper:pos() + vec2(16, 10), vec2(0, 0), "ФРАГМЕНТ АРХИВА")
    text.box(clue_s, rect(paper.x + 16, paper.y + 28, paper.w - 32, clue_h), vec2(0, 0), clue)
    r:cut_top(18)
    local continue = r:cut_top(56):align(size2(280, 56), vec2(.5, .5))
    G.spots.continue = continue:center()
    if button(continue, "Продолжить", "green") then go_home() end
end

local function chapter_card(r, i)
    local sc = scenes[i]
    local locked = G.wallet[INFLUENCE] < sc.gate
    local inner = frame(r, true, 18)
    local pic = inner:cut_top(inner.w * 2 / 3):inflate(-8)
    pic.y = pic.y + 4
    gfx.round_rect(pic:inflate(3), 10, GOLD_LO)
    local bg = G.backgrounds[i]
    local ts = texture.size(bg)
    gfx.image_part(bg, rect(0, 0, ts.w, ts.h), pic, locked and rgba(110, 110, 110, 255) or WHITE)
    gfx.round_rect_line(pic, 8, 2, GOLD_SEAM)
    if locked then
        gfx.rect(pic, rgba(10, 20, 24, 120))
        gfx.circle(pic:center(), 30, rgba(9, 28, 32, 210))
        gfx.ring(pic:center(), 30, 2, GOLD)
        icon_lock(pic:center() + vec2(0, 2), 22)
    end
    local tag = rect.anchor(pic:point(vec2(0, 0)) + vec2(10, 10), size2(92, 26), vec2(0, 0))
    gfx.round_rect(tag, 13, rgba(9, 28, 32, 220))
    text.draw(G.eyebrow:sized(11), tag:center(), vec2(.5, .5), ("ГЛАВА %d"):format(i))
    inner:cut_top(10)
    text.fit(G.card_title:sized(23), inner:cut_top(30):inflate2(vec2(-12, 0)), vec2(.5, .5), sc.title)
    star_row(inner:cut_top(36):center() + vec2(0, 4), 11, G.stars[i])
    local teaser = inner:cut_top(math.max(0, inner.h - 74))
    text.box(G.ink_small, teaser:inflate2(vec2(-16, -2)), vec2(.5, 0), sc.teaser)
    local b = inner:inflate2(vec2(-16, -10)):bottom(50)
    G.spots["play" .. i] = b:center()
    if locked then
        button(b, ("Нужно %d влияния"):format(sc.gate), "off")
    elseif button(b, G.wins[i] > 0 and "Играть снова" or "Играть", G.wins[i] > 0 and "blue" or "green") then
        open_scene(i)
    end
end

local function pause_dialog(t)
    local box, r = popup(560, 216, t, "Пауза")
    r:cut_top(44)
    text.box(G.body:sized(19), r:cut_top(40):inflate2(vec2(-30, 0)), vec2(.5, .5),
             ("%s · найдено %d из %d"):format(scenes[G.scene].title, found_count(), ITEMS))
    r:cut_top(18)
    local buttons = r:cut_top(56):inflate2(vec2(-40, 0))
    if button(buttons:col(2, 0, 20), "На остров", "blue") then go_home() end
    if button(buttons:col(2, 1, 20), "Продолжить", "green") then G.modal = MODAL_NONE end
end

local function chapters_dialog(t)
    local w = math.min(1040, app.screen().w - 40)
    local card_w = (w - 10 - 44 - 40) / SCENES
    local card_h = (card_w - 26) * 2 / 3 + 8 + 10 + 30 + 36 + 54 + 74
    local box, r = popup(1040, card_h + 10 + 28 + 40 + 6, t, "Главы архива")
    close_button(box)
    r = r:inflate2(vec2(-22, -14))
    r:cut_top(40)
    for i = 1, SCENES do chapter_card(r:col(SCENES, i - 1, 20), i) end
end

local function cast_dialog(t)
    local box, r = popup(1000, 640, t, "Люди острова")
    close_button(box)
    r = r:inflate2(vec2(-24, -16))
    r:cut_top(40)
    for i, who in ipairs(cast) do
        local col = r:col(#cast, i - 1, 20)
        local caption = col:cut_bottom(84)
        gfx.glow(col:point(vec2(.5, .8)), col.w * .5, rgba(242, 210, 140, 50), rgba(242, 210, 140, 0))
        local face = story.character(who.id).portrait
        local fs = texture.size(face)
        gfx.image(face, col:align(fs:scale(fs:fit(col:size())), vec2(.5, 1)), WHITE)
        local plate = caption:inflate2(vec2(-8, -4))
        local inner = frame(plate, true, 14)
        text.draw(G.card_title:sized(24), inner:point(vec2(.5, 0)) + vec2(0, 8), vec2(.5, 0), who.name)
        text.box(G.ink_small, inner:bottom(30):inflate2(vec2(-10, 0)), vec2(.5, 0), who.role)
    end
end

------------------------------------------------------------------ smoke

-- --smoke plays chapter one through injected clicks: skip the intro, open the
-- chapters, play, tap a miss and every item, continue, and check the save.
local function smoke()
    G.smoke_frame = (G.smoke_frame or 0) + 1
    local f = G.smoke_frame
    if f > 6000 then error("Nile smoke timed out at step " .. tostring(G.smoke_step)) end
    if f % 6 ~= 0 then return end
    G.smoke_step = G.smoke_step or 0
    if story.active() then story.next() return end
    local step = G.smoke_step
    if step == 0 then app.inject_click(G.spots.chapters); G.smoke_step = 1
    elseif step == 1 then
        assert(G.modal == MODAL_CHAPTERS, "chapters button failed")
        app.inject_click(G.spots.play1); G.smoke_step = 2
    elseif step == 2 then
        assert(G.scene == 1 and G.modal == MODAL_NONE, "play button failed")
        app.inject_click(G.cam:to_screen(vec2(640, 470))); G.smoke_step = 3   -- open floor: a miss
    elseif step == 3 then
        assert(found_count() == 0, "a miss found an item")
        G.smoke_step = 4
    elseif step == 4 then
        for i = 1, ITEMS do
            if not G.found[i] then
                -- the picture covers the screen, so an item may start off it or
                -- under the HUD: pan to it as a player would, then tap it
                local at = G.cam:to_screen(scenes[1].at[i])
                if not app.screen():inflate2(vec2(-110, -110)):contains(at) then
                    G.cam = G.cam:look(scenes[1].at[i]):clamp()
                    at = G.cam:to_screen(scenes[1].at[i])
                end
                app.inject_click(at)
                return
            end
        end
        G.smoke_step = 5
    elseif step == 5 then
        assert(G.modal == MODAL_WIN and G.result and G.result.stars >= 1, "no result after every item")
        app.inject_click(G.spots.continue); G.smoke_step = 6
    elseif step == 6 then
        assert(not G.scene and G.wins[1] == 1 and G.stars[1] >= 1, "continue did not bank the chapter")
        print(("Nile smoke: chapter one played through clicks, %d points, %d stars"):format(G.result.score, G.result.stars))
        app.quit()
    end
end

------------------------------------------------------------------ frame

local function frame_fn(dt)
    local inp = input.get()
    local world = input.world()
    local talking = story.active()
    if G.modal ~= MODAL_NONE or talking then world = input{pos = inp.pos, pinch = 1} end
    if inp.back and not talking then
        if G.modal == MODAL_WIN then go_home()
        elseif G.modal ~= MODAL_NONE then G.modal = MODAL_NONE
        elseif G.tray then G.tray = false; G.island.selected = -1
        elseif G.scene then G.modal, G.modal_time = MODAL_PAUSE, 0 end
    end
    fx.update(dt)

    local screen = app.screen()
    ui.set_enabled(G.modal == MODAL_NONE and not talking)
    if G.scene then scene_frame(screen, world, dt) else island_frame(screen, world) end
    ui.set_enabled(true)

    if G.modal ~= MODAL_NONE and not talking then   -- a dialogue goes first: the reward waits for it
        G.modal_time = G.modal_time + dt
        ui.modal_backdrop(G.modal_time * 4)
        if G.modal == MODAL_WIN then win_dialog(G.modal_time)
        elseif G.modal == MODAL_CHAPTERS then chapters_dialog(G.modal_time)
        elseif G.modal == MODAL_PAUSE then pause_dialog(G.modal_time)
        else cast_dialog(G.modal_time) end
    end
    story.frame(dt)
    if G.smoke then smoke() end
end

------------------------------------------------------------------- setup

local function setup_theme()
    G.serif = font.load("fonts/Philosopher-Bold.ttf")
    G.sans = font.load("fonts/PT_Sans-Web-Regular.ttf")
    G.sans_bold = font.load("fonts/PT_Sans-Web-Bold.ttf")
    font.set_fallback(G.serif, G.sans_bold)

    local cream, ink = hex(0xF4E8CA), hex(0x0B2426)
    local base = style{font = G.sans, size = 17, fill = cream, shadow = rgba(0, 0, 0, 90), shadow_offset = vec2(0, 1), shadow_blur = 1}
    G.body = base
    G.muted = base:sized(14):filled(hex(0xB5C6B9))
    G.eyebrow = style{font = G.sans_bold, size = 12, fill = hex(0xE9D7A8), tracking = 1.6, shadow = rgba(0, 0, 0, 120), shadow_offset = vec2(0, 1), shadow_blur = 1}
    G.heading = style{font = G.serif, size = 22, fill = cream, shadow = rgba(0, 0, 0, 120), shadow_offset = vec2(0, 2), shadow_blur = 2}
    G.number = style{font = G.sans_bold, size = 20, fill = cream, outline = ink, outline_width = 1}
    G.tiny = style{font = G.sans_bold, size = 11, fill = WHITE, outline = rgba(10, 40, 50, 220), outline_width = 1}
    G.tiny_num = style{font = G.sans_bold, size = 13, fill = WHITE}
    G.name = style{font = G.serif, size = 20, fill = cream, outline = ink, outline_width = 1.2}
    G.badge = style{font = G.sans_bold, size = 16, fill = WHITE, outline = hex(0x6B4410), outline_width = 1.6}
    G.caption = style{font = G.sans_bold, size = 13, fill = cream}
    G.button = style{font = G.sans_bold, size = 21, fill = WHITE, shadow = rgba(0, 0, 0, 80), shadow_offset = vec2(0, 2), shadow_blur = 1}
    G.ribbon = style{font = G.serif, size = 26}:grad(hex(0xFFF6DC), hex(0xF5D58E)):outlined(1.6, hex(0x5A150F)):shadowed(vec2(0, 2), 2, rgba(0, 0, 0, 120))
    G.score_style = style{font = G.serif, size = 30}:grad(hex(0xFFF3D1), hex(0xE2B46A)):outlined(1.4, ink):shadowed(vec2(0, 2), 3, rgba(0, 0, 0, 140))
    G.item = style{font = G.serif, size = 22, fill = INK}
    G.item_found = style{font = G.serif, size = 22, fill = hex(0x4E7A44)}
    G.card_title = style{font = G.serif, size = 18, fill = INK}
    G.price = style{font = G.sans_bold, size = 15, fill = INK}
    G.reward = style{font = G.serif, size = 28, fill = INK}
    G.ink_body = style{font = G.sans, size = 17, fill = INK}
    G.ink_small = style{font = G.sans, size = 14, fill = INK_SOFT}
    G.goal_eyebrow = style{font = G.sans_bold, size = 11, fill = hex(0x8A5A22), tracking = 1.4}
    G.goal_title = style{font = G.serif, size = 20, fill = INK}
    G.pill_text = style{font = G.sans_bold, size = 30, fill = WHITE, outline = rgba(40, 24, 10, 230), outline_width = 2,
                        shadow = rgba(0, 0, 0, 120), shadow_offset = vec2(0, 2), shadow_blur = 2}
    G.bonus = style{font = G.sans_bold, size = 22, fill = WHITE, outline = rgba(10, 50, 70, 220), outline_width = 1.6}
    G.multiplier = style{font = G.serif, size = 24}:grad(hex(0xF6C24A), hex(0xB8761C)):outlined(1.2, hex(0x5A3608))
    G.float = style{font = G.serif, size = 26}:grad(hex(0xFFF6DC), hex(0xF5C860)):outlined(1.6, hex(0x4A2A08))
    G.float_miss = style{font = G.serif, size = 22, fill = hex(0xFF8A70), outline = hex(0x3A0E08), outline_width = 1.4}

    G.theme = ui_theme{
        text = base,
        small = G.eyebrow,
        title = style{font = G.serif, size = 30}:grad(hex(0xFFF3D1), hex(0xE2B46A)):outlined(1.4, ink):shadowed(vec2(0, 3), 4, rgba(0, 0, 0, 140)),
        button = style{font = G.sans_bold, size = 17, fill = hex(0xF5E7C5)},
        accent_text = style{font = G.sans_bold, size = 17, fill = hex(0x293E39)},
        panel = hex(0x1D4442), panel2 = hex(0x183A39), border = rgba(167, 173, 117, 90),
        button_bg = hex(0x2A524F), button_bg2 = hex(0x1F4442), button_hot = hex(0x38615B),
        button_border = rgba(191, 166, 107, 110),
        accent = hex(0xF0CF8E), accent2 = hex(0xD8AE66), active = hex(0xE4C080),
        dim = rgba(6, 22, 26, 200), toast_bg = hex(0xF6E7C1), toast_text = INK, radius = 10,
    }
    ui.set_theme(G.theme)
    story.setup(cast, story_style{
        text = style{font = G.sans, size = 22, fill = hex(0x203C36)},
        name = style{font = G.sans_bold, size = 17, fill = hex(0xFFF6E0)},
        bubble = hex(0xFBF1DA), edge = hex(0x9C7A3C), dim = rgba(6, 28, 33, 120),
        portrait_height = .64, skip = "Пропустить",
    })
end

-- Debug/QA entry points used to capture screenshots:
-- --screen island|build|scene0..2|cast|chapters|pause|win|story|horem|merit,
-- and --footprints to check the buildings' measured footprints and pivots
local function apply_screen_arg(screen)
    G.wallet[INFLUENCE] = 100
    G.wallet[COINS] = 900
    if screen:sub(1, 5) == "scene" then
        open_scene(num.clampi((tonumber(screen:sub(6)) or 0) + 1, 1, SCENES))
        if app.arg("found") then
            for _, i in ipairs({1, 3, 4, 6}) do G.found[i] = -10 end
            G.score, G.combo, G.combo_left, G.clock = 1800, 3, 3.2, 47
            refill_slots(app.time(), 0)
            for k = 1, SLOTS do G.slot_time[k] = app.time() - 10 end
            show_hint()
            G.hint_ready = G.clock + 6
            G.bonus_in = 1
        end
    elseif screen == "build" then
        G.tray = true
        G.island.selected = 1
    elseif screen == "cast" then
        G.modal, G.modal_time = MODAL_CAST, 1
    elseif screen == "pause" then
        open_scene(1)
        for _, i in ipairs({2, 5}) do G.found[i] = -10 end
        G.modal, G.modal_time = MODAL_PAUSE, 1
    elseif screen == "chapters" then
        G.wallet[INFLUENCE] = 30
        G.wins, G.stars = {1, 0, 0}, {3, 0, 0}
        G.modal, G.modal_time = MODAL_CHAPTERS, 1
    elseif screen == "win" then
        open_scene(2)
        for i = 1, ITEMS do G.found[i] = 0 end
        G.result = {score = 4200, time = 68, stars = 3}
        G.modal, G.modal_time = MODAL_WIN, 2
    elseif screen == "story" then
        story.play("intro", intro)
    elseif screen == "horem" then
        open_scene(3)
        story.play("chapter-2", scenes[3].clue)
        story.next()   -- Nefra listens while her father's note speaks
    elseif screen == "merit" then
        story.add(merit_shore)
    elseif screen == "island" then
        local types = {1, 2, 3, 4, 1}
        local spots = {vec2(1060, 600), vec2(760, 860), vec2(960, 1000), vec2(1400, 700), vec2(1700, 900)}
        G.island.open = 7
        for i = 1, 5 do G.island:add(G.island:snap(spots[i], types[i]), types[i], 0) end
        local cam = G.island.cam
        cam.center = vec2(1150, 720)
        cam.zoom = .55
        G.island.cam = cam
    end
end

local function init()
    setup_theme()
    for i = 1, SCENES do G.backgrounds[i] = texture.load(scenes[i].background) end
    G.coin = texture.load("icons/coin.png")
    G.influence = texture.load("icons/influence.png")
    island_setup()
    new_game()
    legacy_progress()
    save.read("progress", serialize)
    G.scene = nil
    G.hint = nil
    G.smoke = app.arg("smoke") ~= nil
    G.island.show_footprints = app.arg("footprints") ~= nil
    local screen = app.arg("screen")
    if screen then apply_screen_arg(screen) else story.play("intro", intro) end
end

return {
    title = "Архив Нила",
    id = "nile-archive",
    design = size2(1200, 900),
    max_aspect = 16 / 9,
    landscape = true,
    rotate_text = "«Архив Нила» играется только в альбомной ориентации. Поверните устройство.",
    clear = rgba(14, 43, 46),
    init = init,
    frame = frame_fn,
}
