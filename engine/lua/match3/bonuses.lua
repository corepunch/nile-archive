-- The four permanent slots for the square campaigns. A skin supplies the
-- name, image and optional targeting copy for each rank.
local B = {THRESHOLD=90}

local layout = {
    {key="impact", legacy_slot="blast", levels={
        {key="hammer", name="Hammer", action="hit", effect="Hit one cell."},
        {key="bomb", name="Bomb", action="blast", effect="Hit a 3×3 square around a cell."},
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
        {key="lightning", name="Lightning", action="lightning", hits=15, effect="Strike up to fifteen random cells."},
        {key="star", name="Star", action="color", effect="Clear all pieces of a chosen kind."},
    }},
}

function B.slots(skin)
    local slots, by_key = {}, {}
    for tool, slot in ipairs(layout) do
        local levels = {}
        for rank, descriptor in ipairs(slot.levels) do
            local bonus = {}
            for field, value in pairs(descriptor) do bonus[field] = value end
            local art = skin and skin[bonus.key] or {}
            bonus.tool, bonus.rank, bonus.amount = tool, rank, 3
            bonus.icon = art.icon or "bonus-" .. bonus.key
            bonus.frame = art.frame or bonus.icon
            bonus.name, bonus.effect = art.name or bonus.name, art.effect or bonus.effect
            levels[rank], by_key[bonus.key] = bonus, bonus
        end
        slots[tool] = {key=slot.key, levels=levels}
    end
    return slots, by_key
end

function B.index_unlocks(unlocks)
    for _, unlock in ipairs(unlocks) do
        unlock.after = unlock.after or unlock.first_level - 1
        unlock.first_level = unlock.first_level or unlock.after + 1
        if unlock.bonus then unlock.bonus.first_level = unlock.first_level end
    end
end

local function points(value)
    return math.max(0, math.min(math.floor(value or 0), B.THRESHOLD))
end

-- A confirmed upgrade replaces its predecessor in the same socket. On
-- earlier replays it keeps that artwork, while the first charging piece
-- still respects the original slot debut.
function B.loadout(number, restored, seed, slots, unlocks, yields, kind)
    restored = restored or {}
    local active, meter, available = {}, {}, {}
    local saved = restored.bonus_charge or {}
    for tool, slot in ipairs(slots) do active[tool] = slot.levels[1] end
    for _, unlock in ipairs(unlocks) do
        local bonus = unlock.bonus
        if bonus and restored[unlock.building] and (not restored.preview or number >= unlock.first_level) then
            local tool = bonus.tool
            active[tool], meter[tool] = bonus, points(saved[tool])
        end
    end
    local debut
    for tool, slot in ipairs(slots) do
        if meter[tool] and number >= slot.levels[1].first_level then
            local bonus = active[tool]
            available[#available + 1] = bonus
            if number == bonus.first_level then debut = bonus end
        end
    end
    local bonus = debut or (#available > 0 and available[(seed or 1) % #available + 1])
    if not debut and yields[kind] and yields[kind].first_level == number then bonus = nil end
    if bonus then yields[kind] = bonus end
    return {tool_threshold=B.THRESHOLD, tool_meter=meter, tool_slots=active, match_only_resources=true,
        bonus=bonus, bonus_debut=debut, bonus_preview=restored.preview, loadout_seed=seed}
end

-- Both games write the same keyed slots. Older formats translate in the
-- campaign that shipped them, then enter the common one-use clamp.
function B.serialize(s, saved, migrate)
    local reading = save.is_reading(s)
    local out = {}
    for tool, slot in ipairs(layout) do
        local charge
        if reading and migrate then charge = migrate(tool, slot)
        else charge = s:int("bonus_slot_" .. slot.key, reading and 0 or saved and saved[tool] or 0) end
        out[tool] = points(charge)
    end
    return out
end

return B
