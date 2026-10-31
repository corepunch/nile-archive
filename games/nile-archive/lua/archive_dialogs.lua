-- archive_dialogs.lua — the popups over the island and the scene: chapter
-- won, the chapter browser, pause and the cast gallery.
local G = require("archive_state")
local content = require("archive_content")
local economy = require("archive_economy")
local progress = require("archive_progress")
local scene = require("archive_scene")
local K = require("archive_kit")
local S = K.styles
local rgba = color
local scenes, SCENES, cast = content.scenes, content.SCENES, content.cast
local ITEMS, INFLUENCE = G.ITEMS, G.INFLUENCE
local MODAL_NONE, MODAL_WIN, MODAL_CHAPTERS, MODAL_PAUSE = G.MODAL_NONE, G.MODAL_WIN, G.MODAL_CHAPTERS, G.MODAL_PAUSE
local WHITE, GOLD, GOLD_LO, GOLD_SEAM = K.WHITE, K.GOLD, K.GOLD_LO, K.GOLD_SEAM

local M = {}

-- A framed box with a ribbon title, popping in over `t` seconds.
local function popup(w, h, t, title)
    local s = app.screen()
    local box = rect.centered(s:center() + vec2(0, 14), size2(math.min(w, s.w - 40), math.min(h, s.h - 70)))
    local k = G.reduced_motion and 1 or .9 + .1 * ease.out_back(num.saturate(t * 4))
    box = box:scale(k)
    local inner = K.frame(box, false, 24)
    K.ribbon(vec2(box:center().x, box.y + 2), math.min(420, box.w * .6), title)
    return box, inner
end

local function close_button(box)
    if K.round_button(box:point(vec2(1, 0)) + vec2(-6, 6), 22, K.icon_close) then G.modal = MODAL_NONE end
end

local function win_dialog(t)
    local sc = scenes[G.scene]
    local res = G.result or {score = G.score, time = G.clock, stars = 1}
    local clue = #sc.clue > 1 and ("%s «%s»"):format(sc.clue[1][2], sc.clue[2][2]) or sc.clue[1][2]
    local clue_h = text.box_size(S.ink_body, 560 - 80, clue).h
    local payout = res.payout or economy.reward(G.wins[G.scene], G.stars[G.scene], res.stars, false)
    local _, r = popup(640, 470 + clue_h, t, "Глава пройдена!")
    r:cut_top(44)
    K.star_row(r:point(vec2(.5, 0)) + vec2(0, 34), 26, res.stars, not G.reduced_motion and t or nil)
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
    text.draw(S.goal_eyebrow, paper:pos() + vec2(16, 10), vec2(0, 0), payout.first > 0 and "НОВЫЙ ФРАГМЕНТ АРХИВА" or "УЛИКА УЖЕ НАЙДЕНА")
    text.box(S.ink_body, rect(paper.x + 16, paper.y + 28, paper.w - 32, clue_h), vec2(0, 0), clue)
    r:cut_top(18)
    local continue = r:cut_top(56):align(size2(280, 56), vec2(.5, .5))
    G.spots.continue = continue:center()
    local next_chapter, ready = progress.chapter_goal()
    local restore = next_chapter and not ready
    if K.button(continue, restore and "Строить за монеты" or "На остров", "green") then
        scene.go_home()
        G.tray = not not restore
    end
end

local function chapter_card(r, i)
    local sc = scenes[i]
    local locked = not economy.can_play(G.wins, G.wallet[INFLUENCE], i)
    local previous = i > 1 and G.wins[i - 1] == 0 and G.wins[i] == 0
    local inner = K.frame(r, true, 18)
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
        K.icon_lock(pic:center() + vec2(0, 2), 22)
    end
    local tag = rect.anchor(pic:point(vec2(0, 0)) + vec2(10, 10), size2(92, 26), vec2(0, 0))
    gfx.round_rect(tag, 13, rgba(9, 28, 32, 220))
    text.draw(S.eyebrow:sized(11), tag:center(), vec2(.5, .5), ("ГЛАВА %d"):format(i))
    inner:cut_top(10)
    text.fit(S.card_title:sized(23), inner:cut_top(30):inflate2(vec2(-12, 0)), vec2(.5, .5), sc.title)
    K.star_row(inner:cut_top(36):center() + vec2(0, 4), 11, G.stars[i])
    local teaser = inner:cut_top(math.max(0, inner.h - 74))
    local note = previous and ("Сначала пройдите главу %d."):format(i - 1) or sc.teaser
    note = note .. "\n80 монет за поиск + бонусы.\nВлияние дают постройки."
    text.box(S.ink_small, teaser:inflate2(vec2(-16, -2)), vec2(.5, 0), note)
    local b = inner:inflate2(vec2(-16, -10)):bottom(50)
    G.spots["play" .. i] = b:center()
    if locked then
        K.button(b, previous and ("Пройдите главу %d"):format(i - 1) or ("Ещё %d влияния"):format(math.max(0, sc.gate - G.wallet[INFLUENCE])), "off")
    elseif K.button(b, G.wins[i] > 0 and "Играть снова" or "Играть", G.wins[i] > 0 and "blue" or "green") then
        scene.open(i)
    end
end

local MOTION = "Меньше анимации"
local function pause_dialog(t)
    local _, r = popup(560, 282, t, "Пауза")
    r:cut_top(44)
    text.box(S.body:sized(19), r:cut_top(40):inflate2(vec2(-30, 0)), vec2(.5, .5),
             ("%s · найдено %d из %d"):format(scenes[G.scene].title, scene.found_count(), ITEMS))
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

local function chapters_dialog(t)
    local w = math.min(1040, app.screen().w - 40)
    local card_w = (w - 10 - 44 - 40) / SCENES
    local card_h = (card_w - 26) * 2 / 3 + 8 + 10 + 30 + 36 + 108 + 74
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
        local inner = K.frame(plate, true, 14)
        text.draw(S.card_title:sized(24), inner:point(vec2(.5, 0)) + vec2(0, 8), vec2(.5, 0), who.name)
        text.box(S.ink_small, inner:bottom(30):inflate2(vec2(-10, 0)), vec2(.5, 0), who.role)
    end
end

local dialogs = {[MODAL_WIN] = win_dialog, [MODAL_CHAPTERS] = chapters_dialog, [MODAL_PAUSE] = pause_dialog}

-- Draws the open dialog `t` seconds after it opened; the cast gallery otherwise.
function M.draw(modal, t)
    (dialogs[modal] or cast_dialog)(t)
end

return M
