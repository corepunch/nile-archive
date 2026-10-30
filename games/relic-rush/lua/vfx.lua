-- vfx.lua — presentation-only effects with their own random stream and fixed
-- pools: impacts, travelling sun rays, blast shockwaves, prism links, special
-- births, score pop-ups, sparks, relics flying to the HUD and torch flames.
-- Gameplay never reads anything from here.
local R = require("state")
local rules = require("rules")
local CELLS, RELIC_IDOL, RELIC_LEAF, RELIC_CRYSTAL = rules.CELLS, rules.RELIC_IDOL, rules.RELIC_LEAF, rules.RELIC_CRYSTAL
local ROW, COLUMN, DIAGONAL, BOMB, PRISM = rules.ROW, rules.COLUMN, rules.DIAGONAL, rules.BOMB, rules.PRISM
local hex_neighbor = rules.hex_neighbor
local rgba = color
local PI = math.pi

local FX_CAP, PARTICLES = 256, 650
local FX_NONE, FX_IMPACT, FX_RAY, FX_BLAST, FX_LINK, FX_BIRTH, FX_SCORE = 0, 1, 2, 3, 4, 5, 6

local pool, parts = {}, {}
for i = 1, FX_CAP do pool[i] = {type = FX_NONE, kind = 0, value = 0, at = vec2(), to = vec2(), age = 0, life = 0, delay = 0} end
for i = 1, PARTICLES do parts[i] = {at = vec2(), vel = vec2(), to = vec2(), age = 0, life = 0, kind = 0, flying = false} end
local pool_next, part_next = 0, 0

-- the effects' own xorshift stream, as in the engine's rng
local fx_rng = 0x4a17b83
local function rng_float()
    local x = fx_rng
    x = x ~ ((x << 13) & 0xFFFFFFFF)
    x = x ~ (x >> 17)
    x = x ~ ((x << 5) & 0xFFFFFFFF)
    fx_rng = x
    return (x >> 8) * (1.0 / 16777216.0)
end

local palette = {[0] = rgba(255, 201, 73), rgba(255, 107, 48), rgba(113, 232, 115), rgba(71, 222, 255),
                 rgba(196, 116, 255), rgba(255, 173, 70), rgba(188, 244, 255), rgba(249, 223, 161)}
function R.vfx_color(kind, alpha)
    local c = palette[num.clampi(kind, 0, 7)]
    return rgba(c.r, c.g, c.b, num.clamp(alpha, 0, 255))
end
local vfx_color = R.vfx_color

