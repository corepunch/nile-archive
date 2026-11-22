-- The shared town screen's configuration: the merge of a game's
-- lua/town_config.lua over the engine defaults (engine/lua/town/screen.lua).
local town = require("town.screen")

local cfg = town.config({header = {align = "right", role = town.none}, bottom = {middle = {kind = "custom"}}})
check(cfg.header.align == "right" and cfg.header.role == nil, "a game overrides one field and town.none clears a default")
check(cfg.header.width == 110 and cfg.bottom.build == 132, "untouched defaults survive")
check(cfg.bottom.middle.kind == "custom" and cfg.bottom.middle.diameter == 64, "nested objects merge field by field")
-- Every game's file, whichever game this suite runs in.
local function town_config(game)
    local path = "/lua/town_config.lua"
    local source = app.read_text("../../" .. game .. path) or app.read_text("games/" .. game .. path)
    return source and assert(load(source, "@" .. game .. path))()
end
for _, game in ipairs({"relic-rush", "christmas-market", "nile-archive"}) do
    local config = town_config(game)
    check(config and config.texts.placing, game .. " ships a town_config.lua with its wording")
end

-- The five campaign actions have equal, disjoint targets. Updating the
-- phase replaces its four project keys and keeps the fifth Play action.
for _, game in ipairs{"relic-rush", "christmas-market"} do
    local config = town_config(game)
    local phase, first = "First", 1
    local function projects()
        local items = {}
        for i = 1, 4 do items[i] = {id=first + i - 1, state=i == 1 and "ready" or "locked"} end
        return phase, items
    end
    local view = town.new({}, config, {skin={}, wallet=function() return {} end, projects=projects})
    local form = view.navigation
    local actions = form.nodes.actions.children
    check(#actions == 5 and actions[5].item_key == "play", "the last of five actions is Play")
    local play = form.boxes[actions[5].id]
    for i = 1, 4 do
        local box, next_box = view.project_boxes[i], form.boxes[actions[i + 1].id]
        check(box:max().x < next_box.x, "project hit regions do not overlap")
        near(box:center().y, play:center().y, "projects and Play share a center line")
        near(box.w, play.w, "projects and Play share the available row")
    end
    phase, first = "Second", 5
    view:layout()
    check(view.project_phase == phase and view.project_boxes[1] == nil and view.project_boxes[5] ~= nil,
        "advancing the phase updates the project keys and hit targets")
    local screen = app.screen
    rawset(app, "screen", function() return rect(0, 47, 390, 763) end)
    view:layout()
    rawset(app, "screen", screen)
    actions = form.nodes.actions.children
    play = form.boxes[actions[5].id]
    if game == "relic-rush" then
        near(play.w, play.h, "Next Level is square on a narrow phone")
        check(not form.nodes.phase and actions[5].text == "Next\nLevel", "the bar labels its next-level action on two lines")
    end
    check(view.project_boxes[5].x >= 0 and play:max().x < 390 and play:max().y < 810 and play.w >= 44,
        "all five targets fit the narrow phone's safe area")
end
