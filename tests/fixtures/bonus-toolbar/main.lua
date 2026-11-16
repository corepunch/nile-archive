-- luacheck: globals testing
local game = require("games/" .. testing.game .. "/lua/main")
local R, rules = require("state"), require("rules")
local init, frame = game.init, game.frame
local ticks, tool, swap_a, swap_b, took_charge = 0

local function check_layout(g)
    assert(#g.tool_order == 8, "all bonuses keep their toolbar slots")
    local first = R.board_tool_bounds(g.tool_order[1] - 1)
    local second = R.board_tool_bounds(g.tool_order[5] - 1)
    assert(second.x == first.x and second.y > first:max().y and first.w >= 64,
        "two aligned rows keep the bonus buttons large")
    for row = 0, 1 do
        local previous = 0
        for col = 1, 4 do
            local box = R.board_tool_bounds(g.tool_order[row * 4 + col] - 1)
            assert(box.x > previous and box:max().x <= R.SCREEN_W and box:max().y <= app.screen().h,
                "the eight buttons have separate on-screen hit areas")
            previous = box:max().x
        end
    end
    local min_x, max_x, min_y, max_y = math.huge, -math.huge, math.huge, -math.huge
    for cell = 0, rules.CELLS - 1 do
        if rules.game_cell_active(g, cell) then
            local at = R.cell_pos(cell)
            min_x, max_x = math.min(min_x, at.x), math.max(max_x, at.x)
            min_y, max_y = math.min(min_y, at.y), math.max(max_y, at.y)
        end
    end
    local center = app.screen():center()
    assert(math.abs((min_x + max_x) / 2 - center.x) < .01 and math.abs((min_y + max_y) / 2 - center.y) < .01,
        "the playable cells are centred on screen")
    assert(first.y > R.BOARD_CLIP:max().y, "the tray starts below the board")
end

local function prepare_flight(g)
    tool, took_charge = g.bonus.tool, false
    assert(g.tool_meter[1] == nil, "locked bonuses keep their toolbar slots")
    for a = 0, rules.CELLS - 1 do
        for d = 0, 2 do
            local b = rules.hex_neighbor(a, d)
            if rules.game_can_swap(g, a, b) then
                local copy, wave = rules.game_copy(g), rules.new_match()
                if rules.game_swap(copy, a, b, wave) then
                    rules.game_apply(copy, wave)
                    if copy.tool_meter[tool] == 9 then swap_a, swap_b = a, b; return end
                end
            end
        end
    end
    error("bonus flight review needs a legal three-gem bonus swap")
end

function game.init()
    init()
    R.art_review, R.toast_time, ticks = true, 0, 0
    local g = R.g
    if app.arg("fly-bonus") then
        R.art_review = false
        R.reduced_motion = not not app.arg("flight-no-motion")
        return prepare_flight(g)
    end
    tool = nil
    assert(#g.tool_order == 8)
    g.tools[1], g.tool_meter[1] = 1, g.tool_threshold
    g.tools[4], g.tool_meter[4] = 1, g.tool_threshold
    g.tool_meter[2], g.tool_meter[6] = 6, 12
end

local function review_flight()
    if ticks == 2 then app.inject_click(R.board_tool_bounds(0):center()) end
    if ticks == 6 then
        assert(R.tool == -1 and R.g.tool_meter[1] == nil, "a locked bonus cannot be selected")
        app.inject_click(R.cell_pos(swap_a))
    end
    if ticks == 10 then app.inject_click(R.cell_pos(swap_b)) end
    local actual = R.g.tool_meter[tool]
    local visible = R.bonus_display_charge(tool)
    if actual > 0 and not took_charge then
        took_charge = true
        assert(actual == 9 and visible == (R.reduced_motion and 9 or 0),
            "the first triple earns nine points and its artwork fills on arrival")
    end
    if ticks == 62 then
        assert(took_charge and visible >= 9, "the matched triple must land and reveal all nine points")
    end
end

function game.frame(dt)
    frame(dt)
    ticks = ticks + 1
    if ticks == 1 then check_layout(R.g) end
    if tool then return review_flight() end
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
