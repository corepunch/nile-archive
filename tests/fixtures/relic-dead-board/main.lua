-- Wrapper around the real game; capture.py supplies its modules as symlinks.
local game = require("game")
local R, rules = require("state"), require("rules")
local init = game.init
game.init = function()
    init()
    R.g = require("setup")()
    R.pending = rules.new_match()
    R.phase, R.phase_time, R.idle_time = R.PH_IDLE, 0, 5.1
    R.overlay, R.on_island = R.OV_NONE, false
    R.selected, R.tool, R.hint_a, R.hint_b = -1, -1, -1, -1
    R.toast_time = 0
    assert(not rules.game_hint(R.g), "fixture must start without a legal move")
end
return game
