-- luacheck: globals testing check

-- Follow a complete hint pulse, then jump to the repeat and tap a tablet.
local desc = require('games/' .. testing.game .. '/lua/main')
local R, rules = require('state'), require('rules')
local init, frame = desc.init, desc.frame
local target, frames, hints

local draw_hint = R.vfx_tablet_hint
function R.vfx_tablet_hint(...)
    hints = hints + 1
    draw_hint(...)
end

function desc.init()
    init()
    local g = R.g
    local targets = {table.unpack(rules.level_of(g).oil)}
    local center = rules.hex_center()
    table.sort(targets, function(a, b)
        local da, db = rules.hex_distance(a, center), rules.hex_distance(b, center)
        return da == db and a < b or da < db
    end)
    for j = 3, #targets do g.oil[targets[j]] = 0 end
    target, frames = targets[2], 0
    g.oil[target], g.oil_left = 1, 2   -- on double-pane boards, show both strengths
    R.idle_time = 4.8
end

function desc.frame(dt)
    frames = frames + 1
    hints = 0
    if frames == 236 then R.idle_time = R.idle_time + 5.7 end
    if frames == 244 then app.inject_click(R.cell_pos(target)) end
    frame(dt)
    if frames == 20 or frames == 240 then
        check(hints == 2 and R.hint_a >= 0, 'the move suggestion and both tablet reminders are visible after the idle delay')
    elseif frames == 233 then
        check(hints == 0 and R.hint_a >= 0, 'the tablet pulse fades before repeating while the move hint stays visible')
    elseif frames == 1 or frames == 248 then
        check(hints == 0 and R.hint_a < 0, 'both hints wait for inactivity and reset on a tap')
    end
end

return desc
