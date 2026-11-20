-- Optional board rules. Higher priority wins when shapes overlap.
-- A colored special keeps matching as its piece kind and fires when it is
-- cleared; a colorless one never matches and fires on a tap or any swap.
local S = {}
-- A special's hit is direct, like a tool's, and swept: its pieces still pay.
local function mark(m, cell)
    if not m.mask[cell] then m.hits = m.hits + 1 end
    m.swept = m.swept or {}
    m.mask[cell], m.direct[cell], m.swept[cell] = true, true, true
end

local rules = {
    striped = {
        priority = 20, colored = true, accepts = function(run) return run.length == 4 end,
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

S.colored = {}
for name, rule in pairs(rules) do S.colored[name] = rule.colored end

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
    local function special(g, cell)
        local rule = enabled[g.tiles[cell].special]
        return rule and eligible(g,cell) and rule or nil
    end
    -- One wave shares its chain: a special fires once however often it is hit.
    local function chain(g, m)
        m.special_effects = m.special_effects or {}
        m.special_seen = m.special_seen or {}
        local seen, fire = m.special_seen, nil
        local function hit(i)
            mark(m,i)
            local rule = special(g,i)
            if rule and not seen[i] then seen[i] = true; fire(i,rule,g.tiles[i].axis) end
        end
        function fire(i, rule, axis, color)
            local event = {cell=i, name=g.tiles[i].special, axis=axis}
            m.special_effects[#m.special_effects + 1] = event
            event.target = rule.effect(board,g,m,i,axis,hit,color)
            if event.target then
                m.plane_targets = m.plane_targets or {}
                m.plane_targets[event.target] = true
            end
        end
        local function start(i, color)
            local rule = special(g,i)
            if not rule or seen[i] then return end
            seen[i] = true
            mark(m,i)
            return rule, color
        end
        return hit, fire, start
    end
    local function activation(g, m, cell, kind)
        local _, fire, start = chain(g,m)
        local rule = start(cell)
        if rule then fire(cell,rule,g.tiles[cell].axis,kind) end
    end
    local function swap_fires(g, a, b)
        local ra, rb = special(g,a), special(g,b)
        if ra and rb then return true end
        return (ra and not ra.colored or rb and not rb.colored) and true or false
    end
    -- The tiles have been exchanged: b holds the piece the player moved.
    local function swap(g, m, a, b)
        local ra, rb = special(g,a), special(g,b)
        local ta, tb = g.tiles[a], g.tiles[b]
        local bomb = rules.color_bomb
        if not (ra and rb) then
            if rb then activation(g,m,b,ta.kind) else activation(g,m,a,tb.kind) end
            return
        end
        local hit, fire, start = chain(g,m)
        if ra.colored and rb.colored then
            -- Two colored specials cross: every axis through the moved piece.
            start(a); start(b)
            for axis = 0, board.AXES - 1 do fire(b,rb,axis) end
        elseif ra == bomb and rb == bomb then
            start(a); start(b)
            fire(b,{effect=function()
                for i = 0, board.CELLS - 1 do if g.active[i] then hit(i) end end
            end})
        elseif (ra == bomb and rb.colored) or (rb == bomb and ra.colored) then
            -- A color bomb turns its partner's whole color into that special.
            local at, gem = a, tb
            if rb == bomb then at, gem = b, ta end
            local count = 0
            for i = 0, board.CELLS - 1 do
                local t = g.tiles[i]
                if g.active[i] and eligible(g,i) and t.kind == gem.kind and not t.special then
                    g.tiles[i] = board.tile(gem.kind,gem.special,count % board.AXES)
                    count = count + 1
                end
            end
            start(at)
            fire(at,bomb,nil,gem.kind)
        else
            activation(g,m,b,ta.kind)
            activation(g,m,a,tb.kind)
        end
    end
    return {
        has_shapes = enabled.plane ~= nil,
        at = function(g, cell)
            for _, shape in ipairs(by_cell[cell] or {}) do
                if same(shape, function(i) return kind_at(g,i) end) then return true end
            end
            return false
        end,
        active = function(g, cell) return special(g,cell) ~= nil end,
        -- A tap fires a colorless special on its own.
        tappable = function(g, cell)
            local rule = special(g,cell)
            return rule ~= nil and not rule.colored
        end,
        swap_fires = swap_fires,
        swap = swap,
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
