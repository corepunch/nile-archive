-- board.lua — the expedition screen: HUD, square board, relic animation phases,
-- tools and swipe / tap input.
--
-- Phases: SWAP (relics trade places, then the wave clears), REJECT (they
-- slide back), CLEAR (matched relics pop) and FALL (diagonal trickling around holes and locks); after a fall the board is checked again, so cascades chain.
local R = require("state")
local rules = require("rules")
local art = require("art")
local match3 = require("match3")
local elements = require("match3.elements_view")
local lantern_floor = {normal="square-plain", covered="square-target", double="square-double", tablet_hint=true}
R.HEX_R = 24
R.piece_width = 2 * R.HEX_R
rules.bind_view(R)
R.GROUND.seam_width = .65
local words = require("match3.game").config().board   -- lua/game_config.lua
R.kudos_words, R.tool_notes = words.kudos or R.kudos_words, words.tool_notes or R.tool_notes
R.locked_notice = words.locked
board_intro.bind(R, rules)
match3.bind_board_ui(R, rules)
match3.bind_town_board_hud(R)

function R.board_goal_icon(_, goal)
    if goal == "oil" then return lantern_floor.covered end
end
local CELLS, HEX_R = rules.CELLS, R.HEX_R
local cell_active = rules.game_cell_active
local rgba = color

-- The atlas preserves transparent gutters around each piece. Draw the board
-- canvas slightly larger than a cell so the painted silhouettes fill it.
local BOARD_ART_SIZE = R.cell_width * 1.06
local PREVIEW_ART_SIZE = 46 * .95
local cell_pos = R.cell_pos

-------------------------------------------------------------------- drawing

function R.board_piece_texture(kind)
    if R.g.resource_multipliers then return R.board_art["market-" .. kind] end
    return R.relics[kind + 1]
end

function R.draw_relic(t, at, scale, alpha, aspect, board)
    if t.kind < 0 then return end
    local s = (board and BOARD_ART_SIZE or PREVIEW_ART_SIZE) * scale
    local tint = rgba(255, 255, 255, alpha)
    local tex = board and R.board_piece_texture(t.kind) or R.relics[t.kind + 1]
    local area = rect.centered(at, size2(s * aspect, s / aspect))
    if board then elements.piece_shadow(tex, area, alpha, s) end
    gfx.image(tex, area, tint)
end
local draw_relic = R.draw_relic

local function wrapf(v, m) return v - m * math.floor(v / m) end

function R.draw_board_background(opacity)
    local scene = R.scenes[rules.level_of(R.g).background or (R.g.level >= 5 and 2 or 1)]
    local tex = scene.tex and scene or R.backdrop
    local full = app.bleed()
    local size = texture.size(tex)
    gfx.bleed(true)
    -- Keep the stalls' lit windows visible on the shorter phone.
    gfx.image(tex, R.backdrop_rect(size, full, 960), rgba(255, 255, 255, opacity * 255))
    gfx.bleed(false)
end

local function draw_motes()
    for i = 0, 11 do   -- drifting motes of sunlight
        local p = vec2(20 + wrapf(i * 93 + R.now * (i % 2 == 1 and 3 or -4) + 480, 440), 170 + wrapf(i * 139 + R.now * 5, 620))
        gfx.circle(p, 1.5 + math.sin(R.now + i) * .5, rgba(245, 250, 255, 130 + 50 * math.sin(R.now + i)))
    end
end

local function draw_relics(sx)
    local g = R.g
    local cover = elements.reveal_cover(R, rules)
    if cover <= 0 then return end
    gfx.clip(R.BOARD_CLIP)
    for i = 0, CELLS - 1 do
        if cell_active(g, i) then
            local t, at, scale, alpha, aspect, clip = R.piece_pose(i, sx)
            if clip then gfx.clip(clip) end
            draw_relic(t, at, scale * elements.selection_scale(R,i), alpha * cover, aspect, true)
            if clip then gfx.clip(R.BOARD_CLIP) end
        end
    end
    gfx.unclip()
end

-- The light running across the board as it goes live.
local function draw_sheen(sx)
    for i = 0, CELLS - 1 do
        local s = cell_active(R.g, i) and R.intro:sheen(i) or 0
        if s > .02 then R.vfx_halo(cell_pos(i) + vec2(sx, 0), HEX_R * 1.9, rgba(255, 238, 186, 150 * s)) end
    end
end


---------------------------------------------------------------------- input

-- The lantern floor: its pane art, for painting and for shattering.
function R.board_floor() return lantern_floor end

function R.board_screen(inp, dt)
    R.draw_board_background(1)
    draw_motes()
    local intro = R.intro
    R.draw_board_hud()
    local sx = (not R.reduced_motion and R.shake > 0) and math.sin(R.now * 110) * R.shake * 15 or 0
    elements.ground(R, rules, sx, R.board_floor())
    draw_relics(sx)
    elements.square_blockers(R, rules, sx)
    elements.blockers(R, rules, sx)
    if intro then draw_sheen(sx) end
    if app.arg("art-states") then art.draw_catalogue(R)
    else R.draw_board_tools(inp) end
    if app.arg("hud-states") then art.draw_hud_catalogue(R) end
    R.board_input(inp)
end

return R
