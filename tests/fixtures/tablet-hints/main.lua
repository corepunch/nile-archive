-- luacheck: globals testing

-- Show the threshold crossing and the last tablets clearing on a real board.
local desc = require('games/' .. testing.game .. '/lua/main')
local R, rules = require('state'), require('rules')
local init, frame = desc.init, desc.frame
local targets, frames

function desc.init()
    init()
    local g = R.g
    targets = {table.unpack(rules.level_of(g).oil)}
    local center = rules.hex_center()
    table.sort(targets, function(a, b)
        local da, db = rules.hex_distance(a, center), rules.hex_distance(b, center)
        return da == db and a < b or da < db
    end)
    for j = 5, #targets do g.oil[targets[j]] = 0 end
    g.oil_left, frames = 4, 0
    g.oil[targets[2]], g.oil[targets[3]] = 1, 1   -- on double-pane boards, show both strengths
end

function desc.frame(dt)
    frames = frames + 1
    if frames == 5 or frames == 37 or frames == 49 or frames == 61 then
        local g = R.g
        g.oil[targets[g.oil_left]], g.oil_left = 0, g.oil_left - 1
    end
    frame(dt)
end

return desc
