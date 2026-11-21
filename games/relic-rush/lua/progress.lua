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

local game = require("match3.game")
local bonuses = require("match3.bonuses")
game.bind_campaign_bonuses(R, island, economy.board_loadout, function(_, number, restored)
    return economy.board_backdrop(number, restored)
end)

local function opening_unlock(g)
    local level = rules.level_of(g)
    for _, unlock in ipairs(economy.unlocks) do
        local building = island.buildings[island.kinds[unlock.building] + 1].name
        if g.bonus_debut and unlock.bonus == g.bonus_debut then
            return economy.bonus_lesson(g.bonus_debut), building
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
    -- The finale has its own opening.
    if (g.level < 28 or g.bonus_debut) and g.moves == rules.level_of(g).moves and not app.arg("mission") then
        local text, building = opening_unlock(g)
        if text then
            R.notice(building and building .. " · " .. text or text)
        end
    end
end

local serialize_completed = game.bind_completed_rewards(R, rules)
function R.serialize_campaign(s)
    local reading = save.is_reading(s)
    local version = s:int("resource_version", reading and 0 or economy.CAMPAIGN_VERSION)
    -- Version 4 added the twenty-step ladder. Restorations an older save had
    -- already passed stay optional rather than holding its next expedition.
    island.serialize_waivers(s, R.island, R.prog.level, reading and version < 4)
    if reading and version < 8 then
        local c, p = R.island, R.prog
        local waived = island.waived(c)
        if version >= 4 then
            local old = {"camp","well","log_cabin","workshop","water_mill","clock_tower","amphitheater","gateway",
                "lodge","trading_post","lighthouse","archive","beached_ship","map_room","observatory","aviary",
                "fountain","museum","temple"}
            if version < 7 then table.insert(old, 6, "quay_steps") end
            local mask = s:int("ladder_waived", 0)
            waived = {}
            for pos, key in ipairs(old) do
                local now = island.ladder_position[island.kinds[key]]
                if now and mask & (1 << (pos - 1)) ~= 0 then waived[now] = true end
            end
            island.set_waived(c, waived)
        end
        if version < 7 and (island.owned(c, island.kinds.workshop) > 0 or version < 6 and p.level >= 10) then
            if island.owned(c, island.kinds.log_cabin) == 0 then
                waived[island.ladder_position[island.kinds.log_cabin]] = true
                p.story_seen["restore-07"] = true
            end
        end
    end
    if reading and version < 1 then
        island.migrate_wallet(R.prog, R.island)
    elseif reading and version < 3 then
        local wallet = R.prog.wallet
        R.prog.wallet = wallet + economy.shortfall(island.reserved_cost(R.island, R.prog.level), wallet)
    end
    R.prog.bonus_charge = bonuses.serialize(s, R.prog.bonus_charge, reading and version < 9 and function(_, slot)
        local charge
        if version < 5 then
            -- Old tools were independent and used half as many points per use.
            charge = 0
            local old = {impact={"hammer","dynamite"}, shield={"shield","fireball","superbomb","plus"},
                hourglass={"hourglass","mixer"}, lightning={"lightning","star"}}
            for _, key in ipairs(old[slot.key]) do
                charge = charge + 2 * num.clampi(s:int("bonus_" .. key, 0), 0, 18)
            end
        else
            charge = s:int("bonus_slot_" .. (version < 8 and slot.legacy_slot or slot.key), 0)
        end
        return math.floor(charge * economy.BONUS_THRESHOLD / 36)
    end)
    serialize_completed(s)
end
