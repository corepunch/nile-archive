-- board.lua — the expedition screen: HUD, hex board, relic animation phases,
-- tools and swipe / tap input.
--
-- Phases: SWAP (relics trade places, then the wave clears), REJECT (they
-- slide back), CLEAR (matched relics pop) and FALL (diagonal trickling around holes and locks); after a fall the board is checked again, so cascades chain.
local R = require("state")
local rules = require("rules")
local art = require("art")
local elements = require("match3.elements_view")
R.piece_width = 2 * R.HEX_R * 128 / 112   -- conservative canvas width for animated refill clipping
rules.bind_view(R)
local words = require("match3.game").config().board   -- data/game.json
R.kudos_words, R.tool_notes = words.kudos or R.kudos_words, words.tool_notes or R.tool_notes
R.locked_notice = words.locked
board_intro.bind(R, rules)
require("match3").bind_board_ui(R, rules, art.tools)
local CELLS, HEX_R = rules.CELLS, R.HEX_R
local PH_IDLE = R.PH_IDLE
local PAL_WHITE = R.PAL_WHITE
local NORMAL, PRISM = rules.NORMAL, rules.PRISM
local hex_q, hex_r, hex_neighbor, cell_active = rules.hex_q, rules.hex_r, rules.hex_neighbor, rules.game_cell_active
local rgba = color
local PI = math.pi

-- Preserve the guide's icon size; only live board pieces follow the board's geometry.
local ART_HEX_R, ART_CELL_SIZE = 26.5, 46
local BOARD_SCALE = HEX_R / ART_HEX_R
local ART_STATE_SIZE = (ART_HEX_R - .8) * 2
local STATE_SIZE = ART_STATE_SIZE * BOARD_SCALE
local CELL_FACE_R = HEX_R - .65
local EDGE_SIZE = 128 * CELL_FACE_R / 46
local INSET_SAND_SIZE = 128 * (CELL_FACE_R - 7.5) / 46
local cell_pos = R.cell_pos

local object_form = ui.form{root={kind="row", panel=true, role="quest", padding={6,2,10,2}, gap=5, align="center", children={
    {kind="image", id="icon", width=37, height=34},
    {kind="label", id="label", grow=1, em=19, text_style="cream", text_align="start"},
}}}

local function show_object(object, found)
    object_form:set("icon", R.board_art[object.key])
    object_form:set("label", (found and "Recovered · " or "Recover · ") .. object.name)
    object_form:draw(rect(10, R.hud_rect.y - 50, 298, 40), R.skin, {interactive=false})
end

function R.draw_story_item()
    local beat = R.story_current
    if beat and beat.key:match("^after%-") then
        local object = rules.levels[tonumber(beat.key:sub(-2))].quest_object
        if object then show_object(object, true) end
    end
end

-------------------------------------------------------------------- drawing

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
    if t.special >= rules.ROW and t.special <= rules.DIAGONAL then
        local angle = math.pi / 6 + (t.special - rules.ROW) * math.pi / 3
        gfx.image_striped(R.relics[t.kind + 1], rect.centered(at, size2(s * aspect, s / aspect)),
            angle, art.stripes.repeats, art.stripes.width, art.stripes.ink, tint)
    elseif t.special == rules.BOMB or t.special == PRISM then
        gfx.image(R.board_art[art.specials[t.special]], dst, tint)
    else
        gfx.image(R.relics[t.kind + 1], rect.centered(at, size2(s * aspect, s / aspect)), tint)
    end
end
local draw_relic = R.draw_relic

-- The guide and board share the ice rim and its remaining-hit indicator.
function R.draw_ice(hits, at, scale, alpha, material_only)
    local name = hits > 1 and "ice-2" or "ice-1"
    local edge = R.board_art[name .. "-edge"]
    local size = edge and EDGE_SIZE / BOARD_SCALE or ART_STATE_SIZE
    local dst = rect.centered(at,size2.splat(size * scale))
    gfx.image(edge or R.board_art[name], dst, rgba(255,255,255,(edge and 255 or art.indicators.ice_opacity) * alpha))
    if material_only then return end
    R.draw_ice_count(hits,at,scale,alpha)
end

function R.draw_ice_count(hits,at,scale,alpha)
    local badge = at
    gfx.circle(badge,8 * scale,rgba(15,57,81,230 * alpha))
    local style = R.pal(PAL_WHITE,12 * scale)
    for _, key in ipairs{"fill","fill2","outline","shadow"} do
        if style[key] then style[key] = color.alpha(style[key],alpha) end
    end
    text.inside(style,rect.centered(badge,size2.splat(20 * scale)),vec2(.5,.5),tostring(hits))
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

