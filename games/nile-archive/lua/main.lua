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

-- Sprites are 248 px tall inside the old 256 px atlas cells: drawn height and
-- how far below the anchor they reach keep the original placement.
local function building(title, size, coins, influence, path)
    return {name = title, sprite_path = path, height = size * 248 / 256, sink = size * .17, footprint = size2(size * .38, size * .17), cost = purse(coins), reward = purse(0, influence)}
end

local buildings = {
    building("Дом садовника", 160, 70, 10, "buildings/0.png"),
    building("Храм Исиды", 210, 160, 30, "buildings/1.png"),
    building("Архив", 190, 130, 25, "buildings/2.png"),
    building("Фонтан", 150, 60, 10, "buildings/3.png"),
    building("Мастерская", 170, 100, 15, "buildings/4.png"),
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

local MODAL_NONE, MODAL_WIN, MODAL_CAST = 0, 1, 2

local G = {
    wallet = purse(),
    wins = {0, 0, 0},
    island = nil,                 -- the engine city
    scene = nil,                  -- 1-based chapter, nil = island
    found = {},                   -- found[i] = time the item was found
    hint = nil,
    cam = nil,                    -- hidden-object camera
    focus = vec2(), focus_time = 0,
    modal = MODAL_NONE, modal_time = 0,
    backgrounds = {}, coin = nil, influence = nil,
    serif = nil, sans = nil, sans_bold = nil,
    theme = nil, eyebrow = nil, heading = nil, body = nil, muted = nil, number = nil, item = nil,
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
    G.island:add(vec2(850, 650), 0, 0)
end

local function serialize(s)
    s:int("version", 2)
    G.wallet[COINS] = s:int("coins", G.wallet[COINS])
    G.wallet[INFLUENCE] = s:int("influence", G.wallet[INFLUENCE])
    G.wins = s:ints("wins", G.wins)
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

local function open_scene(i)
    G.scene = i
    G.found = {}
    G.hint = nil
    G.island.selected = -1
    G.cam = camera{center = vec2(600, 400), zoom = 0, world = size2(1200, 800)}
    fx.clear()
end

local function go_home()
    G.scene = nil
    G.modal = MODAL_NONE
    fx.clear()
end

local function found_count()
    local n = 0
    for i = 1, ITEMS do if G.found[i] then n = n + 1 end end
    return n
end

local function show_hint()
    for i = 1, ITEMS do
        if not G.found[i] then
            G.hint = i
            G.focus = scenes[G.scene].at[i]
            G.focus_time = .6
            return
        end
    end
end

local function scene_tap(screen)
    local sc = scenes[G.scene]
    local p = G.cam:to_world(screen)
    for i = 1, ITEMS do
        if not G.found[i] and (p - sc.at[i]):ellipse(sc.radius[i]) <= 1 then
            G.found[i] = app.time()
            if G.hint == i then G.hint = nil end
            fx.sparkle(G.cam:to_screen(sc.at[i]), 40 * G.cam.zoom + 20, hex(0xFFE7A0))
            if found_count() == ITEMS then
                G.wallet = G.wallet + scene_reward
                G.wins[G.scene] = G.wins[G.scene] + 1
                story.play(("chapter-%d"):format(G.scene - 1), sc.clue)   -- the clue, the first time
                save_progress()
                G.modal = MODAL_WIN
                G.modal_time = 0
            end
            return
        end
    end
end

----------------------------------------------------------------- widgets

local function amount(pos, pivot, icon, str, s)
    local icon_size = s.size * 1.25
    local w = icon_size + 6 + text.measure(s, str).w
    local box = rect.anchor(pos, size2(w, icon_size), pivot)
    gfx.image(icon, box:left(icon_size), color.WHITE)
    text.draw(s, box:offset(vec2(icon_size + 6, 0)):point(vec2(0, .5)), vec2(0, .5), str)
    return box
end

local function pill(area, align, str)
    local s = G.eyebrow:sized(13)
    local r = area:align(size2(text.measure(s, str).w + 28, 34), align)
    gfx.round_rect(r, 17, rgba(24, 59, 57, 232))
    gfx.round_rect_line(r, 17, 1, rgba(229, 203, 135, 100))
    text.draw(s, r:center(), vec2(.5, .5), str)
end

local function icon_button(r, glyph)
    local st = ui.button_frame(r, 0)
    text.draw(G.theme.button:sized(28), (st.held and r:offset(vec2(0, 1)) or r):center(), vec2(.5, .54), glyph)
    return st.clicked
end

----------------------------------------------------------------- screens

local function draw_header(bar)
    gfx.rect_grad(bar, hex(0x1B4343), hex(0x153637))
    gfx.rect(bar:bottom(1), rgba(191, 166, 107, 70))
    local inner = bar:inflate2(vec2(-18, -6))
    local brand = inner:cut_left(360)
    text.draw(G.eyebrow, brand:pos(), vec2(0, 0), "ТАЙНЫ ЗАБЫТОГО ОСТРОВА")
    text.draw(G.theme.title, brand:point(vec2(0, 1)), vec2(0, .92), "Архив Нила")

    local r = inner:cut_right(120)
    amount(r:point(vec2(1, .5)), vec2(1, .5), G.influence, tostring(G.wallet[INFLUENCE]), G.number)
    r = inner:cut_right(130)
    amount(r:point(vec2(1, .5)), vec2(1, .5), G.coin, tostring(G.wallet[COINS]), G.number)
    inner:cut_right(18)
    if ui.button(inner:cut_right(150):align(size2(150, 44), vec2(1, .5)), "Персонажи", 0) then G.modal, G.modal_time = MODAL_CAST, 0 end
    if G.scene then
        inner:cut_right(10)
        if ui.button(inner:cut_right(170):align(size2(170, 44), vec2(1, .5)), "‹ На остров", 0) then go_home() end
    end
end

local function draw_chapters(panel)
    ui.panel(panel)
    local r = panel:inflate(-16)

    local intro_box = r:cut_top(150)
    local face = intro_box:cut_left(92)
    local portrait = story.character("nefra").portrait
    gfx.image(portrait, face:fit(texture.size(portrait)), color.WHITE)
    intro_box:cut_left(10)
    text.draw(G.eyebrow, intro_box:pos(), vec2(0, 0), "ЕГИПЕТ · 196 ДО Н. Э.")
    text.box(G.heading:sized(21), rect(intro_box.x, intro_box.y + 20, intro_box.w, 52), vec2(0, 0), "Остров, который помнит")
    text.box(G.muted:sized(13), rect(intro_box.x, intro_box.y + 74, intro_box.w, 76), vec2(0, 0),
             "Вы — Нефра. Стройте поместье, повышайте влияние и ищите следы исчезнувшей библиотеки.")

    r:cut_top(6)
    text.draw(G.heading, r:pos(), vec2(0, 0), "Пропавший архив")
    r:cut_top(44)
    for i = 1, SCENES do
        local sc = scenes[i]
        local card = r:cut_top(math.min(196, r.h / (SCENES - i + 1)))
        gfx.rect(card:top(1), rgba(173, 194, 155, 40))
        local c = card:inflate2(vec2(0, -10))
        text.draw(G.eyebrow, c:pos(), vec2(0, 0), ("ГЛАВА 0%d%s"):format(i, G.wins[i] > 0 and "  ★" or ""))
        text.draw(G.heading:sized(19), c:pos() + vec2(0, 18), vec2(0, 0), sc.title)
        text.box(G.muted, rect(c.x, c.y + 46, c.w, c:max().y - c.y - 46 - 54), vec2(0, 0), sc.teaser)
        local locked = G.wallet[INFLUENCE] < sc.gate
        local label = locked and ("Нужно %d влияния"):format(sc.gate) or (G.wins[i] > 0 and "Играть снова" or "Найти предметы ›")
        local flags = locked and ui.DISABLED or ((i == 1 or G.wins[i] == 0) and ui.ACCENT or 0)
        if ui.button(c:bottom(46), label, flags) then open_scene(i) end
    end
end

local function draw_shop(area)
    for i, d in ipairs(buildings) do
        local card = area:col(#buildings, i - 1, 10)
        local st = ui.button_frame(card, G.island.selected == i - 1 and ui.ACTIVE or 0)
        if st.clicked then G.island.selected = G.island.selected == i - 1 and -1 or i - 1 end
        local c = card:inflate(-8)
        local pic = c:cut_left(c.h * .62)
        gfx.image(d.sprite, pic:fit(texture.size(d.sprite)), color.WHITE)
        c:cut_left(6)
        text.box(G.heading:sized(17), c:cut_top(c.h * .55), vec2(0, 1), d.name)
        local line = c:cut_top(22)
        local cost = amount(line:point(vec2(0, .5)), vec2(0, .5), G.coin, tostring(d.cost[COINS]), G.number:sized(14))
        amount(cost:point(vec2(1, .5)) + vec2(10, 0), vec2(0, .5), G.influence, ("+%d"):format(d.reward[INFLUENCE]), G.number:sized(14))
    end
end

local function island_frame(body, world)
    local side = body:cut_right(math.min(270, body.w * .26))
    body:cut_right(12)
    local shop = body:cut_bottom(112)
    body:cut_bottom(10)
    local footer = body:cut_bottom(50)
    body:cut_bottom(8)
    local view = body
    local island = G.island

    local cam = island.cam
    cam.view = view
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

    gfx.shadow(view:offset(vec2(0, 8)), 14, 26, rgba(0, 0, 0, 70))
    island:draw(world, app.clock())
    gfx.round_rect_line(view:inflate(2), 14, 4, hex(0x102F32))
    fx.draw()

    local overlay = view:inflate(-10)
    pill(overlay, vec2(0, 0), ("ОСТРОВ ФИЛА · ЗОНА %d / %d"):format(island:open_count(), ZONES))
    pill(overlay, vec2(1, 0), island.selected < 0 and "Тяните, чтобы исследовать" or "Коснитесь места для постройки")
    local zoom = overlay:align(size2(102, 46), vec2(1, 1))
    if icon_button(zoom:left(46), "−") then island.cam = island.cam:zoom_at(1 / 1.25, view:center()) end
    if icon_button(zoom:right(46), "+") then island.cam = island.cam:zoom_at(1.25, view:center()) end

    local expand = footer:cut_right(270)
    text.box(G.muted, footer:inflate2(vec2(-4, 0)), vec2(0, .5),
             island.selected < 0 and "Выберите здание и коснитесь свободного места на острове."
                 or ("Строится: %s. Повторное нажатие на карточку снимает выбор."):format(buildings[island.selected + 1].name))
    local nxt = island:next_zone(G.wallet)
    if nxt < 0 then
        ui.button(expand, "Весь остров открыт", ui.DISABLED)
    else
        local cost = island.zones[nxt + 1].cost
        if ui.button(expand, ("Открыть берег · %d монет"):format(cost[COINS]), 0) then
            if island:unlock(nxt, G.wallet) then
                save_progress()
                story.add(merit_shore)
            else
                ui.toast("Нужно больше монет — пройдите сцену")
            end
        end
    end
    draw_shop(shop)
    draw_chapters(side)
end

local function scene_frame(body, world, dt)
    local sc = scenes[G.scene]
    local strip = body:cut_bottom(64)
    body:cut_bottom(10)
    local view = body

    G.cam.view = view
    G.cam.min_zoom = G.cam:fit_zoom()
    G.cam.max_zoom = G.cam.min_zoom * 3
    G.cam = G.cam:clamp()
    if G.modal == MODAL_NONE then
        G.cam = G.cam:input(world):clamp()
        if world.tap and view:contains(world.pos) then scene_tap(world.pos) end
    end
    if G.focus_time > 0 then
        G.focus_time = G.focus_time - dt
        G.cam = G.cam:look(G.cam.center:approach(G.focus, 10, dt)):clamp()
    end

    gfx.round_rect(view, 14, hex(0x0C2629))
    gfx.clip(view)
    G.cam:draw_texture(G.backgrounds[G.scene])
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
    gfx.round_rect_line(view:inflate(2), 14, 4, hex(0x102F32))

    local overlay = view:inflate(-10)
    pill(overlay, vec2(0, 0), ("%s · %d/%d"):format(sc.title, found_count(), ITEMS))
    pill(overlay, vec2(1, 0), "Найдите предметы")
    local zoom = overlay:align(size2(102, 46), vec2(1, 1))
    if icon_button(zoom:left(46), "−") then G.cam = G.cam:zoom_at(1 / 1.25, view:center()) end
    if icon_button(zoom:right(46), "+") then G.cam = G.cam:zoom_at(1.25, view:center()) end

    local hint = strip:cut_right(170)
    strip:cut_right(10)
    if ui.button(hint, "Подсказка", ui.ACCENT) then show_hint() end
    ui.panel_ex(strip, hex(0x1B3F3E), hex(0x173A39), color.CLEAR, 12)
    local chips = strip:inflate(-6)
    for i = 1, ITEMS do
        local chip = chips:col(ITEMS, i - 1, 6)
        local done = G.found[i] ~= nil
        gfx.round_rect(chip, 9, done and rgba(49, 83, 74, 110) or hex(0x31534A))
        local label = text.fit(G.item:faded(done and .6 or 0), chip:inflate(-6), vec2(.5, .5), sc.names[i])
        if done then gfx.line(label:point(vec2(0, .55)), label:point(vec2(1, .55)), 2, rgba(244, 232, 202, 160)) end
    end
end

local function win_dialog(t)
    local sc = scenes[G.scene]
    local s = app.screen()
    local box = rect.centered(s:center(), size2(620, 340))
    box = box:offset(vec2(0, (1 - ease.out_cubic(t * 3)) * 40))
    ui.panel_ex(box, hex(0x1F4645), hex(0x183B3A), hex(0xD4B775), 20)
    local r = box:inflate(-30)
    text.draw(G.eyebrow, r:pos(), vec2(0, 0), "ФРАГМЕНТ АРХИВА НАЙДЕН")
    r:cut_top(22)
    text.draw(G.theme.title:sized(34), r:pos(), vec2(0, 0), "Память возвращается")
    r:cut_top(54)
    local button = r:cut_bottom(50)
    local reward = r:cut_bottom(40)
    local clue = #sc.clue > 1 and ("%s «%s»"):format(sc.clue[1][2], sc.clue[2][2]) or sc.clue[1][2]
    text.box(G.body:sized(18), r, vec2(0, 0), clue)
    local label = text.draw(G.body, reward:point(vec2(0, .5)), vec2(0, .5), "Награда:")
    local coins = amount(label:point(vec2(1, .5)) + vec2(12, 0), vec2(0, .5), G.coin, tostring(scene_reward[COINS]), G.number)
    amount(coins:point(vec2(1, .5)) + vec2(18, 0), vec2(0, .5), G.influence, tostring(scene_reward[INFLUENCE]), G.number)
    if ui.button(button:align(size2(280, 50), vec2(0, .5)), "Вернуться на остров", ui.ACCENT) then go_home() end
end

local function cast_dialog(t)
    local s = app.screen()
    local box = rect.centered(s:center(), size2(math.min(1000, s.w - 60), math.min(640, s.h - 80)))
    box = box:offset(vec2(0, (1 - ease.out_cubic(t * 3)) * 40))
    ui.panel_ex(box, hex(0x1F4645), hex(0x183B3A), hex(0xD4B775), 20)
    local r = box:inflate(-24)
    local head = r:cut_top(50)
    text.draw(G.theme.title:sized(34), head:point(vec2(0, .5)), vec2(0, .5), "Люди острова")
    if ui.button(head:align(size2(50, 46), vec2(1, .5)), "×", 0) then G.modal = MODAL_NONE end
    r:cut_top(10)
    for i, who in ipairs(cast) do
        local col = r:col(#cast, i - 1, 20)
        local caption = col:cut_bottom(92)
        gfx.glow(col:point(vec2(.5, .78)), col.w * .45, rgba(242, 210, 140, 40), rgba(242, 210, 140, 0))
        local face = story.character(who.id).portrait
        local fs = texture.size(face)
        gfx.image(face, col:align(fs:scale(fs:fit(col:size())), vec2(.5, 1)), color.WHITE)
        text.draw(G.heading:sized(25), caption:point(vec2(.5, 0)), vec2(.5, 0), who.name)
        text.box(G.muted, caption:bottom(54):inflate2(vec2(-10, 0)), vec2(.5, 0), who.role)
    end
end

------------------------------------------------------------------ frame

local function frame(dt)
    local inp = input.get()
    local world = input.world()
    local talking = story.active()
    if G.modal ~= MODAL_NONE or talking then world = input{pos = inp.pos, pinch = 1} end
    if inp.back and not talking then
        if G.modal == MODAL_WIN then go_home()
        elseif G.modal ~= MODAL_NONE then G.modal = MODAL_NONE
        elseif G.scene then go_home() end
    end
    fx.update(dt)

    local screen = app.screen()
    gfx.rect_grad(screen, hex(0x12393B), hex(0x0E2B2E))
    local header = screen:cut_top(66)
    local body = screen:inflate(-12)

    ui.set_enabled(G.modal == MODAL_NONE and not talking)
    if G.scene then scene_frame(body, world, dt) else island_frame(body, world) end
    draw_header(header)
    ui.set_enabled(true)

    if G.modal ~= MODAL_NONE and not talking then   -- a dialogue goes first: the reward waits for it
        G.modal_time = G.modal_time + dt
        ui.modal_backdrop(G.modal_time * 4)
        if G.modal == MODAL_WIN then win_dialog(G.modal_time) else cast_dialog(G.modal_time) end
    end
    story.frame(dt)
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
    G.eyebrow = style{font = G.sans_bold, size = 12, fill = hex(0xB6C9BC), tracking = 1.6}
    G.heading = style{font = G.serif, size = 22, fill = cream, shadow = rgba(0, 0, 0, 120), shadow_offset = vec2(0, 2), shadow_blur = 2}
    G.number = style{font = G.sans_bold, size = 19, fill = cream, outline = ink, outline_width = 1}
    G.item = style{font = G.sans_bold, size = 16, fill = cream}

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
        dim = rgba(6, 28, 33, 215), toast_bg = hex(0xF0D49D), toast_text = hex(0x203C36), radius = 10,
    }
    ui.set_theme(G.theme)
    story.setup(cast, story_style{
        text = style{font = G.sans, size = 22, fill = hex(0x203C36)},
        name = style{font = G.sans_bold, size = 17, fill = hex(0xFFF6E0)},
        bubble = hex(0xFBF1DA), edge = hex(0x9C7A3C), dim = rgba(6, 28, 33, 120),
        portrait_height = .64, skip = "Пропустить",
    })
end

-- Debug/QA entry points used to capture screenshots: --screen island|build|scene0..2|cast|win
local function apply_screen_arg(screen)
    G.wallet[INFLUENCE] = 100
    G.wallet[COINS] = 900
    if screen:sub(1, 5) == "scene" then
        open_scene(num.clampi((tonumber(screen:sub(6)) or 0) + 1, 1, SCENES))
        if app.arg("found") then
            for _, i in ipairs({1, 3, 4, 6}) do G.found[i] = 0 end
            show_hint()
        end
    elseif screen == "build" then
        G.island.selected = 1
    elseif screen == "cast" then
        G.modal, G.modal_time = MODAL_CAST, 1
    elseif screen == "win" then
        open_scene(2)
        for i = 1, ITEMS do G.found[i] = 0 end
        G.modal, G.modal_time = MODAL_WIN, 1
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
        for i = 1, 5 do G.island:add(spots[i], types[i], 0) end
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
    frame = frame,
}
