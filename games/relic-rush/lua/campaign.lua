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

local levels = {
    (function()
        local l = level("First Light", "Match 3 in a row.", 24, 1100, 8, 0, 0, 0)
        l.mask = "0011101111111111111111111111111111111111111111111111111111111"
        l.terrain = seam(1, 0, 0, 0, 1)
        l.ice_layers = 1
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("The Jade Crescent", "Match 4 for a sun ray.", 29, 1800, 10, 7, 0, 0)
        l.mask = "0001100111101111111111111111111111111111111111111111111111111"
        l.terrain = seam(0, 1, -1, 1, 0)
        l.ice_layers = 1
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("Sunstone Spiral", "Dig along the seam.", 32, 2300, 12, 12, 0, 0)
        l.mask = "1111011100111000111110011111110111111111111111111111111111111"
        l.terrain = seam(1, 1, 0, 1, 0)
        l.ice_layers = 1
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("The Vine Constellation", "Match to break chains.", 35, 2700, 12, 10, 4, 0)
        l.mask = "0011101111101111111111111111111111111111111111111111111011110"
        l.terrain = seam(1, 0, -1, 0, 1)
        l.ice_layers = 1
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("Three Paths Meet", "Rays cross gaps.", 35, 3100, 14, 13, 4, 0)
        l.mask = "1111011100111000111110011111110111111111111111111110111101111"
        l.terrain = seam(0, 1, 0, 1, 0)
        l.ice_layers = 1
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("Winter Lotus", "Match to break ice.", 37, 3400, 14, 13, 0, 5)
        l.mask = "0011111111111111111111101111111101111111111111111111111100111"
        l.terrain = seam(1, 1, 1, -1, 0)
        l.ice_layers = 1
        l.background = 2
        return l
    end)(),
    (function()
        local l = level("The Ember Ring", "Flames thaw nearby ice.", 40, 3800, 16, 15, 4, 5)
        l.mask = "0011101111111111111111111111110111111111111111111111111011100"
        l.terrain = seam(1, 0, 1, 0, -1)
        l.ice_layers = 2
        l.background = 2
        return l
    end)(),
    (function()
        local l = level("Prism Hollow", "Match 5 for a prism.", 40, 4200, 16, 17, 4, 6)
        l.mask = "1111011110011110001111001111110111111111111011111101111101111"
        l.terrain = seam(0, 1, -1, -1, 0)
        l.ice_layers = 2
        l.background = 2
        return l
    end)(),
    (function()
        local l = level("The Sixfold Seal", "Use rays across the seal.", 43, 4600, 18, 19, 5, 6)
        l.mask = "1101111001111001111111111111111111111111111111001111001111011"
        l.terrain = seam(1, 1, 0, 1, 0)
        l.ice_layers = 2
        l.background = 2
        return l
    end)(),
    (function()
        local l = level("Heart of the Hexagon", "Uncover the buried centre.", 46, 5000, 20, 22, 6, 6)
        l.mask = "0111011111111111111111111101110111011111111111111111111101110"
        l.terrain = seam(1, 0, 0, 0, -1)
        l.ice_layers = 2
        l.background = 2
        return l
    end)(),
    (function()
        local l = level("The Long Terrace", "Dig the long terrace.", 33, 2500, 12, 14, 0, 0)
        l.mask = "0111101111101111110111111101111111111111111111111111111111110"
        l.terrain = seam(0, 1, 1, 1, 0)
        l.ice_layers = 1
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("Twelve Crates", "Free chained relics.", 36, 2900, 13, 15, 5, 0)
        l.mask = "1111011111011111101111111011111111111111111111111111111100111"
        l.terrain = seam(1, 1, -1, -1, 0)
        l.ice_layers = 1
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("Names in the Stone", "Aim rays along the stone.", 37, 3200, 14, 16, 6, 0)
        l.mask = "0111100111100011111001011111111111111101111111111011111011110"
        l.terrain = seam(1, 0, 0, 0, 1)
        l.ice_layers = 1
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("Static", "Work around the broken seam.", 38, 3500, 14, 17, 7, 0)
        l.mask = "1011110011111001111111111111111111111111111111001111100111101"
        l.terrain = seam(0, 1, 1, -1, 0)
        l.ice_layers = 1
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("The Frost Line", "Clear chains and ice.", 39, 3700, 15, 18, 4, 6)
        l.mask = "0011101111111111111111111111111111011111110111111011111111111"
        l.terrain = seam(1, 1, 0, 1, 0)
        l.ice_layers = 1
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("Supper for Twelve", "Flames thaw nearby ice.", 40, 4000, 15, 18, 4, 7)
        l.mask = "1111011111011111111110111111101111111111111111111101111101111"
        l.terrain = seam(1, 0, -1, 0, -1)
        l.ice_layers = 2
        l.background = 2
        return l
    end)(),
    (function()
        local l = level("The Torn Log", "Some ice takes two hits.", 42, 4200, 16, 19, 5, 7)
        l.mask = "0001110011111001111110011111111111111111111111111111111100011"
        l.terrain = seam(0, 1, -1, 1, 0)
        l.ice_layers = 2
        l.background = 2
        return l
    end)(),
    (function()
        local l = level("Lantern Steps", "Clear the open terrace.", 40, 3000, 12, 12, 2, 4)
        l.mask = "0111011111111111111111111111111111111111111111111111111101110"
        l.terrain = seam(1, 1, 1, -1, 0)
        l.ice_layers = 1
        l.background = 2
        return l
    end)(),
    (function()
        local l = level("Under the Vines", "Dig beneath the locks.", 45, 4600, 18, 20, 6, 8)
        l.mask = "1111011110111110111111111111111110011111000111110011111011111"
        l.terrain = seam(1, 0, 1, 0, 1)
        l.ice_layers = 2
        l.background = 2
        return l
    end)(),
    (function()
        local l = level("The Archivist's Key", "Open the central approach.", 46, 5100, 20, 22, 7, 9)
        l.mask = "1011110011110001111100111111110111111111111111110111110111101"
        l.terrain = central_seam(0)
        l.ice_layers = 2
        l.background = 2
        return l
    end)(),
    (function()
        local l = level("Tomas's Trail", "Follow the buried seam.", 35, 2800, 12, 15, 0, 0)
        l.mask = "0111101111101111110111111111111111111111110111111011111111111"
        l.terrain = seam(1, 1, -1, 1, 0)
        l.ice_layers = 1
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("The Frozen Stair", "Thaw the frozen approach.", 40, 3400, 14, 16, 2, 8)
        l.mask = "1111011100111100011110001111111111111111111110111110111101111"
        l.terrain = seam(1, 0, -1, 0, 1)
        l.ice_layers = 2
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("The Star Road", "Choose a colour for the prism.", 40, 3700, 15, 16, 5, 5)
        l.mask = "0111101111101111111111111111110111111111111011111101111101111"
        l.terrain = seam(0, 1, 1, 1, 0)
        l.ice_layers = 1
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("Noon Shadow", "Excavate across the shadow.", 41, 3900, 16, 20, 4, 5)
        l.mask = "1101111001111000111111001111111111111111111111111111011111011"
        l.terrain = seam(1, 1, 1, -1, 0)
        l.ice_layers = 2
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("Smoke on the Water", "Work through the locks.", 38, 4000, 16, 18, 6, 6)
        l.mask = "0011110011110001111101111111111011111111111111111111110111100"
        l.terrain = seam(1, 0, 0, 0, -1)
        l.ice_layers = 2
        l.background = 1
        return l
    end)(),
    (function()
        local l = level("The Jade Deep", "Thaw the buried ground.", 43, 4300, 17, 17, 4, 7)
        l.mask = "1111011110111110111111111111110111111100111110001111001111011"
        l.terrain = central_seam(-1)
        l.ice_layers = 2
        l.background = 2
        return l
    end)(),
    (function()
        local l = level("Six Sun Gates", "Clear the scattered locks.", 45, 4600, 18, 20, 7, 8)
        l.mask = "0111011111111100111110001101111111011111111111111111111101110"
        l.terrain = seam(1, 1, 0, 1, 0)
        l.ice_layers = 2
        l.background = 2
        return l
    end)(),
    (function()
        local l = level("The Last Terrace", "Clear the open terrace.", 42, 3200, 13, 13, 2, 4)
        l.mask = "0011101111111111111111111111111111111111111111111111111111110"
        l.terrain = seam(1, 0, 1, 0, -1)
        l.ice_layers = 1
        l.background = 2
        return l
    end)(),
    (function()
        local l = level("The Silent Temple", "Dig through the temple floor.", 47, 5200, 20, 23, 8, 10)
        l.mask = "0111100111100011111001111111110111011111110111111011111111111"
        l.terrain = seam(0, 1, 0, 1, 0)
        l.ice_layers = 2
        l.background = 2
        return l
    end)(),
    (function()
        local l = level("The Song Returns", "Uncover the final approach.", 49, 5500, 22, 24, 8, 10)
        l.mask = "1011110011111001111100011111110111111111111111011111101111101"
        l.terrain = seam(1, 1, 0, -1, 0)
        l.ice_layers = 2
        l.background = 2
        return l
    end)(),
}

local shapes = {}
for i, l in ipairs(levels) do shapes[i] = l.name end

return {levels=levels, shapes=shapes, wonder_levels={1,4,7,9,13,16,19,23,26,29}}
