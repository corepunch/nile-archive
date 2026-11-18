-- luacheck: globals testing

-- Film a real swipe into an authored blocker on the selected board:
-- a chain, or `--block ice` / `--block stone`.
local desc = require('games/' .. testing.game .. '/lua/main')
local R, rules = require('state'), require('rules')
local init, frame = desc.init, desc.frame
local source, target, frames

function desc.init()
    init()
    frames = 0
    local g, best = R.g, math.huge
    local block = app.arg('block') or 'chain'
    local layer = assert(({chain = g.chain, ice = g.ice, stone = g.stone_hp})[block], 'unknown --block')
    for b = 0, rules.CELLS - 1 do
        if (layer[b] or 0) > 0 and rules.hex_distance(b, rules.hex_center()) < best then
            for direction = 0, 5 do
                local a = rules.hex_neighbor(b, direction)
                if rules.game_cell_active(g, a) and g.chain[a] == 0 and g.ice[a] == 0 and g.tiles[a].kind >= 0 then
                    source, target, best = a, b, rules.hex_distance(b, rules.hex_center())
                    break
                end
            end
        end
    end
    assert(source, 'review board needs a ' .. block .. ' next to a movable gem')
end

function desc.frame(dt)
    frames = frames + 1
    if frames == 2 then app.inject_press(R.cell_pos(source)) end
    if frames == 3 then app.inject_release(R.cell_pos(target)) end
    frame(dt)
end

return desc
