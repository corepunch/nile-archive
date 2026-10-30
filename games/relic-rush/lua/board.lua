-- board.lua — the expedition screen: HUD, hex board, relic animation phases,
-- tools and swipe / tap input.
--
-- Phases: SWAP (relics trade places, then the wave clears), REJECT (they
-- slide back), CLEAR (matched relics pop) and FALL (gravity per column
-- segment); after a fall the board is checked again, so cascades chain.
local R = require("state")
local rules = require("rules")
local CELLS, HEX_R, SCREEN_W, SCREEN_H = rules.CELLS, R.HEX_R, R.SCREEN_W, R.SCREEN_H
local PH_IDLE, PH_SWAP, PH_REJECT, PH_CLEAR, PH_FALL = R.PH_IDLE, R.PH_SWAP, R.PH_REJECT, R.PH_CLEAR, R.PH_FALL
local PAL_GOLD, PAL_CREAM, PAL_WHITE = R.PAL_GOLD, R.PAL_CREAM, R.PAL_WHITE
local NORMAL, ROW, COLUMN, DIAGONAL, BOMB, PRISM = rules.NORMAL, rules.ROW, rules.COLUMN, rules.DIAGONAL, rules.BOMB, rules.PRISM
local hex_q, hex_r, hex_index, hex_neighbor, hex_distance, cell_active = rules.hex_q, rules.hex_r, rules.hex_index, rules.hex_neighbor, rules.hex_distance, rules.game_cell_active
local rgba = color
local PI = math.pi

local CELL_SIZE = 46
local HEX_DY = 1.732050808 * HEX_R
local board_origin = vec2(240, 492)

function R.cell_pos(i) return board_origin + vec2(hex_q(i) * 1.5 * HEX_R, (hex_r(i) + hex_q(i) * .5) * HEX_DY) end
local cell_pos = R.cell_pos

-- Screen point to the active cell under it, by rounding cube coordinates.
local function cell_at(p)
    local d = p - board_origin
    local q = d.x * 2 / (3 * HEX_R)
    local r = -d.x / (3 * HEX_R) + d.y / HEX_DY
    local s = -q - r
    local iq, ir, is = math.floor(q + .5), math.floor(r + .5), math.floor(s + .5)
    local dq, dr, ds = math.abs(iq - q), math.abs(ir - r), math.abs(is - s)
    if dq > dr and dq > ds then iq = -ir - is
    elseif dr > ds then ir = -iq - is end
    local cell = hex_index(iq, ir)
    return cell_active(R.g, cell) and cell or -1
end

-------------------------------------------------------------------- drawing

function R.draw_relic(t, at, scale, alpha, aspect)
    if t.kind < 0 then return end
    local s = CELL_SIZE * .95 * scale
    gfx.image(R.relics[t.kind + 1], rect.centered(at, size2(s * aspect, s / aspect)), rgba(255, 255, 255, alpha))
    if t.special == NORMAL then return end
    local r = 18 * scale
    local cream = rgba(255, 251, 194, alpha)
    if t.special == ROW or t.special == COLUMN or t.special == DIAGONAL then
        local a = (t.special == ROW and 30 or t.special == COLUMN and 90 or 150) * PI / 180
        local dir, n = vec2.polar(a, r), vec2.polar(a + PI / 2, 7 * scale)
        for k = -1, 1 do
            local c = at + n:scale(k)
            gfx.line(c - dir, c + dir, 1.6 * scale, cream)
        end
    elseif t.special == BOMB then
        gfx.circle(at, 12 * scale, rgba(74, 47, 50, alpha))
        gfx.circle(at + vec2.splat(-3 * scale), 3 * scale, cream)
        gfx.line(at + vec2(6, -9):scale(scale), at + vec2(13, -18):scale(scale), 1.6 * scale, cream)
        gfx.circle(at + vec2(13, -18):scale(scale), 3 * scale, rgba(255, 185, 65, alpha))
    else   -- prism
        gfx.circle(at, 12 * scale, cream)
        for k = 0, 5 do
            gfx.circle(at + vec2.polar(k * PI / 3, 8 * scale), 3 * scale, rgba(100 + k * 20, 220 - k * 20, 180, alpha))
        end
    end
end
local draw_relic = R.draw_relic

local function wrapf(v, m) return v - m * math.floor(v / m) end

