-- Three wallet slots. Score-only pieces have no wallet yield.
local E = {
    GOLD=1, PROVISIONS=2, SUPPLIES=3, STARS=4,
    currencies={
        {key="coins", name="Coins"},
        {key="food", name="Food"},
        {key="supplies", name="Supplies"},
    },
    pieces={
        [0]={key="coin", name="Sun coin", slot=1, amount=4},
        {key="berries", name="Red berries", slot=2, amount=1},
        {key="apple", name="Green apple", slot=2, amount=1},
        {key="timber", name="Timber", slot=3, amount=2},
        {key="stone", name="Dressed stone", slot=3, amount=3},
    },
    WELL_KIND=1, WORKSHOP_KIND=2,
    CAMPAIGN_VERSION=4,
}
-- Presentation order is independent of the persisted purse slots.
E.currency_order = {E.GOLD, E.SUPPLIES, E.PROVISIONS}

E.silver_coin = {key="silver-coin", name="Silver coins", kind=0, slot=E.GOLD, amount=3, first_level=3}

E.BONUS_THRESHOLD = 18
E.bonuses = {
    {key="hammer", name="Hammer", tool=1, effect="Tap a cell to hit it once."},
    {key="dynamite", name="Dynamite", tool=2, effect="Tap a cell to hit it and its neighbors."},
    {key="star", name="Star", tool=3, effect="Tap a piece to hit every piece of that kind."},
    {key="shield", name="Shield", tool=4, effect="Tap a cell to hit the row through it."},
    {key="lightning", name="Lightning", tool=5, effect="Tap the charged bolt to strike up to 20 cells."},
    {key="plus", name="Plus", tool=6, effect="Tap the charged Plus to half-charge your other bonuses."},
}
for _, bonus in ipairs(E.bonuses) do bonus.amount = 3 end

-- The campaign ladder, in purchase order, after Cradle of Rome's 20
-- constructions. Most buildings add a resource or bonus piece. `building`
-- is the catalogue key. The ten story restorations hold the next new
-- expedition; the other ten must be placed before the next story restoration.
-- backdrop is the board painting the restored building brings: 1 lagoon, 2 temple.
local B = E.bonuses
E.unlocks = {
    {building="camp", backdrop=1, first_level=2, bonus=B[2]},
    {building="well", key="water", backdrop=1, name="Water buckets", kind=3, slot=E.PROVISIONS, amount=3, first_level=5},
    {building="log_cabin", first_level=8, bonus=B[1]},
    {building="workshop", key="cut-blocks", backdrop=1, name="Cut blocks", kind=4, slot=E.SUPPLIES, amount=5, first_level=8},
    {building="water_mill", first_level=10},
    {building="market", key="rations", backdrop=1, name="Ration jars", kind=1, slot=E.PROVISIONS, amount=4, first_level=10},
    {building="clock_tower", first_level=12},
    {building="amphitheater", first_level=14, bonus=B[4]},
    {building="gateway", key="helmet", backdrop=2, name="Helmets", kind=0, slot=E.GOLD, amount=6, first_level=14},
    {building="lodge", key="grain", backdrop=1, name="Grain bundles", kind=1, slot=E.PROVISIONS, amount=5, first_level=17},
    {building="trading_post", key="ring", name="Rings", kind=0, slot=E.GOLD, amount=7, first_level=18},
    {building="lighthouse", first_level=20, bonus=B[5]},
    {building="archive", key="quartz", backdrop=2, name="Carved quartz", kind=4, slot=E.SUPPLIES, amount=7, first_level=20},
    {building="beached_ship", key="scarab", name="Scarabs", kind=0, slot=E.GOLD, amount=8, first_level=21},
    {building="map_room", first_level=23, bonus=B[6]},
    {building="observatory", backdrop=2, first_level=24, bonus=B[3]},
    {building="aviary", key="sandal", name="Sandals", kind=0, slot=E.GOLD, amount=9, first_level=25},
    {building="fountain", key="shrimp", backdrop=1, name="Shrimp", kind=3, slot=E.PROVISIONS, amount=6, first_level=27},
    {building="museum", key="harp", name="Harps", kind=0, slot=E.GOLD, amount=10, first_level=28},
    {building="temple", key="emerald", backdrop=2, name="Emeralds", kind=0, slot=E.GOLD, amount=11, first_level=30},
}
-- A restoration is placed after the clear before its first board.
for _, unlock in ipairs(E.unlocks) do unlock.after = unlock.first_level - 1 end

function E.unlock_of(building)
    for _, unlock in ipairs(E.unlocks) do
        if unlock.building == building then return unlock end
    end
end

function E.unlock_text(unlock)
    return ("%s earn +%d %s each."):format(unlock.name, unlock.amount, E.currencies[unlock.slot].name)
end

function E.building_unlock_text(unlock)
    return unlock.bonus and unlock.bonus.name .. " gems" or unlock.name
end

function E.bonus_lesson(bonus)
    return "Match " .. bonus.name .. " gems to charge the bonus."
end

function E.board_loadout(level, number, restored, seed)
    local yields, available, meter, order = {}, {}, {}, {}
    local debut
    local score_pieces = level.score_pieces or {}
    for kind, piece in pairs(E.pieces) do
        if kind ~= level.omit_kind and not score_pieces[kind] and not (level.story_piece and level.goal_kind == kind) then
            yields[kind] = piece
        end
    end
    local silver = E.silver_coin
    if number == silver.first_level and yields[silver.kind] then yields[silver.kind] = silver end
    for _, unlock in ipairs(E.unlocks) do
        local bonus = unlock.bonus
        local placed = restored and restored[unlock.building]
        if bonus then
            order[#order + 1] = bonus.tool
            if placed and (not restored.preview or number >= unlock.first_level) then
                meter[bonus.tool] = restored.bonus_charge and restored.bonus_charge[bonus.tool] or 0
            end
        end
        if number >= unlock.first_level and placed then
            if bonus then
                available[#available + 1] = bonus
                if number == unlock.first_level then debut = bonus end
            end
            if unlock.kind and yields[unlock.kind] then yields[unlock.kind] = unlock end
        end
    end
    local bonus = debut or (#available > 0 and available[(seed or 1) % #available + 1])
    -- Use the score slot or the red slot when a story item uses orange.
    -- Give a newly unlocked resource (such as board 10's rations) its debut.
    local kind = level.goal_kind == 5 and 1 or 5
    if not debut and yields[kind] and yields[kind].first_level == number then bonus = nil end
    if bonus then yields[kind] = bonus end
    return yields, {tool_threshold=E.BONUS_THRESHOLD, tool_meter=meter,
        tool_order=order, single_charge_tools=true}, bonus, debut
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
