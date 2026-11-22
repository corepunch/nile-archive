-- Relic Rush · The Lost Valley — square-grid match-3 expeditions that restore an island.
--
-- The game is data: lua/game_config.lua (words), lua/town_config.lua (the town), the
-- campaign, story and building tables, skin.lua, art.lua and the PNGs. The
-- flow around the board, every dialog, the shop, saving and
-- the debug entry points are the engine's (engine/lua/match3/game.lua).
-- See docs/PORTRAIT_GAMES.md.
local R = require("state")
require("art").bind_board_backdrops(R.scenes)
require("screens")
require("narrative")
require("progress")
require("smoke")
require("user_events_runtime")   -- after every hook it wraps

return require("match3.game").app(R)
