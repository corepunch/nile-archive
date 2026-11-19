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
        {name="Gold bell coin", slot=1, amount=5},
        {name="Bundled pine", slot=3, amount=5},
        {name="Farrier's hammer"},
        {name="Toy blocks", slot=1, amount=6},
        {name="Gingerbread man", slot=2, amount=4},
        {name="Mulled wine", slot=2, amount=3},
        {name="Wrapped gift", slot=1, amount=7},
        {name="Candle lantern"},
        {name="Hot cocoa", slot=2, amount=5},
        {name="Dressed stone", slot=3, amount=7},
        {name="Ice pendant", slot=1, amount=8},
        {name="Glass bauble", slot=1, amount=9},
        {name="Candy cane"},
        {name="Pretzel", slot=2, amount=6},
        {name="Ceramic snowman", slot=1, amount=10},
        {name="Carved reindeer", slot=1, amount=11},
        {name="Santa hat", slot=1, amount=12},
        {name="Winter vase"},
        {name="Smoked trout", slot=2, amount=7},
    },
    CAMPAIGN_VERSION=6,
    BONUS_THRESHOLD=bonuses.THRESHOLD,
    SPECIAL_KIND=0,
}

local B
E.bonus_slots, B = bonuses.slots{
    hammer={icon="booster-hammer", frame="market-5", name="Farrier's hammer"},
    bomb={icon="booster-firework", frame="booster-firework-icon", name="Firework Bomb"},
    shield={icon="booster-shield", frame="booster-shield-icon", name="Frost shield"},
    plus={icon="booster-plus", frame="booster-plus-icon", name="Wish cross"},
    hourglass={icon="booster-hourglass", frame="booster-hourglass-icon"},
    mixer={icon="booster-mixer", frame="booster-mixer-icon", name="Wind-up top"},
    lightning={icon="booster-lantern", frame="market-10", name="Candle lantern"},
    star={icon="booster-star", frame="booster-star-icon"},
}
E.bonuses = B

-- The five positions start green, blue, silver, gold and red.
local BASE = {0, 1, 2, 3, 15}

-- Building keys and clear gates are campaign data. The engine manages bonus
-- ranks and their charges. Material and treat pieces replace their palette line.
E.unlocks = {
    {building="arch", after=1, line=5, kind=8},
    {building="reindeer_stable", after=2, bonus=B.hammer, line=2, kind=20},
    {building="lumber", after=4, line=2, kind=4},
    {building="gingerbread_house", after=5, bonus=B.bomb},
    {building="bakery", after=7, line=5, kind=7},
    {building="chapel", after=8, line=2, kind=12},
    {building="cocoa", after=9, line=5, kind=11},
    {building="santa_workshop", after=11, bonus=B.shield},
    {building="toys", after=13, line=4, kind=6},
    {building="post_office", after=14, bonus=B.hourglass},
    {building="gifts", after=16, line=4, kind=9, bonus=B.plus},
    {building="log_cabin", after=17, line=5, kind=16},
    {building="candles", after=19, bonus=B.lightning},
    {building="igloo", after=21, line=4, kind=13},
    {building="carousel", after=23, bonus=B.mixer, income=purse(0, 30, 0)},
    {building="sleigh", after=24, bonus=B.star, line=5, kind=21},
    {building="giant_ornament", after=25, line=4, kind=14},
    {building="rink", after=26, line=4, kind=17},
    {building="presents", after=27, line=4, kind=18},
    {building="tree", after=29, line=4, kind=19},
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
    local income = purse()
    for _, unlock in ipairs(E.unlocks) do
        if restored[unlock.building] and number >= unlock.first_level then
            if unlock.kind then kinds[unlock.line] = unlock.kind end
            if unlock.income then income = income + unlock.income end
        end
    end
    local yields = {}
    for _, kind in ipairs(kinds) do
        local piece = E.pieces[kind]
        if piece.amount then yields[kind] = piece end
    end
    local loadout = bonuses.loadout(number, restored, seed, E.bonus_slots, E.unlocks, yields, E.SPECIAL_KIND)
    loadout.kinds, loadout.win_income = kinds, income
    return yields, loadout
end

return E
