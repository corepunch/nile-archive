-- Full-screen hidden-object search. Scenes supply item names and hit ellipses,
-- an optional ordered list, and backgrounds in state.backgrounds. The caller
-- owns campaign rewards, pause and routing back to its other screens.
local Screen = {}
local hex, rgba = color.hex, color

function Screen.new(state, config, hooks)
    local scenes, rules, hud = config.scenes, config.rules, config.hud
    local S = hud.styles
    local M = {buttons = {}}
    local previous_scene

    local function current_scene()
        return scenes[state.scene or previous_scene]
    end

    local function item_count()
        return #current_scene().names
    end

    local function slot_count()
        return current_scene().ordered and 1 or rules.slots
    end

    -------------------------------------------------------------------- rules

    function M.found_count()
        local n = 0
        for i = 1, item_count() do if state.found[i] then n = n + 1 end end
        return n
    end

    local function in_slots(i)
        for k = 1, slot_count() do if state.slots[k] == i then return true end end
        return false
    end

    -- The item bar's motion, on the engine's tween module: a pill's name slides up
    -- as it arrives, is struck through when found, and the pill drops away.
    local function pill(k)
        local p = state.pills[k]
        if not p then p = {arrive = 1, leave = 0, strike = 0}; state.pills[k] = p end
        return p
    end

    -- Fill empty slots (and slots whose item was found a moment ago) from the list.
    function M.refill_slots(now, linger)
        for k = 1, slot_count() do
            local i = state.slots[k]
            if not i or (state.found[i] and now - state.found[i] > linger) then
                state.slots[k] = nil
                for j = 1, item_count() do
                    if not state.found[j] and not in_slots(j) then
                        state.slots[k] = j
                        local p = pill(k)
                        tween.kill(p)
                        p.arrive, p.leave, p.strike = 1, 0, 0
                        tween.from(p, .25, {arrive = 0}):ease("out_back")
                        break
                    end
                end
            end
        end
    end

    -- The opening list is simply there; later refills slide in.
    function M.settle_slots()
        for k = 1, slot_count() do
            local p = pill(k)
            tween.kill(p)
            p.arrive, p.leave, p.strike = 1, 0, 0
        end
    end

    -- A find: a ring grows on the item, its name is struck through, then its box
    -- leaves (and refill_slots replaces it once the strike and the drop are over).
    function M.show_found(i)
        local mark = {r = 0}
        state.marks[i] = mark
        tween.to(mark, .33, {r = 1}):ease("out_back")
        for k = 1, slot_count() do
            if state.slots[k] == i then
                tween.to(pill(k), .45, {strike = 1}):ease("linear"):after(.35, {leave = 1}):ease("linear")
            end
        end
    end

    function M.open(i)
        state.scene = i
        state.found = {}
        state.hint, state.hint_ready = nil, 0
        state.slots, state.pills, state.marks = {}, {}, {}
        state.score, state.combo, state.combo_left, state.clock, state.result = 0, 0, 0, 0, nil
        state.misses, state.hints = 0, 0
        state.focus_time, state.bonus_in, state.bonus_goal = 0, 0, 0
        tween.kill(state)
        state.cam = camera{center = vec2(config.world.w / 2, config.world.h / 2), zoom = 0, world = config.world, cover = true}
        M.refill_slots(app.time(), 0)
        M.settle_slots()
        fx.clear()
    end

    function M.close()
        -- The outgoing view can still be painted during a screen transition.
        previous_scene = state.scene
        state.scene = nil
        fx.clear()
    end

    function M.show_hint()
        local pick
        for k = 1, slot_count() do   -- a name the player can read in the bar first
            local i = state.slots[k]
            if i and not state.found[i] then pick = i break end
        end
        if not pick then return end
        state.hints = state.hints + 1
        state.hint = pick
        state.hint_ready = state.clock + rules.hint_recharge
        state.focus = scenes[state.scene].at[pick]
        state.focus_time = .6
        haptic.play(haptic.TICK, .5)
    end

    local function stars_for(seconds)
        if seconds <= rules.star_times[1] then return 3 elseif seconds <= rules.star_times[2] then return 2 end
        return 1
    end

    function M.tap(screen)
        local sc = current_scene()
        local p = state.cam:to_world(screen)
        if sc.ordered then
            local i = M.found_count() + 1
            if not sc.at[i] or (p - sc.at[i]):ellipse(sc.radius[i]) > 1 then return end
            state.found[i], state.hint, state.slots[1] = app.time(), nil, nil
            M.show_found(i)
            if i < #sc.names then
                M.refill_slots(app.time(), 0)
                haptic.play(haptic.MATCH)
            else hooks.completed(state.scene)
            end
            return
        end
        for i = 1, #sc.names do
            if not state.found[i] and in_slots(i) and (p - sc.at[i]):ellipse(sc.radius[i]) <= 1 then
                state.found[i] = app.time()
                M.show_found(i)
                if state.hint == i then state.hint = nil end
                state.combo = state.combo_left > 0 and math.min(state.combo + 1, rules.combo_max) or 1
                state.combo_left = rules.combo_window
                haptic.play(state.combo > 1 and haptic.COMBO or haptic.MATCH, math.min(1, .5 + .1 * state.combo))
                local gain = rules.find_points * state.combo
                state.score = state.score + gain
                local at = state.cam:to_screen(sc.at[i])
                if not state.reduced_motion then
                    fx.sparkle(at, 40 * state.cam.zoom + 20, hex(0xFFE7A0))
                    fx.text(at - vec2(0, 30), S.float, ("+%d"):format(gain))
                end
                if M.found_count() == #sc.names then
                    local stars = stars_for(state.clock)
                    state.result = {score = state.score, time = state.clock, stars = stars, complete = true, perfect = state.misses == 0 and state.hints == 0}
                    hooks.completed(state.scene, state.result)
                end
                return
            end
        end
        -- a stray tap: points lost and the combo broken
        state.score = math.max(0, state.score - rules.miss_points)
        state.misses = state.misses + 1
        state.combo, state.combo_left = 0, 0
        haptic.play(haptic.ERROR, .5)
        if not state.reduced_motion then fx.text(screen - vec2(0, 20), S.float_miss, ("−%d"):format(rules.miss_points)) end
    end

    ------------------------------------------------------------------- screen

    function M:frame(world, dt, active)
        local screen = app.screen()
        local sc = current_scene()
        -- the picture covers the whole display, safe-area margins included (no
        -- bars); drag to see its edges. The HUD floats over it inside the safe screen.
        local view = app.bleed()
        if active then
            state.clock = state.clock + dt
            state.combo_left = math.max(0, state.combo_left - dt)
            if state.combo_left <= 0 then state.combo = 0 end
        end
        M.refill_slots(app.time(), .8)

        state.cam.view = view
        state.cam.min_zoom = 0                -- cover sets the floor: the picture always fills the view
        state.cam.max_zoom = state.cam:fit_zoom() * 3.4
        state.cam = state.cam:clamp()
        if active then
            state.cam = state.cam:input(world):clamp()
            if world.tap and view:contains(world.pos) then M.tap(world.pos) end
        end
        if state.focus_time > 0 then
            state.focus_time = state.focus_time - dt
            state.cam = state.cam:look(state.cam.center:approach(state.focus, 10, dt)):clamp()
        end

        local bg = state.backgrounds[state.scene or previous_scene]
        gfx.bleed(true)
        gfx.clip(view)
        state.cam:draw_texture(bg)
        local now = app.time()
        for i = 1, item_count() do
            local p = state.cam:to_screen(sc.at[i])
            if state.found[i] then
                local t = state.marks[i] and state.marks[i].r or 1
                gfx.ring(p, 15 * t, 2.5, rgba(172, 239, 195, 230))
                gfx.ring(p, 21 * t, 1.5, rgba(172, 239, 195, 120))
            elseif state.hint == i then
                local r = math.max(25, math.min(sc.radius[i].x, sc.radius[i].y)) * state.cam.zoom
                local pulse = state.reduced_motion and 1 or 1 + math.sin(now * 6) * .06
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
        M.buttons.pause = pc
        local pause = ui.hit(rect.centered(pc, size2(64, 64)), 0)
        local pp = pause.held and pc + vec2(0, 2) or pc
        gfx.circle(pp, 29, rgba(20, 16, 12, pause.hot and 150 or 110))
        gfx.ring(pp, 28, 3, rgba(255, 248, 230, 235))
        for k = -1, 1, 2 do gfx.round_rect(rect.centered(pp + vec2(k * 6.5, 0), size2(7, 22)), 2.5, rgba(255, 248, 230, 245)) end
        if active and pause.clicked then hooks.pause() end

        -- the bonus bar: it fills on each find and drains; the badge counts the chain
        local shown = state.combo >= 2 and 1 or 0
        if shown ~= state.bonus_goal then   -- the bar slides in with a combo and out after it
            state.bonus_goal = shown
            tween.to(state, .3, {bonus_in = shown})
        end
        if state.bonus_in > .02 then
            local a = state.bonus_in
            local bar = rect.anchor(vec2(screen:center().x - 30, area.y + 30), size2(330, 40), vec2(.5, .5))
            gfx.round_rect(bar:inflate(2), 22, rgba(255, 236, 190, 170 * a))
            gfx.round_rect(bar, 20, rgba(20, 16, 12, 130 * a))
            local f = num.saturate(state.combo_left / rules.combo_window)
            local fill = rect(bar.x + 3, bar.y + 3, math.max(34, (bar.w - 6) * f), bar.h - 6)
            gfx.round_rect_grad(fill, 17, hex(0x7FE3F5):alpha(a), hex(0x1E97C2):alpha(a))
            gfx.round_rect(rect(fill.x + 6, fill.y + 2, fill.w - 12, fill.h * .35), 8, rgba(255, 255, 255, 70 * a))
            text.draw(S.bonus:faded(1 - a), bar:center() - vec2(14, 0), vec2(.5, .52), hud.bonus_label)
            local c = vec2(bar:max().x, bar:center().y)
            gfx.circle(c + vec2(0, 3), 31, rgba(0, 0, 0, 70 * a))
            gfx.circle(c, 30, hud.gold_seam:alpha(a))
            gfx.circle(c, 28, hud.gold:alpha(a))
            gfx.circle(c, 24, hex(0xFFF6DE):alpha(a))
            text.draw(S.multiplier:faded(1 - a), c + vec2(0, 1), vec2(.5, .5), ("%dx"):format(state.combo))
        end

        -- hint, bottom right: a glowing bulb in a gold ring
        local ready = state.clock >= state.hint_ready
        local hc = vec2(area:max().x - 44, area:max().y - 38)
        local hint = ui.hit(rect.centered(hc, size2(96, 96)), 0)
        local hp = hint.held and hc + vec2(0, 2) or hc
        if ready then gfx.glow(hp, 62, rgba(255, 214, 110, state.reduced_motion and 170 or 150 + 40 * math.sin(now * 3)), rgba(255, 214, 110, 0)) end
        gfx.circle(hp, 42, hud.gold_seam)
        gfx.circle(hp, 40, ready and hud.gold_hi or hex(0xB8A27A))
        gfx.circle(hp, 34, hud.gold_seam)
        gfx.circle(hp, 33, rgba(30, 22, 14, 150))
        hud.hint_icon(hp + vec2(0, 2), 20, ready)
        if not ready then   -- the recharge sweeps round the ring
            local f = 1 - (state.hint_ready - state.clock) / rules.hint_recharge
            local pts = {}
            for k = 0, 40 do
                local ang = -math.pi / 2 + (k / 40) * f * math.pi * 2
                pts[#pts + 1] = hp + vec2(math.cos(ang), math.sin(ang)):scale(37)
            end
            if #pts > 1 then gfx.polyline(pts, 5, hex(0x8FE0F0)) end
        end
        if active and hint.clicked and ready then M.show_hint() end

        -- the names: three translucent pills across the bottom, the picture showing through
        local row = rect(area.x, area:max().y - 66, hc.x - 56 - area.x, 60)
        for k = 1, slot_count() do
            local slot = row:col(slot_count(), k - 1, 14)
            if sc.ordered then slot = row:align(size2(420, 60), vec2(.5, .5)) end
            local i = state.slots[k]
            if i then
                local p = pill(k)
                local arrive, leave = p.arrive, p.leave
                local a = num.saturate(arrive) * (1 - leave)
                local box = slot:offset(vec2(0, (1 - arrive) * 30 + leave * 24))
                local hinted = state.hint == i and not state.found[i]
                gfx.round_rect(box:inflate(2.5), box.h * .5 + 2.5, (hinted and hex(0xFFE08A) or hex(0xE2BC6E)):alpha(a))
                local fill = hinted and rgba(176, 118, 36, 215) or rgba(48, 28, 12, 168)
                gfx.round_rect(box, box.h * .5, fill:alpha(a))
                gfx.round_rect(rect(box.x + box.h * .4, box.y + 3, box.w - box.h * .8, box.h * .3), box.h * .15, rgba(255, 236, 200, 16 * a))
                local name = sc.ordered and ("%d / %d · %s"):format(i, #sc.names, sc.names[i]) or sc.names[i]
                local ink = text.fit(S.pill_text:faded(1 - a), box:inflate2(vec2(-box.h * .5, -8)), vec2(.5, .54), name)
                if state.found[i] then gfx.line(ink:point(vec2(0, .55)), ink:point(vec2(p.strike, .55)), 3, rgba(150, 235, 140, 240 * a)) end
                ui.block(box)
            end
        end
    end

    return M
end

return Screen
