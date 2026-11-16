local R = require("state")
local rules = require("rules")
local island = require("island")
local economy = require("economy")

function R.board_context(preview)
    if preview then
        return {
            [economy.WELL_KIND]=not app.arg("before-well"),
            [economy.WORKSHOP_KIND]=not app.arg("before-workshop"),
        }
    end
    return {
        [economy.WELL_KIND]=island.owned(R.island, economy.WELL_KIND) > 0,
        [economy.WORKSHOP_KIND]=island.owned(R.island, economy.WORKSHOP_KIND) > 0,
    }
end

function R.board_lesson(g)
    local level = rules.level_of(g)
    local piece = economy.unlocks[level.resource_unlock]
    if piece and g.resource_yields and g.resource_yields[piece.kind] == piece then
        return level.lesson .. "\n" .. economy.unlock_text(piece)
    end
    return level.lesson
end

local serialize_completed = require("match3.game").bind_completed_rewards(R, rules)
function R.serialize_campaign(s)
    local reading = save.is_reading(s)
    local version = s:int("resource_version", reading and 0 or economy.CAMPAIGN_VERSION)
    if reading and version < economy.CAMPAIGN_VERSION then island.migrate_wallet(R.prog, R.island) end
    serialize_completed(s)
end
