-- Three wallet slots, six regular pieces including the optional ration jar.
local E = {
    GOLD=1, PROVISIONS=2, SUPPLIES=3, STARS=4,
    currencies={
        {key="coin", name="Gold"},
        {key="berries", name="Provisions"},
        {key="timber", name="Supplies"},
    },
    pieces={
        [0]={key="coin", name="Sun coin", slot=1, amount=4},
        {key="berries", name="Red berries", slot=2, amount=1},
        {key="plantains", name="Green plantains", slot=2, amount=1},
        {key="timber", name="Blue-tied timber", slot=3, amount=1},
        {key="stone", name="Dressed stone", slot=3, amount=1},
        {key="rations", name="Ration jar", slot=2, amount=1},
    },
    WELL_KIND=1, WORKSHOP_KIND=2,
    CAMPAIGN_VERSION=1,
}

E.unlocks = {
    water={key="water", name="Water buckets", building=E.WELL_KIND, kind=3, slot=E.PROVISIONS, amount=1},
    ["cut-blocks"]={key="cut-blocks", name="Cut blocks", building=E.WORKSHOP_KIND, kind=4, slot=E.SUPPLIES, amount=1},
}

function E.unlock_text(piece)
    return ("%s earn +%d %s each."):format(piece.name, piece.amount, E.currencies[piece.slot].name)
end

function E.board_yields(level, restored)
    local yields = {}
    for kind, piece in pairs(E.pieces) do
        if kind ~= level.omit_kind and not (level.story_piece and level.goal_kind == kind) then yields[kind] = piece end
    end
    local piece = E.unlocks[level.resource_unlock]
    if piece and restored and restored[piece.building] and yields[piece.kind] then
        yields[piece.kind] = piece
    end
    return yields
end

function E.price_parts(cost)
    local parts = {}
    for slot, currency in ipairs(E.currencies) do
        if cost[slot] > 0 then
            parts[#parts+1] = {slot=slot, name=currency.name, amount=cost[slot]}
        end
    end
    return parts
end

return E
