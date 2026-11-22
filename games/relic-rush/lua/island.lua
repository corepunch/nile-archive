-- island.lua — the Lost Valley map: shoreline, six regions and the campaign ladder.
--
-- The island is an engine city. This file only knows the map: which world
-- points are lawn (an authored contour), which region owns them (a hidden
-- axial hex grid flood-filled from six region centres, so every region is one
-- connected patch) and which regions touch. Placement, unlocking, moving and
-- drawing are the engine's.
local M = {}
local journey = require("journey")
local economy = require("economy")

M.ISLAND_W, M.ISLAND_H, M.ISLAND_ZONES, M.WONDERS = 1920, 2880, 6, 10
local ZONES, WONDERS = M.ISLAND_ZONES, M.WONDERS

-- Ten restorations in campaign order. Each sprite's footprint is measured in
-- its own pixels (see docs/BUILDINGS.md): the ground centre it stands on
-- (pivot), the width from its left corner to its right one, and its size in
-- whole TILE tiles.
M.TILE = 56   -- a tile's side on the ground, in world units

-- The catalogue owns sprite registration, prices, descriptions and unlocks.
M.catalogue = require("buildings")
M.buildings, M.wonders = M.catalogue, {}
M.kinds = {}
-- Roads lead to buildings, and to any catalogue row marked road=true (big pieces
-- on a foundation); trees, statues, camp props and the rest are decorations.
local HOUSES = {wonder = true, building = true}
for i, d in ipairs(M.buildings) do
    d.decoration = not (HOUSES[d.category] or d.road)
    M.kinds[d.key] = i - 1
end
-- Two story restorations in each epoch of twenty expeditions (docs/story.md).
M.wonder_kinds = {M.kinds.well, M.kinds.camp, M.kinds.market, M.kinds.clock_tower,
    M.kinds.gateway, M.kinds.lodge, M.kinds.archive, M.kinds.lighthouse, M.kinds.temple, M.kinds.fountain}
local story_kind = {}
for i, kind in ipairs(M.wonder_kinds) do
    M.wonders[i] = M.buildings[kind + 1]
    story_kind[kind] = true
end

function M.wonder_count(c)
    local n=0
    for _,b in ipairs(c.items) do if story_kind[b.type] then n=n+1 end end
    -- Older campaigns could pass the cabin before it carried a story scene.
    if M.waived(c)[M.ladder_position[M.kinds.log_cabin]] and M.owned(c, M.kinds.log_cabin) == 0 then n = n + 1 end
    return n
end

function M.owned(c, kind)
    local n=0
    for _,b in ipairs(c.items) do if b.type==kind then n=n+1 end end
    return n
end

-- The twenty-step campaign ladder (economy.unlocks), after Cradle of Rome:
-- Each twenty-expedition epoch offers a choice among its four projects.
require("match3.game").campaign_ladder(M, economy.unlocks, journey, #economy.currencies, 20)
for _, entry in ipairs(economy.unlocks) do
    local unlock = economy.building_unlock_text(entry)
    if unlock then M.buildings[M.kinds[entry.building] + 1].unlock_text = "Unlocks " .. unlock end
end

local function scenery_building(kind)
    local item = M.catalogue[kind + 1]
    return item and HOUSES[item.category] and not M.ladder_position[kind]
end
for i = #M.catalogue_order, 1, -1 do
    local kind = M.catalogue_order[i] - 1
    if scenery_building(kind) then table.remove(M.catalogue_order, i) end
end

local can_buy = M.can_buy
function M.can_buy(c, wallet, level, kind)
    if scenery_building(kind) then return false end
    return can_buy(c, wallet, level, kind)
end

function M.migrate_wallet(progress, c)
    local wallet = progress.wallet
    local reserved = M.reserved_cost(c,progress.level)
    -- Legacy wood and stone both become construction supplies.
    wallet[economy.SUPPLIES] = math.max(reserved[economy.SUPPLIES], wallet[2] + wallet[3])
    wallet[economy.PROVISIONS] = reserved[economy.PROVISIONS]
    wallet[economy.GOLD] = math.max(wallet[economy.GOLD], reserved[economy.GOLD])
end

-- Pitch the crew's tent in the middle of the Harbor glade clearing.
-- It is free, movable scenery outside the campaign ladder.
function M.new_game(c, now)
    local tent = M.kinds.supply_tent
    local ok, spot = c:find_spot(tent, vec2(790, 1910))
    if ok then c:add(spot, tent, now) end
end

function M.restore_saved(c)
    -- Purchased decorations do not count toward campaign restoration progress.
    -- Discard the retired Quay Steps before checking the remaining footprints.
    -- Rehome saved buildings whose footprints no longer fit without charging again.
    local items,seen=c.items,{}
    local needs_relocation=false
    c.count=0
    for _,b in ipairs(items) do
        local valid=b.type ~= M.kinds.quay_steps and M.buildings[b.type+1] and (not story_kind[b.type] or not seen[b.type])
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

-- A ladder restoration is suggested beside the story restoration after it.
function M.island_suggestion(kind)
    if kind == M.kinds.well then return vec2(610, 1840) end   -- the old spring, but it may stand anywhere
    if kind == M.kinds.log_cabin then return vec2(875, 2050) end
    local site = M.buildings[kind + 1].fixed_site
    if site then return site end
    local n = M.ladder_position[kind]
    if n and kind >= WONDERS then
        for k = n, #M.ladder do
            if M.ladder[k].story then kind = M.ladder[k].kind; break end
        end
    end
    return suggestions[num.clampi(kind, 0, WONDERS - 1) + 1]
end

-- Map, zones, wonders and rules for an engine city.
function M.island_setup(c)
    c.defs = M.buildings
    local zones, levels = {}, #require("campaign").levels
    for z = 1, ZONES do
        zones[z] = {name = zone_names[z], marker = zone_centers[z], needs = purse(0, 0, 0, (z - 1) * levels // (ZONES - 1)), cost = purse()}
    end
    c.zones = zones
    c.buildable = function(_, p) return M.island_grass(p) end
    c.zone_at = function(_, p) return M.island_zone(p) end
    c.zone_touches = function(_, z, open) return M.island_zone_touches(z, open) end
    c.tile = M.TILE
    c.clearance = size2(1, 1)   -- half a tile of ground around every base
    c.fog = color(233, 242, 224, 240)
    c.fog_on_land_only = true
    c.fog_clouds = true
    c.movable = true
    c.cam = camera{center = vec2(760, 2010), zoom = .65, min_zoom = .24, max_zoom = 1.05, world = size2(M.ISLAND_W, M.ISLAND_H)}
    c:init("city/island.jpg")
    c.road = texture.load("city/roads.png")   -- tools/roads.py relic-rush
end

-- Build the next ladder restoration at a free spot.
function M.island_place_next(c, wallet, built_limit, now)
    local nxt = M.next_step(c, built_limit)
    if not nxt or not M.can_buy(c, wallet, built_limit, nxt) then return false end
    local ok, spot = c:find_spot(nxt, M.island_suggestion(nxt))
    if not ok then return false end
    c:begin_place(nxt, spot)
    if c:confirm(wallet, now).result == city.BUILT then
        return true
    end
    c:cancel()
    return false
end

return M
