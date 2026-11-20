-- Reference player for tuning and income: visible matches, no tools or RNG
-- lookahead. Break ties in goal progress with score, future clearing power
-- and nearby holes below remaining targets that bring fresh pieces onto them.
-- A new line or rainbow gem is worth two or five extra clears respectively.
local award_value = {striped = 100, color_bomb = 250}

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
        local function consider(i, j)
            local legal, progress, score = rules.game_probe_swap(g, i, j, probe)
            if not legal or progress < best_progress then return end
            local award_bonus, stirred = 0, 0
            for c in pairs(probe.mask) do
                local award = probe.special_awards and probe.special_awards[c]
                if award then
                    award_bonus = award_bonus + (award_value[award.name] or 0)
                else
                    for _, row in ipairs(goals[columns[c]] or {}) do
                        local distance = rows[c] - row
                        if distance >= 0 then stirred = stirred + 1 / (1 + distance) end
                    end
                end
            end
            local value = score + award_bonus + 40 * stirred
            if progress > best_progress or value > best_value then
                best_progress, best_value, a, b = progress, value, i, j
            end
        end
        for edge = 1, #edges, 2 do
            local i, j = edges[edge], edges[edge + 1]
            local first, second = g.tiles[i], g.tiles[j]
            if movable[i] and movable[j] and (first.kind ~= second.kind or first.special or second.special) then
                consider(i, j)
                -- A line-gem cross is centered on the destination.
                if first.special == 'striped' and second.special == 'striped' then consider(j, i) end
            end
        end
        return a, b
    end
end
