-- archive_island.lua — the island: an engine city with the player plate,
-- the currencies, the goal card, the building tray and the placement sheet.
local G = require("archive_state")
local content = require("archive_content")
local economy = require("archive_economy")
local progress = require("archive_progress")
local K = require("archive_kit")
local S = K.styles
local hex, rgba = color.hex, color
local COINS, INFLUENCE, CHAPTERS, STARS, ZONES = G.COINS, G.INFLUENCE, G.CHAPTERS, G.STARS, G.ZONES
local MODAL_NONE, MODAL_CAST, MODAL_CHAPTERS = G.MODAL_NONE, G.MODAL_CAST, G.MODAL_CHAPTERS
local WHITE, GOLD_HI, GOLD_LO, GOLD_SEAM, INK_SOFT = K.WHITE, K.GOLD_HI, K.GOLD_LO, K.GOLD_SEAM, K.INK_SOFT

local M = {}

-------------------------------------------------------------------- setup

-- Approximate land outline of island.png: an ellipse minus the pond.
local function buildable(c, p)
    if p.y < 400 or p.y > 1170 then return false end
    if (p - vec2(1230, 800)):ellipse(vec2(760, 530)) > 1 then return false end
    return not rect(1030, 920, 290, 180):contains(p)
end

function M.setup()
    local c = city.new()
    c.defs = content.buildings
    c.tile = content.TILE
    c.clearance = size2(1, 1)   -- half a tile of ground around every base
    c.spacing = 120
    c.path = color(0, 0, 0, 0)   -- no automatic roads between buildings
    c.movable = true
    c.buildable = buildable
    local zones = {{area = rect(580, 200, 600, 1050)}}
    for z = 1, ZONES - 1 do
        zones[z + 1] = {area = rect(800 + z * 380, 200, 380, 1050), cost = purse(economy.shore_costs[z]), needs = purse(0, 0, z)}
    end
    c.zones = zones
    c.cam = camera{center = vec2(900, 650), zoom = .8, min_zoom = .35, max_zoom = 2, cover = true}
    c:init("island.png")
    G.island = c
    G.buildings = c.defs   -- with the sprites loaded
end

---------------------------------------------------------------------- HUD

local function draw_player(at)
    local nefra = story.character("nefra")
    local level, fraction, next_at = progress.level_of(G.wallet[INFLUENCE])
    local avatar = rect(at.x, at.y, 78, 78)
    local plate = rect(avatar:center().x, avatar.y + 14, 250, 54)
    gfx.shadow(plate:offset(vec2(0, 4)), 27, 8, rgba(0, 0, 0, 90))
    gfx.round_rect(plate, 27, rgba(9, 28, 32, 222))
    gfx.round_rect_line(plate, 27, 1.6, rgba(233, 199, 123, 190))
    local info = plate:inflate2(vec2(-14, -7))
    info:cut_left(avatar.w * .5 + 6)
    text.draw(S.name, info:pos(), vec2(0, 0), nefra.name)
    local bar = info:bottom(15)
    gfx.round_rect(bar, 7.5, rgba(0, 0, 0, 120))
    local fill = rect(bar.x, bar.y, math.max(bar.h, bar.w * fraction), bar.h)
    gfx.round_rect_grad(fill, 7.5, hex(0x8FE0F0), hex(0x2F95B3))
    gfx.round_rect_line(bar, 7.5, 1, rgba(233, 199, 123, 120))
    text.fit(S.tiny, bar:inflate2(vec2(-4, 0)), vec2(.5, .5), ("%d / %d"):format(G.wallet[INFLUENCE], next_at))

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
    text.draw(S.badge, star + vec2(0, 1), vec2(.5, .5), tostring(level))
    ui.block(avatar:union(plate))
end

