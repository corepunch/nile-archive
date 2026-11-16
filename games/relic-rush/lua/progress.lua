local R = require("state")
local rules = require("rules")
local island = require("island")
local economy = require("economy")

function R.board_context(preview)
    local restored = {}
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

local function opening_unlock(g)
    local level = rules.level_of(g)
    for i, unlock in ipairs(economy.unlocks) do
        if g.level + 1 == unlock.first_level or level.featured_resource == unlock.key then
            local active = unlock.tool and g.starting_tools and g.starting_tools[unlock.tool] > 0
                or g.resource_yields and g.resource_yields[unlock.kind] == unlock
            if active then return unlock, island.wonders[i].name end
        end
    end
    for _, piece in pairs(g.resource_yields or {}) do
        if g.level + 1 == piece.first_level then return piece end
    end
end

function R.board_lesson(g)
    local lesson, unlock = rules.level_of(g).lesson, opening_unlock(g)
    return unlock and lesson .. "\n" .. economy.unlock_text(unlock) or lesson
end

local present_board = R.present_board
function R.present_board()
    present_board()
    local g = R.g
    if g.level < 20 and g.moves == rules.level_of(g).moves and not app.arg("mission") then
        local unlock, building = opening_unlock(g)
        if unlock then
            local text = economy.unlock_text(unlock)
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
    serialize_completed(s)
end
