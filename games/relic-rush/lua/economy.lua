local bonuses = require("match3.bonuses")

-- Three wallet slots. Score-only pieces have no wallet yield.
-- The sequel sets the construction order. The amphora is an opening score piece.
local E = {
    GOLD=1, PROVISIONS=2, SUPPLIES=3,
    CLEARED=4,   -- boards cleared: a counter in the purse's fourth slot, which opens regions and decorations
    currencies={
        {key="coins", name="Coins"},
        {key="food", name="Food"},
        {key="supplies", name="Supplies"},
    },
    pieces={
        [0]={key="coin", name="Sun coin", slot=1, amount=5},
        {key="silver-coin", name="Silver coins", slot=1, amount=3},
        {key="leaf", name="Leaf"},
        {key="flower", name="Flower"},
        {key="amphora", name="Amphora"},
    },
    WELL_KIND=1, WORKSHOP_KIND=2,
    -- The bonus piece takes the leaf's slot.
    SPECIAL_KIND=2,
    CAMPAIGN_VERSION=9,
}
-- Presentation order is independent of the persisted purse slots.
E.currency_order = {E.GOLD, E.SUPPLIES, E.PROVISIONS}

E.BONUS_THRESHOLD = bonuses.THRESHOLD
local B
E.bonus_slots, B = bonuses.slots()
E.bonuses = B

-- The twenty purchases in the Windows sequel's epochs.xml. Stable catalogue keys
-- retain the island's original artwork and old saves. The eight bonus IDs use
-- their first-game identities. One purchase opens every five expeditions,
-- four to each of the five epochs; first_level is the first board it supplies.
E.unlocks = {
    {building="well", rome="city_well", tile=5, first_level=2, backdrop=1, key="water", name="Water buckets", kind=3, slot=E.PROVISIONS, amount=3},
    {building="log_cabin", rome="city_hunter", tile=600, first_level=7, bonus=B.hammer},
    {building="workshop", rome="city_sawmill", tile=6, first_level=12, backdrop=1, key="timber", name="Timber bundles", kind=4, slot=E.SUPPLIES, amount=5},
    {building="camp", rome="city_village", tile=601, first_level=17, backdrop=1, bonus=B.bomb},
    {building="market", rome="city_farm", tile=7, first_level=22, key="rations", name="Ration jars", kind=1, slot=E.PROVISIONS, amount=4},
    {building="trading_post", rome="city_mine", tile=8, first_level=27, key="stone", name="Dressed stones", kind=4, slot=E.SUPPLIES, amount=7},
    {building="water_mill", rome="city_mill", tile=9, first_level=32, key="grain", name="Grain bundles", kind=1, slot=E.PROVISIONS, amount=5},
    {building="clock_tower", rome="city_thermae", tile=602, first_level=37, bonus=B.shield},
    {building="gateway", rome="city_port", tile=10, first_level=42, backdrop=2, key="shrimp", name="Shrimp", kind=3, slot=E.PROVISIONS, amount=6},
    {building="lodge", rome="city_oktavia", tile=603, first_level=47, backdrop=1, bonus=B.hourglass},
    {building="amphitheater", rome="city_coliseum", tile=11, first_level=52, key="helmet", name="Helmets", kind=0, slot=E.GOLD, amount=6},
    {building="map_room", rome="city_vestalki", tile=604, first_level=57, bonus=B.lightning},
    {building="archive", rome="city_aqueduct", tile=12, first_level=62, backdrop=2, key="ring", name="Rings", kind=0, slot=E.GOLD, amount=7},
    {building="lighthouse", rome="city_lighthouse", tile=605, first_level=67, bonus=B.plus},
    {building="beached_ship", rome="city_neron", tile=13, first_level=72, key="scarab", name="Scarabs", kind=0, slot=E.GOLD, amount=8},
    {building="observatory", rome="city_mausoleum", tile=606, first_level=77, backdrop=2, bonus=B.mixer},
    {building="aviary", rome="city_pantheon", tile=14, first_level=82, key="sandal", name="Sandals", kind=0, slot=E.GOLD, amount=9},
    {building="museum", rome="city_theatre", tile=15, first_level=87, key="harp", name="Harps", kind=0, slot=E.GOLD, amount=10},
    {building="temple", rome="city_forum", tile=607, first_level=92, backdrop=2, bonus=B.star},
    {building="fountain", rome="city_center", tile=16, first_level=97, backdrop=1, key="emerald", name="Emeralds", kind=0, slot=E.GOLD, amount=11},
}
bonuses.index_unlocks(E.unlocks)

function E.unlock_of(building)
    for _, unlock in ipairs(E.unlocks) do
        if unlock.building == building then return unlock end
    end
end

function E.unlock_text(unlock, amount)
    return ("%s earn +%d %s each."):format(unlock.name, amount or unlock.amount, E.currencies[unlock.slot].name)
end

function E.building_unlock_text(unlock)
    return unlock.bonus and unlock.bonus.name or unlock.name
end

function E.bonus_lesson(bonus)
    if bonus.rank == 2 then
        local first = E.bonus_slots[bonus.tool].levels[1]
        return ("%s replaces %s and keeps its charge."):format(bonus.name, first.name)
    end
    return ("Match %d %s pieces for one charge."):format(E.BONUS_THRESHOLD // bonus.amount, bonus.name)
end

function E.board_loadout(number, restored, seed)
    local yields = {}
    for kind, piece in pairs(E.pieces) do
        if piece.amount then yields[kind] = piece end
    end
    for _, unlock in ipairs(E.unlocks) do
        if number >= unlock.first_level and restored and restored[unlock.building] and unlock.kind then
            yields[unlock.kind] = unlock
        end
    end
    return yields, bonuses.loadout(number, restored, seed, E.bonus_slots, E.unlocks, yields, E.SPECIAL_KIND)
end

-- Like Cradle of Rome, the board shows the latest restoration in force on this
-- expedition (the same gate as its pieces); before any, the level's own scene.
function E.board_backdrop(level, number, restored)
    local backdrop = level.background
    for _, unlock in ipairs(E.unlocks) do
        if unlock.backdrop and number >= unlock.first_level and restored and restored[unlock.building] then
            backdrop = unlock.backdrop
        end
    end
    return backdrop
end

function E.shortfall(cost, available)
    local missing = purse()
    for slot in ipairs(E.currencies) do missing[slot] = math.max(0, cost[slot] - available[slot]) end
    return missing
end

function E.price_parts(cost)
    local parts = {}
    for _, slot in ipairs(E.currency_order) do
        if cost[slot] > 0 then
            parts[#parts+1] = {slot=slot, name=E.currencies[slot].name, amount=cost[slot]}
        end
    end
    return parts
end

return E
