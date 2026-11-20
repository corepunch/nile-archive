-- Continuous alpha-blended smoke from the registered openings of placed buildings.
local R = require("state")
local kinds = require("island").kinds
local outlets = {}
for key, flue in pairs(require("chimney_flues")) do outlets[assert(kinds[key])] = flue end

local PUFFS, INTERVAL = 9, .24

local function plume(at, width, time)
    local emission = math.floor(time)
    for n = PUFFS - 1, 0, -1 do
        local puff = emission - n
        local age = (time - puff) / PUFFS
        local curl = math.sin(puff * 2.39996 + age * 4)
        local drift = 1.9 * age ^ 2 + curl * age * .55
        local rise = .4 + 3.5 * age
        local at_puff = at + vec2(drift * width, -rise * width)
        local side = width * (.65 + 2.25 * math.sqrt(age))
        local opacity = math.floor(158 * math.min(1, age / .08) * (1 - age) ^ 1.3)
        gfx.image_rot(R.vfx_smoke[puff % 4 + 1], rect.centered(at_puff, size2.splat(side)),
            curl * .62, color(176, 175, 186, opacity))
    end
end

function R.draw_town_world(view)
    if R.reduced_motion then return end
    local c = R.island
    gfx.clip(view)
    for i, b in ipairs(c.items) do
        local flue = outlets[b.type]
        if flue then
            local box = c:placed_sprite_rect(i - 1)
            if box.w > 0 then
                local scale = box.w / R.buildings[b.type + 1].sprite.w
                local at = vec2(box.x + flue.x * scale, box.y + flue.y * scale)
                local width = flue.width * scale
                if rect.contains(rect.inflate(view, 6 * width), at) then
                    plume(at, width, R.now / INTERVAL + i * 1.618)
                end
            end
        end
    end
    gfx.unclip()
end