local function draw_backdrop()
    local scene = R.scenes[R.g.level >= 5 and 2 or 1]
    gfx.image(scene.tex and scene or R.backdrop, rect(0, 0, SCREEN_W, SCREEN_H), color.WHITE)
    gfx.rect(rect(0, 0, SCREEN_W, SCREEN_H), rgba(5, 30, 29, 35))
    for i = 0, 11 do   -- drifting motes of sunlight
        local p = vec2(20 + wrapf(i * 93 + R.now * (i % 2 == 1 and 3 or -4) + 480, 440), 170 + wrapf(i * 139 + R.now * 5, 620))
        gfx.circle(p, 1.5 + math.sin(R.now + i) * .5, rgba(255, 228, 139, 70 + 50 * math.sin(R.now + i)))
    end
end

local function draw_hud()
    local g = R.g
    local l = rules.level_of(g)
    R.panel(rect(24, 106, 432, 112))
    R.say_at("SCORE", vec2(90, 126), 14, PAL_WHITE, 0)
    R.say_at(tostring(math.floor(R.score_display)), vec2(90, 153), 30 + (R.reduced_motion and 0 or 5 * math.sin(R.score_pulse / .25 * PI)), PAL_GOLD, 0)
    R.say_at(("LEVEL %d"):format(g.level + 1), vec2(239, 126), 17, PAL_GOLD, 0)
    R.say_at(l.name, vec2(239, 155), 18, PAL_CREAM, 184)
    gfx.circle(vec2(399, 151), 38, rgba(122, 78, 36))
    gfx.circle(vec2(399, 148), 34, rgba(237, 184, 77))
    gfx.circle(vec2(399, 146), 30, rgba(255, 223, 129))
    R.say(tostring(g.moves), rect(369, 119, 60, 37), 33, PAL_CREAM)
    R.say("MOVES", rect(365, 156, 68, 17), 11, PAL_CREAM)
    gfx.round_rect(rect(47, 190, 386, 11), 5, rgba(163, 132, 78))
    if R.goal_display > 0 then gfx.round_rect(rect(48, 191, math.max(6, 384 * R.goal_display), 8), 4, rgba(88, 169, 92)) end

    -- two primary goals, then sand and lock goals when the level has them
    local goals = 2 + (l.soil > 0 and 1 or 0) + (g.initial_obstacles > 0 and 1 or 0)
    local gw = 432 / goals
    for k = 0, goals - 1 do gfx.round_rect(rect(24 + k * gw + 2, 230, gw - 4, 36), 10, rgba(13, 47, 41, 230)) end
    R.say_at(("%d / %d"):format(math.min(g.score, l.score), l.score), vec2(24 + gw * .5, 246), 17, PAL_CREAM, gw - 10)
    local pop = R.reduced_motion and 0 or 5 * math.sin(R.goal_pulse / .22 * PI)
    gfx.image(R.relics[rules.RELIC_IDOL + 1], rect(24 + gw + 5 - pop / 2, 234 - pop / 2, 29 + pop, 29 + pop), color.WHITE)
    R.say_at(("%d / %d"):format(math.min(g.relics, l.relics), l.relics), vec2(24 + gw * 1.58, 246), 19, PAL_GOLD, gw - 33)
    local slot = 2
    if l.soil > 0 then
        R.say_at(("SAND %d"):format(l.soil - g.dug), vec2(24 + gw * (slot + .5), 246), 17, PAL_CREAM, gw - 8)
        slot = slot + 1
    end
    if g.initial_obstacles > 0 then R.say_at(("LOCK %d"):format(g.obstacles), vec2(24 + gw * (slot + .5), 246), 17, PAL_WHITE, gw - 8) end
end

local function draw_cells(sx)
    local g = R.g
    for i = 0, CELLS - 1 do
        if cell_active(g, i) then
            local at = cell_pos(i) + vec2(sx, 0)
            gfx.ngon(at + vec2(0, 2), HEX_R + .7, 6, 0, rgba(7, 37, 34))
            for d = 0, 5 do   -- a gold rim where the board ends
                if not cell_active(g, hex_neighbor(i, d)) then
                    local a, b = d * PI / 3, (d + 1) * PI / 3
                    gfx.line(at + vec2.polar(a, HEX_R - .5), at + vec2.polar(b, HEX_R - .5), 2, rgba(212, 175, 95))
                end
            end
            gfx.ngon(at, HEX_R - .8, 6, 0, rgba(75, 120, 91))
            gfx.ngon(at, HEX_R - 2, 6, 0, (hex_q(i) - hex_r(i)) % 2 == 1 and rgba(29, 82, 67) or rgba(35, 94, 73))
            if g.soil[i] > 0 then
                gfx.ngon(at, HEX_R - 1.5, 6, 0, rgba(209, 166, 85))
                gfx.ngon(at, HEX_R - 4, 6, 0, rgba(164, 121, 57))
                gfx.circle(at + vec2(-13, -12), 2, rgba(247, 211, 141, 220))
            end
            if i == R.selected or ((i == R.hint_a or i == R.hint_b) and R.phase == PH_IDLE) then
                local a = i == R.selected and 255 or 110 + 70 * math.sin(R.now * 5)
                gfx.ngon(at, HEX_R - 1, 6, 0, rgba(255, 234, 138, a))
                gfx.ngon(at, HEX_R - 4, 6, 0, rgba(65, 123, 82))
            end
        end
    end
