-- Campaign content only; all match mechanics live in engine/match3.lua.
local function level(name, moves, chains)
    return {name=name, lesson="Clear every blue plaque.", moves=moves, score=0, relics=0, chains=chains, ice=0}
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
        local l = level("First Light", 24, 0)
        l.mask = bowl_mask
        l.terrain = seam(1, 0, 0, 0, 1)
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("The Lamp Lens", 29, 0)
        l.mask = bowl_mask
        l.terrain = seam(0, 1, -1, 1, 0)
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("The Relay Cable", 32, 0)
        l.mask = chambers_mask
        l.terrain = seam(1, 1, 0, 1, 0)
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("Under the Pump", 35, 4)
        l.mask = lanes_mask
        l.terrain = seam(1, 0, -1, 0, 1)
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("The Quay Marker", 35, 4)
        l.mask = bowl_mask
        l.terrain = seam(0, 1, 0, 1, 0)
        l.background = 1
        -- The first idle hint makes a water match across three plaques.
        l.opening = ".1302" .. "..3413" .. "..24042" .. "00423323" .. "232033032"
            .. "24304010" .. "..42230" .. "..3113" .. ".2343"
        return l
    end)(),
    (function()
        local l = level("The Shore Marker", 37, 0)
        l.mask = chambers_mask
        l.terrain = seam(1, 1, 1, -1, 0)
        l.background = 2
        return l
    end)(),
    (function()
        local l = level("The Tool Roll", 40, 3)
        l.mask = chambers_mask
        l.terrain = seam(0, 1, 0, 1, 0)
        l.background = 2
        return l
    end)(),
    (function()
        local l = level("The Broken Cable", 40, 4)
        l.mask = compact_mask
        l.terrain = seam(0, 1, -1, -1, 0)
        l.background = 2
        return l
    end)(),
    (function()
        local l = level("The Supply Crate", 43, 5)
        l.mask = chambers_mask
        l.terrain = seam(1, 1, 0, 1, 0)
        l.background = 2
        -- Put a cut-block match in the first hint while leaving the crate to find.
        l.opening = "31355" .. "440543" .. "5424340" .. "32......" .. "55......."
            .. "15......" .. "0014105" .. "454204" .. "05142"
        l.featured_resource = "cut-blocks"
        return l
    end)(),
    (function()
        local l = level("The Shutter Gear", 46, 6)
        l.mask = lanes_mask
        l.terrain = seam(1, 0, 0, 0, -1)
        l.background = 2
        return l
    end)(),
    (function()
        local l = level("The Long Terrace", 33, 0)
        l.mask = bowl_mask
        l.terrain = seam(0, 1, 1, 1, 0)
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("Twelve Crates", 36, 5)
        l.mask = lanes_mask
        l.terrain = seam(1, 1, -1, -1, 0)
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("Names in the Stone", 37, 6)
        l.mask = lanes_mask
        l.terrain = seam(1, 0, 0, 0, 1)
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("Static", 38, 7)
        l.mask = chambers_mask
        l.terrain = seam(0, 1, 1, -1, 0)
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("The Cracked Wall", 39, 4)
        l.mask = bowl_mask
        l.terrain = seam(1, 1, 0, 1, 0)
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("Supper for Twelve", 40, 4)
        l.mask = lanes_mask
        l.terrain = seam(1, 0, -1, 0, -1)
        l.background = 2
        return l
    end)(),
    (function()
        local l = level("The Torn Log", 42, 5)
        l.mask = bowl_mask
        l.terrain = seam(0, 1, -1, 1, 0)
        l.background = 2
        return l
    end)(),
    (function()
        local l = level("Lantern Steps", 40, 2)
        l.mask = bowl_mask
        l.terrain = seam(1, 1, 1, -1, 0)
        l.background = 2
        return l
    end)(),
    (function()
        local l = level("Under the Vines", 45, 4)
        l.mask = lanes_mask
        l.terrain = seam(1, 0, 1, 0, 1)
        l.background = 2
        return l
    end)(),
    (function()
        local l = level("The Archivist's Key", 46, 5)
        l.mask = lanes_mask
        l.terrain = central_seam(0)
        l.background = 2
        return l
    end)(),
    (function()
        local l = level("Tomas's Trail", 35, 0)
        l.mask = bowl_mask
        l.terrain = seam(1, 1, -1, 1, 0)
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("The Alternate Landing", 40, 2)
        l.mask = lanes_mask
        l.terrain = seam(1, 0, -1, 0, 1)
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("The Star Road", 40, 3)
        l.mask = lanes_mask
        l.terrain = seam(0, 1, 1, 1, 0)
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("Noon Shadow", 41, 4)
        l.mask = bowl_mask
        l.terrain = central_seam(1)
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("Smoke on the Water", 38, 6)
        l.mask = bowl_mask
        l.terrain = seam(1, 0, 0, 0, -1)
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("The Jade Deep", 43, 4)
        l.mask = lanes_mask
        l.terrain = central_seam(-1)
        l.background = 2
        return l
    end)(),
    (function()
        local l = level("Six Sun Gates", 45, 7)
        l.mask = lanes_mask
        l.terrain = seam(1, 1, 0, 1, 0)
        l.background = 2
        return l
    end)(),
    (function()
        local l = level("The Last Terrace", 42, 2)
        l.mask = bowl_mask
        l.terrain = seam(1, 0, 1, 0, -1)
        l.background = 2
        return l
    end)(),
    (function()
        local l = level("The Silent Temple", 47, 8)
        l.mask = lanes_mask
        l.terrain = seam(0, 1, 0, 1, 0)
        l.background = 2
        return l
    end)(),
    (function()
        local l = level("The Warning Returns", 49, 8)
        l.mask = bowl_mask
        l.terrain = seam(1, 1, 0, -1, 0)
        l.background = 2
        return l
    end)(),
}


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
-- goal_kind registers the slot the story piece replaces. Set omit_kind to leave
-- one other slot out of a board's opening and refills.
levels[1].goal_kind, levels[1].omit_kind = 3, 5         -- ordinary timber in a five-resource palette
levels[2].story_piece, levels[2].goal_kind = "lens", 3   -- blue replaces the scarab
levels[2].omit_kind = 5
levels[3].story_piece, levels[3].goal_kind = "cable", 4  -- purple replaces the crystal
levels[4].story_piece, levels[4].goal_kind = "chart", 0  -- gold replaces the sun idol
levels[5].story_piece, levels[5].goal_kind = "marker", 2 -- green replaces the leaf
levels[5].omit_kind = 5
levels[6].story_piece, levels[6].goal_kind = "marker", 2
levels[7].story_piece, levels[7].goal_kind = "tools", 1  -- red replaces the flame
-- Keep the workshop's purple slot available on the expedition right after the build.
levels[8].story_piece, levels[8].goal_kind = "broken-cable", 5
levels[8].omit_kind = 1
levels[9].story_piece, levels[9].goal_kind = "supplies", 3 -- blue replaces the scarab
levels[10].story_piece, levels[10].goal_kind = "gear", 5 -- orange replaces the amphora
levels[10].omit_kind = 0
levels[13].story_piece, levels[13].goal_kind = "note", 0 -- gold replaces the sun idol
levels[13].omit_kind = 5
-- Score pieces occupy existing palette slots. Level 6 has both kinds,
-- with the restored Well supplying Food on that expedition.
levels[3].score_pieces = {[5]="leaf"}
levels[4].score_pieces = {[5]="flower"}
levels[6].score_pieces = {[1]="flower", [5]="leaf"}
levels[7].score_pieces = {[5]="flower"}
levels[9].score_pieces = {[5]="leaf"}
for _, i in ipairs{12,18,24} do levels[i].score_pieces = {[2]="leaf"} end
for _, i in ipairs{15,21,27} do levels[i].score_pieces = {[2]="flower"} end
levels[3].signal = "cliff"
levels[30].signal = "landing"
levels[30].signal_cell = cell(1,2)
-- Clear the marked cells directly. A chain on a plaque protects it.
-- Each patch names the part of the site the crew needs to uncover.
local plaques = {
    [1] = {cell(-1,0), cell(-1,1), cell(0,-1), cell(0,0), cell(0,1), cell(1,-1), cell(1,0)},
    [2] = {cell(-2,1), cell(-1,0), cell(-1,1), cell(0,-1), cell(0,0),
        cell(0,1), cell(1,-2), cell(1,-1), cell(2,-2)},
    [3] = {cell(-3,0), cell(-3,1), cell(-2,-1), cell(-2,0), cell(-2,1),
        cell(2,-2), cell(2,-1), cell(3,-2), cell(3,-1), cell(3,0)},
    [4] = {cell(-3,0), cell(-3,1), cell(-3,2), cell(-2,-1), cell(-2,0), cell(-2,1),
        cell(2,-2), cell(2,-1), cell(2,0), cell(3,-2), cell(3,-1)},
    [5] = {cell(-2,1), cell(-1,0), cell(-1,1), cell(-1,2), cell(0,-1),
        cell(0,0), cell(0,1), cell(1,-1), cell(1,0), cell(2,0)},
    [6] = {cell(-3,0), cell(-3,1), cell(-2,-1), cell(-2,0), cell(-2,1),
        cell(2,-2), cell(2,-1), cell(2,0), cell(3,-2), cell(3,-1), cell(3,0)},
    [7] = {cell(-3,-1), cell(-3,0), cell(-3,1), cell(-2,-1), cell(-2,0), cell(-2,1),
        cell(2,-2), cell(2,-1), cell(2,1), cell(3,-2), cell(3,-1), cell(3,0)},
    [8] = {cell(-2,0), cell(-2,1), cell(-1,-1), cell(-1,0), cell(-1,1), cell(0,-2),
        cell(0,-1), cell(0,0), cell(0,1), cell(1,-2), cell(1,-1), cell(1,0)},
    [9] = {cell(-3,0), cell(-3,1), cell(-3,2), cell(-2,-1), cell(-2,0), cell(-2,1),
        cell(2,-3), cell(2,-2), cell(2,-1), cell(3,-3), cell(3,-2), cell(3,-1)},
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
    [21] = {cell(-2,2), cell(-1,1), cell(-1,2), cell(-1,3), cell(0,-2), cell(0,-1),
        cell(0,0), cell(0,1), cell(0,2), cell(1,-3), cell(1,-2), cell(1,-1)},
    [22] = {cell(-3,0), cell(-3,1), cell(-3,2), cell(-2,-1), cell(-2,0), cell(-2,1),
        cell(-2,2), cell(-2,3), cell(2,-2), cell(2,-1), cell(2,1), cell(3,-1), cell(3,0)},
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
    [30] = {cell(-1,0), cell(-1,1), cell(-1,2), cell(0,-1), cell(0,0), cell(0,1),
        cell(0,2), cell(1,-2), cell(1,-1), cell(1,0), cell(1,1), cell(1,2),
        cell(2,-1), cell(2,0), cell(2,1), cell(2,2)},
}

local dress = {floor={normal="tile-cell-normal", covered="tile-tablet-single"}}
for i, l in ipairs(levels) do
    local cells = plaques[i]
    assert(cells and #cells > 0, "expedition " .. i .. " needs an authored plaque patch")
    if not l.story_piece then l.omit_kind = 5 end
    l.oil, l.oil_still = cells, true
    l.dress = dress
    l.goals = {"oil"}
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
