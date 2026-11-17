-- luacheck: globals testing
local game = require("games/" .. testing.game .. "/lua/main")
local R, rules = require("state"), require("rules")
local init, frame = game.init, game.frame
local ticks, tool, swap_a, swap_b, took_charge = 0

local function check_layout(g)
    assert(#g.tool_slots == 4, "all bonuses keep their toolbar slots")
    local first = R.board_tool_bounds(0)
    local last = first
    for i in ipairs(g.tool_slots) do
        local box = R.board_tool_bounds(i - 1)
        assert(box.y == first.y and box.w >= 100 and app.screen():contains(box:center()),
            "the four large buttons stay on one on-screen line")
        if i > 1 then
            assert(box.x >= last:max().x and box.x - last:max().x <= 10,
                "adjacent buttons stay tightly spaced")
        end
        last = box
    end
    assert(first.x >= 0 and last:max().x <= app.screen().w, "the full row fits in the safe area")
    local header = R.town.header_form.boxes
    assert(math.abs(header.menu.w - header.menu.h) < .01 and header.menu.h == R.town.cfg.header.menu.size,
        "the pause button retains its square slot beside the wallet")
    assert(math.abs(header.cap1.w - header.cap3.w) < .01 and header.cap3:max().x < header.menu.x,
        "the wallet shares the available space without overlapping pause")
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
    assert(g.tool_meter[4] == nil, "locked bonuses keep their toolbar slots")
    for a = 0, rules.CELLS - 1 do
        for d = 0, 2 do
            local b = rules.hex_neighbor(a, d)
            if rules.game_can_swap(g, a, b) then
                local copy, wave = rules.game_copy(g), rules.new_match()
                if rules.game_swap(copy, a, b, wave) then
                    rules.game_apply(copy, wave)
                    if copy.tool_meter[tool] == g.bonus.amount * 3 then swap_a, swap_b = a, b; return end
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
    assert(#g.tool_slots == 4)
    g.tools[1], g.tool_meter[1] = 1, g.tool_threshold
    g.tools[2], g.tool_meter[2] = 1, g.tool_threshold
    g.tool_meter[3], g.tool_meter[4] = g.tool_threshold // 3, g.tool_threshold * 2 // 3
end

local function review_flight()
    if ticks == 2 then app.inject_click(R.board_tool_bounds(3):center()) end
    if ticks == 6 then
        assert(R.tool == -1 and R.g.tool_meter[4] == nil, "a locked bonus cannot be selected")
        app.inject_click(R.cell_pos(swap_a))
    end
    if ticks == 10 then app.inject_click(R.cell_pos(swap_b)) end
    local actual = R.g.tool_meter[tool]
    local visible = R.bonus_display_charge(tool)
    local triple = R.g.bonus.amount * 3
    if actual > 0 and not took_charge then
        took_charge = true
        assert(actual == triple and visible == (R.reduced_motion and triple or 0),
            "the first triple fills the socket as the gems arrive")
    end
    if ticks == 62 then
        assert(took_charge and visible >= triple, "the matched triple must land and reveal its charge")
    end
end

function game.frame(dt)
    frame(dt)
    ticks = ticks + 1
    if ticks == 1 then check_layout(R.g) end
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
