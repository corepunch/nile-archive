-- island.lua — the Lost Valley map: shoreline, six regions and ten wonders.
--
-- The island is an engine city. This file only knows the map: which world
-- points are lawn (an authored contour), which region owns them (a hidden
-- axial hex grid flood-filled from six region centres, so every region is one
-- connected patch) and which regions touch. Placement, unlocking, moving and
-- drawing are the engine's.
local M = {}

M.ISLAND_W, M.ISLAND_H, M.ISLAND_ZONES, M.WONDERS = 1920, 2880, 6, 10
local ZONES, WONDERS = M.ISLAND_ZONES, M.WONDERS
local STARS, COMPASSES = 4, 5

-- Ten restorations in campaign order. Each sprite's footprint is measured in
-- its own pixels (see docs/BUILDINGS.md): the ground centre it stands on
-- (pivot), the width from its left corner to its right one, and its size in
-- whole TILE tiles.
M.TILE = size2(40, 20)   -- half extents: a tile is 80 x 40 world units

-- The catalogue owns sprite registration, prices, descriptions and unlocks.
M.catalogue = require("buildings")
M.buildings, M.wonders = M.catalogue, {}
for i=1,WONDERS do M.wonders[i]=M.buildings[i] end

function M.wonder_count(c)
    local n=0
    for _,b in ipairs(c.items) do if b.type < WONDERS then n=n+1 end end
    return n
end

function M.owned(c, kind)
    local n=0
    for _,b in ipairs(c.items) do if b.type==kind then n=n+1 end end
    return n
end

function M.can_buy(c, wallet, level, kind)
    if kind<0 or kind>=#M.buildings or c.count>=160 then return false end
    local d=M.buildings[kind+1]
    if kind<WONDERS and (kind~=M.wonder_count(c) or kind>=level) then return false end
    if kind>=WONDERS and wallet[1]-M.reserved_gold(c,level)<d.cost[1] then return false end
    if not wallet:covers(d.needs) or not wallet:covers(d.cost) then return false end
    return true
end

-- Keep the earned story restorations affordable in the finite campaign economy.
function M.reserved_gold(c, level)
    local gold=0
    for kind=0,math.min(level,WONDERS)-1 do
        if M.owned(c,kind)==0 then gold=gold+M.wonders[kind+1].cost[1] end
    end
    return gold
end

function M.restore_saved(c,level)
    -- Purchased decorations do not count toward campaign restoration progress.
    -- Rehome old, larger footprints onto valid tiles without charging again.
    local items,seen=c.items,{}
    local needs_relocation=false
    c.count=0
    for _,b in ipairs(items) do
        local valid=b.type>=WONDERS or (b.type<level and not seen[b.type])
        if valid then
            local spot=c:snap(b.pos,b.type)
            local ok=c:can_place(spot,b.type,-1)
            if not ok then ok,spot=c:find_spot(b.type,spot) end
            -- Preserve ownership even if a future terrain change leaves no free
            -- plot. The player can move it after opening more land.
            if not ok then spot=b.pos;needs_relocation=true end
            c:add(spot,b.type,b.stamp);seen[b.type]=true
        end
    end
    return needs_relocation
end

local zone_names = {"Harbor glade", "Sunlit coast", "Fern meadow", "Sun garden", "Ancient heights", "Temple ridge"}
local zone_stars = {0, 6, 9, 15, 21, 27}
local zone_compasses = {0, 2, 3, 4, 5, 6}
local zone_centers = {vec2(760, 2080), vec2(1330, 2100), vec2(670, 1430), vec2(1330, 1440), vec2(850, 770), vec2(1220, 860)}
local suggestions = {vec2(760, 2030), vec2(1270, 2120), vec2(640, 1580), vec2(1110, 1830), vec2(1000, 1420),
                     vec2(1400, 1710), vec2(1070, 1040), vec2(1390, 1350), vec2(690, 1250), vec2(940, 780)}

-- Authored walkable lawn contour in half-scale map coordinates.
local shore = {{440, 220}, {535, 235}, {610, 300}, {700, 350}, {795, 470}, {795, 680}, {770, 820},
               {805, 965}, {710, 1110}, {580, 1170}, {440, 1160}, {290, 1090}, {210, 980}, {230, 855},
               {180, 700}, {190, 575}, {255, 465}, {320, 400}, {340, 295}}

local function on_lawn(p)
    local x, y = math.floor(math.floor(p.x) * .5), math.floor(math.floor(p.y) * .5)
    local inside = false
    local n = #shore
    local j = n
    for i = 1, n do   -- even-odd point in polygon
        local a, b = shore[i], shore[j]
        if (a[2] > y) ~= (b[2] > y) and x < (b[1] - a[1]) * (y - a[2]) / (b[2] - a[2]) + a[1] then inside = not inside end
        j = i
    end
    return inside
