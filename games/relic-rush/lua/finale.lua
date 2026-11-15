-- The same delayed three flashes first come from the cliff and later from Ines.
local R = require("state")
local rules = require("rules")
local art = require("art").finale

local function flash(t)
    local delay, spacing, width = .65, .53, .27
    t = t - delay
    if t < 0 or t >= 3 * spacing then return 0 end
    local phase = t % spacing
    return phase < width and math.sin(math.pi * phase / width)^2 or 0
end

function R.clear_scene()
    local g = R.g
    if not g or not g.won or g.level ~= R.prog.level or g.story_clear then return end
    local level = rules.level_of(g)
    if not level.signal or (level.signal == "landing" and g.delivered < g.delivery_total) then return end
    if not R.signal_scene or R.signal_scene.game ~= g then
        R.signal_scene = {game=g, key=level.signal, time=R.now,
            exit=level.deliveries and level.deliveries.exits[1]}
    end
    local scene = R.signal_scene
    scene.elapsed = R.now - scene.time
    local duration = scene.key == "landing" and 3.8 or 2.25
    if not scene.skipped and scene.elapsed < duration then return scene end
end

local function lamp(at, radius, amount)
    if amount <= 0 then return end
    R.vfx_halo(at, radius, color(255, 170, 69, 165 * amount))
    R.vfx_halo(at, radius * .37, color(255, 238, 169, 230 * amount))
end

function R.draw_clear_scene(scene, inp)
    local t, still = scene.elapsed, R.reduced_motion
    if t > .4 and (inp.released or inp.back) then scene.skipped = true end
    if scene.key == "cliff" then
        lamp(vec2(R.SCREEN_W * .56, R.hud_rect.y - 29), 32, still and .45 or flash(t))
        return
    end

    -- The delivered plate is visible in the exit before we cut across the bay.
    local join = still and 0 or .68
    local incoming = still and 1 or num.saturate((t - join) / .25)
    if incoming < 1 then
        local at = R.cell_pos(scene.exit)
        local side = 2 * R.HEX_R
        lamp(at, 37, 1 - incoming)
        gfx.image(R.board_art[art.plate], rect.centered(at, size2.splat(side)), color.WHITE)
    end
    if incoming == 0 then return end

    local tex = R.board_art[art.landing]
    local size = texture.size(tex)
    local full = app.bleed()
    local scale = math.min(full.w / size.w, full.h / size.h)
    local dst = rect.centered(full:center(), size2(size.w * scale, size.h * scale))
    local at = vec2(dst.x + dst.w * art.lantern.x, dst.y + dst.h * art.lantern.y)
    gfx.bleed(true)
    gfx.rect(full, color(9, 24, 25, 255 * incoming))
    gfx.image(tex, dst, color(255, 255, 255, 255 * incoming))
    lamp(at, dst.w * .14, still and .42 or flash(t - join))
    gfx.bleed(false)
end
