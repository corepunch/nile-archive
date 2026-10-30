-- screens.lua — Relic Rush's look: text palettes, panels, buttons, the header,
-- toasts and every dialog (guide, pause, results, failure, wonder card, region
-- card, finale).
--
-- Dialogs animate through a paint transform (scale, offset, opacity) applied
-- by the helpers below; hit testing always uses the untransformed layout, so
-- a dialog is clickable where it will come to rest.
local R = require("state")
local rules = require("rules")
local SCREEN_W, SCREEN_H = R.SCREEN_W, R.SCREEN_H
local PAL_GOLD, PAL_CREAM, PAL_GREEN, PAL_WHITE = R.PAL_GOLD, R.PAL_CREAM, R.PAL_GREEN, R.PAL_WHITE
local RELIC_IDOL, RELIC_LEAF, RELIC_CRYSTAL = rules.RELIC_IDOL, rules.RELIC_LEAF, rules.RELIC_CRYSTAL
local rgba = color

local P = {scale = 1, offset = vec2(0, 0), alpha = 1}
R.P = P
local function reset_paint() P.scale, P.offset, P.alpha = 1, vec2(0, 0), 1 end
local function copy_paint() return {scale = P.scale, offset = P.offset, alpha = P.alpha} end
local function set_paint(k) P.scale, P.offset, P.alpha = k.scale, k.offset, k.alpha end
R.copy_paint, R.set_paint = copy_paint, set_paint

local function pp(p) return P.offset + p:scale(P.scale) end
local function pr(r) return rect.make(pp(r:pos()), r:size():scale(P.scale)) end
local function pc(c) return color.alpha(c, P.alpha) end
R.pp, R.pr = pp, pr

function R.fill(r, c) gfx.rect(pr(r), pc(c)) end
function R.rrect(r, radius, c) gfx.round_rect(pr(r), radius * P.scale, pc(c)) end
function R.disc(center, radius, c) gfx.circle(pp(center), radius * P.scale, pc(c)) end
function R.seg(a, b, width, c) gfx.line(pp(a), pp(b), width * P.scale, pc(c)) end
function R.picture(t, r, alpha) gfx.image(t, pr(r), rgba(255, 255, 255, alpha * P.alpha)) end
function R.picture_fit(t, box, alpha)
    if t.w > 0 then R.picture(t, box:fit(texture.size(t)), alpha) end
end
local fill, rrect, disc, seg, picture, picture_fit = R.fill, R.rrect, R.disc, R.seg, R.picture, R.picture_fit

---------------------------------------------------------------------- text

-- Lilita One sizes are given in em like the original pipeline; the engine
-- measures ascent to descent, 1.17 em for this font. Every palette shares a
-- dark rim and a drop shadow cast by the rimmed silhouette.
local tops = {[0] = rgba(255, 255, 219), rgba(255, 249, 226), rgba(199, 255, 201), rgba(255, 255, 255)}
local bottoms = {[0] = rgba(239, 169, 57), rgba(244, 221, 166), rgba(91, 198, 130), rgba(196, 232, 220)}
function R.pal(palette, em)
    palette = num.clampi(palette, 0, 3)
    em = em * P.scale
    return style{font = R.font, size = em * 1.171875, fill = tops[palette], fill2 = bottoms[palette],
                 outline = rgba(62, 49, 29), outline_width = em * 4 / 64, shadow = rgba(31, 35, 24, 184),
                 shadow_offset = vec2(0, em * 5 / 64), fade = 1 - P.alpha}
end
local pal = R.pal

function R.say(s, box, em, palette) return text.inside(pal(palette, em), pr(box), vec2(.5, .5), s) end
function R.say_left(s, box, em, palette) return text.inside(pal(palette, em), pr(box), vec2(0, .5), s) end
function R.say_at(s, center, em, palette, max_width)
    local w = max_width > 0 and max_width or 2000
    return R.say(s, rect.centered(center, size2(w, em * 2)), em, palette)
