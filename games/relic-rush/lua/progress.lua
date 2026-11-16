local R = require("state")
local rules = require("rules")
local island = require("island")
local economy = require("economy")

function R.board_context(preview)
    local restored = {}
    for _, piece in pairs(economy.unlocks) do
        local building = piece.building
        if preview then
            restored[building] = not app.arg("before-" .. island.wonders[building + 1].key)
        else
            restored[building] = island.owned(R.island, building) > 0
        end
    end
    return restored
end

function R.board_lesson(g)
    local level = rules.level_of(g)
    for _, piece in pairs(economy.unlocks) do
        if g.level + 1 == piece.first_level and g.resource_yields and g.resource_yields[piece.kind] == piece then
            return level.lesson .. "\n" .. economy.unlock_text(piece)
        end
    end
    return level.lesson
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
