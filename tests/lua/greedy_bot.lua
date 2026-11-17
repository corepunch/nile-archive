-- The reference bot for tuning and balance: the best evaluated swap (score
-- plus goal progress), no tools. Like a player, when no move reaches a goal
-- it prefers moves that clear cells at or below the remaining tablets and
-- blockers, so new pieces fall onto them.
return function(rules)
    local probe = rules.new_match()
    local function targets(g)
        local below = {}   -- column -> lowest row of a goal cell in it
        for i = 0, rules.CELLS - 1 do
            if g.active[i] and (g.oil[i] > 0 or g.chain[i] > 0 or g.ice[i] > 0 or g.stone_hp[i] > 0) then
                local q, r = rules.hex_q(i), rules.hex_r(i)
                below[q] = below[q] or {}
                below[q][#below[q] + 1] = r
            end
        end
        return below
    end
    return function(g)
        local goals = targets(g)
        local best, a, b = -1, -1, -1
        for i = 0, rules.CELLS - 1 do
            for d = 0, 2 do
                local j = rules.hex_neighbor(i, d)
                local value = rules.game_evaluate_move(g, i, j, probe)
                if value >= 0 then
                    local stirred = 0
                    for c in pairs(probe.mask) do
                        local column = goals[rules.hex_q(c)]
                        if column then
                            for _, r in ipairs(column) do
                                if r <= rules.hex_r(c) then stirred = stirred + 1 end
                            end
                        end
                    end
                    value = value + 40 * stirred
                    if value > best then best, a, b = value, i, j end
                end
            end
        end
        return a, b
    end
end
