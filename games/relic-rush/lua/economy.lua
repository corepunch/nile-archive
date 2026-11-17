-- Three wallet slots. Score-only pieces have no wallet yield.
local E = {
    GOLD=1, PROVISIONS=2, SUPPLIES=3,
    CLEARED=4,   -- boards cleared: a counter in the purse's fourth slot, which opens regions and decorations
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
    -- Boards spawn five kinds, as in Cradle of Rome. The green apple's slot
    -- (1 Food, never upgraded) carries the bonus gem, a story item or a score
    -- piece; the red slot takes the bonus when a story item holds it.
    SPECIAL_KIND=2, SPECIAL_FALLBACK=1,
    CAMPAIGN_VERSION=6,
}
-- Presentation order is independent of the persisted purse slots.
E.currency_order = {E.GOLD, E.SUPPLIES, E.PROVISIONS}

E.silver_coin = {key="silver-coin", name="Silver coins", kind=0, slot=E.GOLD, amount=3, first_level=3}

E.BONUS_THRESHOLD = 36
E.bonus_slots = {
    {key="blast", levels={
        {key="hammer", name="Hammer", action="hit", effect="Tap a cell to hit it once."},
        {key="dynamite", name="Dynamite", action="blast", effect="Tap a cell to hit it and its neighbors."},
    }},
    {key="sweep", levels={
        {key="shield", name="Shield", action="row", effect="Tap a cell to hit the row through it."},
        {key="lightning", name="Lightning", action="row_lightning",
            effect="Tap a cell to hit its row and scatter strikes across up to 20 cells total."},
    }},
    {key="star", levels={
        {key="star", name="Star", action="color", effect="Tap a piece to hit every piece of that kind."},
        {key="star-ii", name="Star II", action="color_pierce", art="star",
            effect="Tap a piece to hit its kind through one layer of chain or ice."},
    }},
    {key="recharge", levels={
        {key="plus", name="Plus", action="charge", charge_divisor=4,
            effect="Tap to add a quarter charge to your other unlocked bonuses."},
        {key="plus-ii", name="Plus II", action="charge", art="plus", charge_divisor=2,
            effect="Tap to add half a charge to your other unlocked bonuses."},
    }},
}
local B = {}
for tool, slot in ipairs(E.bonus_slots) do
    for rank, bonus in ipairs(slot.levels) do
        bonus.tool, bonus.rank, bonus.amount = tool, rank, 6
        bonus.icon = "bonus-" .. (bonus.art or bonus.key)
        B[bonus.key] = bonus
    end
end
E.bonuses = B

-- The campaign ladder, in purchase order, after Cradle of Rome's 20
-- constructions. Most buildings add a resource or bonus piece. `building`
-- is the catalogue key. The ten story restorations hold the next new
-- expedition; the other ten must be placed before the next story restoration.
-- backdrop is the board painting the restored building brings: 1 lagoon, 2 temple.
E.unlocks = {
    {building="camp", backdrop=1, first_level=2, bonus=B.hammer},
    {building="well", key="water", backdrop=1, name="Water buckets", kind=3, slot=E.PROVISIONS, amount=3, first_level=5},
    {building="log_cabin", first_level=8, bonus=B.dynamite},
    {building="workshop", key="cut-blocks", backdrop=1, name="Cut blocks", kind=4, slot=E.SUPPLIES, amount=5, first_level=8},
    {building="water_mill", first_level=10},
    {building="quay_steps", first_level=11},
    {building="market", key="rations", name="Ration jars", kind=1, slot=E.PROVISIONS, amount=4, first_level=11, optional=true},
    {building="clock_tower", first_level=12, bonus=B.star},
    {building="amphitheater", first_level=14, bonus=B.shield},
    {building="gateway", key="helmet", backdrop=2, name="Helmets", kind=0, slot=E.GOLD, amount=6, first_level=14},
    {building="lodge", key="grain", backdrop=1, name="Grain bundles", kind=1, slot=E.PROVISIONS, amount=5, first_level=17},
    {building="trading_post", key="ring", name="Rings", kind=0, slot=E.GOLD, amount=7, first_level=18},
    {building="lighthouse", first_level=20, bonus=B.lightning},
    {building="archive", key="quartz", backdrop=2, name="Carved quartz", kind=4, slot=E.SUPPLIES, amount=7, first_level=20},
    {building="beached_ship", key="scarab", name="Scarabs", kind=0, slot=E.GOLD, amount=8, first_level=21},
    {building="map_room", first_level=23, bonus=B.plus},
    {building="observatory", backdrop=2, first_level=24, bonus=B["star-ii"]},
    {building="aviary", key="sandal", name="Sandals", kind=0, slot=E.GOLD, amount=9, first_level=25},
    {building="fountain", key="shrimp", backdrop=1, name="Shrimp", kind=3, slot=E.PROVISIONS, amount=6, first_level=27},
    {building="museum", key="harp", name="Harps", kind=0, slot=E.GOLD, amount=10, first_level=28, bonus=B["plus-ii"]},
    {building="temple", key="emerald", backdrop=2, name="Emeralds", kind=0, slot=E.GOLD, amount=11, first_level=30},
}
-- A restoration is placed after the clear before its first board.
for _, unlock in ipairs(E.unlocks) do
    unlock.after = unlock.first_level - 1
    if unlock.bonus then unlock.bonus.first_level = unlock.first_level end
