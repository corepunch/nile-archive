-- archive_dialogs.lua — the popups over the island and the scene: chapter
-- won, the chapter browser, pause and the cast gallery.
local G = require("archive_state")
local content = require("archive_content")
local economy = require("archive_economy")
local progress = require("archive_progress")
local scene = require("archive_scene")
local island = require("archive_island")
local K = require("archive_kit")
local S = K.styles
local beats = require("archive_story")
local scenes, cast = content.scenes, content.cast
local MODAL_NONE, MODAL_WIN, MODAL_CHAPTERS, MODAL_PAUSE = G.MODAL_NONE, G.MODAL_WIN, G.MODAL_CHAPTERS, G.MODAL_PAUSE
local WHITE = K.WHITE

local M = {}

-- Game Center boards (engine/leaderboard.lua): lifetime influence, and each search's best score.
M.boards = require("leaderboard").boards{skin = K.skin, width = 520, texts = {
    everyone = "Все", friends = "Друзья", close = "Закрыть", native = "Game Center", you = "(вы)",
    loading = "Загрузка...", empty = "Пока нет результатов. Будьте первым!",
    empty_friends = "Никто из друзей ещё не играл.",
    sign_in = "Войдите в Game Center, чтобы сравнить себя с другими игроками.",
    sign_in_friends = "Войдите в Game Center, чтобы увидеть друзей.",
}}
local function open_influence_board() M.boards:open("influence", "Влияние") end
local function open_search_board(i) M.boards:open(("search_%d"):format(i), scenes[i].title) end

-- A framed box with a ribbon title, popping in as G.dialog arrives.
local function popup(w, h, title)
    local s = app.screen()
    local box = rect.centered(s:center() + vec2(0, 14), size2(math.min(w, s.w - 40), math.min(h, s.h - 70)))
    local k = .9 + .1 * G.dialog.pop
    box = box:scale(k)
    local inner = K.frame(box, false, 24)
    K.ribbon(vec2(box:center().x, box.y + 2), math.min(420, box.w * .6), title)
    return box, inner
end

local function close_button(box)
    if K.round_button(box:point(vec2(1, 0)) + vec2(-6, 6), 22, K.icon_close) then G.modal = MODAL_NONE end
end

local function win_dialog()
    local sc = scenes[G.scene]
    local res = G.result or {score = G.score, time = G.clock, stars = 1}
    local key = sc.clues[res.clue or G.clues[G.scene]]
    local clue = key and beats[key].note or "Записи по этой сцене появятся в журнале по ходу расследования."
    local clue_h = text.box_size(S.ink_body, 560 - 80, clue).h
    local payout = res.payout or economy.reward(G.wins[G.scene], G.stars[G.scene], res.stars, false)
    local _, r = popup(640, 470 + clue_h, "Поиск завершён!")
    r:cut_top(44)
    K.star_row(r:point(vec2(.5, 0)) + vec2(0, 34), 26, res.stars, G.dialog.stars)
    r:cut_top(84)
    local stats = r:cut_top(56)
    local half = stats:col(2, 0, 0)
    text.draw(S.eyebrow, half:point(vec2(.5, 0)), vec2(.5, 0), "ОЧКИ")
    text.draw(S.score, half:point(vec2(.5, 1)), vec2(.5, 1), tostring(res.score))
    half = stats:col(2, 1, 0)
    text.draw(S.eyebrow, half:point(vec2(.5, 0)), vec2(.5, 0), "ВРЕМЯ")
    text.draw(S.score, half:point(vec2(.5, 1)), vec2(.5, 1), ("%d:%02d"):format(math.floor(res.time / 60), math.floor(res.time % 60)))
    r:cut_top(14)
    local rewards = r:cut_top(54):inflate2(vec2(-110, 0))
    local inner = K.frame(rewards, true, 14)
    K.amount(inner:center(), vec2(.5, .5), G.coin, ("+%d"):format(payout.coins), S.reward)
    local breakdown = ("%d за поиск · %d первая победа\n%d новые звёзды · %d без ошибок и подсказок")
        :format(payout.base, payout.first, payout.mastery, payout.perfect)
    text.box(S.body:sized(16), r:cut_top(62):inflate2(vec2(-30, -6)), vec2(.5, .5), breakdown)
    r:cut_top(16)
    local note = r:cut_top(clue_h + 46):inflate2(vec2(-24, 0))
    local paper = K.frame(note, true, 14)
    text.draw(S.goal_eyebrow, paper:pos() + vec2(16, 10), vec2(0, 0), res.clue and "НОВАЯ УЛИКА" or "ЗАПИСЬ В ЖУРНАЛЕ")
    text.box(S.ink_body, rect(paper.x + 16, paper.y + 28, paper.w - 32, clue_h), vec2(0, 0), clue)
    r:cut_top(18)
    local buttons = r:cut_top(56):inflate2(vec2(-24, 0))
    local continue = buttons:col(2, 1, 16)
    G.spots.continue = continue:center()
    if K.button(buttons:col(2, 0, 16), "Таблица лидеров", "blue") then open_search_board(G.scene) end
    local _, _, restore = progress.chapter_goal()
    if K.button(continue, restore and "Строить за монеты" or "На остров", "green") then
        scene.go_home()
        if restore then island.open_tray("story") end
    end
