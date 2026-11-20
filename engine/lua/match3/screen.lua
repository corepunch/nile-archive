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
    function R.draw_relic(tile, at, scale, alpha, aspect)
        if tile.special then return R.draw_match_special(tile, at, scale, alpha) end
        if tile.kind < 0 then return end
        local side = piece_size * scale
        local tex = R.board_piece_texture(tile.kind)
        tex = R.board_piece_crops and R.board_piece_crops[tex] or tex
        local area = rect.centered(at, size2(side * aspect, side / aspect))
        elements.piece_shadow(tex, area, alpha, side)
        gfx.image(tex, area, color(255, 255, 255, alpha))
    end

    local image_alpha = background.opacity or 255
    local shade = background.shade and color(table.unpack(background.shade))
    function R.draw_board_background(opacity)
        local g = R.g
        local scene = R.scenes[g.backdrop or rules.level_of(g).background or (g.level >= 5 and 2 or 1)]
        local tex = scene and scene.tex and scene or R.backdrop
        local full = app.bleed()
        local box = R.backdrop_rect(texture.size(tex), full, background.min_height)
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

    local function draw_pieces(sx)
        local cover = elements.reveal_cover(R, rules)
        if cover <= 0 then return end
        gfx.clip(R.BOARD_CLIP)
        for i = 0, rules.CELLS - 1 do
            if rules.game_cell_active(R.g, i) then
                local tile, at, scale, alpha, aspect, clip = R.piece_pose(i, sx)
                if clip then gfx.clip(clip) end
                R.draw_relic(tile, at, scale * elements.selection_scale(R, i), alpha * cover, aspect)
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

    local function draw_board(inp)
        R.draw_board_background(1)
        draw_motes()
        R.draw_board_hud()
        local sx = not R.reduced_motion and R.shake > 0 and math.sin(R.now * 110) * R.shake * 15 or 0
        elements.ground(R, rules, sx, R.board_floor())
        draw_pieces(sx)
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
        R.board_input(inp)
    end

    local screen = {}
    R.board_screen = screen
    local function draw(inp, dt, fade, banners)
        if fade < 1 then
            draw_board(inp)
            R.vfx_draw()
            R.vfx_particles()
            if banners then R.draw_board_banners(dt) end
        end
        if fade > 0 then R.draw_board_background(fade) end
    end

    function screen:frame(inp, dt, active, fade)
        draw(active and inp or input{pos = inp.pos, pinch = 1}, dt, fade or 0, true)
    end

    function screen:transition(inp, dt, fade)
        draw(inp, dt, fade, false)
    end
end

function V.load(R, art, config)
    R.board_art = art.load()
    local skin = match3.skin(require("match3_skin"))
    elements.load(R.board_art, skin)
    elements.load_frame(R.board_art, art.board_frame)
    elements.load_square(R.board_art, skin)
    R.board_piece_crops = {}
    for name, inset in pairs((config.pieces or {}).crops or {}) do
        local tex = assert(R.board_art[name], "missing board piece: " .. name)
        R.board_piece_crops[tex] = texture.region(tex, texture.rect(tex):inflate(-inset))
    end
end

return V
