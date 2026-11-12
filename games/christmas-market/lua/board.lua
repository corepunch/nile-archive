-- board.lua — the expedition screen: HUD, hex board, relic animation phases,
-- tools and swipe / tap input.
--
-- Phases: SWAP (relics trade places, then the wave clears), REJECT (they
-- slide back), CLEAR (matched relics pop) and FALL (diagonal trickling around holes and locks); after a fall the board is checked again, so cascades chain.
local R = require("state")
local rules = require("rules")
local art = require("art")
local elements = require("match3.elements_view")
R.piece_width = 2 * R.HEX_R * 128 / 112   -- maximum registered canvas width for refill clipping
rules.bind_view(R)
local words = require("match3.game").config().board   -- data/game.json
R.kudos_words, R.tool_notes = words.kudos or R.kudos_words, words.tool_notes or R.tool_notes
R.locked_notice = words.locked
board_intro.bind(R, rules)
require("match3").bind_board_ui(R, rules, art.tools)
local CELLS, HEX_R = rules.CELLS, R.HEX_R
local NORMAL = rules.NORMAL
local hex_q, hex_r, cell_active = rules.hex_q, rules.hex_r, rules.game_cell_active
local rgba = color

-- Keep the guide's icon size; only live board pieces use the enlarged board scale.
local ART_HEX_R, ART_CELL_SIZE = 26.5, 46
local BOARD_SCALE = HEX_R / ART_HEX_R
local ART_STATE_SIZE = (ART_HEX_R - .8) * 2
local STATE_SIZE = 2 * HEX_R
local CELL_FACE_R = HEX_R - .65
-- Registered edge sprites have a centreline radius of 46 px on a 128px canvas.
local FESTIVE = not app.arg("default-match3")
local BOARD_FRAME_SIZE = FESTIVE and 2 * CELL_FACE_R / BOARD_SCALE or 2 * ART_HEX_R
local cell_pos = R.cell_pos

-------------------------------------------------------------------- drawing

function R.draw_relic(t, at, scale, alpha, aspect, board)
    if elements.delivery(R, rules, t, at, scale, alpha, aspect, ART_CELL_SIZE * .95) then return end
    if t.kind < 0 then return end
    -- Same piece size as Relic Rush: the whole 128px canvas, gutter included,
    -- spans 95% of the authored cell, so pieces never crowd the cell edges.
    local s = ART_CELL_SIZE * .95 * scale
    local frame = (board and BOARD_FRAME_SIZE or ART_STATE_SIZE) * scale
    local dst = rect.centered(at, size2(frame * aspect, frame / aspect))
    local tint = rgba(255, 255, 255, alpha)
    if t.special ~= NORMAL then
        gfx.image(R.board_art[art.specials[t.special]],dst,tint)
    else
        gfx.image(R.relics[t.kind+1],rect.centered(at,size2(s*aspect,s/aspect)),tint)
    end
end
local draw_relic = R.draw_relic

local function wrapf(v, m) return v - m * math.floor(v / m) end

local function draw_backdrop()
    local scene = R.scenes[rules.level_of(R.g).background or (R.g.level >= 5 and 2 or 1)]
    local tex = scene.tex and scene or R.backdrop
    local full = app.bleed()
    local size = texture.size(tex)
    gfx.bleed(true)
    gfx.image(tex, R.backdrop_rect(size, full), color.WHITE)   -- engine layout: bottom-anchored
    gfx.rect(full, rgba(5, 30, 29, 35))
    gfx.bleed(false)
    for i = 0, 11 do   -- drifting motes of sunlight
        local p = vec2(20 + wrapf(i * 93 + R.now * (i % 2 == 1 and 3 or -4) + 480, 440), 170 + wrapf(i * 139 + R.now * 5, 620))
        gfx.circle(p, 1.5 + math.sin(R.now + i) * .5, rgba(245, 250, 255, 130 + 50 * math.sin(R.now + i)))
    end
end

local function draw_cells(sx, foreground)
    local g,intro=R.g,R.intro
    local fade=intro and intro:fade() or 1
    for i=0,CELLS-1 do
        if cell_active(g,i) then
            local scale,turn,lift,flash=1,0,0,0
            if intro then scale,turn,lift,flash=intro:cell(i) end
            if scale>.02 then
                local at=cell_pos(i)+vec2(sx,lift)
                if not foreground then
                    -- Plain flat hex ground: no authored frame, bevel or edge trim.
                    local face=(hex_q(i)-hex_r(i))%2==1 and rgba(72,72,72) or rgba(84,84,84)
                    gfx.ngon(at,HEX_R*scale,6,turn,color.alpha(face,fade))
                elseif flash>0 then
                    R.vfx_halo(at,HEX_R*1.6*scale,rgba(255,226,150,120*flash))
                end
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
            if not elements.covers_cherry(g, i, t) then
                if clip then gfx.clip(clip) end
                draw_relic(t, at, scale * BOARD_SCALE * elements.piece_scale(g, i) * elements.selection_scale(R,i), alpha, aspect, true)
                if clip then gfx.clip(R.BOARD_CLIP) end
            end
        end
    end
    gfx.unclip()
end

local function draw_blockers(sx)
    local g = R.g
    for i = 0, CELLS - 1 do
        local tinsel = g.chain[i] > 0
        local ice = g.ice[i] > 0
        if (tinsel or ice) and cell_active(g, i) then
            local at = cell_pos(i) + vec2(sx, 0)
            local visible, scale, alpha = true, 1, 1
            if R.intro then visible, scale, alpha = R.intro:blocker(i); alpha = alpha * R.intro:fade() end
            if visible then
                local dst = rect.centered(at, size2.splat(STATE_SIZE * scale))
                local tint = rgba(255, 255, 255, 255 * alpha)
                if ice then
                    local name = g.ice[i] > 1 and "ice-2" or "ice-1"
                    gfx.image(R.board_art[name], dst, tint)
                end
                if tinsel then
                    gfx.image(elements.chain(R,g,i), dst, tint)
                end
            end
        end
    end
end

-- The light running across the board as it goes live.
local function draw_sheen(sx)
    for i = 0, CELLS - 1 do
        local s = cell_active(R.g, i) and R.intro:sheen(i) or 0
        if s > .02 then R.vfx_halo(cell_pos(i) + vec2(sx, 0), HEX_R * 1.9, rgba(255, 238, 186, 150 * s)) end
    end
end


---------------------------------------------------------------------- input

function R.board_screen(inp, dt)
    draw_backdrop()
    local intro = R.intro
    R.draw_board_hud()
    local sx = (not R.reduced_motion and R.shake > 0) and math.sin(R.now * 110) * R.shake * 15 or 0
    draw_cells(sx, false)
    elements.ground(R, rules, sx)
    draw_cells(sx, true)
    -- Overhanging blockers sit below treats, including those in adjacent cells.
    draw_relics(sx)
    draw_blockers(sx)
    elements.blockers(R, rules, sx)
    if intro then draw_sheen(sx) end
    R.draw_board_tools(inp)
    if app.arg("art-states") then art.draw_catalogue(R) end
    if app.arg("hud-states") then art.draw_hud_catalogue(R) end
    R.board_input(inp)
end

return R
