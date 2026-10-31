-- A match-free ring with no legal swaps, even with every blocker removed.
-- Shared by the update-loop regression and actual-game review captures.
return function(level)
    local rules = require("rules")
    local g = rules.game_start(level or 6, 123)
    for i = 0, rules.CELLS - 1 do
        if g.active[i] then
            g.tiles[i] = rules.tile((rules.hex_q(i) + 2 * rules.hex_r(i) + 12) % rules.COLORS)
        end
    end
    g.tools = {0, 0, 0}
    return g
end
