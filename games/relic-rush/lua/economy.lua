-- Three wallet slots. Score-only pieces have no wallet yield.
-- Every piece has a Cradle of Rome 2 counterpart with the same wallet and
-- yield (docs/cradle-of-rome-reference/gem-correspondence.html).
local E = {
    GOLD=1, PROVISIONS=2, SUPPLIES=3,
    CLEARED=4,   -- boards cleared: a counter in the purse's fourth slot, which opens regions and decorations
    currencies={
        {key="coins", name="Coins"},
        {key="food", name="Food"},
        {key="supplies", name="Supplies"},
    },
    -- The opening pool, the five pieces of Cradle of Rome's first level: two
    -- coins that pay Coins and a leaf, a flower and an amphora that only
    -- score. Food and Supplies pieces come from restorations; each takes the
    -- slot of the piece below it (E.unlocks, `kind`).
    pieces={
        [0]={key="coin", name="Sun coin", slot=1, amount=5},
        {key="silver-coin", name="Silver coins", slot=1, amount=3},
        {key="leaf", name="Leaf"},
        {key="flower", name="Flower"},
        {key="amphora", name="Amphora"},
    },
    WELL_KIND=1, WORKSHOP_KIND=2,
    -- Boards spawn five kinds, as in Cradle of Rome. The leaf's slot carries
    -- the bonus gem or a story item; the silver slot takes the bonus when a
    -- story item holds the leaf's.
    SPECIAL_KIND=2, SPECIAL_FALLBACK=1,
    CAMPAIGN_VERSION=8,
}
-- Presentation order is independent of the persisted purse slots.
E.currency_order = {E.GOLD, E.SUPPLIES, E.PROVISIONS}

E.BONUS_THRESHOLD = 36
E.bonus_slots = {
    {key="impact", legacy_slot="blast", levels={
        {key="hammer", name="Hammer", action="hit", effect="Hit one cell."},
        {key="bomb", name="Bomb", action="blast", effect="Hit a cell and its six neighbors."},
    }},
    {key="shield", legacy_slot="sweep", levels={
        {key="shield", name="Shield", action="row", effect="Hit the row through a chosen cell."},
        {key="plus", name="Plus", action="replenish", resource_amount=100, effect="Choose a resource piece for 100 resources or another bonus to add a quarter charge."},
    }},
    {key="hourglass", legacy_slot="recharge", levels={
        {key="hourglass", name="Hourglass", action="moves", effect="Add five moves."},
        {key="mixer", name="Mixer", action="shuffle", effect="Shuffle the pieces."},
    }},
    {key="lightning", legacy_slot="star", levels={
        {key="lightning", name="Lightning", action="lightning", effect="Strike up to fifteen random cells."},
        {key="star", name="Star", action="color", effect="Clear all pieces of a chosen kind."},
    }},
}
local B = {}
for tool, slot in ipairs(E.bonus_slots) do
    for rank, bonus in ipairs(slot.levels) do
        bonus.tool, bonus.rank, bonus.amount = tool, rank, 6
        bonus.icon = "bonus-" .. bonus.key
        B[bonus.key] = bonus
    end
end
E.bonuses = B

-- The next-building card states each need as narration: who needs the
-- building and why. Characters speak in the scenes, which play once. Costs
-- and board unlocks come from the building catalogue and ladder.
E.quests = {
    well={title="Draw fresh water", request="Restore the well to bring water buckets onto the board."},
    log_cabin={title="Build the Hunter's Hut", request="The hunter brings a hammer. Match hammer pieces to charge it."},
    workshop={title="Open the Sawmill", request="The mill supplies timber for the village."},
    camp={title="Build the Village", request="The village unlocks bombs. Match them to charge a blast."},
}

