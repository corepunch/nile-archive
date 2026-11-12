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

local levels = {
    -- 01: Welcome Lights
    level("Welcome Lights", "Match three treats in a line.", 24, 1100, 8, 0, 0, 0, 1,
        "0011101111111111111111111111110111111111111111111111111101111", terrain(-1, 0, 1, -1, 1)),
    -- 02: Lumber Lane
    level("Lumber Lane", "Match four to make a striped treat.", 28, 1800, 10, 7, 0, 0, 1,
        "0111101111101111110110111111111111111111111111111111111101111", terrain(0, -1, 1, 0, -1)),
    -- 03: Gingerbread Swirl
    level("Gingerbread Swirl", "Match on snow to clear it.", 32, 2300, 12, 12, 0, 0, 1,
        "1110011110011111011111111111111111111110111111111111111100111", terrain(-2, 1, 1, 0, 1)),
    -- 04: Cocoa Corner
    level("Cocoa Corner", "Match through tinsel to free treats.", 34, 2700, 12, 10, 4, 0, 1,
        "0111101111101111111110011101100111011101111111111111111100111", terrain(1, -2, -1, 1, -1)),
    -- 05: Toymaker Lane
    level("Toymaker Lane", "Use striped treats across the court.", 36, 3100, 14, 13, 4, 0, 1,
        "1001111011111111111111111111111111011101111111111111101111000", terrain(-2, 0, 2, -1, 1)),
    -- 06: Ribbon Wishes
    level("Ribbon Wishes", "Match on ice to crack it.", 38, 3400, 14, 13, 0, 5, 1,
        "0011101111011111101111111111111011111111111111111011111011111", terrain(0, 1, 1, -2, -1)),
    -- 07: Candlelight Circle
    level("Candlelight Circle", "Candy canes also thaw nearby ice.", 40, 3800, 16, 15, 4, 5, 2,
        "1110011110111111010111111101101111111111111111111111111101111", terrain(-1, 1, 2, -1, 1)),
    -- 08: Carousel Stars
    level("Carousel Stars", "Match five to make a rainbow star.", 42, 4200, 16, 17, 4, 6, 2,
        "0111101111101111111111110011100011011100011111111111111101111", terrain(0, -1, 0, 1, 0)),
    -- 09: Skating Evening
    level("Skating Evening", "Striped treats clear a whole line.", 44, 4600, 18, 19, 5, 6, 2,
        "0011101111111111110101111101111111111111111111111011111011110", terrain(-2, 1, 2, -2, 1)),
    -- 10: Under the Big Fir
    level("Under the Big Fir", "Clear snow, tinsel and ice.", 46, 5000, 20, 22, 6, 6, 2,
        "0111101111101111111111011101110011011100111111111011111011111", terrain(0, 1, 0, -2, -1)),
    -- 11: Carols and Crumbs
    level("Carols and Crumbs", "Clear the snow around the square.", 32, 2500, 12, 14, 0, 0, 1,
        "1110011110011111101111111111111111111110111111111111111100111", terrain(-1, -1, 1, 1, 1)),
    -- 12: Word from Fenwick
    level("Word from Fenwick", "Free tinsel along the snowy court.", 35, 2900, 13, 15, 5, 0, 1,
        "0011101111101111110110111111111111011111111111111111111011111", terrain(-2, 1, 1, -1, -1)),
    -- 13: Sawdust Row
    level("Sawdust Row", "Use a striped treat to reach across.", 36, 3200, 14, 16, 6, 0, 1,
        "0111101111101111110111111101111011011111111111111011111011111", terrain(1, -2, -1, 1, 1)),
    -- 14: The Bench by the Fir
    level("The Bench by the Fir", "Open the court from either side.", 37, 3500, 14, 17, 7, 0, 1,
        "0011101111011111101110011111110011111100111011111101111111111", terrain(-2, 0, 2, -1, -1)),
    -- 15: Tangled Tinsel
    level("Tangled Tinsel", "Untangle tinsel through the snow.", 38, 3700, 15, 16, 9, 0, 1,
        "1110011111111111011110011011110011011111111111111101111101111", terrain(0, -2, 1, 1, 1)),
    -- 16: Paper and String
    level("Paper and String", "Crack the ice around the paper.", 40, 4000, 15, 18, 4, 7, 1,
        "0111101111101111110111111101101111111111110111111011111011111", terrain(-1, 1, 1, -1, -1)),
    -- 17: Twelve Horses
    level("Twelve Horses", "Thaw ice across the court.", 41, 4200, 16, 19, 5, 7, 1,
        "0011101111011111101110011101100111111111011011111111111111111", terrain(-2, 1, 2, -1, 1)),
    -- 18: Fairy Lights
    level("Fairy Lights", "Take a breath and clear the snow.", 42, 3000, 12, 12, 2, 4, 1,
        "0111101111101111111101111011111111011111111111111011111011111", terrain(0, 0, 1, -2, -1)),
    -- 19: A Hundred Flames
    level("A Hundred Flames", "Remember: thick ice takes two hits.", 44, 4600, 18, 20, 6, 8, 2,
        "1110011110111111011111111101110111111111111011111101111101111", terrain(-1, -1, 2, -1, 1)),
    -- 20: A Letter Forty Years Late
    level("A Letter Forty Years Late", "Open both sides of the court.", 46, 5100, 20, 22, 7, 9, 2,
        "0011101111111111110110111101100111011100111111111011111111111", terrain(-2, 1, 1, 0, -1)),
    -- 21: Carolers Court
    level("Carolers Court", "Clear the snow for the carolers.", 34, 2800, 12, 15, 0, 0, 1,
        "0111101111101111110110111101111111111111111111111111111100111", terrain(0, -1, 1, 1, 1)),
    -- 22: Many Hands
    level("Many Hands", "Free tinsel along the passage.", 38, 3400, 14, 16, 6, 0, 1,
        "1110011111111111011111111011100011011100111111111101111100111", terrain(-2, 0, 1, -1, -1)),
    -- 23: Painted Horses
    level("Painted Horses", "Rainbow stars clear one colour.", 39, 3700, 15, 16, 5, 5, 1,
        "0011101111011111101111111111111111111101111011111101111101111", terrain(-1, 1, 2, -2, 1)),
    -- 24: Frozen Fountain
    level("Frozen Fountain", "Thaw the ice around the fountain.", 40, 3900, 16, 16, 4, 5, 2,
        "0111101111101111110111011111110011011100110111111011111111111", terrain(0, -1, 0, 1, 0)),
    -- 25: Snow on the Line
    level("Snow on the Line", "Clear the snow and free the treats.", 42, 4000, 16, 18, 6, 6, 2,
        "1110011110111111011111111101101111111111111011111101111111111", terrain(-2, 1, 1, -1, 1)),
    -- 26: Lantern Ice
    level("Lantern Ice", "Thaw the ice around the lanterns.", 44, 4300, 17, 20, 4, 9, 2,
        "0011101111111111110111011101110011011110011111111011111011111", terrain(-1, 0, 1, -2, -1)),
    -- 27: Every Light in Bellmere
    level("Every Light in Bellmere", "Clear the snow across the court.", 38, 4800, 18, 21, 7, 8, 2,
        "0111101111101111111100011011100011011111111011111101111101111", terrain(-2, 1, 2, -1, 1)),
    -- 28: The Last Train
    level("The Last Train", "A little snow before the finale.", 44, 3200, 13, 13, 2, 4, 1,
        "1110011110011111101111111111110111111111111011111101111111111", terrain(0, 0, 1, -1, -1)),
    -- 29: The Big Fir
    level("The Big Fir", "Untangle and thaw the snowy court.", 47, 5200, 20, 23, 8, 10, 2,
        "0011101111101111110110011101100111111110111111111011111011111", terrain(-1, 1, 2, -1, 1)),
    -- 30: Light the Christmas Tree
    level("Light the Christmas Tree", "Clear the snow, tinsel and ice.", 48, 5500, 22, 24, 8, 10, 2,
        "1110011111111111011110111011100111011100111011111101111110111", terrain(0, -2, 1, 1, -1)),
}

local shapes = {}
for i, entry in ipairs(levels) do shapes[i] = entry.name end

return {levels=levels, shapes=shapes, wonder_levels={1,4,7,9,13,16,19,23,26,29}}