end
function R.paragraph(s, box, em, palette) text.box(pal(palette, em), pr(box), vec2(.5, .5), s) end
local say, say_left, say_at, paragraph = R.say, R.say_left, R.say_at, R.paragraph

-------------------------------------------------------------------- widgets

function R.panel(r)
    rrect(r:offset(vec2(0, 6)), 18, rgba(9, 28, 26, 145))
    rrect(r, 18, rgba(102, 68, 39))
    rrect(r:inflate(-2), 16, rgba(239, 204, 135))
    rrect(r:inflate(-5), 13, rgba(255, 239, 188))
end
local panel = R.panel

function R.tapped(r) return ui.hit(r, 0).clicked end
local tapped = R.tapped

-- Buttons respond even when drawn disabled, so the game can explain why not.
function R.button(r, label, enabled)
    local st = ui.hit(r, 0)
    local b = st.held and r:offset(vec2(0, 2)) or r
    rrect(r:offset(vec2(0, 6)), 15, rgba(13, 54, 43))
    rrect(b, 15, enabled and rgba(46, 112, 70) or rgba(75, 94, 80))
    rrect(rect(b.x + 3, b.y + 3, b.w - 6, b.h - 7), 12, enabled and rgba(113, 185, 83) or rgba(110, 126, 108))
    rrect(rect(b.x + 6, b.y + 4, b.w - 12, b.h * .4), 10, enabled and rgba(159, 213, 109) or rgba(130, 145, 125))
    say(label, b:inflate(-12), 25, PAL_CREAM)
    return st.clicked
end
local button = R.button

-- Two-tone gold star on a darker rim, lit from above.
function R.star_icon(center, radius)
    for layer = 0, 1 do
        local r = (radius - (layer == 1 and 2 or 0)) * P.scale
        local c = pp(center) + vec2(0, layer == 1 and 0 or 2 * P.scale)
        local rim = rgba(129, 78, 27)
        local pts, cols, idx = {c}, {pc(layer == 1 and rgba(255, 224, 100) or rim)}, {}
        for k = 0, 9 do
            local a, rr = -math.pi / 2 + k * math.pi / 5, r * (k % 2 == 1 and .46 or 1)
            pts[k + 2] = c + vec2.polar(a, rr)
            cols[k + 2] = pc(layer == 1 and (k < 5 and rgba(255, 242, 163) or rgba(225, 158, 41)) or rim)
            idx[k * 3 + 1], idx[k * 3 + 2], idx[k * 3 + 3] = 0, k + 1, (k + 1) % 10 + 1
        end
        app.mesh(pts, cols, idx)
    end
end

function R.compass_icon(center, radius)
    disc(center, radius, rgba(112, 81, 40))
    disc(center, radius - 2, rgba(255, 232, 162))
    local pts = {pp(center + vec2(0, -radius + 4)), pp(center + vec2(4, 3)), pp(center + vec2(0, radius - 4)), pp(center + vec2(-4, -3))}
    local cols = {pc(rgba(33, 114, 102)), pc(rgba(33, 114, 102)), pc(rgba(185, 92, 47)), pc(rgba(185, 92, 47))}
    app.mesh(pts, cols, {0, 1, 3, 1, 2, 3})
end
local star_icon, compass_icon = R.star_icon, R.compass_icon

--------------------------------------------------------------------- header

local function header_button(r, label, em)
    rrect(r, 13, rgba(22, 60, 50, 220))
    say(label, r:inflate(-4), em, PAL_CREAM)
    return tapped(r)
end