-- The parchment card at the bottom: the next chapter, or what it still needs.
local function draw_goal(c)
    local i, ready = progress.chapter_goal()
    local eyebrow, title
    if not i then eyebrow, title = "АРХИВ СОБРАН", "Переиграйте главы на три звезды"
    elseif ready then eyebrow, title = ("ГЛАВА %d ГОТОВА"):format(i), content.scenes[i].title
    else
        eyebrow = ("ГЛАВА %d · ЕЩЁ %d ВЛИЯНИЯ"):format(i, math.max(0, content.scenes[i].gate - G.wallet[INFLUENCE]))
        title = "Постройте здание за монеты"
    end
    local w = math.max(text.measure(S.goal_title, title).w, text.measure(S.goal_eyebrow, eyebrow).w) + 110
    local r = rect.anchor(c, size2(w, 66), vec2(.5, 1))
    local st = ui.hit(r, 0)
    local inner = K.frame(st.held and r:offset(vec2(0, 2)) or r, true, 16)
    local icon = inner:cut_left(56)
    if ready and i then K.icon_glass(icon:center() + vec2(2, 0), 13) else K.icon_house(icon:center() + vec2(2, 4), 14) end
    text.draw(S.goal_eyebrow, inner:pos() + vec2(0, 11), vec2(0, 0), eyebrow)
    text.draw(S.goal_title, inner:pos() + vec2(0, 27), vec2(0, 0), title)
    local arrow = vec2(inner:max().x - 18, inner:center().y)
    gfx.poly({arrow + vec2(-6, -9), arrow + vec2(6, 0), arrow + vec2(-6, 9)}, INK_SOFT)
    if st.clicked then
        if i and not ready then M.open_tray("story") else G.modal, G.modal_time = MODAL_CHAPTERS, 0 end
    end
end

--------------------------------------------------------------------- tray

-- The build tray pages through one category at a time: the five restorations
-- first, then the decoration catalogue (docs/building-catalogue.md).
M.TRAY_CATEGORIES = {
    {"story", "Восстановление"}, {"all", "Все постройки"}, {"wonder", "Памятники"}, {"building", "Дома и мастерские"},
    {"tree", "Деревья"}, {"bush", "Кусты"}, {"flower", "Цветы"}, {"statue", "Статуи"}, {"water", "Вода"},
    {"garden", "Сад"}, {"camp", "Припасы"}, {"animal", "Животные"}, {"rock", "Камни"},
}
local TRAY_PAGE = 5
M.tray = {category = 1, page = 1}   -- 1 = the restorations

local function plural(n, one, few, many)
    local d, h = n % 10, n % 100
    if d == 1 and h ~= 11 then return one end
    if d >= 2 and d <= 4 and (h < 12 or h > 14) then return few end
    return many
end

local function stars_text(n) return ("%d %s"):format(n, plural(n, "звезда", "звезды", "звёзд")) end

local build_form = ui.form{kind = "column", panel = true, radius = 20, padding = 16, gap = 8, children = {
    {kind = "row", height = 34, gap = 10, children = {
        {kind = "label", id = "budget", role = "budget", grow = 1, text_align = "start"},
        {kind = "button", id = "category_prev", text = "<", width = 44},
        {kind = "label", id = "category", role = "category", width = 230},
        {kind = "button", id = "category_next", text = ">", width = 44},
        {kind = "button", id = "close", text = "Закрыть", width = 100},
    }},
    {kind = "list", id = "stock", direction = "row", gap = 12, item = function(e)
        return {kind = "column", panel = true, role = "parchment", radius = 12, grow = 1, padding = 8, gap = 4, children = {
            {kind = "label", text = e.name, height = 38, wrap = true},
            {kind = "image", image = e.sprite, height = 80},
            {kind = "label", text = e.detail, height = 22},
            {kind = "label", text = ("%d монет"):format(e.coins), height = 22},
            {kind = "button", id = "buy", text = e.action, enabled = e.available, height = 36},
        }}
    end},
    {kind = "row", height = 34, gap = 10, children = {
        {kind = "button", id = "page_prev", text = "Назад", width = 110},
        {kind = "label", id = "page", role = "budget", grow = 1},
        {kind = "button", id = "page_next", text = "Далее", width = 110},
    }},
}}
-- Frames, card text and the tray's roles all come from archive_skin.lua.
local build_skin = K.skin

-- Opens the tray on a category ("story", "tree", ...) and page.
function M.open_tray(category, page)
    for i, c in ipairs(M.TRAY_CATEGORIES) do
        if c[1] == category then M.tray.category = i end
    end
    M.tray.page = page or 1
    G.tray = true
end

