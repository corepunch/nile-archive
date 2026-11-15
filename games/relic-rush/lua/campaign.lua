-- Campaign content only; all match mechanics live in engine/match3.lua.
local function level(name, lesson, moves, score, relics, chains, ice)
    return {name=name, lesson=lesson, moves=moves, score=score, relics=relics, chains=chains, ice=ice}
end

-- Masks are ordered by axial q, then r, exactly as the engine enumerates cells.
-- Terrain priorities trace an authored axial seam and then sweep along it.
-- Locks sample the first ranks as documented in
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
        local l = level("First Light", "Match 3 to collect timber.", 24, 1100, 10, 0, 0)
        l.mask = bowl_mask
        l.terrain = seam(1, 0, 0, 0, 1)
        l.ice_layers = 1
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("The Lamp Lens", "Match 4 for a rocket. Collect lenses.", 29, 1800, 10, 0, 0)
        l.mask = bowl_mask
        l.terrain = seam(0, 1, -1, 1, 0)
        l.ice_layers = 1
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("The Relay Cable", "Match beside stone to break it. Collect cable coils.", 32, 2300, 12, 0, 0)
        l.mask = chambers_mask
        l.terrain = seam(1, 1, 0, 1, 0)
        l.ice_layers = 1
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("Under the Pump", "Collect map pieces. Match a chained piece to free it.", 35, 2700, 15, 4, 0)
        l.mask = lanes_mask
        l.terrain = seam(1, 0, -1, 0, 1)
        l.ice_layers = 1
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("The Quay Marker", "Clear the blue plaques. Collect marker pieces.", 35, 3100, 14, 4, 0)
        l.mask = bowl_mask
        l.terrain = seam(0, 1, 0, 1, 0)
        l.ice_layers = 1
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("The Shore Marker", "Match the piece under the salt crust. Collect marker pieces.", 37, 3400, 14, 0, 5)
        l.mask = chambers_mask
        l.terrain = seam(1, 1, 1, -1, 0)
        l.ice_layers = 1
        l.background = 2
        return l
    end)(),
    (function()
        local l = level("The Tool Roll", "Collect tool rolls. Break stone to open more space.", 40, 3800, 16, 3, 4)
        l.mask = chambers_mask
        l.terrain = seam(0, 1, 0, 1, 0)
        l.ice_layers = 2
        l.background = 2
        return l
    end)(),
    (function()
        local l = level("The Broken Cable", "Collect snapped cable. Match 5 for a rainbow ball.", 40, 4200, 16, 4, 6)
        l.mask = compact_mask
        l.terrain = seam(0, 1, -1, -1, 0)
        l.ice_layers = 2
        l.background = 2
        return l
    end)(),
    (function()
        local l = level("The Supply Crate", "Collect supply packs.", 43, 4600, 18, 5, 6)
        l.mask = chambers_mask
        l.terrain = seam(1, 1, 0, 1, 0)
        l.ice_layers = 2
        l.background = 2
        return l
    end)(),
    (function()
        local l = level("The Shutter Gear", "Clear blue plaques and collect gears.", 46, 5000, 20, 6, 6)
        l.mask = lanes_mask
        l.terrain = seam(1, 0, 0, 0, -1)
        l.ice_layers = 2
        l.background = 2
        return l
    end)(),
    (function()
        local l = level("The Long Terrace", "Clear the blue plaques along the terrace.", 33, 2500, 12, 0, 0)
        l.mask = bowl_mask
        l.terrain = seam(0, 1, 1, 1, 0)
        l.ice_layers = 1
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("Twelve Crates", "Match through the vines to reach the blue plaques.", 36, 2900, 13, 5, 0)
        l.mask = lanes_mask
        l.terrain = seam(1, 1, -1, -1, 0)
        l.ice_layers = 1
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("Names in the Stone", "Clear blue plaques and collect folded notes.", 37, 3200, 14, 6, 0)
        l.mask = lanes_mask
        l.terrain = seam(1, 0, 0, 0, 1)
        l.ice_layers = 1
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("Static", "Clear blue plaques on both sides of the seam.", 38, 3500, 14, 7, 0)
        l.mask = chambers_mask
        l.terrain = seam(0, 1, 1, -1, 0)
        l.ice_layers = 1
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("The Frost Line", "Clear the blue plaques around the fallen wall.", 39, 3700, 15, 4, 6)
        l.mask = bowl_mask
        l.terrain = seam(1, 1, 0, 1, 0)
        l.ice_layers = 1
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("Supper for Twelve", "Hit the salt crust with matches or power-ups.", 40, 4000, 15, 4, 7)
        l.mask = lanes_mask
        l.terrain = seam(1, 0, -1, 0, -1)
        l.ice_layers = 2
        l.background = 2
        return l
    end)(),
    (function()
        local l = level("The Torn Log", "Thick salt crust takes two hits.", 42, 4200, 16, 5, 7)
        l.mask = bowl_mask
        l.terrain = seam(0, 1, -1, 1, 0)
        l.ice_layers = 2
        l.background = 2
        return l
    end)(),
    (function()
        local l = level("Lantern Steps", "Clear the blue plaques on the terrace.", 40, 3000, 12, 2, 4)
        l.mask = bowl_mask
        l.terrain = seam(1, 1, 1, -1, 0)
        l.ice_layers = 1
        l.background = 2
        return l
    end)(),
    (function()
        local l = level("Under the Vines", "Clear the blue plaques under the locks.", 45, 4600, 18, 4, 6)
        l.mask = lanes_mask
        l.terrain = seam(1, 0, 1, 0, 1)
        l.ice_layers = 2
        l.background = 2
        return l
    end)(),
    (function()
        local l = level("The Archivist's Key", "Clear the blue plaques beside the records.", 46, 5100, 20, 5, 7)
        l.mask = lanes_mask
        l.terrain = central_seam(0)
        l.ice_layers = 2
        l.background = 2
        return l
    end)(),
    (function()
        local l = level("Tomas's Trail", "Follow the buried seam.", 35, 2800, 12, 0, 0)
        l.mask = bowl_mask
        l.terrain = seam(1, 1, -1, 1, 0)
        l.ice_layers = 1
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("The Frozen Stair", "Break the ice to reach the blue plaques.", 40, 3400, 14, 2, 8)
        l.mask = lanes_mask
        l.terrain = seam(1, 0, -1, 0, 1)
        l.ice_layers = 2
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("The Star Road", "Choose a colour for the rainbow ball.", 40, 3700, 15, 3, 4)
        l.mask = lanes_mask
        l.terrain = seam(0, 1, 1, 1, 0)
        l.ice_layers = 1
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("Noon Shadow", "Clear the blue plaques in the shade.", 41, 3900, 16, 4, 5)
        l.mask = bowl_mask
        l.terrain = central_seam(1)
        l.ice_layers = 2
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("Smoke on the Water", "Clear the blue plaques along the quay.", 38, 4000, 16, 6, 6)
        l.mask = bowl_mask
        l.terrain = seam(1, 0, 0, 0, -1)
        l.ice_layers = 2
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("The Jade Deep", "Clear the blue plaques to open the water channel.", 43, 4300, 17, 4, 7)
        l.mask = lanes_mask
        l.terrain = central_seam(-1)
        l.ice_layers = 2
        l.background = 2
        return l
    end)(),
    (function()
        local l = level("Six Sun Gates", "Clear the six pairs of blue plaques.", 45, 4600, 18, 7, 8)
        l.mask = lanes_mask
        l.terrain = seam(1, 1, 0, 1, 0)
        l.ice_layers = 2
        l.background = 2
        return l
    end)(),
    (function()
        local l = level("The Last Terrace", "Clear the blue plaques on the terrace.", 42, 3200, 13, 2, 4)
        l.mask = bowl_mask
        l.terrain = seam(1, 0, 1, 0, -1)
        l.ice_layers = 1
        l.background = 2
        return l
    end)(),
    (function()
        local l = level("The Silent Temple", "Clear the blue plaques at the temple entrance.", 47, 5200, 20, 8, 10)
        l.mask = lanes_mask
        l.terrain = seam(0, 1, 0, 1, 0)
        l.ice_layers = 2
        l.background = 2
        return l
    end)(),
    (function()
        local l = level("The Warning Returns", "Uncover the final approach.", 49, 5500, 22, 8, 10)
        l.mask = bowl_mask
        l.terrain = seam(1, 1, 0, -1, 0)
        l.ice_layers = 2
        l.background = 2
        return l
    end)(),
}


