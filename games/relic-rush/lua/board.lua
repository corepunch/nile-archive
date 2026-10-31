-- board.lua — the expedition screen: HUD, hex board, relic animation phases,
-- tools and swipe / tap input.
--
-- Phases: SWAP (relics trade places, then the wave clears), REJECT (they
-- slide back), CLEAR (matched relics pop) and FALL (diagonal trickling around holes and locks); after a fall the board is checked again, so cascades chain.
local R = require("state")
local rules = require("rules")
local art = require("art")
R.piece_width = 2 * R.HEX_R * 128 / 112   -- maximum registered canvas width for refill clipping
rules.bind_view(R)
local CELLS, HEX_R, SCREEN_H = rules.CELLS, R.HEX_R, R.SCREEN_H
local PH_IDLE = R.PH_IDLE
local PAL_GOLD, PAL_CREAM, PAL_WHITE = R.PAL_GOLD, R.PAL_CREAM, R.PAL_WHITE
local NORMAL, PRISM = rules.NORMAL, rules.PRISM
local hex_q, hex_r, hex_neighbor, cell_active = rules.hex_q, rules.hex_r, rules.hex_neighbor, rules.game_cell_active
local rgba = color
local PI = math.pi

-- Preserve the authored cell-mask registration and the guide's icon size;
-- only live board pieces use the enlarged board scale.
local ART_HEX_R, ART_CELL_SIZE = 26.5, 46
local BOARD_SCALE = HEX_R / ART_HEX_R
local ART_STATE_SIZE = (ART_HEX_R - .8) * 2
local STATE_SIZE = 2 * HEX_R
local HEX_DY = 1.732050808 * HEX_R
R.board_origin = vec2(240, 434)
local TOOLS_Y, TOOL_SIZE = 808, art.tool_size

-- The screen is 480 wide and at least 900 tall; tall phones add height. The
-- bottom group moves down by all of it (R.drop) and the board by half.
function R.layout()
    R.drop = app.screen().h - SCREEN_H
    R.board_origin = vec2(240, 434 + R.drop / 2)
    local half_w = (1.5 * rules.HEX_RADIUS + 1) * HEX_R + 6
    local half_h = (rules.HEX_RADIUS + .5) * HEX_DY + 6
    R.BOARD_CLIP = rect.centered(R.board_origin, size2(half_w * 2, half_h * 2))
end

local cell_pos = R.cell_pos

-------------------------------------------------------------------- drawing

function R.draw_relic(t, at, scale, alpha, aspect, board)
    if t.kind < 0 then return end
    -- Hex silhouettes meet all six neighboring edges; other silhouettes fit
    -- the cell's inscribed square. Account for the authored 8px canvas gutter.
    local span = t.kind == R.hex_piece_kind and 2 or 1.732050808
    local s = (board and span * ART_HEX_R * 128 / 112 or ART_CELL_SIZE * .95) * scale
    local frame = (board and 2 * ART_HEX_R or ART_STATE_SIZE) * scale
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

local function draw_relics(sx)
    local g = R.g
    gfx.clip(R.BOARD_CLIP)
    for i = 0, CELLS - 1 do
        if cell_active(g, i) then
            local t, at, scale, alpha, aspect, clip = R.piece_pose(i, sx)
            if clip then gfx.clip(clip) end
            draw_relic(t, at, scale * BOARD_SCALE, alpha, aspect, true)
            if clip then gfx.clip(R.BOARD_CLIP) end
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

R.tool_notes = {"Pickaxe: tap a relic to break it.", "Dynamite: tap a relic to blast around it.",
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
            R.select_tool(k)
        end
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
    R.board_input(inp)
end

return R
