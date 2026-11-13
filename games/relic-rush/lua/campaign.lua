-- Campaign content only; all match mechanics live in engine/match3.lua.
local function level(name, lesson, moves, score, relics, soil, chains, ice)
    return {name=name, lesson=lesson, moves=moves, score=score, relics=relics, soil=soil, chains=chains, ice=ice}
end

-- Masks are ordered by axial q, then r, exactly as the engine enumerates cells.
-- Terrain priorities trace an authored axial seam and then sweep along it.
-- Soil uses the first ranks; locks sample those ranks as documented in
-- docs/board-progression.md. The priority values are unique, including ties.
local function seam(a, b, offset, c, d)
    local ranks, i = {}, 0
    for q = -4, 4 do
        for r = math.max(-4, -q - 4), math.min(4, -q + 4) do
            i = i + 1
            ranks[i] = math.abs(a * q + b * r - offset) * 10000
                + (c * q + d * r + 8) * 100 + i
        end
    end
    return ranks
end

-- Prioritise the centre of the horizontal seam to avoid leaving its distant ends as cleanup.
local function central_seam(offset)
    local ranks, i = {}, 0
    for q = -4, 4 do
        for r = math.max(-4, -q - 4), math.min(4, -q + 4) do
            i = i + 1
            ranks[i] = math.abs(r - offset) * 1000 + math.abs(q) * 1500 + i
        end
    end
    return ranks
end

-- Authored axial positions, converted to the engine's zero-based cell IDs.
local function cell(q, r)
    local i = 0
    for x = -4, 4 do
        for y = math.max(-4, -x - 4), math.min(4, -x + 4) do
            if x == q and y == r then return i end
            i = i + 1
        end
    end
    error("invalid campaign coordinate")
end

-- Deliberate repeated silhouettes: two cut lanes, a tapered court, and
-- two chambers joined by an end bridge.
local lanes_mask = "1111111111111111111100001111111111111000011111111111111111111"
local bowl_mask = "0111100111100111111111111111111111111111111001111100111101111"
local chambers_mask = "1111111111111111111100000011000000011000000111111111111111111"

-- Compact radius-three court, offset to suit each game.
local compact_mask = "1111011111011111101111111001111110001111100011110000000000000"

