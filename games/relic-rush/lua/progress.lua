local R = require("state")
local rules = require("rules")
local island = require("island")
local economy = require("economy")

function R.debug_fill_earnings(g)
    if g.level ~= R.prog.level then return end
    local level = g.level + 1
    local matched = purse(table.unpack(g.earnings))
    local cost = island.reserved_cost(R.island, level)
    local next_kind = island.next_step(R.island, level)
    if next_kind then
        local next_cost = island.buildings[next_kind + 1].cost
        if not cost:covers(next_cost) then cost = next_cost end
    end
    local needed = economy.shortfall(cost, R.prog.wallet + matched)
    for i = 1, #g.earnings do g.earnings[i] = g.earnings[i] + needed[i] end
end

-- Which ladder restorations are in force, by building key. A preview counts
-- every one unless --before-<key> names it.
function R.board_context(preview)
    local restored = {preview=preview, bonus_charge=not preview and R.prog and R.prog.bonus_charge}
    for _, unlock in ipairs(economy.unlocks) do
        local key = unlock.building
        if preview then
            restored[key] = not app.arg("before-" .. key)
        else
            restored[key] = island.owned(R.island, island.kinds[key]) > 0
        end
    end
    return restored
end

function R.update_bonus_charges()
    local g = R.g
    if g.bonus_preview or not g.single_charge_tools then return end
    local saved = R.prog.bonus_charge or {}
    local changed = false
    for tool, charge in pairs(g.tool_meter) do
        if (saved[tool] or 0) ~= charge then
            saved[tool], changed = charge, true
        end
    end
    if changed then
        R.prog.bonus_charge = saved
        R.save_progress()
    end
end

-- Apply restorations made while an unfinished board was parked on the island.
-- Existing tile kinds, charge and the position of every socket stay in place.
function R.refresh_board_bonuses()
    local g = R.g
    if not g.tool_slots or g.bonus_preview then return end
    local slots, meters = economy.active_bonus_slots(g.level + 1, R.board_context())
    for tool, charge in pairs(meters) do
        if g.tool_meter[tool] == nil then
            g.tool_meter[tool], g.tools[tool] = charge, charge // g.tool_threshold
        end
    end
    local bonus = g.bonus
    if bonus and slots[bonus.tool] ~= bonus then
        g.bonus, g.bonus_debut = slots[bonus.tool], nil
        for kind, reward in pairs(g.resource_yields) do
            if reward == bonus then g.resource_yields[kind] = g.bonus end
        end
    end
    g.tool_slots = slots
end

local function opening_unlock(g)
    local level = rules.level_of(g)
    for _, unlock in ipairs(economy.unlocks) do
        local building = island.buildings[island.kinds[unlock.building] + 1].name
        if g.bonus_debut and unlock.bonus == g.bonus_debut then
            local text = economy.bonus_lesson(g.bonus_debut)
            if unlock.kind and g.resource_yields[unlock.kind] == unlock then
                text = text .. " " .. economy.unlock_text(unlock)
            end
            return text, building
        elseif unlock.kind and (g.level + 1 == unlock.after + 1 or level.featured_resource == unlock.key) then
            if g.resource_yields and g.resource_yields[unlock.kind] == unlock then
                local amount = g.yield_amounts and g.yield_amounts[unlock.kind]
                return economy.unlock_text(unlock, amount), building
            end
        end
    end
    for _, piece in pairs(g.resource_yields or {}) do
        if g.level + 1 == piece.first_level then return economy.unlock_text(piece) end
    end
end

function R.board_lesson(g)
    local lesson, unlock = rules.level_of(g).lesson, opening_unlock(g)
    return unlock and lesson .. "\n" .. unlock or lesson
end

local present_board = R.present_board
function R.present_board()
    present_board()
    local g = R.g
    -- Arrivals through the museum's harps on board 28; the finale keeps its own opening.
    if (g.level < 28 or g.bonus_debut) and g.moves == rules.level_of(g).moves and not app.arg("mission") then
        local text, building = opening_unlock(g)
        if text then
            R.notice(building and building .. " · " .. text or text)
        end
    end
end

local serialize_completed = require("match3.game").bind_completed_rewards(R, rules)
function R.serialize_campaign(s)
    local reading = save.is_reading(s)
    local version = s:int("resource_version", reading and 0 or economy.CAMPAIGN_VERSION)
    -- Version 4 added the twenty-step ladder. Restorations an older save had
    -- already passed stay optional rather than holding its next expedition.
    island.serialize_waivers(s, R.island, R.prog.level, reading and version < 4)
    if reading and version < 7 then
        local c, p = R.island, R.prog
        local waived = island.waived(c)
        if version >= 4 then
            -- The old sixth position was the separately purchased quay.
            local mask = s:int("ladder_waived", 0)
            for n = 6, #island.ladder do waived[n] = mask & (1 << n) ~= 0 or nil end
        end
        if island.owned(c, island.kinds.workshop) > 0 or version < 6 and p.level >= 10 then
            island.restore_quay(c, 0)
            if island.owned(c, island.kinds.log_cabin) == 0 then waived[3] = true end
        end
        if waived[3] then p.story_seen["restore-07"] = true end
    end
    if reading and version < 1 then
        island.migrate_wallet(R.prog, R.island)
    elseif reading and version < 3 then
        local wallet = R.prog.wallet
        R.prog.wallet = wallet + economy.shortfall(island.reserved_cost(R.island, R.prog.level), wallet)
    end
    local saved, charges = R.prog.bonus_charge or {}, {}
    for tool, slot in ipairs(economy.bonus_slots) do
        local name = "bonus_slot_" .. slot.key
        local charge
        if reading and version < 5 then
            -- Old tools were independent and used half as many points per use.
            charge = 0
            for _, bonus in ipairs(slot.levels) do
                charge = charge + 2 * num.clampi(s:int("bonus_" .. bonus.key, 0), 0, 18)
            end
        else charge = s:int(name, reading and 0 or saved[tool] or 0) end
        charges[tool] = num.clampi(charge, 0, economy.BONUS_THRESHOLD)
    end
    R.prog.bonus_charge = charges
    serialize_completed(s)
end