-- Teach each new problem alone, then combine it with a familiar one.
levels[3].stones = {{cell=cell(2,0)}}
levels[3].lesson = "Match beside a stone to break it."
levels[7].stones = {{cell=cell(2,0)}}
levels[15].stones = {{cell=cell(0,0)}}
levels[21].deliveries = {tokens={cell(0,-2)},exits={cell(0,2)}}
levels[21].lesson = "Clear below the tablet to deliver it."
levels[22].stones = {{cell=cell(2,0)}}
levels[29].stones = {{cell=cell(2,0)}}

-- The first clear hands recovered quest objects to the story.
local quest_objects = {
    {key="timber", name="Camp timber"}, {key="lens", name="Lamp lens"},
    {key="cable", name="Relay cable"}, {key="chart", name="Tide chart"},
    {key="marker", name="Quay marker"}, {key="marker", name="Shore marker"},
    {key="tools", name="Tool roll"}, {key="broken-cable", name="Broken cable"},
    {key="supplies", name="Supply crate"}, {key="gear", name="Shutter gear"},
}
for i, object in ipairs(quest_objects) do levels[i].quest_object = object end
levels[13].quest_object = {key="note", name="Folded note"}
-- goal_kind is the slot the story piece replaces. Set omit_kind to leave
-- one other slot out of a board's opening and refills.
levels[1].story_piece, levels[1].goal_kind = "timber", 5 -- orange replaces the amphora
levels[1].omit_kind = 0                                -- no gold sun idols in the tutorial
levels[2].story_piece, levels[2].goal_kind = "lens", 3   -- blue replaces the scarab
levels[2].omit_kind = 5
levels[3].story_piece, levels[3].goal_kind = "cable", 4  -- purple replaces the crystal
levels[4].story_piece, levels[4].goal_kind = "chart", 0  -- gold replaces the sun idol
levels[5].story_piece, levels[5].goal_kind = "marker", 2 -- green replaces the leaf
levels[5].omit_kind = 5
levels[6].story_piece, levels[6].goal_kind = "marker", 2
levels[7].story_piece, levels[7].goal_kind = "tools", 1  -- red replaces the flame
levels[8].story_piece, levels[8].goal_kind = "broken-cable", 4 -- purple replaces the crystal
levels[8].omit_kind = 5
levels[9].story_piece, levels[9].goal_kind = "supplies", 3 -- blue replaces the scarab
levels[10].story_piece, levels[10].goal_kind = "gear", 5 -- orange replaces the amphora
levels[10].omit_kind = 0
levels[13].story_piece, levels[13].goal_kind = "note", 0 -- gold replaces the sun idol
levels[13].omit_kind = 5
levels[30].deliveries = {tokens={cell(1,-2)},exits={cell(1,2)},icon="signal-plate"}
levels[30].lesson = "Clear below the signal plate to deliver it."
levels[3].signal = "cliff"
levels[30].signal = "landing"
-- Clear the marked cells directly. A lock or cover on a plaque protects it.
-- Each patch names the part of the site the crew needs to uncover.
local plaques = {
    [5] = {cell(-2,1), cell(-1,0), cell(-1,1), cell(-1,2), cell(0,-1),
        cell(0,0), cell(0,1), cell(1,-1), cell(1,0), cell(2,0)},
    [10] = {cell(-3,1), cell(-3,2), cell(-3,3), cell(-2,0), cell(-2,1), cell(-2,2),
        cell(2,-2), cell(2,-1), cell(2,0), cell(2,1), cell(3,-2), cell(3,-1)},
    [11] = {cell(-3,2), cell(-2,1), cell(-2,2), cell(-1,0), cell(-1,1), cell(-1,2),
        cell(0,-1), cell(0,0), cell(0,1), cell(1,-2), cell(1,-1), cell(2,-2)},
    [12] = {cell(-4,1), cell(-4,2), cell(-4,3), cell(-3,0), cell(-3,1), cell(-3,2),
        cell(-3,3), cell(-2,-1), cell(-2,0), cell(-2,1), cell(-2,2), cell(-2,3)},
    [13] = {cell(-3,-1), cell(-3,0), cell(-3,1), cell(-2,-1), cell(-2,0),
        cell(1,-4), cell(1,-3), cell(2,-3), cell(2,-2), cell(3,-3)},
    [14] = {cell(-4,2), cell(-3,1), cell(-3,2), cell(-2,0), cell(-2,1), cell(-2,2),
        cell(2,-2), cell(2,-1), cell(2,0), cell(3,-2), cell(3,-1), cell(3,0), cell(4,-2)},
    [15] = {cell(-2,0), cell(-2,1), cell(-1,-1), cell(-1,0), cell(-1,1), cell(0,-2),
        cell(0,-1), cell(0,1), cell(1,-2), cell(1,-1), cell(1,0), cell(2,-1)},
    [16] = {cell(-4,1), cell(-4,2), cell(-3,0), cell(-3,1), cell(-3,2), cell(-2,-1), cell(-2,0),
        cell(2,-1), cell(2,0), cell(2,1), cell(3,-1), cell(3,0), cell(4,-1)},
    [17] = {cell(-2,2), cell(-1,1), cell(-1,2), cell(0,0), cell(0,1), cell(0,2),
        cell(1,-1), cell(1,0), cell(1,1), cell(2,-2), cell(2,-1), cell(2,0), cell(3,-1)},
    [18] = {cell(-3,2), cell(-2,2), cell(-2,3), cell(-1,1), cell(-1,2), cell(-1,3),
        cell(0,0), cell(0,1), cell(0,2), cell(1,-1), cell(1,0), cell(1,1), cell(2,-1), cell(2,0)},
    [19] = {cell(-4,2), cell(-4,3), cell(-4,4), cell(-3,1), cell(-3,2), cell(-3,3),
        cell(-3,4), cell(-2,0), cell(-2,1), cell(-2,2), cell(-2,3), cell(-1,3)},
    [20] = {cell(-4,1), cell(-4,2), cell(-4,3), cell(-3,0), cell(-3,1),
        cell(-3,2), cell(-3,3), cell(-2,0), cell(-2,1)},
    [22] = {cell(-3,0), cell(-3,1), cell(-3,2), cell(-2,-1), cell(-2,0), cell(-2,1),
        cell(-2,2), cell(-2,3), cell(2,-1), cell(2,0), cell(2,1), cell(3,-1), cell(3,0)},
    [23] = {cell(-4,1), cell(-4,2), cell(-3,1), cell(-3,2), cell(-2,1), cell(-2,2),
        cell(2,-3), cell(2,-2), cell(3,-3), cell(3,-2), cell(4,-3), cell(4,-2)},
    [24] = {cell(-2,1), cell(-1,0), cell(-1,1), cell(-1,2), cell(0,-1), cell(0,0),
        cell(0,1), cell(0,2), cell(1,0), cell(1,1), cell(1,2), cell(2,0)},
    [25] = {cell(-3,2), cell(-3,3), cell(-2,1), cell(-2,2), cell(-2,3), cell(-1,0),
        cell(-1,1), cell(-1,2), cell(0,-1), cell(0,0), cell(0,1), cell(1,-2), cell(1,-1), cell(2,-2)},
    [26] = {cell(2,-2), cell(2,-1), cell(2,0), cell(3,-4), cell(3,-3), cell(3,-2),
        cell(3,-1), cell(4,-4), cell(4,-3), cell(4,-2)},
    [27] = {cell(-4,1), cell(-3,0), cell(-3,2), cell(-2,2), cell(-3,4), cell(-2,3),
        cell(2,-4), cell(3,-4), cell(2,-2), cell(3,-2), cell(3,0), cell(4,-1)},
    [28] = {cell(-1,2), cell(-1,3), cell(0,1), cell(0,2), cell(0,3), cell(1,-3),
        cell(1,-2), cell(1,-1), cell(1,0), cell(1,1), cell(1,2), cell(2,0), cell(2,1)},
    [29] = {cell(-4,0), cell(-4,1), cell(-3,-1), cell(-3,0), cell(-3,1), cell(-2,-2),
        cell(-2,-1), cell(-2,0), cell(-1,-3), cell(-1,-2), cell(0,-4), cell(1,-4),
        cell(2,-4), cell(2,-3), cell(3,-4), cell(3,-3)},
}

