-- board.lua — the expedition screen: HUD, hex board, relic animation phases,
-- tools and swipe / tap input.
--
-- Phases: SWAP (relics trade places, then the wave clears), REJECT (they
-- slide back), CLEAR (matched relics pop) and FALL (gravity per column
-- segment); after a fall the board is checked again, so cascades chain.
local R = require("state")
local rules = require("rules")
local art = require("art")
local CELLS, HEX_R, SCREEN_W, SCREEN_H = rules.CELLS, R.HEX_R, R.SCREEN_W, R.SCREEN_H
local PH_IDLE, PH_SWAP, PH_REJECT, PH_CLEAR, PH_FALL = R.PH_IDLE, R.PH_SWAP, R.PH_REJECT, R.PH_CLEAR, R.PH_FALL
local PAL_GOLD, PAL_CREAM, PAL_WHITE = R.PAL_GOLD, R.PAL_CREAM, R.PAL_WHITE
local NORMAL, PRISM = rules.NORMAL, rules.PRISM
local hex_q, hex_r, hex_index, hex_neighbor, hex_distance, cell_active = rules.hex_q, rules.hex_r, rules.hex_index, rules.hex_neighbor, rules.hex_distance, rules.game_cell_active
local rgba = color
local PI = math.pi

-- Preserve the authored cell-mask registration and the guide's icon size;
-- only live board pieces use the enlarged board scale.
local ART_HEX_R, ART_CELL_SIZE = 26.5, 46
local BOARD_SCALE = HEX_R / ART_HEX_R
local ART_STATE_SIZE = (ART_HEX_R - .8) * 2
local CELL_SIZE = ART_CELL_SIZE * BOARD_SCALE
local STATE_SIZE = ART_STATE_SIZE * BOARD_SCALE
local HEX_DY = 1.732050808 * HEX_R
local board_origin = vec2(240, 492)
local TOOLS_Y, TOOL_SIZE = 784, art.tool_size   -- square buttons leave room for labels below

-- The screen is 480 wide and at least 900 tall; tall phones add height. The
-- bottom group moves down by all of it (R.drop) and the board by half.
function R.layout()
    R.drop = app.screen().h - SCREEN_H
    board_origin = vec2(240, 492 + R.drop / 2)
    local half_w = (1.5 * rules.HEX_RADIUS + 1) * HEX_R + 6
    local half_h = (rules.HEX_RADIUS + .5) * HEX_DY + 6
    R.BOARD_CLIP = rect.centered(board_origin, size2(half_w * 2, half_h * 2))
end

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
    local s = ART_CELL_SIZE * .95 * scale
    local frame = ART_STATE_SIZE * scale
    local dst = rect.centered(at, size2(frame * aspect, frame / aspect))
    local tint = rgba(255, 255, 255, alpha)
    -- Authored frames leave the matching kind visible in every optional pack.
    if t.special ~= PRISM then
        local inner = t.special == NORMAL and 1 or .72
        gfx.image(R.relics[t.kind + 1], rect.centered(at, size2(s * aspect * inner, s / aspect * inner)), tint)
    end
    if t.special ~= NORMAL then gfx.image(R.board_art[art.specials[t.special]], dst, tint) end
end
local draw_relic = R.draw_relic

local function wrapf(v, m) return v - m * math.floor(v / m) end

local function draw_backdrop()
    local scene = R.scenes[R.g.level >= 5 and 2 or 1]
    local tex = scene.tex and scene or R.backdrop
    local full = app.bleed()   -- the jungle runs on under the status bar and the home indicator
    local size = texture.size(tex)
    gfx.bleed(true)
    gfx.image(tex, full:align(size:scale(size:cover(full:size())), vec2(.5, .5)), color.WHITE)
    gfx.rect(full, rgba(5, 30, 29, 35))
    gfx.bleed(false)
    for i = 0, 11 do   -- drifting motes of sunlight
        local p = vec2(20 + wrapf(i * 93 + R.now * (i % 2 == 1 and 3 or -4) + 480, 440), 170 + wrapf(i * 139 + R.now * 5, 620))
        gfx.circle(p, 1.5 + math.sin(R.now + i) * .5, rgba(255, 228, 139, 70 + 50 * math.sin(R.now + i)))
    end
end

