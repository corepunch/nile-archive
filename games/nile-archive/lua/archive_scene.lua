-- archive_scene.lua — the hidden-object chapter: the rules (finding, misses,
-- combos, hints, stars) and the full-screen scene with its floating HUD.
local G = require("archive_state")
local content = require("archive_content")
local economy = require("archive_economy")
local progress = require("archive_progress")
local K = require("archive_kit")
local S = K.styles
local hex, rgba = color.hex, color
local scenes = content.scenes
local ITEMS, SLOTS = G.ITEMS, G.SLOTS
local FIND_POINTS, MISS_POINTS, COMBO_WINDOW, COMBO_MAX = G.FIND_POINTS, G.MISS_POINTS, G.COMBO_WINDOW, G.COMBO_MAX
local HINT_RECHARGE, STAR_TIMES = G.HINT_RECHARGE, G.STAR_TIMES
local MODAL_NONE, MODAL_WIN, MODAL_PAUSE = G.MODAL_NONE, G.MODAL_WIN, G.MODAL_PAUSE

local M = {}

-------------------------------------------------------------------- rules

function M.found_count()
    local n = 0
    for i = 1, ITEMS do if G.found[i] then n = n + 1 end end
    return n
end

local function in_slots(i)
    for k = 1, SLOTS do if G.slots[k] == i then return true end end
    return false
end

-- Fill empty slots (and slots whose item was found a moment ago) from the list.
function M.refill_slots(now, linger)
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

function M.open(i)
    G.scene = i
    G.found = {}
    G.hint, G.hint_ready = nil, 0
    G.slots, G.slot_time = {}, {}
    G.score, G.combo, G.combo_left, G.clock, G.result = 0, 0, 0, 0, nil
    G.misses, G.hints = 0, 0
    G.island.selected = -1
    G.tray = false
    G.modal = MODAL_NONE
    G.cam = camera{center = vec2(600, 400), zoom = 0, world = size2(1200, 800), cover = true}
    M.refill_slots(app.time(), 0)
    for k = 1, SLOTS do G.slot_time[k] = app.time() - 10 end   -- the opening list is simply there; refills slide in
    fx.clear()
end

function M.go_home()
    G.scene = nil
    G.modal = MODAL_NONE
    fx.clear()
end

function M.show_hint()
    local pick
    for k = 1, SLOTS do   -- a name the player can read in the bar first
        local i = G.slots[k]
        if i and not G.found[i] then pick = i break end
    end
    for i = 1, ITEMS do if not pick and not G.found[i] then pick = i end end
    if not pick then return end
    G.hints = G.hints + 1
    G.hint = pick
    G.hint_ready = G.clock + HINT_RECHARGE
    G.focus = scenes[G.scene].at[pick]
    G.focus_time = .6
end

local function stars_for(seconds)
    if seconds <= STAR_TIMES[1] then return 3 elseif seconds <= STAR_TIMES[2] then return 2 end
    return 1
end

local function tap(screen)
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
            if not G.reduced_motion then
                fx.sparkle(at, 40 * G.cam.zoom + 20, hex(0xFFE7A0))
                fx.text(at - vec2(0, 30), S.float, ("+%d"):format(gain))
            end
            if M.found_count() == ITEMS then
                local stars = stars_for(G.clock)
                G.result = {score = G.score, time = G.clock, stars = stars, complete = true, perfect = G.misses == 0 and G.hints == 0}
                assert(economy.claim(G, G.scene, G.result), "completed scene must pay once")
                story.play(("chapter-%d"):format(G.scene - 1), sc.clue)   -- the clue, the first time
                progress.save()
                G.modal = MODAL_WIN
                G.modal_time = 0
            end
            return
        end
    end
    -- a stray tap: points lost and the combo broken
    G.score = math.max(0, G.score - MISS_POINTS)
    G.misses = G.misses + 1
    G.combo, G.combo_left = 0, 0
    if not G.reduced_motion then fx.text(screen - vec2(0, 20), S.float_miss, ("−%d"):format(MISS_POINTS)) end
end

------------------------------------------------------------------- screen

