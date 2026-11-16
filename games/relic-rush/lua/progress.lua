local R = require("state")
local rules = require("rules")
local island = require("island")
local economy = require("economy")

function R.board_context(preview)
    local restored = {preview=preview, bonus_charge=not preview and R.prog and R.prog.bonus_charge}
    for i, wonder in ipairs(island.wonders) do
        local building = i - 1
        if preview then
            restored[building] = not app.arg("before-" .. wonder.key)
        else
            restored[building] = island.owned(R.island, building) > 0
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

local function opening_unlock(g)
    local level = rules.level_of(g)
    for i, unlock in ipairs(economy.unlocks) do
        local building = island.wonders[i].name
        if g.bonus_debut and unlock.bonus == g.bonus_debut then
            return economy.bonus_lesson(g.bonus_debut), building
        elseif unlock.kind and (g.level + 1 == unlock.first_level or level.featured_resource == unlock.key) then
            if g.resource_yields and g.resource_yields[unlock.kind] == unlock then
                return economy.unlock_text(unlock), building
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
    if (g.level < 20 or g.bonus_debut) and g.moves == rules.level_of(g).moves and not app.arg("mission") then
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
    if reading and version < 1 then
        island.migrate_wallet(R.prog, R.island)
    elseif reading and version < economy.CAMPAIGN_VERSION then
        local wallet = R.prog.wallet
        R.prog.wallet = wallet + economy.shortfall(island.reserved_cost(R.island, R.prog.level), wallet)
    end
    local charges = R.prog.bonus_charge or {}
    for i, bonus in ipairs(economy.bonuses) do
        charges[i] = num.clampi(s:int("bonus_" .. bonus.key, reading and 0 or charges[i] or 0), 0, economy.BONUS_THRESHOLD)
    end
    R.prog.bonus_charge = charges
    serialize_completed(s)
end
