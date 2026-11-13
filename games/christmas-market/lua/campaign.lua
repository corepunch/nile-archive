-- Campaign data. Each court has its own contour and terrain priority.
local function level(name, lesson, moves, score, relics, soil, chains, ice, ice_layers, mask, terrain)
    return {name=name, lesson=lesson, moves=moves, score=score, relics=relics,
        soil=soil, chains=chains, ice=ice, ice_layers=ice_layers, mask=mask, terrain=terrain}
end

-- Rank cells around two authored focal points. Snow uses the first ranks;
-- the engine interleaves tinsel and then places ice within the inner court.
local function terrain(aq, ar, bq, br, direction)
    local ranks, index = {}, 1
    local function distance(q, r, x, y)
        return math.max(math.abs(q-x), math.abs(r-y), math.abs(q+r-x-y))
    end
    for q = -4, 4 do
        for r = math.max(-4, -q-4), math.min(4, -q+4) do
            ranks[index] = math.min(distance(q, r, aq, ar), distance(q, r, bq, br)) * 100
                + direction * (q * 5 + r) + index / 100
            index = index + 1
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
local lanes_mask = "1111111111111111111000000111111111110000001111111111111111111"
local bowl_mask = "0111101111101111111111111111111111111111111011111101111101111"
local chambers_mask = "1111111111111111110000001100000001100000011111111111111111111"

-- Compact radius-three court, offset to suit each game.
local compact_mask = "0000000000000111100011111000111111001111111011111101111101111"

