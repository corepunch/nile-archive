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

local serialize_completed = match3_game.bind_completed_rewards(R, rules)
function R.serialize_campaign(s)
    local reading = save.is_reading(s)
    local version = s:int("market_resources", reading and 0 or 1)
    if reading and version == 0 then island.migrate_wallet(R.prog, R.island) end
    serialize_completed(s)
end

return match3_game.app(R)
