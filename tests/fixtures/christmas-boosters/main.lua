local game = require("games/christmas-market/lua/main")
local R, rules = require("state"), require("rules")
local init, frame = game.init, game.frame
local ticks, target

function game.init()
    init()
    ticks = 0
    R.art_review, R.toast_time, R.reduced_motion = not app.arg("spend-booster"), 0, true
    local g = R.g
    g.tools[1], g.tool_meter[1] = 2, 0
    g.tools[2], g.tools[4] = 1, 1
    g.tool_meter[3] = g.tool_threshold // 3
    target = rules.hex_center()
end

function game.frame(dt)
    frame(dt)
    ticks = ticks + 1
    if ticks == 1 then
        local boxes = R.town.header_form.boxes
        assert(boxes.leading and boxes.cap3 and boxes.cap4 == nil, "the board shows Moves and only three resources")
        local previous = boxes.leading
        for slot = 1, 3 do
            local box = boxes["cap" .. slot]
            local icon_center = R.town.resource_targets[slot]
            assert(box.x >= previous:max().x and box:center().y == boxes.leading:center().y,
                "resource counters follow Moves on the same line")
            assert(icon_center and box:contains(icon_center), "matched resources land on their counter")
            previous = box
        end
        local center = app.screen():center()
        assert(not boxes.menu and math.abs((boxes.leading.x + previous:max().x) / 2 - center.x) < .01,
            "the display-only header is centered")
        local top, bottom = math.huge, -math.huge
        for cell = 0, rules.CELLS - 1 do
            if rules.game_cell_active(R.g, cell) then
                local y = R.cell_pos(cell).y
                top, bottom = math.min(top, y), math.max(bottom, y)
            end
        end
        assert(math.abs((top + bottom) / 2 - center.y) < .01, "the active board is vertically centered")
        assert(#R.g.tool_slots == 4, "four boosters are visible")
        local first = R.board_tool_bounds(0)
        local last = first
        for slot = 0, 3 do
            local box = R.board_tool_bounds(slot)
            assert(box.w <= require("match3").TOOL_SIZE and box.w >= 64 and box.w == box.h and box.y == first.y,
                "boosters share one row of large square art cells")
            assert(box.x >= 0 and box:max().x <= app.screen().w and box:max().y <= app.screen().h,
                "the complete toolbar stays on screen")
            if slot > 0 then assert(box.x >= last:max().x and box.x - last:max().x <= 10) end
            last = box
        end
        local pause = R.board_pause
        assert(pause.w == first.w and pause.y == first.y and pause.x >= last:max().x
            and app.screen():contains(pause:center()), "Pause is the fifth bottom button")
        assert(math.abs((first.x + pause:max().x) / 2 - center.x) < .01, "the bottom row is centered")
        app.inject_click(R.town.resource_targets[1])
    end
    if ticks == 3 then
        assert(R.toast_time <= 0 and R.overlay == R.OV_NONE, "the currency header takes no input")
        app.inject_click(R.board_tool_bounds(3):center())
    end
    if ticks == 7 then
        assert(R.tool == 3 and R.g.tools[4] == 1, "aiming keeps the Shooting Star use")
        if app.arg("spend-booster") then app.inject_click(R.cell_pos(target)) end
    end
    if ticks == 11 and app.arg("spend-booster") then
        assert(R.g.tools[4] == 0 and R.g.tools[1] == 2 and R.g.tools[2] == 1,
            "using the Shooting Star spends only its own use")
    end
end

return game
