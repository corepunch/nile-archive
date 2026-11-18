-- Straight runs on the three axial hex axes. Each cell belongs to one line
-- per axis. The envelope is fixed; holes, stones and colours change per board.
local S = {}

function S.lines(M, minimum)
    local lines = {}
    for start = 0, M.CELLS - 1 do
        for axis = 0, 2 do
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
return S
