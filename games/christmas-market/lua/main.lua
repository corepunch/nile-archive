-- Christmas Market · Winter Wishes — square-grid match-3 winter wishes that build a Christmas market.
--
-- The game is data: lua/game_config.lua (words), lua/town_config.lua (the town), the
-- campaign, story and building tables, skin.lua, art.lua and the PNGs. The
-- flow around the board, every dialog, the shop, saving and
-- the debug entry points are the engine's (engine/lua/match3/game.lua).
-- See docs/PORTRAIT_GAMES.md.
local R = require("state")
local island = require("island")
local rules = require("rules")
local economy = require("economy")
local match3_game = require("match3.game")
require("screens")
require("narrative")
require("chimney_smoke")
require("smoke")
require("campaign_smoke")

local bonuses = require("match3.bonuses")
match3_game.bind_campaign_bonuses(R, island, economy.board_loadout, function(_, number, restored)
    return economy.board_backdrop(number, restored)
end)
require("art").bind_board_backdrops(R.scenes)

local serialize_completed = match3_game.bind_completed_rewards(R, rules)
function R.serialize_campaign(s)
    local reading = save.is_reading(s)
    local version = s:int("market_resources", reading and 0 or economy.CAMPAIGN_VERSION)
    -- Version 3 added the twenty-stall ladder. Stalls an older save had
    -- already passed stay optional rather than holding its next wish. Waive
    -- them before any wallet top-up, which reserves only what is still owed.
    island.serialize_waivers(s, R.island, R.prog.level, reading and version < 3)
    if reading and version >= 3 and version < 6 then
        -- Chapel moved from the thirteenth permit to before the cocoa kiosk.
        -- Keep old waivers attached to their buildings.
        local chapel = island.ladder_position[island.kinds.chapel]
        local old_chapel = 13
        local old, moved = island.waived(R.island), {}
        for n in ipairs(island.ladder) do
            local previous = n
            if n == chapel then previous = old_chapel
            elseif n > chapel and n <= old_chapel then previous = n - 1 end
            moved[n] = old[previous]
        end
        if R.prog.level > economy.unlock_of("chapel").after then moved[chapel] = true end
        island.set_waived(R.island, moved)
    end
    if reading and version < 7 then
        -- Version 7 spread the twenty stalls over a hundred wishes and changed
        -- their order, so old positions name other stalls. Start again from
        -- what the save owns: stalls already passed stay optional.
        island.set_waived(R.island, {})
        island.waive_passed(R.island, R.prog.level)
    elseif reading and version < 8 then
        -- Candlelight and Gift wrapping traded gates. Ownership is keyed by
        -- the unchanged city types, but waivers are stored by ladder position.
        local waivers = island.waived(R.island)
        local candles = island.ladder_position[island.kinds.candles]
        local gifts = island.ladder_position[island.kinds.gifts]
        waivers[candles], waivers[gifts] = waivers[gifts], waivers[candles]
    end
    if reading and version < 2 then island.migrate_wallet(R.prog, R.island) end
    local legacy
    if reading and version < 5 then
        local stock = s:ints("tool_stock", purse())
        local threshold = version < 4 and 200 or bonuses.THRESHOLD
        -- The post office halved the threshold in the old extended campaign.
        if R.prog.level >= 14 and island.owned(R.island, island.kinds.post_office) > 0 then threshold = threshold // 2 end
        legacy = function(tool)
            if tool == 1 or tool == 4 then
                local old_slot = tool == 1 and 1 or 3
                return math.floor(math.max(0, stock[old_slot]) * bonuses.THRESHOLD / threshold)
            end
            return 0
        end
    end
    R.prog.bonus_charge = bonuses.serialize(s, R.prog.bonus_charge, legacy)
    serialize_completed(s)
end

require("user_events_runtime")   -- after every hook it wraps

return match3_game.app(R)