-- A soft radial glow texture (cubic falloff), drawn additively.
function R.vfx_init()
    local px = {}
    for y = 0, 63 do
        for x = 0, 63 do
            local t = math.max(0, 1 - vec2(x - 31.5, y - 31.5):len() / 32)
            px[#px + 1] = string.char(255, 255, 255, math.floor(255 * t * t * t))
        end
    end
    R.glow = texture.from_pixels(table.concat(px), 64, 64)
    texture.additive(R.glow, true)
end

function R.vfx_reset()
    for i = 1, FX_CAP do pool[i].type, pool[i].life = FX_NONE, 0 end
    for i = 1, PARTICLES do parts[i].life = 0 end
    pool_next, part_next = 0, 0
    R.fx_combo = 0
    R.fx_origin = -1
    R.score_display = R.g.score
    R.goal_display, R.word_time, R.score_pulse, R.goal_pulse = 0, 0, 0, 0
end

local function add(kind_of, at, to, kind, life, delay, value)
    if R.reduced_motion then return end
    local e = pool[pool_next % FX_CAP + 1]
    pool_next = pool_next + 1
    e.type, e.kind, e.value, e.at, e.to, e.age, e.life, e.delay = kind_of, kind, value, at, to, 0, life, delay
end

function R.vfx_halo(at, radius, c) gfx.image(R.glow, rect.centered(at, size2.splat(radius * 2)), c) end
local vfx_halo = R.vfx_halo
local function ring(at, radius, width, c)
    if radius >= 1 then gfx.ring(at, radius - width * .5, width, c) end
end
local function spark(at, radius, angle, c) gfx.star(at, radius, .24, 4, angle, c) end

------------------------------------------------------------------ particles

local function goal_count() return 2 + (rules.level_of(R.g).soil > 0 and 1 or 0) + (R.g.initial_obstacles > 0 and 1 or 0) end

function R.vfx_emit(at, kind, flying)
    if R.reduced_motion then return end
    for _ = 1, flying and 1 or 7 do
        local p = parts[part_next % PARTICLES + 1]
        part_next = part_next + 1
        local a, speed = rng_float() * 2 * PI, 55 + rng_float() * 125
        local to = kind == RELIC_IDOL and vec2(24 + 432 / goal_count() + 19, 248) or vec2(90, 153)   -- idol goal or score
        p.at, p.vel, p.to = at, vec2.polar(a, speed) + vec2(0, -35), to
        p.age = flying and -rng_float() * .14 or 0
        p.life = flying and .75 + rng_float() * .2 or .35 + rng_float() * .32
        p.kind, p.flying = kind, flying
    end
end
local vfx_emit = R.vfx_emit

local function flight(p, t)
    local f = t < .5 and 2 * t * t or 1 - (-2 * t + 2) ^ 2 / 2
    local arc = math.sin(f * PI)
    return p.at:lerp(p.to, f) + vec2(arc * (p.at.x < 240 and -34 or 34), -arc * 64)
end

local function land(p)
    add(FX_IMPACT, p.to, vec2(0, 0), p.kind, .25, 0, 0)
    if p.kind == RELIC_IDOL then R.goal_pulse = .22 else R.score_pulse = .22 end
end

function R.vfx_particles()
    if R.reduced_motion then return end
    for i = 1, PARTICLES do
        local p = parts[i]
        if p.life > 0 and p.age >= 0 then
            local t = p.age / p.life
            local fade = 1 - t
            if p.flying then
                local at = flight(p, t)
                for k = 4, 1, -1 do vfx_halo(flight(p, math.max(0, t - k * .025)), 9 - k, vfx_color(p.kind, 70 * (1 - k / 5))) end
                vfx_halo(at, 19, vfx_color(p.kind, 125))
                local size = 18 + 7 * math.sin(t * PI)
                gfx.image(R.relics[p.kind + 1], rect.centered(at, size2.splat(size)), color.WHITE)
            else
                local c = vfx_color(p.kind, 255 * fade)
                vfx_halo(p.at, 8 * fade + 2, vfx_color(p.kind, 130 * fade))
                if (i - 1) % 3 == 0 then
                    spark(p.at, 5 * fade + 1, t * 4, c)
                else
                    gfx.line(p.at, p.at - p.vel:scale(.025), 2.5 * fade, c)
                    gfx.circle(p.at, 1.4 + 1.6 * fade, rgba(255, 252, 216, 230 * fade))
                end
            end
        end
    end
end

---------------------------------------------------------------------- waves

local function axis_rays(cell, axis, kind)
    for sign = 0, 1 do
        local d = axis + sign * 3
        local e = cell
        local n = hex_neighbor(cell, d)
        while n >= 0 do e = n; n = hex_neighbor(n, d) end
        add(FX_RAY, R.cell_pos(cell), R.cell_pos(e), kind, .6, .025, 0)
    end
end

local function prism_links(cell)
    local links = 0
    for i = 0, CELLS - 1 do
        if links >= 18 then break end
        if R.pending.mask[i] and i ~= cell then
            add(FX_LINK, R.cell_pos(cell), R.cell_pos(i), R.old_tiles[i].kind, .48, (links % 6) * .018, 0)
            links = links + 1
        end
    end
    add(FX_BLAST, R.cell_pos(cell), vec2(0, 0), 4, .6, 0, 90)
end

-- Effects for one clearing wave, read from R.pending and the board before it.
function R.vfx_wave(old_score)
    local sum, hits = vec2(0, 0), 0
    for i = 0, CELLS - 1 do
        if R.pending.mask[i] and rules.game_cell_active(R.g, i) then
            local at = R.cell_pos(i)
            local was = R.old_tiles[i]
            sum = sum + at
            hits = hits + 1
            local kind = R.wave_ice[i] > 0 and 6 or R.wave_chain[i] > 0 and 7 or was.kind
            add(FX_IMPACT, at, vec2(0, 0), kind, .3, 0, 0)
            vfx_emit(at, kind, false)
            if R.wave_ice[i] == 0 and R.wave_chain[i] == 0 then
                if was.kind == RELIC_IDOL or was.kind == RELIC_LEAF or was.kind == RELIC_CRYSTAL then vfx_emit(at, was.kind, true) end
                if not R.pending.make[i] then
                    if was.special == ROW or was.special == COLUMN or was.special == DIAGONAL then
                        axis_rays(i, was.special == ROW and 0 or was.special == COLUMN and 1 or 2, was.kind)
                    elseif was.special == BOMB then add(FX_BLAST, at, vec2(0, 0), 0, .58, 0, 95)
                    elseif was.special == PRISM then prism_links(i) end
                end
            end
            if R.pending.make[i] then add(FX_BIRTH, at, vec2(0, 0), was.kind, .65, .2, 0) end
        end
    end
    if R.fx_origin >= 0 then   -- the cell a combo swap fired from
        if R.fx_combo == 3 then prism_links(R.fx_origin)
        elseif R.fx_combo == 2 then add(FX_BLAST, R.cell_pos(R.fx_origin), vec2(0, 0), 0, .65, 0, 150)
        elseif R.fx_combo == 1 then for a = 0, 2 do axis_rays(R.fx_origin, a, 0) end end
    end
    R.fx_origin = -1
    R.fx_combo = 0
    if hits > 0 then
        add(FX_SCORE, sum:scale(1 / hits) - vec2(0, 22), vec2(0, 0), 0, .65, .08, R.g.score - old_score)
        R.score_pulse = .25
    end
    if R.g.combo > 1 then R.word_time, R.word_combo = .75, R.g.combo end
end

function R.vfx_update(dt)
    for i = 1, FX_CAP do
        local e = pool[i]
        if e.life > 0 then
            e.age = e.age + dt
            if e.age >= e.life + e.delay then e.life = 0 end
        end
    end
    for i = 1, PARTICLES do
        local p = parts[i]
        if p.life > 0 then
            p.age = p.age + dt
            if p.age >= p.life then
                if p.flying then land(p) end
                p.life = 0
            elseif p.age >= 0 and not p.flying then
                p.at = p.at + p.vel:scale(dt)
                p.vel.y = p.vel.y + 210 * dt
            end
        end
    end
    R.score_display = num.approach(R.score_display, R.g.score, 15, dt)
    if math.abs(R.g.score - R.score_display) < 1 then R.score_display = R.g.score end
    R.goal_display = num.approach(R.goal_display, num.saturate(R.g.score / rules.level_of(R.g).score), 12, dt)
    R.score_pulse = math.max(0, R.score_pulse - dt)
    R.goal_pulse = math.max(0, R.goal_pulse - dt)
    R.word_time = math.max(0, R.word_time - dt)
end

function R.vfx_draw()
    if R.on_island or R.reduced_motion then return end
    for i = 1, FX_CAP do
        local e = pool[i]
        if e.life > 0 and e.age >= e.delay and e.type ~= FX_SCORE then
            local t = (e.age - e.delay) / e.life
            local fade = 1 - t
            local c = vfx_color(e.kind, 220 * fade)
            local cream = rgba(255, 249, 207, 220 * fade)
            gfx.additive(true)
            if e.type == FX_IMPACT then
                vfx_halo(e.at, 20 + 35 * t, vfx_color(e.kind, 150 * fade))
                ring(e.at, 7 + 28 * t, 2.5 * fade, c)
                if t < .65 then spark(e.at, 16 * fade, PI / 4, cream) end
            elseif e.type == FX_BLAST then
                local r = e.value * ease.out_cubic(t)
                vfx_halo(e.at, 48 + 60 * t, vfx_color(e.kind, 190 * fade * fade))
                ring(e.at, r + 7, 18 * fade, vfx_color(e.kind, 45 * fade))
                ring(e.at, r, 4 + 7 * fade, c)
                ring(e.at, r * .85, 2.5, rgba(255, 245, 202, 220 * fade))
                if t < .5 then spark(e.at, 40 * fade, PI / 4, rgba(255, 242, 183, 220 * fade)) end
                for k = 0, 7 do spark(e.at + vec2.polar(k * PI / 4, r * .8), 7 * fade, k * PI / 4, c) end
            elseif e.type == FX_RAY then
                local tip = e.at:lerp(e.to, ease.out_cubic(math.min(1, t * 1.8)))
                gfx.line(e.at, tip, 36 * fade, vfx_color(e.kind, 80 * fade))
                gfx.line(e.at, tip, 2 + 13 * fade, c)
                gfx.line(e.at, tip, 1.5 + 3 * fade, rgba(255, 255, 227, 255 * fade))
                vfx_halo(tip, 29, vfx_color(e.kind, 255 * fade))
                spark(tip, 13 * fade, PI / 4, rgba(255, 251, 220, 255 * fade))
            elseif e.type == FX_LINK then
                local prev = e.at
                local f = ease.out_cubic(math.min(1, t * 3))
                for k = 1, 8 do
                    local u = k / 8 * f
                    local bend = math.sin(u * PI) * math.sin(k * 2.7 + (i - 1)) * 7
                    local nxt = e.at:lerp(e.to, u) + vec2(bend, -bend)
                    gfx.line(prev, nxt, 8 * fade, vfx_color(e.kind, 65 * fade))
                    gfx.line(prev, nxt, 2, rgba(255, 250, 220, 220 * fade))
                    prev = nxt
                end
                vfx_halo(e.to, 24, vfx_color(e.kind, 150 * fade))
            elseif e.type == FX_BIRTH then
                vfx_halo(e.at, 48 * fade + 20, c)
                ring(e.at, R.HEX_R * (1 + .4 * t), 3 * fade, c)
                for k = 0, 3 do
                    local a = t * 3 + k * PI / 2
                    spark(e.at + vec2.polar(a, 24), 8 * fade, a, rgba(255, 250, 219, 220 * fade))
                end
            end
            gfx.additive(false)
        end
    end
    local P = R.P
    for i = 1, FX_CAP do
        local e = pool[i]
        if e.type == FX_SCORE and e.life > 0 and e.age >= e.delay then
            local t = (e.age - e.delay) / e.life
            local keep = R.copy_paint()
            P.alpha = 1 - t
            R.say_at(("+%d"):format(e.value), e.at - vec2(0, ease.out_cubic(t) * 30), 21 + 5 * math.sin(t * PI), R.PAL_GOLD, 0)
            R.set_paint(keep)
        end
    end
    if R.word_time > 0 then
        local t = 1 - R.word_time / .75
        local word = R.word_combo >= 5 and "SUNSTORM!" or R.word_combo >= 3 and "MAGNIFICENT!" or "BRILLIANT!"
        R.say_at(word, vec2(240, 732 - math.sin(t * PI) * 8), 28 + 8 * math.sin(math.min(1, t * 4) * PI), R.PAL_GOLD, 420)
    end
end

-- A quiet torch: buoyant flame parcels, a warm core and translucent wisps.
function R.vfx_torch(at, t)
    vfx_halo(at + vec2(0, -20), 53, rgba(255, 122, 26, 90))
    gfx.round_rect(rect(at.x - 12, at.y - 42, 24, 49), 11, rgba(78, 87, 57))
    texture.additive(R.glow, false)
    local clock = R.reduced_motion and 1.2 or t
    for k = 0, 33 do
        local seed = math.sin(k * 127.1 + 311.7) * .5 + .5
        local life = .65 + .5 * seed
        local a = math.fmod(clock + seed * life * 5, life) / life
        local fade = (1 - a) ^ 1.2
        local p = vec2(at.x + math.sin(a * 6 + k * .8) * (2 + a * 4) + math.sin(clock * 3 + seed * 4) * 1.3, at.y - 4 - 40 * a - 8 * a * a)
        local r = (5 + seed * 4) * fade
        gfx.image(R.glow, rect(p.x - r, p.y - r * 2, r * 2, r * 4), rgba(255, 72 + seed * 64, 8, 105 * fade))
        gfx.image(R.glow, rect(p.x - r * .55, p.y - r * 1.3, r * 1.1, r * 2.6), rgba(255, 179 + seed * 55, 62, 150 * fade))
    end
    texture.additive(R.glow, true)
    vfx_halo(at + vec2(0, -4), 18, rgba(255, 234, 150, 160))
    gfx.round_rect(rect(at.x - 3, at.y + 8, 6, 22), 2, rgba(93, 60, 33))
    gfx.round_rect(rect(at.x - 11, at.y + 5, 22, 7), 3, rgba(147, 98, 45))
    gfx.round_rect(rect(at.x - 9, at.y + 1, 18, 6), 2, rgba(211, 160, 78))
    gfx.rect(rect(at.x - 7, at.y + 2, 14, 2), rgba(255, 219, 131))
end

return R
