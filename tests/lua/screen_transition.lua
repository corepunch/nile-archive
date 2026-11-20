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

local preview = transition.new({style = "none"}, "wipe")
preview:watch("town", true)
preview:watch("match3", true)
check(preview:active(), "the runtime preview can override the game setting")
