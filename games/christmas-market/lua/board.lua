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
board_intro.bind(R, rules)
require("match3").bind_board_ui(R, rules, art.tools)
R.locked_notice = "Ice and tinsel must be cleared first."
local CELLS, HEX_R = rules.CELLS, R.HEX_R
local PH_IDLE = R.PH_IDLE
local NORMAL, PRISM = rules.NORMAL, rules.PRISM
local hex_q, hex_r, hex_neighbor, cell_active = rules.hex_q, rules.hex_r, rules.hex_neighbor, rules.game_cell_active
local rgba = color
local PI = math.pi

-- Keep the guide's icon size; only live board pieces use the enlarged board scale.
local ART_HEX_R, ART_CELL_SIZE = 26.5, 46
local BOARD_SCALE = HEX_R / ART_HEX_R
local ART_STATE_SIZE = (ART_HEX_R - .8) * 2
local STATE_SIZE = 2 * HEX_R
local CELL_FACE_R = HEX_R - .65
-- Registered edge sprites have a centreline radius of 46 px on a 128px canvas.
local EDGE_SIZE = 128 * CELL_FACE_R / 46
local INSET_SNOW_SIZE = 128 * (CELL_FACE_R - 7.5) / 46
local FESTIVE = not app.arg("default-match3")
local BOARD_FRAME_SIZE = FESTIVE and 2 * CELL_FACE_R / BOARD_SCALE or 2 * ART_HEX_R
local cell_pos = R.cell_pos

-------------------------------------------------------------------- drawing

function R.draw_relic(t, at, scale, alpha, aspect, board)
    if t.kind < 0 then return end
    -- Same piece size as Relic Rush: the whole 128px canvas, gutter included,
    -- spans 95% of the authored cell, so pieces never crowd the cell edges.
    local s = ART_CELL_SIZE * .95 * scale
    local frame = (board and BOARD_FRAME_SIZE or ART_STATE_SIZE) * scale
    local dst = rect.centered(at, size2(frame * aspect, frame / aspect))
    local tint = rgba(255, 255, 255, alpha)
    -- Authored frames leave the matching kind visible in every optional pack.
    if t.special ~= PRISM then
        local inner = t.special == NORMAL and 1 or .72
        local h = s / aspect * inner
        local lift = FESTIVE and art.piece_lift[t.kind] or 0
        gfx.image(R.relics[t.kind + 1], rect.centered(vec2(at.x, at.y - lift * h), size2(s * aspect * inner, h)), tint)
    end
    if t.special ~= NORMAL then gfx.image(R.board_art[art.specials[t.special]], dst, tint) end
end
local draw_relic = R.draw_relic

local function wrapf(v, m) return v - m * math.floor(v / m) end

local function draw_backdrop()
    local scene = R.scenes[R.g.level >= 5 and 2 or 1]
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

local function draw_cells(sx)
    local g = R.g
    local intro = R.intro
    local fade = intro and intro:fade() or 1
    for i = 0, CELLS - 1 do
        local active, scale, turn, lift, flash = cell_active(g, i), 1, 0, 0, 0
        if intro and active then scale, turn, lift, flash = intro:cell(i) end
        if active and scale > .02 then
            local at = cell_pos(i) + vec2(sx, lift)
            -- Match Relic Rush's flat wells. The painted Christmas cell mask
            -- had its own bevel, doubling the rim around every treat.
            local face = (hex_q(i) - hex_r(i)) % 2 == 1 and rgba(24, 65, 58) or rgba(29, 73, 63)
            local radius = CELL_FACE_R * scale
            gfx.ngon(at + vec2(0, scale), (HEX_R + .25) * scale, 6, turn, rgba(11, 34, 36, 255 * fade))
            if g.soil[i] > 0 and not FESTIVE then
                gfx.image_hex(R.board_art.sand, art.snow_source, at, radius, turn, rgba(255, 255, 255, 255 * fade))
            else
                gfx.ngon_grad(at, radius, 6, turn, color.alpha(color.shade(face, 1.26), fade),
                              color.alpha(color.shade(face, .77), fade))
            end
            for d = 0, 5 do   -- a fine champagne rim along the exposed sides
                if not cell_active(g, hex_neighbor(i, d)) then
                    local a, b = turn + d * PI / 3, turn + (d + 1) * PI / 3
                    gfx.line(at + vec2.polar(a, radius), at + vec2.polar(b, radius),
                             1.1 * scale, rgba(239, 212, 154, 220 * fade))
                end
            end
            if FESTIVE and g.soil[i] > 0 then
                local size = (g.ice[i] > 0 or g.chain[i] > 0) and INSET_SNOW_SIZE or EDGE_SIZE
                local snow = rect.centered(at, size2.splat(size * scale))
                gfx.image_rot(R.board_art["sand-edge"], snow, turn, color.alpha(color.WHITE, fade))
            end
            local dst = rect.centered(at, size2.splat(FESTIVE and 2 * radius or STATE_SIZE * scale))
            if flash > 0 then   -- it opens glowing
                R.vfx_halo(at, HEX_R * 1.6 * scale, rgba(255, 226, 150, 120 * flash))
                gfx.additive(true)
                gfx.ngon(at, (HEX_R - .5) * scale, 6, turn, rgba(255, 226, 150, 110 * flash))
                gfx.additive(false)
            end
            if i == R.selected then
                gfx.image_rot(R.board_art.selected, dst, turn, color.WHITE)
            elseif (i == R.hint_a or i == R.hint_b) and R.phase == PH_IDLE then
                gfx.image_rot(R.board_art.hint, dst, turn, rgba(255, 255, 255, R.reduced_motion and 220 or 170 + 60 * math.sin(R.now * 5)))
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
        local tinsel = g.chain[i] > 0
        local ice = g.ice[i] > 0
        if (tinsel or ice) and cell_active(g, i) then
            local at = cell_pos(i) + vec2(sx, 0)
            local visible, scale, alpha = true, 1, 1
            if R.intro then visible, scale, alpha = R.intro:blocker(i); alpha = alpha * R.intro:fade() end
            if visible then
                local dst = rect.centered(at, size2.splat((FESTIVE and EDGE_SIZE or STATE_SIZE) * scale))
                local tint = rgba(255, 255, 255, 255 * alpha)
                if ice then
                    local name = g.ice[i] > 1 and "ice-2" or "ice-1"
                    gfx.image(R.board_art[FESTIVE and name .. "-edge" or name], dst, tint)
                end
                if tinsel then
                    gfx.image(FESTIVE and R.board_art["chain-board"] or R.board_art.chain, dst, tint)
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

R.tool_notes = {"Hammer: tap a treat to break it.", "Firecracker: tap a treat to blast around it.",
                "Star wand: tap a treat to clear its three lines."}

---------------------------------------------------------------------- input

function R.board_screen(inp, dt)
    draw_backdrop()
    local intro = R.intro
    R.draw_board_hud()
    local sx = (not R.reduced_motion and R.shake > 0) and math.sin(R.now * 110) * R.shake * 15 or 0
    draw_cells(sx)
    -- Overhanging blockers sit below treats, including those in adjacent cells.
    if FESTIVE then draw_blockers(sx) end
    draw_relics(sx)
    if not FESTIVE then draw_blockers(sx) end
    if intro then draw_sheen(sx) end
    R.draw_board_tools(inp)
    if app.arg("art-states") then art.draw_catalogue(R) end
    if app.arg("hud-states") then art.draw_hud_catalogue(R) end
    R.board_input(inp)
end

return R
