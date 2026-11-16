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

function R.board_lesson(g)
    local level = rules.level_of(g)
    for _, unlock in ipairs(economy.unlocks) do
        if g.level + 1 == unlock.first_level then
            local active = unlock.tool and g.starting_tools and g.starting_tools[unlock.tool] > 0
                or g.resource_yields and g.resource_yields[unlock.kind] == unlock
            if active then return level.lesson .. "\n" .. economy.unlock_text(unlock) end
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
