-- Straight runs on the three axial hex axes. A match only clears its cells:
-- no shape makes a power-up. Crossing runs clear their union once.
local S={}
function S.matches(M,g,m,minimum,equal)
    for i=0,M.CELLS-1 do
        if equal(g,i,i) then
            for axis=0,2 do
                if not equal(g,i,M.hex_neighbor(i,axis+3)) and equal(g,i,M.hex_neighbor(M.hex_neighbor(i,axis),axis)) then
                    local cells,c={},i
                    while equal(g,i,c) do cells[#cells+1]=c;c=M.hex_neighbor(c,axis) end
                    if #cells>=minimum then
                        for _, cell in ipairs(cells) do
                            m.mask[cell],m.ordinary[cell]=true,true
                            if m.match_lengths then
                                m.match_lengths[cell] = math.max(m.match_lengths[cell] or 0, #cells)
                            end
                        end
                    end
                end
            end
        end
    end
    m.hits=0
    for _ in pairs(m.mask) do m.hits=m.hits+1 end
end
return S
