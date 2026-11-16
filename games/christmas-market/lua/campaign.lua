-- Each wish has a fixed set of panes. Only those panes need clearing.
-- Axial coordinates follow the engine's zero-based cell IDs.
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

local function level(name, moves, chains, mask, positions)
    local oil, floor_marks, terrain = {}, {}, {}
    for i = 1, #mask do terrain[i] = i end
    for _, pos in ipairs(positions) do
        local i = cell(pos[1], pos[2])
        assert(mask:sub(i + 1, i + 1) == "1" and not floor_marks[i], "invalid blue pane")
        oil[#oil + 1], floor_marks[i] = i, true
        -- Rank panes first so tinsel covers some of the blue objectives.
        terrain[i + 1] = #oil - 100
    end
    return {name=name, lesson="Light every pane.", moves=moves, score=0, relics=0,
        chains=chains, ice=0, mask=mask, terrain=terrain, oil=oil, oil_still=true,
        goals={"oil"}, floor_marks=floor_marks}
end

-- Deliberate repeated silhouettes: two cut lanes, a tapered court, and
-- two chambers joined by an end bridge.
local lanes_mask = "1111111111111111111000000111111111110000001111111111111111111"
local bowl_mask = "0111101111101111111111111111111111111111111011111101111101111"
local chambers_mask = "1111111111111111110000001100000001100000011111111111111111111"

-- Compact radius-three court, offset to suit each game.
local compact_mask = "0000000000000111100011111000111111001111111011111101111101111"

local levels = {
    level("Welcome Lights", 20, 0, bowl_mask,
        {{-1,0}, {-1,1}, {0,-1}, {0,0}, {0,1}, {1,-1}, {1,0}}),
    level("Lumber Lane", 24, 0, bowl_mask,
        {{-2,0}, {-2,1}, {-1,0}, {-1,1}, {0,0}, {0,1}, {1,-1}, {2,-1}}),
    level("Gingerbread Swirl", 30, 0, bowl_mask,
        {{-2,1}, {-1,0}, {-1,1}, {0,-1}, {0,0}, {0,1}, {1,-1}, {1,0},
         {2,-1}, {-2,0}, {-1,-1}, {0,-2}, {0,2}, {1,1}}),
    level("Cocoa Corner", 57, 0, lanes_mask,
        {{-3,1}, {-3,2}, {-2,0}, {-2,1}, {-2,2}, {2,-2}, {2,-1}, {3,-2},
         {3,-1}, {2,0}, {-3,0}, {-2,-1}, {3,0}, {-4,1}, {-2,3}, {2,-3},
         {4,-1}, {-4,2}, {-3,3}, {3,-3}, {4,-2}, {-4,3}, {4,-3}, {0,0}}),
    level("Toymaker Lane", 60, 1, chambers_mask,
        {{-3,0}, {-3,1}, {-2,0}, {-2,1}, {-2,2}, {2,-1}, {2,0}, {2,1},
         {3,-1}, {3,0}, {-2,-1}, {1,2}, {-4,0}, {-3,-1}, {2,-2}, {2,2},
         {3,1}, {4,0}, {-4,1}, {-3,2}, {-2,3}, {3,-2}, {4,-1}, {-4,2},
         {-3,3}}),
    level("Ribbon Wishes", 62, 5, compact_mask,
        {{-1,0}, {-1,1}, {0,0}, {0,1}, {0,2}, {1,-1}, {1,1}, {2,-2},
         {2,-1}, {2,0}, {0,-1}, {1,0}, {-2,0}, {-1,-1}, {-2,1}, {-1,2},
         {0,3}, {1,-2}, {1,2}, {2,1}, {3,0}, {-2,2}, {-1,3}, {3,-1},
         {2,-3}, {3,-2}}),
    level("Candlelight Circle", 64, 0, chambers_mask,
        {{-3,1}, {-3,2}, {-2,1}, {-2,2}, {-1,3}, {0,3}, {1,2}, {2,1},
         {2,2}, {3,0}, {-2,0}, {2,0}, {-3,0}, {0,4}, {1,3}, {3,-1},
         {3,1}, {4,0}, {-4,1}, {-2,3}, {-1,4}, {4,-1}, {-4,2}, {-3,3},
         {-2,4}, {-4,3}, {-2,-1}, {2,-1}}),
    level("Carousel Stars", 58, 5, bowl_mask,
        {{-2,0}, {-2,1}, {-1,-1}, {-1,1}, {0,-2}, {0,-1}, {0,0}, {0,1},
         {0,2}, {1,-1}, {1,0}, {-1,0}, {1,1}, {2,0}, {-3,0}, {-2,-1},
         {-1,-2}, {-1,2}, {0,-3}, {0,3}, {1,-2}, {1,2}, {2,-1}}),
    level("Skating Evening", 58, 1, lanes_mask,
        {{-3,0}, {-3,1}, {-2,0}, {-2,1}, {-2,2}, {2,-2}, {2,-1}, {2,0},
         {3,-2}, {3,-1}, {-2,-1}, {2,1}, {3,0}, {-4,0}, {-3,-1}, {-4,1},
         {-3,2}, {-2,3}, {2,-3}, {4,-1}}),
    level("Under the Big Fir", 78, 0, bowl_mask,
        {{-2,1}, {-2,2}, {-1,0}, {-1,1}, {-1,2}, {0,-2}, {0,-1}, {0,0},
         {0,1}, {0,2}, {1,-1}, {1,0}, {2,0}, {-2,0}, {-1,-1}, {1,1},
         {-1,-2}, {0,-3}, {0,3}, {1,-2}, {1,2}, {2,-1}}),
    level("Carols and Crumbs", 63, 0, chambers_mask,
        {{-3,1}, {-3,2}, {-2,1}, {-2,2}, {2,-1}, {2,0}, {2,1}, {3,0},
         {-2,0}, {-3,0}, {1,2}, {2,-2}, {2,2}, {3,-1}, {3,1}, {4,0},
         {-4,1}, {-2,3}, {3,-2}, {4,-1}, {-4,2}, {-3,3}, {-4,3}, {-2,-1},
         {0,3}, {-4,0}, {-3,-1}, {-1,3}}),
    level("Word from Fenwick", 69, 2, bowl_mask,
        {{-2,1}, {-1,0}, {-1,1}, {-1,2}, {0,-1}, {0,0}, {1,-1}, {1,0},
         {2,-2}, {2,-1}, {0,1}, {-2,0}, {-1,-1}, {0,-2}, {0,2}, {1,1},
         {2,0}, {1,-2}, {-3,1}, {-2,2}, {-1,3}, {3,-1}, {-3,2}, {-2,3},
         {2,-3}, {3,-2}, {3,-3}, {-3,0}, {-2,-1}, {-1,-2}, {0,-3}, {0,3}}),
    level("Sawdust Row", 65, 5, lanes_mask,
        {{-3,0}, {-3,1}, {-2,-1}, {-2,0}, {-2,1}, {-2,2}, {2,-2}, {2,-1},
         {3,-2}, {3,-1}, {3,0}, {2,0}, {2,1}, {-4,0}, {-3,-1}, {-2,-2},
         {3,1}, {4,0}, {-4,1}, {-3,2}, {-2,3}, {2,-3}, {4,-1}, {-4,2},
         {-3,3}, {3,-3}, {4,-2}, {4,-3}, {0,0}}),
    level("The Bench by the Fir", 65, 0, bowl_mask,
        {{-2,-1}, {-2,0}, {-2,1}, {-1,-1}, {-1,0}, {0,0}, {0,1}, {1,0},
         {1,1}, {2,-1}, {2,0}, {2,1}, {0,-1}, {-1,1}, {0,-2}, {0,2},
         {1,-1}, {-3,0}, {-1,-2}, {-1,2}, {1,2}, {3,0}, {-3,1}, {-2,2},
         {2,-2}, {2,2}, {3,-1}, {3,1}, {-3,2}}),
    level("Tangled Tinsel", 64, 1, bowl_mask,
        {{-2,1}, {-1,-1}, {-1,0}, {-1,1}, {-1,2}, {0,-2}, {0,-1}, {0,1},
         {0,2}, {1,-2}, {1,-1}, {1,0}, {2,-1}, {0,0}, {-2,0}, {1,1},
         {2,0}, {-2,-1}, {-1,-2}, {0,-3}, {0,3}, {1,2}, {-3,1}, {-2,2},
         {-1,3}, {1,-3}, {2,-2}, {3,-1}}),
    level("Paper and String", 69, 0, lanes_mask,
        {{-3,2}, {-3,3}, {-2,1}, {-2,2}, {-2,3}, {2,-2}, {2,-1}, {2,0},
         {3,-2}, {-2,0}, {2,1}, {3,0}, {-3,1}, {3,-1}, {2,-3}, {-4,2},
         {-2,4}, {3,-3}, {4,-2}, {-4,3}, {-3,4}, {4,-3}}),
    level("Twelve Horses", 66, 0, bowl_mask,
        {{-3,1}, {-2,0}, {-2,1}, {-2,2}, {-1,-1}, {-1,0}, {-1,2}, {1,-2},
         {1,0}, {1,1}, {2,-2}, {2,-1}, {2,0}, {3,-1}, {0,0}, {0,-1},
         {0,1}, {-1,1}, {0,-2}, {0,2}, {1,-1}, {-3,0}, {-2,-1}, {-1,-2},
         {1,2}, {2,1}, {3,0}, {-1,3}, {1,-3}, {-4,1}}),
    level("Fairy Lights", 72, 1, bowl_mask,
        {{-2,1}, {-1,0}, {-1,1}, {0,-1}, {0,0}, {1,-1}, {2,-2}, {2,-1},
         {0,1}, {1,0}, {-2,0}, {-1,-1}, {0,-2}, {2,0}, {-1,2}, {1,-2},
         {-3,1}, {-2,2}, {3,-1}, {-3,2}, {2,-3}, {3,-2}, {3,-3}, {0,2},
         {1,1}, {-3,0}, {-2,-1}, {-1,-2}, {0,-3}, {2,1}, {3,0}, {-1,3}}),
    level("A Hundred Flames", 70, 0, chambers_mask,
        {{-3,0}, {-3,1}, {-3,2}, {-2,0}, {-2,1}, {-2,2}, {2,-2}, {2,-1},
         {2,0}, {2,1}, {3,-2}, {3,-1}, {3,0}, {-2,-1}, {1,2}, {-4,0},
         {-3,-1}, {2,2}, {3,1}, {4,0}, {-4,1}, {-2,3}, {2,-3}, {4,-1},
         {-4,2}, {-3,3}, {3,-3}, {4,-2}, {-4,3}, {4,-3}, {0,3}, {-2,-2}}),
    level("A Letter Forty Years Late", 84, 0, bowl_mask,
        {{-3,1}, {-3,2}, {-2,0}, {-2,1}, {-2,2}, {-1,0}, {-1,1}, {1,-1},
         {1,0}, {2,-2}, {2,-1}, {2,0}, {3,-2}, {3,-1}, {0,0}, {0,-1},
         {0,1}, {-1,-1}, {1,1}, {-3,0}, {-2,-1}, {-1,2}, {1,-2}, {2,1},
         {3,0}}),
    level("Carolers Court", 34, 0, bowl_mask,
        {{-2,1}, {-2,2}, {-1,1}, {-1,2}, {0,0}, {0,1}, {1,0}, {1,1}, {2,0}}),
    level("Many Hands", 38, 6, bowl_mask,
        {{-3,1}, {-2,0}, {-2,1}, {-1,0}, {-1,1}, {0,-1}, {0,0}, {1,-1}, {1,0}, {2,-2}, {2,-1}, {3,-1}}),
    level("Painted Horses", 39, 5, lanes_mask,
        {{-3,1}, {-3,2}, {-2,0}, {-2,1}, {-2,2}, {2,-2}, {2,-1}, {2,0}, {3,-2}, {3,-1}}),
    level("A Ribbon for Home", 40, 4, bowl_mask,
        {{-2,0}, {-2,1}, {-1,-1}, {-1,0}, {-1,2}, {0,-2}, {0,-1}, {0,1}, {0,2}, {1,-2}, {1,-1}, {1,1}, {2,-1}, {2,0}}),
    level("Word from the Station", 42, 6, bowl_mask,
        {{-2,0}, {-2,1}, {-1,-1}, {-1,0}, {0,-1}, {0,0}, {0,1}, {1,-1}, {1,0}, {1,1}, {2,-2}, {2,-1}, {2,0}, {3,-2}}),
    level("First Skate", 44, 4, bowl_mask,
        {{-3,1}, {-2,0}, {-2,1}, {-2,2}, {-1,-1}, {-1,0}, {-1,1}, {-1,2}, {0,-2}, {0,-1}, {0,0}, {0,1}, {1,-1}, {1,0}}),
    level("Every Light in Bellmere", 44, 5, chambers_mask,
        {{-3,0}, {-3,1}, {-3,2}, {-3,3}, {-2,0}, {-2,1}, {-2,2}, {-2,3}, {2,-2}, {2,-1}, {2,0}, {2,1}, {3,-2}, {3,-1}, {3,0}, {3,1}}),
    level("The Last Train", 44, 2, bowl_mask,
        {{-2,2}, {-1,1}, {-1,2}, {0,0}, {0,1}, {1,-1}, {1,0}, {2,-2}, {2,-1}, {3,-2}}),
    level("The Big Fir", 46, 8, lanes_mask,
        {{-3,0}, {-3,1}, {-3,2}, {-2,-1}, {-2,0}, {-2,1}, {-2,2}, {2,-2}, {2,-1}, {2,0}, {2,1}, {3,-2}, {3,-1}}),
    level("Light the Christmas Tree", 48, 8, bowl_mask,
        {{0,-3}, {0,-2}, {0,-1}, {0,0}, {0,1}, {0,2}, {0,3}, {-1,-1}, {-1,0}, {-1,1}, {-1,2}, {-2,1}, {1,-2}, {1,-1}, {1,0}, {1,1}, {2,-1}}),
}

-- Rome I introduces double plaques on 10 and repeats them on 20.
for _, number in ipairs{10, 20} do
    levels[number].oil_double = levels[number].oil
end

-- The finished board holds a painting before the first-clear scene.
levels[24].reveal = {picture="wish-ribbon", floor="oil", on_clear=true}
levels[25].reveal = {picture="telegram", floor="oil", on_clear=true}
levels[28].reveal = {picture="last-train", floor="oil", on_clear=true}

-- Each find is part of the first-clear scene and results card. It has
-- no colour slot, tally or effect on the goods delivered by the board.
local finds = {
    [9]={key="cocoa", name="Cocoa mug"},
    [16]={key="scarf", name="Blue practice scarf"},
    [19]={key="letter", name="Undelivered letter"},
    [24]={key="ribbon", name="Wish ribbon"},
    [25]={key="telegram", name="Station telegram"},
    [27]={key="lantern", name="Borrowed lantern"},
}
for index, find in pairs(finds) do
    levels[index].story_piece = find
end

local shapes = {}
for i, entry in ipairs(levels) do shapes[i] = entry.name end

return {levels=levels, shapes=shapes, wonder_levels={1,4,7,9,13,16,19,23,26,29}}
