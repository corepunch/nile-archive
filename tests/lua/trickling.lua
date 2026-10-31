-- Shared regressions, run against both portrait games' real rule modules.
local rules = require("rules")
local index, tile = rules.hex_index, rules.tile
local function board(cells)
    local g = rules.game_start(0, 123)
    for i = 0, rules.CELLS - 1 do
        g.active[i], g.tiles[i], g.chain[i], g.ice[i] = false, tile(-1), 0, 0
    end
    for _, p in ipairs(cells) do
        local i = index(p[1], p[2])
        g.active[i], g.tiles[i] = true, tile(p[3] or -1, p[4])
    end
    return g
end
local center, left, right, above = index(0, 0), index(-1, 0), index(1, -1), index(0, -1)
-- A gem directly above falls before either diagonal donor.
for _, side in ipairs({{-1, 0}, {1, -1}}) do
    local g = board({{0, 0}, {0, -1, 2}, {side[1], side[2], 4, rules.BOMB}})
    local _, steps = rules.game_collapse(g)
    local source = index(side[1], side[2])
    check(steps[1].from[center] == above, "straight down beats either diagonal")
    check(g.tiles[center].kind == 2 and g.tiles[source].special == rules.BOMB, "side special stays put")
end
-- A distant diagonal donor must not delay an available straight fall.
do
    local g = board({{0, 0}, {0, -1, 2}, {-1, 0}, {-1, -1}, {-2, 0, 5}})
    local _, steps = rules.game_collapse(g)
    check(steps[1].from[center] == above, "do not wait for a distant diagonal gem")
    check(steps[1].from[left] == index(-2, 0) and g.tiles[center].kind == 2, "side route fills independently")
end
-- A diagonal destination must not steal a donor with an empty cell below it,
-- even when that destination is visited before the straight destination.
for _, side in ipairs({{-1, 0}, {1, -1}}) do
    local source = index(side[1], side[2])
    local down = rules.hex_neighbor(source, 1)
    local g = board({{0, 0}, {0, -1, 2}, {side[1], side[2], 4, rules.BOMB},
                     {rules.hex_q(down), rules.hex_r(down)}})
    g.chain[above] = 1
    local _, steps = rules.game_collapse(g)
    check(steps[1].from[down] == source, "donor takes its own empty cell below")
    check(steps[1].tiles[center].kind < 0, "diagonal waits while donor can fall straight")
    check(steps[1].tiles[down].special == rules.BOMB, "fall preserves special")
    -- Occupied and locked cells below both allow the donor to slide sideways.
    for _, blocker in ipairs({"gem", "chain", "ice"}) do
        g = board({{0, 0}, {0, -1, 2}, {side[1], side[2], 4, rules.BOMB},
                   {rules.hex_q(down), rules.hex_r(down), 1}})
        g.chain[above] = 1
        if blocker ~= "gem" then g[blocker][down] = 1 end
        _, steps = rules.game_collapse(g)
        check(steps[1].from[center] == source, blocker .. " below allows diagonal")
        check(steps[1].tiles[center].special == rules.BOMB, "slide preserves special")
    end
