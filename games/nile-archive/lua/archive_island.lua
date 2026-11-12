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
    c.fog_clouds = true
    c.fog = rgba(239, 241, 228, 240)
    c.clearance = size2(0, 0)   -- adjacent bases may share an edge
    c.spacing = 120
    c.path = color(0, 0, 0, 0)   -- no automatic roads between buildings
    c.movable = true
    c.buildable = buildable
    local zones = {{area = rect(580, 200, 600, 1050)}}
    local shores = {"Тростниковый берег", "Пальмовый берег", "Дальний берег"}
    for z = 1, ZONES - 1 do
        local area = rect(800 + z * 380, 200, 380, 1050)
        zones[z + 1] = {area = area, name = shores[z], marker = vec2(area:center().x, 640),
                        cost = purse(economy.shore_costs[z]), needs = purse(0, 0, z)}
    end
    c.zones = zones
    c.cam = camera{center = vec2(900, 650), zoom = .8, min_zoom = .35, max_zoom = 2, cover = true}
    c:init("island.png")
    G.island = c
    G.buildings = c.defs   -- with the sprites loaded
    M.town_setup()
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

-- The parchment card at the bottom: the next search, or what it still needs.
local function draw_goal(c)
    local i, blocked, restore = progress.chapter_goal()
    local eyebrow, title
    if not i then eyebrow, title = "ИСТОРИЯ ЗАВЕРШЕНА", "След ведёт вверх по Нилу"
    elseif blocked then eyebrow, title = "СЛЕДУЮЩАЯ ЦЕЛЬ", blocked
    elseif content.cache_chapter(i) then eyebrow, title = "ТАЙНИК ГОТОВ", content.scenes[i].title
    else
        eyebrow = G.wins[i] == 0 and ("ПОИСК %d"):format(i)
            or G.stars[i] < 3 and "СОБЕРИТЕ ТРИ ЗВЕЗДЫ" or "ПОВТОРИТЕ ПОИСК РАДИ УЛИКИ"
        title = content.scenes[i].title
    end
    local w = math.max(text.measure(S.goal_title, title).w, text.measure(S.goal_eyebrow, eyebrow).w) + 110
    local r = rect.anchor(c, size2(w, 66), vec2(.5, 1))
    local st = ui.hit(r, 0)
    local inner = K.frame(st.held and r:offset(vec2(0, 2)) or r, true, 16)
    local icon = inner:cut_left(56)
    if restore then K.icon_house(icon:center() + vec2(2, 4), 14) else K.icon_glass(icon:center() + vec2(2, 0), 13) end
    text.draw(S.goal_eyebrow, inner:pos() + vec2(0, 11), vec2(0, 0), eyebrow)
    text.draw(S.goal_title, inner:pos() + vec2(0, 27), vec2(0, 0), title)
    local arrow = vec2(inner:max().x - 18, inner:center().y)
    gfx.poly({arrow + vec2(-6, -9), arrow + vec2(6, 0), arrow + vec2(-6, 9)}, INK_SOFT)
    if st.clicked then
        if restore then
            local projects = i and i > 5 and i <= content.SCENES and economy.lock(G, i) == "influence"
            M.open_tray(projects and "projects" or "story")
        else G.open_modal(MODAL_CHAPTERS) end
    end
end

--------------------------------------------------------------------- tray

