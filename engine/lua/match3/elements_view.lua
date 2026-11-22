-- Presentation of optional match-three elements. Games provide the atlas;
-- rules and board layouts stay independent of this drawing code.
local E = {}

local function image(R, name, at, size, alpha)
    gfx.image(R.board_art[name], rect.centered(at, size2.splat(size)), color(255, 255, 255, alpha * 255))
end

local REVEAL_FADE, REVEAL_HOLD = .6, 1.2
local function reveal(R, rules)
    local g = R.g
    if not g then return end
    if R.reveal_game ~= g then
        local spec = rules.level_of(g).reveal
        R.reveal_game, R.reveal_won, R.reveal_barked = g, nil, false
        R.reveal_spec = spec and (not R.prog or g.level >= R.prog.level) and spec or nil
    end
    local spec = R.reveal_spec
    if not spec then return end
    if g.won and not R.reveal_won then R.reveal_won = R.now end
    local half = spec.object and g.oil_left * 2 <= #rules.level_of(g).oil
    if spec.bark and not R.reveal_barked and not g.won and half then
        R.reveal_barked = true
        R.notice(spec.bark)
    end
    return spec
end
-- Piece and blocker opacity, 1 until the win and 0 once the picture is clear.
function E.reveal_cover(R, rules)
    if not reveal(R, rules) or not R.reveal_won then return 1 end
    return R.reduced_motion and 0 or 1 - ease.out_cubic(math.min(1, (R.now - R.reveal_won) / REVEAL_FADE))
end
function E.reveal_holding(R, rules)
    return reveal(R, rules) ~= nil and R.reveal_won ~= nil and R.now - R.reveal_won < REVEAL_FADE + REVEAL_HOLD
end
local function floor_pose(R, i)
    local scale, turn, lift = 1, 0, 0
    if R.intro then scale, turn, lift = R.intro:cell(i) end
    return scale, turn, lift
end

local function each_ground_cell(R, rules, sx, fn)
    for i = 0, rules.CELLS - 1 do
        if rules.game_cell_active(R.g, i) then
            local scale, turn, lift = floor_pose(R, i)
            if scale > .02 then fn(i, R.cell_pos(i) + vec2(sx, lift), scale, turn) end
        end
    end
end

