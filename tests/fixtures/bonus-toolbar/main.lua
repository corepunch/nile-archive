-- luacheck: globals testing
local game = require("games/" .. testing.game .. "/lua/main")
local R, rules = require("state"), require("rules")
local init, frame = game.init, game.frame
local ticks = 0

function game.init()
    init()
    R.art_review, R.toast_time, ticks = true, 0, 0
    local g = R.g
    assert(#g.tool_order == 8)
    g.tools[1], g.tool_meter[1] = 1, g.tool_threshold
    g.tools[4], g.tool_meter[4] = 1, g.tool_threshold
    g.tool_meter[2], g.tool_meter[6] = 6, 12
end

function game.frame(dt)
    frame(dt)
    ticks = ticks + 1
    if ticks == 3 then app.inject_click(R.board_tool_bounds(0):center()) end
    if ticks == 7 then
        assert(R.tool == 0 and R.g.tools[1] == 1, "selecting a stored Hammer must leave its charge intact")
        if app.arg("spend-bonus") then app.inject_click(R.cell_pos(rules.hex_center())) end
    end
    if ticks == 11 and app.arg("spend-bonus") then
        assert(R.g.tools[1] == 0 and R.g.tool_meter[1] == 0 and R.g.tools[4] == 1,
            "using Hammer must drain just the selected bonus")
    end
end

return game