function R.draw_header(island)
    local c = R.island
    picture(R.title, rect(137, 12, 206, 206 * R.title.h / math.max(R.title.w, 1)), 255)
    if header_button(rect(21, 26, 53, 48), island and "<" or "Isle", 19) then
        if not island then
            R.on_island = true
        elseif c.placing >= 0 then
            c:cancel()
            R.notice("Your island is unchanged.")
        elseif R.prog.level == c.count and R.prog.level < rules.LEVELS then
            if R.g.won or R.g.lost or R.g.level ~= R.prog.level then R.start_level() else R.on_island = false end
        else
            R.notice("Restore your new wonder to continue.")
        end
    end
    if header_button(rect(407, 26, 53, 48), "II", 26) then R.overlay = R.OV_PAUSE end
    if not island then return end
    panel(rect(22, 92, 436, 67))
    local kinds = {RELIC_IDOL, RELIC_LEAF, RELIC_CRYSTAL}
    local icon_x, text_x = {35, 171, 304}, {104, 240, 379}
    for k = 1, 3 do
        picture(R.relics[kinds[k] + 1], rect(icon_x[k], 104, 40, 40), 255)
        say_at(tostring(R.prog.wallet[k]), vec2(text_x[k], 121), 24, k > 1 and PAL_CREAM or PAL_GOLD, 0)
    end
end

function R.draw_toast()
    if R.toast_time <= 0 or R.overlay ~= R.OV_NONE then return end
    local y = R.on_island and 716 or 93
    rrect(rect(18, y - 15, 444, 30), 11, rgba(10, 37, 31, 235))
    say_at(R.toast, vec2(240, y - 1), 14, PAL_CREAM, 424)
end

-------------------------------------------------------------------- dialogs

local function result_rects()
    local w, s = math.min(408, SCREEN_W - 48), math.min(1, (SCREEN_H - 100) / 556)
    local x, y = (SCREEN_W - w) / 2, (SCREEN_H - 556 * s) / 2 + 8
    return {card = rect(x, y, w, 556 * s), header = rect(x + 22, y - 26 * s, w - 44, 74 * s), stars = rect(x + 70, y + 70 * s, w - 140, 64 * s),
            score_label = rect(x + 66, y + 140 * s, w - 132, 20 * s), score = rect(x + 60, y + 163 * s, w - 120, 53 * s),
            treasure_label = rect(x + 30, y + 217 * s, w - 60, 20 * s), rewards = rect(x + 22, y + 243 * s, w - 44, 91 * s),
            progress = rect(x + 44, y + 349 * s, w - 88, 36 * s), next = rect(x + 28, y + 397 * s, w - 56, 65 * s),
            claim = rect(x + 40, y + 480 * s, w - 80, 56 * s)}
end

local function wonder_rects()
    local w, s = math.min(420, SCREEN_W - 48), math.min(1, (SCREEN_H - 100) / 592)
    local x, y = (SCREEN_W - w) / 2, (SCREEN_H - 592 * s) / 2
    return {card = rect(x, y, w, 592 * s), title = rect(x + 24, y + 20 * s, w - 48, 44 * s), art = rect(x + 76, y + 83 * s, w - 152, 205 * s),
            description = rect(x + 24, y + 306 * s, w - 48, 62 * s), costs = rect(x + 40, y + 382 * s, w - 80, 78 * s),
            action = rect(x + 46, y + 478 * s, w - 92, 56 * s), close = rect(x + 96, y + 551 * s, w - 192, 28 * s)}
end

-- Fade and lift a part of a dialog in after `delay`; returns the paint to restore.
local function section(delay, duration, rise)
    local old = copy_paint()
    local f = R.reduced_motion and 1 or ease.out_cubic((R.modal_clock - delay) / duration)
    P.alpha = P.alpha * f
    P.offset = P.offset + vec2(0, rise * (1 - f) * P.scale)
    return old
end