function M.frame(screen, world, dt)
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
    M.refill_slots(app.time(), .8)

    G.cam.view = view
    G.cam.min_zoom = 0                -- cover sets the floor: the picture always fills the view
    G.cam.max_zoom = G.cam:fit_zoom() * 3.4
    G.cam = G.cam:clamp()
    if G.modal == MODAL_NONE then
        G.cam = G.cam:input(world):clamp()
        if world.tap and view:contains(world.pos) then tap(world.pos) end
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
            local t = G.reduced_motion and 1 or ease.out_back(num.saturate((now - G.found[i]) * 3))
            gfx.ring(p, 15 * t, 2.5, rgba(172, 239, 195, 230))
            gfx.ring(p, 21 * t, 1.5, rgba(172, 239, 195, 120))
        elseif G.hint == i then
            local r = math.max(25, math.min(sc.radius[i].x, sc.radius[i].y)) * G.cam.zoom
            local pulse = G.reduced_motion and 1 or 1 + math.sin(now * 6) * .06
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
    G.spots.pause = pc
    local pause = ui.hit(rect.centered(pc, size2(64, 64)), 0)
    local pp = pause.held and pc + vec2(0, 2) or pc
    gfx.circle(pp, 29, rgba(20, 16, 12, pause.hot and 150 or 110))
    gfx.ring(pp, 28, 3, rgba(255, 248, 230, 235))
    for k = -1, 1, 2 do gfx.round_rect(rect.centered(pp + vec2(k * 6.5, 0), size2(7, 22)), 2.5, rgba(255, 248, 230, 245)) end
    if pause.clicked then G.modal, G.modal_time = MODAL_PAUSE, 0 end

    -- the bonus bar: it fills on each find and drains; the badge counts the chain
    local shown = G.combo >= 2 and 1 or 0
    G.bonus_in = G.bonus_in + (shown - G.bonus_in) * math.min(1, dt * 10)
    if G.bonus_in > .02 then
        local a = G.bonus_in
        local bar = rect.anchor(vec2(screen:center().x - 30, area.y + 30), size2(330, 40), vec2(.5, .5))
        gfx.round_rect(bar:inflate(2), 22, rgba(255, 236, 190, 170 * a))
        gfx.round_rect(bar, 20, rgba(20, 16, 12, 130 * a))
        local f = num.saturate(G.combo_left / COMBO_WINDOW)
        local fill = rect(bar.x + 3, bar.y + 3, math.max(34, (bar.w - 6) * f), bar.h - 6)
        gfx.round_rect_grad(fill, 17, hex(0x7FE3F5):alpha(a), hex(0x1E97C2):alpha(a))
        gfx.round_rect(rect(fill.x + 6, fill.y + 2, fill.w - 12, fill.h * .35), 8, rgba(255, 255, 255, 70 * a))
        text.draw(S.bonus:faded(1 - a), bar:center() - vec2(14, 0), vec2(.5, .52), "Бонус")
        local c = vec2(bar:max().x, bar:center().y)
        gfx.circle(c + vec2(0, 3), 31, rgba(0, 0, 0, 70 * a))
        gfx.circle(c, 30, K.GOLD_SEAM:alpha(a))
        gfx.circle(c, 28, K.GOLD:alpha(a))
        gfx.circle(c, 24, hex(0xFFF6DE):alpha(a))
        text.draw(S.multiplier:faded(1 - a), c + vec2(0, 1), vec2(.5, .5), ("%dx"):format(G.combo))
    end

    -- hint, bottom right: a glowing bulb in a gold ring
    local ready = G.clock >= G.hint_ready
    local hc = vec2(area:max().x - 44, area:max().y - 38)
    local hint = ui.hit(rect.centered(hc, size2(96, 96)), 0)
    local hp = hint.held and hc + vec2(0, 2) or hc
    if ready then gfx.glow(hp, 62, rgba(255, 214, 110, G.reduced_motion and 170 or 150 + 40 * math.sin(now * 3)), rgba(255, 214, 110, 0)) end
    gfx.circle(hp, 42, K.GOLD_SEAM)
    gfx.circle(hp, 40, ready and K.GOLD_HI or hex(0xB8A27A))
    gfx.circle(hp, 34, K.GOLD_SEAM)
    gfx.circle(hp, 33, rgba(30, 22, 14, 150))
    K.icon_bulb(hp + vec2(0, 2), 20, ready)
    if not ready then   -- the recharge sweeps round the ring
        local f = 1 - (G.hint_ready - G.clock) / HINT_RECHARGE
        local pts = {}
        for k = 0, 40 do
            local ang = -math.pi / 2 + (k / 40) * f * math.pi * 2
            pts[#pts + 1] = hp + vec2(math.cos(ang), math.sin(ang)):scale(37)
        end
        if #pts > 1 then gfx.polyline(pts, 5, hex(0x8FE0F0)) end
    end
    if hint.clicked and ready then M.show_hint() end

    -- the names: three translucent pills across the bottom, the picture showing through
    local row = rect(area.x, area:max().y - 66, hc.x - 56 - area.x, 60)
    for k = 1, SLOTS do
        local slot = row:col(SLOTS, k - 1, 14)
        local i = G.slots[k]
        if i then
            local arrive = G.reduced_motion and 1 or ease.out_back(num.saturate((now - (G.slot_time[k] or 0)) * 4))
            local leave = G.found[i] and num.saturate((now - G.found[i] - .45) / .35) or 0
            local a = num.saturate(arrive) * (1 - leave)
            local pill = G.reduced_motion and slot or slot:offset(vec2(0, (1 - arrive) * 30 + leave * 24))
            local hinted = G.hint == i and not G.found[i]
            gfx.round_rect(pill:inflate(2.5), pill.h * .5 + 2.5, (hinted and hex(0xFFE08A) or hex(0xE2BC6E)):alpha(a))
            local fill = hinted and rgba(176, 118, 36, 215) or rgba(48, 28, 12, 168)
            gfx.round_rect(pill, pill.h * .5, fill:alpha(a))
            gfx.round_rect(rect(pill.x + pill.h * .4, pill.y + 3, pill.w - pill.h * .8, pill.h * .3), pill.h * .15, rgba(255, 236, 200, 16 * a))
            local ink = text.fit(S.pill_text:faded(1 - a), pill:inflate2(vec2(-pill.h * .5, -8)), vec2(.5, .54), sc.names[i])
            if G.found[i] then
                local t = num.saturate((now - G.found[i]) / .45)
                gfx.line(ink:point(vec2(0, .55)), ink:point(vec2(t, .55)), 3, rgba(150, 235, 140, 240 * a))
            end
            ui.block(pill)
        end
    end
end

return M
