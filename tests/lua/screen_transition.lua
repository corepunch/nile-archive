local transition = require("screen_transition")
local view = transition.new{
    style = "none",
    routes = {menu = {town = "wipe"}, town = {hidden_object = "flash"}},
}

view:watch("menu", true)
check(not view:active(), "startup shows the initial screen immediately")
view:watch("town", true)
check(view:active() and not view:covering(), "the menu-to-town route starts a wipe")
view:watch("town", false)
check(not view:active(), "reduced motion cancels an ongoing transition")
view:watch("hidden_object", true)
check(view:active() and view:covering(), "the town-to-search route covers the outgoing screen")
view:watch("town", true)
check(not view:active(), "the reverse route uses the default and clears the previous effect")

view:watch("hidden_object", true)
local idle = input{pinch = 1}
local function paint() end
view:frame(idle, .16, paint)
check(view:active() and not view:covering(), "the flash reveals the incoming screen after .16 seconds")
view:frame(idle, .18, paint)
check(view:active(), "the effect is still revealing just before .35 seconds")
view:frame(idle, .011, paint)
check(not view:active(), "the flash finishes after .35 seconds")

local preview = transition.new({style = "none"}, "wipe")
preview:watch("town", true)
preview:watch("match3", true)
check(preview:active(), "the runtime preview can override the game setting")
