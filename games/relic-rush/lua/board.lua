-- board.lua — the expedition screen: HUD, hex board, relic animation phases,
-- tools and swipe / tap input.
--
-- Phases: SWAP (relics trade places, then the wave clears), REJECT (they
-- slide back), CLEAR (matched relics pop) and FALL (gravity per column
-- segment); after a fall the board is checked again, so cascades chain.
local R = require("state")
local rules = require("rules")
local art = require("art")
local CELLS, HEX_R, SCREEN_H = rules.CELLS, R.HEX_R, R.SCREEN_H
local PH_IDLE, PH_SWAP, PH_REJECT, PH_CLEAR, PH_FALL = R.PH_IDLE, R.PH_SWAP, R.PH_REJECT, R.PH_CLEAR, R.PH_FALL
local PAL_CREAM, PAL_WHITE = R.PAL_CREAM, R.PAL_WHITE
local NORMAL, BOMB, PRISM = rules.NORMAL, rules.BOMB, rules.PRISM
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
local board_origin = vec2(240, 434)
local TOOLS_Y, TOOL_SIZE = 808, art.tool_size

-- The screen is 480 wide and at least 900 tall; tall phones add height. The
-- bottom group moves down by all of it (R.drop) and the board by half.
function R.layout()
    R.drop = app.screen().h - SCREEN_H
    board_origin = vec2(240, 434 + R.drop / 2)
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

