-- board.lua — the expedition screen: HUD, hex board, relic animation phases,
-- tools and swipe / tap input.
--
-- Phases: SWAP (relics trade places, then the wave clears), REJECT (they
-- slide back), CLEAR (matched relics pop) and FALL (diagonal trickling around holes and locks); after a fall the board is checked again, so cascades chain.
local R = require("state")
local rules = require("rules")
local art = require("art")
R.piece_width = 46 * R.HEX_R / 26.5   -- authored sprite registration
rules.bind_view(R)
R.locked_notice = "Ice and tinsel must be cleared first."
local CELLS, HEX_R, SCREEN_H = rules.CELLS, R.HEX_R, R.SCREEN_H
local PH_IDLE = R.PH_IDLE
local PAL_CREAM, PAL_WHITE = R.PAL_CREAM, R.PAL_WHITE
local NORMAL, PRISM = rules.NORMAL, rules.PRISM
local hex_q, hex_r, hex_neighbor, cell_active = rules.hex_q, rules.hex_r, rules.hex_neighbor, rules.game_cell_active
local rgba = color
local PI = math.pi

-- Preserve the authored cell-mask registration and the guide's icon size;
-- only live board pieces use the enlarged board scale.
local ART_HEX_R, ART_CELL_SIZE = 26.5, 46
local BOARD_SCALE = HEX_R / ART_HEX_R
local ART_STATE_SIZE = (ART_HEX_R - .8) * 2
local STATE_SIZE = ART_STATE_SIZE * BOARD_SCALE
local HEX_DY = 1.732050808 * HEX_R
R.board_origin = vec2(240, 492)
local TOOLS_Y, TOOL_SIZE = 784, art.tool_size   -- square buttons leave room for labels below

-- The screen is 480 wide and at least 900 tall; tall phones add height. The
-- bottom group moves down by all of it (R.drop) and the board by half.
function R.layout()
    R.drop = app.screen().h - SCREEN_H
    R.board_origin = vec2(240, 492 + R.drop / 2)
    local half_w = (1.5 * rules.HEX_RADIUS + 1) * HEX_R + 6
    local half_h = (rules.HEX_RADIUS + .5) * HEX_DY + 6
    R.BOARD_CLIP = rect.centered(R.board_origin, size2(half_w * 2, half_h * 2))
end

local cell_pos = R.cell_pos

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
        gfx.circle(p, 1.5 + math.sin(R.now + i) * .5, rgba(245, 250, 255, 130 + 50 * math.sin(R.now + i)))
    end
end

-- One goal panel, a moves card and Elena's independent investigation cutout.
-- Repeated goal rows use the shared measured list, with stable objective keys.
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
local function goal_icon(box, entry)
    local image = entry.remaining==0 and R.hud_art.complete
        or entry.icon=="score" and R.hud_art.score
        or entry.icon=="idols" and R.relics[rules.RELIC_IDOL+1]
        or R.board_art[entry.icon]
    gfx.image(image, box, color.WHITE)
end
local hud_form=ui.form{kind="row",gap=8,children={
    {kind="column",panel=true,width=224,padding={12,8,12,10},gap=4,children={
        {kind="label",text="GOAL",height=18,em=14},
        {kind="list",id="goals",gap=4,item=function(row)
            local cells={}
            for _,entry in ipairs(row.entries) do
                cells[#cells+1]={kind="row",grow=1,gap=6,align="center",children={
                    {kind="custom",width=28,height=28,paint=function(box) goal_icon(box,entry) end},
                    {kind="label",text=entry.remaining==0 and "DONE" or tostring(entry.remaining),grow=1,em=17,text_align="start"},
                }}
            end
            return {kind="row",height=36,gap=8,children=cells}
        end},
    }},
    {kind="spacer",grow=1},
    {kind="column",panel=true,width=88,height=116,padding={8,8,8,10},gap=4,children={
        {kind="label",text="MOVES",height=18,em=14},
        {kind="label",id="moves",grow=1,em=43},
    }},
}}
local function hud_style(node)
    return style{font=R.font,size=(node.em or 17)*1.171875,fill=rgba(78,52,27)}
end
local hud_skin={
    style=hud_style,
    panel=function(r)
        gfx.shadow(r:offset(vec2(0,4)),16,8,rgba(0,0,0,85))
        gfx.round_rect(r,16,rgba(139,87,38))
        gfx.round_rect(r:inflate(-2),14,rgba(228,181,92))
        gfx.round_rect(r:inflate(-5),12,rgba(255,237,187))
        gfx.round_rect_line(r:inflate(-6),11,1,rgba(255,252,219,190))
    end,
    label=function(r,label,node)
        text.inside(hud_style(node),r,vec2(node.text_align=="start" and 0 or .5,.5),label)
    end,
}
function R.goal_target(kind)
    -- Collection flights land on the goal they advance, rather than the old HUD.
    local column=kind==rules.RELIC_IDOL and 1 or 0
    local entries=R.goal_entries()
    return #entries==2 and vec2(50,122+column*40) or vec2(50+column*104,122)
end
local function draw_hud()
    local entries, rows=R.goal_entries(),{}
    local per_row=#entries==2 and 1 or 2
    for i=1,#entries,per_row do
        local row={id=entries[i].id,entries={}}
        for j=i,math.min(#entries,i+per_row-1) do row.entries[#row.entries+1]=entries[j] end
        rows[#rows+1]=row
    end
    assert(hud_form:set_items("goals",rows))
    hud_form:set("moves",tostring(R.g.moves))
    -- Separate portrait texture/anchor will also work for later animated poses.
    if R.hud_art.elena then gfx.image(R.hud_art.elena,rect(242,18,132,174):fit(texture.size(R.hud_art.elena)),color.WHITE) end
    hud_form:draw(rect(24,74,432,116),hud_skin,{interactive=false})
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
            draw_relic(t, at, scale * BOARD_SCALE, alpha, aspect)
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

local tool_names = {"Hammer", "Firecracker", "Star wand"}

local function draw_tools(inp)
    if R.word_time <= 0 or R.reduced_motion then
        R.say_at(R.tool >= 0 and "TAP A TREAT TO USE YOUR TOOL" or "CONNECT 4+ MATCHING NEIGHBORS.", vec2(240, 766 + R.drop), 13, PAL_WHITE, 0)
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
            R.select_tool(k)
        end
    end
    local guide = rect(387, y + 14, 63, 55)
    gfx.image(R.board_art.guide, guide, color.WHITE)
    R.say_at("GUIDE", vec2(419, y + TOOL_SIZE + 11), 12, PAL_WHITE, 0)
    if R.tapped(guide) then R.overlay = R.OV_GUIDE end
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
    if app.arg("hud-states") then art.draw_hud_catalogue(R) end
    R.board_input(inp)
end

return R
