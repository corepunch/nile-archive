-- Source BornPatterns grammar. The same conservative subset as Match3LabCore.
local P = {}
function P.tokens(text)
    local out, at = {}, 1
    while at <= #text do
        local a,b,token = text:find('%[([^%[%]]+)%]',at)
        assert(a == at, 'invalid BornPatterns sequence')
        out[#out+1],at = token,b+1
    end
    assert(#out>0,'empty BornPatterns sequence')
    return out
end
function P.palette(model,spec)
    local pattern=assert((spec.colorPatterns or {})[tonumber(model.id)+1],'missing color pattern')
    assert(pattern==model.pattern and model.isLooped=='1','conflicting color pattern')
    local digits=assert(pattern:match('^%[Cs([0-5]+)%]$'),'invalid source palette')
    local weights={}
    for c in digits:gmatch('.') do
        local k=tonumber(c)
        assert(not weights[k],'duplicate palette color')
        weights[k]=(spec.colors or {})[k] or 100
    end
    return weights
end
function P.queue(model,spec)
    local pattern=assert((spec.bornPatterns or {})[tonumber(model.id)+1],'missing BornPatterns reference')
    assert(pattern.str==model.pattern,'conflicting BornPatterns reference')
    assert(pattern.isLooped=='true' or pattern.isLooped=='false','invalid loop flag')
    assert(model.isLooped==(pattern.isLooped=='true' and '1' or '0'),'conflicting loop flag')
    assert(not pattern.loopedCount or pattern.loopedCount=='0','unsupported loop count')
    local tokens=P.tokens(pattern.str)
    local settings=pattern.settings or {}
    assert(#settings==0 or #settings==#tokens,'BornPatterns property count')
    local units={}
    for i,token in ipairs(tokens) do
        local unit={count=1}
        if token=='c' then unit.random=true
        elseif token:match('^c[1-6]$') then unit.color=tonumber(token:sub(2))-1
        elseif token=='b' or token=='f' or token=='z' or token=='l' or token=='lh' or token=='lv' then unit.special=token
        elseif token:match('^[tT][1-3]$') then unit.element=token:sub(1,1)=='t' and 'cookie' or 'hazelnut';unit.hp=tonumber(token:sub(2))
        else error('unsupported BornPatterns token ['..token..']') end
        local seen={}
        for _,property in ipairs(settings[i] or {}) do
            local name=property.name
            assert(not seen[name],'duplicate BornPatterns property');seen[name]=true
            if name=='CountProperty' then
                unit.count=assert(tonumber(property.count),'invalid CountProperty')
                assert(math.type(unit.count)=='integer' and unit.count>0 and unit.count<=10000,'invalid CountProperty')
            elseif name=='DropChanceProperty' then assert(property.value=='100','unsupported DropChanceProperty')
            elseif name=='LevelProperty' then
                local hp=tonumber(property.levels)
                assert(unit.element and hp and hp>=1 and hp<=3 and hp<=tonumber(property.levelMax),'unsupported LevelProperty')
                unit.hp=hp
            elseif name=='ColorSetProperty' then
                assert(token=='c' and property.randomEverySpawn=='0','unsupported ColorSetProperty')
                unit.weights=assert(((spec.colorSets or {}).c or {})[tonumber(property.colorSetId)+1],'missing color set')
                local total=0
                for k=0,5 do local w=unit.weights[k]
                    assert(math.type(w)=='integer' and w>=0 and w<=100,'invalid color set weight');total=total+w
                end
                assert(total>0,'empty color set')
            else error('unsupported BornPatterns property '..tostring(name)) end
        end
        units[#units+1]=unit
    end
    return {units=units,looped=pattern.isLooped=='true',cursor=1,emitted=0,spawns=0}
end
function P.next(queue)
    local unit=queue.units[queue.cursor]
    if not unit then return nil end
    queue.emitted,queue.spawns=queue.emitted+1,queue.spawns+1
    if queue.emitted==unit.count then
        queue.emitted,queue.cursor=0,queue.cursor+1
        if queue.cursor>#queue.units and queue.looped then queue.cursor=1 end
    end
    return unit
end
return P
