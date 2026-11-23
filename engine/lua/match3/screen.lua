-- The match-3 screen and its presentation bindings.
local match3 = require("match3")
local elements = require("match3.elements_view")
local V = {}

local square_floor = {normal="square-plain", covered="square-target", double="square-double", tablet_hint=true}

function V.bind(R, rules, config, art, base_pieces)
    local board = config.board
    local pieces = board.pieces or {}
    local background = board.background or {}
    local neutral, pack = app.arg("default-match3"), app.arg("tiles")
    local reference = app.arg("rome-reference-art")
    local default_pack = not pack or pack == config.packs[1]
    R.campaign_art = pieces.campaign_prefix and default_pack and not neutral and not reference

    R.piece_width = 2 * R.HEX_R
    rules.bind_view(R)
    R.GROUND.seam_width = .65
    R.kudos_words = board.kudos or R.kudos_words
    R.tool_notes = board.tool_notes or R.tool_notes
    R.locked_notice = board.locked
    if board.tutorial_chain then
        R.tutorial = require("match3.tutorial").new(R, rules, board.tutorial_chain, board.tutorial_goal)
    end
    board_intro.bind(R, rules)
    match3.bind_board_ui(R, rules)

    function R.board_floor(level)
        local dress = (level or rules.level_of(R.g)).dress
        return dress and dress.floor or square_floor
    end

    function R.board_goal_icon(level, goal)
        if goal == "oil" then return R.board_floor(level).covered end
    end

    function R.board_piece_texture(kind)
        local g = R.g
        local textures = R.board_art
        local piece = g.resource_yields and g.resource_yields[kind]
        if piece and piece.tool then return textures[piece.icon] end
        if pieces.kind_prefix and g.resource_yields then return textures[pieces.kind_prefix .. kind] end

        local level, base = rules.level_of(g), base_pieces[kind]
        if pieces.story_prefix and level.story_piece and kind == level.goal_kind then
            local prefix = R.campaign_art and pieces.campaign_prefix or pieces.story_prefix
            return textures[prefix .. level.story_piece]
        end
        if R.campaign_art and (piece or base) then
            return textures[pieces.campaign_prefix .. (piece or base).key]
        end
        local resource = pieces.resource_prefix
        if resource then
            if piece and (kind == level.goal_kind or piece.kind ~= nil or not neutral and default_pack) then
                return textures[resource .. piece.key]
            end
            if reference and base then return textures[resource .. base.key] end
        end
        return R.relics[kind + 1]
    end

    local piece_size = R.cell_width * (pieces.scale or .95)
    -- A colored special is its own piece under cream ribbons that run along
    -- the axis it clears, masked to the piece's painted alpha.
    local colored_specials = require("match3.specials").colored
    local stripes = pieces.stripes or {repeats=4, width=.5, ink=color(255, 250, 224)}
    local axis_angle = rules.square and math.pi / 2 or math.pi / 3
    -- Also the guide's picture of a line gem.
    function R.draw_banded(tex, area, axis, alpha)
        local angle = (rules.square and 0 or math.pi / 6) + axis * axis_angle
        gfx.image_striped(tex, area, angle, stripes.repeats, stripes.width, stripes.ink, color(255, 255, 255, alpha))
    end
    -- The painted specials carry a wider gutter than the pieces: this brings
    -- the rainbow gem up to their size on the board.
    local special_scale = {color_bomb = 1.14}
    -- A gem is lit on the board. A rim of light follows its silhouette: warm
    -- cream on a line gem, a slow turn through the spectrum on a rainbow gem.
    -- Over the pieces a glint crosses a line gem the way it will sweep, and
    -- one winks on the rainbow gem. Reduce Motion holds the rim and hides the glints.
    local LINE_GLOW = color(255, 240, 176)
    local GLINT_PERIOD, GLINT_TIME = 2.8, .75
    local function spectrum(turn)
        local function channel(shift) return 165 + 90 * math.sin((turn + shift) * 2 * math.pi) end
        return color(channel(0), channel(1 / 3), channel(2 / 3))
    end
    local function gem_phase(at) return at.x * .021 + at.y * .013 end
    local function gem_glow(tex, area, at, alpha, side, rainbow)
        local phase, still = gem_phase(at), R.reduced_motion
        local pulse = still and .5 or .5 + .5 * math.sin(R.now * 2.6 + phase)
        elements.piece_glow(tex, area, alpha, side, rainbow and spectrum(still and 0 or R.now * .16 + phase) or LINE_GLOW,
            .62 + .38 * pulse)
    end
    function R.draw_relic(tile, at, scale, alpha, aspect, guided)
        local banded = colored_specials[tile.special]
        if tile.special and not banded then
            local tex = R.match_special_texture(tile)
            local side = R.HEX_R * 2 * scale * (special_scale[tile.special] or 1)
            local area = rect.centered(at, size2(side * aspect, side / aspect))
            elements.piece_shadow(tex, area, alpha, side)
            if guided then elements.piece_glow(tex, area, alpha, side, LINE_GLOW, 1)
            elseif tile.special == "color_bomb" then gem_glow(tex, area, at, alpha, side, true) end
            return gfx.image(tex, area, color(255, 255, 255, alpha))
        end
        if tile.kind < 0 then return end
        local side = piece_size * scale
        local tex = R.board_piece_texture(tile.kind)
        tex = R.board_piece_crops and R.board_piece_crops[tex] or tex
        local area = rect.centered(at, size2(side * aspect, side / aspect))
        elements.piece_shadow(tex, area, alpha, side)
        if guided then elements.piece_glow(tex, area, alpha, side, LINE_GLOW, 1)
        elseif banded then gem_glow(tex, area, at, alpha, side) end
        if banded then R.draw_banded(tex, area, tile.axis, alpha)
        else gfx.image(tex, area, color(255, 255, 255, alpha)) end
    end
    function R.draw_gem_glint(tile, at, scale, alpha)
        local banded = colored_specials[tile.special]
        if R.reduced_motion or tile.special ~= "color_bomb" and not banded then return end
        local t = (R.now + gem_phase(at) * 3) % GLINT_PERIOD / GLINT_TIME
        if t >= 1 then return end
        local side = piece_size * scale
        local shine = color(255, 252, 232, alpha * math.sin(math.pi * t))
        if banded then
            local angle = (rules.square and 0 or math.pi / 6) + tile.axis * axis_angle
            local reach = (t * 2 - 1) * side * .42
            R.vfx_sprite("twinkle", vec2(at.x + math.cos(angle) * reach, at.y + math.sin(angle) * reach), side * .95, 0, shine)
        else
            R.vfx_sprite("twinkle", vec2(at.x - side * .17, at.y - side * .19), side * .8 * (.6 + .4 * math.sin(math.pi * t)), 0, shine)
        end
    end

    local image_alpha = background.opacity or 255
    local shade = background.shade and color(table.unpack(background.shade))
    function R.draw_board_background(opacity)
        local g = R.g
        local scene = R.scenes[g.backdrop or rules.level_of(g).background or (g.level >= 5 and 2 or 1)]
        local tex = scene and scene.tex and scene or R.backdrop
        local full = app.bleed()
        local box = R.backdrop_rect(texture.size(tex), full, background.min_height, background.align_y)
        -- Composite the same tinted background at partial opacity during the board exit.
        local shade_alpha = shade and opacity * shade.a / 255 or 0
        gfx.bleed(true)
        gfx.image(tex, box, color(255, 255, 255, opacity * image_alpha / (1 - shade_alpha)))
        if shade then gfx.rect(full, color.alpha(shade, opacity)) end
        gfx.bleed(false)
    end

    local motes = background.motes and color(table.unpack(background.motes))
    local function draw_motes()
        if not motes then return end
        for i = 0, 11 do
            local x = (i * 93 + R.now * (i % 2 == 1 and 3 or -4) + 480) % 440
            local y = (i * 139 + R.now * 5) % 620
            local wave = math.sin(R.now + i)
            gfx.circle(vec2(20 + x, 170 + y), 1.5 + .5 * wave,
                color(motes.r, motes.g, motes.b, motes.a + 50 * wave))
        end
    end

    local function draw_pieces(sx, highlights)
        local cover = elements.reveal_cover(R, rules)
        if cover <= 0 then return end
        gfx.clip(R.BOARD_CLIP)
        for i = 0, rules.CELLS - 1 do
            if rules.game_cell_active(R.g, i) then
                local tile, at, scale, alpha, aspect, clip = R.piece_pose(i, sx)
                if clip then gfx.clip(clip) end
                R.draw_relic(tile, at, scale * elements.selection_scale(R, i), alpha * cover, aspect,
                    highlights and highlights[i])
                if clip then gfx.clip(R.BOARD_CLIP) end
            end
        end
        -- Glints go over every piece, so one never slips under a neighbor.
        for i = 0, rules.CELLS - 1 do
            if rules.game_cell_active(R.g, i) and R.g.tiles[i].special then
                local tile, at, scale, alpha, _, clip = R.piece_pose(i, sx)
                if clip then gfx.clip(clip) end
                R.draw_gem_glint(tile, at, scale, alpha * cover)
                if clip then gfx.clip(R.BOARD_CLIP) end
            end
        end
        gfx.unclip()
    end

    local function draw_sheen(sx)
        for i = 0, rules.CELLS - 1 do
            local sheen = rules.game_cell_active(R.g, i) and R.intro:sheen(i) or 0
            if sheen > .02 then
                R.vfx_halo(R.cell_pos(i) + vec2(sx, 0), R.HEX_R * 1.9, color(255, 238, 186, 150 * sheen))
            end
        end
    end

    local function draw_board(inp, highlights)
        R.draw_board_background(1)
        draw_motes()
        R.draw_board_hud()
        local sx = not R.reduced_motion and R.shake > 0 and math.sin(R.now * 110) * R.shake * 15 or 0
        elements.ground(R, rules, sx, R.board_floor())
        draw_pieces(sx, highlights)
        elements.square_blockers(R, rules, sx)
        elements.blockers(R, rules, sx)
        if R.intro then draw_sheen(sx) end

        local review = app.arg("art-states")
        if not review or not board.review_replaces_tools then R.draw_board_tools(inp) end
        if review then
            local draw = review == "bonuses" and art.draw_bonus_catalogue
                or review == "dressing" and art.draw_dressing_catalogue or art.draw_catalogue
            draw(R)
        end
        if app.arg("hud-states") then art.draw_hud_catalogue(R) end
    end

    local screen = {}
    R.board_screen = screen
    local function draw(inp, dt, fade, banners, active)
        if R.intro and R.intro:showing_backdrop() then
            R.draw_board_background(1)
            draw_motes()
            R.board_input(inp)
            return
        end
        if fade < 1 then
            local tutorial = active and R.tutorial
            local talking = tutorial and tutorial:show_goal_reminder()
            local step = tutorial and not talking and tutorial:step()
            draw_board(inp, step and step.cells)
            R.vfx_draw()
            R.vfx_particles()
            if banners then R.draw_board_banners(dt) end
            local skipped = step and tutorial:frame(inp, dt, step)
            if not talking and not skipped then R.board_input(inp) end
        end
        if fade > 0 then R.draw_board_background(fade) end
    end

    function screen:frame(inp, dt, active, fade)
        draw(active and inp or input{pos = inp.pos, pinch = 1}, dt, fade or 0, true, active)
    end

    function screen:transition(inp, dt, fade)
        draw(inp, dt, fade, false)
    end
end

function V.load(R, art, config)
    R.board_art = art.load()
    if R.tutorial then
        R.tutorial.arrow = texture.load_engine("data/board/hints/tutorial-arrow.png")
        assert(R.tutorial.arrow.tex, "missing tutorial arrow")
    end
    local skin = match3.skin(require("match3_skin"))
    elements.load_square(R.board_art, skin)
    R.board_piece_crops = {}
    for name, inset in pairs((config.pieces or {}).crops or {}) do
        local tex = assert(R.board_art[name], "missing board piece: " .. name)
        R.board_piece_crops[tex] = texture.region(tex, texture.rect(tex):inflate(-inset))
    end
end

return V
