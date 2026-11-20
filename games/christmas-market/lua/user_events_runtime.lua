-- user_events_runtime.lua — Christmas Market's wiring of the shared user-event
-- runtime (engine/lua/match3/user_events.lua) to user_events.lua. Required
-- last in main.lua, after every hook it wraps.
local R = require("state")
return require("match3.user_events").install(R, {
    data = require("user_events"), rules = require("rules"),
    island = require("island"), economy = require("economy"),
    target = "pane",
})
