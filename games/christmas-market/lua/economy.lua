local bonuses = require("match3.bonuses")

-- Wallet slots are save data: Tokens, Treats, Materials.
local E = {
    GOLD=1, FOOD=2, SUPPLIES=3,
    CLEARED=4,   -- boards cleared: a counter in the purse's fourth slot, which opens regions and decorations
    currencies={
        {name="Tokens", kind=3},
        {name="Treats", kind=11},
        {name="Materials", kind=4},
    },
    pieces={
        [0]={name="Snow-dusted fir"},
        {name="Knitted mitten"},
        {name="Silver snowflake coin", slot=1, amount=3},
        {name="Sun coin", slot=1, amount=5},
        {name="Bundled pine", slot=3, amount=5},
        {name="Reindeer"},
        {name="Toy blocks", slot=1, amount=6},
        {name="Gingerbread man", slot=2, amount=4},
        {name="Mulled wine", slot=2, amount=3},
        {name="Wrapped gift", slot=1, amount=7},
        {name="Candle lantern"},
        {name="Hot cocoa", slot=2, amount=5},
        {name="Dressed stone", slot=3, amount=7},
        {name="Ice pendant"},
        {name="Glass bauble", slot=1, amount=8},
        {name="Candy cane"},
        {name="Pretzel"},
        {name="Ice skates", slot=1, amount=9},
        {name="Carved reindeer", slot=1, amount=10},
        {name="Santa hat", slot=1, amount=11},
        {name="Winter vase"},
        {name="Smoked trout", slot=2, amount=6},
    },
    CAMPAIGN_VERSION=8,
    BONUS_THRESHOLD=bonuses.THRESHOLD,
    SPECIAL_KIND=0,
}

local B
E.bonus_slots, B = bonuses.slots{
    hammer={icon="booster-reindeer", frame="market-5", name="Reindeer", effect="Kick through one cell."},
    bomb={icon="booster-firework", frame="booster-firework-icon", name="Firework Bomb"},
    shield={icon="booster-shield", frame="booster-shield-icon", name="Frost shield"},
    plus={icon="booster-plus", frame="booster-plus-icon", name="Wish cross"},
    hourglass={icon="booster-clock", frame="booster-hourglass-icon", name="Station clock"},
    mixer={icon="booster-mixer", frame="booster-mixer-icon", name="Wind-up top"},
    lightning={icon="booster-lantern", frame="market-10", name="Candle lantern"},
    star={icon="booster-star", frame="booster-star-icon"},
}
E.bonuses = B

-- Fir, mitten, silver coin, gold coin and candy cane. The cane's slot becomes Treats.
local BASE = {0, 1, 2, 3, 15}

-- The twenty purchases follow Cradle of Rome 2's epochs.xml, one every five
-- wishes, four to each Advent (docs/market-pieces.md). Each building gives
-- what its stall sells: material and treat pieces replace their palette line.
-- Each purchase unlocks a single regular or charging piece in Rome's order.
E.unlocks = {
    {building="arch", after=1, line=5, kind=8},
    {building="reindeer_stable", after=6, bonus=B.hammer},
    {building="lumber", after=11, line=2, kind=4},
    {building="firework_stall", after=16, bonus=B.bomb},
    {building="bakery", after=21, line=5, kind=7},
    {building="chapel", after=26, line=2, kind=12},
    {building="cocoa", after=31, line=5, kind=11},
    {building="igloo", after=36, bonus=B.shield},
    {building="log_cabin", after=41, line=5, kind=21},
    {building="station_kiosk", after=46, bonus=B.hourglass},
    {building="toys", after=51, line=4, kind=6},
    {building="candles", after=56, bonus=B.lightning},
    {building="gifts", after=61, line=4, kind=9},
    {building="post_office", after=66, bonus=B.plus},
    {building="glassblower", after=71, line=4, kind=14},
    {building="carousel", after=76, bonus=B.mixer},
    {building="rink", after=81, line=4, kind=17},
    {building="santa_workshop", after=86, line=4, kind=18},
    {building="tree", after=91, bonus=B.star},
    {building="sleigh", after=96, line=4, kind=19},
}
bonuses.index_unlocks(E.unlocks)

function E.unlock_of(building)
    for _, unlock in ipairs(E.unlocks) do
        if unlock.building == building then return unlock end
    end
end

-- Replays keep the regular goods that belonged to their board number.
function E.board_loadout(number, restored, seed)
    local kinds = {table.unpack(BASE)}
    for _, unlock in ipairs(E.unlocks) do
        if unlock.kind and restored[unlock.building] and number >= unlock.first_level then
            kinds[unlock.line] = unlock.kind
        end
    end
    local yields = {}
    for _, kind in ipairs(kinds) do
        local piece = E.pieces[kind]
        if piece.amount then yields[kind] = piece end
    end
    local loadout = bonuses.loadout(number, restored, seed, E.bonus_slots, E.unlocks, yields, E.SPECIAL_KIND)
    loadout.kinds = kinds
    return yields, loadout
end

return E
