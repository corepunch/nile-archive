-- match3/vfx.lua — presentation-only match-3 effects with their own random
-- stream and fixed pools: impacts, score pop-ups, sparks and pieces flying
-- to the HUD
-- (`require("match3.vfx").bind(R, rules)`, called by match3.game).
-- Gameplay never reads anything from here. Glow and particles use board atlas regions.
local V = {}

function V.bind(R, rules)
    local CELLS, RELIC_LEAF, RELIC_CRYSTAL = rules.CELLS, rules.RELIC_LEAF, rules.RELIC_CRYSTAL
    local rgba = color
    local PI = math.pi

    local FX_CAP, PARTICLES = 256, 650
    local FX_NONE, FX_IMPACT, FX_SCORE = 0, 1, 2

    local pool, parts, bonus_in_flight = {}, {}, {}
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
        local c = ((kind == 6 or kind == 7) and R.blocker_color and R.blocker_color(kind))
            or palette[num.clampi(kind, 0, 7)]
        return rgba(c.r, c.g, c.b, num.clamp(alpha, 0, 255))
    end
    local vfx_color = R.vfx_color

    -- Additive blending belongs to the texture region, so the board's other
    -- frames keep their usual alpha blending.
    local fx_art = {}
    function R.vfx_init(board_skin)
        R.glow = board_skin.glow
        R.glow.additive = true
        for _, name in ipairs{"shock", "flash", "burst", "ring", "glint", "twinkle", "streak", "tablet-glow", "tablet-spark"} do
            local image = assert(board_skin["fx-" .. name], "missing match3 effect: " .. name)
            image.additive = true
            fx_art[name] = image
        end
        -- Smoke puffs keep alpha blending: their grey fringe is the billow's shading.
        R.vfx_smoke = {}
        for k = 0, 3 do R.vfx_smoke[k + 1] = assert(board_skin["fx-smoke-" .. k], "missing match3 effect: smoke") end
    end

    function R.vfx_reset()
        for i = 1, FX_CAP do pool[i].type, pool[i].life = FX_NONE, 0 end
        for i = 1, PARTICLES do parts[i].life = 0 end
        pool_next, part_next = 0, 0
        bonus_in_flight = {}
        R.score_display = R.g.score
        R.goal_display, R.score_pulse, R.goal_pulse = 0, 0, 0
    end

    local function add(kind_of, at, to, kind, life, delay, value)
        if R.reduced_motion then return end
        local e = pool[pool_next % FX_CAP + 1]
        pool_next = pool_next + 1
        e.type, e.kind, e.value, e.at, e.to, e.age, e.life, e.delay = kind_of, kind, value, at, to, 0, life, delay
    end

    function R.vfx_halo(at, radius, c) gfx.image(R.glow, rect.centered(at, size2.splat(radius * 2)), c) end
    local vfx_halo = R.vfx_halo
    local function sprite(name, at, side, angle, c)
        gfx.image_rot(fx_art[name], rect.centered(at, size2.splat(side)), angle, c)
    end
    -- The sprites' rings sit at .57 (ring) and .70 (shock) of their half-size.
    local function ring_sprite(name, at, radius, c) sprite(name, at, radius * (name == "ring" and 3.5 or 2.86), 0, c) end
    local function spark(at, radius, angle, c) sprite("glint", at, radius * 2.6, angle, c) end

    local blue_hint = {face = rgba(12, 76, 235), shadow = rgba(14, 44, 199), glow = rgba(28, 105, 255), spark = rgba(53, 222, 255)}
    local green_hint = {face = rgba(18, 164, 47), shadow = rgba(12, 104, 39), glow = rgba(54, 203, 52), spark = rgba(161, 255, 105)}
    local HINT_PERIOD, HINT_DURATION, HINT_LAP = 9, 3.6, 2.65
    local TRAIL_PARTICLES = 36
    function R.tablet_hint_time(age)
        local time = age and age % HINT_PERIOD
        if time and time < HINT_DURATION then return time end
    end

    local function rim_particle(at, radius, time, n, behind, ink, bright)
        local wake = math.max(0, 1 - behind * 2.4)
        local head = math.max(0, 1 - behind * 7)
        sprite("tablet-glow", at, radius * (1.08 + .20 * wake), 0,
            color.alpha(ink.glow, bright * (.22 + .39 * wake)))
        if head > 0 then
            sprite("tablet-glow", at, radius * .74, 0, color.alpha(ink.spark, bright * head * .75))
        end
        if n % 3 == 0 and wake > 0 then
            local flicker = .75 + .25 * math.sin(time * 18 + n * 2.3)
            sprite("tablet-spark", at, radius * .38, time + n,
                color.alpha(ink.spark, bright * wake * flicker * .45))
        end
    end

    function R.vfx_ready_rim(center, radius, time)
        -- Only the bright head and fading wake trace the brass rim. The face
        -- stays clear under the spinning particles.
        local angle = 2 * PI * (time / HINT_LAP - .25)
        for n = 14, 0, -1 do
            local behind = n / TRAIL_PARTICLES
            local at = center + vec2.polar(angle - 2 * PI * behind, radius)
            rim_particle(at, radius, time, n, behind, blue_hint, 1 - behind * 2.4)
        end
    end

    function R.vfx_tablet_hint(center, radius, vertices, time, double)
        local bright = num.saturate(time / .42) * num.saturate((HINT_DURATION - time) / .55)
        local phase = 5.5 + 6 * time / HINT_LAP
        local ink = double and green_hint or blue_hint
        gfx.ngon_grad(center, radius + 1, 6, 0, color.alpha(ink.face, .54 * bright), color.alpha(ink.shadow, .52 * bright))

        -- The soft blue trail lingers across the bevel. The brighter leading
        -- particles follow it clockwise, with a hot spot one edge long.
        for n = TRAIL_PARTICLES - 1, 0, -1 do
            local behind = n / TRAIL_PARTICLES
            local distance = phase - 6 * behind
            local edge = math.floor(distance)
            local at = center + vertices[edge % 6]:lerp(vertices[(edge + 1) % 6], distance - edge):scale(radius)
            rim_particle(at, radius, time, n, behind, ink, bright)
        end
    end

    ------------------------------------------------------------------ particles


    -- Rules bank charge immediately. The meter and stored-use badge update on arrival.
    function R.bonus_display_charge(tool)
        local g = R.g
        local points = g.tool_meter[tool]
        if not g.single_charge_tools then points = points + g.tools[tool] * g.tool_threshold end
        return math.max(0, points - (not R.reduced_motion and bonus_in_flight[tool] or 0))
    end

    function R.vfx_emit(at, kind, flying, count, target, tool, charge)
        if R.reduced_motion then return end
        for _ = 1, flying and 1 or count or 7 do
            local p = parts[part_next % PARTICLES + 1]
            part_next = part_next + 1
            local a, speed = rng_float() * 2 * PI, 55 + rng_float() * 125
            local to = target or at
            p.at, p.vel, p.to = at, vec2.polar(a, speed) + vec2(0, -35), to
            p.age = flying and -rng_float() * .14 or 0
            p.life = flying and .75 + rng_float() * .2 or .35 + rng_float() * .32
            p.kind, p.flying, p.tool, p.charge = kind, flying, tool, charge
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
        if p.tool then return end
        if rules.is_goal_kind(R.g, p.kind) then R.goal_pulse = .22 else R.score_pulse = .22 end
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
                    local piece = R.board_piece_texture and R.board_piece_texture(p.kind) or R.relics[p.kind + 1]
                    gfx.image(piece, rect.centered(at, size2.splat(size)), color.WHITE)
                else
                    local c = vfx_color(p.kind, 255 * fade)
                    vfx_halo(p.at, 8 * fade + 2, vfx_color(p.kind, 130 * fade))
                    if (i - 1) % 3 == 0 then
                        sprite("twinkle", p.at, 16 * fade + 4, t * 4, c)
                    else   -- a shard streaking along its velocity, with a hot head
                        local tail = p.at - p.vel:scale(.025)
                        local length = math.max(8, (p.at - tail):len() * 2.2)
                        sprite("streak", p.at:lerp(tail, .5), length, math.atan(p.vel.y, p.vel.x) - PI / 2, c)
                        sprite("twinkle", p.at, 7 + 5 * fade, 0, rgba(255, 252, 216, 230 * fade))
                    end
                end
            end
        end
    end

    -- A blocker hitting its cell in the board's entrance.
    function R.vfx_slam(at, kind)
        add(FX_IMPACT, at, vec2(0, 0), kind, .3, 0, 0)
        vfx_emit(at, kind, false, 4)
    end

    ---------------------------------------------------------------------- waves

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
                    local to
                    local bonus_hits = R.pending.bonus_charge_by_cell
                    local charge = bonus_hits and bonus_hits[i]
                    local tool = charge and R.g.resource_yields[was.kind].tool
                    if tool then
                        to = R.board_tool_bounds(tool - 1):center()
                    elseif R.resource_target and R.g.earnings then
                        if not R.g.match_only_resources or not R.pending.direct[i] or R.pending.ordinary[i] then
                            to = R.resource_target(was.kind)
                        end
                    elseif rules.is_goal_kind(R.g, was.kind) or was.kind == RELIC_LEAF or was.kind == RELIC_CRYSTAL then
                        to = R.goal_target(was.kind)
                    end
                    if to then vfx_emit(at, was.kind, true, nil, to, tool, charge) end
                end
            end
        end
        if hits > 0 then
            add(FX_SCORE, sum:scale(1 / hits) - vec2(0, 22), vec2(0, 0), 0, .65, .08, R.g.score - old_score)
            R.score_pulse = .25
        end
    end

    function R.vfx_update(dt)
        for i = 1, FX_CAP do
            local e = pool[i]
            if e.life > 0 then
                e.age = e.age + dt
                if e.age >= e.life + e.delay then e.life = 0 end
            end
        end
        for tool in pairs(bonus_in_flight) do bonus_in_flight[tool] = nil end
        for i = 1, PARTICLES do
            local p = parts[i]
            if p.life > 0 then
                if p.tool then p.to = R.board_tool_bounds(p.tool - 1):center() end
                p.age = p.age + dt
                if p.age >= p.life then
                    if p.flying then land(p) end
                    p.life = 0
                elseif p.tool then
                    bonus_in_flight[p.tool] = (bonus_in_flight[p.tool] or 0) + p.charge
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
                    ring_sprite("ring", e.at, 7 + 28 * t, c)
                    if t < .65 then spark(e.at, 16 * fade, PI / 4, cream) end
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
    end

    return R
end

return V
