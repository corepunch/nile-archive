local R = require("state")
local rules = require("rules")
local island = require("island")
local economy = require("economy")
local quests = require("quests")

-- The crew's requests (lua/quests.lua): what this save has banked and handed in.
R.item_keys = {}
for i, quest in ipairs(quests.list) do R.item_keys[i] = quest.key end
function R.quest_state()
    R.prog.quests = R.prog.quests or quests.new_state()
    return R.prog.quests
end
local function owns(building) return island.owned(R.island, island.kinds[building]) > 0 end
function R.open_quests() return quests.open(R.quest_state(), owns) end

function R.quest_opened(id)
    local state = R.quest_state()
    local quest = quests.by_key[id]
    local ready = quest and quests.ready(state, quest)
    if not state.introduced[id] or ready and not state.ready_seen[id] then
        state.introduced[id] = true
        if ready then state.ready_seen[id] = true end
        R.save_progress()
    end
end

-- Restoration dialogue plays first. Introduce one actionable request per
-- visit. A new purchase or hand-in can give the crew a fresh lead in town.
local story_tick = R.story_tick
function R.story_tick()
    local state = R.quest_state()
    if state.pending and R.story_current and R.story_current.key == "quest-" .. state.pending and not story.active() then
        state.pending = nil  -- the base tick acknowledges and saves this beat
    end
    story_tick()
    if not R.on_island then state.offered_visit = nil; return end
    if not R.town or R.quiet or R.overlay ~= R.OV_NONE or story.active() or R.island.placing >= 0 or R.diving() then return end
    if state.pending then
        R.queue_story({key="quest-" .. state.pending, lines=require("quest_scenes")[state.pending]})
        return
    end
    if state.offered_visit == R.island.count then return end
    state.offered_visit = R.island.count
    if quests.shutter_open(state) and not state.introduced.shutter then
        R.open_quest("shutter", true)
        return
    end
    local open = R.open_quests()
    for _, quest in ipairs(open) do
        if quests.ready(state, quest) and not state.ready_seen[quest.key] then
            R.open_quest(quest.key, true)
            return
        end
    end
    for _, quest in ipairs(open) do
        if not state.introduced[quest.key] and not R.quest_model(quest.key).waiting then
            R.open_quest(quest.key, true)
            return
        end
    end
end

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
    if not preview and R.prog then restored.quests = quests.collecting(R.quest_state(), owns) end
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

-- Apply the same loadout to a parked board that a new deal would get. Resource
-- and request pieces change in their existing slots, so the deal, progress and
-- resources already earned survive the trip to the island.
function R.refresh_board_bonuses()
    local g = R.g
    if not g.tool_slots or g.bonus_preview then return end
    local spec, restored = rules.level_of(g), R.board_context()
    local yields, loadout, bonus, debut = economy.board_loadout(spec, g.level + 1, restored, g.loadout_seed)
    for tool, charge in pairs(loadout.tool_meter) do
        if g.tool_meter[tool] == nil then
            g.tool_meter[tool], g.tools[tool] = charge, charge // g.tool_threshold
        end
    end
    g.resource_yields, g.tool_slots = yields, loadout.tool_slots
    g.bonus, g.bonus_debut = bonus, debut
    g.backdrop = economy.board_backdrop(spec, g.level + 1, restored)
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
    -- The finale has its own opening.
    if (g.level < 28 or g.bonus_debut) and g.moves == rules.level_of(g).moves and not app.arg("mission") then
        local text, building = opening_unlock(g)
        if text then
            R.notice(building and building .. " · " .. text or text)
        else
            -- A request's piece on its first board.
            local state = R.quest_state()
            for _, piece in pairs(g.resource_yields or {}) do
                if piece.item and not g.bonus_preview and (state.have[piece.item] or 0) == 0 then
                    R.notice(piece.name .. " · Match them to fill the crew's request.")
                    break
                end
            end
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
    local saved, charges = R.prog.bonus_charge or {}, {}
    for tool, slot in ipairs(economy.bonus_slots) do
        local name = "bonus_slot_" .. (reading and version < 8 and slot.legacy_slot or slot.key)
        local charge
        if reading and version < 5 then
            -- Old tools were independent and used half as many points per use.
            charge = 0
            local old = {impact={"hammer","dynamite"}, shield={"shield","fireball","superbomb","plus"},
                hourglass={"hourglass","mixer"}, lightning={"lightning","star"}}
            for _, key in ipairs(old[slot.key]) do
                charge = charge + 2 * num.clampi(s:int("bonus_" .. key, 0), 0, 18)
            end
        else charge = s:int(name, reading and 0 or saved[tool] or 0) end
        charges[tool] = num.clampi(charge, 0, economy.BONUS_THRESHOLD)
    end
    R.prog.bonus_charge = charges
    quests.serialize(s, R.quest_state())
    serialize_completed(s)
end

-- Review entry points for the crew's requests, after the engine's own:
--   --quest-have N     every open request has N pieces banked (up to its need)
--   --quest-card KEY   the island, with that request's card open
--   --quest-handoff KEY   the island, with the request's hand-in painting open
local debug_screens = R.debug_screens
function R.debug_screens()
    debug_screens()
    local have = tonumber(app.arg("quest-have") or "")
    if have then
        local state = R.quest_state()
        for _, quest in ipairs(R.open_quests()) do state.have[quest.key] = math.min(quest.need, have) end
    end
    if have and app.arg("victory") and R.g and R.g.items then   -- a won board with request pieces to bank
        for _, quest in ipairs(quests.scheduled(R.g.level + 1)) do R.g.items[quest.key] = 9 end
    end
    local handoff = app.arg("quest-handoff")
    local offer = app.arg("quest-offer")
    local id = handoff or offer or app.arg("quest-card")
    if id == "shutter" or quests.by_key[id] then
        R.on_island, R.toast_time = true, 0
        local state = R.quest_state()
        -- An interactive review starts at this story moment, with earlier
        -- restoration dialogue settled, just as it would be after play.
        for _, beat in ipairs(require("journey").beats) do
            if beat.level <= R.prog.level then R.prog.story_seen[beat.key] = true end
        end
        local target = quests.by_key[id] or quests.by_key.cable
        for _, earlier in ipairs(quests.list) do
            if earlier == target then break end
            if earlier.line == target.line then state.done[earlier.key] = true end
        end
        if id == "shutter" then state.done.cable = true
        elseif have then state.have[id] = math.min(have, target.need) end
        if handoff then
            if quests.by_key[id] then state.have[id] = target.need end
            assert(R.open_quest_handoff(id))
        else assert(R.open_quest(id, offer ~= nil)) end
    end
end
