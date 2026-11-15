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
    water={key="water", name="Water bucket", slot=2, amount=1},
    WELL_KIND=1,
    CAMPAIGN_VERSION=1,
}

function E.board_yields(level, well_restored)
    local yields = {}
    for kind, piece in pairs(E.pieces) do
        if kind ~= level.omit_kind and not (level.story_piece and level.goal_kind == kind) then yields[kind] = piece end
    end
    if level.water_after_well and well_restored then yields[3] = E.water end
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
