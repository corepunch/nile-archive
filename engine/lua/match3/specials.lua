-- Optional board rules. Higher priority wins when shapes overlap.
local S = {}
local function mark(m, cell)
    if not m.mask[cell] then m.hits = m.hits + 1 end
    m.mask[cell], m.direct[cell] = true, true
end

local rules = {
    striped = {
        priority = 20, accepts = function(run) return run.length == 4 end,
        effect = function(board, g, _, cell, axis, hit)
            for _, direction in ipairs{axis, axis + 3} do
                local other = board.hex_neighbor(cell, direction)
                while other >= 0 do
                    if g.active[other] then hit(other) end
                    other = board.hex_neighbor(other, direction)
                end
            end
        end,
    },
    color_bomb = {
        priority = 40, accepts = function(run) return run.length >= 5 end,
        effect = function(board, g, _match, cell, _axis, hit, kind)
            kind = kind or g.tiles[cell].kind
            for i = 0, board.CELLS - 1 do
                if g.active[i] and g.tiles[i].kind == kind then hit(i) end
            end
        end,
    },
    t_bomb = {
        priority = 30,
        accepts = function(run)
            for _, crossing in ipairs(run.crossings) do
                if crossing.a > 1 and crossing.a < run.length
                    and (crossing.b == 1 or crossing.b == crossing.run.length) then return crossing.run end
            end
        end,
        effect = function(board, g, _match, cell, _axis, hit)
            for d = 0, 5 do
                local i = board.hex_neighbor(cell, d)
                if i >= 0 and g.active[i] then hit(i) end
            end
        end,
    },
    plane = {
        priority = 10, accepts = function(run) return run.rhombus end,
        effect = function(board, g, m, cell, _, hit)
            local target, rank
            for i = 0, board.CELLS - 1 do
                if i ~= cell and g.active[i] and not m.mask[i] and
                    (g.tiles[i].kind >= 0 or g.stone_hp[i] > 0) then
                    local value = (g.oil and g.oil[i] or 0) * 2
                        + (g.chain[i] + g.ice[i] + g.stone_hp[i] > 0 and 1 or 0)
                    if not rank or value > rank then target, rank = i, value end
                end
            end
            if target then hit(target) end
            return target
        end,
    },
}

function S.bind(board, names, kind_at, eligible)
    local enabled, ordered, rhombi, by_cell = {}, {}, {}, {}
    for _, name in ipairs(names) do
        assert(rules[name] and not enabled[name], 'invalid or duplicate special rule: ' .. tostring(name))
        enabled[name] = rules[name]
        ordered[#ordered + 1] = name
    end
    table.sort(ordered, function(a, b) return rules[a].priority > rules[b].priority end)
    if enabled.plane then
        local n = board.hex_neighbor
        for cell = 0, board.CELLS - 1 do
            for d = 0, 2 do
                local a, b = n(cell, d), n(cell, d + 1)
                local c = a >= 0 and n(a, d + 1) or -1
                if a >= 0 and b >= 0 and c >= 0 then
                    local shape = {cell, a, b, c}
                    rhombi[#rhombi + 1] = shape
                    for _, i in ipairs(shape) do
                        by_cell[i] = by_cell[i] or {}
                        table.insert(by_cell[i], shape)
                    end
                end
            end
        end
    end
    local function same(shape, kinds)
        local kind = kinds(shape[1])
        return kind ~= nil and kind == kinds(shape[2]) and kind == kinds(shape[3]) and kind == kinds(shape[4])
    end
    local function activation(g, m, cell, kind)
        m.special_effects = m.special_effects or {}
        m.special_seen = m.special_seen or {}
        local seen = m.special_seen
        local function activate(i, color)
            local t = g.tiles[i]
            local rule = enabled[t.special]
            if not rule or seen[i] or not eligible(g,i) then return end
            seen[i] = true
            local function hit(j) mark(m,j); activate(j) end
            mark(m,i)
            local event = {cell=i, name=t.special, axis=t.axis}
            m.special_effects[#m.special_effects + 1] = event
            event.target = rule.effect(board,g,m,i,t.axis,hit,color)
            if event.target then
                m.plane_targets = m.plane_targets or {}
                m.plane_targets[event.target] = true
            end
        end
        activate(cell,kind)
    end
    return {
        has_shapes = enabled.plane ~= nil,
        at = function(g, cell)
            for _, shape in ipairs(by_cell[cell] or {}) do
                if same(shape, function(i) return kind_at(g,i) end) then return true end
            end
            return false
        end,
        active = function(g, cell) return enabled[g.tiles[cell].special] ~= nil and eligible(g,cell) end,
        activate = activation,
        award = function(g, m, kinds, runs, preferred, alternate)
            for _, cells in ipairs(rhombi) do
                if same(cells, function(i) return kinds[i] end) then
                    runs[#runs + 1] = {cells=cells, rhombus=true, crossings={}}
                    for _, i in ipairs(cells) do
                        if not m.mask[i] then m.hits = m.hits + 1 end
                        m.mask[i], m.ordinary[i] = true, true
                    end
                end
            end
            local membership = {}
            for _, run in ipairs(runs) do
                for j, i in ipairs(run.cells) do
                    local list = membership[i] or {}
                    for _, other in ipairs(list) do
                        if run.axis and other.run.axis and run.axis ~= other.run.axis then
                            table.insert(run.crossings, {a=j,b=other.index,run=other.run})
                            table.insert(other.run.crossings, {a=other.index,b=j,run=run})
                        end
                    end
                    membership[i] = list
                    list[#list + 1] = {run=run,index=j}
                end
            end
            local used = {}
            for _, name in ipairs(ordered) do
                for _, run in ipairs(runs) do
                    local match = enabled[name].accepts(run)
                    if match then
                        local cells = run.cells
                        if type(match) == "table" then
                            cells = {table.unpack(cells)}
                            for _, i in ipairs(match.cells) do cells[#cells + 1] = i end
                        end
                        local pick, rank, overlaps
                        for _, i in ipairs(cells) do
                            if used[i] then overlaps = true end
                            local score = i == preferred and 2 or i == alternate and 1 or 0
                            if eligible(g,i) and (not rank or score > rank or score == rank and i < pick) then
                                pick, rank = i, score
                            end
                        end
                        if pick and not overlaps then
                            m.special_awards = m.special_awards or {}
                            m.special_awards[pick] = {name=name,axis=run.axis}
                            for _, i in ipairs(cells) do used[i] = true end
                        end
                    end
                end
            end
        end,
    }
end

return S
