-- Campaign content only; all match mechanics live in engine/match3.lua.
local function level(name, lesson, moves, score, relics, soil, chains, ice)
    return {name=name, lesson=lesson, moves=moves, score=score, relics=relics, soil=soil, chains=chains, ice=ice}
end
local levels = {
    level("First Light", "Line up 3 or more relics along any hex axis.", 24, 1100, 8, 0, 0, 0),
    level("The Jade Crescent", "Four in a straight line create a sun ray.", 28, 1800, 10, 7, 0, 0),
    level("Sunstone Spiral", "Excavate the spiral beneath the relics.", 32, 2300, 12, 12, 0, 0),
    level("The Vine Constellation", "Match locked relics to break their chains.", 34, 2700, 12, 10, 4, 0),
    level("Three Paths Meet", "Combine sun rays to clear all three axes.", 36, 3100, 14, 13, 4, 0),
    level("Winter Lotus", "Break the ice around the frozen lotus.", 38, 3400, 14, 13, 0, 5),
    level("The Ember Ring", "Fire melts ice in all six neighboring cells.", 40, 3800, 16, 15, 4, 5),
    level("Prism Hollow", "Five in a straight line forge a sun prism.", 42, 4200, 16, 17, 4, 6),
    level("The Sixfold Seal", "Combine rays to clear all three axes.", 44, 4600, 18, 19, 5, 6),
    level("Heart of the Hexagon", "Uncover the ancient sun at the heart of the valley.", 46, 5000, 20, 22, 6, 6),
}
local shapes = {"Hexagon", "Crescent", "Diamond", "Butterfly", "Hourglass", "Lotus", "Ring", "Twin courts", "Crossroads", "Sun crown"}

local masks = {
    "1111111111111111111111111111111111111111111111111111111111111",
    "1111111111111111111111111111111111111111111111100011110011100",
    "0000011111011111101111111001111111001111111011111101111100000",
    "1000111001111000111111111111111111111111111110001111001110001",
    "0111000110011111111111111111111111111111111111111100110001110",
    "1000101111001111100111111011111111101111110011111001111010001",
    "1111111111111111111110011111100011111100111111111111111111111",
    "1111111111111111111111111100011100011111111111111111111111111",
    "1101111111101111101111111111111111111111111011111011111111011",
    "1111111111111111110011111100011111100011111111111111111111111",
}
local terrain = {
    {84,83,82,81,80,80,65,64,63,62,81,82,61,40,45,44,63,82,84,63,42,21,20,45,64,83,80,65,44,23,2,21,40,65,84,81,60,45,24,23,42,61,80,82,61,40,45,44,63,82,83,62,61,60,65,84,84,83,82,81,80},
    {40,39,38,37,36,41,20,19,18,17,38,42,21,0,-1,-2,19,40,43,22,1,20,19,0,21,42,44,23,2,21,40,21,2,23,44,44,23,2,21,22,3,24,45,44,23,2,3,4,25,46,44,23,24,25,26,47,44,45,46,47,48},
    {50,49,48,54,53,52,39,38,37,36,54,54,41,28,27,26,37,48,49,36,30,17,16,27,38,49,51,38,25,12,6,17,28,39,50,52,39,26,13,12,30,41,52,53,40,27,26,25,36,54,54,41,40,39,38,49,48,54,53,52,51},
    {4,54,54,54,4,54,3,53,53,3,54,54,53,2,52,2,53,54,54,53,52,1,1,52,53,54,4,3,2,1,0,1,2,3,4,54,53,52,1,1,52,53,54,54,53,2,52,2,53,54,54,3,53,53,3,54,4,54,54,54,4},
    {44,44,44,44,4,44,43,43,43,3,44,44,43,42,42,2,43,44,44,43,42,41,1,42,43,44,4,3,2,1,0,1,2,3,4,44,43,42,1,41,42,43,44,44,43,2,42,42,43,44,44,3,43,43,43,44,4,44,44,44,44},
    {44,44,44,44,44,43,23,23,23,23,43,42,22,2,2,2,22,42,41,21,1,21,21,1,21,41,40,20,0,20,40,20,0,20,40,41,21,1,21,21,1,21,41,42,22,2,2,2,22,42,43,23,23,23,23,43,44,44,44,44,44},
    {40,41,42,43,44,41,20,21,22,23,44,42,21,0,1,2,23,44,43,22,1,20,21,2,23,44,44,23,2,21,40,21,2,23,44,44,23,2,21,20,1,22,43,44,23,2,1,0,21,42,44,23,22,21,20,41,44,43,42,41,40},
    {4,44,44,44,4,44,3,43,43,3,44,4,43,2,42,2,43,44,44,43,2,1,1,42,43,44,44,43,42,41,0,41,42,43,44,44,43,42,1,1,2,43,44,44,43,2,42,2,43,4,44,3,43,43,3,44,4,44,44,44,4},
    {21,20,24,23,22,23,2,1,0,4,23,20,4,23,22,21,0,24,22,1,20,44,43,22,1,20,24,3,22,41,60,44,23,2,21,20,4,23,42,41,20,4,23,21,0,24,23,22,1,20,22,1,0,4,3,22,23,22,21,20,24},
    {84,83,82,81,80,80,65,64,63,62,81,82,61,40,45,44,63,82,84,63,42,21,20,45,64,83,80,65,44,23,2,21,40,65,84,81,60,45,24,23,42,61,80,82,61,40,45,44,63,82,83,62,61,60,65,84,84,83,82,81,80},
}
for i, entry in ipairs(levels) do
    entry.mask, entry.terrain = masks[i], terrain[i]
    entry.ice_layers = i >= 7 and 2 or 1
