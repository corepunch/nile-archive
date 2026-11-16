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
    CAMPAIGN_VERSION=3,
}
-- Presentation order is independent of the persisted purse slots.
E.currency_order = {E.GOLD, E.SUPPLIES, E.PROVISIONS}

E.silver_coin = {key="silver-coin", name="Silver coins", kind=0, slot=E.GOLD, amount=3, first_level=3}

E.BONUS_THRESHOLD = 18
E.bonuses = {
    {key="hammer", name="Hammer", tool=1, effect="Tap a cell to hit it once."},
    {key="dynamite", name="Dynamite", tool=2, effect="Tap a cell to hit it and its neighbors."},
    {key="star", name="Star", tool=3, effect="Tap a piece to hit every piece of that kind."},
    {key="mixer", name="Shutter Gear", tool=4, effect="Tap the charged gear to shuffle loose pieces."},
    {key="shield", name="Shield", tool=5, effect="Tap a cell to hit the row through it."},
    {key="lightning", name="Lightning", tool=6, effect="Tap the charged bolt to strike up to 20 cells."},
}
for _, bonus in ipairs(E.bonuses) do bonus.amount = 3 end

-- Same order as the story catalogue and its stable city type IDs (zero-based).
-- backdrop is the board painting the restored building brings: 1 lagoon, 2 temple.
E.unlocks = {
    {backdrop=1, first_level=2, bonus=E.bonuses[2]},
    {key="water", backdrop=1, name="Water buckets", kind=3, slot=E.PROVISIONS, amount=3, first_level=5},
    {key="cut-blocks", backdrop=1, name="Cut blocks", kind=4, slot=E.SUPPLIES, amount=5, first_level=8, bonus=E.bonuses[1]},
    {key="rations", backdrop=1, name="Ration jars", kind=1, slot=E.PROVISIONS, amount=4, first_level=10, bonus=E.bonuses[4]},
    {key="helmet", backdrop=2, name="Helmets", kind=0, slot=E.GOLD, amount=6, first_level=14, bonus=E.bonuses[5], variants={
        {key="ring", name="Rings", kind=0, slot=E.GOLD, amount=7, first_level=18},
        {key="scarab", name="Scarabs", kind=0, slot=E.GOLD, amount=8, first_level=21},
        {key="sandal", name="Sandals", kind=0, slot=E.GOLD, amount=9, first_level=25},
        {key="harp", name="Harps", kind=0, slot=E.GOLD, amount=10, first_level=28},
    }},
    {key="grain", backdrop=1, name="Grain bundles", kind=1, slot=E.PROVISIONS, amount=5, first_level=17},
    {key="quartz", backdrop=2, name="Carved quartz", kind=4, slot=E.SUPPLIES, amount=7, first_level=20, bonus=E.bonuses[6]},
    {backdrop=2, first_level=24, bonus=E.bonuses[3]},
    {key="shrimp", backdrop=1, name="Shrimp", kind=3, slot=E.PROVISIONS, amount=6, first_level=27},
    {key="emerald", backdrop=2, name="Emeralds", kind=0, slot=E.GOLD, amount=11, first_level=30},
}

function E.unlock_text(unlock)
    return ("%s earn +%d %s each."):format(unlock.name, unlock.amount, E.currencies[unlock.slot].name)
end

function E.building_unlock_text(unlock)
    if unlock.bonus then
        local name = unlock.bonus.name .. " gems"
        return unlock.kind and (unlock.name .. " and " .. name) or name
    end
    return unlock.name
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
    for i, unlock in ipairs(E.unlocks) do
        local bonus = unlock.bonus
        if bonus and restored and restored[i - 1] and (not restored.preview or number >= unlock.first_level) then
            meter[bonus.tool] = restored.bonus_charge and restored.bonus_charge[bonus.tool] or 0
            order[#order + 1] = bonus.tool
        end
        if number >= unlock.first_level and restored and restored[i - 1] then
            if bonus then
                available[#available + 1] = bonus
                if number == unlock.first_level then debut = bonus end
            end
            if unlock.kind and yields[unlock.kind] then
                yields[unlock.kind] = unlock
                for _, variant in ipairs(unlock.variants or {}) do
                    if number >= variant.first_level then yields[variant.kind] = variant end
                end
            end
        end
    end
    local bonus = debut or (#available > 0 and available[(seed or 1) % #available + 1])
    if bonus then
        -- Reuse the score slot to keep the tuned six-kind board. The Mixer
        -- doubles as the story gear. Other finds in that slot take priority.
        local story_gear = level.story_piece == "gear" and bonus.key == "mixer"
        local kind = level.goal_kind == 5 and not story_gear and 1 or 5
        yields[kind] = bonus
    end
    return yields, {tool_threshold=E.BONUS_THRESHOLD, tool_meter=meter,
        tool_order=order, single_charge_tools=true}, bonus, debut
end

-- Like Cradle of Rome, the board shows the latest restoration in force on this
-- expedition (the same gate as its pieces); before any, the level's own scene.
function E.board_backdrop(level, number, restored)
    local backdrop = level.background
    for i, unlock in ipairs(E.unlocks) do
        if number >= unlock.first_level and restored and restored[i - 1] then backdrop = unlock.backdrop end
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
