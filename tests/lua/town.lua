-- The shared town screen's configuration: the merge of a game's
-- lua/town_config.lua over the engine defaults (engine/lua/town.lua).
local town = require("town")

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

-- The two puzzle towns share the primary Play layout. The level-list action
-- keeps the old middle hook, so existing progression and smoke input stay valid.
for _, game in ipairs{"relic-rush", "christmas-market"} do
    local config = town.config(town_config(game))
    local b = config.bottom
    check(b.layout == "play-primary" and b.play > b.build, "Play is the primary button")
    check(b.build == b.secondary_height, "Build and Levels use matching square slots")
    local view = town.new({}, config, {skin={}, wallet=function() return {} end})
    local buttons = view.navigation.boxes
    check(buttons.pause and buttons.play.w > buttons.pause.w, "Pause joins the bottom row and Play is largest")
    near((buttons.build.x + buttons.pause:max().x) / 2, view.bottom_row:center().x, "the four-button row stays centered")
    near(buttons.pause:center().y, view.buttons.play.y, "Pause and Play share a center line")
    near(view.buttons.build.y, view.buttons.levels.y, "secondary buttons align")
    check(view.buttons.build.x + b.build/2 < view.buttons.play.x - b.play/2, "Build does not overlap Play")
    check(view.buttons.play.x + b.play/2 < view.buttons.levels.x - b.build/2, "Levels does not overlap Play")
end