end

function E.unlock_of(building)
    for _, unlock in ipairs(E.unlocks) do
        if unlock.building == building then return unlock end
    end
end

function E.unlock_text(unlock, amount)
    return ("%s earn +%d %s each."):format(unlock.name, amount or unlock.amount, E.currencies[unlock.slot].name)
end

function E.building_unlock_text(unlock)
    local bonus = unlock.bonus
    if not bonus then return unlock.name end
    local gems = bonus.rank == 1 and bonus.name .. " gems" or bonus.name
    return unlock.name and unlock.name .. " and " .. gems or gems
end

function E.bonus_lesson(bonus)
    if bonus.rank == 2 then
        local first = E.bonus_slots[bonus.tool].levels[1]
        return ("%s upgrades %s and keeps its charge."):format(bonus.name, first.name)
    end
    return "Match " .. bonus.name .. " gems to charge the bonus."
end

function E.active_bonus_slots(number, restored)
    local slots, meter = {}, {}
    for tool, slot in ipairs(E.bonus_slots) do slots[tool] = slot.levels[1] end
    for _, unlock in ipairs(E.unlocks) do
        local bonus = unlock.bonus
        if bonus and restored and restored[unlock.building] and (not restored.preview or number >= unlock.first_level) then
            local tool = bonus.tool
            slots[tool] = bonus
            meter[tool] = restored.bonus_charge and restored.bonus_charge[tool] or 0
        end
    end
    return slots, meter
end

function E.board_loadout(level, number, restored, seed)
    local yields, available = {}, {}
    local slots, meter = E.active_bonus_slots(number, restored)
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
        if number >= unlock.first_level and restored and restored[unlock.building] and unlock.kind and yields[unlock.kind] then
            yields[unlock.kind] = unlock
        end
    end
    for tool, slot in ipairs(E.bonus_slots) do
        if meter[tool] and number >= slot.levels[1].first_level then
            local bonus = slots[tool]
            available[#available + 1] = bonus
            if number == bonus.first_level then debut = bonus end
        end
    end
    local bonus = debut or (#available > 0 and available[(seed or 1) % #available + 1])
    -- Use the special slot, or the red slot when a story item holds it.
    -- Give a newly unlocked resource (such as board 10's rations) its debut.
    local kind = level.goal_kind == E.SPECIAL_KIND and E.SPECIAL_FALLBACK or E.SPECIAL_KIND
    if not debut and yields[kind] and yields[kind].first_level == number then bonus = nil end
    if bonus then yields[kind] = bonus end
    return yields, {match_only_resources=true, tool_threshold=E.BONUS_THRESHOLD, tool_meter=meter,
        tool_slots=slots, single_charge_tools=true}, bonus, debut
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
