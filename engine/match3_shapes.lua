-- Straight runs on the three axial hex axes. A match only clears its cells:
-- no shape makes a power-up. Runs that share a cell form one group so that a
-- carpet under any of its cells spreads to all of them.
local S={}
function S.matches(M,g,m,minimum,equal)
    local groups={}
    local function add(cells)
        local group={}
        for _,i in ipairs(cells) do group[i]=true end
        for n=#groups,1,-1 do
            local other,overlap=groups[n],false
            for i in pairs(other) do if group[i] then overlap=true;break end end
            if overlap then
                for i in pairs(other) do group[i]=true end
                table.remove(groups,n)
            end
        end
        groups[#groups+1]=group
    end
    for i=0,M.CELLS-1 do
        if equal(g,i,i) then
            for axis=0,2 do
                if not equal(g,i,M.hex_neighbor(i,axis+3)) and equal(g,i,M.hex_neighbor(M.hex_neighbor(i,axis),axis)) then
                    local cells,c={},i
                    while equal(g,i,c) do cells[#cells+1]=c;c=M.hex_neighbor(c,axis) end
                    if #cells>=minimum then
                        add(cells)
                        if m.match_lengths then
                            for _, cell in ipairs(cells) do
                                m.match_lengths[cell] = math.max(m.match_lengths[cell] or 0, #cells)
                            end
                        end
                    end
                end
            end
        end
    end
    m.spread={}
    for _,group in ipairs(groups) do
        local carpet=false
        for i in pairs(group) do
            m.mask[i],m.ordinary[i]=true,true
            carpet=carpet or g.hs and g.hs.cells[i] and g.hs.cells[i].carpet or g.carpet and (g.carpet[i] or 0)>0
        end
        if carpet then for i in pairs(group) do m.spread[i]=true end end
    end
    m.hits=0
    for _ in pairs(m.mask) do m.hits=m.hits+1 end
end
return S