end

local MOTION = "Меньше анимации"
local function pause_dialog()
    local _, r = popup(560, 282, "Пауза")
    r:cut_top(44)
    text.box(S.body:sized(19), r:cut_top(40):inflate2(vec2(-30, 0)), vec2(.5, .5),
             ("%s · найдено %d из %d"):format(scenes[G.scene].title, scene.found_count(), #scenes[G.scene].names))
    r:cut_top(10)
    -- The setting: no pops, pulses, sparkles or floating text; saved with progress.
    local row = r:cut_top(56)
    local w = K.skin:checkbox_size({kind = "checkbox"}, MOTION)
    local box = rect.centered(row:center(), size2(w, 48))
    G.spots.motion = box:center()
    local reduced = K.skin:draw_checkbox(box, MOTION, G.reduced_motion)
    if reduced ~= G.reduced_motion then G.reduced_motion = reduced; progress.save() end
    r:cut_top(10)
    local buttons = r:cut_top(56):inflate2(vec2(-40, 0))
    if K.button(buttons:col(2, 0, 20), "На остров", "blue") then scene.go_home() end
    G.spots.resume = buttons:col(2, 1, 20):center()
    if K.button(buttons:col(2, 1, 20), "Продолжить", "green") then G.modal = MODAL_NONE end
end

local browser = ui.form{kind = "column", gap = 8, children = {
    {kind = "list", id = "searches", scroll = true, height = 510, gap = 7, item = function(e)
        return {kind = "row", panel = true, role = "archive_entry", radius = 12, padding = 8, gap = 14, align = "center", children = {
            {kind = "image", image = e.image, width = 84, height = 56},
            {kind = "column", grow = 1, gap = 2, children = {
                {kind = "label", text = e.title, text_align = "start", wrap = true, em = 21},
                {kind = "label", text = e.note, role = "archive_note", text_align = "start", wrap = true},
            }},
            {kind = "button", id = "play", text = e.action, enabled = e.available, accent = e.available, width = 240, height = 44},
        }}
    end},
    {kind = "row", gap = 12, height = 44, children = {
        {kind = "button", id = "journal", text = "Журнал улик", grow = 1},
        {kind = "button", id = "leaderboard", text = "Таблица лидеров", grow = 1},
    }},
}}

local function refresh_chapters()
    local records = {}
    for i, sc in ipairs(scenes) do
        local blocked = progress.blocker(i)
        local note, action, title
        if i == content.CACHE then
            title = "Тайник · " .. sc.title
            note = G.cache_done and "Книга разливов пропала. Запись в журнале." or "Четыре предмета в порядке из записки."
            action = "Открыть тайник"
        else
            local clues, total = G.clues[i], economy.clue_count(i)
            local prior_clues = i == 1 or G.clues[i - 1] == economy.clue_count(i - 1)
            title = ("%d. %s"):format(i, sc.title)
            note = ("Улики %d/%d · Звёзды %d/3"):format(clues, total, G.stars[i])
            if G.wins[i] == 0 then note = note .. " · " .. sc.teaser
            elseif clues < total then
                note = note .. (not prior_clues and " · Сначала найдите предыдущие улики"
                    or G.stars[i] == 3 and " · Следующий поиск даст улику" or " · Нужны три звезды")
            end
            action = G.wins[i] == 0 and "Играть" or prior_clues and clues < total and "Искать улику" or "Играть снова"
        end
        records[i] = {id = i, title = title, note = note, image = G.backgrounds[i], action = blocked or action, available = not blocked}
    end
    assert(browser:set_items("searches", records))
end

local browser_dialog
local function chapters_dialog()
    if browser_dialog ~= G.dialog then
        refresh_chapters()
        browser_dialog = G.dialog
    end
    local _, height = browser:measure(888, K.skin)
    local box, r = popup(936, height + 88, "Глава 1 · Игра восьми")
    close_button(box)
    r = r:inflate2(vec2(-19, 0))
    r:cut_top(40)
    local event = browser:draw(r, K.skin, {reduced_motion = G.reduced_motion})
    G.spots.browser = browser
    if not event then return end
    if event.id == "journal" then G.open_modal(G.MODAL_JOURNAL)
    elseif event.id == "leaderboard" then open_influence_board()
    elseif event.source == "searches" then scene.start(event.key) end
end

local journal = ui.form{kind = "column", gap = 8, children = {
    {kind = "label", id = "summary", text_align = "center", role = "budget", height = 24},
    {kind = "list", id = "notes", gap = 4, item = function(e)
        return {kind = "column", panel = true, role = "archive_entry", radius = 10,
            padding = {left = 14, top = 7, right = 14, bottom = 7}, gap = 1, children = {
            {kind = "label", text = e.title, text_align = "start"},
            {kind = "label", text = e.note, role = "archive_note", text_align = "start", wrap = true},
        }}
    end},
    {kind = "button", id = "back", text = "К поискам", height = 42},
}}

local function journal_dialog()
    local notes = progress.journal()
    journal:set("summary", #notes == 0 and "Записи появятся после первого поиска." or ("Записей: %d"):format(#notes))
    assert(journal:set_items("notes", notes))
    local _, height = journal:measure(888, K.skin)
    local box, r = popup(936, height + 88, "Журнал улик")
    close_button(box)
    r = r:inflate2(vec2(-19, 0))
    r:cut_top(40)
    local event = journal:draw(r, K.skin)
    G.spots.journal = journal
    if event and event.id == "back" then G.open_modal(MODAL_CHAPTERS) end
end

local cache_result = ui.form{kind = "column", gap = 16, children = {
    {kind = "column", panel = true, role = "parchment", radius = 12, padding = 16, gap = 4, children = {
        {kind = "label", text = "Глава 1 завершена", em = 24},
        {kind = "label", text = beats.c1t2.note, role = "archive_note", wrap = true, em = 19},
    }},
    {kind = "label", text = "Дальше · Книга разливов", role = "budget", height = 30, em = 22},
    {kind = "label", text = ("Награда за тайник · %d монет"):format(economy.CACHE_COINS), role = "budget", height = 26},
    {kind = "button", id = "home", text = "На остров", accent = true, height = 48},
}}

local function cache_dialog()
    local _, height = cache_result:measure(572, K.skin)
    local _, r = popup(620, height + 88, "Тайник открыт")
    r = r:inflate2(vec2(-19, 0))
    r:cut_top(40)
    local event = cache_result:draw(r, K.skin)
    G.spots.cache_result = cache_result
    if event and event.id == "home" then scene.go_home() end
end

local function cast_dialog()
    local box, r = popup(1000, 640, "Люди острова")
    close_button(box)
    r = r:inflate2(vec2(-24, -16))
    r:cut_top(40)
    for i, who in ipairs(cast) do
        local col = r:col(#cast, i - 1, 20)
        local caption = col:cut_bottom(84)
        gfx.glow(col:point(vec2(.5, .8)), col.w * .5, color(242, 210, 140, 50), color(242, 210, 140, 0))
        local face = story.character(who.id).portrait
        local fs = texture.size(face)
        gfx.image(face, col:align(fs:scale(fs:fit(col:size())), vec2(.5, 1)), WHITE)
        local plate = caption:inflate2(vec2(-8, -4))
        local inner = K.frame(plate, true, 14)
        text.draw(S.card_title:sized(24), inner:point(vec2(.5, 0)) + vec2(0, 8), vec2(.5, 0), who.name)
        text.box(S.ink_small, inner:bottom(30):inflate2(vec2(-10, 0)), vec2(.5, 0), who.role)
    end
end

local dialogs = {
    [MODAL_WIN] = win_dialog, [MODAL_CHAPTERS] = chapters_dialog, [MODAL_PAUSE] = pause_dialog,
    [G.MODAL_JOURNAL] = journal_dialog, [G.MODAL_CACHE] = cache_dialog,
}

-- Draws the open dialog; the cast gallery otherwise.
function M.draw(modal)
    (dialogs[modal] or cast_dialog)()
end

return M
