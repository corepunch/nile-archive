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

-- Both campaigns center Play between a round Build button and Pause.
for _, game in ipairs{"relic-rush", "christmas-market"} do
    local next_level = 1
    local view = town.new({}, town_config(game), {skin={}, wallet=function() return {} end,
        play_label=function() return next_level end})
    local form = view.navigation
    local build, play, pause = form.boxes.build, form.boxes.play, form.boxes.pause
    check(build:max().x < play.x and play:max().x < pause.x, "Build, Play and Pause have separate targets")
    near(build:center().y, play:center().y, "Build shares the Play center line")
    near(pause:center().y, play:center().y, "Pause shares the Play center line")
    near(play:center().x, app.screen():center().x, "Play is centered on screen")
    check(build.w == build.h and pause.w < play.w, "Build is round and Pause is smaller than Play")
    check(form.nodes.play.level == 1, "Play displays the first level in a fresh campaign")
    next_level = 100
    view:layout()
    check(form.nodes.play.level == 100, "Play updates to the next level")
    next_level = nil
    local screen = app.screen
    rawset(app, "screen", function() return rect(0, 47, 390, 763) end)
    view:layout()
    rawset(app, "screen", screen)
    check(form.nodes.play.level == nil, "Play receives no level after the final win")
    build, play, pause = form.boxes.build, form.boxes.play, form.boxes.pause
    near(play:center().x, 195, "Play stays centered on a narrow phone")
    check(build.x >= 0 and pause:max().x < 390 and pause:max().y < 810 and pause.w >= 44,
        "all three targets fit the narrow phone's safe area")
end