local levels = {
    (function()
        local l = level("First Light", "Match 3 in a row.", 24, 1100, 8, 0, 0, 0)
        l.mask = bowl_mask
        l.terrain = seam(1, 0, 0, 0, 1)
        l.ice_layers = 1
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("The Lamp Lens", "Match 4 for a sun ray.", 29, 1800, 10, 7, 0, 0)
        l.mask = bowl_mask
        l.terrain = seam(0, 1, -1, 1, 0)
        l.ice_layers = 1
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("The Buried Cable", "Dig along the seam.", 32, 2300, 12, 12, 0, 0)
        l.mask = chambers_mask
        l.terrain = seam(1, 1, 0, 1, 0)
        l.ice_layers = 1
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("Under the Pump", "Match to break chains.", 35, 2700, 12, 10, 4, 0)
        l.mask = lanes_mask
        l.terrain = seam(1, 0, -1, 0, 1)
        l.ice_layers = 1
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("The Quay Marker", "Rays cross gaps.", 35, 3100, 14, 13, 4, 0)
        l.mask = bowl_mask
        l.terrain = seam(0, 1, 0, 1, 0)
        l.ice_layers = 1
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("The Shore Marker", "Match to break ice.", 37, 3400, 14, 13, 0, 5)
        l.mask = chambers_mask
        l.terrain = seam(1, 1, 1, -1, 0)
        l.ice_layers = 1
        l.background = 2
        return l
    end)(),
    (function()
        local l = level("The Tool Roll", "Hit frozen pieces with matches or power-ups.", 40, 3800, 16, 12, 3, 4)
        l.mask = chambers_mask
        l.terrain = seam(0, 1, 0, 1, 0)
        l.ice_layers = 2
        l.background = 2
        return l
    end)(),
    (function()
        local l = level("The Broken Cable", "Match 5 for a prism.", 40, 4200, 16, 17, 4, 6)
        l.mask = compact_mask
        l.terrain = seam(0, 1, -1, -1, 0)
        l.ice_layers = 2
        l.background = 2
        return l
    end)(),
    (function()
        local l = level("The Supply Crate", "Use rays across the seal.", 43, 4600, 18, 19, 5, 6)
        l.mask = chambers_mask
        l.terrain = seam(1, 1, 0, 1, 0)
        l.ice_layers = 2
        l.background = 2
        return l
    end)(),
    (function()
        local l = level("The Shutter Crank", "Uncover the buried centre.", 46, 5000, 20, 22, 6, 6)
        l.mask = lanes_mask
        l.terrain = seam(1, 0, 0, 0, -1)
        l.ice_layers = 2
        l.background = 2
        return l
    end)(),
    (function()
        local l = level("The Long Terrace", "Dig the long terrace.", 33, 2500, 12, 14, 0, 0)
        l.mask = bowl_mask
        l.terrain = seam(0, 1, 1, 1, 0)
        l.ice_layers = 1
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("Twelve Crates", "Free chained relics.", 36, 2900, 13, 15, 5, 0)
        l.mask = lanes_mask
        l.terrain = seam(1, 1, -1, -1, 0)
        l.ice_layers = 1
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("Names in the Stone", "Aim rays along the stone.", 37, 3200, 14, 16, 6, 0)
        l.mask = lanes_mask
        l.terrain = seam(1, 0, 0, 0, 1)
        l.ice_layers = 1
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("Static", "Work around the broken seam.", 38, 3500, 14, 17, 7, 0)
        l.mask = chambers_mask
        l.terrain = seam(0, 1, 1, -1, 0)
        l.ice_layers = 1
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("The Frost Line", "Clear chains and ice.", 39, 3700, 15, 18, 4, 6)
        l.mask = bowl_mask
        l.terrain = seam(1, 1, 0, 1, 0)
        l.ice_layers = 1
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("Supper for Twelve", "Hit frozen pieces with matches or power-ups.", 40, 4000, 15, 18, 4, 7)
        l.mask = lanes_mask
        l.terrain = seam(1, 0, -1, 0, -1)
        l.ice_layers = 2
        l.background = 2
        return l
    end)(),
    (function()
        local l = level("The Torn Log", "Some ice takes two hits.", 42, 4200, 16, 19, 5, 7)
        l.mask = bowl_mask
        l.terrain = seam(0, 1, -1, 1, 0)
        l.ice_layers = 2
        l.background = 2
        return l
    end)(),
    (function()
        local l = level("Lantern Steps", "Clear the open terrace.", 40, 3000, 12, 12, 2, 4)
        l.mask = bowl_mask
        l.terrain = seam(1, 1, 1, -1, 0)
        l.ice_layers = 1
        l.background = 2
        return l
    end)(),
    (function()
        local l = level("Under the Vines", "Dig beneath the locks.", 45, 4600, 18, 15, 4, 6)
        l.mask = lanes_mask
        l.terrain = seam(1, 0, 1, 0, 1)
        l.ice_layers = 2
        l.background = 2
        return l
    end)(),
    (function()
        local l = level("The Archivist's Key", "Open the central approach.", 46, 5100, 20, 18, 5, 7)
        l.mask = lanes_mask
        l.terrain = central_seam(0)
        l.ice_layers = 2
        l.background = 2
        return l
    end)(),
    (function()
        local l = level("Tomas's Trail", "Follow the buried seam.", 35, 2800, 12, 15, 0, 0)
        l.mask = bowl_mask
        l.terrain = seam(1, 1, -1, 1, 0)
        l.ice_layers = 1
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("The Frozen Stair", "Thaw the frozen approach.", 40, 3400, 14, 16, 2, 8)
        l.mask = lanes_mask
        l.terrain = seam(1, 0, -1, 0, 1)
        l.ice_layers = 2
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("The Star Road", "Choose a colour for the prism.", 40, 3700, 15, 12, 3, 4)
        l.mask = lanes_mask
        l.terrain = seam(0, 1, 1, 1, 0)
        l.ice_layers = 1
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("Noon Shadow", "Excavate across the shadow.", 41, 3900, 16, 20, 4, 5)
        l.mask = bowl_mask
        l.terrain = central_seam(1)
        l.ice_layers = 2
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("Smoke on the Water", "Work through the locks.", 38, 4000, 16, 18, 6, 6)
        l.mask = bowl_mask
        l.terrain = seam(1, 0, 0, 0, -1)
        l.ice_layers = 2
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("The Jade Deep", "Thaw the buried ground.", 43, 4300, 17, 17, 4, 7)
        l.mask = lanes_mask
        l.terrain = central_seam(-1)
        l.ice_layers = 2
        l.background = 2
        return l
    end)(),
    (function()
        local l = level("Six Sun Gates", "Clear the scattered locks.", 45, 4600, 18, 20, 7, 8)
        l.mask = lanes_mask
        l.terrain = seam(1, 1, 0, 1, 0)
        l.ice_layers = 2
        l.background = 2
        return l
    end)(),
    (function()
        local l = level("The Last Terrace", "Clear the open terrace.", 42, 3200, 13, 13, 2, 4)
        l.mask = bowl_mask
        l.terrain = seam(1, 0, 1, 0, -1)
        l.ice_layers = 1
        l.background = 2
        return l
    end)(),
    (function()
        local l = level("The Silent Temple", "Dig through the temple floor.", 47, 5200, 20, 23, 8, 10)
        l.mask = lanes_mask
        l.terrain = seam(0, 1, 0, 1, 0)
        l.ice_layers = 2
        l.background = 2
        return l
    end)(),
    (function()
        local l = level("The Warning Returns", "Uncover the final approach.", 49, 5500, 22, 24, 8, 10)
        l.mask = bowl_mask
        l.terrain = seam(1, 1, 0, -1, 0)
        l.ice_layers = 2
        l.background = 2
        return l
    end)(),
}