-- Separate readout cards keep the painting visible between groups. Shared
-- form rows/columns own the grouping; the skin only paints their bounds.
local hud_form = ui.form{kind="column", gap=10, children={
    {kind="row", height=68, gap=8, children={
        {kind="column", panel=true, width=104, padding={8,6,8,6}, children={
            {kind="label", text="SCORE", height=19, em=13, palette=PAL_WHITE},
            {kind="label", id="score", height=37, em=30, role="score"},
        }},
        {kind="column", panel=true, grow=1, padding={8,6,8,6}, children={
            {kind="label", id="level", height=20, em=15},
            {kind="label", id="name", height=36, em=18, palette=PAL_CREAM, wrap=true},
        }},
        {kind="column", panel=true, width=88, padding={8,6,8,6}, children={
            {kind="label", id="moves", height=37, em=33},
            {kind="label", text="MOVES", height=19, em=12, palette=PAL_WHITE},
        }},
    }},
    {kind="custom", id="progress", height=10, paint=function(r, value)
        gfx.round_rect(r, 5, rgba(13,47,41,245))
        if value>0 then gfx.round_rect(rect(r.x+1,r.y+1,math.max(6,(r.w-2)*value),r.h-2),4,rgba(88,169,92)) end
    end},
}}
local function hud_style(node)
    local pulse = node.role=="score" and not R.reduced_motion and 5*math.sin(R.score_pulse/.25*PI) or 0
    return R.pal(node.palette or PAL_GOLD, (node.em or 18)+pulse)
end
local hud_skin = {
    style=hud_style,
    panel=function(r)
        gfx.shadow(r:offset(vec2(0,3)),12,5,rgba(0,0,0,100))
        gfx.round_rect(r,12,rgba(13,47,41,248))
        gfx.round_rect_line(r:inflate(-.8),11,1.4,rgba(224,188,113,190))
    end,
    label=function(r, label, node)
        if node.wrap then text.box(hud_style(node),r,vec2(.5,.5),label)
        else text.inside(hud_style(node),r,vec2(.5,.5),label) end
    end,
}

local function draw_hud()
    local g = R.g
    local l = rules.level_of(g)
    hud_form:set("score",tostring(math.floor(R.score_display)))
    hud_form:set("level",("LEVEL %d"):format(g.level+1))
    hud_form:set("name",l.name)
    hud_form:set("moves",tostring(g.moves))
    hud_form:set("progress",R.goal_display)
    hud_form:draw(rect(24,80,432,88),hud_skin,{interactive=false})

    -- two primary goals, then sand and lock goals when the level has them
    local goals = 2 + (l.soil > 0 and 1 or 0) + (g.initial_obstacles > 0 and 1 or 0)
    local gw = 432 / goals
    for k = 0, goals - 1 do
        local r=rect(24+k*gw+2,196,gw-4,36)
        gfx.round_rect(r,10,rgba(13,47,41,248))
        gfx.round_rect_line(r:inflate(-.5),9,1,rgba(224,188,113,145))
    end
    R.say_at(("%d / %d"):format(math.min(g.score, l.score), l.score), vec2(24 + gw * .5, 212), 17, PAL_CREAM, gw - 10)
    local pop = R.reduced_motion and 0 or 5 * math.sin(R.goal_pulse / .22 * PI)
    gfx.image(R.relics[rules.RELIC_IDOL + 1], rect(24 + gw + 5 - pop / 2, 200 - pop / 2, 29 + pop, 29 + pop), color.WHITE)
    R.say_at(("%d / %d"):format(math.min(g.relics, l.relics), l.relics), vec2(24 + gw * 1.58, 212), 19, PAL_GOLD, gw - 33)
    local slot = 2
    if l.soil > 0 then
        R.say_at(("SAND %d"):format(l.soil - g.dug), vec2(24 + gw * (slot + .5), 212), 17, PAL_CREAM, gw - 8)
        slot = slot + 1
    end
    if g.initial_obstacles > 0 then R.say_at(("LOCK %d"):format(g.obstacles), vec2(24 + gw * (slot + .5), 212), 17, PAL_WHITE, gw - 8) end
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
            local dst = rect.centered(at, size2.splat(STATE_SIZE))
            local has_state = g.soil[i] > 0 or g.ice[i] > 0 or g.tiles[i].special ~= NORMAL or i == R.selected
                              or ((i == R.hint_a or i == R.hint_b) and R.phase == PH_IDLE)
            -- State panels replace the old green face/rim; no cell sticks out.
            gfx.image(R.board_art["cell-mask"], dst, has_state and rgba(13, 47, 41)
                      or (hex_q(i) - hex_r(i)) % 2 == 1 and rgba(29, 82, 67) or rgba(35, 94, 73))
            if g.soil[i] > 0 then gfx.image(R.board_art.sand, dst, color.WHITE) end
            if i == R.selected then
                gfx.image(R.board_art.selected, dst, color.WHITE)
            elseif (i == R.hint_a or i == R.hint_b) and R.phase == PH_IDLE then
                gfx.image(R.board_art.hint, dst, rgba(255, 255, 255, R.reduced_motion and 220 or 170 + 60 * math.sin(R.now * 5)))
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
            draw_relic(t, at, scale * BOARD_SCALE, alpha, aspect)
            if clipped then gfx.clip(R.BOARD_CLIP) end
        end
    end
    gfx.unclip()