local levels = {
    -- 01: Welcome Lights
    level("Welcome Lights", "Match three treats in a line.", 24, 1100, 8, 0, 0, 0, 1,
        bowl_mask, terrain(-1, 0, 1, -1, 1)),
    -- 02: Lumber Lane
    level("Lumber Lane", "Match four to make a rocket.", 28, 1800, 10, 7, 0, 0, 1,
        bowl_mask, terrain(0, -1, 1, 0, -1)),
    -- 03: Gingerbread Swirl
    level("Gingerbread Swirl", "Match on snow to clear it.", 32, 2300, 12, 12, 0, 0, 1,
        bowl_mask, terrain(-2, 1, 1, 0, 1)),
    -- 04: Cocoa Corner
    level("Cocoa Corner", "Match through tinsel to free treats.", 34, 2700, 12, 10, 4, 0, 1,
        lanes_mask, terrain(1, -2, -1, 1, -1)),
    -- 05: Toymaker Lane
    level("Toymaker Lane", "Use rockets across the court.", 36, 3100, 14, 13, 4, 0, 1,
        chambers_mask, terrain(-2, 0, 2, -1, 1)),
    -- 06: Ribbon Wishes
    level("Ribbon Wishes", "Match on ice to crack it.", 38, 3400, 14, 13, 0, 5, 1,
        compact_mask, terrain(0, 1, 1, -2, -1)),
    -- 07: Candlelight Circle
    level("Candlelight Circle", "Hit frozen pieces with matches or power-ups.", 40, 3800, 16, 15, 4, 5, 2,
        chambers_mask, terrain(-1, 1, 2, -1, 1)),
    -- 08: Carousel Stars
    level("Carousel Stars", "Match five to make a rainbow star.", 42, 4200, 16, 17, 4, 6, 2,
        bowl_mask, terrain(0, -1, 0, 1, 0)),
    -- 09: Skating Evening
    level("Skating Evening", "Striped treats clear a whole line.", 44, 4600, 18, 19, 5, 6, 2,
        lanes_mask, terrain(-2, 1, 2, -2, 1)),
    -- 10: Under the Big Fir
    level("Under the Big Fir", "Clear snow, tinsel and ice.", 46, 5000, 20, 22, 6, 6, 2,
        bowl_mask, terrain(0, 1, 0, -2, -1)),
    -- 11: Carols and Crumbs
    level("Carols and Crumbs", "Clear the snow around the square.", 32, 2500, 12, 14, 0, 0, 1,
        chambers_mask, terrain(-1, -1, 1, 1, 1)),
    -- 12: Word from Fenwick
    level("Word from Fenwick", "Free tinsel along the snowy court.", 35, 2900, 13, 15, 5, 0, 1,
        bowl_mask, terrain(-2, 1, 1, -1, -1)),
    -- 13: Sawdust Row
    level("Sawdust Row", "Use a rocket to reach across.", 36, 3200, 14, 16, 6, 0, 1,
        lanes_mask, terrain(1, -2, -1, 1, 1)),
    -- 14: The Bench by the Fir
    level("The Bench by the Fir", "Open the court from either side.", 37, 3500, 14, 17, 7, 0, 1,
        bowl_mask, terrain(-2, 0, 2, -1, -1)),
    -- 15: Tangled Tinsel
    level("Tangled Tinsel", "Untangle tinsel through the snow.", 38, 3700, 15, 16, 9, 0, 1,
        bowl_mask, terrain(0, -2, 1, 1, 1)),
    -- 16: Paper and String
    level("Paper and String", "Crack the ice around the paper.", 40, 4000, 15, 18, 4, 7, 1,
        lanes_mask, terrain(-1, 1, 1, -1, -1)),
    -- 17: Twelve Horses
    level("Twelve Horses", "Thaw ice across the court.", 41, 4200, 16, 19, 5, 7, 1,
        bowl_mask, terrain(-2, 1, 2, -1, 1)),
    -- 18: Fairy Lights
    level("Fairy Lights", "Take a breath and clear the snow.", 42, 3000, 12, 12, 2, 4, 1,
        bowl_mask, terrain(0, 0, 1, -2, -1)),
    -- 19: A Hundred Flames
    level("A Hundred Flames", "Remember: thick ice takes two hits.", 44, 4600, 18, 20, 6, 8, 2,
        chambers_mask, terrain(-1, -1, 2, -1, 1)),
    -- 20: A Letter Forty Years Late
    level("A Letter Forty Years Late", "Open both sides of the court.", 46, 5100, 20, 22, 7, 9, 2,
        bowl_mask, terrain(-2, 1, 1, 0, -1)),
    -- 21: Carolers Court
    level("Carolers Court", "Clear the snow for the carolers.", 34, 2800, 12, 15, 0, 0, 1,
        bowl_mask, terrain(0, -1, 1, 1, 1)),
    -- 22: Many Hands
    level("Many Hands", "Free tinsel along the passage.", 38, 3400, 14, 16, 6, 0, 1,
        bowl_mask, terrain(-2, 0, 1, -1, -1)),
    -- 23: Painted Horses
    level("Painted Horses", "Rainbow stars clear one colour.", 39, 3700, 15, 16, 5, 5, 1,
        lanes_mask, terrain(-1, 1, 2, -2, 1)),
    -- 24: Frozen Fountain
    level("Frozen Fountain", "Thaw the ice around the fountain.", 40, 3900, 16, 16, 4, 5, 2,
        bowl_mask, terrain(0, -1, 0, 1, 0)),
    -- 25: Snow on the Line
    level("Snow on the Line", "Clear the snow and free the treats.", 42, 4000, 16, 18, 6, 6, 2,
        bowl_mask, terrain(-2, 1, 1, -1, 1)),
    -- 26: Lantern Ice
    level("Lantern Ice", "Thaw the ice around the lanterns.", 44, 4300, 17, 20, 4, 9, 2,
        bowl_mask, terrain(-1, 0, 1, -2, -1)),
    -- 27: Every Light in Bellmere
    level("Every Light in Bellmere", "Clear the snow across the court.", 38, 4800, 18, 16, 5, 6, 2,
        chambers_mask, terrain(-2, 1, 2, -1, 1)),
    -- 28: The Last Train
    level("The Last Train", "A little snow before the finale.", 44, 3200, 13, 13, 2, 4, 1,
        bowl_mask, terrain(0, 0, 1, -1, -1)),
    -- 29: The Big Fir
    level("The Big Fir", "Untangle and thaw the snowy court.", 47, 5200, 20, 23, 8, 10, 2,
        lanes_mask, terrain(-1, 1, 2, -1, 1)),
    -- 30: Light the Christmas Tree
    level("Light the Christmas Tree", "Clear the snow, tinsel and ice.", 48, 5500, 22, 24, 8, 10, 2,
        bowl_mask, terrain(0, -2, 1, 1, -1)),
}


