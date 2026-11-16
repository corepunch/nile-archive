-- board.lua — the expedition screen: HUD, hex board, relic animation phases,
-- tools and swipe / tap input.
--
-- Phases: SWAP (relics trade places, then the wave clears), REJECT (they
-- slide back), CLEAR (matched relics pop) and FALL (diagonal trickling around holes and locks); after a fall the board is checked again, so cascades chain.
local R = require("state")
local rules = require("rules")
local art = require("art")
local elements = require("match3.elements_view")
local skin = require("skin")
local neutral = app.arg("default-match3")
R.piece_width = 2 * R.HEX_R * 128 / 112   -- conservative canvas width for animated refill clipping
rules.bind_view(R)
if not neutral then
    for _, name in ipairs{"edge", "rim", "seam", "face"} do
        R.GROUND[name] = skin:color("board_" .. name)
    end
    R.GROUND.edge_width, R.GROUND.rim_width, R.GROUND.seam_width = 2.5, 3, .9
end
local words = require("match3.game").config().board   -- data/game.json
R.kudos_words, R.tool_notes = words.kudos or R.kudos_words, words.tool_notes or R.tool_notes
R.locked_notice = words.locked
board_intro.bind(R, rules)
local match3 = require("match3")
match3.bind_board_ui(R, rules, art.tools)
match3.bind_town_board_hud(R)

local CELLS, HEX_R = rules.CELLS, R.HEX_R
local NORMAL = rules.NORMAL
local cell_active = rules.game_cell_active
local rgba = color

-- Preserve the guide's icon size; only live board pieces follow the board's geometry.
local ART_HEX_R, ART_CELL_SIZE = 26.5, 46
local BOARD_SCALE = HEX_R / ART_HEX_R
local ART_STATE_SIZE = (ART_HEX_R - .8) * 2
local CELL_FACE_SIZE = 2 * (HEX_R - .65)
local cell_pos = R.cell_pos

-------------------------------------------------------------------- drawing

function R.board_piece_texture(kind)
    local level = rules.level_of(R.g)
    if level.story_piece and kind == level.goal_kind then
        return R.board_art["story-" .. level.story_piece]
    end
    local piece = R.g.resource_yields and R.g.resource_yields[kind]
    local pack = app.arg("tiles")
    if piece and (kind == level.goal_kind or piece.building or not neutral and (not pack or pack == "relics")) then
        return R.board_art["resource-" .. piece.key]
    end
    return R.relics[kind + 1]
end

function R.draw_relic(t, at, scale, alpha, aspect, board)
    if elements.delivery(R, rules, t, at, scale, alpha, aspect, ART_CELL_SIZE * .95 * (board and BOARD_SCALE or 1)) then return end
    if t.kind < 0 then return end
    -- Preserve the original piece canvas, including its transparent gutter.
    -- Filling the cell with the opaque interior makes pieces crowd its edges.
    local draw_scale = scale * (board and BOARD_SCALE or 1)
    local s = ART_CELL_SIZE * .95 * draw_scale
    local frame = ART_STATE_SIZE * draw_scale
    local dst = rect.centered(at, size2(frame * aspect, frame / aspect))
    local tint = rgba(255, 255, 255, alpha)
    local tex, area = board and R.board_piece_texture(t.kind) or R.relics[t.kind+1],
        rect.centered(at,size2(s*aspect,s/aspect))
    if t.special ~= NORMAL then tex, area = R.board_art[art.specials[t.special]], dst end
    if board then elements.piece_shadow(tex, area, alpha, s) end
    gfx.image(tex, area, tint)
end
local draw_relic = R.draw_relic

function R.board_goal_icon(l, goal)
    if goal == "oil" and l.dress then return l.dress.floor.covered end
end

local function wrapf(v, m) return v - m * math.floor(v / m) end

local function draw_backdrop()
    local scene = R.scenes[rules.level_of(R.g).background or (R.g.level >= 5 and 2 or 1)]
    local tex = scene.tex and scene or R.backdrop
    local full = app.bleed()   -- the jungle runs on under the status bar and the home indicator
    local size = texture.size(tex)
    gfx.bleed(true)
    gfx.image(tex, R.backdrop_rect(size, full), color.WHITE)   -- engine layout: bottom-anchored
    gfx.rect(full, rgba(5, 30, 29, 35))
    gfx.bleed(false)
    for i = 0, 11 do   -- drifting motes of sunlight
        local p = vec2(20 + wrapf(i * 93 + R.now * (i % 2 == 1 and 3 or -4) + 480, 440), 170 + wrapf(i * 139 + R.now * 5, 620))
        gfx.circle(p, 1.5 + math.sin(R.now + i) * .5, rgba(255, 228, 139, 70 + 50 * math.sin(R.now + i)))
    end
end

local function draw_relics(sx)
    local g = R.g
    local cover = elements.reveal_cover(R, rules)   -- a recovered find clears its pieces away
    if cover <= 0 then return end
    gfx.clip(R.BOARD_CLIP)
    for i = 0, CELLS - 1 do
        if cell_active(g, i) then
            local t, at, scale, alpha, aspect, clip = R.piece_pose(i, sx)
            alpha = alpha * cover
            if not elements.covers_cherry(g, i, t) then
                if clip then gfx.clip(clip) end
                draw_relic(t, at, scale * elements.piece_scale(g, i) * elements.selection_scale(R,i), alpha, aspect, true)
                if clip then gfx.clip(R.BOARD_CLIP) end
            end
        end
    end
    gfx.unclip()
end

local function draw_blockers(sx)
    local g = R.g
    local cover = elements.reveal_cover(R, rules)
    for i = 0, CELLS - 1 do
        if cell_active(g, i) and (g.ice[i] > 0 or g.chain[i] > 0) then
            local at = cell_pos(i) + vec2(sx, 0)
            local visible, scale, alpha = true, 1, 1
            if R.intro then visible, scale, alpha = R.intro:blocker(i); alpha = alpha * R.intro:fade() end
            if visible then
                local dst = rect.centered(at, size2.splat(CELL_FACE_SIZE * scale))
                local tint = rgba(255, 255, 255, 255 * alpha * cover)
                -- Generic ice is available to the engine's reference boards.
                if g.ice[i] > 0 then gfx.image(R.board_art[g.ice[i] > 1 and "ice-2" or "ice-1"], dst, tint) end
                if g.chain[i] > 0 then gfx.image(elements.chain(R,g,i), dst, tint) end
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
    local dress = not R.g.hs and rules.level_of(R.g).dress
    R.draw_board_hud()
    local sx = (not R.reduced_motion and R.shake > 0) and math.sin(R.now * 110) * R.shake * 15 or 0
    elements.ground(R, rules, sx, dress and dress.floor)
    draw_relics(sx)
    draw_blockers(sx)
    elements.blockers(R, rules, sx)
    if intro then draw_sheen(sx) end
    R.draw_board_tools(inp)
    if app.arg("art-states") == "dressing" then art.draw_dressing_catalogue(R)
    elseif app.arg("art-states") then art.draw_catalogue(R) end
    if app.arg("stripe-states") then art.draw_stripe_catalogue(R) end
    if app.arg("hud-states") then art.draw_hud_catalogue(R) end
    R.board_input(inp)
end

return R
