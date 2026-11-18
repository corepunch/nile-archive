-- luacheck: globals testing
local game = require("games/" .. testing.game .. "/lua/main")
local R, rules = require("state"), require("rules")
local init, frame = game.init, game.frame
local ticks, tool, swap_a, swap_b, initial_points, match_charge, took_charge = 0

local function check_layout(g)
    assert(#g.tool_slots == 4, "all bonuses keep their toolbar slots")
    local first = R.board_tool_bounds(0)
    local town_cfg = require("town_config").bottom
    assert(math.abs(first.w-town_cfg.build)<.01 and math.abs(first.h-town_cfg.secondary_height)<.01
        and town_cfg.play>first.w, "town secondary buttons match bonus size, Play stays larger")
    local last = first
    for i in ipairs(g.tool_slots) do
        local box = R.board_tool_bounds(i - 1)
        assert(box.y == first.y and box.w <= require("match3").TOOL_SIZE and box.w >= 64 and app.screen():contains(box:center()),
            "the four large buttons stay on one on-screen line")
        if i > 1 then
            assert(box.x >= last:max().x and box.x - last:max().x <= 10,
                "adjacent buttons stay tightly spaced")
        end
        last = box
    end
    assert(first.x >= 0 and last:max().x <= app.screen().w, "the full row fits in the safe area")
    local pause = R.board_pause
    assert(pause.w == first.w and pause.h == pause.w and pause.y == first.y and pause.x >= last:max().x,
        "the round Pause button is the fifth slot")
    assert(math.abs((first.x + pause:max().x) / 2 - app.screen():center().x) < .01, "the five slots are centered")
    local header = R.town.header_form.boxes
    assert(not header.menu and not header.leading and header.cap4
        and math.abs((header.cap1.x + header.cap4:max().x) / 2 - app.screen():center().x) < .01,
        "the display-only header is centered")
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

local function stored_points(g)
    return g.tool_meter[tool] + (not g.single_charge_tools and g.tools[tool] * g.tool_threshold or 0)
end

local function find_flight_swap(g)
    for _, resource in pairs(g.resource_yields) do
        if resource.tool then tool, match_charge = resource.tool, resource.amount * rules.MATCH_MIN end
    end
    assert(tool, "flight review needs an unlocked charging piece")
    if not g.single_charge_tools then
        g.tools[tool], g.tool_meter[tool] = 1, g.tool_threshold - 4
    end
    initial_points = stored_points(g)
    for a = 0, rules.CELLS - 1 do
        for d = 0, 2 do
            local b = rules.hex_neighbor(a, d)
            if rules.game_can_swap(g, a, b) then
                local copy, wave = rules.game_copy(g), rules.new_match()
                if rules.game_swap(copy, a, b, wave) then
                    rules.game_apply(copy, wave)
                    -- In Christmas Market capture currency and boosters in the same wave.
                    local income = copy.earnings[1] + copy.earnings[2] + copy.earnings[3]
                    if stored_points(copy) == initial_points + match_charge and (g.single_charge_tools or income > 0) then
                        swap_a, swap_b = a, b
                        return true
                    end
                end
            end
        end
    end
end

local function prepare_flight(g)
    tool, took_charge = nil, false
    if find_flight_swap(g) then return end
    for seed = 123479, 123578 do
        local candidate = R.make_board(g.level, seed, true)
        if find_flight_swap(candidate) then
            R.reset_board(candidate)
            return
        end
    end
    error("bonus flight review needs a legal bonus match")
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
    assert(#g.tool_slots == 4)
    g.tools[1], g.tool_meter[1] = 1, g.tool_threshold
    g.tools[2], g.tool_meter[2] = 1, g.tool_threshold
    g.tool_meter[3], g.tool_meter[4] = g.tool_threshold // 3, g.tool_threshold * 2 // 3
end

local function review_flight()
    if ticks == 2 and R.g.single_charge_tools then app.inject_click(R.board_tool_bounds(3):center()) end
    if ticks == 6 then
        assert(R.tool == -1, "the swap starts without an active booster")
        app.inject_click(R.cell_pos(swap_a))
    end
    if ticks == 10 then app.inject_click(R.cell_pos(swap_b)) end
    local actual = stored_points(R.g)
    local visible = R.bonus_display_charge(tool)
    if actual > initial_points and not took_charge then
        took_charge = true
        assert(actual == initial_points + match_charge and visible == (R.reduced_motion and actual or initial_points),
            "the first match counts visually when the gems arrive")
    end
    if ticks == 85 then
        assert(took_charge and visible >= initial_points + match_charge, "the matched gems must land and reveal its charge")
    end
end

function game.frame(dt)
    frame(dt)
    ticks = ticks + 1
    if ticks == 1 and testing.game == "relic-rush" then check_layout(R.g) end
    if tool then return review_flight() end
    if ticks == 3 then app.inject_click(R.board_tool_bounds(0):center()) end
    if ticks == 7 then
        assert(R.tool == 0 and R.g.tools[1] == 1, "selecting a stored Dynamite must leave its charge intact")
        if app.arg("spend-bonus") then app.inject_click(R.cell_pos(rules.hex_center())) end
    end
    if ticks == 11 and app.arg("spend-bonus") then
        assert(R.g.tools[1] == 0 and R.g.tool_meter[1] == 0 and R.g.tools[2] == 1,
            "using Dynamite must drain just the selected bonus")
    end
end

return game
