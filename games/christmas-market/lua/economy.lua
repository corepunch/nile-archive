-- Wallet slots are save data. Prices are Gold, Food, Supplies.
local E = {
    GOLD=1, FOOD=2, SUPPLIES=3, STARS=4,
    currencies={
        {name="Gold", kind=3},
        {name="Food", kind=11},
        {name="Supplies", kind=4},
    },
    pieces={
        [0]={name="Holly"},
        {name="Mitten"},
        {name="Silver coin", slot=1, amount=3},
        {name="Gold coin", slot=1, amount=5},
        {name="Firewood", slot=3, amount=5},
        {name="Toy hammer", tool=1, amount=3},
        {name="Packing blocks", slot=3, amount=7},
        {name="Gingerbread", slot=2, amount=5},
        {name="Milk", slot=2, amount=3},
        {name="Winter apple", slot=2, amount=6},
        {name="Lantern star", tool=3, amount=3},
        {name="Cocoa", slot=2, amount=4},
    },
    -- The first eight shops follow Rome I's build-to-piece ladder.
    unlocks={4, 5, 6, 11, 8, 9, 10, 7},
}

local multipliers = {[3]=1, [4]=2, [5]=4, [6]=6, [7]=6, [8]=6, [9]=6}
local ordinary = {
    [0]={0, 1, 2, 3},
    {0, 1, 2, 3, 4},
    {0, 1, 2, 3, 4},
    {0, 1, 3, 4, 6},
    {0, 1, 3, 6, 11},
    {0, 3, 6, 8, 11},
    {0, 3, 6, 9, 11},
    {0, 3, 6, 9, 11},
    {0, 3, 6, 7, 9},
}

function E.loadout(built, number, seed)
    built = math.min(built, require("journey").earned(number - 1))
    local kinds = {table.unpack(ordinary[math.min(built, #ordinary)])}
    local meter = {}
    local charge_tool
    if built >= 2 then
        meter[1], charge_tool = 0, 1
        if built >= 7 then
            meter[3] = 0
            if number == 20 or seed % 2 == 0 then charge_tool = 3 end
        end
        kinds[#kinds + 1] = charge_tool == 1 and 5 or 10
    end
    local yields = {}
    for _, kind in ipairs(kinds) do
        local piece = E.pieces[kind]
        if piece.amount then yields[kind] = piece end
    end
    return yields, {kinds=kinds, multipliers=multipliers, tool_threshold=200, tool_meter=meter}
end

-- Rome I Beta lightning hits 15 cells and reserves one hit for a plaque.
-- The board seed determines the order so the aiming preview matches the hit.
function E.lightning_targets(g, cell, cells)
    local mask = {}
    local first = (g.rng + cell) % cells
    local count = 0
    for step = 0, cells - 1 do
        local i = (first + 13 * step) % cells
        if g.active[i] and g.oil[i] > 0 and g.chain[i] == 0 then
            mask[i], count = true, 1
            break
        end
    end
    for step = 0, cells - 1 do
        if count == 15 then break end
        local i = (first + 13 * step) % cells
        if g.active[i] and not mask[i] then mask[i], count = true, count + 1 end
    end
    return mask
end

function E.unlock_text(index)
    local piece = E.pieces[E.unlocks[index]]
    if not piece then return end
    local unit = piece.tool and "tool charge" or E.currencies[piece.slot].name
    return ("%s · +%d %s per piece"):format(piece.name, piece.amount, unit)
end

return E