end
-- Episodes two and three: authored lane variants, with a gentler restart and
-- a breather before each final stretch. All thirty contours remain connected.
local later = {
    {level("The Long Terrace", "Dig along the rail, one terrace at a time.", 32, 2500, 12, 14, 0, 0), "1111111111111111111111111111111111011111111111111111111111111", 1},
    {level("Twelve Crates", "Chained relics first, then the crates beneath.", 35, 2900, 13, 15, 5, 0), "0000001111101111110111111101111111001111110111111011111000000", 1},
    {level("Names in the Stone", "Sun rays reach the names no pick can.", 36, 3200, 14, 16, 6, 0), "1111111111011110001111100011011101000011111000111101111111111", 1},
    {level("Static", "Two rays together clear the crossing lines.", 37, 3500, 14, 17, 7, 0), "1111111111111111111111111100011100001111111111111111111111111", 1},
    {level("The Frost Line", "The frost has climbed. Break it before it sets.", 38, 3700, 15, 18, 4, 6), "1000101111001111100111111011111111001111110011111001111010001", 1},
    {level("Supper for Twelve", "Flame relics thaw every cell around them.", 40, 4000, 15, 18, 4, 7), "1111111111111111111111111101111111111111111111111111111111111", 2},
    {level("The Torn Log", "Old ice takes two hits. Plan for both.", 41, 4200, 16, 19, 5, 7), "1111111111111111111110011111100011011100111111111111111111111", 2},
    {level("Lantern Steps", "Take a breath. These steps are nearly clear.", 42, 3000, 12, 12, 2, 4), "1110011110111111110111111100111110001111110111111110111100111", 1},
    {level("Under the Vines", "Vines above, frost below. Free what you can reach.", 44, 4600, 18, 20, 6, 8), "1000111001111000111111111111111111011111111110001111001110001", 2},
    {level("The Archivist's Key", "Everything he hid is at the centre.", 46, 5100, 20, 22, 7, 9), "1111111111111111111110011101100011111100111111111111111111111", 2},
    {level("Tomas's Trail", "Follow the prints. Clear a path through the sand.", 34, 2800, 12, 15, 0, 0), "1111111111011111101111110011111100011111110111111111111111111", 1},
    {level("The Frozen Stair", "Thaw the stair, one flame at a time.", 38, 3400, 14, 16, 2, 8), "0011110111111111111111111000111110001111111011111111110111100", 2},
    {level("The Star Road", "Five in a line forge a prism. Aim it well.", 39, 3700, 15, 16, 5, 5), "1101111111101111101111111111111111011111111011111011111111011", 1},
    {level("Noon Shadow", "Dig where the shadow falls.", 40, 3900, 16, 20, 4, 5), "0111001111001111100111111001111111001111110011111001111000110", 2},
    {level("Smoke on the Water", "Moves are short. Every swap has to count.", 36, 4000, 16, 18, 6, 6), "0111110111111011111111111111111111011111111111101111110111110", 2},
    {level("The Jade Deep", "Open the spring beneath the frost.", 42, 4300, 17, 20, 4, 9), "1000101111001111100111111001111111101111110011111001111010001", 2},
    {level("Six Sun Gates", "Six gates, one seal. Clear them in any order.", 44, 4600, 18, 20, 7, 8), "1111111111111111101111100011111100011111100111111111111111111", 2},
    {level("The Last Terrace", "Run. The board is on your side this time.", 44, 3200, 13, 13, 2, 4), "1111111111111111111111111111111111101111111111111111111111111", 1},
    {level("The Silent Temple", "Every blocker in the valley guards this floor.", 46, 5200, 20, 23, 8, 10), "1101111111101111101111111011111111111111111011111011111111011", 2},
    {level("The Song Returns", "Clear the way to the socket.", 48, 5500, 22, 24, 8, 10), "1111111111111111110011111100011111100011111011111111111111111", 2},
}
for i, entry in ipairs(later) do
    local l = entry[1]
    l.mask, l.ice_layers = entry[2], entry[3]
    l.terrain = terrain[(i - 1) % 10 + 1]
    l.background = (i <= 5 or (i > 10 and i <= 15)) and 1 or 2
    levels[#levels + 1] = l
    shapes[#shapes + 1] = l.name
end

return {levels=levels, shapes=shapes, wonder_levels={1,4,7,9,13,16,19,23,26,29}}
