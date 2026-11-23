local bonuses = require("match3.bonuses")
local l10n = require("l10n")
local tr = l10n.tr

-- Wallet slots are save data: Tokens, Treats, Materials. A currency's id names
-- its wallet capsule (game_config.lua capsules.show); its name is what the player reads.
local E = {
    GOLD=1, FOOD=2, SUPPLIES=3,
    CLEARED=4,   -- boards cleared: a counter in the purse's fourth slot, which opens regions and decorations
    currencies={
        {id="tokens", name=tr("Tokens"), frame="market-3"},
        {id="treats", name=tr("Treats"), frame="resource-wallet-food"},
        {id="materials", name=tr("Materials"), frame="resource-wallet-supplies"},
    },
    pieces={
        [0]={name=tr("Snow-dusted fir")},
        {name=tr("Knitted mitten")},
        {name=tr("Silver snowflake coin"), slot=1, amount=3},
        {name=tr("Sun coin"), slot=1, amount=5},
        {name=tr("Bundled pine"), slot=3, amount=5},
        {name=tr("Farrier's hammer")},
        {name=tr("Toy blocks"), slot=1, amount=6},
        {name=tr("Gingerbread man"), slot=2, amount=4},
        {name=tr("Mulled wine"), slot=2, amount=3},
        {name=tr("Wrapped gift"), slot=1, amount=7},
        {name=tr("Candle lantern")},
        {name=tr("Hot cocoa"), slot=2, amount=5},
        {name=tr("Dressed stone"), slot=3, amount=7},
        {name=tr("Ice pendant")},
        {name=tr("Glass bauble"), slot=1, amount=8},
        {name=tr("Candy cane")},
        {name=tr("Pretzel")},
        {name=tr("Ice skates"), slot=1, amount=9},
        {name=tr("Carved reindeer"), slot=1, amount=10},
        {name=tr("Santa hat"), slot=1, amount=11},
        {name=tr("Winter vase")},
        {name=tr("Smoked trout"), slot=2, amount=6},
    },
    CAMPAIGN_VERSION=8,
    BONUS_THRESHOLD=bonuses.THRESHOLD,
    SPECIAL_KIND=0,
}

local B
E.bonus_slots, B = bonuses.slots{
    hammer={icon="booster-hammer", frame="market-5", name=tr("Farrier's hammer")},
    bomb={icon="booster-firework", frame="booster-firework-icon", name=tr("Firework Bomb")},
    shield={icon="booster-shield", frame="booster-shield-icon", name=tr("Frost shield")},
    plus={icon="booster-plus", frame="booster-plus-icon", name=tr("Wish cross")},
    hourglass={icon="booster-clock", frame="booster-hourglass-icon", name=tr("Station clock")},
    mixer={icon="booster-mixer", frame="booster-mixer-icon", name=tr("Wind-up top")},
    lightning={icon="booster-lantern", frame="market-10", name=tr("Candle lantern")},
    star={icon="booster-star", frame="booster-star-icon"},
}
E.bonuses = B

-- Fir, mitten, silver coin, gold coin and candy cane. The cane's slot becomes Treats.
local BASE = {0, 1, 2, 3, 15}

-- Four purchases per Advent follow Cradle of Rome 2's epochs.xml.
-- The original wish milestones time the board rewards. Each building gives
-- what its stall sells: material and treat pieces replace their palette line.
-- Each purchase unlocks a single regular or charging piece in Rome's order.
E.unlocks = {
    {building="arch", after=1, line=5, kind=8, backdrop="welcome-arch"},
    {building="reindeer_stable", after=6, bonus=B.hammer, backdrop="reindeer-stable"},
    {building="lumber", after=11, line=2, kind=4, backdrop="lumber-workshop"},
    {building="firework_stall", after=16, bonus=B.bomb, backdrop="firework-stall"},
    {building="bakery", after=21, line=5, kind=7, backdrop="gingerbread-bakery"},
    {building="chapel", after=26, line=2, kind=12, backdrop="snowy-chapel"},
    {building="cocoa", after=31, line=5, kind=11, backdrop="hot-cocoa-kiosk"},
    {building="igloo", after=36, bonus=B.shield, backdrop="ice-house"},
    {building="log_cabin", after=41, line=5, kind=21, backdrop="lakeside-smokehouse"},
    {building="station_kiosk", after=46, bonus=B.hourglass, backdrop="station-kiosk"},
    {building="toys", after=51, line=4, kind=6, backdrop="toymakers-workshop"},
    {building="candles", after=56, bonus=B.lightning, backdrop="candlelight-shop"},
    {building="gifts", after=61, line=4, kind=9, backdrop="gift-wrapping-pavilion"},
    {building="post_office", after=66, bonus=B.plus, backdrop="north-pole-post-office"},
    {building="glassblower", after=71, line=4, kind=14, backdrop="glassblowers-stall"},
    {building="carousel", after=76, bonus=B.mixer, backdrop="reindeer-carousel"},
    {building="rink", after=81, line=4, kind=17, backdrop="winter-skating-rink"},
    {building="santa_workshop", after=86, line=4, kind=18, backdrop="woodcarvers-hall"},
    {building="tree", after=91, bonus=B.star, backdrop="christmas-tree"},
    {building="sleigh", after=96, line=4, kind=19, backdrop="santas-sleigh"},
}
bonuses.index_unlocks(E.unlocks)
E.opening_backdrop = "bellmere-opening"

function E.unlock_of(building)
    for _, unlock in ipairs(E.unlocks) do
        if unlock.building == building then return unlock end
    end
end

-- Use the latest confirmed construction for this wish's era.
function E.board_backdrop(number, restored)
    local backdrop = E.opening_backdrop
    for _, unlock in ipairs(E.unlocks) do
        if number >= unlock.first_level and restored[unlock.building] then
            backdrop = unlock.backdrop
        end
    end
    return backdrop
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
