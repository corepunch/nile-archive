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

-- Same order as the story catalogue and its stable city type IDs (zero-based).
E.unlocks = {
    {key="dynamite", name="Dynamite", tool=2, amount=2, first_level=2, effect="Hits one cell and its neighbors."},
    {key="water", name="Water buckets", kind=3, slot=E.PROVISIONS, amount=3, first_level=5},
    {key="cut-blocks", name="Cut blocks", kind=4, slot=E.SUPPLIES, amount=5, first_level=8},
    {key="rations", name="Ration jars", kind=1, slot=E.PROVISIONS, amount=4, first_level=10},
    {key="helmet", name="Helmets", kind=0, slot=E.GOLD, amount=6, first_level=14, variants={
        {key="ring", name="Rings", kind=0, slot=E.GOLD, amount=7, first_level=18},
        {key="scarab", name="Scarabs", kind=0, slot=E.GOLD, amount=8, first_level=21},
        {key="sandal", name="Sandals", kind=0, slot=E.GOLD, amount=9, first_level=25},
        {key="harp", name="Harps", kind=0, slot=E.GOLD, amount=10, first_level=28},
    }},
    {key="grain", name="Grain bundles", kind=1, slot=E.PROVISIONS, amount=5, first_level=17},
    {key="quartz", name="Carved quartz", kind=4, slot=E.SUPPLIES, amount=7, first_level=20},
    {key="sunburst", name="Sunburst", tool=3, amount=2, first_level=24, effect="Hits every piece of the color you tap."},
    {key="shrimp", name="Shrimp", kind=3, slot=E.PROVISIONS, amount=6, first_level=27},
    {key="emerald", name="Emeralds", kind=0, slot=E.GOLD, amount=11, first_level=30},
}

function E.unlock_text(unlock)
    if unlock.tool then return ("%d %s charges per expedition."):format(unlock.amount, unlock.name) end
    return ("%s earn +%d %s each."):format(unlock.name, unlock.amount, E.currencies[unlock.slot].name)
end

function E.board_loadout(level, number, restored)
    local yields = {}
    local tools = {2, 0, 0}
    local score_pieces = level.score_pieces or {}
    for kind, piece in pairs(E.pieces) do
        if kind ~= level.omit_kind and not score_pieces[kind] and not (level.story_piece and level.goal_kind == kind) then
            yields[kind] = piece
        end
    end
    local silver = E.silver_coin
    if number == silver.first_level and yields[silver.kind] then yields[silver.kind] = silver end
    for i, unlock in ipairs(E.unlocks) do
        if number >= unlock.first_level and restored and restored[i - 1] then
            if unlock.tool then tools[unlock.tool] = unlock.amount
            elseif yields[unlock.kind] then
                yields[unlock.kind] = unlock
                for _, variant in ipairs(unlock.variants or {}) do
                    if number >= variant.first_level then yields[variant.kind] = variant end
                end
            end
        end
    end
    return yields, tools
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
