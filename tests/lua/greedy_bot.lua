-- Reference player for tuning and income: visible matches, no tools or RNG
-- lookahead. Goal progress comes first. Break ties with ordinary score and
-- nearby matches below remaining targets that bring fresh pieces onto them.
return function(rules)
    local probe = rules.new_match()
    local columns, rows, edges, movable = {}, {}, {}, {}
    for i = 0, rules.CELLS - 1 do
        columns[i], rows[i] = rules.hex_q(i), rules.hex_r(i)
        for axis = 0, rules.AXES - 1 do
            local j = rules.hex_neighbor(i, axis)
            if j >= 0 then edges[#edges + 1], edges[#edges + 2] = i, j end
        end
    end
    return function(g)
        local goals = {}
        for i = 0, rules.CELLS - 1 do
            movable[i] = g.active[i] and g.chain[i] == 0 and g.ice[i] == 0
                and g.stone_hp[i] == 0 and g.tiles[i].kind >= 0
            if g.active[i] and (g.oil[i] > 0 or g.chain[i] > 0 or g.ice[i] > 0 or g.stone_hp[i] > 0) then
                local q = columns[i]
                goals[q] = goals[q] or {}
                goals[q][#goals[q] + 1] = rows[i]
            end
        end
        local best_progress, best_value, a, b = -1, -1, -1, -1
        for edge = 1, #edges, 2 do
            local i, j = edges[edge], edges[edge + 1]
            if movable[i] and movable[j] and (g.tiles[i].kind ~= g.tiles[j].kind
                or g.tiles[i].special or g.tiles[j].special) then
                local legal, progress, score = rules.game_probe_swap(g, i, j, probe)
                if legal then
                    local stirred = 0
                    for c in pairs(probe.mask) do
                        for _, row in ipairs(goals[columns[c]] or {}) do
                            local distance = rows[c] - row
                            if distance >= 0 then stirred = stirred + 1 / (1 + distance) end
                        end
                    end
                    local value = score + 40 * stirred
                    if progress > best_progress or progress == best_progress and value > best_value then
                        best_progress, best_value, a, b = progress, value, i, j
                    end
                end
            end
        end
        return a, b
    end
end