local function draw_cells(sx, foreground)
    local g = R.g
    local intro = R.intro
    local fade = intro and intro:fade() or 1
    for i = 0, CELLS - 1 do
        local active, scale, turn, lift, flash = cell_active(g, i), 1, 0, 0, 0
        if intro and active then scale, turn, lift, flash = intro:cell(i) end
        if active and scale > .02 then
            local at = cell_pos(i) + vec2(sx, lift)
            if not foreground then
                gfx.ngon(at + vec2(0, 2), (HEX_R + .7) * scale, 6, turn, rgba(7, 37, 34, 255 * fade))
                for d = 0, 5 do   -- a gold rim where the board ends
                    if not cell_active(g, hex_neighbor(i, d)) then
                        local a, b = turn + d * PI / 3, turn + (d + 1) * PI / 3
                        gfx.line(at + vec2.polar(a, (HEX_R - .5) * scale), at + vec2.polar(b, (HEX_R - .5) * scale), 2, rgba(212, 175, 95, 255 * fade))
                    end
                end
                local has_state = g.soil[i] > 0 or g.ice[i] > 0 or g.tiles[i].special ~= NORMAL or i == R.selected
                                  or ((i == R.hint_a or i == R.hint_b) and R.phase == PH_IDLE)
                local tile = has_state and rgba(13, 47, 41)
                          or (hex_q(i) - hex_r(i)) % 2 == 1 and rgba(29, 82, 67) or rgba(35, 94, 73)
                gfx.ngon_grad(at, CELL_FACE_R * scale, 6, turn, color.alpha(color.shade(tile, 1.26), fade),
                              color.alpha(color.shade(tile, .77), fade))
            else
                local dst = rect.centered(at, size2.splat(STATE_SIZE * scale))
                if g.soil[i] > 0 then
                    local edge = R.board_art["sand-edge"]
                    local size = g.ice[i] > 0 and INSET_SAND_SIZE or EDGE_SIZE
                    local sand = edge and rect.centered(at, size2.splat(size * scale)) or dst
                    gfx.image_rot(edge or R.board_art.sand, sand, turn, color.alpha(color.WHITE, fade))
                end
                if flash > 0 then
                    R.vfx_halo(at, HEX_R * 1.6 * scale, rgba(255, 226, 150, 120 * flash))
                    gfx.additive(true)
                    gfx.ngon(at, (HEX_R - .5) * scale, 6, turn, rgba(255, 226, 150, 110 * flash))
                    gfx.additive(false)
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
            if clip then gfx.clip(clip) end
            draw_relic(t, at, scale * elements.piece_scale(g, i), alpha, aspect, true)
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
            local visible, scale, alpha = true, 1, 1
            if R.intro then visible, scale, alpha = R.intro:blocker(i); alpha = alpha * R.intro:fade() end
            if visible then
                local dst = rect.centered(at, size2.splat(STATE_SIZE * scale))
                local tint = rgba(255, 255, 255, 255 * alpha)
                if g.ice[i] > 0 then
                    R.draw_ice(g.ice[i],at,BOARD_SCALE * scale,alpha,true)
                end
                if g.chain[i] > 0 then gfx.image(R.board_art.chain, dst, tint) end
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
    local object = rules.level_of(R.g).quest_object
    if object and R.g.objects[1] and R.g.objects[1].art and not story.active()
        and R.overlay == R.OV_NONE and not intro then
        show_object(object, R.g.discovered > 0)
    end
    local sx = (not R.reduced_motion and R.shake > 0) and math.sin(R.now * 110) * R.shake * 15 or 0
    draw_cells(sx, false)
    elements.ground(R, rules, sx)
    draw_cells(sx, true)
    draw_relics(sx)
    draw_blockers(sx)
    elements.blockers(R, rules, sx)
    elements.highlights(R, rules, sx, STATE_SIZE)
    if intro then draw_sheen(sx) end
    for i = 0, CELLS - 1 do
        if cell_active(R.g,i) and R.g.ice[i] > 0 then
            local visible, scale, alpha = true, 1, 1
            if intro then visible, scale, alpha = intro:blocker(i); alpha = alpha * intro:fade() end
            if visible then R.draw_ice_count(R.g.ice[i],cell_pos(i)+vec2(sx,0),BOARD_SCALE*scale,alpha) end
        end
    end
    R.draw_board_tools(inp)
    if app.arg("art-states") then art.draw_catalogue(R) end
    if app.arg("stripe-states") then art.draw_stripe_catalogue(R) end
    if app.arg("hud-states") then art.draw_hud_catalogue(R) end
    R.board_input(inp)
end

return R