end

local function draw_blockers(sx)
    local g = R.g
    for i = 0, CELLS - 1 do
        if cell_active(g, i) then
            local at = cell_pos(i) + vec2(sx, 0)
            local dst = rect.centered(at, size2.splat(STATE_SIZE))
            if g.ice[i] > 0 then gfx.image(R.board_art[g.ice[i] > 1 and "ice-2" or "ice-1"], dst, color.WHITE) end
            if g.chain[i] > 0 then gfx.image(R.board_art.chain, dst, color.WHITE) end
        end
    end
end

local tool_names = {"Pickaxe", "Dynamite", "Sunburst"}

local function draw_tools(inp)
    if R.word_time <= 0 or R.reduced_motion then
        R.say_at(R.tool >= 0 and "TAP A RELIC TO USE YOUR TOOL" or "CONNECT 4+ MATCHING NEIGHBORS.", vec2(240, 766 + R.drop), 13, PAL_WHITE, 0)
    end
    local y = TOOLS_Y + R.drop
    for k = 0, 2 do
        local x = 63 + k * 112
        local r = rect(x - TOOL_SIZE / 2, y, TOOL_SIZE, TOOL_SIZE)
        local state = art.tool_state(R.g.tools[k + 1], R.tool == k, r:contains(inp.pos), inp.down,
                                     inp.press_pos ~= nil and r:contains(inp.press_pos), inp.hover, R.phase == PH_IDLE)
        gfx.image(R.board_art[art.tools[k + 1] .. "-" .. state], r:inflate(5), color.WHITE)
        gfx.circle(vec2(x + 29, y + 6), 13, rgba(44, 88, 61))
        R.say(tostring(R.g.tools[k + 1]), rect(x + 16, y - 7, 26, 26), 16, PAL_CREAM)
        R.say_at(tool_names[k + 1], vec2(x, y + TOOL_SIZE + 12), 15, PAL_CREAM, 0)
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
    local guide = rect(387, y + 14, 63, 55)
    gfx.image(R.board_art.guide, guide, color.WHITE)
    R.say_at("GUIDE", vec2(419, y + TOOL_SIZE + 11), 12, PAL_WHITE, 0)
    if R.tapped(guide) then R.overlay = R.OV_GUIDE end
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
    if rules.game_check_end(R.g) then
        R.selected, R.tool, R.hint_a, R.hint_b = -1, -1, -1, -1
        R.notice("No moves. Board reshuffled.")
    end
    if R.g.won then R.overlay = R.OV_RESULT; R.tone(880)
    elseif R.g.lost then R.overlay = R.OV_FAILED; R.tone(165) end
    R.idle_time = 0
end

function R.board_update(dt)
    if R.art_review then return end
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
    if R.idle_time > 5 and R.hint_a < 0 and R.phase == PH_IDLE and not R.g.won and not R.g.lost then
        local ok, a, b = rules.game_hint(R.g)
        if ok then R.hint_a, R.hint_b = a, b
        else settle() end   -- idle/resumed dead boards need the same recovery as a completed fall
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
    draw_tools(inp)
    if app.arg("art-states") then art.draw_catalogue(R) end
    board_input(inp)
end

return R
