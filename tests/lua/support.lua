-- Named cases continue after failures; deterministic fixtures never load textures.
local M = {}
function M.suite(name)
    local t = {checks=0, failures=0, cases=0, name=name}
    function t:check(ok, message)
        self.checks = self.checks + 1
        if not ok then error(message or 'assertion failed', 2) end
        check(true)
    end
    function t:case(label, run)
        self.cases = self.cases + 1
        local ok, err = pcall(run)
        if not ok then
            self.failures = self.failures + 1
            print(('FAIL %s / %s: %s'):format(name, label, err))
            -- The engine owns reporting for the whole file; the label keeps the case diagnosable.
            if not self.expected_failures then check(false, label..': '..tostring(err)) end
        end
    end
    function t:finish()
        print(('%s: %d cases, %d checks, %d failures'):format(name, self.cases, self.checks, self.failures))
        return self.failures
    end
    return t
end

function M.same(a, b)
    if type(a) ~= type(b) then return false end
    if type(a) ~= 'table' then return a == b end
    for k, v in pairs(a) do if not M.same(v, b[k]) then return false end end
    for k in pairs(b) do if a[k] == nil then return false end end
    return true
end

function M.board(rules)
    local g = {tiles={}, active={}, soil={}, chain={}, ice={}, tools={2,2,2},
        level=0, moves=20, score=0, relics=0, dug=0, obstacles=0, initial_obstacles=0,
        initial_soil=0, combo=0, cleared=0, last_gold=0, last_wood=0, last_stone=0,
        wood=0, stone=0, rng=12345, won=false, lost=false}
    for i=0,rules.CELLS-1 do
        g.tiles[i] = rules.tile(-1)
        g.active[i], g.soil[i], g.chain[i], g.ice[i] = true, 0, 0, 0
    end
    return g
end

function M.wallet(def)
    local w = purse()
    for i=1,purse.MAX do w[i] = math.max(def.cost[i], def.needs[i]) + 10 end
    return w
end
function M.city(defs)
    local c = city.new()
    c:init(nil)
    c.cam = camera{world=size2(10000,10000),view=rect(0,0,10000,10000),zoom=1,min_zoom=1,max_zoom=1,center=vec2(5000,5000)}
    c.defs = defs
    return c
end
return M
