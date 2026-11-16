-- Christmas Market · Winter Wishes — hex straight-line match-3 winter wishes that build a Christmas market.
--
-- The game is data: data/game.json (words), data/town.json (the town), the
-- campaign, story and building tables, skin.lua, art.lua and the PNGs. The
-- flow around the board, every dialog, the shop, the level list, saving and
-- the debug entry points are the engine's (engine/match3_game.lua); board.lua
-- and screens.lua paint the game's own art. See docs/PORTRAIT_GAMES.md.
local R = require("state")
local island = require("island")
local rules = require("rules")
local match3_game = require("match3.game")
require("screens")
require("board")
require("narrative")
require("smoke")
require("campaign_smoke")

function R.board_context(preview)
    if not preview then return island.wonder_count(R.island) end
end

local make_board = R.make_board
function R.make_board(level, seed, preview)
    local g = make_board(level, seed, preview)
    if not preview and g.tool_meter and R.prog then
        g.bank_tools = true
        local stock = R.prog.tool_stock
        for tool in pairs(g.tool_meter) do
            local points = stock and math.max(0, stock[tool]) or 0
            g.tools[tool] = points // g.tool_threshold
            g.tool_meter[tool] = points % g.tool_threshold
        end
    end
    return g
end

-- Carry uses and partial meters through retries and restarts.
function R.update_bonus_charges()
    local g = R.g
    if not g.bank_tools then return end
    local stock = R.prog.tool_stock or purse()
    local changed = false
    for tool, meter in pairs(g.tool_meter) do
        local points = g.tools[tool] * g.tool_threshold + meter
        if stock[tool] ~= points then stock[tool], changed = points, true end
    end
    if changed then
        R.prog.tool_stock = stock
        R.save_progress()
    end
end

local serialize_completed = match3_game.bind_completed_rewards(R, rules)
function R.serialize_campaign(s)
    local reading = save.is_reading(s)
    local version = s:int("market_resources", reading and 0 or 2)
    if reading and version < 2 then island.migrate_wallet(R.prog, R.island) end
    R.prog.tool_stock = s:ints("tool_stock", not reading and R.prog.tool_stock or purse())
    serialize_completed(s)
end

return match3_game.app(R)
