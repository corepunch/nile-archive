-- Straight runs on the board axes. Each cell belongs to one line
-- per axis. The envelope is fixed; holes, stones and colours change per board.
local S = {}

function S.lines(M, minimum)
    local lines = {}
    for start = 0, M.CELLS - 1 do
        for axis = 0, M.AXES - 1 do
            if M.hex_neighbor(start, axis + 3) < 0 then
                local line, cell = {}, start
                while cell >= 0 do
                    line[#line + 1] = cell
                    cell = M.hex_neighbor(cell, axis)
                end
                if #line >= minimum then lines[#lines + 1] = line end
            end
        end
    end
    return lines
end

function S.matches(lines, kinds, m, minimum)
    for _, line in ipairs(lines) do
        local start, kind = 1, kinds[line[1]]
        -- The extra iteration closes a run at the edge of the envelope.
        for pos = 2, #line + 1 do
            local next_kind = kinds[line[pos]]
            if next_kind ~= kind then
                local length = pos - start
                if kind and length >= minimum then
                    for n = start, pos - 1 do
                        local cell = line[n]
                        if not m.mask[cell] then m.hits = m.hits + 1 end
                        m.mask[cell], m.ordinary[cell] = true, true
                        if m.match_lengths then
                            m.match_lengths[cell] = math.max(m.match_lengths[cell] or 0, length)
                        end
                    end
                end
                start, kind = pos, next_kind
            end
        end
    end
end
-- Compact square layouts, centred in a common column-major envelope.
-- Space outside the drawn rows and hyphens are holes. Dots are plain cells,
-- asterisks are targets, plus signs are two-layer targets, and c/C are
-- targets with single/double chains. `tier` sets the tuner's move margin.
function S.square_levels(boards, columns, rows, lesson, dress)
    local levels, names = {}, {}
    for n, board in ipairs(boards) do
        local width = #board[1]
        assert(width <= columns and #board <= rows, "square board exceeds its envelope")
        local left, top = (columns - width) // 2, (rows - #board) // 2
        local mask, oil, double, chains = {}, {}, {}, {}
        for i = 1, columns * rows do mask[i] = "0" end
        for y, row in ipairs(board) do
            assert(#row == width and not row:find("[^.*+cC-]"), "invalid square board row")
            for x = 1, width do
                local mark = row:sub(x, x)
                local cell = (left + x - 1) * rows + top + y - 1
                if mark ~= "-" then mask[cell + 1] = "1" end
                if mark ~= "-" and mark ~= "." then oil[#oil + 1] = cell end
                if mark == "+" then double[#double + 1] = cell end
                if mark == "c" or mark == "C" then
                    chains[#chains + 1] = {cell=cell, hits=mark == "c" and 1 or 2}
                end
            end
        end
        assert(#oil > 0, "square board needs at least one target")
        levels[n] = {name=board.name, tier=board.tier, moves=board.moves, lesson=board.lesson or lesson,
            mask=table.concat(mask), oil=oil, oil_double=double, chain_cells=chains, goals={"oil"},
            score=0, relics=0, chains=0, ice=0, dress=dress}
        names[n] = board.name
    end
    return levels, names
end

return S