-- The build tray scrolls through one category at a time: the five restorations
-- first, then the decoration catalogue (docs/building-catalogue.md).
M.TRAY_CATEGORIES = {
    {"story", "Восстановление"}, {"projects", "Работы на острове"}, {"all", "Все постройки"}, {"wonder", "Памятники"}, {"building", "Дома и мастерские"},
    {"tree", "Деревья"}, {"bush", "Кусты"}, {"flower", "Цветы"}, {"statue", "Статуи"}, {"water", "Вода"},
    {"garden", "Сад"}, {"camp", "Припасы"}, {"animal", "Животные"}, {"rock", "Камни"},
}
M.tray = {category = 1}   -- 1 = the restorations

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
    {kind = "list", id = "stock", scroll = true, height = 454, gap = 8, item = function(e)
        return {kind = "row", panel = true, role = "parchment", radius = 12, padding = 8, gap = 14, align = "center", children = {
            {kind = "image", image = e.sprite, width = 108, height = 68},
            {kind = "column", grow = 1, gap = 3, children = {
                {kind = "label", text = e.name, wrap = true, text_align = "start"},
                {kind = "label", text = ("%s · %d монет"):format(e.detail, e.coins), wrap = true, text_align = "start"},
            }},
            {kind = "button", id = "buy", text = e.action, enabled = e.available, width = 260, height = 44},
        }}
    end},
}}
local build_skin = K.skin

local project_confirm = ui.form{kind = "column", panel = true, radius = 20, padding = 24, gap = 12, children = {
    {kind = "label", id = "title", role = "category", wrap = true},
    {kind = "label", id = "detail", role = "budget", wrap = true},
    {kind = "row", gap = 12, height = 56, children = {
        {kind = "button", id = "cancel", text = "Отмена", grow = 1},
        {kind = "button", id = "confirm", text = "Выполнить", grow = 1, accent = true},
    }},
}}

-- Opens the tray on a category, with an optional starting group for captures.
function M.open_tray(category, review_page)
    local tray = M.tray
    for i, c in ipairs(M.TRAY_CATEGORIES) do
        if c[1] == category then tray.category = i end
    end
    tray.dirty, tray.review_page, tray.pending = true, review_page, nil
    G.tray = true
end

-- One tray card: the price, what the building gives and why it can't be bought yet.
local function card(i)
    local d, kind = G.buildings[i], content.kinds[i]
    local unlocked = G.wallet:covers(d.needs)
    local afford = G.wallet:covers(d.cost)
    local full = G.island.count >= 160
    local restoration = i <= content.RESTORATIONS
    local owned = restoration and G.restored[i]
    local searches = d.needs[CHAPTERS]
    local locked = restoration and ("Нужно завершить %d %s"):format(searches, plural(searches, "поиск", "поиска", "поисков"))
        or "Нужно " .. stars_text(kind.stars)
    local action = owned and "Уже восстановлено" or not unlocked and locked or full and "Остров заполнен"
        or afford and "Выбрать место" or "Не хватает монет"
    local gain = d.reward[INFLUENCE]
    local detail = ("+%d влияния"):format(gain)
    if not restoration then detail = ("%d×%d · %s"):format(d.size.w, d.size.h, detail) end
    return {id = i, name = d.name, sprite = d.sprite, coins = d.cost[COINS], detail = detail,
        available = not owned and unlocked and afford and not full, action = action}
end

