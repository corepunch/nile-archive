local desc = require("games/christmas-market/lua/main")
local R = require("state")
local init = desc.init

function desc.init()
    init()
    local c = R.island
    c.clearance = size2(0, 0) -- let the painted slab edges meet for the art check
    local firs, bench = 10, 11
    c.count, c.open = 0, 63
    local first = c:snap(vec2(760, 1650), firs)
    local wallet = purse(2000)
    c:begin_place(firs, first)
    local event
    event, wallet = c:confirm(wallet, 0)
    assert(event.result == city.BUILT, "the Lantern Firs must place")

    -- These world points snap to adjacent plots along the same tile row.
    local second = c:snap(first + vec2(95, 36), bench)
    assert(not c:can_place(second + (first - second):scale(.01), bench, -1),
        "moving the second foundation toward the first must overlap it")
    c:begin_place(bench, second)
    event = c:confirm(wallet, 0)
    assert(event.result == city.BUILT and c.count == 2, "shared footprint edges must be buildable")

    R.island_focus((first + second):scale(.5) - vec2(0, 45), .94)
    R.on_island, R.toast_time = true, 0
end

return desc