-- One tray card: the price, what the building gives and why it can't be bought yet.
local function card(i)
    local d, kind = G.buildings[i], content.kinds[i]
    local unlocked = G.wallet:covers(d.needs)
    local afford = G.wallet:covers(d.cost)
    local full = G.island.count >= 160
    local restoration = i <= content.RESTORATIONS
    local locked = restoration and ("Пройдите главу %d"):format(d.needs[CHAPTERS]) or "Нужно " .. stars_text(kind.stars)
    local action = not unlocked and locked or full and "Остров заполнен" or afford and "Выбрать место" or "Не хватает монет"
    return {id = i, name = d.name, sprite = d.sprite, coins = d.cost[COINS],
        detail = restoration and ("+%d влияния"):format(d.reward[INFLUENCE]) or ("Украшение · %d×%d"):format(d.size.w, d.size.h),
        available = unlocked and afford and not full, action = action}
end

local function draw_tray(r)
    local tray = M.tray
    local filter = M.TRAY_CATEGORIES[tray.category][1]
    local shown = {}
    for i, kind in ipairs(content.kinds) do
        if kind.category == filter or filter == "all" and kind.category ~= "story" then shown[#shown + 1] = i end
    end
    local pages = math.max(1, math.ceil(#shown / TRAY_PAGE))
    tray.page = num.clampi(tray.page, 1, pages)
    local stock = {}
    for at = (tray.page - 1) * TRAY_PAGE + 1, math.min(tray.page * TRAY_PAGE, #shown) do stock[#stock + 1] = card(shown[at]) end
    assert(build_form:set_items("stock", stock))
    build_form:set("budget", ("%d монет · %s"):format(G.wallet[COINS], stars_text(G.wallet[STARS])))
    build_form:set("category", M.TRAY_CATEGORIES[tray.category][2])
    build_form:set("page", ("Страница %d из %d · %d %s"):format(tray.page, pages, #shown, plural(#shown, "постройка", "постройки", "построек")))
    build_form.nodes.page_prev.enabled, build_form.nodes.page_next.enabled = tray.page > 1, tray.page < pages
    local _, height = build_form:measure(r.w, build_skin)
    r = r:bottom(height)
    ui.block(r)
    local event = build_form:draw(r, build_skin)
    G.spots.build_form = build_form
    if not event then return end
    if event.id == "close" then G.tray = false
    elseif event.id == "category_prev" or event.id == "category_next" then
        tray.category = (tray.category - 1 + (event.id == "category_next" and 1 or -1)) % #M.TRAY_CATEGORIES + 1
        tray.page = 1
    elseif event.id == "page_prev" or event.id == "page_next" then
        tray.page = tray.page + (event.id == "page_next" and 1 or -1)
    elseif event.source == "stock" then
        local kind = event.key - 1
        local ok, spot = G.island:find_spot(kind, G.island.cam.center)
        if ok then
            G.island:begin_place(kind, spot)
            G.island.selected = -1
            G.tray = false
        else ui.toast("Откройте берег, чтобы найти свободное место") end
    end
end

---------------------------------------------------------------- placement

local move_form = ui.form{kind = "column", panel = true, padding = 18, gap = 8, children = {
    {kind = "label", id = "name", role = "title", height = 32},
    {kind = "label", text = "Перетащите постройку или коснитесь свободного места", height = 24},
    {kind = "label", id = "payment", height = 24},
    {kind = "row", height = 44, gap = 12, children = {
        {kind = "button", id = "cancel", text = "Отмена", grow = 1},
        {kind = "button", id = "confirm", text = "Подтвердить", accent = true, grow = 1, enabled_field = "valid"},
    }},
}}

-- The confirm/cancel sheet while a building is placed or moved; nothing is
-- charged or moved until Confirm.
local function draw_placement(screen)
    local island = G.island
    local def = G.buildings[island.placing + 1]
    move_form:set("name", def.name)
    local gain = def.reward[INFLUENCE]
    move_form:set("payment", island.moving >= 0 and "Перемещение бесплатно"
        or gain > 0 and ("%d монет · +%d влияния после подтверждения"):format(def.cost[COINS], gain)
        or ("%d монет после подтверждения"):format(def.cost[COINS]))
    move_form:set("confirm", island.moving >= 0 and "Подтвердить" or "Построить")
    move_form.values.valid = island:can_place(island:snap(island.ghost, island.placing), island.placing, island.moving)
    local width = math.min(620, screen.w - 36)
    local _, height = move_form:measure(width)
    local box = rect.anchor(vec2(screen:center().x, screen:max().y - 18), size2(width, height), vec2(.5, 1))
    local action = move_form:draw(box)
    G.spots.move_cancel, G.spots.move_confirm = move_form.boxes.cancel:center(), move_form.boxes.confirm:center()
    if action and action.id == "cancel" then island:cancel()
    elseif action and action.id == "confirm" then
        local confirmed = island:confirm(G.wallet, app.clock())
        if confirmed.result == city.MOVED then
            progress.save()
            ui.toast("Постройка перемещена")
        elseif confirmed.result == city.BUILT then
            progress.save()
            ui.toast(gain > 0 and ("Готово · +%d влияния. Откройте главы, чтобы продолжить."):format(gain) or "Украшение на месте")
        elseif confirmed.result == city.CANT_AFFORD then
            ui.toast("Недостаточно монет. Переиграйте открытую главу.")
        end
    end
end

-------------------------------------------------------------------- frame

function M.frame(screen, world)
    local island = G.island
    local cam = island.cam
    cam.view = app.bleed()   -- the island runs under the status bar and the home indicator
    island.cam = cam
    local ev = island:update(world, G.wallet, app.clock(), app.dt())
    if G.modal == MODAL_NONE then
        if ev.result == city.BUILT then
            progress.save()
            fx.burst(ev.screen, 26, hex(0xF2D29A), 260, 9)
            local gain = G.buildings[island.items[ev.building + 1].type + 1].reward[INFLUENCE]
            ui.toast(gain > 0 and ("Постройка готова · +%d влияния"):format(gain) or "Украшение на месте")
        elseif ev.result == city.CANT_AFFORD then
            ui.toast("Недостаточно монет. Пройдите сцену ещё раз.")
        elseif ev.result == city.BLOCKED then
            ui.toast("Нужно свободное место на открытом берегу")
        elseif ev.result == city.LOCKED_TYPE then
            ui.toast("Сначала пройдите нужную главу или соберите больше звёзд")
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
    if K.capsule(coins:inflate2(vec2(0, -2)), G.coin, tostring(G.wallet[COINS])) then
        ui.toast("80 монет за сцену · бонусы за первую победу, новые звёзды и поиск без ошибок и подсказок")
    end
    if K.capsule(influence:inflate2(vec2(0, -2)), G.influence, tostring(G.wallet[INFLUENCE])) then
        ui.toast("Влияние дают только постройки. Оно открывает главы и не тратится.")
    end

    if story.active() then return end   -- story scenes keep the stage clear, as June's Journey does

    if island.placing >= 0 then
        G.tray = false
        draw_placement(screen)
        return
    end

    -- the left column: people and the next shore
    local x = area.x + 39
    if K.round_button(vec2(x, area.y + 150), 32, K.icon_people, "Герои") then G.modal, G.modal_time = MODAL_CAST, 0 end
    local nxt = island:next_zone(G.wallet)
    if nxt >= 0 then
        local zone = island.zones[nxt + 1]
        local cost = zone.cost[COINS]
        if K.round_button(vec2(x, area.y + 250), 32, K.icon_boat, ("Берег · %d"):format(cost)) then
            if island:unlock(nxt, G.wallet) then
                progress.save()
                story.add(content.merit_shore)
            elseif G.wallet[CHAPTERS] < zone.needs[CHAPTERS] then
                ui.toast(("Сначала пройдите главу %d"):format(zone.needs[CHAPTERS]))
            else
                ui.toast(("Берег стоит %d монет. Переиграйте открытую главу."):format(cost))
            end
        end
    end

    if G.tray then
        draw_tray(area)
        return
    end

    -- bottom: build, the current goal, play
    G.spots.build = vec2(area.x + 46, area:max().y - 56)
    if K.round_button(G.spots.build, 40, K.icon_house, "Строить") then G.tray = true end
    draw_goal(vec2(screen:center().x, area:max().y))
    local play = vec2(area:max().x - 62, area:max().y - 66)
    G.spots.chapters = play
    if K.round_button(play, 54, K.icon_glass, "Главы", true) then G.modal, G.modal_time = MODAL_CHAPTERS, 0 end
    local i, ready = progress.chapter_goal()
    if i and ready then K.notify_dot(play + vec2(40, -40)) end
end

return M