-- Introduce a display, a packed snowdrift and the delivery tools separately.
levels[3].objects = {{cells={cell(0,-1),cell(0,0)}}}
levels[3].lesson = "Clear both snow cells to reveal a display."
levels[5].stones = {{cell=cell(2,0),hp=1}}
levels[5].lesson = "Match beside the snowdrift to clear it."
levels[7].stones = {{cell=cell(2,0),hp=2}}
levels[7].lesson = "Some snowdrifts need two hits."
levels[8].crates = {{cell=cell(-1,0),hp=1,kind=0}}
levels[8].lesson = "Match the ribbon colour beside its parcel."
levels[10].crates = {{cell=cell(-1,0),hp=1,kind=1}}
levels[11].objects = {{cells={cell(2,-1),cell(2,0)}}}
levels[12].tunnels = {{entrance=cell(0,-2),exit=cell(1,1)}}
levels[12].lesson = "Treats travel between paired chutes."
levels[13].crates = {{cell=cell(2,0),hp=1,kind=2}}
levels[14].stones = {{cell=cell(2,0),hp=3}}
levels[14].lesson = "Clear the three-layer snowdrift."
levels[15].objects = {{cells={cell(1,0),cell(1,1)}}}
levels[16].crates = {{cell=cell(2,0),hp=2,kind=3}}
levels[16].lesson = "Some ribbon parcels take two hits."
levels[17].deliveries = {tokens={cell(2,-2)},exits={cell(2,2)}}
levels[17].lesson = "Clear below the parcel to deliver it."
levels[19].stones = {{cell=cell(2,1),hp=2}}
levels[20].tunnels = {{entrance=cell(0,-2),exit=cell(1,1)}}
levels[22].crates = {{cell=cell(-1,0),hp=1,kind=4}}
levels[23].hazards = {cell(2,0)}
levels[23].lesson = "Untangle the ribbon before it spreads."
levels[24].objects = {{cells={cell(-1,-1),cell(0,-1)}}}
levels[25].hazards = {cell(2,0)}
levels[26].crates = {{cell=cell(2,0),hp=2,kind=5}}
levels[27].stones = {{cell=cell(2,0),hp=3}}
levels[29].hazards = {cell(2,0)}
levels[30].tunnels = {{entrance=cell(2,-1),exit=cell(2,1)}}
levels[30].deliveries = {tokens={cell(2,-2)},exits={cell(2,2)}}
levels[30].lesson = "Send the parcel through the chute."
-- Green carpet (Homescapes' carpet): matches touching it spread it.
levels[9].carpet = {cell(-3,-1), cell(3,0)}   -- one in each lane, not on the narrow spine
levels[9].lesson = "Match on the green carpet to spread it."
levels[21].carpet = {cell(-2,1), cell(-2,2)}
levels[28].carpet = {cell(-1,-1), cell(0,-2)}
levels[28].lesson = "Roll out the carpet before the finale."
-- Spilled caramel (Homescapes' oil): clear it by matching on it; it spreads
-- after any turn that clears none of it.
levels[13].oil = {cell(4,-4), cell(4,-3), cell(4,-2), cell(4,-1), cell(4,0), cell(3,-1), cell(3,0)}
levels[13].lesson = "Clear the spilled caramel before it spreads."
levels[25].oil = {cell(2,-3), cell(3,-3), cell(3,-2), cell(3,-1), cell(4,-3), cell(4,-2), cell(4,-1)}

-- Goals, as in Homescapes: one to three per level, never score (points only
-- rank a clear). The early levels ask for at most two, led by the lesson.
-- "locks" counts every blocker: tinsel, ice, snowdrifts, parcels and ribbon;
-- "carpet" counts the cells the green carpet has yet to cover; "oil" counts
-- the spilled caramel left on the board.
local goals = {
    {"idols"}, {"idols", "sand"}, {"discoveries"}, {"locks", "sand"}, {"locks", "idols"},
    {"locks", "sand"}, {"locks", "idols"}, {"locks", "sand"}, {"carpet"}, {"sand", "locks"},
    {"discoveries", "idols"}, {"idols", "sand"}, {"oil", "locks"}, {"locks", "sand"}, {"discoveries", "locks"},
    {"locks", "idols"}, {"deliveries", "sand"}, {"sand"}, {"locks", "sand", "idols"}, {"sand", "locks"},
    {"carpet", "sand"}, {"locks", "sand"}, {"locks", "idols"}, {"discoveries", "locks"}, {"oil", "sand", "locks"},
    {"locks", "idols"}, {"sand", "locks", "idols"}, {"carpet"}, {"locks", "sand", "idols"}, {"deliveries", "sand", "locks"},
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
for i, entry in ipairs(levels) do shapes[i] = entry.name end

return {levels=levels, shapes=shapes, wonder_levels={1,4,7,9,13,16,19,23,26,29}}
