-- A match-free ring with no legal swaps, even with every blocker removed.
-- Shared by the update-loop regression and actual-game review captures.
return function(level, board)
    local rules = require("rules")
    local g = board or rules.game_start(level or 6, 123)
    for i = 0, rules.CELLS - 1 do
        if g.active[i] and g.stone_hp[i] == 0 then
            g.tiles[i] = rules.tile((rules.hex_q(i) + 2 * rules.hex_r(i) + 12) % rules.COLORS)
        end
    end
    for i in ipairs(g.tools) do
        g.tools[i] = 0
        if g.tool_meter and g.tool_meter[i] then g.tool_meter[i] = 0 end
    end
    return g
end
