-- Reference player for tuning and income: visible matches, no tools or RNG
-- lookahead. Goal progress comes first. Break ties with ordinary score and
-- nearby matches below remaining targets that bring fresh pieces onto them.
return function(rules)
    local probe = rules.new_match()
    return function(g)
        local goals = {}
        for i = 0, rules.CELLS - 1 do
            if g.active[i] and (g.oil[i] > 0 or g.chain[i] > 0 or g.ice[i] > 0 or g.stone_hp[i] > 0) then
                local q = rules.hex_q(i)
                goals[q] = goals[q] or {}
                goals[q][#goals[q] + 1] = rules.hex_r(i)
            end
        end
        local best_progress, best_value, a, b = -1, -1, -1, -1
        for i = 0, rules.CELLS - 1 do
            for d = 0, rules.AXES - 1 do
                local j = rules.hex_neighbor(i, d)
                if rules.game_swap_matches(g, i, j) then
                    local trial = rules.game_copy(g)
                    assert(rules.game_swap(trial, i, j, probe))
                    rules.game_apply(trial, probe)
                    local progress = g.obstacles - trial.obstacles
                    for c = 0, rules.CELLS - 1 do progress = progress + g.oil[c] - trial.oil[c] end
                    local stirred = 0
                    for c in pairs(probe.mask) do
                        for _, row in ipairs(goals[rules.hex_q(c)] or {}) do
                            local distance = rules.hex_r(c) - row
                            if distance >= 0 then stirred = stirred + 1 / (1 + distance) end
                        end
                    end
                    local value = trial.score - g.score + 40 * stirred
                    if progress > best_progress or progress == best_progress and value > best_value then
                        best_progress, best_value, a, b = progress, value, i, j
                    end
                end
            end
        end
        return a, b
    end
end