local function refresh_tray(tray)
    local filter = M.TRAY_CATEGORIES[tray.category][1]
    local stock = {}
    for i, kind in ipairs(content.kinds) do
        if kind.category == filter or filter == "all" and kind.category ~= "story" then stock[#stock + 1] = card(i) end
    end
    if filter == "projects" then
        local building_types = {3, 4, 5, 2, 1, 3, 4, 5, 2, 1}
        for i, project in ipairs(economy.projects) do
            local lock = economy.project_lock(G, i)
            local action = lock == "done" and "Выполнено" or lock == "chapter" and "Завершите предыдущую главу"
                or lock == "coins" and "Не хватает монет" or "Выбрать"
            stock[#stock + 1] = {id = "project-" .. i, name = project.name,
                sprite = G.buildings[building_types[i]].sprite, coins = project.coins,
                detail = ("+%d влияния"):format(project.influence), available = not lock, action = action}
        end
    end
    assert(build_form:set_items("stock", stock))
    build_form:set("budget", ("%d монет · %s"):format(G.wallet[COINS], stars_text(G.wallet[STARS])))
    build_form:set("category", M.TRAY_CATEGORIES[tray.category][2])
    local index = num.clampi((math.floor(tray.review_page or 1) - 1) * 5 + 1, 1, math.max(1, #stock))
    build_form:scroll_to("stock", stock[index] and stock[index].id)
    tray.dirty, tray.review_page = false, nil
end

local function draw_tray(r)
    local tray = M.tray
    if tray.pending then
        local project = economy.projects[tray.pending]
        project_confirm:set("title", project.name)
        project_confirm:set("detail", ("%d монет · +%d влияния"):format(project.coins, project.influence))
        local _, height = project_confirm:measure(r.w, build_skin)
        r = r:bottom(height)
        ui.block(r)
        local event = project_confirm:draw(r, build_skin, {interactive = G.modal == MODAL_NONE, reduced_motion = G.reduced_motion})
        G.spots.project_form = project_confirm
        if event and event.id == "cancel" then tray.pending = nil; tray.dirty = true
        elseif event and event.id == "confirm" then
            if economy.claim_project(G, tray.pending) then
                progress.save()
                ui.toast(("Работы завершены · +%d влияния"):format(project.influence))
            else
                ui.toast("Работы больше недоступны")
            end
            tray.pending, tray.dirty = nil, true
        end
        return
    end
    if tray.dirty or not G.spots.build_form then refresh_tray(tray) end
    local _, height = build_form:measure(r.w, build_skin)
    r = r:bottom(height)
    ui.block(r)
    local event = build_form:draw(r, build_skin, {interactive = G.modal == MODAL_NONE, reduced_motion = G.reduced_motion})
    G.spots.build_form = build_form
    if not event then return end
    if event.id == "close" then G.tray = false
    elseif event.id == "category_prev" or event.id == "category_next" then
        tray.category = (tray.category - 1 + (event.id == "category_next" and 1 or -1)) % #M.TRAY_CATEGORIES + 1
        tray.dirty = true
    elseif event.source == "stock" then
        if M.TRAY_CATEGORIES[tray.category][1] == "projects" then
            local id = tonumber(event.key:match("^project%-(%d+)$"))
            if id and not economy.project_lock(G, id) then tray.pending = id end
        elseif M.town:begin(event.key - 1, false) then
            G.island.selected = -1
            G.tray = false
        end
    end
end

---------------------------------------------------------------- placement

local function finish_purchase(kind)
    if kind <= content.RESTORATIONS then
        G.restored[kind] = true
        local beat = content.restoration_beats[kind]
        if beat then progress.play(beat) end
    end
    progress.save()
    local gain = G.buildings[kind].reward[INFLUENCE]
    ui.toast(gain > 0 and ("Постройка готова · +%d влияния"):format(gain) or "Украшение на месте")
end

-------------------------------------------------------------------- frame

-- The island on the engine's shared town screen (engine/town.lua), laid out
-- by data/town.json like Relic Rush and Christmas Market. The archive adds its
-- player plate, the cast button and the goal card between Build and Play.
local function shore(z)
    if G.island:unlock(z, G.wallet) then
        progress.save()
        story.add(content.merit_shore)
    elseif G.wallet[CHAPTERS] < G.island.zones[z + 1].needs[CHAPTERS] then
        local n = G.island.zones[z + 1].needs[CHAPTERS]
        ui.toast(("Нужно завершить %d %s"):format(n, plural(n, "поиск", "поиска", "поисков")))
    else
        ui.toast(("Берег стоит %d монет. Переиграйте открытую главу."):format(G.island.zones[z + 1].cost[COINS]))
    end
end

local function placement_words(kind)
    local def = G.buildings[kind]
    local gain = def.reward[INFLUENCE]
    return G.island.moving >= 0 and "Перемещение бесплатно"
        or gain > 0 and ("%d монет · +%d влияния после подтверждения"):format(def.cost[COINS], gain)
        or ("%d монет после подтверждения"):format(def.cost[COINS])
end

function M.town_setup()
    local town = require("town")
    M.town = town.new(G.island, town.load("town.json"), {
        skin = K.skin,
        wallet = function() return G.wallet end,
        notice = function(text)
            if text == M.town.cfg.texts.placing and G.island.placing >= 0 then text = text .. " · " .. placement_words(G.island.placing + 1) end
            ui.toast(text)
        end,
        capsules = function()
            local function plus(r) K.plus_badge(vec2(r:max().x - r.h * .5, r:center().y), r.h * .5 - 3) end
            return {
                {icon = G.coin, value = tostring(G.wallet[COINS]), width = 170, reserve = 42 * .7, decorate = plus,
                 note = "80 монет за сцену · бонусы за первую победу, новые звёзды и поиск без ошибок и подсказок"},
                {icon = G.influence, value = tostring(G.wallet[INFLUENCE]), width = 150, reserve = 42 * .7, decorate = plus,
                 note = "Влияние дают постройки и украшения. Оно открывает поиски и не тратится."},
            }
        end,
        build = function() M.open_tray() end,
        play = function() G.open_modal(MODAL_CHAPTERS) end,
        draw_middle = function(at) draw_goal(at) end,
        hide_bottom = function() return G.tray end,
        about = function(item)
            local def = G.buildings[G.island.items[item + 1].type + 1]
            local gain = def.reward[INFLUENCE]
            return gain > 0 and ("%s\n+%d влияния"):format(def.name, gain) or def.name
        end,
        zone = shore,
        event = function(ev)
            if ev.result == city.CANT_AFFORD then ui.toast("Недостаточно монет. Пройдите сцену ещё раз.")
            elseif ev.result == city.BLOCKED then ui.toast("Нужно свободное место на открытом берегу")
            elseif ev.result == city.LOCKED_TYPE then ui.toast("Сначала пройдите нужную главу или соберите больше звёзд") end
        end,
        can_buy = function(kind) return not (kind < content.RESTORATIONS and G.restored[kind + 1]) end,
        placed = function(ev, fresh)
            if fresh then finish_purchase(G.island.items[ev.building + 1].type + 1)
            else progress.save(); ui.toast("Постройка перемещена") end
            if not G.reduced_motion then fx.burst(ev.screen, 26, hex(0xF2D29A), 260, 9) end
        end,
        bubble_text = function() return K.skin:text("card_title", 18) end,
        reduced_motion = function() return G.reduced_motion end,
        draw_world = function(full)
            -- a soft vignette keeps the corners readable under the HUD
            local screen = app.screen()
            gfx.rect_grad(rect(full.x, full.y, full.w, screen.y - full.y + 120), rgba(6, 22, 26, 150), rgba(6, 22, 26, 0))
            local low = screen:max().y - 150
            gfx.rect_grad(rect(full.x, low, full.w, full:max().y - low), rgba(6, 22, 26, 0), rgba(6, 22, 26, 150))
            fx.draw()
        end,
        extras = function(screen)
            local area = screen:inflate(-18)
            draw_player(area:pos())
            if K.round_button(vec2(area.x + 39, area.y + 150), 32, K.icon_people, "Герои") then G.open_modal(MODAL_CAST) end
            local island = G.island
            if island.placing >= 0 then
                G.tray = false
                G.spots.move_cancel = M.town.placement_form.boxes.cancel:center()
                G.spots.move_confirm = M.town.placement_form.boxes.confirm:center()
                return
            end
            if G.tray then draw_tray(area); return end
            local i, blocked = progress.chapter_goal()
            if i and not blocked then K.notify_dot(M.town.buttons.play + vec2(48, -46)) end
        end,
    })
    G.spots.build, G.spots.chapters = M.town.buttons.build, M.town.buttons.play
end

function M.frame(_, world)
    M.town:frame(world, app.dt(), G.modal == MODAL_NONE and not story.active())
    G.spots.build, G.spots.chapters = M.town.buttons.build, M.town.buttons.play
end

return M
