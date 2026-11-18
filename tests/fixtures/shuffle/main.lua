-- luacheck: globals testing
-- Start the real shuffle after a few still frames so the reel shows its source board.
local game = testing.game
local desc = require("games/" .. game .. "/lua/main")
local R, rules = require("state"), require("rules")
local init, frame = desc.init, desc.frame
local mixer, frames = nil, 0
local moves

function desc.init()
    init()
    local g = R.g
    if app.arg("shuffle-mixer") then
        for slot, tool in ipairs(g.tool_slots) do
            if tool.action == "shuffle" then mixer = slot; break end
        end
        assert(mixer, "review level must have the Mixer")
        g.tools[mixer], g.tool_meter[mixer] = 1, g.tool_threshold
    else
        require("fixtures/dead_board")(g.level, g)
        assert(not rules.game_hint(g), "review board must have no legal swap")
    end
    moves = g.moves
    R.reset_board(g)
    R.overlay, R.on_island, R.toast_time = R.OV_NONE, false, 0
end

function desc.frame(dt)
    frames = frames + 1
    if frames == 7 then
        if mixer then app.inject_click(R.board_tool_bounds(mixer - 1):center())
        else R.idle_time = 5 end
    end
    frame(dt)
    if frames == 60 then
        assert(R.phase == R.PH_IDLE and R.g.moves == moves and rules.game_hint(R.g), "shuffle must finish on a playable board")
        assert(not mixer or R.g.tools[mixer] == 0, "Mixer press must spend its charge")
    end
end

return desc