end

local function movable(i) return cell_active(R.g, i) and R.g.ice[i] == 0 and R.g.chain[i] == 0 end

local function draw_relics(sx)
    local g = R.g
    gfx.clip(R.BOARD_CLIP)
    for i = 0, CELLS - 1 do
        if cell_active(g, i) then
            local at = cell_pos(i) + vec2(sx, 0)
            local scale, alpha, aspect = 1, 255, 1
            local t = g.tiles[i]
            local clipped = false
            if R.phase == PH_SWAP or R.phase == PH_REJECT then
                t = R.old_tiles[i]
                if i == R.swap_a or i == R.swap_b then
                    local other = i == R.swap_a and R.swap_b or R.swap_a
                    local f = R.phase_time / (R.phase == PH_SWAP and .17 or .16)
                    if R.phase == PH_REJECT and f > 1 then f = 2 - f end
                    at = at:lerp(cell_pos(other) + vec2(sx, 0), ease.out_cubic(f))
                end
            elseif R.phase == PH_CLEAR and R.pending.mask[i] then
                t = R.old_tiles[i]
                if R.wave_chain[i] == 0 and R.wave_ice[i] == 0 and not R.pending.make[i] then   -- a small pop, then shrink away
                    local f = num.saturate(R.phase_time / .24)
                    scale = f < .22 and 1 + .18 * math.sin(f / .22 * PI) or 1 - .92 * ease.out_cubic((f - .22) / .78)
                    alpha = 255 * (1 - f * f)
                end
            elseif R.phase == PH_FALL then
                local q, lo = hex_q(i), hex_r(i)
                local hi = lo
                if movable(i) then   -- the column segment this relic falls within
                    while movable(hex_index(q, lo - 1)) do lo = lo - 1 end
                    while movable(hex_index(q, hi + 1)) do hi = hi + 1 end
                end
                local f = ease.out_cubic((R.phase_time - (q + 4) * .006) / .29)
                local from = R.fall_from[i]
                local source = from >= 0 and cell_pos(from).y or cell_pos(hex_index(q, lo)).y + from * HEX_DY
                at.y = num.lerp(source, cell_pos(i).y, f)
                if not R.reduced_motion then
                    at.y = at.y + math.sin(f * PI * 2) * 3 * (1 - f)
                    if f > .72 then aspect = 1 + .11 * math.sin((f - .72) / .28 * PI) end   -- landing squash
                end
                local top = cell_pos(hex_index(q, lo))
                gfx.clip(rect(cell_pos(i).x - CELL_SIZE / 2 - 1, top.y - HEX_DY / 2, CELL_SIZE + 2, (hi - lo + 1) * HEX_DY))
                clipped = true
            end
            draw_relic(t, at, scale, alpha, aspect)
            if clipped then gfx.clip(R.BOARD_CLIP) end
        end
    end
    gfx.unclip()
end

local cracks = {{vec2(-11, -18), vec2(11, -18)}, {vec2(-20, 0), vec2(-11, -18)}, {vec2(-7, -19), vec2(4, -4)}, {vec2(4, -4), vec2(-4, 11)}, {vec2(18, -10), vec2(-10, 17)}}

local function draw_blockers(sx)
    local g = R.g
    local ice = rgba(225, 253, 255, 235)
    for i = 0, CELLS - 1 do
        if cell_active(g, i) then
            local at = cell_pos(i) + vec2(sx, 0)
            if g.ice[i] > 0 then
                gfx.ngon(at, HEX_R - 2, 6, 0, rgba(170, 230, 249, 110))
                for k = 1, g.ice[i] > 1 and 5 or 4 do gfx.line(at + cracks[k][1], at + cracks[k][2], 1.5, ice) end
            end
            if g.chain[i] > 0 then
                for a = -1, 1, 2 do
                    for k = -2, 2 do
                        local link = at + vec2(k * 7, a * k * 6)
                        gfx.round_rect(rect.centered(link, size2(10, 6)), 2, rgba(42, 45, 42))
                        gfx.round_rect(rect.centered(link, size2(6, 2)), 1, rgba(194, 186, 151))
                    end
                end
                gfx.round_rect(rect(at.x - 7, at.y - 5, 14, 13), 3, rgba(224, 183, 76))
                gfx.circle(at, 2, rgba(72, 68, 48))
            end
        end
    end