end

---------------------------------------------------------- hidden region map

local MQ, MR, RMIN = 29, 52, -14
local MAP_HEX_R = 45
local region            -- -2 water, -1 unassigned land, else zone (0-based)
local axial_dirs = {{1, 0}, {0, 1}, {-1, 1}, {-1, 0}, {0, -1}, {1, -1}}

local function map_index(q, r)
    if q >= 0 and q < MQ and r >= RMIN and r < RMIN + MR then return q * MR + r - RMIN end
    return -1
end
local function map_axial(i) return i // MR, i % MR + RMIN end

local function map_position(i)
    local q, r = map_axial(i)
    return vec2(math.floor(q * 1.5 * MAP_HEX_R), math.floor((r + q * .5) * 1.732050808 * MAP_HEX_R))
end

local function region_init()
    if region then return end
    region = {}
    local queue, head, tail = {}, 1, 0
    for i = 0, MQ * MR - 1 do region[i] = on_lawn(map_position(i)) and -1 or -2 end
    for z = 0, ZONES - 1 do   -- seed each region at the land cell nearest its centre
        local best, best_d = -1, math.huge
        for i = 0, MQ * MR - 1 do
            if region[i] == -1 then
                local d = map_position(i) - zone_centers[z + 1]
                local dd = d:dot(d)
                if dd < best_d then best_d, best = dd, i end
            end
        end
        if best >= 0 then region[best] = z; tail = tail + 1; queue[tail] = best end
    end
    while head <= tail do   -- multi-source flood fill: every region grows at the same pace
        local i = queue[head]
        head = head + 1
        local q, r = map_axial(i)
        for d = 1, 6 do
            local n = map_index(q + axial_dirs[d][1], r + axial_dirs[d][2])
            if n >= 0 and region[n] == -1 then region[n] = region[i]; tail = tail + 1; queue[tail] = n end
        end
    end
end

local function map_cell(p)
    local q = p.x / (1.5 * MAP_HEX_R)
    local r = p.y / (1.732050808 * MAP_HEX_R) - q * .5
    local s = -q - r
    local iq, ir, is = math.floor(q + .5), math.floor(r + .5), math.floor(s + .5)
    local dq, dr, ds = math.abs(iq - q), math.abs(ir - r), math.abs(is - s)
    if dq > dr and dq > ds then iq = -ir - is
    elseif dr > ds then ir = -iq - is end
    return map_index(iq, ir)
end

function M.island_zone(p)
    region_init()
    local i = map_cell(p:floor())
    return (i >= 0 and region[i] >= 0) and region[i] or -1
end

function M.island_grass(p) return on_lawn(p) and M.island_zone(p) >= 0 end

function M.island_zone_touches(z, open)
    region_init()
    for i = 0, MQ * MR - 1 do
        if region[i] == z then
            local q, r = map_axial(i)
            for d = 1, 6 do
                local n = map_index(q + axial_dirs[d][1], r + axial_dirs[d][2])
                if n >= 0 and region[n] >= 0 and (open >> region[n]) & 1 == 1 then return true end
            end
        end
    end
    return false
end

function M.island_suggestion(i) return suggestions[num.clampi(i, 0, WONDERS - 1) + 1] end

-- Map, zones, wonders and rules for an engine city.
function M.island_setup(c)
    c.defs = M.buildings
    local zones = {}
    for z = 1, ZONES do
        zones[z] = {name = zone_names[z], marker = zone_centers[z], needs = purse(0, 0, 0, zone_stars[z]), cost = purse(0, 0, 0, 0, zone_compasses[z])}
    end
    c.zones = zones
    c.buildable = function(_, p) return M.island_grass(p) end
    c.zone_at = function(_, p) return M.island_zone(p) end
    c.zone_touches = function(_, z, open) return M.island_zone_touches(z, open) end
    c.tile = M.TILE
    c.clearance = size2(1, 1)   -- half a tile of ground around every base
    c.fog = color(233, 242, 224, 240)
    c.fog_on_land_only = true
    c.path = color(222, 204, 151, 240)
    c.movable = true
    c.cam = camera{center = vec2(760, 2010), zoom = .65, min_zoom = .24, max_zoom = 1.05, world = size2(M.ISLAND_W, M.ISLAND_H)}
    c:init("island.jpg")
end

-- Build the next wonder at a free spot.
function M.island_place_next(c, wallet, built_limit, now)
    local nxt = M.wonder_count(c)
    if nxt >= WONDERS or nxt >= built_limit then return false end
    local ok, spot = c:find_spot(nxt, M.island_suggestion(nxt))
    if not ok then return false end
    c:begin_place(nxt, spot)
    if c:confirm(wallet, now).result == city.BUILT then return true end
    c:cancel()
    return false
end

return M