-- Story materials are presentation only. The cover rules still use ice HP,
-- and locks, covers and stones still obstruct the cells behind them.
local locks = {
    [5]="creeper-vine", [7]="rope-lashing", [8]="cable-snarl", [9]="rope-lashing",
    [12]="creeper-vine", [13]="creeper-vine", [14]="rope-lashing", [15]="rope-lashing", [16]="rope-lashing",
    [22]="cable-snarl", [23]="cable-snarl", [24]="rope-lashing", [25]="rope-lashing", [26]="rope-lashing",
}
local covers = {
    [10]="barnacle-crust", [15]="wall-rubble", [22]="ice",
    [24]="barnacle-crust", [25]="barnacle-crust", [26]="barnacle-crust", [27]="wall-rubble",
}
for i, l in ipairs(levels) do
    local cells = plaques[i]
    l.oil, l.oil_still = cells, cells ~= nil
    l.dress = {lock=locks[i], cover=l.ice > 0 and (covers[i] or "salt-crust") or nil,
        floor={normal="sandstone-floor", covered=cells and "blue-plaque" or nil}}
    l.goals = {}
    if cells then l.goals[#l.goals+1] = "oil" end
    if l.story_piece then l.goals[#l.goals+1] = "idols" end
    if l.deliveries then l.goals[#l.goals+1] = "deliveries" end
    assert(#l.goals > 0, "each board needs a plaque, story or delivery goal")
end

-- Keep the one-cell central spine clear for swapping: the two openings are
-- passage, not unreachable mandatory cleanup. Locks can occupy the bridges.
for _, board in ipairs(levels) do
    if board.mask == lanes_mask then
        for r = -2, 2 do board.terrain[cell(0,r) + 1] = 10000000 + r end
    end
end

local shapes = {}
for i, l in ipairs(levels) do shapes[i] = l.name end

return {levels=levels, colors=6, shapes=shapes, wonder_levels={1,4,7,9,13,16,19,23,26,29}}
