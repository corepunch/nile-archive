-- Homescapes shapes adapted to axial hexes: straight runs on three axes and
-- four-cell rhombi on every pair of adjacent axes. Power-ups are not colors.
local S={}
function S.matches(M,g,m,preferred,alternate,minimum,no_specials,eligible,equal)
    local groups={}
    local function add(cells,length,axis,rhombus)
        local group={cells={},length=length,axis=axis,rhombus=rhombus,cross=false}
        for _,i in ipairs(cells) do group.cells[i]=true end
        -- Merge transitively: a rhombus can connect two otherwise disjoint runs.
        local changed=true
        while changed do
            changed=false
            for n=#groups,1,-1 do
                local other,overlap=groups[n],false
                for i in pairs(other.cells) do if group.cells[i] then overlap=true;break end end
                if overlap then
                    if group.axis and other.axis and group.axis~=other.axis then group.cross=true end
                    group.cross=group.cross or other.cross
                    group.rhombus=group.rhombus or other.rhombus
                    if other.length>group.length then group.length,group.axis=other.length,other.axis end
                    for i in pairs(other.cells) do group.cells[i]=true end
                    table.remove(groups,n);changed=true
                end
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
                    if #cells>=minimum then add(cells,#cells,axis,false) end
                end
            end
            if minimum==3 then
                for d=0,2 do
                    local a,b=M.hex_neighbor(i,d),M.hex_neighbor(i,d+1)
                    local c=a>=0 and M.hex_neighbor(a,d+1) or -1
                    if equal(g,i,a) and equal(g,i,b) and equal(g,i,c) then add({i,a,b,c},0,nil,true) end
                end
            end
        end
    end
    m.spread={}
    for _,group in ipairs(groups) do
        local pick,count,carpet=-1,0,false
        for i=0,M.CELLS-1 do if group.cells[i] then
            m.mask[i],m.ordinary[i]=true,true;count=count+1
            if eligible(g,i) then
                if i==preferred or i==alternate and pick~=preferred or pick<0 then pick=i end
            end
            carpet=carpet or g.hs and g.hs.cells[i] and g.hs.cells[i].carpet or g.carpet and (g.carpet[i] or 0)>0
        end end
        local sp=group.length>=minimum+2 and M.PRISM or group.cross and count>=5 and M.BOMB
            or group.length==minimum+1 and (group.axis==0 and M.ROW or group.axis==1 and M.COLUMN or M.DIAGONAL)
            or group.rhombus and M.PLANE or M.NORMAL
        if not no_specials and pick>=0 and sp~=M.NORMAL then m.make[pick]=sp end
        if carpet then for i in pairs(group.cells) do m.spread[i]=true end end
    end
    m.hits=0
    for _ in pairs(m.mask) do m.hits=m.hits+1 end
end
return S