-- Teach each new problem alone, then combine it with a familiar one.
levels[3].stones = {{cell=cell(2,0),hp=1}}
levels[3].lesson = "Match beside the stone to break it."
levels[7].stones = {{cell=cell(2,0),hp=2}}
levels[7].lesson = "Some stones need two hits."
levels[9].crates = {{cell=cell(2,0),hp=1,kind=0}}
levels[9].lesson = "Match the seal's colour beside it."
levels[11].tunnels = {{entrance=cell(0,-2),exit=cell(1,1)}}
levels[11].lesson = "Pieces travel between paired conduits."
levels[12].crates = {{cell=cell(2,0),hp=1,kind=1}}
levels[14].crates = {{cell=cell(2,0),hp=1,kind=2}}
levels[15].stones = {{cell=cell(0,0),hp=3}}
levels[15].lesson = "Break the three-layer stone."
levels[16].hazards = {cell(2,0)}
levels[16].lesson = "Stop the vines before they spread."
levels[17].crates = {{cell=cell(2,0),hp=2,kind=3}}
levels[17].lesson = "Some coloured seals take two hits."
levels[19].hazards = {cell(2,0)}
levels[21].deliveries = {tokens={cell(0,-2)},exits={cell(0,2)}}
levels[21].lesson = "Clear below the tablet to deliver it."
levels[22].stones = {{cell=cell(2,0),hp=2}}
levels[23].crates = {{cell=cell(2,0),hp=1,kind=4}}
levels[24].tunnels = {{entrance=cell(0,-2),exit=cell(1,1)}}
levels[25].hazards = {cell(2,0)}
levels[27].crates = {{cell=cell(2,0),hp=2,kind=5}}
levels[29].stones = {{cell=cell(2,0),hp=3}}
levels[30].tunnels = {{entrance=cell(1,-1),exit=cell(1,1)}}

-- Quest objects belong to the story after the first clear, not to the board goals.
local quest_objects = {
    {key="timber", name="Camp timber"}, {key="lens", name="Lamp lens"},
    {key="cable", name="Relay cable"}, {key="chart", name="Tide chart"},
    {key="marker", name="Quay marker"}, {key="marker", name="Shore marker"},
    {key="tools", name="Tool roll"}, {key="cable", name="Broken cable"},
    {key="supplies", name="Supply crate"}, {key="crank", name="Shutter crank"},
}
for i, object in ipairs(quest_objects) do levels[i].quest_object = object end
levels[30].deliveries = {tokens={cell(1,-2)},exits={cell(1,2)}}
levels[30].lesson = "Send the tablet through the conduit."
-- Moss (Homescapes' carpet): matches touching it spread it.
levels[18].carpet = {cell(-1,0), cell(0,0)}
levels[18].lesson = "Match on the moss to spread it."
levels[24].carpet = {cell(2,-1), cell(3,-1)}
levels[28].carpet = {cell(0,-1), cell(0,0)}
-- Lamp oil (Homescapes' oil): clear it by matching on it; it spreads after any
-- turn that clears none of it.
levels[20].oil = {cell(-4,1), cell(-4,2), cell(-4,3), cell(-3,1), cell(-3,2), cell(-3,3)}
levels[20].lesson = "Mop up the lamp oil before it spreads."
levels[26].oil = {cell(3,-4), cell(3,-3), cell(3,-2), cell(4,-4), cell(4,-3), cell(4,-2)}

-- Goals, as in Homescapes: one to three per level, never score (points only
-- rank a clear). The early levels ask for at most two, led by the lesson.
-- "idols" are relics, "sand" is dig sites, "locks" counts every blocker:
-- chains, ice, stones, seals and vines; "carpet" counts the cells the moss
-- has yet to cover; "oil" counts the lamp oil left on the board.
local goals = {
    {"idols"}, {"idols", "sand"}, {"locks", "sand"}, {"locks", "idols"}, {"idols", "sand"},
    {"locks", "sand"}, {"locks", "idols"}, {"idols", "sand"}, {"locks", "sand"}, {"sand", "locks"},
    {"idols", "sand"}, {"locks", "idols"}, {"locks", "sand"}, {"locks", "idols"}, {"locks", "sand"},
    {"locks", "idols"}, {"locks", "sand"}, {"carpet"}, {"sand", "locks", "idols"}, {"oil", "locks"},
    {"deliveries", "sand"}, {"locks", "sand"}, {"idols", "locks"}, {"carpet", "sand"}, {"locks", "sand"},
    {"oil", "locks", "sand"}, {"locks", "idols"}, {"carpet", "sand"}, {"sand", "locks", "idols"}, {"deliveries", "sand", "locks"},
}
assert(#goals == #levels, "one goal list per level")
for i, board in ipairs(levels) do board.goals = goals[i] end

-- Keep the one-cell central spine clear for swapping: the two openings are
-- passage, not unreachable mandatory cleanup. Locks can occupy the bridges.
for _, board in ipairs(levels) do
    if board.mask == lanes_mask then
        for r = -2, 2 do board.terrain[cell(0,r) + 1] = 10000000 + r end
    end
end

local shapes = {}
for i, l in ipairs(levels) do shapes[i] = l.name end

return {levels=levels, shapes=shapes, wonder_levels={1,4,7,9,13,16,19,23,26,29}}