local function result_screen()
    local l = result_rects()
    local w = R.wonders[R.g.level + 1]
    local s
    panel(l.card)
    rrect(l.header:offset(vec2(0, 5)), 18, rgba(77, 58, 31))
    rrect(l.header, 18, rgba(31, 83, 69))
    rrect(l.header:inflate(-3), 15, rgba(44, 108, 84))
    say("Expedition complete", rect(l.header.x + 14, l.header.y + 9, l.header.w - 28, 34), 31, PAL_GOLD)
    say(("LEVEL %d  -  WELL EXPLORED"):format(R.g.level + 1), rect(l.header.x + 12, l.header.y + 48, l.header.w - 24, 15), 14, PAL_GOLD)
    for k = 0, 2 do
        local slot = l.stars:col(3, k, 8)
        s = section(.24 + k * .13, .32, 13)
        local t = R.reduced_motion and 1 or num.saturate((R.modal_clock - .24 - k * .13) / .32)
        local pop = 1 + math.sin(t * math.pi) * .14
        R.vfx_halo(pp(slot:center()), 45 * P.scale, rgba(255, 201, 77, 65 * P.alpha))
        star_icon(slot:center(), (k == 1 and 29 or 24) * pop)
        set_paint(s)
    end
    R.vfx_torch(pp(vec2(l.card.x + 35, l.score.y + 20)), R.now)
    R.vfx_torch(pp(vec2(l.card:max().x - 35, l.score.y + 20)), R.now + .3)
    s = section(.43, .3, 9)
    say("EXPEDITION SCORE", l.score_label, 12, PAL_CREAM)
    local count = R.reduced_motion and 1 or ease.out_cubic((R.modal_clock - .43) / .65)
    say(tostring(math.floor(R.g.score * count + .5)), l.score, 46, PAL_GOLD)
    set_paint(s)
    s = section(.62, .25, 8)
    say("TREASURES FOUND", l.treasure_label, 12, PAL_CREAM)
    set_paint(s)
    local reward = rules.level_reward(R.g, R.wonders)
    local kinds = {RELIC_IDOL, RELIC_LEAF, RELIC_CRYSTAL}
    for k = 0, 2 do
        local r = l.rewards:col(3, k, 10)
        s = section(.66 + k * .1, .28, 10)
        rrect(r, 12, rgba(241, 218, 157))
        rrect(r:inflate(-2), 10, rgba(255, 242, 201))
        picture_fit(R.relics[kinds[k + 1] + 1], rect(r.x + (r.w - 40) / 2, r.y + 8, 40, 40), 255)
        say(("+%d"):format(reward[k + 1]), rect(r.x + 6, r.y + 56, r.w - 12, 26), 26, PAL_GOLD)
        set_paint(s)
    end
    s = section(.93, .24, 8)
    for k = 0, 1 do
        local r = l.progress:col(2, k, 12)
        rrect(r, 16, rgba(221, 228, 182))
        local icon = vec2(r.x + 20, r:center().y)
        if k == 1 then compass_icon(icon, 12) else star_icon(icon, 11) end
        say(k == 1 and "+3 Compasses" or "+3 Stars", rect(r.x + 38, r.y, r.w - 44, r.h), 16, PAL_CREAM)
    end
    set_paint(s)
    s = section(1.01, .26, 8)
    rrect(l.next, 12, rgba(240, 225, 180))
    picture_fit(w.sprite, rect(l.next.x + 8, l.next.y + 5, 60, l.next.h - 10), 255)
    say_left("READY TO RESTORE", rect(l.next.x + 78, l.next.y + 9, l.next.w - 88, 18), 11, PAL_CREAM)
    say_left(w.name, rect(l.next.x + 78, l.next.y + 32, l.next.w - 88, 24), 22, PAL_GOLD)
    set_paint(s)
    s = section(1.12, .22, 8)
    if button(l.claim, "COLLECT & RETURN", not R.modal_closing) and not R.modal_closing then
        if not R.reduced_motion and R.modal_clock < 1.25 then R.modal_clock = 1.5   -- first tap fast-forwards
        else R.modal_closing, R.modal_exit = true, 0 end
    end
    set_paint(s)
end