end

local function draw_tool_icon(k, x)
    if k == 0 then   -- pickaxe
        gfx.line(vec2(x - 12, 812), vec2(x + 9, 782), 7, rgba(109, 66, 38))
        gfx.line(vec2(x - 16, 783), vec2(x + 20, 792), 9, rgba(234, 237, 196))
    elseif k == 1 then   -- dynamite
        for z = -1, 1 do gfx.round_rect(rect(x + z * 10 - 5, 783, 10, 30), 4, rgba(190 + z * 15, 66, 42)) end
        gfx.rect(rect(x - 16, 795, 32, 5), rgba(244, 202, 129))
        gfx.circle(vec2(x + 9, 780), 4, rgba(255, 235, 141))
    else   -- sunburst
        gfx.circle(vec2(x, 798), 14, rgba(255, 234, 147))
        for z = 0, 7 do
            local d = vec2.polar(z * PI / 4, 1)
            gfx.line(vec2(x, 798) + d:scale(17), vec2(x, 798) + d:scale(23), 2, rgba(255, 232, 154))
        end
    end
end

local tool_names = {"Pickaxe", "Dynamite", "Sunburst"}

local function draw_tools()
    if R.word_time <= 0 or R.reduced_motion then
        R.say_at(R.tool >= 0 and "TAP A RELIC TO USE YOUR TOOL" or "CONNECT 4+ MATCHING NEIGHBORS.", vec2(240, 739), 13, PAL_WHITE, 0)
    end
    for k = 0, 2 do
        local x = 63 + k * 112
        local r = rect(x - 38, 766, 76, 65)
        gfx.round_rect(r, 14, rgba(50, 45, 31, 240))
        gfx.round_rect(rect(x - 35, 768, 70, 58), 12, R.tool == k and rgba(168, 191, 92) or rgba(220, 178, 99))
        draw_tool_icon(k, x)
        gfx.circle(vec2(x + 29, 772), 13, rgba(44, 88, 61))
        R.say(tostring(R.g.tools[k + 1]), rect(x + 16, 759, 26, 26), 16, PAL_CREAM)
        R.say_at(tool_names[k + 1], vec2(x, 846), 15, PAL_CREAM, 0)
        if R.tapped(r) and R.phase == PH_IDLE then
            if R.g.tools[k + 1] > 0 then
                R.tool = R.tool == k and -1 or k
                R.selected = -1
                R.notice(R.tool < 0 and "Tool put away." or "Tap a relic to use your tool.")
            else
                R.notice("No charges left. More tools next expedition.")
            end
        end
    end
    local guide = rect(387, 774, 63, 55)
    gfx.round_rect(guide, 14, rgba(28, 77, 61, 240))
    R.say("?", guide:inflate(-3), 33, PAL_GOLD)
    R.say_at("GUIDE", vec2(419, 845), 12, PAL_WHITE, 0)
    if R.tapped(guide) then R.overlay = R.OV_GUIDE end
    R.say_at("THE LOST VALLEY", vec2(240, 881), 11, PAL_WHITE, 0)
end

---------------------------------------------------------------------- input

local function tap_cell(at)
    local cell = cell_at(at)
    if cell < 0 then
        R.selected, R.tool = -1, -1
        return
    end
    R.idle_time = 0
    R.hint_a, R.hint_b = -1, -1
    if R.tool >= 0 then
        if rules.game_tool(R.g, R.tool, cell, R.pending) then
            R.tool = -1
            R.finish_wave()
        end
        return
    end
    if R.selected == cell then R.selected = -1
    elseif R.selected >= 0 and hex_distance(R.selected, cell) == 1 then R.attempt_swap(R.selected, cell)
    else R.selected = cell; R.tone(270) end
end

-- A swipe trades with the neighbour best aligned with the gesture.
local function swipe(from, to)
    local a, b = cell_at(from), -1
    local d = to - from
    local best = -1
    if a < 0 then return end
    for k = 0, 5 do
        local n = hex_neighbor(a, k)
        if n >= 0 then
            local alignment = d:norm():dot((cell_pos(n) - cell_pos(a)):norm())
            if alignment > best then best, b = alignment, n end
        end
    end
    if best > .75 then R.attempt_swap(a, b) end
end

