-- luacheck: globals testing
local desc = require("games/" .. testing.game .. "/lua/main")
local island, R = require("island"), require("state")
local scenes = require(testing.game)
local init = desc.init

function desc.init()
    init()
    local scene = assert(scenes[app.arg("town-scene")], "unknown App Store town scene")
    local c = R.island
    c.count, c.open = 0, (1 << island.ISLAND_ZONES) - 1
    R.prog.level = require("rules").LEVELS
    R.prog.wallet = purse(2840, 1360, 1620, R.prog.level * 3)
    for _, placement in ipairs(scene.items) do
        local key, x, y = table.unpack(placement)
        local kind = assert(island.kinds[key], key)
        local ok, spot = c:find_spot(kind, vec2(x, y))
        assert(ok, "no plot for " .. key)
        assert(c:add(spot, kind, 0) >= 0, "could not place " .. key)
    end
    R.island_focus(vec2(scene.x, scene.y), scene.zoom)
    R.on_island, R.toast_time = true, 0
end

return desc
