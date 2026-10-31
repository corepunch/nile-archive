-- capture.py links the real game as game.lua and supplies its normal modules.
local game = require("game")
local R, rules = require("state"), require("rules")
local init, frame = game.init, game.frame
local steps, pending, ticks = {}, nil, 0
game.init = function()
    init()
    R.art_review, R.toast_time = true, 0
    R.on_island, R.overlay = false, R.OV_NONE
    R.selected, R.tool = -1, -1
    local state = app.arg("tool-state") or "normal"
    if state == "disabled" then R.g.tools = {0, 0, 0}
    elseif state == "selected" then R.tool = 1
    elseif state == "pressed" then app.inject_press(vec2(63, 822 + R.drop))
    elseif state == "hover" then app.inject_move(vec2(287, 822 + R.drop)) end
    if app.arg("tool-smoke") then
        for k = 0, 2 do
            local x = 63 + k * 112
            -- The expanded top/bottom edges used to fall outside the 76x65 hit box.
            steps[#steps + 1] = {point = vec2(x, 785 + R.drop), selected = k}
            steps[#steps + 1] = {point = vec2(x, 859 + R.drop), selected = -1}
            steps[#steps + 1] = {point = vec2(x, 862 + R.drop), selected = -1}
        end
        -- Selecting and using a tool still consumes only its own charge.
        steps[#steps + 1] = {point = vec2(63, 822 + R.drop), selected = 0}
        steps[#steps + 1] = {point = R.cell_pos(rules.hex_center()), selected = -1, charges = 1}
    end
end
game.frame = function(dt)
    frame(dt)
    if not app.arg("tool-smoke") then return end
    ticks = ticks + 1
    if ticks % 3 ~= 0 then return end
    if pending then
        assert(R.tool == pending.selected, "square tool edge did not select/toggle correctly")
        assert(R.g.tools[1] == (pending.charges or 2) and R.g.tools[2] == 2 and R.g.tools[3] == 2,
               "tool charges changed without applying that tool")
    end
    pending = table.remove(steps, 1)
    if pending then app.inject_click(pending.point)
    else print("square tools: all three top/bottom hit edges, outside edges and pickaxe use passed"); app.quit() end
end
return game
