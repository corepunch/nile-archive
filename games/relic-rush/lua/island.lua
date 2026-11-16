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
-- Roads lead to buildings, and to any catalogue row marked road=true (big pieces
-- on a foundation); trees, statues, camp props and the rest are decorations.
local HOUSES = {wonder = true, building = true}
for _, d in ipairs(M.buildings) do d.decoration = not (HOUSES[d.category] or d.road) end
for i = 1, WONDERS do M.wonders[i] = M.buildings[i] end

-- The campaign ladder (economy.unlocks): twenty catalogue types in purchase
-- order. The ten story restorations are types 0-9 and keep the journey's
-- schedule; the other ten are placed in order between them. A save that
-- predates the ladder waives the ones it had already passed: those stay
-- optional and never block.
M.ladder, M.ladder_position = {}, {}
do
    local type_of = {}
    for i, d in ipairs(M.buildings) do type_of[d.key] = i - 1 end
    for n, unlock in ipairs(economy.unlocks) do
        local kind = assert(type_of[unlock.building], unlock.building)
        local story = kind < WONDERS
        assert(not story or unlock.after == journey.wonder_levels[kind + 1], unlock.building .. " follows the story schedule")
        M.ladder[n] = {kind=kind, unlock=unlock, after=unlock.after, story=story}
        M.ladder_position[kind] = n
        M.buildings[kind + 1].unlock_text = "Unlocks " .. economy.building_unlock_text(unlock)
    end
end

-- The shop lists the ladder in purchase order, then everything else.
M.catalogue_order = {}
for _, step in ipairs(M.ladder) do M.catalogue_order[#M.catalogue_order + 1] = step.kind + 1 end
for i in ipairs(M.buildings) do
    if not M.ladder_position[i - 1] then M.catalogue_order[#M.catalogue_order + 1] = i end
end

-- Waived ladder positions, {[position]=true}, per city (a city takes no new fields).
local waivers = setmetatable({}, {__mode = "k"})
local function waived(c, n) return waivers[c] and waivers[c][n] end
function M.waived(c) return waivers[c] or {} end
function M.set_waived(c, positions) waivers[c] = positions end

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

-- The next ladder restoration to place and its position. The type is nil
-- while that one waits for a later clear.
function M.next_step(c, level)
    for n, step in ipairs(M.ladder) do
        if not waived(c, n) and M.owned(c, step.kind) == 0 then
            if step.after <= level then return step.kind, n end
            return nil, n
        end
    end
end

function M.next_build(c, level) return M.next_step(c, level) or M.wonder_count(c) end

-- Why a ladder restoration cannot be placed now: "built", "later" (with the
-- clear it waits for) or "earlier" (another comes first). False when it can,
-- nil for shop items.
function M.ladder_blocked(c, level, kind)
    local n = M.ladder_position[kind]
    if not n then return nil end
    local step = M.ladder[n]
    if M.owned(c, kind) > 0 then return "built" end
    if step.after > level then return "later", step.after end
    if not waived(c, n) and M.next_step(c, level) ~= kind then return "earlier" end
    return false
end

-- Ladder positions the story requires by `level`: everything up to the
-- latest restoration it has earned.
local function required_through(level)
    local earned, last = journey.earned(level), 0
    for n, step in ipairs(M.ladder) do
        if step.story and step.kind < earned then last = n end
    end
    return last
end

function M.campaign_count(c)
    local n=0
    for _,b in ipairs(c.items) do if M.ladder_position[b.type] then n=n+1 end end
    return n
end

function M.happiness_points(kind) return M.ladder_position[kind] and 4 or 1 end

function M.happiness(c)
    local points = 0
    for _, item in ipairs(c.items) do points = points + M.happiness_points(item.type) end
    return points
end

function M.happiness_gold(c)
    return c and math.min(10, #c.items - M.campaign_count(c)) or 0
end

function M.can_buy(c, wallet, level, kind)
    if kind<0 or kind>=#M.buildings or c.count>=160 then return false end
    local d=M.buildings[kind+1]
    local blocked = M.ladder_blocked(c, level, kind)
    if blocked then return false end
    if blocked == nil and not M.can_spend(c,wallet,level,d.cost) then return false end
    if not wallet:covers(d.needs) or not wallet:covers(d.cost) then return false end
    return true
end

-- Keep the restorations the story requires affordable in the finite campaign economy.
function M.reserved_cost(c, level)
    local cost=purse()
    for n=1,required_through(level) do
        local step = M.ladder[n]
        if not waived(c, n) and M.owned(c,step.kind)==0 then cost=cost+M.buildings[step.kind+1].cost end
    end
    return cost
end

function M.can_spend(c, wallet, level, cost)
    local reserved = M.reserved_cost(c,level)
    for slot in ipairs(economy.currencies) do
        if cost[slot] > 0 and wallet[slot] - reserved[slot] < cost[slot] then return false end
    end
    return true
end

-- A save from before the ladder waives the new restorations it had passed:
-- those before the latest story restoration it has earned.
function M.waive_passed(c, level)
    local positions = waivers[c] or {}
    for n = 1, required_through(level) do
        local step = M.ladder[n]
        if not step.story and M.owned(c, step.kind) == 0 then positions[n] = true end
    end
    waivers[c] = positions
end

function M.migrate_wallet(progress, c)
    local wallet = progress.wallet
    local reserved = M.reserved_cost(c,progress.level)
    -- Legacy wood and stone both become construction supplies.
    wallet[economy.SUPPLIES] = math.max(reserved[economy.SUPPLIES], wallet[2] + wallet[3])
    wallet[economy.PROVISIONS] = reserved[economy.PROVISIONS]
    wallet[economy.GOLD] = math.max(wallet[economy.GOLD], reserved[economy.GOLD])
end

function M.restore_saved(c,level)
    -- Purchased decorations do not count toward campaign restoration progress.
    -- Rehome saved buildings whose footprints no longer fit without charging again.
    local items,seen=c.items,{}
    local needs_relocation=false
    c.count=0
    for _,b in ipairs(items) do
        local valid=b.type>=WONDERS or (b.type>=0 and not seen[b.type])
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
local zone_stars = {0, 18, 27, 45, 63, 81}
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
    local zones = {}
    for z = 1, ZONES do
        zones[z] = {name = zone_names[z], marker = zone_centers[z], needs = purse(0, 0, 0, zone_stars[z]), cost = purse()}
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
    c:init("island.jpg")
    c.road = texture.load("roads.png")   -- tools/roads.py relic-rush
end

-- Build the next ladder restoration at a free spot.
function M.island_place_next(c, wallet, built_limit, now)
    local nxt = M.next_step(c, built_limit)
    if not nxt then return false end
    local ok, spot = c:find_spot(nxt, M.island_suggestion(nxt))
    if not ok then return false end
    c:begin_place(nxt, spot)
    if c:confirm(wallet, now).result == city.BUILT then return true end
    c:cancel()
    return false
end

return M