end
-- Every exposed column top spawns vertically, even beside an occupied diagonal.
do
    local g = board({{0, 0}, {1, -1, 3}})
    local _, steps = rules.game_collapse(g)
    check(steps[1].from[center] < 0 and g.tiles[above].kind == -1, "spawn above a column's exposed top")
    check(steps[1].tiles[right].kind == 3, "top inlet does not steal the side gem")
    g = board({{0, 0}})
    local from
    from, steps = rules.game_collapse(g)
    check(#steps == 1 and steps[1].from[center] < 0 and from[center] < 0, "isolated cell fills from above")
    g = board({{0, 0}, {0, -1, 1}})
    _, steps = rules.game_collapse(g)
    check(steps[1].from[center] == above, "straight fall when no diagonal can feed")
end
-- The whole stepped top edge refills together, rather than from one apex.
for level = 0, rules.LEVELS - 1 do
    local g = rules.game_start(level, 123)
    for i = 0, rules.CELLS - 1 do
        g.chain[i], g.ice[i], g.tiles[i] = 0, 0, tile(-1)
    end
    local _, steps = rules.game_collapse(g)
    for i = 0, rules.CELLS - 1 do
        if g.active[i] and not rules.game_cell_active(g, rules.hex_neighbor(i, 4)) then
            check(steps[1].from[i] < 0 and steps[1].tiles[i].kind >= 0, "every top cell spawns in the first step")
        end
    end
end
-- Ice and chains block donors; an empty diagonal inlet supplies from its edge,
-- never by spawning directly in the lower cell behind the blocker.
for _, blocker in ipairs({"ice", "chain"}) do
    local g = board({{0, 0}, {-1, 0, 3}, {0, -1, 2}})
    g[blocker][left] = 1
    local _, steps = rules.game_collapse(g)
    check(steps[1].from[center] == above and g.tiles[left].kind == 3, blocker .. " cannot donate")
    g = board({{0, 0}, {0, -1, 2}, {-1, 0}})
    g[blocker][above] = 1
    _, steps = rules.game_collapse(g)
    check(steps[1].tiles[center].kind < 0 and steps[2].from[center] == left, "side inlet feeds below " .. blocker)
end
-- Audit each simultaneous step, including competing destinations and deep gaps,
-- on every campaign silhouette, and repeat to check determinism.
for level = 0, rules.LEVELS - 1 do
    for seed = 1, 12 do
        local g = rules.game_start(level, seed)
        for i = 0, rules.CELLS - 1 do
            if g.active[i] and g.chain[i] == 0 and g.ice[i] == 0 and (i + seed) % 3 ~= 0 then g.tiles[i] = tile(-1) end
        end
        local old, repeat_g = rules.game_copy(g), rules.game_copy(g)
        local previous = g.tiles
        local from, steps = rules.game_collapse(g)
        local again, repeat_steps = rules.game_collapse(repeat_g)
        check(#steps == #repeat_steps and g.rng == repeat_g.rng, "seeded collapse is deterministic")
        for _, step in ipairs(steps) do
            local used = {}
            for i = 0, rules.CELLS - 1 do
                local source = step.from[i]
                if source ~= i and step.tiles[i].kind >= 0 then
                    check(previous[i].kind < 0 and old.active[i] and old.chain[i] == 0 and old.ice[i] == 0, "destination was empty and movable")
                    if source >= 0 then
                        check(not used[source] and previous[source] == step.tiles[i], "gem moves once per step, preserving identity")
                        used[source] = true
                        check(source == rules.hex_neighbor(i, 3) or source == rules.hex_neighbor(i, 4)
                              or source == rules.hex_neighbor(i, 5), "one downward edge, never across voids")
                        if source ~= rules.hex_neighbor(i, 4) then
                            local down = rules.hex_neighbor(source, 1)
                            check(not rules.game_cell_active(old, down) or old.chain[down] > 0
                                  or old.ice[down] > 0 or previous[down].kind >= 0,
                                  "diagonal only when the donor cannot fall straight down")
                        end
                        check(old.active[source] and old.chain[source] == 0 and old.ice[source] == 0, "donor is movable")
                    else
                        if rules.game_cell_active(old, rules.hex_neighbor(i, 4)) then
                            for _, d in ipairs({3, 4, 5}) do
                                local p = rules.hex_neighbor(i, d)
                                check(not rules.game_cell_active(old, p) or old.chain[p] > 0 or old.ice[p] > 0, "interior spawns only when all donors are blocked")
                            end
                        end
                    end
                end
            end
            previous = step.tiles
        end
        local origins = {}
        for i = 0, rules.CELLS - 1 do
            check(g.tiles[i].kind >= 0 == not not g.active[i], "only the mask fills")
            check(from[i] == again[i] and g.tiles[i].kind == repeat_g.tiles[i].kind, "repeated source and tile agree")
            if g.active[i] then
                check(not origins[from[i]], "no duplicate original or spawned gems")
                origins[from[i]] = true
                if from[i] >= 0 then check(g.tiles[i] == old.tiles[from[i]] or g.tiles[i].kind == old.tiles[from[i]].kind
                    and g.tiles[i].special == old.tiles[from[i]].special, "original tile survives") end
            end
            if not g.active[i] or g.chain[i] > 0 or g.ice[i] > 0 then
                check(from[i] == i and g.tiles[i].kind == old.tiles[i].kind, "locks and holes stay fixed")
            end
        end
        for i = 0, rules.CELLS - 1 do
            if old.active[i] and old.tiles[i].kind >= 0 then check(origins[i], "all original gems conserved") end
        end
        local rng = g.rng
        local _, idle = rules.game_collapse(g)
        check(#idle == 0 and g.rng == rng, "full board stays put without RNG")
    end
end
print("trickling: shared board conservation, paths and deterministic refill passed")
return 0