-- The twenty purchases in the Windows sequel's epochs.xml. Stable catalogue keys
-- retain the island's original artwork and old saves. The eight bonus IDs use
-- their first-game identities. first_level sets the small board's pacing.
E.unlocks = {
    {building="well", rome="city_well", tile=5, first_level=2, backdrop=1, key="water", name="Water buckets", kind=3, slot=E.PROVISIONS, amount=3},
    {building="log_cabin", rome="city_hunter", tile=600, first_level=5, bonus=B.hammer},
    {building="workshop", rome="city_sawmill", tile=6, first_level=8, backdrop=1, key="timber", name="Timber bundles", kind=4, slot=E.SUPPLIES, amount=5},
    {building="camp", rome="city_village", tile=601, first_level=11, backdrop=1, bonus=B.bomb},
    {building="market", rome="city_farm", tile=7, first_level=12, key="rations", name="Ration jars", kind=1, slot=E.PROVISIONS, amount=4},
    {building="trading_post", rome="city_mine", tile=8, first_level=13, key="stone", name="Dressed stones", kind=4, slot=E.SUPPLIES, amount=7},
    {building="water_mill", rome="city_mill", tile=9, first_level=13, key="grain", name="Grain bundles", kind=1, slot=E.PROVISIONS, amount=5},
    {building="clock_tower", rome="city_thermae", tile=602, first_level=14, bonus=B.shield},
    {building="gateway", rome="city_port", tile=10, first_level=14, backdrop=2, key="shrimp", name="Shrimp", kind=3, slot=E.PROVISIONS, amount=6},
    {building="lodge", rome="city_oktavia", tile=603, first_level=17, backdrop=1, bonus=B.hourglass},
    {building="amphitheater", rome="city_coliseum", tile=11, first_level=18, key="helmet", name="Helmets", kind=0, slot=E.GOLD, amount=6},
    {building="map_room", rome="city_vestalki", tile=604, first_level=19, bonus=B.lightning},
    {building="archive", rome="city_aqueduct", tile=12, first_level=20, backdrop=2, key="ring", name="Rings", kind=0, slot=E.GOLD, amount=7},
    {building="lighthouse", rome="city_lighthouse", tile=605, first_level=21, bonus=B.plus},
    {building="beached_ship", rome="city_neron", tile=13, first_level=22, key="scarab", name="Scarabs", kind=0, slot=E.GOLD, amount=8},
    {building="observatory", rome="city_mausoleum", tile=606, first_level=24, backdrop=2, bonus=B.mixer},
    {building="aviary", rome="city_pantheon", tile=14, first_level=25, key="sandal", name="Sandals", kind=0, slot=E.GOLD, amount=9},
    {building="museum", rome="city_theatre", tile=15, first_level=26, key="harp", name="Harps", kind=0, slot=E.GOLD, amount=10},
    {building="temple", rome="city_forum", tile=607, first_level=27, backdrop=2, bonus=B.star},
    {building="fountain", rome="city_center", tile=16, first_level=30, backdrop=1, key="emerald", name="Emeralds", kind=0, slot=E.GOLD, amount=11},
}
-- A restoration is placed after the clear before its first board.
for _, unlock in ipairs(E.unlocks) do
    unlock.after = unlock.after or unlock.first_level - 1
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
    local gems = bonus.name .. " gems"
    return unlock.name and unlock.name .. " and " .. gems or gems
end

function E.bonus_lesson(bonus)
    if bonus.rank == 2 then
        local first = E.bonus_slots[bonus.tool].levels[1]
        return ("%s replaces %s and keeps its charge."):format(bonus.name, first.name)
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
    -- A slot is open unless the board omits it or a story item holds it.
    local function open(kind)
        return kind ~= level.omit_kind and not (level.story_piece and level.goal_kind == kind)
    end
    for kind, piece in pairs(E.pieces) do
        if piece.amount and open(kind) then yields[kind] = piece end
    end
    for _, unlock in ipairs(E.unlocks) do
        if number >= unlock.first_level and restored and restored[unlock.building] and unlock.kind and open(unlock.kind) then
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