local function wonder_screen()
    local i = R.inspect >= 0 and R.inspect or R.island.count
    if i < 0 or i >= #R.wonders then return end
    local w = R.wonders[i + 1]
    local can_build = i == R.island.count and i < R.prog.level
    local built = i < R.island.count
    local l = wonder_rects()
    panel(l.card)
    say(w.name, l.title, 34, PAL_GOLD)
    picture_fit(w.sprite, l.art, 255)
    paragraph(w.about, l.description, 22, PAL_CREAM)
    if can_build then
        local kinds = {RELIC_IDOL, RELIC_LEAF, RELIC_CRYSTAL}
        for k = 0, 2 do
            local r = l.costs:col(3, k, 10)
            picture_fit(R.relics[kinds[k + 1] + 1], rect(r.x + (r.w - 34) / 2, r.y, 34, 34), 255)
            say(tostring(w.cost[k + 1]), rect(r.x, r.y + 43, r.w, 28), 26, PAL_GOLD)
        end
    else
        paragraph(built and "RESTORED WITH YOUR EXPEDITION TREASURES" or "COMPLETE MORE LEVELS TO RESTORE THIS WONDER", l.costs, 15, PAL_CREAM)
    end
    if button(l.action, can_build and "CHOOSE A LOCATION" or built and "MOVE THIS BUILDING" or "BACK TO ISLAND", true) then
        if can_build or built then R.island_begin(i, true) else R.overlay = R.OV_NONE end
    end
    say("CLOSE", l.close, 16, PAL_CREAM)
    if tapped(l.close) then R.overlay = R.OV_NONE end
end

local guide_titles = {"Connect 4+ neighbors", "Group 5: lightning", "Group 6+: bomb or prism", "Chains & ancient sand", "Ice & fire"}
local guide_lines = {"Bends and diamonds count. Three do not.", "A sun ray follows the longest axis.",
                     "Six in a line: prism. Other shapes: bomb.", "Match on them to break or excavate.",
                     "Match on ice; nearby flames also thaw it."}

local function guide_screen()
    panel(rect(24, 144, 432, 632))
    say_at("Explorer's guide", vec2(240, 182), 34, PAL_GOLD, 0)
    say_at("SWIPE OR TAP TWO NEIGHBORING RELICS", vec2(240, 221), 13, PAL_WHITE, 0)
    for k = 0, 4 do
        local y = 278 + k * 79
        R.draw_relic(rules.tile(k, k == 1 and rules.ROW or k == 2 and rules.BOMB or rules.NORMAL), pp(vec2(66, y)), P.scale, 255 * P.alpha, 1)
        say_at(guide_titles[k + 1], vec2(273, y - 12), 23, PAL_GOLD, 318)
        say_at(guide_lines[k + 1], vec2(273, y + 15), 16, PAL_CREAM, 318)
    end
    say_at("TOOLS DO NOT COST MOVES. TAP ONE, THEN A TILE.", vec2(240, 679), 12, PAL_WHITE, 0)
    local done = button(rect(78, 709, 324, 45), "LET'S EXPLORE", true)
    if done or tapped(rect(0, 700, SCREEN_W, SCREEN_H - 700)) then R.overlay = R.OV_NONE end
end

local function pause_screen()
    panel(rect(42, 252, 396, 382))
    say_at("Take a breath", vec2(240, 291), 34, PAL_GOLD, 0)
    if button(rect(88, 337, 304, 49), "RESUME", true) then R.overlay = R.OV_NONE end
    if button(rect(88, 406, 304, 49), R.sound and "SOUND ON" or "SOUND OFF", true) then
        R.sound = not R.sound
        sfx.enable(R.sound)
    end
    if button(rect(88, 475, 304, 49), R.reduced_motion and "MOTION REDUCED" or "FULL ANIMATION", true) then R.reduced_motion = not R.reduced_motion end
    if button(rect(88, 544, 304, 49), "EXPLORER'S GUIDE", true) then R.overlay = R.OV_GUIDE end
end

local function failed_screen()
    panel(rect(38, 272, 404, 333))
    say_at("One more adventure?", vec2(240, 317), 32, PAL_GOLD, 0)
    say_at("THE RUINS WILL WAIT FOR YOU.", vec2(240, 366), 16, PAL_WHITE, 0)
    say_at("Try a special combo or use a tool.", vec2(240, 404), 17, PAL_CREAM, 0)
    if button(rect(83, 448, 314, 50), "TRY AGAIN", true) then R.start_level() end
    if button(rect(115, 520, 250, 42), "VISIT ISLAND", true) then R.on_island, R.overlay = true, R.OV_NONE end