local square_ice = {"ice-square-1", "ice-square-2"}
local square_chain = {"chain-square-1", "chain-square-2"}
local function blocker_art(R, states, hits)
    return R.board_art[states[math.min(hits, #states)]]
end

-- Art for the layer removed by a shatter effect.
function E.layer_art(R, floor, oil, ice)
    if ice > 0 then return blocker_art(R, square_ice, ice) end
    if oil > 1 then return R.board_art[floor.double] end
    if oil > 0 then return R.board_art[floor.covered] end
end

local function draw_floor_cell(R, i, at, material, alpha)
    local scale, turn, lift = floor_pose(R, i)
    if scale <= .02 then return end
    at = at + vec2(0, lift)
    local tint = color(255, 255, 255, 255 * alpha)
    local radius = (R.HEX_R - R.GROUND.seam_width) * scale
    gfx.image_rot(R.board_art[material], rect.centered(at, size2.splat(2 * radius)), turn, tint)
end

local square_vertices = {vec2(1, -1), vec2(1, 1), vec2(-1, 1), vec2(-1, -1)}
local function draw_tablet_hints(R, rules, sx, floor)
    local g = R.g
    if not (floor and floor.tablet_hint and g.oil_left > 0 and g.oil_left <= 3)
        or R.reduced_motion or R.overlay ~= R.OV_NONE then return end
    local time = R.tablet_hint_time(R.idle_hint_age())
    if not time then return end
    local radius = R.HEX_R - R.GROUND.seam_width - 1
    for i = 0, rules.CELLS - 1 do
        local layers = g.oil[i] or 0
        if layers > 0 and rules.game_cell_active(g, i) then
            R.vfx_tablet_hint(R.cell_pos(i) + vec2(sx, 0), radius, square_vertices, time, layers > 1)
        end
    end
end

local square_cells = {"square-plain", "square-target", "square-double", "square-selected", "square-grout"}

-- Neighbour bits are ordered clockwise from north, with one diagonal
-- between each pair of sides. Match the masks baked by square_board_frame.py.
local square_frame_neighbours = {{0,-1}, {1,-1}, {1,0}, {1,1}, {0,1}, {-1,1}, {-1,0}, {-1,-1}}

local function square_frame_art(skin)
    local frames = {}
    for mask = 1, 255 do
        local shape = mask
        for k = 0, 6, 2 do
            if shape & ((1 << k) | (1 << ((k + 2) % 8))) ~= 0 then
                shape = shape & ~(2 << k)   -- the side already covers this corner
            end
        end
        local best, turn = shape, 0
        for k = 1, 3 do
            shape = ((shape << 2) | (shape >> 6)) & 255
            if shape < best then best, turn = shape, 4 - k end
        end
        local key = "square-frame-" .. best
        frames[mask] = {stone=assert(skin[key], key), leaf=skin[key .. "-leaf"], turn=turn}
    end
    return frames
end

function E.load_square(art, skin)
    for _, key in ipairs(square_cells) do art[key] = assert(skin[key], key) end
    for _, states in ipairs{square_ice, square_chain} do
        for _, key in ipairs(states) do art[key] = assert(skin[key], key) end
    end
    art["stone-1"] = assert(skin["stone-1"], "missing stone blocker")
    art.square_frame = square_frame_art(skin)
end

local SHADOW_SAMPLES, SHADOW_RADIUS, SHADOW_MARGIN = 8, 3, 8

-- A rolling box filter. Transposing the output lets the same pass blur
-- along the other axis without jumping between rows to read the input.
local function blur_shadow_rows(samples, width, height)
    local blurred = {}
    for y = 1, height do
        local row, sum = (y - 1) * width, 0
        for x = 1, SHADOW_RADIUS do sum = sum + samples[row + x] end
        for x = 1, width do
            if x + SHADOW_RADIUS <= width then sum = sum + samples[row + x + SHADOW_RADIUS] end
            if x > SHADOW_RADIUS + 1 then sum = sum - samples[row + x - SHADOW_RADIUS - 1] end
            blurred[(x - 1) * height + y] = sum
        end
    end
    return blurred
end

local function square_shadow_mask(rules, game)
    local width = rules.COLUMNS * SHADOW_SAMPLES + 2 * SHADOW_MARGIN
    local height = rules.ROWS * SHADOW_SAMPLES + 2 * SHADOW_MARGIN
    local samples = {}
    for i = 1, width * height do samples[i] = 0 end
    local q0, row0 = rules.hex_q(0), rules.hex_r(0)
    for i = 0, rules.CELLS - 1 do
        if rules.game_cell_active(game, i) then
            local x = SHADOW_MARGIN + (rules.hex_q(i) - q0) * SHADOW_SAMPLES
            local y = SHADOW_MARGIN + (rules.hex_r(i) - row0) * SHADOW_SAMPLES
            -- Spread one sample under the outer frame. Rasterize the union
            -- first so touching cells never darken each other's shadow.
            for row = y, y + SHADOW_SAMPLES + 1 do
                for col = x, x + SHADOW_SAMPLES + 1 do
                    samples[(row - 1) * width + col] = 1
                end
            end
        end
    end
    for _ = 1, 2 do
        samples = blur_shadow_rows(blur_shadow_rows(samples, width, height), height, width)
    end
    local weight = (2 * SHADOW_RADIUS + 1) ^ 4
    for i, sample in ipairs(samples) do
        samples[i] = "\255\255\255" .. string.char(math.floor(sample * 255 / weight + .5))
    end
    return texture.from_pixels(table.concat(samples), width, height)
end

local function draw_square_shadow(R, rules, sx, frame_alpha)
    if frame_alpha <= 0 then return end
    local shadow = R.board_shadow
    if not shadow or shadow.game ~= R.g then
        if shadow then texture.free(shadow.texture) end
        shadow = {game=R.g, texture=square_shadow_mask(rules, R.g)}
        R.board_shadow = shadow
    end
    local unit = 2 * R.HEX_R / SHADOW_SAMPLES
    local corner = R.cell_pos(0) - vec2(R.HEX_R, R.HEX_R)
    local inset = SHADOW_MARGIN * unit
    local box = rect(corner.x - inset + sx, corner.y - inset + 1.5 * unit,
                     shadow.texture.w * unit, shadow.texture.h * unit)
    gfx.image(shadow.texture, box, color(9, 15, 12, 190 * frame_alpha))
end

local function draw_square_frame(R, rules, sx, tint)
    if tint.a <= 0 then return end
    local step, frames = 2 * R.HEX_R, R.board_art.square_frame
    local size = size2.splat(step)
    local origin = R.board_origin + vec2(sx, 0)
    local function occupied(q, row)
        return rules.game_cell_active(R.g, rules.hex_index(q, row))
    end
    local q0, row0 = rules.hex_q(0), rules.hex_r(0)
    local leafy = {[0]=false, true, false, true}
    -- Include the empty ring just outside the configured grid. Each
    -- occupied floor cell keeps its entire rectangle clear of frame art.
    for q = q0 - 1, q0 + rules.COLUMNS do
        for row = row0 - 1, row0 + rules.ROWS do
            if not occupied(q, row) then
                local mask = 0
                for i, offset in ipairs(square_frame_neighbours) do
                    if occupied(q + offset[1], row + offset[2]) then mask = mask | (1 << (i - 1)) end
                end
                local tile = frames[mask]
                if tile then
                    local sprite, turn = tile.stone, tile.turn
                    -- The planted NE corner also needs a diagonal floor cell.
                    if tile.leaf and mask & (2 << (2 * turn)) ~= 0 then
                        if leafy[turn] then sprite = tile.leaf end
                        leafy[turn] = not leafy[turn]
                    end
                    local box = rect.centered(origin + vec2(step * q, step * row), size)
                    gfx.image_rot(sprite, box, turn * math.pi / 2, tint)
                end
            end
        end
    end
end

local function draw_square_ground(R, rules, sx, floor, alpha, frame_alpha)
    local active, game = rules.game_cell_active, R.g
    local r, art = R.HEX_R, R.board_art
    local tint = color(255, 255, 255, 255 * frame_alpha)
    each_ground_cell(R, rules, sx, function(_, at, scale, turn)
        local box = rect.centered(at, size2.splat(2 * r * scale))
        gfx.image_rot(art["square-grout"], box, turn, tint)
    end)
    each_ground_cell(R, rules, sx, function(i, at, scale, turn)
        local box = rect.centered(at, size2.splat(2 * (r - R.GROUND.seam_width) * scale))
        local layers = game.oil[i]
        local key = layers > 1 and floor.double or layers > 0 and floor.covered or floor.normal
        gfx.image_rot(art[key], box, turn, color(255, 255, 255, 255 * alpha))
    end)
    draw_square_frame(R, rules, sx, tint)
    local function outline(i, opacity)
        draw_floor_cell(R, i, R.cell_pos(i) + vec2(sx, 0), "square-selected", alpha * opacity)
    end
    local aim = R.aim_cell or -1
    if aim >= 0 then
        for i in pairs(rules.game_tool_area(game, R.tool, aim) or {}) do outline(i, .82) end
    end
    local selected = R.selected or -1
    if active(game, selected) then outline(selected, 1) end
end

-- Paint the full board surface before pieces and blockers.
function E.ground(R, rules, sx, floor)
    local intro = R.intro
    local alpha = intro and intro:fade() or 1
    local frame_alpha = intro and intro:frame_fade() or 1
    draw_square_shadow(R, rules, sx, frame_alpha)
    draw_square_ground(R, rules, sx, floor, alpha, frame_alpha)
    draw_tablet_hints(R, rules, sx, floor)
end

-- Ice and chains sit above the piece and stay centred on the square cell.
function E.square_blockers(R, rules, sx)
    local g, intro = R.g, R.intro
    local cover = E.reveal_cover(R, rules)
    if cover <= 0 then return end
    local side = 2 * (R.HEX_R - R.GROUND.seam_width)
    for i = 0, rules.CELLS - 1 do
        local ice, chain = g.ice[i], g.chain[i]
        if (ice > 0 or chain > 0) and rules.game_cell_active(g, i) then
            local visible, scale, alpha = true, 1, 1
            if intro then visible, scale, alpha = intro:blocker(i); alpha = alpha * intro:fade() end
            if visible then
                local dst = rect.centered(R.cell_pos(i) + vec2(sx, 0), size2.splat(side * scale))
                local tint = color(255, 255, 255, 255 * alpha * cover)
                if ice > 0 then gfx.image(blocker_art(R, square_ice, ice), dst, tint) end
                if chain > 0 then gfx.image(blocker_art(R, square_chain, chain), dst, tint) end
            end
        end
    end
end

-- Fixed blockers cover the piece area.
function E.blockers(R, rules, sx)
    local g = R.g
    local cover = E.reveal_cover(R, rules)
    if cover <= 0 then return end
    for i = 0, rules.CELLS - 1 do
        if rules.game_cell_active(g, i) then
            local name
            local hp = g.stone_hp and g.stone_hp[i] or 0
            if hp > 0 then name = "stone-1" end
            if name then
                local visible, scale, alpha = true, 1, 1
                if R.intro then visible, scale, alpha = R.intro:blocker(i); alpha = alpha * R.intro:fade() end
                if visible then
                    image(R, name, R.cell_pos(i) + vec2(sx, 0), 2 * (R.HEX_R - .65) * scale, alpha * cover)
                end
            end
        end
    end
end

-- Selection/hints animate the original piece; no legacy frame is drawn.
function E.selection_scale(R,i)
    if i==R.selected then return 1.08 end
    if R.phase==R.PH_IDLE and (i==R.hint_a or i==R.hint_b) then
        return R.reduced_motion and 1.06 or 1+.06*math.sin(R.now*5)^2
    end
    return 1
end

-- A soft drop shadow under a board piece, so it stays legible on bright floor
-- art: the piece's silhouette inked dark blue (a single full-width stripe),
-- dropped and spread over a ring of faint taps. size is the piece's drawn
-- width in logical pixels. Square-board pieces nearly fill their cells, so the
-- shadow drops 7% of the piece to clear its rim and read on the floor.
local SHADOW_TAPS = 12
local SHADOW_DROP, SHADOW_SPREAD, SHADOW_TAP_ALPHA = .07, .06, 14
local SHADOW_INK = color(22, 38, 92, 255)
function E.piece_shadow(tex, dst, alpha, size)
    local drop, spread = size * SHADOW_DROP, size * SHADOW_SPREAD
    local tint = color(255, 255, 255, SHADOW_TAP_ALPHA * alpha / 255)
    local base = dst:offset(vec2(0, drop))
    gfx.image_striped(tex, base, 0, 1, 1, SHADOW_INK, tint)
    for k = 1, SHADOW_TAPS do
        local a = k / SHADOW_TAPS * 2 * math.pi
        gfx.image_striped(tex, base:offset(vec2(math.cos(a) * spread, math.sin(a) * spread)), 0, 1, 1, SHADOW_INK, tint)
    end
end

-- A rim of light around a gem: the piece's silhouette inked in `ink` and
-- spread over a ring of taps, drawn before the piece so only the rim shows.
-- strength is 0..1; size is the piece's drawn width in logical pixels.
local GLOW_TAPS, GLOW_SPREAD, GLOW_TAP_ALPHA = 12, .085, 74
function E.piece_glow(tex, dst, alpha, size, ink, strength)
    local spread = size * GLOW_SPREAD
    local tint = color(255, 255, 255, GLOW_TAP_ALPHA * strength * alpha / 255)
    for k = 1, GLOW_TAPS do
        local a = k / GLOW_TAPS * 2 * math.pi
        gfx.image_striped(tex, dst:offset(vec2(math.cos(a) * spread, math.sin(a) * spread)), 0, 1, 1, ink, tint)
    end
end

return E
