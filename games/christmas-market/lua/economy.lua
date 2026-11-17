-- Wallet slots are save data. Prices are Gold, Food, Supplies.
local E = {
    GOLD=1, FOOD=2, SUPPLIES=3,
    CLEARED=4,   -- boards cleared: a counter in the purse's fourth slot, which opens regions and decorations
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
        -- Kinds 12-15 are Gold treasures and a Food piece from later stalls.
        {name="Golden bell", slot=1, amount=6},
        {name="Snowflake bauble", slot=1, amount=7},
        {name="Plum bauble", slot=1, amount=8},
        {name="Candy cane", slot=2, amount=7},
    },
    CAMPAIGN_VERSION=3,
}

E.tool_slots = {
    {icon="booster-hammer", action="hit", effect="Tap a cell to hit it with the Hammer."},
    {icon="booster-firework", action="blast", effect="Tap a cell to blast it and its neighbors."},
    {icon="booster-lantern", action="sunburst", effect="Tap a cell to strike across 15 cells."},
    {icon="booster-star", action="row", effect="Tap a cell to clear its row with Shooting Star."},
}

-- Every wish's five ordinary kinds sit on five lines; a stall's new piece
-- takes the place of the one below it on its line. The fifth line opens with
-- the arch's firewood.
local BASE = {0, 1, 2, 3}

-- The twenty-stall ladder after Cradle of Rome: each stall adds one piece or
-- one bonus, from the wish after it is placed. `building` is the catalogue
-- key and `after` the clear it opens on. Pieces name a `line`; tools charge
-- from their own `piece`; `opening_tool` grants one more use per wish of
-- that booster (a second stall for the same booster makes it two);
-- `moves` adds moves; `charge` speeds tool charge; `income` pays every win.
E.unlocks = {
    {building="arch", after=1, line=5, kind=4},
    {building="reindeer_stable", after=2, opening_tool=4, name="Shooting Star"},
    {building="lumber", after=4, tool=1, piece=5},
    {building="gingerbread_house", after=5, moves=3},
    {building="bakery", after=7, line=3, kind=6},
    {building="cocoa", after=9, line=5, kind=11},
    {building="santa_workshop", after=11, opening_tool=2, name="Firework Bomb"},
    {building="toys", after=13, line=2, kind=8},
    {building="post_office", after=14, charge=2},
    {building="gifts", after=16, line=2, kind=9},
    {building="log_cabin", after=17, line=2, kind=15},
    {building="candles", after=19, tool=3, piece=10},
    {building="chapel", after=20, line=4, kind=12},
    {building="igloo", after=21, line=4, kind=13},
    {building="carousel", after=23, line=5, kind=7},
    {building="sleigh", after=24, opening_tool=4, name="Shooting Star"},
    {building="giant_ornament", after=25, line=4, kind=14},
    {building="rink", after=26, income=purse(25, 0, 0)},
    {building="presents", after=27, income=purse(0, 0, 20)},
    {building="tree", after=29, opening_tool=2, name="Firework Bomb"},
}
for _, unlock in ipairs(E.unlocks) do unlock.first_level = unlock.after + 1 end

function E.unlock_of(building)
    for _, unlock in ipairs(E.unlocks) do
        if unlock.building == building then return unlock end
    end
end

local multipliers = {[3]=1, [4]=2, [5]=4, [6]=6, [7]=6, [8]=6, [9]=6}

-- `restored` maps building keys to true for the stalls placed. A wish uses
-- what was in force by its number: a replay keeps its own pool.
function E.loadout(restored, number, seed)
    local lines = {table.unpack(BASE)}
    local meter, tools, opening_tools, income = {}, {}, {}, purse()
    local moves, charge = 0, 1
    for _, unlock in ipairs(E.unlocks) do
        if restored[unlock.building] and number >= unlock.first_level then
            if unlock.kind then lines[unlock.line] = unlock.kind
            elseif unlock.tool then meter[unlock.tool], tools[#tools + 1] = 0, unlock
            elseif unlock.opening_tool then
                opening_tools[unlock.opening_tool] = (opening_tools[unlock.opening_tool] or 0) + 1
            elseif unlock.moves then moves = moves + unlock.moves
            elseif unlock.charge then charge = charge * unlock.charge
            elseif unlock.income then income = income + unlock.income end
        end
    end
    local kinds = {}
    for line = 1, 5 do if lines[line] then kinds[#kinds + 1] = lines[line] end end
    -- One tool charges per wish: the newest on its first wish, then by seed.
    local charging = tools[#tools]
    if #tools > 1 and number ~= charging.first_level and seed % 2 == 1 then charging = tools[1] end
    if charging then kinds[#kinds + 1] = charging.piece end
    local yields = {}
    for _, kind in ipairs(kinds) do
        local piece = E.pieces[kind]
        if piece.amount then yields[kind] = piece end
    end
    -- Faster charge lowers the meter a use needs; stored points convert with it.
    return yields, {kinds=kinds, multipliers=multipliers, tool_threshold=200 // charge, tool_meter=meter,
        tool_slots=E.tool_slots, opening_tools=opening_tools, charge_tool=charging and charging.tool,
        extra_moves=moves, win_income=income}
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

-- What a stall adds, for its card and the board's arrival notice.
function E.unlock_text(unlock)
    if unlock.kind or unlock.tool then
        local piece = E.pieces[unlock.kind or unlock.piece]
        local unit = piece.tool and "tool charge" or E.currencies[piece.slot].name
        return ("%s · +%d %s per piece"):format(piece.name, piece.amount, unit)
    elseif unlock.opening_tool then
        for _, earlier in ipairs(E.unlocks) do
            if earlier == unlock then break end
            if earlier.opening_tool == unlock.opening_tool then
                return ("A second %s booster per wish"):format(unlock.name)
            end
        end
        return ("One %s booster per wish"):format(unlock.name)
    elseif unlock.moves then return ("Every wish gets %d more moves"):format(unlock.moves)
    elseif unlock.charge then return "Tool pieces charge twice as fast"
    end
    local parts = {}
    for slot, currency in ipairs(E.currencies) do
        if unlock.income[slot] > 0 then parts[#parts + 1] = ("+%d %s"):format(unlock.income[slot], currency.name) end
    end
    return table.concat(parts, " ") .. " on every win"
end

return E
