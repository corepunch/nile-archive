-- Each wish has a fixed set of red panes. Only those panes need clearing.
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
        assert(mask:sub(i + 1, i + 1) == "1" and not floor_marks[i], "invalid red pane")
        oil[#oil + 1], floor_marks[i] = i, true
        -- Rank panes first so tinsel covers some of the red objectives.
        terrain[i + 1] = #oil - 100
    end
    return {name=name, lesson="Light every red pane.", moves=moves, score=0, relics=0,
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
    level("Gingerbread Swirl", 26, 0, bowl_mask,
        {{-2,1}, {-1,0}, {-1,1}, {0,-1}, {0,0}, {0,1}, {1,-1}, {1,0}, {2,-1}}),
    level("Cocoa Corner", 30, 4, lanes_mask,
        {{-3,1}, {-3,2}, {-2,0}, {-2,1}, {-2,2}, {2,-2}, {2,-1}, {3,-2}, {3,-1}}),
    level("Toymaker Lane", 36, 4, chambers_mask,
        {{-3,0}, {-3,1}, {-2,0}, {-2,1}, {-2,2}, {2,-1}, {2,0}, {2,1}, {3,-1}, {3,0}}),
    level("Ribbon Wishes", 38, 0, compact_mask,
        {{-1,0}, {-1,1}, {0,0}, {0,1}, {0,2}, {1,-1}, {1,1}, {2,-2}, {2,-1}, {2,0}}),
    level("Candlelight Circle", 40, 4, chambers_mask,
        {{-3,1}, {-3,2}, {-2,1}, {-2,2}, {-1,3}, {0,3}, {1,2}, {2,1}, {2,2}, {3,0}}),
    level("Carousel Stars", 42, 4, bowl_mask,
        {{-2,0}, {-2,1}, {-1,-1}, {-1,1}, {0,-2}, {0,-1}, {0,0}, {0,1}, {0,2}, {1,-1}, {1,0}}),
    level("Skating Evening", 46, 5, lanes_mask,
        {{-3,0}, {-3,1}, {-2,0}, {-2,1}, {-2,2}, {2,-2}, {2,-1}, {2,0}, {3,-2}, {3,-1}}),
    level("Under the Big Fir", 46, 6, bowl_mask,
        {{-2,1}, {-2,2}, {-1,0}, {-1,1}, {-1,2}, {0,-2}, {0,-1}, {0,0}, {0,1}, {0,2}, {1,-1}, {1,0}, {2,0}}),
    level("Carols and Crumbs", 32, 0, chambers_mask,
        {{-3,1}, {-3,2}, {-2,1}, {-2,2}, {2,-1}, {2,0}, {2,1}, {3,0}}),
    level("Word from Fenwick", 35, 5, bowl_mask,
        {{-2,1}, {-1,0}, {-1,1}, {-1,2}, {0,-1}, {0,0}, {1,-1}, {1,0}, {2,-2}, {2,-1}}),
    level("Sawdust Row", 36, 6, lanes_mask,
        {{-3,0}, {-3,1}, {-2,-1}, {-2,0}, {-2,1}, {-2,2}, {2,-2}, {2,-1}, {3,-2}, {3,-1}, {3,0}}),
    level("The Bench by the Fir", 37, 7, bowl_mask,
        {{-2,-1}, {-2,0}, {-2,1}, {-1,-1}, {-1,0}, {0,0}, {0,1}, {1,0}, {1,1}, {2,-1}, {2,0}, {2,1}}),
    level("Tangled Tinsel", 38, 9, bowl_mask,
        {{-2,1}, {-1,-1}, {-1,0}, {-1,1}, {-1,2}, {0,-2}, {0,-1}, {0,1}, {0,2}, {1,-2}, {1,-1}, {1,0}, {2,-1}}),
    level("Paper and String", 40, 4, lanes_mask,
        {{-3,2}, {-3,3}, {-2,1}, {-2,2}, {-2,3}, {2,-2}, {2,-1}, {2,0}, {3,-2}}),
    level("Twelve Horses", 41, 5, bowl_mask,
        {{-3,1}, {-2,0}, {-2,1}, {-2,2}, {-1,-1}, {-1,0}, {-1,2}, {1,-2}, {1,0}, {1,1}, {2,-2}, {2,-1}, {2,0}, {3,-1}}),
    level("Fairy Lights", 42, 2, bowl_mask,
        {{-2,1}, {-1,0}, {-1,1}, {0,-1}, {0,0}, {1,-1}, {2,-2}, {2,-1}}),
    level("A Hundred Flames", 44, 6, chambers_mask,
        {{-3,0}, {-3,1}, {-3,2}, {-2,0}, {-2,1}, {-2,2}, {2,-2}, {2,-1}, {2,0}, {2,1}, {3,-2}, {3,-1}, {3,0}}),
    level("A Letter Forty Years Late", 46, 7, bowl_mask,
        {{-3,1}, {-3,2}, {-2,0}, {-2,1}, {-2,2}, {-1,0}, {-1,1}, {1,-1}, {1,0}, {2,-2}, {2,-1}, {2,0}, {3,-2}, {3,-1}}),
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

-- The finished board holds a painting before the first-clear scene.
levels[24].reveal = {picture="wish-ribbon", floor="oil", on_clear=true}
levels[25].reveal = {picture="telegram", floor="oil", on_clear=true}
levels[28].reveal = {picture="last-train", floor="oil", on_clear=true}

-- The story object replaces its regular kind for the whole wish, including
-- refills. The red panes still decide the win.
local finds = {
    [9]={key="cocoa", name="Cocoa mug", kind=1},
    [16]={key="scarf", name="Blue practice scarf", kind=3},
    [19]={key="letter", name="Undelivered letter", kind=5},
    [24]={key="ribbon", name="Wish ribbon", kind=1},
    [25]={key="telegram", name="Station telegram", kind=3},
    [27]={key="lantern", name="Borrowed lantern", kind=0},
}
for index, find in pairs(finds) do
    levels[index].story_piece, levels[index].goal_kind = find, find.kind
end

local shapes = {}
for i, entry in ipairs(levels) do shapes[i] = entry.name end

return {levels=levels, shapes=shapes, wonder_levels={1,4,7,9,13,16,19,23,26,29}}