end

local function zone_screen()
    local z = R.zone_card
    local zone = R.island.zones[z + 1]
    local ready = R.island:zone_available(z, R.prog.wallet)
    panel(rect(30, 263, 420, 365))
    say_at(zone.name, vec2(240, 304), 34, PAL_GOLD, 380)
    say_at("A NEW PLACE TO DISCOVER", vec2(240, 349), 16, PAL_CREAM, 0)
    say_at(("STARS  %d / %d"):format(R.prog.wallet[rules.STARS], zone.needs[rules.STARS]), vec2(240, 397), 24, PAL_GOLD, 0)
    say_at(("COMPASSES  %d / %d"):format(R.prog.wallet[rules.COMPASSES], zone.cost[rules.COMPASSES]), vec2(240, 441), 23, PAL_CREAM, 0)
    if button(rect(72, 487, 336, 47), ready and "OPEN THIS AREA" or "KEEP EXPLORING", true) then
        if R.island:unlock(z, R.prog.wallet) then
            R.island_focus(zone.marker, R.island.cam.zoom)
            R.save_progress()
            story.add({"mara", "New land is yours. Make it your own!", story.SHOUT})
            R.tone(820)
        end
        R.overlay = R.OV_NONE
    end
    say_at("COMPASSES ARE SPENT. STARS STAY WITH YOU.", vec2(240, 559), 12, PAL_WHITE, 0)
    say_at("CLOSE", vec2(240, 592), 15, PAL_WHITE, 0)
    if tapped(rect(0, 575, SCREEN_W, SCREEN_H - 575)) then R.overlay = R.OV_NONE end
end

local function finale_screen()
    panel(rect(32, 285, 416, 305))
    say_at("The valley lives again", vec2(240, 330), 31, PAL_GOLD, 0)
    say_at("YOU RESTORED ALL TEN WONDERS.", vec2(240, 386), 16, PAL_WHITE, 0)
    say_at("THANK YOU FOR EXPLORING.", vec2(240, 422), 16, PAL_WHITE, 0)
    if button(rect(82, 489, 316, 50), "BACK TO MY ISLAND", true) then R.overlay = R.OV_NONE end
end

local dialogs = {[R.OV_GUIDE] = guide_screen, [R.OV_PAUSE] = pause_screen, [R.OV_RESULT] = result_screen, [R.OV_FAILED] = failed_screen,
                 [R.OV_WONDER] = wonder_screen, [R.OV_ZONE] = zone_screen, [R.OV_FINALE] = finale_screen}

-- Draws the open dialog over everything; it alone receives input.
function R.overlays(dt)
    if R.overlay ~= R.modal_for then   -- a new dialog starts its entrance
        R.modal_for = R.overlay
        R.modal_clock, R.modal_exit = 0, 0
        R.modal_closing = false
    end
    if R.overlay == R.OV_NONE then return end
    R.modal_clock = R.modal_clock + dt
    if R.modal_closing then
        R.modal_exit = R.modal_exit + dt
        if R.modal_exit >= .2 or R.reduced_motion then
            R.modal_closing = false
            R.claim_reward()
            R.modal_for = R.overlay
            return
        end
    end
    local entry = R.reduced_motion and 1 or ease.out_cubic(R.modal_clock / .28)
    local exit = R.modal_closing and ease.out_cubic(R.modal_exit / .2) or 0
    gfx.rect(rect(0, 0, SCREEN_W, SCREEN_H), rgba(5, 22, 22, 185 * entry * (1 - exit)))
    ui.block(rect(0, 0, SCREEN_W, SCREEN_H))
    local scale = .96 + .04 * entry
    P.scale, P.offset, P.alpha = scale, vec2(240 * (1 - scale), 450 * (1 - scale) + 22 * (1 - entry) + 18 * exit), entry * (1 - exit)
    local draw = dialogs[R.overlay]
    if draw then draw() end
    reset_paint()
end

return R