-- The expedition HUD follows the portrait match-3 convention (Royal Match, Toon
-- Blast, Homescapes): one band fixed to the top edge holding a large Moves
-- medallion, goal icons with their remaining counts beneath, and pause; the
-- tools sit in a matching tray along the bottom edge. Nothing else covers the
-- painting, and the board takes the space between.
-- Repeated goal cells use the shared measured list, with stable objective keys.
-- Both bars stay slim so the painting carries the screen.
local HUD_BOTTOM, TRAY_TOP = 60, 832   -- the tools stand up out of the tray
local MOVES_AT, MOVES_R = vec2(56, 34), 40
function R.goal_entries()
    local g, l = R.g, rules.level_of(R.g)
    local entries = {
        {id="score", icon="score", remaining=math.max(0, l.score-g.score)},
        {id="idols", icon="idols", remaining=math.max(0, l.relics-g.relics)},
    }
    if l.soil>0 then entries[#entries+1]={id="sand",icon="sand",remaining=math.max(0,l.soil-g.dug)} end
    if g.initial_obstacles>0 then entries[#entries+1]={id="locks",icon="chain",remaining=math.max(0,g.obstacles)} end
    return entries
end
local goal_centers = {}
local function goal_icon(box, entry)
    goal_centers[entry.id] = box:center()
    local image = entry.icon=="score" and R.hud_art.score
        or entry.icon=="idols" and R.relics[rules.RELIC_IDOL+1]
        or R.board_art[entry.icon]
    -- Collections landing on a goal make it bounce.
    local pulse = entry.id=="idols" and R.goal_pulse or entry.id=="score" and R.score_pulse or 0
    local s = 1 + math.sin(num.saturate(pulse / .22) * PI) * .16
    gfx.image(image, rect.centered(box:center(), box:size():scale(s)), rgba(255, 255, 255, entry.remaining==0 and 150 or 255))
end
local function goal_count(box, entry)
    if entry.remaining==0 then
        gfx.image(R.hud_art.complete, rect(box.x, box.y + (box.h - 22) / 2, 22, 22), color.WHITE)
    else
        text.inside(R.pal(PAL_CREAM, 15), box, vec2(0, .5), tostring(entry.remaining))
    end
end
local hud_form=ui.form{kind="row",gap=10,children={
    {kind="spacer",width=78},    -- the Moves medallion overhangs the band here
    {kind="row",panel=true,grow=1,padding={4,4,4,4},children={
        {kind="spacer",grow=1},
        {kind="list",id="goals",direction="row",gap=4,item=function(entry)
            return {kind="row",width=72,gap=4,align="center",children={
                {kind="custom",width=28,height=28,paint=function(box) goal_icon(box,entry) end},
                {kind="custom",width=40,height=24,paint=function(box) goal_count(box,entry) end},
            }}
        end},
        {kind="spacer",grow=1},
    }},
    {kind="spacer",width=46},    -- pause, drawn by the shared header
}}
-- A recessed jade plate inside the band, so the goals read as one group.
local hud_skin={
    panel=function(r)
        gfx.round_rect(r:offset(vec2(0,1)),15,rgba(255,226,150,70))
        gfx.round_rect_grad(r,15,rgba(5,26,24,235),rgba(9,40,36,235))
        gfx.round_rect_line(r,15,1.5,rgba(212,175,95,170))
    end,
    label=function() end,
}

-- A jade band with a gold trim; `top` true hangs it from the top edge, false
-- stands it on the bottom edge. Both run under the safe areas.
local function draw_band(edge, top)
    local full = app.bleed()
    gfx.bleed(true)
    local r = top and rect(full.x, full.y, full.w, edge - full.y) or rect(full.x, edge, full.w, full.y + full.h - edge)
    gfx.rect_grad(rect(full.x, top and edge or edge - 14, full.w, 14),
                  rgba(0, 0, 0, top and 70 or 0), rgba(0, 0, 0, top and 0 or 70))   -- soft shadow on the board side
    gfx.rect_grad(r, top and rgba(9, 44, 40) or rgba(17, 70, 60), top and rgba(17, 70, 60) or rgba(9, 44, 40))
    gfx.rect(rect(full.x, edge - 2, full.w, 4), rgba(116, 74, 33))
    gfx.rect(rect(full.x, edge - 1, full.w, 2), rgba(236, 196, 112))
    gfx.bleed(false)
end

-- Hexagonal medallion, echoing the board cells: gold rim, jade face, the
-- remaining moves large inside. It warms to red over the last five moves.
local function draw_moves()
    local c, r, a = MOVES_AT, MOVES_R, 0   -- flat-top, like the cells
    local moves = R.g.moves
    local urgent = moves <= 5 and not R.g.won
    if urgent and not R.reduced_motion then
        gfx.additive(true)
        gfx.glow(c, r + 14, rgba(255, 92, 40, 70 + 50 * math.sin(R.now * 6)), rgba(255, 92, 40, 0))
        gfx.additive(false)
    end
    gfx.ngon(c + vec2(0, 5), r, 6, a, rgba(3, 20, 18, 150))
    gfx.ngon(c, r, 6, a, rgba(116, 74, 33))
    gfx.ngon(c, r - 2, 6, a, rgba(236, 196, 112))
    gfx.ngon(c + vec2(0, 2), r - 5, 6, a, rgba(176, 120, 48))
    gfx.ngon(c, r - 7, 6, a, urgent and rgba(112, 34, 24) or rgba(12, 62, 52))
    gfx.glow(c + vec2(0, -4), r - 12, urgent and rgba(178, 64, 40) or rgba(36, 124, 96), urgent and rgba(112, 34, 24, 0) or rgba(12, 62, 52, 0))
    text.inside(R.pal(PAL_CREAM, 9), rect.centered(c + vec2(0, -17), size2(56, 12)), vec2(.5, .5), "MOVES")
    local s = R.pal(urgent and PAL_WHITE or PAL_GOLD, 29)
    text.inside(s, rect.centered(c + vec2(0, 5), size2(62, 34)), vec2(.5, .5), tostring(moves))
end

function R.goal_target(kind)
    -- Collection flights land on the goal they advance.
    return goal_centers[kind==rules.RELIC_IDOL and "idols" or "score"] or vec2(250, 30)
end
local function draw_hud()
    draw_band(HUD_BOTTOM, true)
    draw_band(TRAY_TOP + R.drop, false)
    assert(hud_form:set_items("goals",R.goal_entries()))
    hud_form:draw(rect(14,8,452,44),hud_skin,{interactive=false})
    draw_moves()
end
R.hud_form=hud_form

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

local tool_notes = {"Pickaxe: tap a relic to break it.", "Dynamite: tap a relic to blast around it.",
                    "Sunburst: tap a relic to clear its three lines."}

-- Three tools, evenly spaced in the tray; their names and the rules live in
-- the toast and the Explorer's Guide (in Pause), as in other match-3 games.
local function draw_tools(inp)
    local y = TOOLS_Y + R.drop
    for k = 0, 2 do
        local x = 240 + (k - 1) * 120
        local r = rect(x - TOOL_SIZE / 2, y, TOOL_SIZE, TOOL_SIZE)
        local state = art.tool_state(R.g.tools[k + 1], R.tool == k, r:contains(inp.pos), inp.down,
                                     inp.press_pos ~= nil and r:contains(inp.press_pos), inp.hover, R.phase == PH_IDLE)
        gfx.round_rect(r:inflate(7):offset(vec2(0, 2)), 22, rgba(4, 24, 22, 150))   -- a socket in the tray
        gfx.image(R.board_art[art.tools[k + 1] .. "-" .. state], r:inflate(5), color.WHITE)
        gfx.circle(vec2(x + 31, y + 4), 14, rgba(116, 74, 33))
        gfx.circle(vec2(x + 31, y + 4), 12, R.g.tools[k + 1] > 0 and rgba(46, 112, 70) or rgba(75, 94, 80))
        R.say(tostring(R.g.tools[k + 1]), rect(x + 18, y - 9, 26, 26), 16, PAL_CREAM)
        if R.tapped(r) and R.phase == PH_IDLE then
            if R.g.tools[k + 1] > 0 then
                R.tool = R.tool == k and -1 or k
                R.selected = -1
                R.notice(R.tool < 0 and "Tool put away." or tool_notes[k + 1])
            else
                R.notice("No charges left. More tools next expedition.")
            end
        end
    end
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
    draw_hud()
    R.draw_header(false)
    local sx = (not R.reduced_motion and R.shake > 0) and math.sin(R.now * 110) * R.shake * 15 or 0
    draw_cells(sx)
    draw_relics(sx)
    draw_blockers(sx)
    draw_tools(inp)
    if app.arg("art-states") then art.draw_catalogue(R) end
    if app.arg("hud-states") then art.draw_hud_catalogue(R) end
    board_input(inp)
end

return R