local function board_input(inp)
    if not inp.released or R.overlay ~= R.OV_NONE then return end
    local d = inp.pos - inp.press_pos
    if R.phase == PH_IDLE and cell_at(inp.press_pos) >= 0 and (math.abs(d.x) > 16 or math.abs(d.y) > 16) then swipe(inp.press_pos, inp.pos)
    elseif R.phase == PH_IDLE and R.BOARD_CLIP:contains(inp.pos) then tap_cell(inp.pos) end
end

---------------------------------------------------------------------- rules

local function snapshot()
    for i = 0, CELLS - 1 do
        local t = R.g.tiles[i]
        R.old_tiles[i] = {kind = t.kind, special = t.special}
        R.wave_ice[i], R.wave_chain[i] = R.g.ice[i], R.g.chain[i]
    end
end

local notes = {523.25, 659.25, 783.99, 1046.5, 1318.5}

function R.finish_wave()
    snapshot()
    local old_score = R.g.score
    rules.game_apply(R.g, R.pending)
    R.phase = PH_CLEAR
    R.phase_time = 0
    R.shake = R.reduced_motion and 0 or R.g.combo > 1 and .13 or .06
    R.vfx_wave(old_score)
    R.tone(notes[num.clampi(R.g.combo - 1, 0, 4) + 1])
end

function R.attempt_swap(a, b)
    if R.phase ~= PH_IDLE or R.overlay ~= R.OV_NONE or R.on_island then return end
    R.selected, R.tool, R.hint_a, R.hint_b = -1, -1, -1, -1
    R.idle_time = 0
    R.swap_a, R.swap_b = a, b
    snapshot()
    if rules.game_swap(R.g, a, b, R.pending) then
        local sa, sb = R.old_tiles[a].special, R.old_tiles[b].special
        R.fx_origin = sa == PRISM and b or sb == PRISM and a or b
        R.fx_combo = (sa == PRISM or sb == PRISM) and 3 or (sa ~= NORMAL and sb ~= NORMAL) and ((sa == BOMB or sb == BOMB) and 2 or 1) or 0
        R.phase = PH_SWAP
        R.phase_time = 0
        R.tone(320)
    elseif rules.game_can_swap(R.g, a, b) then
        R.phase = PH_REJECT
        R.phase_time = 0
        R.tone(170)
    else
        R.notice("Ice and chains must be broken first.")
    end
end

local function settle()
    rules.game_matches(R.g, R.pending, -1)
    if R.pending.hits > 0 then
        R.finish_wave()
        return
    end
    R.phase = PH_IDLE
    rules.game_check_end(R.g)
    if R.g.won then R.overlay = R.OV_RESULT; R.tone(880)
    elseif R.g.lost then R.overlay = R.OV_FAILED; R.tone(165) end
    R.idle_time = 0
end

function R.board_update(dt)
    R.shake = math.max(0, R.shake - dt)
    if R.overlay ~= R.OV_NONE or R.on_island then return end
    R.idle_time = R.idle_time + dt
    if R.phase == PH_IDLE and not R.g.won and not R.g.lost then   -- ready groups resolve before any input
        rules.game_matches(R.g, R.pending, -1)
        if R.pending.hits > 0 then
            R.selected, R.tool, R.hint_a, R.hint_b = -1, -1, -1, -1
            R.finish_wave()
        end
    end
    if R.idle_time > 5 and R.hint_a < 0 and R.phase == PH_IDLE then
        local ok, a, b = rules.game_hint(R.g)
        if ok then R.hint_a, R.hint_b = a, b end
    end
    if R.phase == PH_IDLE then return end
    R.phase_time = R.phase_time + dt
    local speed = R.reduced_motion and .35 or 1
    if R.phase == PH_SWAP and R.phase_time > .17 * speed then R.finish_wave()
    elseif R.phase == PH_REJECT and R.phase_time > .32 * speed then R.phase = PH_IDLE
    elseif R.phase == PH_CLEAR and R.phase_time > .24 * speed then
        R.fall_from = rules.game_collapse(R.g)
        R.phase = PH_FALL
        R.phase_time = 0
    elseif R.phase == PH_FALL and R.phase_time > .35 * speed then
        settle()
    end
end

function R.board_screen(inp, dt)
    draw_backdrop()
    R.draw_header(false)
    draw_hud()
    local sx = (not R.reduced_motion and R.shake > 0) and math.sin(R.now * 110) * R.shake * 15 or 0
    draw_cells(sx)
    draw_relics(sx)
    draw_blockers(sx)
    draw_tools()
    board_input(inp)
end

return R
